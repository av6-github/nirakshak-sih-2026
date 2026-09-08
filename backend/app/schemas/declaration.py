"""
NIRIKSHAK AI - Declaration Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel


class DeclarationBase(BaseModel):
    manufacturer_name: str | None = None
    packer_name: str | None = None
    importer_name: str | None = None
    generic_product_name: str | None = None
    net_quantity: float | None = None
    unit: str | None = None
    mrp: float | None = None
    currency: str = "INR"
    manufacture_month: int | None = None
    manufacture_year: int | None = None
    consumer_care_name: str | None = None
    consumer_care_phone: str | None = None
    consumer_care_email: str | None = None
    consumer_care_address: str | None = None
    field_confidence: dict | None = None
    bounding_boxes: dict | None = None
    raw_declarations: dict | None = None


class DeclarationCreate(DeclarationBase):
    scan_id: uuid.UUID


class DeclarationRead(DeclarationBase):
    id: uuid.UUID
    scan_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True
