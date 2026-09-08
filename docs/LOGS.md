# NIRIKSHAK AI Engineering Decision Log

---

## Decision ID: DEC-001

Date: 2026-09-06

Decision:
Use Groq API (llama-3.1-8b-instant) as the LLM provider for declaration extraction and RAG query processing.

Reason:
- Free tier with generous rate limits (30 RPM)
- Very fast inference (Groq's LPU hardware)
- Llama 3.1 8B is capable enough for structured extraction tasks
- User preference

Alternatives Considered:
- Google Gemini: Excellent free tier, but user chose Groq
- OpenAI: Requires paid billing setup
- Local LLM: Too resource-intensive for development

Consequences:
- Need GROQ_API_KEY environment variable
- Model may need upgrade to 70B for complex extraction if 8B proves insufficient
- Can switch providers later via LLM_PROVIDER config

Related Files:
- .env
- backend/app/core/config.py

---

## Decision ID: DEC-002

Date: 2026-09-06

Decision:
Use local sentence-transformers (all-MiniLM-L6-v2) for embedding generation instead of API-based embeddings.

Reason:
- No API key dependency for embeddings
- Faster batch processing for 39+ legal PDFs
- Free, no rate limits
- 384-dimensional vectors are efficient for ChromaDB storage
- Good enough quality for legal document retrieval

Alternatives Considered:
- Gemini Embeddings API: Higher quality but adds API dependency
- all-mpnet-base-v2: Better quality (768-dim) but slower; can upgrade later
- OpenAI Embeddings: Paid, unnecessary dependency

Consequences:
- ~500MB model download on first run
- CPU-only inference (sufficient for batch ingestion and query-time embedding)
- If retrieval quality is poor, can upgrade to mpnet or API embeddings

Related Files:
- .env (EMBEDDING_PROVIDER=local, EMBEDDING_MODEL=all-MiniLM-L6-v2)
- backend/app/core/config.py

---

## Decision ID: DEC-003

Date: 2026-09-06

Decision:
Use PostgreSQL as transactional database and ChromaDB only for vector retrieval.

Reason:
- ChromaDB is not suitable for transactional relational data
- PostgreSQL provides proper relational integrity, joins, indexes, and ACID compliance
- Clear separation: PostgreSQL = structured app data, ChromaDB = RAG embeddings

Alternatives Considered:
- ChromaDB only: Cannot handle relational data
- MongoDB: Less suitable for relational compliance data with strict schema needs
- SQLite: Not suitable for concurrent access from multiple services

Consequences:
- Two databases to manage (both run in Docker, minimal overhead)
- Need async PostgreSQL driver (asyncpg) for FastAPI

Related Files:
- docker-compose.yml
- backend/app/core/database.py
- backend/app/core/config.py

---

## Decision ID: DEC-004

Date: 2026-09-06

Decision:
Run PaddleOCR inside Docker container (Python 3.11) rather than installing locally.

Reason:
- User has Python 3.12.4 locally; PaddleOCR has known compatibility issues with 3.12+
- Docker provides consistent environment across development machines
- Avoids Windows-specific PaddlePaddle installation issues
- System dependencies (libgl, poppler) are cleanly managed in Docker

Alternatives Considered:
- Local PaddleOCR install: Risk of compatibility issues with Python 3.12
- Tesseract OCR: Lower accuracy for Indian language documents
- Cloud OCR APIs: Adds cost and external dependency

Consequences:
- First Docker build will be slow (downloading PaddlePaddle + models)
- OCR processing is CPU-only (GPU support deferred per user request)

Related Files:
- backend/Dockerfile
- backend/requirements.txt
- docker-compose.yml

---

## Decision ID: DEC-005

Date: 2026-09-05

Decision:
Use Celery + Redis for background task processing.

Reason:
- OCR and document ingestion are slow operations that shouldn't block API responses
- Celery is production-proven for Python async task queues
- Redis serves dual purpose: task broker and result backend
- Simple setup via Docker Compose

Alternatives Considered:
- FastAPI BackgroundTasks: Too simple, no retry/monitoring
- Dramatiq: Less ecosystem support than Celery
- RQ (Redis Queue): Simpler but fewer features for task monitoring

Consequences:
- Additional Redis service in Docker
- Separate worker container needed
- Task results accessible via Celery result backend

Related Files:
- docker-compose.yml
- backend/app/workers/celery_app.py
- backend/app/workers/tasks.py

---

## Decision ID: DEC-006

Date: 2026-09-06

Decision:
Implement 3-Layer Declaration Extraction Pipeline (Layer 1: Regex, Layer 2: Groq LLM Schema, Layer 3: Validation).

Reason:
- Ensures high accuracy and resilience: regex handles well-defined numbers (MRP, Dates, Emails), while LLM handles freeform names and complex label layouts
- Prevents hallucinated data through Layer 3 strict validation rules
- Operates reliably even if LLM API is temporarily unavailable

Alternatives Considered:
- LLM-only extraction: Risk of missing exact numbers or hallucinating values
- Regex-only extraction: Cannot parse varied manufacturer names or address text formats

Consequences:
- Modular extraction pipeline in `backend/app/services/extraction/declaration_extractor.py`
- Stores raw extraction data alongside normalized fields for transparency

Related Files:
- backend/app/services/extraction/declaration_extractor.py

---

## Decision ID: DEC-007

Date: 2026-09-06

Decision:
Separate AI fact extraction from legal compliance decisions via a versioned Deterministic Rule Engine.

Reason:
- Strict compliance requirement: LLMs must NOT independently decide legal compliance
- Rule engine produces reproducible PASS, FAIL, or REVIEW statuses
- Generates SHA-256 evidence package hashes for tamper prevention

Alternatives Considered:
- Prompting LLM to output pass/fail: Violates system architectural principles

Consequences:
- Rule logic encapsulated in `backend/app/services/rules/rule_engine.py`
- Stores tamper-proof SHA-256 evidence hashes in PostgreSQL `evidence` table

Related Files:
- backend/app/services/rules/rule_engine.py

---

## Decision ID: DEC-008

Date: 2026-09-06

Decision:
Use Flutter with Riverpod, GoRouter, and Dio for mobile application.

Reason:
- High performance, modern UI with rich aesthetic dark design system
- Cross-platform architecture (Android first, iOS ready)
- Riverpod for clean reactive state management, GoRouter for declarative routing

Alternatives Considered:
- React Native: Flutter provides superior performance for camera/image manipulation
- Plain Provider: Riverpod provides better compile-time safety

Related Files:
- mobile/pubspec.yaml
- mobile/lib/main.dart
- mobile/lib/core/theme.dart

---

## Decision ID: DEC-009

Date: 2026-09-06

Decision:
Implemented remaining core goals: 
1. Evidence Bounding-Box Crops using PaddleOCR coordinates.
2. Versioned YAML Legal Rule Engine (`rule_definitions.yaml`).
3. SHA-256 PDF report signing with full embedded images and citations.
4. Persistent Digital Twin tracking via `products` table matching.
5. Trust Portal with officer-assigned (not AI-assigned) ratings.
6. Unified Full-Screen image viewing on both Web and Mobile platforms.

Reason:
- Ensures full alignment with the 8 original goals of the Nirikshak AI system.
- Separates AI scores from official Trust Ratings to preserve human authority.
- The YAML rule engine ensures rules can be updated without backend redeployment, and versions are tied to generated evidence.

Alternatives Considered:
- Storing full images instead of crops: Rejected because officers need precise pointers to where the AI found the text.

Consequences:
- The backend PDF generator needs access to the local storage path for images to embed them.
- Next.js and Flutter dashboards are fully synced in feature parity (including Trust Portal tab).

Related Files:
- backend/app/services/pipeline.py
- backend/app/services/rules/rule_engine.py
- web/src/app/dashboard/page.tsx
- mobile/lib/screens/details_screen.dart
