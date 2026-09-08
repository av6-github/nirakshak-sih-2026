"""
NIRIKSHAK AI - Citizen Complaint SQLAlchemy Model.
"""

from datetime import datetime, timezone
import uuid

from sqlalchemy import DateTime, Enum, Float, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.enums import ComplaintStatus


class Complaint(Base):
    """Citizen complaint for overcharging or Legal Metrology violations."""

    __tablename__ = "complaints"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    citizen_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    product_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id", ondelete="SET NULL"), nullable=True
    )
    officer_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    receipt_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    product_image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    paid_price: Mapped[float | None] = mapped_column(Float, nullable=True)
    printed_mrp: Mapped[float | None] = mapped_column(Float, nullable=True)

    shopkeeper_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    shop_address: Mapped[str | None] = mapped_column(Text, nullable=True)

    status: Mapped[ComplaintStatus] = mapped_column(
        Enum(ComplaintStatus), default=ComplaintStatus.SUBMITTED, nullable=False
    )
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    resolution_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

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
    citizen = relationship("User", back_populates="complaints", foreign_keys=[citizen_id])
    product = relationship("Product", back_populates="complaints")
