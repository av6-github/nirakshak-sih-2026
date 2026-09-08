"""
NIRIKSHAK AI - Local Embeddings Service.

Uses sentence-transformers (all-MiniLM-L6-v2) for local 384-dimensional vector embeddings.
"""

from typing import List
from app.core.config import get_settings
from app.core.logging import get_logger

logger = get_logger("services.rag.embeddings")
settings = get_settings()

_model_instance = None


def get_embedding_model():
    """Lazy initialization of SentenceTransformer model."""
    global _model_instance
    if _model_instance is None:
        try:
            from sentence_transformers import SentenceTransformer
            model_name = settings.embedding_model or "all-MiniLM-L6-v2"
            logger.info(f"Loading local embedding model: {model_name}")
            _model_instance = SentenceTransformer(model_name)
            logger.info("Local embedding model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load sentence-transformers model: {e}")
            raise RuntimeError(f"Embedding model initialization failed: {e}")
    return _model_instance


class EmbeddingService:
    """Service to generate dense vector embeddings for text chunks and queries."""

    def __init__(self):
        self.dimension = 384  # Default dimension for all-MiniLM-L6-v2

    def embed_text(self, text: str) -> List[float]:
        """Generate embedding vector for a single string."""
        model = get_embedding_model()
        vector = model.encode(text, convert_to_numpy=True).tolist()
        return vector

    def embed_batch(self, texts: List[str]) -> List[List[float]]:
        """Generate embedding vectors for a batch of strings."""
        if not texts:
            return []
        model = get_embedding_model()
        vectors = model.encode(texts, convert_to_numpy=True, batch_size=32).tolist()
        return vectors
