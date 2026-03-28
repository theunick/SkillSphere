import asyncio
import json
import logging
import os
from contextlib import asynccontextmanager

import httpx
import websockets
from fastapi import FastAPI, WebSocket, WebSocketDisconnect

logger = logging.getLogger("broker")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

SIMULATOR_URL = os.getenv("SIMULATOR_URL", "http://simulator:8080")
RECONNECT_DELAY = 5

replica_connections: set[WebSocket] = set()
sensor_tasks: dict[str, asyncio.Task] = {}


async def fetch_sensor_ids() -> list[str]:
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(f"{SIMULATOR_URL}/api/devices/")
        response.raise_for_status()
        devices = response.json()
    return [device["id"] for device in devices]


async def broadcast(message: str):
    disconnected = []
    for ws in replica_connections.copy():
        try:
            await ws.send_text(message)
        except Exception:
            disconnected.append(ws)
    for ws in disconnected:
        replica_connections.discard(ws)


async def sensor_listener(sensor_id: str):
    ws_url = SIMULATOR_URL.replace("http://", "ws://").replace("https://", "wss://")
    uri = f"{ws_url}/api/device/{sensor_id}/ws"

    while True:
        try:
            async with websockets.connect(uri) as ws:
                logger.info("Connected to sensor %s", sensor_id)
                async for raw in ws:
                    measurement = json.loads(raw)
                    enriched = json.dumps({
                        "sensor_id": sensor_id,
                        "timestamp": measurement["timestamp"],
                        "value": measurement["value"],
                    })
                    await broadcast(enriched)
        except (websockets.ConnectionClosed, ConnectionError, OSError) as exc:
            logger.warning("Lost connection to sensor %s: %s. Reconnecting in %ds...", sensor_id, exc, RECONNECT_DELAY)
        except Exception:
            logger.exception("Unexpected error on sensor %s. Reconnecting in %ds...", sensor_id, RECONNECT_DELAY)
        await asyncio.sleep(RECONNECT_DELAY)


async def start_sensor_listeners():
    while True:
        try:
            sensor_ids = await fetch_sensor_ids()
            logger.info("Discovered %d sensors", len(sensor_ids))
            break
        except Exception:
            logger.exception("Failed to fetch sensor list. Retrying in %ds...", RECONNECT_DELAY)
            await asyncio.sleep(RECONNECT_DELAY)

    for sensor_id in sensor_ids:
        if sensor_id not in sensor_tasks or sensor_tasks[sensor_id].done():
            sensor_tasks[sensor_id] = asyncio.create_task(sensor_listener(sensor_id))


@asynccontextmanager
async def lifespan(app: FastAPI):
    listener_task = asyncio.create_task(start_sensor_listeners())
    yield
    listener_task.cancel()
    for task in sensor_tasks.values():
        task.cancel()
    await asyncio.gather(listener_task, *sensor_tasks.values(), return_exceptions=True)


app = FastAPI(title="Seismic Broker", lifespan=lifespan)


@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "connected_sensors": len([t for t in sensor_tasks.values() if not t.done()]),
        "connected_replicas": len(replica_connections),
    }


@app.websocket("/ws/sensors")
async def ws_sensors(websocket: WebSocket):
    await websocket.accept()
    replica_connections.add(websocket)
    logger.info("Replica connected. Total replicas: %d", len(replica_connections))
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        replica_connections.discard(websocket)
        logger.info("Replica disconnected. Total replicas: %d", len(replica_connections))
