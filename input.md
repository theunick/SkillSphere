# SeismicWatch — System Overview

## Project Description

SeismicWatch is a distributed, fault-tolerant seismic analysis platform designed to ingest real-time seismic sensor data, perform frequency-domain analysis, classify seismic events, and provide a real-time monitoring dashboard for a military command center scenario.

The system operates under the constraint that the command center (neutral region) can only host lightweight routing services, while processing happens in geographically distributed data centers that may be subject to sudden failure.

## Architecture Overview

```
┌─────────────┐     ┌─────────────┐     ┌──────────────────┐     ┌────────────┐
│  Simulator   │────▶│   Broker    │────▶│  Processing (x3) │────▶│ PostgreSQL │
│  (sensors)   │     │  (fan-out)  │     │  (FFT + classify)│     │   (events) │
└─────────────┘     └─────────────┘     └──────────────────┘     └────────────┘
       │                                        │
       │ SSE /api/control                       │ REST + SSE
       └────────────────────────────────────────┤
                                                ▼
                                        ┌──────────────┐     ┌────────────┐
                                        │   Gateway    │────▶│  Frontend  │
                                        │   (Nginx)    │     │   (Vue 3)  │
                                        └──────────────┘     └────────────┘
```

## Standard Event Schema

```json
{
  "id": "integer (auto-generated)",
  "sensor_id": "string — identifier of the originating sensor",
  "event_type": "string — one of: earthquake, conventional_explosion, nuclear_like",
  "dominant_frequency": "float — dominant frequency in Hz detected by FFT",
  "amplitude": "float — amplitude of the dominant frequency component",
  "timestamp": "ISO-8601 UTC — time of the measurement window",
  "detected_by": "string — replica ID that detected the event",
  "created_at": "ISO-8601 UTC — time of database insertion"
}
```

## Rule Model

Event classification is based on the dominant frequency component extracted via FFT from a sliding window of 256 samples:

| Event Type | Frequency Range | Description |
|---|---|---|
| Earthquake | 0.5 ≤ f < 3.0 Hz | Low-frequency ground motion |
| Conventional Explosion | 3.0 ≤ f < 8.0 Hz | Mid-frequency blast signature |
| Nuclear-like Event | f ≥ 8.0 Hz | High-frequency seismic signature |

Detection threshold: amplitude ≥ 0.5 mm/s (configurable via `AMPLITUDE_THRESHOLD`).

Deduplication rule: an event is considered duplicate if another event with the same `sensor_id` and `event_type` was recorded within the last 10 seconds.

---

## User Stories

### Epic 1: Sensor Data Ingestion

**US-01** As a system operator, I want the broker to automatically discover all available sensors on startup, so that no manual configuration is needed.

**US-02** As a system operator, I want the broker to maintain persistent WebSocket connections to all sensors, so that no measurement data is lost.

**US-03** As a system operator, I want the broker to automatically reconnect to sensors if a connection drops, so the system is resilient to transient network issues.

**US-04** As a system operator, I want the broker to broadcast each measurement to all connected processing replicas, so that every replica has the full data stream.

**US-05** As a system operator, I want the broker to expose a health endpoint, so I can monitor its operational status.

### Epic 2: Signal Processing & Event Detection

**US-06** As a data analyst, I want each processing replica to maintain a sliding window of the last 256 samples per sensor, so that frequency analysis has sufficient data.

**US-07** As a data analyst, I want the system to apply FFT on each full window, so that dominant frequency components are extracted.

**US-08** As a data analyst, I want detected events to be classified by frequency band (earthquake, conventional explosion, nuclear-like), so that threat types are immediately identifiable.

**US-09** As a data analyst, I want event detection to use a configurable amplitude threshold, so that noise is filtered out.

**US-10** As a system operator, I want each processing replica to have a unique identifier, so I can trace which replica detected each event.

### Epic 3: Fault Tolerance & Replica Management

**US-11** As a system operator, I want each processing replica to listen to the simulator control stream, so that shutdown commands are received.

**US-12** As a system operator, I want a replica to terminate itself upon receiving a SHUTDOWN command, so that failure simulation works correctly.

**US-13** As a system operator, I want the system to continue operating when one or more replicas fail, so that the service remains available.

**US-14** As a system operator, I want Docker to automatically restart terminated replicas, so the system self-heals.

**US-15** As a system operator, I want the gateway to route requests only to healthy replicas, so that failed replicas don't receive traffic.

### Epic 4: Persistence & Deduplication

**US-16** As a data analyst, I want detected events to be persisted in PostgreSQL, so that historical data is available for analysis.

**US-17** As a data analyst, I want the system to prevent duplicate events (same sensor, same type, within 10s), so that redundant detections from multiple replicas don't pollute the database.

**US-18** As a data analyst, I want events to include metadata (sensor_id, event_type, frequency, amplitude, timestamp, replica_id), so that each event is fully traceable.

### Epic 5: Gateway & Routing

**US-19** As a system operator, I want a single entry point (gateway) for all client requests, so that the internal architecture is abstracted.

**US-20** As a system operator, I want the gateway to load-balance requests across processing replicas using least-connections, so that load is evenly distributed.

**US-21** As a system operator, I want the gateway to automatically exclude unhealthy replicas, so that requests are not sent to failed nodes.

### Epic 6: Real-Time Dashboard

**US-22** As a command center operator, I want to see detected events in real-time on a dashboard, so that I can react immediately to threats.

**US-23** As a command center operator, I want to see event statistics (count by type, latest timestamp), so I have an at-a-glance overview.

**US-24** As a command center operator, I want to browse historical events with pagination, so I can review past activity.

**US-25** As a command center operator, I want to filter events by sensor and event type, so I can focus on specific areas or threats.

### Epic 7: Deployment & Reproducibility

**US-26** As an instructor, I want the entire system to start with `docker compose up`, so that no manual setup is required.

**US-27** As an instructor, I want each service to have its own Dockerfile, so that services are independently buildable.
