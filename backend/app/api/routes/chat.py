"""
NIRIKSHAK AI - RAG Chatbot API Routes.
"""

from typing import Any, Dict
from fastapi import APIRouter
from pydantic import BaseModel

from app.services.rag.rag_pipeline import RAGPipeline

router = APIRouter(prefix="/chat", tags=["RAG Chatbot"])
rag_pipeline = RAGPipeline()

class ChatRequest(BaseModel):
    message: str

@router.post("")
async def chat_with_legal_bot(request: ChatRequest) -> Dict[str, Any]:
    """
    RAG-powered Chatbot endpoint.
    Retrieves legal context based on the user's message and returns it.
    """
    # 1. Retrieve Context
    context = rag_pipeline.search_legal_context(query=request.message, top_k=3)
    
    # 2. Extract citations
    citations = []
    response_parts = []
    
    if context.get("retrieved_documents"):
        response_parts.append("Based on the Legal Metrology Rules, here is the relevant information:\n")
        for i, doc in enumerate(context["retrieved_documents"], 1):
            text_snippet = doc.get("text", "").strip()
            doc_name = doc.get("metadata", {}).get("document_name", "Legal Metrology PDF")
            rule_id = doc.get("metadata", {}).get("rule_id", "Unknown Rule")
            citations.append(f"[{i}] {doc_name} (Rule {rule_id})")
            
            response_parts.append(f"Snippet [{i}]: {text_snippet}")
            
        response_parts.append("\nSources: " + ", ".join(citations))
        final_answer = "\n".join(response_parts)
    else:
        final_answer = "I'm sorry, I couldn't find specific clauses in the Legal Metrology Act regarding that query."

    return {
        "reply": final_answer,
        "context": context,
    }
