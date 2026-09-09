"""
NIRIKSHAK AI - Legal Rule Management API Routes.
"""

from typing import Any, Dict, List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.services.rules.rule_engine import RuleEngine
from app.services.rag.violation_analyzer import STATUTORY_DEFAULTS

router = APIRouter(prefix="/rules", tags=["Rule Engine Management"])
_engine = RuleEngine()


@router.get("")
async def list_active_rules(
    db: AsyncSession = Depends(get_db),
) -> List[Dict[str, Any]]:
    """List all registered deterministic Legal Metrology compliance rules with full statutory references."""
    rules_out = []

    for r in _engine._rule_defs:
        rule_id = r.get("id")
        sd = STATUTORY_DEFAULTS.get(rule_id, {})
        
        # Categorize
        field = r.get("field", "").lower()
        if "mrp" in field:
            category = "Pricing & Taxes"
        elif "net_quantity" in field or "unit" in field:
            category = "Weight & Measure"
        elif "manufacturer" in field or "packer" in field or "importer" in field:
            category = "Manufacturer Identity"
        elif "date" in field or "month" in field:
            category = "Dates & Shelf Life"
        elif "consumer" in field or "care" in field:
            category = "Consumer Grievance"
        elif "ecom" in field or "ecommerce" in field:
            category = "E-Commerce Surveillance"
        else:
            category = "Commodity Identification"

        rules_out.append({
            "rule_id": rule_id,
            "rule_code": sd.get("rule_code") or r.get("act_reference", "").split("—")[0].strip(),
            "title": r.get("title"),
            "description": r.get("description", "").strip(),
            "act_reference": r.get("act_reference") or sd.get("act_name", "Legal Metrology (Packaged Commodities) Rules, 2011"),
            "field": r.get("field"),
            "severity": r.get("severity", "CRITICAL"),
            "category": category,
            "penalty": sd.get("penalty", "Section 36(1) of Legal Metrology Act, 2009: Fine up to ₹25,000 for first offence, up to ₹50,000 for subsequent offences."),
            "legal_quote": sd.get("legal_quote", ""),
            "is_active": True,
        })

    return rules_out
