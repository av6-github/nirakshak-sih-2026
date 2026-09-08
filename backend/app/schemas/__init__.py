"""
NIRIKSHAK AI - Pydantic Schemas Package.
"""

from app.schemas.user import UserBase, UserCreate, UserUpdate, UserRead, Token
from app.schemas.product import ProductBase, ProductCreate, ProductUpdate, ProductRead
from app.schemas.scan import ScanBase, ScanCreate, ScanRead
from app.schemas.ocr_result import OCRResultBase, OCRResultCreate, OCRResultRead
from app.schemas.declaration import DeclarationBase, DeclarationCreate, DeclarationRead
from app.schemas.rule import RuleBase, RuleCreate, RuleRead
from app.schemas.violation import ViolationBase, ViolationCreate, ViolationRead
from app.schemas.evidence import EvidenceBase, EvidenceCreate, EvidenceRead
from app.schemas.review import ReviewBase, ReviewCreate, ReviewRead
from app.schemas.complaint import ComplaintBase, ComplaintCreate, ComplaintRead
from app.schemas.trust import TrustScoreBase, TrustScoreRead

__all__ = [
    "UserBase", "UserCreate", "UserUpdate", "UserRead", "Token",
    "ProductBase", "ProductCreate", "ProductUpdate", "ProductRead",
    "ScanBase", "ScanCreate", "ScanRead",
    "OCRResultBase", "OCRResultCreate", "OCRResultRead",
    "DeclarationBase", "DeclarationCreate", "DeclarationRead",
    "RuleBase", "RuleCreate", "RuleRead",
    "ViolationBase", "ViolationCreate", "ViolationRead",
    "EvidenceBase", "EvidenceCreate", "EvidenceRead",
    "ReviewBase", "ReviewCreate", "ReviewRead",
    "ComplaintBase", "ComplaintCreate", "ComplaintRead",
    "TrustScoreBase", "TrustScoreRead",
]
