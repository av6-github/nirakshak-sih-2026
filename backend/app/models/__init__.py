"""
NIRIKSHAK AI - Database Models Package.

Exports all SQLAlchemy ORM models and Enums for easy import and Alembic discovery.
"""

from app.models.enums import (
    UserRole,
    ScanStatus,
    ComplianceStatus,
    ReviewDecision,
    ComplaintStatus,
)
from app.models.user import User
from app.models.product import Product
from app.models.scan import Scan
from app.models.ocr_result import OCRResult
from app.models.declaration import Declaration
from app.models.rule import Rule
from app.models.violation import Violation
from app.models.evidence import Evidence
from app.models.review import Review
from app.models.complaint import Complaint
from app.models.trust import TrustScore
from app.models.manufacturer_rating import ManufacturerRating

__all__ = [
    "UserRole",
    "ScanStatus",
    "ComplianceStatus",
    "ReviewDecision",
    "ComplaintStatus",
    "User",
    "Product",
    "Scan",
    "OCRResult",
    "Declaration",
    "Rule",
    "Violation",
    "Evidence",
    "Review",
    "Complaint",
    "TrustScore",
    "ManufacturerRating",
]
