"""
NIRIKSHAK AI - Evidence Package SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Float, ForeignKey, String, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Evidence(Base):
    """Evidence artifact generated for compliance evaluation results."""

    __tablename__ = "evidence"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scans.id", ondelete="CASCADE"), nullable=False
    )
    violation_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("violations.id", ondelete="SET NULL"), nullable=True
    )
    rule_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("rules.id", ondelete="SET NULL"), nullable=True
    )

    field: Mapped[str] = mapped_column(String(100), nullable=False)
    detected_value: Mapped[str | None] = mapped_column(String(500), nullable=True)

    source_image: Mapped[str] = mapped_column(String(500), nullable=False)
    cropped_image: Mapped[str | None] = mapped_column(String(500), nullable=True)
    bounding_box: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    ocr_confidence: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    rule_version: Mapped[str] = mapped_column(String(50), default="1.0", nullable=False)
    file_hash: Mapped[str | None] = mapped_column(String(64), nullable=True)  # SHA-256 for tamper prevention

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )

    # Relationships
    scan = relationship("Scan", back_populates="evidence_items")
    violation = relationship("Violation", back_populates="evidence_items")
    rule = relationship("Rule", back_populates="evidence_items")
