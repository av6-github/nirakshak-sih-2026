"""
NIRIKSHAK AI - RAG Pipeline & Document Processing Verification Tests.
"""

import pytest
from app.services.ocr.document_processor import DocumentProcessor, ProcessedPage
from app.services.rag.parser import LegalDocumentParser


def test_document_processor_text_cleaning():
    """Test text cleaning, hyphenation removal, and normalization."""
    processor = DocumentProcessor()
    raw = "Mandatory decla-\nration on packaged commodities.\n\n\nPage 1 of 10   "
    cleaned = processor.clean_text(raw)
    assert "declaration" in cleaned
    assert "Page 1 of 10" not in cleaned


def test_language_detection():
    """Test English vs non-English language filtering."""
    processor = DocumentProcessor()
    english_text = "Every package shall bear a plain and conspicuous declaration of net quantity."
    lang, is_en = processor.detect_language(english_text)
    assert is_en is True
    assert lang == "en"


def test_legal_chunker():
    """Test semantic legal chunking preserves rule boundaries and metadata."""
    parser = LegalDocumentParser()
    sample_pages = [
        ProcessedPage(
            page_number=1,
            text="Rule 6 Declarations to be made on every package.\n(1) Every package shall specify MRP.",
            cleaned_text="Rule 6 Declarations to be made on every package.\n(1) Every package shall specify MRP.",
            extraction_method="native_text",
            language="en",
            is_english=True,
            char_count=100,
        )
    ]

    chunks = parser.chunk_document_pages(
        document_id="pcr_rules_2011",
        document_name="PCR_2011.pdf",
        pages=sample_pages,
    )

    assert len(chunks) >= 1
    first_chunk = chunks[0]
    assert first_chunk.document_id == "pcr_rules_2011"
    assert first_chunk.rule_id == "RULE-LM-6"
    assert first_chunk.metadata["rule_id"] == "RULE-LM-6"
    assert first_chunk.metadata["language"] == "en"
