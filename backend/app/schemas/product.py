"""
NIRIKSHAK AI - Product Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel


class ProductBase(BaseModel):
    barcode: str | None = None
    product_name: str
    brand: str | None = None
    manufacturer: str | None = None
    category: str | None = None
    extra_metadata: dict | None = None


class ProductCreate(ProductBase):
    pass


class ProductUpdate(BaseModel):
    product_name: str | None = None
    brand: str | None = None
    manufacturer: str | None = None
    category: str | None = None
    extra_metadata: dict | None = None


class ProductRead(ProductBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
