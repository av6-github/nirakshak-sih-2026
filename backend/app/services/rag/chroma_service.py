"""
NIRIKSHAK AI - ChromaDB Vector Database Manager.

Manages collection lifecycle, document upserts, vector search, and metadata filtering.
"""

from typing import Any, Dict, List, Optional
import chromadb
from chromadb.config import Settings as ChromaSettings

from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.rag.embeddings import EmbeddingService
from app.services.rag.parser import LegalChunk

logger = get_logger("services.rag.chroma_service")
settings = get_settings()


class ChromaService:
    """Interface for ChromaDB vector store operations."""

    COLLECTION_NAME = "legal_metrology_rules"

    def __init__(self):
        self.host = settings.chroma_host
        self.port = settings.chroma_port
        self._client: Optional[chromadb.HttpClient] = None
        self._embedding_service = EmbeddingService()

    @property
    def client(self) -> chromadb.HttpClient:
        """Get or initialize ChromaDB HTTP client."""
        if self._client is None:
            logger.info(f"Connecting to ChromaDB at {self.host}:{self.port}")
            self._client = chromadb.HttpClient(
                host=self.host,
                port=self.port,
                settings=ChromaSettings(anonymized_telemetry=False),
            )
        return self._client

    def get_or_create_collection(self):
        """Get or create default legal rules collection."""
        return self.client.get_or_create_collection(
            name=self.COLLECTION_NAME,
            metadata={"description": "Legal Metrology Acts, Rules, Amendments & SOPs"},
        )

    def count_documents(self) -> int:
        """Return total document chunks in vector store."""
        try:
            collection = self.get_or_create_collection()
            return collection.count()
        except Exception as e:
            logger.error(f"Error counting ChromaDB documents: {e}")
            return 0

    def add_legal_chunks(self, chunks: List[LegalChunk]) -> int:
        """
        Upsert a batch of LegalChunk objects into ChromaDB.
        Generates embeddings locally and stores full metadata.
        """
        if not chunks:
            return 0

        collection = self.get_or_create_collection()

        ids = [chunk.chunk_id for chunk in chunks]
        documents = [chunk.content for chunk in chunks]
        metadatas = [chunk.metadata for chunk in chunks]

        # Generate embeddings
        logger.info(f"Generating embeddings for {len(chunks)} chunks...")
        embeddings = self._embedding_service.embed_batch(documents)

        # Upsert into ChromaDB
        collection.upsert(
            ids=ids,
            embeddings=embeddings,
            documents=documents,
            metadatas=metadatas,
        )
        logger.info(f"Successfully upserted {len(chunks)} legal chunks into ChromaDB.")
        return len(chunks)

    def search(
        self,
        query: str,
        top_k: int = 5,
        metadata_filter: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        """
        Perform semantic search against ChromaDB.

        Args:
            query: User text or extracted product declaration text
            top_k: Number of relevant chunks to retrieve
            metadata_filter: Optional ChromaDB metadata filter dict (e.g. {"rule_id": "RULE-LM-001"})

        Returns:
            List of structured match dicts containing rule_id, content, source, page, similarity_score
        """
        collection = self.get_or_create_collection()
        if collection.count() == 0:
            logger.warning("ChromaDB collection is empty.")
            return []

        # Embed query vector
        query_vector = self._embedding_service.embed_text(query)

        # Execute query
        results = collection.query(
            query_embeddings=[query_vector],
            n_results=min(top_k, collection.count()),
            where=metadata_filter if metadata_filter else None,
            include=["documents", "metadatas", "distances"],
        )

        matched_documents = []
        if results and results.get("ids") and results["ids"][0]:
            ids = results["ids"][0]
            docs = results["documents"][0]
            metas = results["metadatas"][0]
            distances = results["distances"][0]

            for i in range(len(ids)):
                # Convert distance to similarity score (l2 distance to similarity)
                distance = distances[i]
                similarity = max(0.0, 1.0 - (distance / 2.0))

                meta = metas[i] or {}
                matched_documents.append({
                    "chunk_id": ids[i],
                    "rule_id": meta.get("rule_id", "GENERAL"),
                    "document_id": meta.get("document_id", ""),
                    "document_name": meta.get("document_name", ""),
                    "document_type": meta.get("document_type", "legal_rule"),
                    "page": meta.get("page_number", 1),
                    "content": docs[i],
                    "similarity_score": round(similarity, 4),
                    "source": f"{meta.get('document_name', '')} (Page {meta.get('page_number', 1)})",
                })

        logger.info(f"Query '{query}' returned {len(matched_documents)} ChromaDB matches.")
        return matched_documents
