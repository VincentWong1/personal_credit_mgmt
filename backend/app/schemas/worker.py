from datetime import datetime
from pydantic import BaseModel
from typing import Optional


class WorkerCreate(BaseModel):
    id_card_number: str
    name: str
    gender: Optional[str] = None  # 可自动从身份证号推断


class WorkerUpdate(BaseModel):
    name: Optional[str] = None


class WorkerOut(BaseModel):
    id: int
    id_card_number: str
    name: str
    gender: str
    created_by: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    risk_event_count: Optional[int] = None

    model_config = {"from_attributes": True}


