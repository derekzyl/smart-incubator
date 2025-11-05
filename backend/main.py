"""
Smart Incubator Backend API
FastAPI server for real-time incubator monitoring and control
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, BackgroundTasks, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional, Dict
from datetime import datetime, timedelta
import asyncio
import json
import os
from contextlib import asynccontextmanager

# Database imports (using SQLAlchemy for now, can be swapped for asyncpg)
from sqlalchemy import create_engine, Column, String, Float, Boolean, Integer, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.sql import func
import uuid

# Redis for WebSocket connections and caching
try:
    import redis.asyncio as redis
except ImportError:
    import redis
    redis.asyncio = None

# Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./incubator.db")
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

# Database setup
Base = declarative_base()

class Incubator(Base):
    __tablename__ = "incubators"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False)
    device_id = Column(String, unique=True)
    name = Column(String(100))
    egg_type = Column(String(50))
    hatch_date = Column(DateTime)
    target_temp = Column(Float, default=37.5)
    target_humidity = Column(Float, default=55.0)
    turn_interval_hours = Column(Integer, default=4)
    created_at = Column(DateTime, default=datetime.utcnow)

class SensorReading(Base):
    __tablename__ = "sensor_readings"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    time = Column(DateTime, default=datetime.utcnow, index=True)
    incubator_id = Column(String, nullable=False, index=True)
    temp_1 = Column(Float)
    temp_2 = Column(Float)
    temp_sht31 = Column(Float)
    humidity_sht31 = Column(Float)
    heater_state = Column(Boolean)
    humidifier_state = Column(Boolean)
    fan_speed = Column(Integer)

class TurnEvent(Base):
    __tablename__ = "turn_events"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    incubator_id = Column(String, nullable=False, index=True)
    turn_time = Column(DateTime, default=datetime.utcnow)
    angle_degrees = Column(Integer)
    duration_seconds = Column(Integer)

class Alert(Base):
    __tablename__ = "alerts"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    incubator_id = Column(String, nullable=False, index=True)
    alert_type = Column(String(50))
    severity = Column(String(20))
    message = Column(Text)
    resolved = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

# Create database
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {})
Base.metadata.create_all(bind=engine)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Redis connection pool
redis_pool = None
if redis.asyncio:
    redis_pool = None  # Will be initialized in lifespan

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, List[WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, incubator_id: str):
        await websocket.accept()
        if incubator_id not in self.active_connections:
            self.active_connections[incubator_id] = []
        self.active_connections[incubator_id].append(websocket)
    
    def disconnect(self, websocket: WebSocket, incubator_id: str):
        if incubator_id in self.active_connections:
            self.active_connections[incubator_id].remove(websocket)
    
    async def broadcast(self, incubator_id: str, data: dict):
        if incubator_id in self.active_connections:
            disconnected = []
            for connection in self.active_connections[incubator_id]:
                try:
                    await connection.send_json(data)
                except:
                    disconnected.append(connection)
            for conn in disconnected:
                self.disconnect(conn, incubator_id)

manager = ConnectionManager()

# Pydantic models
class SensorData(BaseModel):
    incubator_id: str
    temp_1: float
    temp_2: float
    temp_sht31: float
    humidity_sht31: float
    heater_state: bool
    humidifier_state: bool
    fan_speed: int = 0
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class IncubatorConfig(BaseModel):
    name: str
    egg_type: str
    hatch_date: str
    target_temp: float = 37.5
    target_humidity: float = 55.0
    turn_interval_hours: int = 4

class IncubatorResponse(BaseModel):
    id: str
    user_id: str
    device_id: Optional[str]
    name: str
    egg_type: str
    hatch_date: Optional[datetime]
    target_temp: float
    target_humidity: float
    turn_interval_hours: int
    created_at: datetime

    class Config:
        from_attributes = True

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Lifespan context
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    global redis_pool
    if redis.asyncio:
        try:
            redis_pool = await redis.asyncio.from_url(REDIS_URL, decode_responses=True)
        except:
            redis_pool = None
            print("Warning: Redis not available, using in-memory cache")
    yield
    # Shutdown
    if redis_pool:
        await redis_pool.close()

# FastAPI app
app = FastAPI(
    title="Smart Incubator API",
    description="Backend API for precision egg incubator monitoring and control",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Helper functions
async def check_anomalies(sensor_data: SensorData, db: Session):
    """Detect temperature/humidity anomalies"""
    incubator = db.query(Incubator).filter(Incubator.id == sensor_data.incubator_id).first()
    if not incubator:
        return
    
    temps = [sensor_data.temp_1, sensor_data.temp_2, sensor_data.temp_sht31]
    avg_temp = sum(temps) / len(temps)
    temp_spread = max(temps) - min(temps)
    
    # Check sensor disagreement
    if temp_spread > 2.0:
        alert = Alert(
            incubator_id=sensor_data.incubator_id,
            alert_type="sensor_mismatch",
            severity="warning",
            message=f"Temperature sensors show {temp_spread:.1f}°C difference"
        )
        db.add(alert)
        db.commit()
        db.refresh(alert)
        await manager.broadcast(sensor_data.incubator_id, {
            "type": "alert",
            "alert": {
                "id": alert.id,
                "incubator_id": alert.incubator_id,
                "alert_type": alert.alert_type,
                "severity": alert.severity,
                "message": alert.message,
                "resolved": alert.resolved,
                "created_at": alert.created_at.isoformat()
            }
        })
    
    # Temperature checks
    if avg_temp < incubator.target_temp - 2.0:
        alert = Alert(
            incubator_id=sensor_data.incubator_id,
            alert_type="temp_low",
            severity="critical",
            message=f"Temperature dropped to {avg_temp:.1f}°C (target: {incubator.target_temp}°C)"
        )
        db.add(alert)
        db.commit()
        db.refresh(alert)
        await manager.broadcast(sensor_data.incubator_id, {
            "type": "alert",
            "alert": {
                "id": alert.id,
                "incubator_id": alert.incubator_id,
                "alert_type": alert.alert_type,
                "severity": alert.severity,
                "message": alert.message,
                "resolved": alert.resolved,
                "created_at": alert.created_at.isoformat()
            }
        })
    elif avg_temp > incubator.target_temp + 2.0:
        alert = Alert(
            incubator_id=sensor_data.incubator_id,
            alert_type="temp_high",
            severity="critical",
            message=f"Temperature rose to {avg_temp:.1f}°C (target: {incubator.target_temp}°C)"
        )
        db.add(alert)
        db.commit()
        db.refresh(alert)
        await manager.broadcast(sensor_data.incubator_id, {
            "type": "alert",
            "alert": {
                "id": alert.id,
                "incubator_id": alert.incubator_id,
                "alert_type": alert.alert_type,
                "severity": alert.severity,
                "message": alert.message,
                "resolved": alert.resolved,
                "created_at": alert.created_at.isoformat()
            }
        })
    
    # Humidity checks
    if sensor_data.humidity_sht31 < incubator.target_humidity - 10:
        alert = Alert(
            incubator_id=sensor_data.incubator_id,
            alert_type="humidity_low",
            severity="warning",
            message=f"Humidity at {sensor_data.humidity_sht31:.1f}% (target: {incubator.target_humidity}%)"
        )
        db.add(alert)
        db.commit()
        db.refresh(alert)
        await manager.broadcast(sensor_data.incubator_id, {
            "type": "alert",
            "alert": {
                "id": alert.id,
                "incubator_id": alert.incubator_id,
                "alert_type": alert.alert_type,
                "severity": alert.severity,
                "message": alert.message,
                "resolved": alert.resolved,
                "created_at": alert.created_at.isoformat()
            }
        })
    elif sensor_data.humidity_sht31 > incubator.target_humidity + 15:
        alert = Alert(
            incubator_id=sensor_data.incubator_id,
            alert_type="humidity_high",
            severity="warning",
            message=f"Humidity at {sensor_data.humidity_sht31:.1f}% (target: {incubator.target_humidity}%)"
        )
        db.add(alert)
        db.commit()
        db.refresh(alert)
        await manager.broadcast(sensor_data.incubator_id, {
            "type": "alert",
            "alert": {
                "id": alert.id,
                "incubator_id": alert.incubator_id,
                "alert_type": alert.alert_type,
                "severity": alert.severity,
                "message": alert.message,
                "resolved": alert.resolved,
                "created_at": alert.created_at.isoformat()
            }
        })

# API Endpoints

@app.get("/")
async def root():
    return {"message": "Smart Incubator API", "version": "1.0.0"}

@app.post("/api/v1/sensors/upload")
async def upload_sensor_data(
    data: SensorData,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Receive sensor readings from ESP32"""
    # Store in database
    reading = SensorReading(
        incubator_id=data.incubator_id,
        time=data.timestamp,
        temp_1=data.temp_1,
        temp_2=data.temp_2,
        temp_sht31=data.temp_sht31,
        humidity_sht31=data.humidity_sht31,
        heater_state=data.heater_state,
        humidifier_state=data.humidifier_state,
        fan_speed=data.fan_speed
    )
    db.add(reading)
    db.commit()
    
    # Cache latest reading in Redis
    if redis_pool:
        await redis_pool.setex(
            f"incubator:{data.incubator_id}:latest",
            300,  # 5 minutes TTL
            json.dumps(data.dict(), default=str)
        )
    
    # Broadcast to WebSocket clients
    await manager.broadcast(data.incubator_id, {
        "type": "sensor_update",
        "data": data.dict()
    })
    
    # Check for anomalies in background
    background_tasks.add_task(check_anomalies, data, db)
    
    return {"status": "success", "timestamp": data.timestamp}

