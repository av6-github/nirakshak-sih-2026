"""
NIRIKSHAK AI - Enforcement Officer Review API Routes.
"""

import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import Review, Scan, User, Violation
from app.models.enums import ComplianceStatus, ReviewDecision

router = APIRouter(prefix="/reviews", tags=["Officer Reviews"])


class ReviewSubmission(BaseModel):
    scan_id: uuid.UUID
    violation_id: Optional[uuid.UUID] = None
    reviewer_id: uuid.UUID
    decision: ReviewDecision  # ACCEPT, REJECT, REQUEST_RESCAN
    notes: Optional[str] = None


from app.models.declaration import Declaration

from sqlalchemy.orm import selectinload

@router.get("/queue")
async def get_review_queue(
    db: AsyncSession = Depends(get_db),
) -> List[Dict[str, Any]]:
    """
    Fetch pending inspection review queue and historical reviews for enforcement officers.
    Lists scans with FAIL or REVIEW compliance status.
    """
    stmt = select(Scan, Declaration, Review).options(
        selectinload(Scan.violations).selectinload(Violation.rule)
    ).outerjoin(
        Declaration, Scan.id == Declaration.scan_id
    ).outerjoin(
        Review, Scan.id == Review.scan_id
    ).where(
        Scan.overall_compliance.in_([ComplianceStatus.FAIL, ComplianceStatus.REVIEW])
    ).order_by(Scan.created_at.desc())

    result = await db.execute(stmt)
    records = result.all()

    queue = []
    seen_scans = set()
    for s, d, r in records:
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
            
        queue.append({
            "scan_id": str(s.id),
            "status": s.status.value,
            "overall_compliance": s.overall_compliance.value if s.overall_compliance else None,
            "image_urls": s.image_urls,
            "created_at": s.created_at.isoformat(),
            "manufacturer_name": d.manufacturer_name if d else None,
            "product_name": d.generic_product_name if d else None,
            "is_resolved": r is not None,
            "decision": r.decision.value if r else None,
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
    return queue


@router.post("")
async def submit_officer_review(
    review_data: ReviewSubmission,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    Submit human officer enforcement decision (ACCEPT, REJECT, or REQUEST_RESCAN).

    Mandatory Rule: Preserves original AI findings in audit trail; never overwrites raw AI output.
    """
    scan = await db.get(Scan, review_data.scan_id)
    if not scan:
        raise HTTPException(status_code=404, detail="Scan session not found.")

    # Auto-create mock officer if doesn't exist (Development only)
    reviewer = await db.get(User, review_data.reviewer_id)
    if not reviewer:
        reviewer = User(
            id=review_data.reviewer_id,
            email=f"officer_{review_data.reviewer_id}@nirikshak.gov.in",
            hashed_password="mock",
            full_name="Simulated Officer",
            role="OFFICER"
        )
        db.add(reviewer)
        await db.commit()

    # Create Review audit record
    review = Review(
        scan_id=scan.id,
        violation_id=review_data.violation_id,
        reviewer_id=review_data.reviewer_id,
        decision=review_data.decision,
        notes=review_data.notes,
        original_ai_result={
            "overall_compliance": scan.overall_compliance.value if scan.overall_compliance else "UNKNOWN",
            "status": scan.status.value,
        },
    )
    db.add(review)

    # Award points if the officer accepted the AI flagged violation
    if review_data.decision == ReviewDecision.ACCEPT and scan.user_id:
        citizen = await db.get(User, scan.user_id)
        if citizen:
            citizen.reward_points += 10
            db.add(citizen)

    await db.commit()
    await db.refresh(review)

    return {
        "review_id": str(review.id),
        "scan_id": str(scan.id),
        "decision": review.decision.value,
        "message": f"Officer decision '{review.decision.value}' logged successfully. Original AI findings preserved.",
    }
