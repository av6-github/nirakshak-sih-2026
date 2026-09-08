"""
NIRIKSHAK AI - Enumerations for Data Models.
"""

from enum import Enum


class UserRole(str, Enum):
    """User authorization roles."""
    CITIZEN = "CITIZEN"
    OFFICER = "OFFICER"
    ADMIN = "ADMIN"


class ScanStatus(str, Enum):
    """Processing state of a product scan."""
    PENDING = "PENDING"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"


class ComplianceStatus(str, Enum):
    """Compliance decision status values."""
    PASS = "PASS"
    FAIL = "FAIL"
    REVIEW = "REVIEW"
    NOT_APPLICABLE = "NOT_APPLICABLE"


class ReviewDecision(str, Enum):
    """Officer enforcement decisions."""
    ACCEPT = "ACCEPT"
    REJECT = "REJECT"
    REQUEST_RESCAN = "REQUEST_RESCAN"


class ComplaintStatus(str, Enum):
    """Status of citizen complaints."""
    SUBMITTED = "SUBMITTED"
    UNDER_REVIEW = "UNDER_REVIEW"
    RESOLVED = "RESOLVED"
    REJECTED = "REJECTED"
