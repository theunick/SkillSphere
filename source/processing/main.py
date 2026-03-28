from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import uuid
from collections import defaultdict, deque
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from typing import Any

import asyncpg
import httpx
import numpy as np
import websockets
import websockets.exceptions
from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse
from sse_starlette.sse import EventSourceResponse

BROKER_URL: str = os.getenv("BROKER_URL", "ws://broker:8000/ws/sensors")
SIMULATOR_URL: str = os.getenv("SIMULATOR_URL", "http://simulator:8080")
DATABASE_URL: str = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@db:5432/seismic",
)
REPLICA_ID: str = os.getenv("REPLICA_ID", str(uuid.uuid4()))
WINDOW_SIZE: int = int(os.getenv("WINDOW_SIZE", "256"))
HOP_SIZE: int = int(os.getenv("HOP_SIZE", str(WINDOW_SIZE // 2)))
AMPLITUDE_THRESHOLD: float = float(os.getenv("AMPLITUDE_THRESHOLD", "0.5"))
SNR_THRESHOLD: float = float(os.getenv("SNR_THRESHOLD", "4.0"))
SAMPLING_RATE: float = float(os.getenv("SAMPLING_RATE", "20.0"))

_dsn: str = re.sub(r"postgresql\+asyncpg://", "postgresql://", DATABASE_URL)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(f"processing-{REPLICA_ID}")

# Per-sensor sliding window of float values
sensor_windows: dict[str, deque[float]] = defaultdict(
    lambda: deque(maxlen=WINDOW_SIZE)
)

# Per-sensor sample counter for hop mechanism
sensor_hop_counter: dict[str, int] = defaultdict(int)

# Latest info per sensor
sensor_status: dict[str, dict[str, Any]] = {}

# Database connection pool
db_pool: asyncpg.Pool | None = None

# SSE subscribers for /api/events/stream
event_subscribers: list[asyncio.Queue] = []

# Background task handles
_background_tasks: list[asyncio.Task] = []


@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_pool

    from init_db import init_db
    for attempt in range(10):
        try:
            await init_db()
            logger.info("Database schema applied")
            break
        except Exception:
            logger.warning("DB init attempt %d failed, retrying in 2s...", attempt + 1)
            await asyncio.sleep(2)

    for attempt in range(10):
        try:
            db_pool = await asyncpg.create_pool(_dsn, min_size=2, max_size=10)
            logger.info("Database connection pool created")
            break
        except Exception:
            logger.warning("DB pool attempt %d failed, retrying in 2s...", attempt + 1)
            await asyncio.sleep(2)

    _background_tasks.append(asyncio.create_task(_broker_listener()))
    _background_tasks.append(asyncio.create_task(_control_listener()))
    logger.info("Replica %s started", REPLICA_ID)

    yield

    for task in _background_tasks:
        task.cancel()
    await asyncio.gather(*_background_tasks, return_exceptions=True)
    if db_pool:
        await db_pool.close()
    logger.info("Replica %s shut down", REPLICA_ID)


app = FastAPI(title="Seismic Processing Service", version="1.0.0", lifespan=lifespan)


async def _broker_listener() -> None:
    while True:
        try:
            logger.info("Connecting to broker at %s", BROKER_URL)
            async with websockets.connect(BROKER_URL) as ws:
                logger.info("Connected to broker")
                async for raw in ws:
                    try:
                        msg = json.loads(raw)
                        await _handle_measurement(msg)
                    except json.JSONDecodeError:
                        logger.warning("Non-JSON message from broker: %s", raw[:120])
                    except Exception:
                        logger.exception("Error handling measurement")
        except websockets.exceptions.ConnectionClosedError:
            logger.warning("Broker connection closed, reconnecting in 3s")
        except Exception:
            logger.warning("Broker connection failed, retrying in 3s", exc_info=True)
        await asyncio.sleep(3)


async def _control_listener() -> None:
    control_url = f"{SIMULATOR_URL}/api/control"

    while True:
        try:
            logger.info("Connecting to simulator control at %s", control_url)
            async with httpx.AsyncClient(timeout=None) as client:
                async with client.stream("GET", control_url) as resp:
                    logger.info("Connected to simulator control stream")
                    event_type = ""
                    data_buffer = ""
                    async for line in resp.aiter_lines():
                        line = line.strip()
                        if line == "":
                            if data_buffer:
                                try:
                                    data = json.loads(data_buffer)
                                    if data.get("command") == "SHUTDOWN":
                                        logger.warning(
                                            "SHUTDOWN command received, terminating replica %s",
                                            REPLICA_ID,
                                        )
                                        os._exit(1)
                                except json.JSONDecodeError:
                                    pass
                                data_buffer = ""
                                event_type = ""
                            continue
                        if line.startswith("event:"):
                            event_type = line[len("event:"):].strip()
                        elif line.startswith("data:"):
                            data_str = line[len("data:"):].strip()
                            data_buffer = data_buffer + data_str if data_buffer else data_str
        except Exception:
            logger.warning("Control stream connection failed, retrying in 3s", exc_info=True)
        await asyncio.sleep(3)


async def _handle_measurement(msg: dict) -> None:
    sensor_id: str = msg.get("sensor_id", "unknown")
    value: float | None = msg.get("value")
    timestamp_str: str | None = msg.get("timestamp")

    if value is None:
        return

    value = float(value)

    ts = (
        datetime.fromisoformat(timestamp_str)
        if timestamp_str
        else datetime.now(timezone.utc)
    )

    sensor_status[sensor_id] = {
        "sensor_id": sensor_id,
        "last_value": value,
        "last_timestamp": ts.isoformat(),
        "sample_count": sensor_status.get(sensor_id, {}).get("sample_count", 0) + 1,
    }

    window = sensor_windows[sensor_id]
    window.append(value)

    if len(window) < WINDOW_SIZE:
        return

    sensor_hop_counter[sensor_id] += 1
    if sensor_hop_counter[sensor_id] < HOP_SIZE:
        return
    sensor_hop_counter[sensor_id] = 0

    result = _run_fft(list(window))
    if result is None:
        return

    dominant_freq, amplitude, snr = result

    if amplitude < AMPLITUDE_THRESHOLD or snr < SNR_THRESHOLD:
        return

    event_type = _classify(dominant_freq)
    if event_type is None:
        return

    await _store_event(sensor_id, event_type, dominant_freq, amplitude, ts)


def _run_fft(values: list[float]) -> tuple[float, float, float] | None:
    """Run real FFT and return (dominant_freq_hz, amplitude, snr) or None."""
    signal = np.array(values, dtype=np.float64)
    signal = signal - np.mean(signal)

    spectrum = np.fft.rfft(signal)
    magnitudes = np.abs(spectrum)

    freqs = np.fft.rfftfreq(len(signal), d=1.0 / SAMPLING_RATE)

    if len(magnitudes) <= 1:
        return None

    # Exclude DC component (index 0)
    mags_no_dc = magnitudes[1:]
    peak_idx = int(np.argmax(mags_no_dc)) + 1

    peak_magnitude = magnitudes[peak_idx]
    dominant_freq = float(freqs[peak_idx])
    amplitude = 2.0 * float(peak_magnitude) / len(signal)

    # Signal-to-Noise Ratio: peak magnitude vs mean of all other components
    other_mags = np.delete(mags_no_dc, peak_idx - 1)
    noise_mean = float(np.mean(other_mags)) if len(other_mags) > 0 else 1.0
    snr = float(peak_magnitude / noise_mean) if noise_mean > 0 else 0.0

    return dominant_freq, amplitude, snr


def _classify(freq: float) -> str | None:
    if 0.5 <= freq < 3.0:
        return "earthquake"
    if 3.0 <= freq < 8.0:
        return "conventional_explosion"
    if freq >= 8.0:
        return "nuclear_like"
    return None


async def _store_event(
    sensor_id: str,
    event_type: str,
    dominant_freq: float,
    amplitude: float,
    ts: datetime,
) -> None:
    if db_pool is None:
        logger.warning("Database pool not available, skipping event storage")
        return

    async with db_pool.acquire() as conn:
        result = await conn.execute(
            """
            INSERT INTO events (sensor_id, event_type, dominant_frequency,
                                amplitude, timestamp, detected_by)
            VALUES ($1, $2, $3, $4, $5, $6)
            ON CONFLICT (sensor_id, event_type, timestamp) DO NOTHING
            """,
            sensor_id,
            event_type,
            dominant_freq,
            amplitude,
            ts,
            REPLICA_ID,
        )
        if result == "INSERT 0 0":
            return

    logger.info(
        "Event stored: sensor=%s type=%s freq=%.2f amp=%.4f",
        sensor_id,
        event_type,
        dominant_freq,
        amplitude,
    )

    event_payload = {
        "sensor_id": sensor_id,
        "event_type": event_type,
        "dominant_frequency": round(dominant_freq, 4),
        "amplitude": round(amplitude, 6),
        "timestamp": ts.isoformat(),
        "detected_by": REPLICA_ID,
    }
    dead: list[asyncio.Queue] = []
    for q in event_subscribers:
        try:
            q.put_nowait(event_payload)
        except asyncio.QueueFull:
            dead.append(q)
    for q in dead:
        event_subscribers.remove(q)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "replica_id": REPLICA_ID}


@app.get("/api/events")
async def get_events(
    sensor_id: str | None = Query(None),
    event_type: str | None = Query(None),
    limit: int = Query(50, ge=1, le=1000),
    offset: int = Query(0, ge=0),
) -> JSONResponse:
    if db_pool is None:
        return JSONResponse(status_code=503, content={"error": "Database not available"})

    conditions: list[str] = []
    params: list[Any] = []
    idx = 1

    if sensor_id:
        conditions.append(f"sensor_id = ${idx}")
        params.append(sensor_id)
        idx += 1
    if event_type:
        conditions.append(f"event_type = ${idx}")
        params.append(event_type)
        idx += 1

    where = f"WHERE {' AND '.join(conditions)}" if conditions else ""

    params.append(limit)
    limit_idx = idx
    idx += 1
    params.append(offset)
    offset_idx = idx

    query = f"""
        SELECT id, sensor_id, event_type, dominant_frequency,
               amplitude, timestamp, detected_by, created_at
        FROM events
        {where}
        ORDER BY timestamp DESC
        LIMIT ${limit_idx} OFFSET ${offset_idx}
    """

    async with db_pool.acquire() as conn:
        rows = await conn.fetch(query, *params)

    events = [
        {
            "id": r["id"],
            "sensor_id": r["sensor_id"],
            "event_type": r["event_type"],
            "dominant_frequency": r["dominant_frequency"],
            "amplitude": r["amplitude"],
            "timestamp": r["timestamp"].isoformat(),
            "detected_by": r["detected_by"],
            "created_at": r["created_at"].isoformat() if r["created_at"] else None,
        }
        for r in rows
    ]
    return JSONResponse(content=events)


@app.get("/api/events/stream")
async def events_stream() -> EventSourceResponse:
    queue: asyncio.Queue = asyncio.Queue(maxsize=256)
    event_subscribers.append(queue)

    async def _generator():
        try:
            while True:
                event = await queue.get()
                yield {"event": "new_event", "data": json.dumps(event)}
        except asyncio.CancelledError:
            pass
        finally:
            if queue in event_subscribers:
                event_subscribers.remove(queue)

    return EventSourceResponse(_generator())


@app.get("/api/sensors")
async def get_sensors() -> JSONResponse:
    sensors = list(sensor_status.values())
    return JSONResponse(content=sensors)
