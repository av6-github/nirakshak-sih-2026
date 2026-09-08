"""
NIRIKSHAK AI - Trust Score SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Float, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class TrustScore(Base):
    """Aggregate citizen trust score based ONLY on officer-verified violations."""

    __tablename__ = "trust_scores"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    product_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), unique=True, nullable=False
    )

    score: Mapped[float] = mapped_column(Float, default=100.0, nullable=False)  # 0.0 to 100.0
    verified_violations_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_inspections_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    last_calculated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )

    # Relationships
    product = relationship("Product", back_populates="trust_score")
