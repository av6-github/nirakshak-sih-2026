"""
NIRIKSHAK AI - Object Storage Service.

Provides file upload abstraction supporting local disk and MinIO S3-compatible storage.
"""

import os
import uuid
from pathlib import Path
from fastapi import UploadFile

from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger("services.storage")
settings = get_settings()


class StorageService:
    """Manages file persistence for product label scans and evidence crops."""

    def __init__(self):
        self.backend = settings.storage_backend
        self.upload_dir = Path(settings.local_storage_path)
        self.upload_dir.mkdir(parents=True, exist_ok=True)

    async def save_upload_file(self, file: UploadFile, subfolder: str = "scans") -> str:
        """
        Save uploaded file to storage.
        Returns persistent relative file URL / path.
        """
        dest_folder = self.upload_dir / subfolder
        dest_folder.mkdir(parents=True, exist_ok=True)

        ext = Path(file.filename or "image.jpg").suffix
        filename = f"{uuid.uuid4().hex}{ext}"
        filepath = dest_folder / filename

        content = await file.read()
        with open(filepath, "wb") as f:
            f.write(content)

        relative_path = f"/uploads/{subfolder}/{filename}"
        logger.info(f"Saved file {file.filename} -> {relative_path}")
        return relative_path

    def save_bytes(self, data: bytes, filename: str, subfolder: str = "evidence") -> str:
        """Save raw bytes (e.g. cropped evidence image) to storage."""
        dest_folder = self.upload_dir / subfolder
        dest_folder.mkdir(parents=True, exist_ok=True)

        filepath = dest_folder / filename
        with open(filepath, "wb") as f:
            f.write(data)

        relative_path = f"/uploads/{subfolder}/{filename}"
        return relative_path
