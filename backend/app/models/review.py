"""
NIRIKSHAK AI - Human Officer Review SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import ReviewDecision


class Review(Base):
    """Enforcement officer verification decision on automated AI flags."""

    __tablename__ = "reviews"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scans.id", ondelete="CASCADE"), nullable=False
    )
    violation_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("violations.id", ondelete="SET NULL"), nullable=True
    )
    reviewer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="RESTRICT"), nullable=False
    )

    decision: Mapped[ReviewDecision] = mapped_column(
        Enum(ReviewDecision), nullable=False
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    original_ai_result: Mapped[dict] = mapped_column(
        JSON, nullable=False
    )  # Preserves un-mutated original AI evaluation

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )

    # Relationships
    scan = relationship("Scan", back_populates="reviews")
    violation = relationship("Violation", back_populates="reviews")
    reviewer = relationship("User", back_populates="reviews")
