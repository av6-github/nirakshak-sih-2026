"""
NIRIKSHAK AI - Database Models & Relationships Verification Tests.
"""

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

from app.core.database import Base
from app.models import (
    User, UserRole, Product, Scan, ScanStatus,
    OCRResult, Declaration, Rule, Violation, Evidence,
    Review, ReviewDecision, Complaint, TrustScore, ComplianceStatus
)

# In-memory SQLite engine for fast unit tests
test_engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
async_test_session_factory = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


@pytest.mark.asyncio
async def test_create_tables():
    """Verify that all models can create database tables without schema errors."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


@pytest.mark.asyncio
async def test_full_model_relationships():
    """Verify end-to-end relational data insertion and cascading relationships."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_test_session_factory() as session:
        # 1. Create User
        user = User(
            email="inspector.gadget@nirikshak.gov.in",
            hashed_password="hashed_secret_password",
            full_name="Inspector Gadget",
            role=UserRole.OFFICER,
            badge_number="OFF-9982",
        )
        session.add(user)
        await session.flush()

        # 2. Create Product
        product = Product(
            barcode="8901234567890",
            product_name="Premium Fortified Wheat Atta 5kg",
            brand="NatureFresh",
            manufacturer="Nature Foods Ltd",
            category="Food Staples",
        )
        session.add(product)
        await session.flush()

        # 3. Create Scan
        scan = Scan(
            user_id=user.id,
            product_id=product.id,
            status=ScanStatus.COMPLETED,
            overall_compliance=ComplianceStatus.FAIL,
            image_urls={"front": "/uploads/front.jpg", "back": "/uploads/back.jpg"},
        )
        session.add(scan)
        await session.flush()

        # 4. Create OCR Result
        ocr = OCRResult(
            scan_id=scan.id,
            image_side="front",
            raw_text="MRP Rs. 299 Net Qty: 5 kg Mfd: 08/2026",
            confidence=0.96,
        )
        session.add(ocr)

        # 5. Create Declaration
        declaration = Declaration(
            scan_id=scan.id,
            generic_product_name="Wheat Atta",
            net_quantity=5.0,
            unit="kg",
            mrp=299.0,
            manufacture_month=8,
            manufacture_year=2026,
        )
        session.add(declaration)

        # 6. Create Rule
        rule = Rule(
            rule_id="RULE-LM-001",
            title="Mandatory Consumer Care Address",
            conditions={"field": "consumer_care_address", "required": True},
            outcome={"missing": "FAIL", "present": "PASS"},
        )
        session.add(rule)
        await session.flush()

        # 7. Create Violation
        violation = Violation(
            scan_id=scan.id,
            rule_id=rule.id,
            field_name="consumer_care_address",
            status=ComplianceStatus.FAIL,
            reason="Consumer care address missing on package label",
        )
        session.add(violation)
        await session.flush()

        # 8. Create Evidence
        evidence = Evidence(
            scan_id=scan.id,
            violation_id=violation.id,
            rule_id=rule.id,
            field="consumer_care_address",
            source_image="/uploads/back.jpg",
            ocr_confidence=0.96,
            file_hash="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        )
        session.add(evidence)

        # 9. Create Review
        review = Review(
            scan_id=scan.id,
            violation_id=violation.id,
            reviewer_id=user.id,
            decision=ReviewDecision.ACCEPT,
            notes="Confirmed violation upon physical package inspection.",
            original_ai_result={"status": "FAIL", "reason": "Consumer care address missing"},
        )
        session.add(review)

        # 10. Create TrustScore
        trust = TrustScore(
            product_id=product.id,
            score=90.0,
            verified_violations_count=1,
            total_inspections_count=1,
        )
        session.add(trust)

        await session.commit()

        # --- VERIFICATION QUERIES ---
        res = await session.execute(select(User).where(User.id == user.id))
        fetched_user = res.scalar_one()
        assert fetched_user.email == "inspector.gadget@nirikshak.gov.in"
        assert fetched_user.role == UserRole.OFFICER

        res = await session.execute(select(Scan).where(Scan.id == scan.id))
        fetched_scan = res.scalar_one()
        assert fetched_scan.overall_compliance == ComplianceStatus.FAIL

        res = await session.execute(select(Rule).where(Rule.rule_id == "RULE-LM-001"))
        fetched_rule = res.scalar_one()
        assert fetched_rule.title == "Mandatory Consumer Care Address"
