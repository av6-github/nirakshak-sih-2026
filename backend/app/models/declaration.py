"""
NIRIKSHAK AI - Extracted Product Declarations SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Declaration(Base):
    """Structured Legal Metrology declarations extracted from OCR text."""

    __tablename__ = "declarations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scans.id", ondelete="CASCADE"), nullable=False
    )

    # Manufacturers / Entities
    manufacturer_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    packer_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    importer_name: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Product Identification
    generic_product_name: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Net Quantity
    net_quantity: Mapped[float | None] = mapped_column(Float, nullable=True)
    unit: Mapped[str | None] = mapped_column(String(50), nullable=True)

    # MRP
    mrp: Mapped[float | None] = mapped_column(Float, nullable=True)
    currency: Mapped[str] = mapped_column(String(10), default="INR", nullable=False)

    # Dates
    manufacture_month: Mapped[int | None] = mapped_column(Integer, nullable=True)
    manufacture_year: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Consumer Care Details
    consumer_care_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    consumer_care_phone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    consumer_care_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    consumer_care_address: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Metadata & Confidence
    field_confidence: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # {"mrp": 0.95, "net_quantity": 0.88}
    bounding_boxes: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # {"mrp": [...], ...}
    raw_declarations: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # Un-normalized raw extractions

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )

    # Relationships
    scan = relationship("Scan", back_populates="declarations")
