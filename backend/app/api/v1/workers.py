from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models.user import User
from app.models.worker import Worker
from app.models.risk_event import RiskEvent
from app.schemas.worker import WorkerCreate, WorkerUpdate, WorkerOut
from app.api.deps import get_current_user, require_operator, require_admin
from app.utils.id_card import validate_id_card, extract_gender

router = APIRouter(prefix="/workers", tags=["工人管理"])


@router.get("", response_model=dict)
async def list_workers(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
    q: str = Query("", description="搜索姓名或身份证号"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    base_query = select(Worker)
    count_query = select(func.count(Worker.id))

    if q:
        filter_cond = or_(Worker.name.contains(q), Worker.id_card_number.contains(q))
        base_query = base_query.where(filter_cond)
        count_query = count_query.where(filter_cond)

    total_result = await db.execute(count_query)
    total = total_result.scalar()

    # Subquery to count risk events per worker
    event_count_subq = (
        select(RiskEvent.worker_id, func.count(RiskEvent.id).label("event_count"))
        .group_by(RiskEvent.worker_id)
        .subquery()
    )

    query = (
        base_query
        .outerjoin(event_count_subq, Worker.id == event_count_subq.c.worker_id)
        .add_columns(event_count_subq.c.event_count)
        .order_by(Worker.id.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(query)
    rows = result.all()

    items = []
    for row in rows:
        worker = row[0]
        event_count = row[1] or 0
        out = WorkerOut.model_validate(worker)
        out.risk_event_count = event_count
        items.append(out)

    return {
        "items": [item.model_dump() for item in items],
        "total": total,
        "page": page,
        "page_size": page_size,
        "pages": (total + page_size - 1) // page_size if total > 0 else 0,
    }


@router.post("", response_model=WorkerOut, status_code=status.HTTP_201_CREATED)
async def create_worker(
    body: WorkerCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(require_operator)],
):
    if not validate_id_card(body.id_card_number):
        raise HTTPException(status_code=400, detail="身份证号格式不正确")

    existing = await db.execute(select(Worker).where(Worker.id_card_number == body.id_card_number))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="该身份证号已存在")

    gender = body.gender or extract_gender(body.id_card_number)
    worker = Worker(
        id_card_number=body.id_card_number,
        name=body.name,
        gender=gender,
        created_by=current_user.id,
    )
    db.add(worker)
    await db.flush()
    await db.refresh(worker)
    return worker


@router.get("/{worker_id}", response_model=dict)
async def get_worker(
    worker_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
):
    result = await db.execute(
        select(Worker).where(Worker.id == worker_id).options(selectinload(Worker.risk_events))
    )
    worker = result.scalar_one_or_none()
    if not worker:
        raise HTTPException(status_code=404, detail="工人不存在")

    # Sort events by date desc
    events = sorted(worker.risk_events, key=lambda e: e.event_date, reverse=True)
    worker_out = WorkerOut.model_validate(worker)
    worker_out.risk_event_count = len(events)

    event_list = []
    for e in events:
        event_list.append({
            "id": e.id,
            "worker_id": e.worker_id,
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
        })

    return {
        **worker_out.model_dump(),
        "risk_events": event_list,
    }


@router.put("/{worker_id}", response_model=WorkerOut)
async def update_worker(
    worker_id: int,
    body: WorkerUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_operator)],
):
    result = await db.execute(select(Worker).where(Worker.id == worker_id))
    worker = result.scalar_one_or_none()
    if not worker:
        raise HTTPException(status_code=404, detail="工人不存在")
    if body.name is not None:
        worker.name = body.name
    db.add(worker)
    await db.flush()
    await db.refresh(worker)
    return worker


@router.delete("/{worker_id}")
async def delete_worker(
    worker_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
):
    result = await db.execute(select(Worker).where(Worker.id == worker_id))
    worker = result.scalar_one_or_none()
    if not worker:
        raise HTTPException(status_code=404, detail="工人不存在")
    await db.delete(worker)
    return {"detail": "工人已删除"}
