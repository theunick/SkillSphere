"""
Processing service for the distributed seismic analysis platform.

Each replica connects to:
- Broker WebSocket for live sensor measurements
- Simulator SSE control stream for shutdown commands

It maintains per-sensor sliding windows, runs FFT analysis, classifies
seismic events, deduplicates, and persists significant detections to
PostgreSQL.
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import sys
import uuid
from collections import defaultdict, deque
from datetime import datetime, timedelta, timezone
from typing import Any

import asyncpg
import httpx
import numpy as np
from fastapi import FastAPI, Query
from fastapi.responses import JSONResponse
from sse_starlette.sse import EventSourceResponse

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

BROKER_URL: str = os.getenv("BROKER_URL", "ws://broker:8000/ws/sensors")
SIMULATOR_URL: str = os.getenv("SIMULATOR_URL", "http://simulator:8080")
DATABASE_URL: str = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@db:5432/seismic",
)
REPLICA_ID: str = os.getenv("REPLICA_ID", str(uuid.uuid4()))
WINDOW_SIZE: int = int(os.getenv("WINDOW_SIZE", "256"))
AMPLITUDE_THRESHOLD: float = float(os.getenv("AMPLITUDE_THRESHOLD", "0.5"))
SAMPLING_RATE: float = float(os.getenv("SAMPLING_RATE", "20.0"))

# asyncpg needs plain postgresql:// DSN
_dsn: str = re.sub(r"postgresql\+asyncpg://", "postgresql://", DATABASE_URL)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(f"processing-{REPLICA_ID[:8]}")

# ---------------------------------------------------------------------------
# Application state
# ---------------------------------------------------------------------------

app = FastAPI(title="Seismic Processing Service", version="1.0.0")

# Per-sensor sliding window: sensor_id -> deque of float values
sensor_windows: dict[str, deque[float]] = defaultdict(
    lambda: deque(maxlen=WINDOW_SIZE)
)

# Latest info per sensor (for /api/sensors)
sensor_status: dict[str, dict[str, Any]] = {}

# Database connection pool
db_pool: asyncpg.Pool | None = None

# SSE subscribers for /api/events/stream
event_subscribers: list[asyncio.Queue] = []

# Background task handles
_background_tasks: list[asyncio.Task] = []


# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------


@app.on_event("startup")
async def startup() -> None:
    global db_pool

    # Initialise database
    from init_db import init_db

    try:
        await init_db()
        logger.info("Database schema applied")
    except Exception:
        logger.exception("Failed to initialise database schema")

    # Create the connection pool
    try:
        db_pool = await asyncpg.create_pool(_dsn, min_size=2, max_size=10)
        logger.info("Database connection pool created")
    except Exception:
        logger.exception("Failed to create database pool")

    # Launch background listeners
    _background_tasks.append(asyncio.create_task(_broker_listener()))
    _background_tasks.append(asyncio.create_task(_control_listener()))
    logger.info("Replica %s started", REPLICA_ID)


@app.on_event("shutdown")
async def shutdown() -> None:
    for task in _background_tasks:
        task.cancel()
    if db_pool:
        await db_pool.close()
    logger.info("Replica %s shut down", REPLICA_ID)


# ---------------------------------------------------------------------------
# Background: Broker WebSocket listener
# ---------------------------------------------------------------------------


async def _broker_listener() -> None:
    """Connect to the broker WebSocket and consume sensor measurements."""
    import websockets
    import websockets.exceptions

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


# ---------------------------------------------------------------------------
# Background: Simulator SSE control listener
# ---------------------------------------------------------------------------


async def _control_listener() -> None:
    """Listen to the simulator control SSE stream for SHUTDOWN commands."""
    control_url = f"{SIMULATOR_URL}/api/control"

    while True:
        try:
            logger.info("Connecting to simulator control at %s", control_url)
            async with httpx.AsyncClient(timeout=None) as client:
                async with client.stream("GET", control_url) as resp:
                    logger.info("Connected to simulator control stream")
                    buffer = ""
                    async for chunk in resp.aiter_text():
                        buffer += chunk
                        while "\n" in buffer:
                            line, buffer = buffer.split("\n", 1)
                            line = line.strip()
                            if not line or line.startswith(":"):
                                continue
                            if line.startswith("data:"):
                                data_str = line[len("data:"):].strip()
                            else:
                                data_str = line

                            try:
                                data = json.loads(data_str)
                            except json.JSONDecodeError:
                                continue

                            if data.get("command") == "SHUTDOWN":
                                logger.warning(
                                    "SHUTDOWN command received, terminating replica %s",
                                    REPLICA_ID,
                                )
                                os._exit(0)
        except Exception:
            logger.warning(
                "Control stream connection failed, retrying in 3s", exc_info=True
            )
        await asyncio.sleep(3)


# ---------------------------------------------------------------------------
# Measurement handling & FFT analysis
# ---------------------------------------------------------------------------


async def _handle_measurement(msg: dict) -> None:
    """Process a single sensor measurement."""
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

    # Update sensor status
    sensor_status[sensor_id] = {
        "sensor_id": sensor_id,
        "last_value": value,
        "last_timestamp": ts.isoformat(),
        "sample_count": sensor_status.get(sensor_id, {}).get("sample_count", 0) + 1,
    }

    # Append to sliding window
    window = sensor_windows[sensor_id]
    window.append(value)

    # Only run FFT when the window is full
    if len(window) < WINDOW_SIZE:
        return

    dominant_freq, amplitude = _run_fft(list(window))

    if amplitude < AMPLITUDE_THRESHOLD:
        return

    event_type = _classify(dominant_freq)
    if event_type is None:
        return

    # Deduplication check then insert
    await _store_event(sensor_id, event_type, dominant_freq, amplitude, ts)


def _run_fft(values: list[float]) -> tuple[float, float]:
    """Run real FFT on a window of values and return (dominant_freq_hz, amplitude)."""
    signal = np.array(values, dtype=np.float64)
    # Remove DC bias
    signal = signal - np.mean(signal)

    spectrum = np.fft.rfft(signal)
    magnitudes = np.abs(spectrum)

    # Frequency bins
    freqs = np.fft.rfftfreq(len(signal), d=1.0 / SAMPLING_RATE)

    # Exclude DC component (index 0)
    if len(magnitudes) > 1:
        peak_idx = int(np.argmax(magnitudes[1:])) + 1
    else:
        return 0.0, 0.0

    dominant_freq = float(freqs[peak_idx])
    amplitude = float(magnitudes[peak_idx]) / len(signal)  # normalised

    return dominant_freq, amplitude


def _classify(freq: float) -> str | None:
    """Classify a dominant frequency into an event type, or None if below 0.5 Hz."""
    if 0.5 <= freq < 3.0:
        return "earthquake"
    if 3.0 <= freq < 8.0:
        return "conventional_explosion"
    if freq >= 8.0:
        return "nuclear_like_event"
    return None


# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------


async def _is_duplicate(
    conn: asyncpg.Connection,
    sensor_id: str,
    event_type: str,
    ts: datetime,
) -> bool:
    """Return True if a similar event was already recorded within the last 10 s."""
    row = await conn.fetchrow(
        """
        SELECT 1 FROM events
        WHERE sensor_id = $1
          AND event_type = $2
          AND timestamp BETWEEN $3 AND $4
        LIMIT 1
        """,
        sensor_id,
        event_type,
        ts - timedelta(seconds=10),
        ts + timedelta(seconds=10),
    )
    return row is not None


async def _store_event(
    sensor_id: str,
    event_type: str,
    dominant_freq: float,
    amplitude: float,
    ts: datetime,
) -> None:
    """Deduplicate and persist an event, then broadcast to SSE subscribers."""
    if db_pool is None:
        logger.warning("Database pool not available, skipping event storage")
        return

    async with db_pool.acquire() as conn:
        if await _is_duplicate(conn, sensor_id, event_type, ts):
            logger.debug(
                "Duplicate event filtered: sensor=%s type=%s", sensor_id, event_type
            )
            return

        await conn.execute(
            """
            INSERT INTO events (sensor_id, event_type, dominant_frequency,
                                amplitude, timestamp, detected_by)
            VALUES ($1, $2, $3, $4, $5, $6)
            """,
            sensor_id,
            event_type,
            dominant_freq,
            amplitude,
            ts,
            REPLICA_ID,
        )

    logger.info(
        "Event stored: sensor=%s type=%s freq=%.2f amp=%.4f",
        sensor_id,
        event_type,
        dominant_freq,
        amplitude,
    )

    # Broadcast to SSE subscribers
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


# ---------------------------------------------------------------------------
# API endpoints
# ---------------------------------------------------------------------------


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
    """Return recent events from the database with optional filters."""
    if db_pool is None:
        return JSONResponse(
            status_code=503,
            content={"error": "Database not available"},
        )

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
    """SSE endpoint pushing newly detected events to connected clients."""

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
    """Return a list of known sensors and their latest status."""
    sensors = list(sensor_status.values())
    return JSONResponse(content=sensors)
