"""
NIRIKSHAK AI - Product Scan API Routes.
"""

import os
import uuid
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models import Scan
from app.models.enums import ScanStatus
from app.services.pipeline import CompliancePipeline
from app.services.storage import StorageService

router = APIRouter(prefix="/scans", tags=["Product Scans"])

storage_service = StorageService()
pipeline_service = CompliancePipeline()


@router.post("", status_code=201)
async def create_scan_session(
    file: UploadFile = File(...),
    back_file: Optional[UploadFile] = File(None),
    top_file: Optional[UploadFile] = File(None),
    bottom_file: Optional[UploadFile] = File(None),
    user_id: Optional[uuid.UUID] = Form(None),
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    Upload product package photos (front required, back/top/bottom optional) and create a new scan session.
    """
    # Save front image
    front_path = await storage_service.save_upload_file(file, subfolder="scans")

    image_urls = {"front": front_path}

    # Save extra images if provided
    if back_file and back_file.filename:
        image_urls["back"] = await storage_service.save_upload_file(back_file, subfolder="scans")
    
    if top_file and top_file.filename:
        image_urls["top"] = await storage_service.save_upload_file(top_file, subfolder="scans")

    if bottom_file and bottom_file.filename:
        image_urls["bottom"] = await storage_service.save_upload_file(bottom_file, subfolder="scans")

    # Create Scan database record
    scan = Scan(
        user_id=user_id,
        status=ScanStatus.PENDING,
        image_urls=image_urls,
    )
    db.add(scan)
    await db.commit()
    await db.refresh(scan)

    return {
        "scan_id": str(scan.id),
        "status": scan.status.value,
        "image_urls": image_urls,
        "message": "Scan session created successfully. Call POST /scans/{scan_id}/process to execute compliance pipeline.",
    }


def _resolve_image_path(rel_path: str) -> Optional[str]:
    """Convert a stored relative path to an absolute local file path."""
    abs_path = os.path.join("./data", rel_path.lstrip("/"))
    if os.path.exists(abs_path):
        return abs_path
    abs_path = os.path.join("./data/uploads/scans", os.path.basename(rel_path))
    if os.path.exists(abs_path):
        return abs_path
    return None


@router.post("/{scan_id}/process")
async def process_scan_endpoint(
    scan_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    Trigger AI OCR, extraction, RAG, rule evaluation, and evidence generation for a scan session.
    """
    scan = await db.get(Scan, scan_id)
    if not scan:
        raise HTTPException(status_code=404, detail="Scan session not found.")

    image_urls = scan.image_urls or {}
    if not image_urls:
        raise HTTPException(status_code=400, detail="Scan record has no attached image URLs.")

    # Resolve all image paths (front, back, etc.)
    image_paths = []
    for side in ["front", "back", "top", "bottom", "main"]:
        rel_path = image_urls.get(side)
        if rel_path:
            abs_path = _resolve_image_path(rel_path)
            if abs_path:
                image_paths.append(abs_path)

    if not image_paths:
        raise HTTPException(status_code=400, detail="No uploaded image files found on disk. Please re-upload.")

    result = await pipeline_service.process_scan(
        scan_id=scan.id,
        image_paths=image_paths,
        db=db,
    )
    return result


@router.get("/{scan_id}")
async def get_scan_details(
    scan_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """Get full details, declarations, violations, and evidence for a scan."""
    scan = await db.get(Scan, scan_id)
    if not scan:
        raise HTTPException(status_code=404, detail="Scan record not found.")

    return {
        "scan_id": str(scan.id),
        "status": scan.status.value,
        "overall_compliance": scan.overall_compliance.value if scan.overall_compliance else None,
        "image_urls": scan.image_urls,
        "created_at": scan.created_at.isoformat(),
        "completed_at": scan.completed_at.isoformat() if scan.completed_at else None,
    }
