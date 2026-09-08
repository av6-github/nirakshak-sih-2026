"""
NIRIKSHAK AI - Trust Score Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel


class TrustScoreBase(BaseModel):
    score: float = 100.0
    verified_violations_count: int = 0
    total_inspections_count: int = 0


class TrustScoreRead(TrustScoreBase):
    id: uuid.UUID
    product_id: uuid.UUID
    last_calculated_at: datetime

    class Config:
        from_attributes = True
