"""
NIRIKSHAK AI - Evidence Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel


class EvidenceBase(BaseModel):
    field: str
    detected_value: str | None = None
    source_image: str
    cropped_image: str | None = None
    bounding_box: dict | None = None
    ocr_confidence: float = 0.0
    rule_version: str = "1.0"
    file_hash: str | None = None


class EvidenceCreate(EvidenceBase):
    scan_id: uuid.UUID
    violation_id: uuid.UUID | None = None
    rule_id: uuid.UUID | None = None


class EvidenceRead(EvidenceBase):
    id: uuid.UUID
    scan_id: uuid.UUID
    violation_id: uuid.UUID | None = None
    rule_id: uuid.UUID | None = None
    created_at: datetime

    class Config:
        from_attributes = True
