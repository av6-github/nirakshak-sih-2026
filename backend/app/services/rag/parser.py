"""
NIRIKSHAK AI - Legal Metrology Document Parser & Semantic Chunker.

Chunks legal rules, guidelines, and amendments preserving rule boundaries and section headers.
"""

import re
from dataclasses import dataclass, field
from typing import Any


@dataclass
class LegalChunk:
    """Structure representing a semantically chunked legal document section."""
    chunk_id: str
    document_id: str
    document_name: str
    document_type: str  # "legal_rule", "amendment", "guideline", "sop"
    page_number: int
    rule_id: str | None
    section: str | None
    title: str | None
    content: str
    language: str = "en"
    source_file: str = ""
    metadata: dict[str, Any] = field(default_factory=dict)


class LegalDocumentParser:
    """Parses legal PDFs into structured, semantically meaningful chunks."""

    RULE_HEADER_PATTERN = re.compile(
        r"(?i)^(?:rule|section|clause|paragraph|provision)\s+(\d+(?:\([\d\w]+\))?)",
        re.MULTILINE,
    )

    def extract_rule_id(self, text: str) -> str | None:
        """Extract explicit Rule or Section identifier if present."""
        match = self.RULE_HEADER_PATTERN.search(text)
        if match:
            rule_num = match.group(1)
            return f"RULE-LM-{rule_num}"
        return None

    def chunk_document_pages(
        self,
        document_id: str,
        document_name: str,
        pages: list[Any],  # list of ProcessedPage objects
        document_type: str = "legal_rule",
        chunk_size: int = 800,
        chunk_overlap: int = 150,
    ) -> list[LegalChunk]:
        """
        Chunk document pages semantically:
        1. Keeps rule headers intact
        2. Merges paragraph blocks up to `chunk_size` characters
        3. Maintains chunk overlap so boundaries don't lose context
        """
        chunks: list[LegalChunk] = []

        for page in pages:
            # Skip non-English pages for current RAG pipeline (Principle 6)
            if not page.is_english or not page.cleaned_text:
                continue

            page_text = page.cleaned_text
            page_num = page.page_number

            # Split page text into logical paragraphs
            paragraphs = [p.strip() for p in page_text.split("\n\n") if p.strip()]

            current_chunk_text = ""
            current_rule_id = None
            current_section = None
            chunk_seq = 1

            for paragraph in paragraphs:
                # Check if paragraph introduces a new Rule / Section header
                detected_rule = self.extract_rule_id(paragraph)
                if detected_rule:
                    current_rule_id = detected_rule
                    first_line = paragraph.split("\n")[0]
                    current_section = first_line[:100]

                if len(current_chunk_text) + len(paragraph) + 2 <= chunk_size:
                    if current_chunk_text:
                        current_chunk_text += "\n\n" + paragraph
                    else:
                        current_chunk_text = paragraph
                else:
                    # Emit current chunk
                    if current_chunk_text:
                        c_id = f"{document_id}_p{page_num}_c{chunk_seq}"
                        chunks.append(
                            LegalChunk(
                                chunk_id=c_id,
                                document_id=document_id,
                                document_name=document_name,
                                document_type=document_type,
                                page_number=page_num,
                                rule_id=current_rule_id,
                                section=current_section,
                                title=current_section or document_name,
                                content=current_chunk_text,
                                language="en",
                                source_file=document_name,
                                metadata={
                                    "document_id": document_id,
                                    "document_name": document_name,
                                    "document_type": document_type,
                                    "page_number": page_num,
                                    "rule_id": current_rule_id or "GENERAL",
                                    "language": "en",
                                },
                            )
                        )
                        chunk_seq += 1

                    # Start next chunk with overlap
                    overlap_text = current_chunk_text[-chunk_overlap:] if len(current_chunk_text) > chunk_overlap else ""
                    current_chunk_text = (overlap_text + "\n\n" + paragraph).strip()

            # Emit final page chunk if remaining
            if current_chunk_text:
                c_id = f"{document_id}_p{page_num}_c{chunk_seq}"
                chunks.append(
                    LegalChunk(
                        chunk_id=c_id,
                        document_id=document_id,
                        document_name=document_name,
                        document_type=document_type,
                        page_number=page_num,
                        rule_id=current_rule_id,
                        section=current_section,
                        title=current_section or document_name,
                        content=current_chunk_text,
                        language="en",
                        source_file=document_name,
                        metadata={
                            "document_id": document_id,
                            "document_name": document_name,
                            "document_type": document_type,
                            "page_number": page_num,
                            "rule_id": current_rule_id or "GENERAL",
                            "language": "en",
                        },
                    )
                )

        return chunks
