"""
NIRIKSHAK AI - Central RAG Pipeline Manager.

Orchestrates Legal Metrology PDF document ingestion, semantic chunking,
ChromaDB vector embedding, and context retrieval for compliance evaluation.
"""

import os
import glob
from typing import Any, Dict, List, Optional

from app.core.logging import get_logger
from app.services.ocr.document_processor import DocumentProcessor
from app.services.rag.chroma_service import ChromaService
from app.services.rag.parser import LegalDocumentParser

logger = get_logger("services.rag.rag_pipeline")


class RAGPipeline:
    """End-to-end RAG service for ingestion and retrieval."""

    def __init__(self):
        self.doc_processor = DocumentProcessor()
        self.parser = LegalDocumentParser()
        self.chroma = ChromaService()

    def ingest_single_document(self, file_path: str) -> int:
        """
        Ingest a single legal PDF or document into ChromaDB.

        1. Extract text and metadata per page (handling OCR fallback)
        2. Filter English pages
        3. Parse & chunk semantically with rule boundaries
        4. Upsert into ChromaDB
        """
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Document file not found: {file_path}")

        file_name = os.path.basename(file_path)
        doc_id = os.path.splitext(file_name)[0].lower().replace(" ", "_")

        logger.info(f"Starting ingestion for: {file_name}")

        # 1. Extraction
        extraction_res = self.doc_processor.extract_pdf_native(file_path)

        # 2. Parsing & Chunking
        chunks = self.parser.chunk_document_pages(
            document_id=doc_id,
            document_name=file_name,
            pages=extraction_res.pages,
            document_type="legal_rule",
        )

        if not chunks:
            logger.warning(f"No valid English chunks produced for {file_name}")
            return 0

        # 3. ChromaDB storage
        count = self.chroma.add_legal_chunks(chunks)
        logger.info(f"Ingestion complete for {file_name}: {count} chunks indexed.")
        return count

    def ingest_directory(self, dir_path: str) -> Dict[str, Any]:
        """
        Batch ingest all PDF documents from a directory (e.g., rag_documetns/).
        """
        pdf_files = glob.glob(os.path.join(dir_path, "*.pdf"))
        logger.info(f"Found {len(pdf_files)} PDF documents in {dir_path}")

        total_chunks = 0
        successful_docs = 0
        failed_docs = 0

        for pdf_file in pdf_files:
            try:
                num_chunks = self.ingest_single_document(pdf_file)
                total_chunks += num_chunks
                successful_docs += 1
            except Exception as e:
                logger.error(f"Failed to ingest document {pdf_file}: {e}")
                failed_docs += 1

        return {
            "total_documents_processed": len(pdf_files),
            "successful_documents": successful_docs,
            "failed_documents": failed_docs,
            "total_chunks_indexed": total_chunks,
            "vector_store_total_count": self.chroma.count_documents(),
        }

    def search_legal_context(
        self,
        query: str,
        top_k: int = 5,
        rule_id_filter: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Search vector database for relevant legal rules and citations.

        Returns structured output guaranteed matching specification format.
        """
        metadata_filter = {}
        if rule_id_filter:
            metadata_filter["rule_id"] = rule_id_filter

        retrieved_docs = self.chroma.search(
            query=query,
            top_k=top_k,
            metadata_filter=metadata_filter if metadata_filter else None,
        )

        return {
            "query": query,
            "retrieved_documents_count": len(retrieved_docs),
            "retrieved_documents": retrieved_docs,
        }
