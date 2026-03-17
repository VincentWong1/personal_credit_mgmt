from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserOut
from app.api.deps import require_admin, hash_password

router = APIRouter(prefix="/users", tags=["用户管理"])


@router.get("", response_model=dict)
async def list_users(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    total_result = await db.execute(select(func.count(User.id)))
    total = total_result.scalar()
    result = await db.execute(
        select(User).order_by(User.id).offset((page - 1) * page_size).limit(page_size)
    )
    users = result.scalars().all()
    return {
        "items": [UserOut.model_validate(u) for u in users],
        "total": total,
        "page": page,
        "page_size": page_size,
        "pages": (total + page_size - 1) // page_size,
    }


@router.post("", response_model=UserOut, status_code=status.HTTP_201_CREATED)
async def create_user(
    body: UserCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
):
    existing = await db.execute(select(User).where(User.username == body.username))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="用户名已存在")
    if body.role not in ("admin", "operator", "user"):
        raise HTTPException(status_code=400, detail="无效的角色")
    user = User(
        username=body.username,
        hashed_password=hash_password(body.password),
        display_name=body.display_name,
        role=body.role,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return user


@router.get("/{user_id}", response_model=UserOut)
async def get_user(
    user_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return user


@router.put("/{user_id}", response_model=UserOut)
async def update_user(
    user_id: int,
    body: UserUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_admin)],
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    if body.display_name is not None:
        user.display_name = body.display_name
    if body.role is not None:
        if body.role not in ("admin", "operator", "user"):
            raise HTTPException(status_code=400, detail="无效的角色")
        user.role = body.role
    if body.is_active is not None:
        user.is_active = body.is_active
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return user


@router.delete("/{user_id}")
async def delete_user(
    user_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    admin: Annotated[User, Depends(require_admin)],
):
    if user_id == admin.id:
        raise HTTPException(status_code=400, detail="不能停用自己的账户")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    user.is_active = False
    db.add(user)
    return {"detail": "用户已停用"}