@app.websocket("/ws/live/{incubator_id}")
async def websocket_endpoint(websocket: WebSocket, incubator_id: str):
    """Push real-time sensor data to Flutter app"""
    await manager.connect(websocket, incubator_id)
    try:
        # Send latest cached data immediately
        if redis_pool:
            latest = await redis_pool.get(f"incubator:{incubator_id}:latest")
            if latest:
                await websocket.send_json({"type": "sensor_update", "data": json.loads(latest)})
        
        # Keep connection alive and send periodic updates
        while True:
            await asyncio.sleep(5)
            if redis_pool:
                latest = await redis_pool.get(f"incubator:{incubator_id}:latest")
                if latest:
                    await websocket.send_json({"type": "sensor_update", "data": json.loads(latest)})
    except WebSocketDisconnect:
        manager.disconnect(websocket, incubator_id)

@app.get("/api/v1/sensors/history/{incubator_id}")
async def get_sensor_history(
    incubator_id: str,
    start_date: datetime,
    end_date: datetime,
    resolution: str = "5min",
    db: Session = Depends(get_db)
):
    """Returns time-aggregated sensor data for charting"""
    # For SQLite, we'll do simple aggregation
    # In production with TimescaleDB, use time_bucket
    readings = db.query(SensorReading).filter(
        SensorReading.incubator_id == incubator_id,
        SensorReading.time >= start_date,
        SensorReading.time <= end_date
    ).order_by(SensorReading.time).all()
    
    # Simple aggregation by resolution
    resolution_minutes = {"1min": 1, "5min": 5, "1hour": 60}.get(resolution, 5)
    
    aggregated = {}
    for reading in readings:
        # Round time to resolution
        time_key = reading.time.replace(second=0, microsecond=0)
        minute = (time_key.minute // resolution_minutes) * resolution_minutes
        time_key = time_key.replace(minute=minute)
        
        if time_key not in aggregated:
            aggregated[time_key] = {
                "time": time_key.isoformat(),
                "temp_1": [],
                "temp_2": [],
                "temp_sht31": [],
                "humidity_sht31": []
            }
        
        if reading.temp_1:
            aggregated[time_key]["temp_1"].append(reading.temp_1)
        if reading.temp_2:
            aggregated[time_key]["temp_2"].append(reading.temp_2)
        if reading.temp_sht31:
            aggregated[time_key]["temp_sht31"].append(reading.temp_sht31)
        if reading.humidity_sht31:
            aggregated[time_key]["humidity_sht31"].append(reading.humidity_sht31)
    
    # Calculate averages
    result = []
    for time_key, data in sorted(aggregated.items()):
        result.append({
            "time": data["time"],
            "avg_temp_1": sum(data["temp_1"]) / len(data["temp_1"]) if data["temp_1"] else None,
            "avg_temp_2": sum(data["temp_2"]) / len(data["temp_2"]) if data["temp_2"] else None,
            "avg_temp_sht31": sum(data["temp_sht31"]) / len(data["temp_sht31"]) if data["temp_sht31"] else None,
            "avg_humidity": sum(data["humidity_sht31"]) / len(data["humidity_sht31"]) if data["humidity_sht31"] else None,
        })
    
    return {"data": result}

@app.get("/api/v1/analytics/hatch-prediction/{incubator_id}")
async def predict_hatch(incubator_id: str, db: Session = Depends(get_db)):
    """Estimates hatch success probability"""
    incubator = db.query(Incubator).filter(Incubator.id == incubator_id).first()
    if not incubator:
        raise HTTPException(status_code=404, detail="Incubator not found")
    
    # Fetch last 21 days of data
    cutoff_date = datetime.utcnow() - timedelta(days=21)
    readings = db.query(SensorReading).filter(
        SensorReading.incubator_id == incubator_id,
        SensorReading.time >= cutoff_date
    ).all()
    
    if not readings:
        return {
            "predicted_success_rate": 0.85,
            "days_remaining": None,
            "temp_stability_score": 100,
            "humidity_score": 100,
            "turn_compliance": 100,
            "recommendations": ["No data available yet"]
        }
    
    # Calculate metrics
    import numpy as np
    temps_1 = [r.temp_1 for r in readings if r.temp_1]
    temps_2 = [r.temp_2 for r in readings if r.temp_2]
    temps_sht31 = [r.temp_sht31 for r in readings if r.temp_sht31]
    all_temps = temps_1 + temps_2 + temps_sht31
    
    temp_stability = float(np.std(all_temps)) if all_temps else 0.0
    avg_humidity = float(np.mean([r.humidity_sht31 for r in readings if r.humidity_sht31])) if readings else 55.0
    
    turn_count = db.query(TurnEvent).filter(
        TurnEvent.incubator_id == incubator_id,
        TurnEvent.turn_time >= cutoff_date
    ).count()
    
    # Simple heuristic model
    base_success = 0.85
    
    if temp_stability > 0.5:
        base_success -= 0.15
    if avg_humidity < 45 or avg_humidity > 70:
        base_success -= 0.10
    expected_turns = (21 * 24) / incubator.turn_interval_hours
    if turn_count < expected_turns * 0.9:
        base_success -= 0.05
    
    days_remaining = None
    if incubator.hatch_date:
        days_remaining = (incubator.hatch_date.date() - datetime.utcnow().date()).days
    
    recommendations = []
    if temp_stability > 0.5:
        recommendations.append("High temperature fluctuation detected. Check insulation and heater placement.")
    if avg_humidity < 45:
        recommendations.append("Humidity too low. Increase water tray surface area or misting frequency.")
    elif avg_humidity > 70:
        recommendations.append("Humidity too high. Improve ventilation or reduce misting.")
    if not recommendations:
        recommendations.append("All parameters optimal. Continue monitoring.")
    
    return {
        "predicted_success_rate": max(0.0, base_success),
        "days_remaining": days_remaining,
        "temp_stability_score": max(0, 100 - int(temp_stability * 100)),
        "humidity_score": max(0, 100 - int(abs(55 - avg_humidity) * 2)),
        "turn_compliance": int((turn_count / expected_turns * 100) if expected_turns > 0 else 100),
        "recommendations": recommendations
    }

@app.post("/api/v1/alerts/trigger")
async def trigger_alert(
    incubator_id: str,
    alert_type: str,
    severity: str,
    message: str,
    db: Session = Depends(get_db)
):
    """Create alert and send notifications"""
    alert = Alert(
        incubator_id=incubator_id,
        alert_type=alert_type,
        severity=severity,
        message=message
    )
    db.add(alert)
    db.commit()
    
    # Broadcast to WebSocket clients
    await manager.broadcast(incubator_id, {
        "type": "alert",
        "alert": {
            "id": alert.id,
            "alert_type": alert_type,
            "severity": severity,
            "message": message,
            "created_at": alert.created_at.isoformat()
        }
    })
    
    return {"alert_id": alert.id, "status": "created"}

@app.post("/api/v1/incubator", response_model=IncubatorResponse)
async def create_incubator(config: IncubatorConfig, user_id: str = "default_user", db: Session = Depends(get_db)):
    """Create a new incubator configuration"""
    hatch_date_obj = datetime.fromisoformat(config.hatch_date.replace("Z", "+00:00"))
    
    incubator = Incubator(
        user_id=user_id,
        name=config.name,
        egg_type=config.egg_type,
        hatch_date=hatch_date_obj,
        target_temp=config.target_temp,
        target_humidity=config.target_humidity,
        turn_interval_hours=config.turn_interval_hours
    )
    db.add(incubator)
    db.commit()
    db.refresh(incubator)
    
    return incubator

@app.get("/api/v1/incubator/{incubator_id}", response_model=IncubatorResponse)
async def get_incubator(incubator_id: str, db: Session = Depends(get_db)):
    """Get incubator configuration"""
    incubator = db.query(Incubator).filter(Incubator.id == incubator_id).first()
    if not incubator:
        raise HTTPException(status_code=404, detail="Incubator not found")
    return incubator

@app.put("/api/v1/incubator/{incubator_id}", response_model=IncubatorResponse)
async def update_config(incubator_id: str, config: IncubatorConfig, db: Session = Depends(get_db)):
    """Update incubator settings"""
    incubator = db.query(Incubator).filter(Incubator.id == incubator_id).first()
    if not incubator:
        raise HTTPException(status_code=404, detail="Incubator not found")
    
    incubator.name = config.name
    incubator.egg_type = config.egg_type
    incubator.hatch_date = datetime.fromisoformat(config.hatch_date.replace("Z", "+00:00"))
    incubator.target_temp = config.target_temp
    incubator.target_humidity = config.target_humidity
    incubator.turn_interval_hours = config.turn_interval_hours
    
    db.commit()
    db.refresh(incubator)
    
    # Broadcast config update
    await manager.broadcast(incubator_id, {
        "type": "config_update",
        "config": {
            "target_temp": config.target_temp,
            "target_humidity": config.target_humidity,
            "turn_interval_hours": config.turn_interval_hours
        }
    })
    
    return incubator

@app.post("/api/v1/turns/record")
async def record_turn(
    incubator_id: str,
    angle_degrees: int,
    duration_seconds: int,
    db: Session = Depends(get_db)
):
    """Record an egg turning event"""
    turn_event = TurnEvent(
        incubator_id=incubator_id,
        angle_degrees=angle_degrees,
        duration_seconds=duration_seconds
    )
    db.add(turn_event)
    db.commit()
    
    await manager.broadcast(incubator_id, {
        "type": "turn_event",
        "turn": {
            "turn_time": turn_event.turn_time.isoformat(),
            "angle_degrees": angle_degrees,
            "duration_seconds": duration_seconds
        }
    })
    
    return {"status": "recorded", "turn_id": turn_event.id}

@app.get("/api/v1/turns/{incubator_id}")
async def get_turn_history(incubator_id: str, limit: int = 50, db: Session = Depends(get_db)):
    """Get turn history for an incubator"""
    turns = db.query(TurnEvent).filter(
        TurnEvent.incubator_id == incubator_id
    ).order_by(TurnEvent.turn_time.desc()).limit(limit).all()
    
    return {
        "turns": [
            {
                "id": t.id,
                "turn_time": t.turn_time.isoformat(),
                "angle_degrees": t.angle_degrees,
                "duration_seconds": t.duration_seconds
            }
            for t in turns
        ]
    }

@app.get("/api/v1/alerts/{incubator_id}")
async def get_alerts(incubator_id: str, resolved: Optional[bool] = None, db: Session = Depends(get_db)):
    """Get alerts for an incubator"""
    query = db.query(Alert).filter(Alert.incubator_id == incubator_id)
    if resolved is not None:
        query = query.filter(Alert.resolved == resolved)
    
    alerts = query.order_by(Alert.created_at.desc()).limit(100).all()
    
    return {
        "alerts": [
            {
                "id": a.id,
                "alert_type": a.alert_type,
                "severity": a.severity,
                "message": a.message,
                "resolved": a.resolved,
                "created_at": a.created_at.isoformat()
            }
            for a in alerts
        ]
    }

@app.patch("/api/v1/alerts/{alert_id}/resolve")
async def resolve_alert(alert_id: str, db: Session = Depends(get_db)):
    """Mark an alert as resolved"""
    alert = db.query(Alert).filter(Alert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alert not found")
    
    alert.resolved = True
    db.commit()
    
    return {"status": "resolved", "alert_id": alert_id}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
