"""
NIRIKSHAK AI - Legal Rule Management API Routes.
"""

from typing import Any, Dict, List
from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import Rule

router = APIRouter(prefix="/rules", tags=["Rule Engine Management"])


@router.get("")
async def list_active_rules(
    db: AsyncSession = Depends(get_db),
) -> List[Dict[str, Any]]:
    """List all registered deterministic Legal Metrology compliance rules."""
    stmt = select(Rule).order_by(Rule.rule_id)
    res = await db.execute(stmt)
    rules = res.scalars().all()

    default_rules = [
        {"rule_id": "RULE-LM-001", "title": "Mandatory MRP Declaration", "version": "1.0", "category": "Pricing"},
        {"rule_id": "RULE-LM-002", "title": "Mandatory Net Quantity & Unit", "version": "1.0", "category": "Quantity"},
        {"rule_id": "RULE-LM-003", "title": "Mandatory Manufacturer / Packer Details", "version": "1.0", "category": "Entity"},
        {"rule_id": "RULE-LM-004", "title": "Mandatory Date of Manufacture", "version": "1.0", "category": "Dates"},
        {"rule_id": "RULE-LM-005", "title": "Mandatory Consumer Care Contact", "version": "1.0", "category": "Consumer Care"},
        {"rule_id": "RULE-LM-006", "title": "Mandatory Generic Product Name", "version": "1.0", "category": "Product Identification"},
    ]

    if not rules:
        return default_rules

    return [
        {
            "rule_id": r.rule_id,
            "title": r.title,
            "version": r.version,
            "category": r.category,
            "is_active": r.is_active,
        }
        for r in rules
    ]
