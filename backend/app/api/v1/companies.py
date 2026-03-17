from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.models.company import Company
from app.models.project import Project
from app.schemas.company import CompanyCreate, CompanyOut, ProjectCreate, ProjectOut
from app.api.deps import get_current_user, require_operator

router = APIRouter(tags=["辅助数据"])


@router.get("/companies", response_model=list[CompanyOut])
async def list_companies(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
):
    result = await db.execute(select(Company).order_by(Company.id))
    return result.scalars().all()


@router.post("/companies", response_model=CompanyOut, status_code=status.HTTP_201_CREATED)
async def create_company(
    body: CompanyCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_operator)],
):
    existing = await db.execute(select(Company).where(Company.name == body.name))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="单位名称已存在")
    company = Company(name=body.name)
    db.add(company)
    await db.flush()
    await db.refresh(company)
    return company


@router.get("/projects", response_model=list[ProjectOut])
async def list_projects(
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(get_current_user)],
    company_id: int | None = Query(None),
):
    query = select(Project).order_by(Project.id)
    if company_id is not None:
        query = query.where(Project.company_id == company_id)
    result = await db.execute(query)
    projects = result.scalars().all()
    items = []
    for p in projects:
        out = ProjectOut.model_validate(p)
        out.company_name = p.company.name if p.company else None
        items.append(out)
    return items


@router.post("/projects", response_model=ProjectOut, status_code=status.HTTP_201_CREATED)
async def create_project(
    body: ProjectCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    _: Annotated[User, Depends(require_operator)],
):
    project = Project(name=body.name, company_id=body.company_id)
    db.add(project)
    await db.flush()
    await db.refresh(project)
    out = ProjectOut.model_validate(project)
    if project.company:
        out.company_name = project.company.name
    return out
