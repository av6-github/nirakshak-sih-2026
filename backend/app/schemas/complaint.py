"""
NIRIKSHAK AI - Complaint Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel

from app.models.enums import ComplaintStatus


class ComplaintBase(BaseModel):
    receipt_image_url: str | None = None
    product_image_url: str | None = None
    paid_price: float | None = None
    printed_mrp: float | None = None
    description: str | None = None


class ComplaintCreate(ComplaintBase):
    product_id: uuid.UUID | None = None


class ComplaintRead(ComplaintBase):
    id: uuid.UUID
    citizen_id: uuid.UUID
    product_id: uuid.UUID | None = None
    officer_id: uuid.UUID | None = None
    status: ComplaintStatus
    resolution_notes: str | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
