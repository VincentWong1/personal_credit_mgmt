from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import Optional

from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.worker import Worker
from app.models.risk_event import RiskEvent, RiskCategory
from app.schemas.risk_event import (
    RiskEventCreate, RiskEventUpdate, RiskEventOut,
    RiskCategoryCreate, RiskCategoryOut,
)
from app.api.deps import get_current_user, require_operator, require_admin

router = APIRouter(tags=["风险事件"])


def _event_to_out(e: RiskEvent) -> dict:
    return {
        "id": e.id,
        "worker_id": e.worker_id,
        "worker_name": e.worker.name if e.worker else None,
        "event_date": e.event_date.isoformat(),
        "risk_level": e.risk_level,
        "category": e.category,
        "description": e.description,
        "company_id": e.company_id,
        "company_name": e.company.name if e.company else None,
        "project_id": e.project_id,
        "project_name": e.project.name if e.project else None,
        "created_by": e.created_by,
        "created_at": e.created_at.isoformat() if e.created_at else None,
    }


@router.get("/events", response_model=dict)
async def list_all_events(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
    q: str = Query("", description="搜索工人姓名"),
    risk_level: Optional[str] = Query(None, description="按风险等级筛选"),
    category: Optional[str] = Query(None, description="按事件类别筛选"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    base_query = select(RiskEvent).join(Worker, RiskEvent.worker_id == Worker.id)
    count_query = select(func.count(RiskEvent.id)).join(Worker, RiskEvent.worker_id == Worker.id)

    if q:
        filter_cond = Worker.name.contains(q)
        base_query = base_query.where(filter_cond)
        count_query = count_query.where(filter_cond)
    if risk_level:
        base_query = base_query.where(RiskEvent.risk_level == risk_level)
        count_query = count_query.where(RiskEvent.risk_level == risk_level)
    if category:
        base_query = base_query.where(RiskEvent.category == category)
        count_query = count_query.where(RiskEvent.category == category)

    total = (await db.execute(count_query)).scalar()

    result = await db.execute(
        base_query
        .order_by(RiskEvent.event_date.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    events = result.scalars().all()

    return {
        "items": [_event_to_out(e) for e in events],
        "total": total,
        "page": page,
        "page_size": page_size,
        "pages": (total + page_size - 1) // page_size if total > 0 else 0,
    }


@router.get("/workers/{worker_id}/events", response_model=dict)
async def list_worker_events(
    worker_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    # Check worker exists
    worker_result = await db.execute(select(Worker).where(Worker.id == worker_id))
    if not worker_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="工人不存在")

    count_result = await db.execute(
        select(func.count(RiskEvent.id)).where(RiskEvent.worker_id == worker_id)
    )
    total = count_result.scalar()

    result = await db.execute(
        select(RiskEvent)
        .where(RiskEvent.worker_id == worker_id)
        .order_by(RiskEvent.event_date.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    events = result.scalars().all()

    return {
        "items": [_event_to_out(e) for e in events],
        "total": total,
        "page": page,
        "page_size": page_size,
        "pages": (total + page_size - 1) // page_size if total > 0 else 0,
    }


@router.post("/workers/{worker_id}/events", response_model=dict, status_code=status.HTTP_201_CREATED)
async def create_event(
    worker_id: int,
    body: RiskEventCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(require_operator)],
):
    worker_result = await db.execute(select(Worker).where(Worker.id == worker_id))
    if not worker_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="工人不存在")

    if body.risk_level not in ("low", "medium", "high", "critical"):
        raise HTTPException(status_code=400, detail="无效的风险等级")

    event = RiskEvent(
        worker_id=worker_id,
        event_date=body.event_date,
        risk_level=body.risk_level,
        category=body.category,
        description=body.description,
        company_id=body.company_id,
        project_id=body.project_id,
        created_by=current_user.id,
    )
    db.add(event)
    await db.flush()
    await db.refresh(event)
    return _event_to_out(event)


@router.get("/events/{event_id}", response_model=dict)
async def get_event(
    event_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
):
    result = await db.execute(select(RiskEvent).where(RiskEvent.id == event_id))
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="事件不存在")
    return _event_to_out(event)


@router.put("/events/{event_id}", response_model=dict)
async def update_event(
    event_id: int,
    body: RiskEventUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_operator)],
):
    result = await db.execute(select(RiskEvent).where(RiskEvent.id == event_id))
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="事件不存在")

    if body.event_date is not None:
        event.event_date = body.event_date
    if body.risk_level is not None:
        if body.risk_level not in ("low", "medium", "high", "critical"):
            raise HTTPException(status_code=400, detail="无效的风险等级")
        event.risk_level = body.risk_level
    if body.category is not None:
        event.category = body.category
    if body.description is not None:
        event.description = body.description
    if body.company_id is not None:
        event.company_id = body.company_id
    if body.project_id is not None:
        event.project_id = body.project_id

    db.add(event)
    await db.flush()
    await db.refresh(event)
    return _event_to_out(event)


@router.delete("/events/{event_id}")
async def delete_event(
    event_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
):
    result = await db.execute(select(RiskEvent).where(RiskEvent.id == event_id))
    event = result.scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="事件不存在")
    await db.delete(event)
    return {"detail": "事件已删除"}


# Risk Categories
@router.get("/risk-categories", response_model=list[RiskCategoryOut])
async def list_risk_categories(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
):
    result = await db.execute(select(RiskCategory).order_by(RiskCategory.id))
    return result.scalars().all()


@router.post("/risk-categories", response_model=RiskCategoryOut, status_code=status.HTTP_201_CREATED)
async def create_risk_category(
    body: RiskCategoryCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
):
    existing = await db.execute(select(RiskCategory).where(RiskCategory.name == body.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="类别已存在")
    cat = RiskCategory(name=body.name, is_preset=False)
    db.add(cat)
    await db.flush()
    await db.refresh(cat)
    return cat
