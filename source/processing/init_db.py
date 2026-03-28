import asyncio
import os
import re

import asyncpg

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@db:5432/seismic",
)

_dsn = re.sub(r"postgresql\+asyncpg://", "postgresql://", DATABASE_URL)

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS events (
    id SERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    dominant_frequency FLOAT NOT NULL,
    amplitude FLOAT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    detected_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_events_sensor_type_ts UNIQUE (sensor_id, event_type, timestamp)
);

CREATE INDEX IF NOT EXISTS idx_events_sensor_time ON events(sensor_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
"""


async def init_db() -> None:
    conn: asyncpg.Connection = await asyncpg.connect(_dsn)
    try:
        await conn.execute(SCHEMA_SQL)
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(init_db())
