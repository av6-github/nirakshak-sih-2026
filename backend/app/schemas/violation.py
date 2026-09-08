"""
NIRIKSHAK AI - Violation Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel

from app.models.enums import ComplianceStatus


class ViolationBase(BaseModel):
    field_name: str
    status: ComplianceStatus
    reason: str


class ViolationCreate(ViolationBase):
    scan_id: uuid.UUID
    rule_id: uuid.UUID


class ViolationRead(ViolationBase):
    id: uuid.UUID
    scan_id: uuid.UUID
    rule_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True
