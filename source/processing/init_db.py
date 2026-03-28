"""Database initialization script. Creates the events table and indexes."""

import asyncio
import os
import re

import asyncpg


DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://postgres:postgres@db:5432/seismic",
)

# asyncpg needs a plain postgresql:// DSN, strip the +asyncpg dialect
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
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_sensor_time ON events(sensor_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
"""


async def init_db() -> None:
    """Connect to PostgreSQL and apply the schema."""
    conn: asyncpg.Connection = await asyncpg.connect(_dsn)
    try:
        await conn.execute(SCHEMA_SQL)
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(init_db())
