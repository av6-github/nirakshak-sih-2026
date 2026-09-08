import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.services.rag.rag_pipeline import RAGPipeline

def main():
    rag = RAGPipeline()
    results = rag.search_legal_context(query="MRP declaration requirements net quantity")
    print("RAG SEARCH RESULTS:", results)

if __name__ == "__main__":
    main()
