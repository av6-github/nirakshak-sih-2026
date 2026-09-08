"""
NIRIKSHAK AI - Manufacturer Officer Rating SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Enum as SAEnum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class RatingLevel(str):
    """Officer-assigned trust rating levels."""
    RED = "RED"
    YELLOW = "YELLOW"
    GREEN = "GREEN"


import enum

class RatingLevelEnum(str, enum.Enum):
    RED = "RED"
    YELLOW = "YELLOW"
    GREEN = "GREEN"


class ManufacturerRating(Base):
    """Officer-assigned trust rating for a manufacturer/retailer.
    
    These are explicitly NOT raw AI scores — only human officers
    can assign RED/YELLOW/GREEN ratings.
    """

    __tablename__ = "manufacturer_ratings"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    manufacturer_name: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    rating: Mapped[RatingLevelEnum] = mapped_column(
        SAEnum(RatingLevelEnum), nullable=False
    )
    officer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )

    # Relationships
    officer = relationship("User")
