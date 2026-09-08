"""
NIRIKSHAK AI - User Pydantic Schemas.
"""

from datetime import datetime
import uuid
from pydantic import BaseModel, EmailStr, Field

from app.models.enums import UserRole


class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    role: UserRole = UserRole.CITIZEN
    badge_number: str | None = None


class UserCreate(UserBase):
    password: str = Field(..., min_length=6)


class UserUpdate(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    badge_number: str | None = None
    is_active: bool | None = None


class UserRead(UserBase):
    id: uuid.UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead
