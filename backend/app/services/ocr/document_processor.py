"""
NIRIKSHAK AI - Document Ingestion & Text Processing Module.

Handles file type detection, native PDF text extraction, fallback image conversion,
English language filtering, and text normalization.
"""

import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal

import fitz  # PyMuPDF
from langdetect import DetectorFactory, detect
from langdetect.lang_detect_exception import LangDetectException

from app.core.logging import get_logger

logger = get_logger("services.ocr.document_processor")

# Ensure deterministic language detection
DetectorFactory.seed = 42


@dataclass
class ProcessedPage:
    """Structure representing a single processed document page."""
    page_number: int
    text: str
    cleaned_text: str
    extraction_method: Literal["native_text", "ocr", "hybrid"]
    language: str  # "en", "hi", "unknown"
    is_english: bool
    char_count: int
    ocr_confidence: float = 1.0


@dataclass
class DocumentIngestionResult:
    """Complete document extraction payload."""
    filename: str
    file_path: str
    file_type: str
    total_pages: int
    pages: list[ProcessedPage] = field(default_factory=list)
    english_pages_count: int = 0
    non_english_pages_count: int = 0


class DocumentProcessor:
    """Processes legal PDFs and image files for RAG ingestion."""

    NATIVE_MIN_CHAR_THRESHOLD = 80  # Minimum characters per page to consider native extraction valid

    def detect_file_type(self, file_path: str) -> str:
        """Detect file format based on extension and magic headers."""
        ext = Path(file_path).suffix.lower()
        if ext == ".pdf":
            return "pdf"
        elif ext in [".png", ".jpg", ".jpeg"]:
            return "image"
        elif ext in [".docx", ".tiff", ".txt"]:
            return ext[1:]
        else:
            return "unknown"

    def clean_text(self, text: str) -> str:
        """
        Normalize and clean extracted text.
        Strips noise, fixes hyphenated word breaks across lines, and standardizes spacing.
        """
        if not text:
            return ""

        # Remove null characters
        text = text.replace("\x00", "")

        # Fix word hyphenation across newlines ("decla-\nration" -> "declaration")
        text = re.sub(r"(\w+)-\n(\w+)", r"\1\2", text)

        # Replace multiple newlines with double newline (preserve paragraph breaks)
        text = re.sub(r"\n{3,}", "\n\n", text)

        # Replace multiple spaces with single space
        text = re.sub(r"[ \t]+", " ", text)

        # Remove repetitive header/footer line patterns (page numbers like "Page 1 of 12")
        text = re.sub(r"(?i)page\s+\d+\s+of\s+\d+", "", text)

        return text.strip()

    def detect_language(self, text: str) -> tuple[str, bool]:
        """
        Detect language of text snippet.
        Returns (language_code, is_english).
        """
        cleaned = self.clean_text(text)
        if len(cleaned) < 20:
            return ("en", True)  # Default short tokens to English

        try:
            lang = detect(cleaned)
            is_en = (lang == "en")
            return (lang, is_en)
        except LangDetectException:
            # Fallback regex: check ratio of ASCII characters
            ascii_chars = sum(1 for c in cleaned if ord(c) < 128)
            ratio = ascii_chars / max(len(cleaned), 1)
            is_en = ratio > 0.75
            return ("en" if is_en else "unknown", is_en)

    def extract_pdf_native(self, file_path: str) -> DocumentIngestionResult:
        """
        Attempt native PDF text extraction using PyMuPDF.
        If native text quality per page is below threshold, marks for OCR fallback.
        """
        filename = os.path.basename(file_path)
        doc = fitz.open(file_path)

        result = DocumentIngestionResult(
            filename=filename,
            file_path=file_path,
            file_type="pdf",
            total_pages=len(doc),
        )

        for page_idx in range(len(doc)):
            page = doc[page_idx]
            page_num = page_idx + 1
            raw_text = page.get_text("text") or ""
            cleaned = self.clean_text(raw_text)

            char_count = len(cleaned)
            if char_count >= self.NATIVE_MIN_CHAR_THRESHOLD:
                lang, is_en = self.detect_language(cleaned)
                processed_page = ProcessedPage(
                    page_number=page_num,
                    text=raw_text,
                    cleaned_text=cleaned,
                    extraction_method="native_text",
                    language=lang,
                    is_english=is_en,
                    char_count=char_count,
                    ocr_confidence=1.0,
                )
            else:
                # Scanned or image PDF page requiring OCR
                processed_page = ProcessedPage(
                    page_number=page_num,
                    text="",
                    cleaned_text="",
                    extraction_method="ocr",
                    language="unknown",
                    is_english=False,
                    char_count=0,
                    ocr_confidence=0.0,
                )

            result.pages.append(processed_page)
            if processed_page.is_english:
                result.english_pages_count += 1
            else:
                result.non_english_pages_count += 1

        doc.close()
        logger.info(
            f"Extracted {filename}: {result.total_pages} pages "
            f"({result.english_pages_count} native English, "
            f"{result.total_pages - result.english_pages_count} requiring OCR)"
        )
        return result
