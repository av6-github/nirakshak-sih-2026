"""
NIRIKSHAK AI - RAG Legal Knowledge Retrieval API Routes.
"""

import os
from typing import Any, Dict, Optional
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from app.services.rag.rag_pipeline import RAGPipeline

router = APIRouter(prefix="/rag", tags=["RAG Pipeline"])
rag_service = RAGPipeline()


class SearchQueryRequest(BaseModel):
    query: str
    top_k: int = 5
    rule_id: Optional[str] = None


class BatchIngestRequest(BaseModel):
    directory_path: str = "./rag_documents"


@router.get("/stats")
async def get_rag_stats() -> Dict[str, Any]:
    """Get total indexed legal chunks in ChromaDB."""
    total_docs = rag_service.chroma.count_documents()
    return {
        "status": "active",
        "collection_name": rag_service.chroma.COLLECTION_NAME,
        "total_chunks_indexed": total_docs,
    }


@router.post("/search")
async def search_legal_knowledge(request: SearchQueryRequest) -> Dict[str, Any]:
    """
    Search Legal Metrology rules and amendments.

    Returns relevant legal context chunks with source citations and similarity scores.
    """
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Search query cannot be empty.")

    result = rag_service.search_legal_context(
        query=request.query,
        top_k=request.top_k,
        rule_id_filter=request.rule_id,
    )
    return result


@router.get("/search")
async def search_legal_knowledge_get(
    query: str = Query(..., description="Legal query string (e.g. MRP declaration requirement)"),
    top_k: int = Query(5, ge=1, le=20),
    rule_id: Optional[str] = None,
) -> Dict[str, Any]:
    """GET endpoint for simple legal search queries."""
    return rag_service.search_legal_context(
        query=query,
        top_k=top_k,
        rule_id_filter=rule_id,
    )


@router.post("/ingest/batch")
async def ingest_batch_documents(request: BatchIngestRequest) -> Dict[str, Any]:
    """Trigger batch ingestion of PDF legal documents from a directory into ChromaDB."""
    dir_path = request.directory_path
    # Handle folder name typo compatibility if applicable
    if not os.path.exists(dir_path) and os.path.exists("rag_documetns"):
        dir_path = "rag_documetns"

    if not os.path.exists(dir_path):
        raise HTTPException(status_code=404, detail=f"Directory not found: {request.directory_path}")

    result = rag_service.ingest_directory(dir_path)
    return result
