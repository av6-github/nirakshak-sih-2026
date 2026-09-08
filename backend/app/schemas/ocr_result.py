"""
NIRIKSHAK AI - OCR Result Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel


class OCRResultBase(BaseModel):
    image_side: str | None = None
    image_url: str | None = None
    raw_text: str
    processed_text: str | None = None
    confidence: float = 0.0
    bounding_boxes: dict | list | None = None
    page_number: int = 1
    extraction_method: str = "paddleocr"
    detected_language: str = "en"


class OCRResultCreate(OCRResultBase):
    scan_id: uuid.UUID


class OCRResultRead(OCRResultBase):
    id: uuid.UUID
    scan_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True
