"""
NIRIKSHAK AI - Rule Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel


class RuleBase(BaseModel):
    rule_id: str
    title: str
    description: str | None = None
    category: str = "general"
    version: str = "1.0"
    effective_date: str | None = None
    conditions: dict
    outcome: dict
    is_active: bool = True


class RuleCreate(RuleBase):
    pass


class RuleRead(RuleBase):
    id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
