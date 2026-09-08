"""
NIRIKSHAK AI - Legal Rule SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import Boolean, DateTime, String, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Rule(Base):
    """Deterministic Legal Metrology compliance rule model."""

    __tablename__ = "rules"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    rule_id: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    category: Mapped[str] = mapped_column(String(100), default="general", nullable=False)
    version: Mapped[str] = mapped_column(String(50), default="1.0", nullable=False)
    effective_date: Mapped[str | None] = mapped_column(String(50), nullable=True)

    conditions: Mapped[dict] = mapped_column(JSON, nullable=False)  # {"field": "mrp", "required": true, ...}
    outcome: Mapped[dict] = mapped_column(JSON, nullable=False)     # {"missing": "FAIL", "present": "PASS"}

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    violations = relationship("Violation", back_populates="rule")
    evidence_items = relationship("Evidence", back_populates="rule")
