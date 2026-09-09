"""
NIRIKSHAK AI - Citizen Overcharging Complaint API Routes.
"""

import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, File, Form, UploadFile
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import Complaint
from app.models.user import User
from app.models.enums import ComplaintStatus
from app.services.storage import StorageService

router = APIRouter(prefix="/complaints", tags=["Citizen Complaints"])
storage_service = StorageService()

def _safe_uuid(val: Any) -> uuid.UUID:
    if isinstance(val, uuid.UUID):
        return val
    try:
        return uuid.UUID(str(val))
    except Exception:
        return uuid.uuid5(uuid.NAMESPACE_DNS, str(val) if val else "default-user")


@router.post("", status_code=201)
async def create_complaint(
    citizen_id: str = Form(...),
    product_id: Optional[str] = Form(None),
    paid_price: float = Form(...),
    printed_mrp: float = Form(...),
    shopkeeper_name: Optional[str] = Form(None),
    shop_address: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    receipt_image: Optional[UploadFile] = File(None),
    product_image: Optional[UploadFile] = File(None),
    receipt_image_url: Optional[str] = Form(None),
    product_image_url: Optional[str] = Form(None),
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    File a citizen complaint for overcharging (Paid Price > Printed MRP) or packaging violation.
    Now supports multipart/form-data for image evidence or existing image URLs.
    """
    is_overcharging = paid_price > printed_mrp
    citizen_uuid = _safe_uuid(citizen_id)
    product_uuid = _safe_uuid(product_id) if product_id else None

    # Auto-create mock citizen if doesn't exist (Development only)
    citizen = await db.get(User, citizen_uuid)
    if not citizen:
        citizen = User(
            id=citizen_uuid,
            email=f"citizen_{str(citizen_uuid)[:8]}@nirikshak.gov.in",
            hashed_password="mock",
            full_name="Simulated Citizen",
            role="CITIZEN"
        )
        db.add(citizen)
        await db.commit()

    receipt_url = receipt_image_url
    if receipt_image and receipt_image.filename:
        receipt_url = await storage_service.save_upload_file(receipt_image, subfolder="complaints")
        
    product_url = product_image_url
    if product_image and product_image.filename:
        product_url = await storage_service.save_upload_file(product_image, subfolder="complaints")

    complaint = Complaint(
        citizen_id=citizen_uuid,
        product_id=product_uuid,
        receipt_image_url=receipt_url,
        product_image_url=product_url,
        paid_price=paid_price,
        printed_mrp=printed_mrp,
        shopkeeper_name=shopkeeper_name,
        shop_address=shop_address,
        status=ComplaintStatus.SUBMITTED,
        description=description or ("Overcharging complaint detected: Paid price exceeds printed MRP." if is_overcharging else "General Packaging Complaint"),
    )
    db.add(complaint)
    await db.commit()
    await db.refresh(complaint)

    return {
        "complaint_id": str(complaint.id),
        "status": complaint.status.value,
        "is_overcharging_detected": is_overcharging,
        "price_difference": round(paid_price - printed_mrp, 2) if is_overcharging else 0.0,
        "message": "Complaint filed successfully and routed to enforcement officer queue.",
    }


@router.get("")
async def list_complaints(
    db: AsyncSession = Depends(get_db),
) -> List[Dict[str, Any]]:
    """List complaints for officer review."""
    stmt = select(Complaint).order_by(Complaint.created_at.desc())
    res = await db.execute(stmt)
    complaints = res.scalars().all()

    return [
        {
            "complaint_id": str(c.id),
            "citizen_id": str(c.citizen_id),
            "paid_price": c.paid_price,
            "printed_mrp": c.printed_mrp,
            "shopkeeper_name": c.shopkeeper_name,
            "shop_address": c.shop_address,
            "status": c.status.value,
            "description": c.description,
            "created_at": c.created_at.isoformat(),
            "receipt_image_url": c.receipt_image_url,
            "product_image_url": c.product_image_url,
        }
        for c in complaints
    ]


class ComplaintReviewRequest(BaseModel):
    officer_id: Any
    status: ComplaintStatus
    resolution_notes: Optional[str] = None

@router.patch("/{complaint_id}/review")
async def review_complaint(
    complaint_id: str,
    review_data: ComplaintReviewRequest,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """Officer reviews and resolves a citizen complaint."""
    complaint_uuid = _safe_uuid(complaint_id)
    officer_uuid = _safe_uuid(review_data.officer_id)

    complaint = await db.get(Complaint, complaint_uuid)
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    # Auto-create mock officer if doesn't exist (Development only)
    officer = await db.get(User, officer_uuid)
    if not officer:
        officer = User(
            id=officer_uuid,
            email=f"officer_{str(officer_uuid)[:8]}@nirikshak.gov.in",
            hashed_password="mock",
            full_name="Simulated Officer",
            role="OFFICER"
        )
        db.add(officer)
        await db.commit()

    complaint.status = review_data.status
    complaint.officer_id = officer_uuid
    if review_data.resolution_notes:
        complaint.resolution_notes = review_data.resolution_notes

    # Award points if complaint is accepted
    if review_data.status == ComplaintStatus.RESOLVED:
        citizen = await db.get(User, complaint.citizen_id)
        if citizen:
            citizen.reward_points += 20  # 20 points for valid complaint
            db.add(citizen)

    db.add(complaint)
    await db.commit()

    return {"message": "Complaint reviewed successfully", "status": complaint.status.value}
