"""
NIRIKSHAK AI - Manufacturer Audit History & Trust Rating API Routes.
"""

import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select, func, distinct
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.models.declaration import Declaration
from app.models.scan import Scan
from app.models.enums import ComplianceStatus
from app.models.manufacturer_rating import ManufacturerRating, RatingLevelEnum

router = APIRouter(prefix="/manufacturers", tags=["Manufacturer Audit"])


class RatingSubmission(BaseModel):
    officer_id: uuid.UUID
    rating: RatingLevelEnum  # RED, YELLOW, GREEN
    notes: Optional[str] = None


@router.get("/{name}/history")
async def get_manufacturer_history(
    name: str,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """Fetch historical compliance records for a manufacturer by name."""
    stmt = select(Declaration, Scan).join(
        Scan, Declaration.scan_id == Scan.id
    ).where(
        Declaration.manufacturer_name.ilike(f"%{name}%")
    ).order_by(Scan.created_at.desc())

    result = await db.execute(stmt)
    records = result.all()

    total_scans = len(records)
    passed_scans = sum(1 for d, s in records if s.overall_compliance == ComplianceStatus.PASS)
    failed_scans = total_scans - passed_scans
    compliance_score = (passed_scans / total_scans * 100) if total_scans > 0 else 0

    # Get latest officer rating
    rating_stmt = select(ManufacturerRating).where(
        ManufacturerRating.manufacturer_name.ilike(f"%{name}%")
    ).order_by(ManufacturerRating.created_at.desc()).limit(1)
    rating_res = await db.execute(rating_stmt)
    latest_rating = rating_res.scalar_one_or_none()

    history = []
    for decl, scan in records:
        history.append({
            "scan_id": str(scan.id),
            "date": scan.created_at.isoformat(),
            "status": scan.overall_compliance.value if scan.overall_compliance else "UNKNOWN",
            "product_name": decl.generic_product_name,
        })

    return {
        "manufacturer_name": name,
        "total_scans": total_scans,
        "compliance_score": round(compliance_score, 1),
        "officer_rating": latest_rating.rating.value if latest_rating else None,
        "officer_rating_notes": latest_rating.notes if latest_rating else None,
        "history": history,
    }


@router.post("/{name}/rate")
async def rate_manufacturer(
    name: str,
    data: RatingSubmission,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    Submit an officer trust rating (RED / YELLOW / GREEN) for a manufacturer.
    Only enforcement officers can assign ratings. This is NOT an AI score.
    """
    rating = ManufacturerRating(
        manufacturer_name=name,
        rating=data.rating,
        officer_id=data.officer_id,
        notes=data.notes,
    )
    db.add(rating)
    await db.commit()
    await db.refresh(rating)

    return {
        "id": str(rating.id),
        "manufacturer_name": name,
        "rating": rating.rating.value,
        "message": f"Officer rating '{rating.rating.value}' assigned to '{name}' successfully.",
    }


@router.get("/ratings")
async def get_all_manufacturer_ratings(
    db: AsyncSession = Depends(get_db),
) -> List[Dict[str, Any]]:
    """
    Get all manufacturers with their latest officer-assigned trust ratings.
    Returns a list suitable for rendering a public trust portal.
    """
    # Get all distinct manufacturer names from declarations
    mfr_stmt = select(distinct(Declaration.manufacturer_name)).where(
        Declaration.manufacturer_name.isnot(None)
    )
    mfr_res = await db.execute(mfr_stmt)
    all_manufacturers = [row[0] for row in mfr_res.all() if row[0]]

    results = []
    for mfr_name in all_manufacturers:
        # Count total scans
        scan_count_stmt = select(func.count()).select_from(Declaration).join(
            Scan, Declaration.scan_id == Scan.id
        ).where(Declaration.manufacturer_name == mfr_name)
        scan_count_res = await db.execute(scan_count_stmt)
        total_scans = scan_count_res.scalar() or 0

        # Count passed scans
        pass_count_stmt = select(func.count()).select_from(Declaration).join(
            Scan, Declaration.scan_id == Scan.id
        ).where(
            Declaration.manufacturer_name == mfr_name,
            Scan.overall_compliance == ComplianceStatus.PASS,
        )
        pass_count_res = await db.execute(pass_count_stmt)
        passed = pass_count_res.scalar() or 0

        # Get latest officer rating
        rating_stmt = select(ManufacturerRating).where(
            ManufacturerRating.manufacturer_name.ilike(f"%{mfr_name}%")
        ).order_by(ManufacturerRating.created_at.desc()).limit(1)
        rating_res = await db.execute(rating_stmt)
        latest_rating = rating_res.scalar_one_or_none()

        results.append({
            "manufacturer_name": mfr_name,
            "total_scans": total_scans,
            "passed_scans": passed,
            "ai_compliance_score": round((passed / total_scans * 100) if total_scans > 0 else 0, 1),
            "officer_rating": latest_rating.rating.value if latest_rating else None,
            "officer_notes": latest_rating.notes if latest_rating else None,
            "last_rated_at": latest_rating.created_at.isoformat() if latest_rating else None,
        })

    return results
