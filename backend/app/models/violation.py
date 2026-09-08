"""
NIRIKSHAK AI - Violation SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import ComplianceStatus


class Violation(Base):
    """Compliance rule evaluation outcome per scan."""

    __tablename__ = "violations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scans.id", ondelete="CASCADE"), nullable=False
    )
    rule_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("rules.id", ondelete="RESTRICT"), nullable=False
    )

    field_name: Mapped[str] = mapped_column(String(100), nullable=False)
    status: Mapped[ComplianceStatus] = mapped_column(
        Enum(ComplianceStatus), nullable=False
    )
    reason: Mapped[str] = mapped_column(Text, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )

    # Relationships
    scan = relationship("Scan", back_populates="violations")
    rule = relationship("Rule", back_populates="violations")
    evidence_items = relationship("Evidence", back_populates="violation", cascade="all, delete-orphan")
    reviews = relationship("Review", back_populates="violation")
