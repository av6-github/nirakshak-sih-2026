"""
NIRIKSHAK AI - User Profile and History API Routes.
"""

import uuid
from typing import Any, Dict
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.models.user import User
from app.models.scan import Scan
from app.models.complaint import Complaint
from app.models.declaration import Declaration
from app.models.violation import Violation
from app.models.review import Review
from sqlalchemy.orm import selectinload

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/{user_id}/history")
async def get_user_history(
    user_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    Fetch a user's scan and complaint history, and their reward points.
    """
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Fetch scans
    scans_stmt = select(Scan, Declaration).options(
        selectinload(Scan.violations).selectinload(Violation.rule),
        selectinload(Scan.reviews)
    ).outerjoin(
        Declaration, Scan.id == Declaration.scan_id
    ).where(Scan.user_id == user_id).order_by(Scan.created_at.desc())
    
    scans_res = await db.execute(scans_stmt)
    scans_data = []
    seen_scans = set()
    for s, d in scans_res.all():
        if s.id in seen_scans:
            continue
        seen_scans.add(s.id)
        
        evaluations = []
        passed_count = 0
        failed_count = 0
        review_count = 0
        
        for v in s.violations:
            if v.status.name == "PASS": passed_count += 1
            elif v.status.name == "FAIL": failed_count += 1
            else: review_count += 1
            
            citation = v.rule.conditions.get("citation") if v.rule and v.rule.conditions else None
            if citation and citation.get("act_name", "").endswith(".pdf"):
                citation["act_name"] = "Legal Metrology (Packaged Commodities) Rules, 2011"
                
            evaluations.append({
                "rule_title": v.rule.title if v.rule else "Compliance Check",
                "status": v.status.value,
                "reason": v.reason,
                "citation": citation,
            })
            
        is_resolved = len(s.reviews) > 0
        decision = s.reviews[0].decision.value if is_resolved else None
        
        scans_data.append({
            "id": str(s.id),
            "scan_id": str(s.id),
            "type": "SCAN",
            "product_name": d.generic_product_name if d else "Unknown Product",
            "date": s.created_at.isoformat(),
            "status": s.overall_compliance.value if s.overall_compliance else "PENDING",
            "reason": "AI Compliance Check",
            "image_urls": s.image_urls,
            "created_at": s.created_at.isoformat(),
            "manufacturer_name": d.manufacturer_name if d else None,
            "is_resolved": is_resolved,
            "decision": decision,
            "extracted_declarations": d.raw_declarations.get("llm", {}).get("extracted_fields", d.raw_declarations.get("llm", {})) if d and d.raw_declarations else {},
            "product_category": d.raw_declarations.get("llm", {}).get("product_category", "Unknown") if d and d.raw_declarations else "Unknown",
            "compliance_summary": {
                "passed_rules": passed_count,
                "failed_rules": failed_count,
                "review_rules": review_count,
                "compliance_score": int((passed_count / max(1, passed_count + failed_count + review_count)) * 100)
            },
            "evaluations": evaluations,
        })

    # Fetch complaints
    comp_stmt = select(Complaint).where(Complaint.citizen_id == user_id).order_by(Complaint.created_at.desc())
    comp_res = await db.execute(comp_stmt)
    complaints = comp_res.scalars().all()
    comp_data = []
    for c in complaints:
        comp_data.append({
            "id": str(c.id),
            "complaint_id": str(c.id),
            "type": "COMPLAINT",
            "product_name": "Reported Violation",
            "date": c.created_at.isoformat(),
            "status": c.status.value,
            "reason": c.description,
            "shopkeeper_name": c.shopkeeper_name,
            "shop_address": c.shop_address,
            "description": c.description,
            "paid_price": c.paid_price,
            "printed_mrp": c.printed_mrp,
            "created_at": c.created_at.isoformat(),
            "receipt_image_url": c.receipt_image_url,
            "product_image_url": c.product_image_url,
        })

    # Combine and sort by date descending
    history = scans_data + comp_data
    history.sort(key=lambda x: x["date"], reverse=True)

    return {
        "user_id": str(user.id),
        "reward_points": user.reward_points,
        "history": history,
    }
