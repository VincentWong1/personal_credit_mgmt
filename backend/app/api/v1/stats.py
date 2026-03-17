from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.worker import Worker
from app.models.risk_event import RiskEvent
from app.models.company import Company
from app.api.deps import get_current_user

router = APIRouter(prefix="/stats", tags=["统计"])


@router.get("/overview")
async def get_overview(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
):
    worker_count = (await db.execute(select(func.count(Worker.id)))).scalar()
    event_count = (await db.execute(select(func.count(RiskEvent.id)))).scalar()
    company_count = (await db.execute(select(func.count(Company.id)))).scalar()

    # Risk level distribution
    level_result = await db.execute(
        select(RiskEvent.risk_level, func.count(RiskEvent.id))
        .group_by(RiskEvent.risk_level)
    )
    risk_distribution = {row[0]: row[1] for row in level_result.all()}

    # Category distribution
    cat_result = await db.execute(
        select(RiskEvent.category, func.count(RiskEvent.id))
        .group_by(RiskEvent.category)
        .order_by(func.count(RiskEvent.id).desc())
        .limit(10)
    )
    category_distribution = [{"name": row[0], "count": row[1]} for row in cat_result.all()]

    return {
        "worker_count": worker_count,
        "event_count": event_count,
        "company_count": company_count,
        "risk_distribution": risk_distribution,
        "category_distribution": category_distribution,
    }
