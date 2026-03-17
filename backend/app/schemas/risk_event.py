from datetime import datetime, date
from pydantic import BaseModel
from typing import Optional


class RiskEventCreate(BaseModel):
    event_date: date
    risk_level: str
    category: str
    description: Optional[str] = None
    company_id: Optional[int] = None
    project_id: Optional[int] = None


class RiskEventUpdate(BaseModel):
    event_date: Optional[date] = None
    risk_level: Optional[str] = None
    category: Optional[str] = None
    description: Optional[str] = None
    company_id: Optional[int] = None
    project_id: Optional[int] = None


class RiskEventOut(BaseModel):
    id: int
    worker_id: int
    event_date: date
    risk_level: str
    category: str
    description: Optional[str] = None
    company_id: Optional[int] = None
    company_name: Optional[str] = None
    project_id: Optional[int] = None
    project_name: Optional[str] = None
    created_by: Optional[int] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class RiskCategoryCreate(BaseModel):
    name: str


class RiskCategoryOut(BaseModel):
    id: int
    name: str
    is_preset: bool

    model_config = {"from_attributes": True}
