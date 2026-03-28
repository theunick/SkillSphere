# Student Documentation — SeismicWatch

## Team

| Name | Student ID | Role |
|---|---|---|
| TBD | TBD | TBD |
| TBD | TBD | TBD |
| TBD | TBD | TBD |
| TBD | TBD | TBD |

## System Overview

SeismicWatch is a distributed seismic event detection and monitoring platform. It ingests real-time sensor data from a seismic simulator, performs frequency-domain analysis via FFT, classifies events, persists them with deduplication, and serves a real-time dashboard.

## Architecture

### Component Diagram

```
                        ┌───────────────────────────────┐
                        │       Seismic Simulator       │
                        │    (provided Docker image)     │
                        │                               │
                        │  WS /api/device/{id}/ws       │
                        │  SSE /api/control             │
                        │  REST /api/devices/           │
                        └──────┬──────────┬─────────────┘
                               │          │
                    WebSocket  │          │ SSE (control)
                               ▼          │
                        ┌──────────────┐  │
                        │    Broker    │  │
                        │  (FastAPI)   │  │
                        │  Port 8000   │  │
                        └──────┬───────┘  │
                               │          │
                    WebSocket  │          │
                    (fan-out)  │          │
                 ┌─────────────┼──────────┤
                 │             │          │
                 ▼             ▼          ▼
          ┌────────────┐┌────────────┐┌────────────┐
          │Processing-1││Processing-2││Processing-3│
          │  (FastAPI)  ││  (FastAPI)  ││  (FastAPI)  │
          │  FFT+Class  ││  FFT+Class  ││  FFT+Class  │
          └──────┬──────┘└──────┬──────┘└──────┬──────┘
                 │              │              │
                 └──────────────┼──────────────┘
                                │
                                ▼
                        ┌──────────────┐
                        │  PostgreSQL  │
                        │  (events DB) │
                        └──────────────┘
                                ▲
                                │
                        ┌──────────────┐
                        │   Gateway    │
                        │   (Nginx)    │
                        │   Port 80    │
                        └──────┬───────┘
                               │
                        ┌──────────────┐
                        │   Frontend   │
                        │   (Vue 3)    │
                        └──────────────┘
```

### Services

| Service | Technology | Port | Role |
|---|---|---|---|
| Simulator | Provided Docker image | 8080 | Seismic data generation |
| Broker | Python 3.11 / FastAPI | 8000 | Sensor data fan-out to replicas |
| Processing (x3) | Python 3.11 / FastAPI + NumPy | 8000 | FFT analysis, event classification, persistence |
| Gateway | Nginx | 80 (ext) / 8080 (int) | Load balancing, reverse proxy |
| Frontend | Vue 3 / Vite / Nginx | 80 | Real-time monitoring dashboard |
| Database | PostgreSQL 16 | 5432 | Event persistence |

## Technology Stack

- **Backend**: Python 3.11, FastAPI, Uvicorn
- **Signal Processing**: NumPy (FFT)
- **Database**: PostgreSQL 16 with asyncpg
- **Message Distribution**: Custom WebSocket-based broker (no external MQ)
- **Gateway**: Nginx with upstream health checks
- **Frontend**: Vue 3 (Composition API), Vite, Vue Router
- **Containerization**: Docker, Docker Compose

## Data Flow

1. **Ingestion**: The broker connects to all simulator sensors via WebSocket and receives measurements at 20 Hz per sensor.
2. **Distribution**: Each measurement is broadcast to all connected processing replicas via WebSocket.
3. **Analysis**: Each replica maintains a sliding window of 256 samples per sensor. When the window is full, an FFT is applied to extract the dominant frequency.
4. **Classification**: The dominant frequency determines the event type:
   - Earthquake: 0.5 ≤ f < 3.0 Hz
   - Conventional Explosion: 3.0 ≤ f < 8.0 Hz
   - Nuclear-like: f ≥ 8.0 Hz
5. **Persistence**: Events above the amplitude threshold are stored in PostgreSQL. Deduplication prevents the same event from being stored multiple times across replicas.
6. **Delivery**: The frontend receives events in real-time via SSE and displays them on the dashboard.

## Fault Tolerance

- **Replica shutdown**: Each processing replica subscribes to the simulator's SSE control stream. Upon receiving `{"command":"SHUTDOWN"}`, the replica terminates immediately via `os._exit(0)`.
- **Auto-restart**: Docker Compose `restart: unless-stopped` ensures terminated replicas are restarted automatically.
- **Gateway failover**: Nginx upstream health checks (`max_fails=3, fail_timeout=10s`) automatically exclude unresponsive replicas from the load balancer pool.
- **System continuity**: As long as at least one processing replica is alive, the system continues to detect and serve events.

## Duplicate Prevention

Multiple replicas may detect the same event from the same sensor data. Before inserting, each replica checks if an event with the same `sensor_id` and `event_type` was already recorded within the last 10 seconds. If so, the insertion is skipped.

## Database Schema

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    sensor_id VARCHAR(50) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    dominant_frequency FLOAT NOT NULL,
    amplitude FLOAT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    detected_by VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_sensor_time ON events(sensor_id, timestamp);
CREATE INDEX idx_events_type ON events(event_type);
```

## How to Run

```bash
cd source/
docker compose up --build
```

The dashboard is accessible at http://localhost:80.

## API Endpoints (Processing Service)

| Method | Path | Description |
|---|---|---|
| GET | /health | Health check |
| GET | /api/events | List events (query: sensor_id, event_type, limit, offset) |
| GET | /api/events/stream | SSE stream of real-time events |
| GET | /api/sensors | List known sensors |

## Configuration

| Variable | Default | Description |
|---|---|---|
| SAMPLING_RATE_HZ | 20 | Simulator sampling rate |
| WINDOW_SIZE | 256 | FFT sliding window size |
| AMPLITUDE_THRESHOLD | 0.5 | Minimum amplitude for event detection |
| AUTO_SHUTDOWN_ENABLED | true | Enable random replica shutdowns |
| AUTO_SHUTDOWN_MIN_SECONDS | 30 | Min delay before auto shutdown |
| AUTO_SHUTDOWN_MAX_SECONDS | 90 | Max delay before auto shutdown |
