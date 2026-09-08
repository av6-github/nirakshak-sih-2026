"""
NIRIKSHAK AI - OCR Result SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class OCRResult(Base):
    """Raw and processed OCR text output with coordinates and confidence scores."""

    __tablename__ = "ocr_results"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    scan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scans.id", ondelete="CASCADE"), nullable=False
    )

    image_side: Mapped[str | None] = mapped_column(String(50), nullable=True)  # front, back, side
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    raw_text: Mapped[str] = mapped_column(Text, nullable=False)
    processed_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    confidence: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    bounding_boxes: Mapped[dict | None] = mapped_column(JSON, nullable=True)  # [{"text": "...", "bbox": [...], "score": 0.95}]
    page_number: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    extraction_method: Mapped[str] = mapped_column(String(50), default="paddleocr", nullable=False)
    detected_language: Mapped[str] = mapped_column(String(10), default="en", nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False
    )

    # Relationships
    scan = relationship("Scan", back_populates="ocr_results")
