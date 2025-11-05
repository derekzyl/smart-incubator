# Smart Incubator Backend API

FastAPI backend for the Smart Incubator system providing real-time monitoring, data logging, and analytics.

## Features

- Real-time sensor data ingestion
- WebSocket support for live updates
- Historical data retrieval with time-series aggregation
- Hatch success prediction algorithm
- Alert management with anomaly detection
- Egg turning event logging

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Configure environment variables (copy `.env.example` to `.env` and update):
```bash
cp .env.example .env
```

3. Run the server:
```bash
python main.py
```

Or with uvicorn:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## API Endpoints

### Sensor Data
- `POST /api/v1/sensors/upload` - Upload sensor readings from ESP32
- `GET /api/v1/sensors/history/{incubator_id}` - Get historical sensor data
- `WebSocket /ws/live/{incubator_id}` - Real-time sensor updates

### Incubator Management
- `POST /api/v1/incubator` - Create new incubator
- `GET /api/v1/incubator/{incubator_id}` - Get incubator configuration
- `PUT /api/v1/incubator/{incubator_id}` - Update configuration

### Analytics
- `GET /api/v1/analytics/hatch-prediction/{incubator_id}` - Get hatch success prediction

### Alerts
- `POST /api/v1/alerts/trigger` - Create alert
- `GET /api/v1/alerts/{incubator_id}` - Get alerts
- `PATCH /api/v1/alerts/{alert_id}/resolve` - Resolve alert

### Egg Turning
- `POST /api/v1/turns/record` - Record turn event
- `GET /api/v1/turns/{incubator_id}` - Get turn history

## Database

The default configuration uses SQLite for easy setup. For production, use PostgreSQL with TimescaleDB for better time-series performance.

To use PostgreSQL:
1. Install PostgreSQL and TimescaleDB
2. Update `DATABASE_URL` in `.env`
3. Run migrations (if using Alembic)

## Development

The API documentation is available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

