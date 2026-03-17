from datetime import datetime
from sqlalchemy import String, Integer, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Worker(Base):
    __tablename__ = "workers"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    id_card_number: Mapped[str] = mapped_column(String(18), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    gender: Mapped[str] = mapped_column(String(4), nullable=False)
    created_by: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    risk_events = relationship("RiskEvent", back_populates="worker", lazy="selectin")
    creator = relationship("User", lazy="selectin")
