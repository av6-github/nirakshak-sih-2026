# NIRIKSHAK AI

**AI-guided Legal Metrology Compliance and Citizen Trust Platform**

> Photograph a packaged product → extract declarations → retrieve relevant legal knowledge → evaluate compliance → generate evidence → allow human verification → maintain compliance history.

---

## Architecture

```
Flutter Mobile App → FastAPI Backend → AI Processing Pipeline
                         │
              ┌──────────┼──────────┐
              │          │          │
         PostgreSQL   ChromaDB   MinIO
              │          │          │
              └──────────┼──────────┘
                         │
              ┌──────────┼──────────┐
              │          │          │
          PaddleOCR  RAG Pipeline  Rule Engine
```

## Quick Start

### Prerequisites

- Docker Desktop
- Python 3.11+
- Flutter SDK
- Android Studio + Android SDK
- Groq API Key ([get one here](https://console.groq.com/keys))

### Setup

1. Clone the repository
2. Copy environment file:
   ```bash
   cp .env.example .env
   ```
3. Add your Groq API key to `.env`
4. Start all services:
   ```bash
   docker compose up --build
   ```
5. Verify:
   - Backend API: http://localhost:8080
   - API Docs: http://localhost:8080/docs
   - Health Check: http://localhost:8080/health
   - MinIO Console: http://localhost:9001

### Running Backend Locally (without Docker)

```bash
cd backend
python -m venv venv
venv\Scripts\activate   # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
```

### Running Tests

```bash
cd backend
pytest
```

---

## Project Structure

```
sih/
├── backend/
│   ├── app/
│   │   ├── api/            # FastAPI routes
│   │   ├── core/           # Config, security, database, logging
│   │   ├── models/         # SQLAlchemy ORM models
│   │   ├── schemas/        # Pydantic schemas
│   │   ├── services/       # Business logic
│   │   │   ├── ocr/        # PaddleOCR integration
│   │   │   ├── extraction/ # Declaration extraction
│   │   │   ├── rag/        # RAG pipeline
│   │   │   ├── rules/      # Deterministic rule engine
│   │   │   ├── evidence/   # Evidence generation
│   │   │   └── trust/      # Trust score calculation
│   │   ├── repositories/   # Database access layer
│   │   ├── workers/        # Celery background tasks
│   │   └── tests/          # Test suite
│   ├── alembic/            # Database migrations
│   ├── data/               # Local data storage
│   └── scripts/            # Utility scripts
├── mobile/                 # Flutter application
├── rag_documetns/          # Legal metrology documents for RAG
├── docs/
│   ├── TASKS.md            # Project task tracker
│   └── LOGS.md             # Engineering decision log
├── docker-compose.yml
├── .env.example
└── README.md
```

## Key Design Principles

1. **AI extracts facts, rules make decisions** — LLMs never decide compliance
2. **Evidence first** — Every result is traceable with full audit trail
3. **Human authority** — Officers make final enforcement decisions
4. **Modular services** — Clean separation of concerns

## Tech Stack

| Component | Technology |
|---|---|
| Mobile | Flutter + Riverpod + GoRouter |
| Backend | FastAPI + SQLAlchemy + Pydantic |
| Database | PostgreSQL |
| Vector DB | ChromaDB |
| OCR | PaddleOCR |
| LLM | Groq (Llama 3.1) |
| Embeddings | sentence-transformers (local) |
| Task Queue | Celery + Redis |
| Object Storage | MinIO |
| Container | Docker Compose |
