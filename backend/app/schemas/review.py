"""
NIRIKSHAK AI - Review Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel

from app.models.enums import ReviewDecision


class ReviewBase(BaseModel):
    decision: ReviewDecision
    notes: str | None = None
    original_ai_result: dict


class ReviewCreate(ReviewBase):
    scan_id: uuid.UUID
    violation_id: uuid.UUID | None = None


class ReviewRead(ReviewBase):
    id: uuid.UUID
    scan_id: uuid.UUID
    violation_id: uuid.UUID | None = None
    reviewer_id: uuid.UUID
    created_at: datetime

    class Config:
        from_attributes = True
