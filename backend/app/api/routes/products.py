"""
NIRIKSHAK AI - Product Digital Twin & Compliance History API Routes.
"""

import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import Declaration, Product, Scan, TrustScore

router = APIRouter(prefix="/products", tags=["Product Digital Twin"])


@router.get("/search")
async def search_products(
    query: str,
    db: AsyncSession = Depends(get_db),
) -> List[Dict[str, Any]]:
    """Search for products by name or barcode."""
    stmt = (
        select(Product)
        .where(
            (Product.product_name.ilike(f"%{query}%")) | 
            (Product.barcode == query)
        )
        .limit(10)
    )
    result = await db.execute(stmt)
    products = result.scalars().all()

    return [
        {
            "product_id": str(p.id),
            "barcode": p.barcode,
            "product_name": p.product_name,
            "brand": p.brand,
            "manufacturer": p.manufacturer,
        }
        for p in products
    ]

@router.get("/{product_id}")
async def get_product_digital_twin(
    product_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """Get persistent Digital Twin details, history, and trust score for a product."""
    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found.")

    # Get scan history
    stmt = select(Scan).where(Scan.product_id == product.id).order_by(Scan.created_at.desc())
    scans_res = await db.execute(stmt)
    scans = scans_res.scalars().all()

    # Get trust score
    trust_stmt = select(TrustScore).where(TrustScore.product_id == product.id)
    trust_res = await db.execute(trust_stmt)
    trust = trust_res.scalar_one_or_none()

    return {
        "product_id": str(product.id),
        "barcode": product.barcode,
        "product_name": product.product_name,
        "brand": product.brand,
        "manufacturer": product.manufacturer,
        "category": product.category,
        "trust_score": trust.score if trust else 100.0,
        "verified_violations_count": trust.verified_violations_count if trust else 0,
        "total_scans": len(scans),
        "scan_history": [
            {
                "scan_id": str(s.id),
                "status": s.status.value,
                "overall_compliance": s.overall_compliance.value if s.overall_compliance else None,
                "created_at": s.created_at.isoformat(),
            }
            for s in scans
        ],
    }


@router.get("/{product_id}/diff")
async def get_product_declaration_diff(
    product_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    Compare previous scan vs current scan declarations for a product (e.g. MRP change detection).
    """
    stmt = (
        select(Scan)
        .where(Scan.product_id == product_id)
        .order_by(Scan.created_at.desc())
        .limit(2)
    )
    result = await db.execute(stmt)
    scans = result.scalars().all()

    if len(scans) < 2:
        return {
            "product_id": str(product_id),
            "message": "At least 2 scans required to generate historical declaration diff.",
            "scans_found": len(scans),
        }

    curr_scan, prev_scan = scans[0], scans[1]

    # Fetch declarations
    curr_decl_res = await db.execute(select(Declaration).where(Declaration.scan_id == curr_scan.id))
    prev_decl_res = await db.execute(select(Declaration).where(Declaration.scan_id == prev_scan.id))

    curr_decl = curr_decl_res.scalar_one_or_none()
    prev_decl = prev_decl_res.scalar_one_or_none()

    mrp_change = None
    if curr_decl and prev_decl and curr_decl.mrp and prev_decl.mrp:
        mrp_change = {
            "previous_mrp": prev_decl.mrp,
            "current_mrp": curr_decl.mrp,
            "change": curr_decl.mrp - prev_decl.mrp,
            "percentage_change": round(((curr_decl.mrp - prev_decl.mrp) / prev_decl.mrp) * 100, 2),
        }

    return {
        "product_id": str(product_id),
        "previous_scan": {"scan_id": str(prev_scan.id), "date": prev_scan.created_at.isoformat()},
        "current_scan": {"scan_id": str(curr_scan.id), "date": curr_scan.created_at.isoformat()},
        "mrp_diff": mrp_change,
    }


@router.get("/{product_id}/twin")
async def get_digital_twin_full(
    product_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    Get the complete Digital Twin view: product identity, all scans,
    all violations, latest declarations, trust score, and whether
    the latest scan matches historical values.
    """
    from app.models import Violation
    from sqlalchemy.orm import selectinload

    product = await db.get(Product, product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found.")

    # Get all scans for this product with violations eagerly loaded
    stmt = (
        select(Scan)
        .options(
            selectinload(Scan.violations).selectinload(Violation.rule),
            selectinload(Scan.declarations),
        )
        .where(Scan.product_id == product.id)
        .order_by(Scan.created_at.desc())
    )
    scans_res = await db.execute(stmt)
    scans = scans_res.scalars().all()

    # Trust score
    trust_stmt = select(TrustScore).where(TrustScore.product_id == product.id)
    trust_res = await db.execute(trust_stmt)
    trust = trust_res.scalar_one_or_none()

    # Build full timeline
    timeline = []
    for s in scans:
        violations_list = []
        for v in s.violations:
            violations_list.append({
                "rule_id": v.rule.rule_id if v.rule else "UNKNOWN",
                "rule_title": v.rule.title if v.rule else "Unknown",
                "status": v.status.value,
                "reason": v.reason,
                "citation": v.rule.conditions.get("citation") if v.rule and v.rule.conditions else None,
            })

        decls = {}
        if s.declarations:
            d = s.declarations[0]
            decls = {
                "generic_product_name": d.generic_product_name,
                "manufacturer_name": d.manufacturer_name,
                "packer_name": d.packer_name,
                "importer_name": d.importer_name,
                "mrp": d.mrp,
                "net_quantity": d.net_quantity,
                "unit": d.unit,
                "manufacture_month": d.manufacture_month,
                "manufacture_year": d.manufacture_year,
                "expiry_date": getattr(d, 'expiry_date', None) or (d.raw_declarations.get("expiry_date") if d.raw_declarations else None),
                "consumer_care_email": getattr(d, 'consumer_care_email', None),
                "consumer_care_phone": getattr(d, 'consumer_care_phone', None),
                "consumer_care_address": getattr(d, 'consumer_care_address', None),
            }

        timeline.append({
            "scan_id": str(s.id),
            "date": s.created_at.isoformat(),
            "overall_compliance": s.overall_compliance.value if s.overall_compliance else None,
            "declarations": decls,
            "violations": violations_list,
        })

    return {
        "product_id": str(product.id),
        "product_name": product.product_name,
        "brand": product.brand,
        "manufacturer": product.manufacturer,
        "barcode": product.barcode,
        "latest_declarations": product.extra_metadata.get("latest_declarations") if product.extra_metadata else None,
        "trust_score": trust.score if trust else 100.0,
        "verified_violations_count": trust.verified_violations_count if trust else 0,
        "total_scans": len(scans),
        "compliance_timeline": timeline,
    }

