from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import engine, Base
from app.models import User, Worker, RiskEvent, RiskCategory, Company, Project
from app.api.v1 import auth, users, workers, events, companies, stats


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield


app = FastAPI(
    title="建筑工人信用风险管理系统",
    description="用于维护、管理和查询公司关联建筑工人的信用风险信息",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 允许所有来源（包括 ngrok）
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Mount API routes
app.include_router(auth.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")
app.include_router(workers.router, prefix="/api/v1")
app.include_router(events.router, prefix="/api/v1")
app.include_router(companies.router, prefix="/api/v1")
app.include_router(stats.router, prefix="/api/v1")


@app.get("/api/health")
async def health_check():
    return {"status": "ok"}
