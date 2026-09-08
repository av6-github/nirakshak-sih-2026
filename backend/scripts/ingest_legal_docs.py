"""
NIRIKSHAK AI - Legal Metrology PDF Batch Ingestion Script.

Ingests all 39 legal metrology acts, rules, amendments, and SOP PDFs into ChromaDB vector store.
"""

import sys
import os
from pathlib import Path

# Add backend directory to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.core.logging import setup_logging
from app.services.rag.rag_pipeline import RAGPipeline

logger = setup_logging("scripts.ingest_legal_docs")

def main():
    rag_dir = Path("./rag_documetns").resolve()
    if not rag_dir.exists():
        rag_dir = Path("./rag_documents").resolve()

    if not rag_dir.exists():
        logger.error(f"RAG document folder not found at {rag_dir}")
        return

    logger.info(f"Starting batch RAG ingestion from: {rag_dir}")
    pipeline = RAGPipeline()
    result = pipeline.ingest_directory(str(rag_dir))

    logger.info("=" * 60)
    logger.info("BATCH INGESTION COMPLETED SUMMARY:")
    logger.info(f"Total Documents: {result['total_documents_processed']}")
    logger.info(f"Successfully Indexed: {result['successful_documents']}")
    logger.info(f"Failed Documents: {result['failed_documents']}")
    logger.info(f"Total Chunks Indexed: {result['total_chunks_indexed']}")
    logger.info(f"ChromaDB Vector Count: {result['vector_store_total_count']}")
    logger.info("=" * 60)

if __name__ == "__main__":
    main()
