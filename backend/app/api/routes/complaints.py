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

@router.post("", status_code=201)
async def create_complaint(
    citizen_id: uuid.UUID = Form(...),
    product_id: Optional[uuid.UUID] = Form(None),
    paid_price: float = Form(...),
    printed_mrp: float = Form(...),
    shopkeeper_name: Optional[str] = Form(None),
    shop_address: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    receipt_image: Optional[UploadFile] = File(None),
    product_image: Optional[UploadFile] = File(None),
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    File a citizen complaint for overcharging (Paid Price > Printed MRP) or packaging violation.
    Now supports multipart/form-data for image evidence.
    """
    is_overcharging = paid_price > printed_mrp

    # Auto-create mock citizen if doesn't exist (Development only)
    citizen = await db.get(User, citizen_id)
    if not citizen:
        citizen = User(
            id=citizen_id,
            email=f"citizen_{citizen_id}@nirikshak.gov.in",
            hashed_password="mock",
            full_name="Simulated Citizen",
            role="CITIZEN"
        )
        db.add(citizen)
        await db.commit()

    receipt_url = None
    if receipt_image and receipt_image.filename:
        receipt_url = await storage_service.save_upload_file(receipt_image, subfolder="complaints")
        
    product_url = None
    if product_image and product_image.filename:
        product_url = await storage_service.save_upload_file(product_image, subfolder="complaints")

    complaint = Complaint(
        citizen_id=citizen_id,
        product_id=product_id,
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
    officer_id: uuid.UUID
    status: ComplaintStatus  # e.g. ACCEPTED, REJECTED
    resolution_notes: Optional[str] = None

@router.patch("/{complaint_id}/review")
async def review_complaint(
    complaint_id: uuid.UUID,
    review_data: ComplaintReviewRequest,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """Officer reviews and resolves a citizen complaint."""
    complaint = await db.get(Complaint, complaint_id)
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")

    # Auto-create mock officer if doesn't exist (Development only)
    officer = await db.get(User, review_data.officer_id)
    if not officer:
        officer = User(
            id=review_data.officer_id,
            email=f"officer_{review_data.officer_id}@nirikshak.gov.in",
            hashed_password="mock",
            full_name="Simulated Officer",
            role="OFFICER"
        )
        db.add(officer)
        await db.commit()

    complaint.status = review_data.status
    complaint.officer_id = review_data.officer_id
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
