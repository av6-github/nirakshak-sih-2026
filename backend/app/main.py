"""
NIRIKSHAK AI - FastAPI Application Entry Point.

Main application factory with lifecycle management, middleware, and route registration.
"""

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes.health import router as health_router
from app.api.routes.rag import router as rag_router
from app.api.routes.scans import router as scans_router
from app.api.routes.reviews import router as reviews_router
from app.api.routes.products import router as products_router
from app.api.routes.complaints import router as complaints_router
from app.api.routes.rules import router as rules_router
from app.api.routes.manufacturers import router as manufacturers_router
from app.api.routes.chat import router as chat_router
from app.api.routes.users import router as users_router
from app.api.routes.reports import router as reports_router
from app.core.config import get_settings
from app.core.database import close_db, init_db
from app.core.logging import setup_logging

settings = get_settings()
logger = setup_logging("nirikshak.backend")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifecycle manager - startup and shutdown events."""
    # --- Startup ---
    logger.info("=" * 60)
    logger.info(f"Starting {settings.app_name} v{settings.app_version}")
    logger.info(f"Debug mode: {settings.debug}")
    logger.info(f"LLM Provider: {settings.llm_provider}")
    logger.info(f"Embedding Provider: {settings.embedding_provider}")
    logger.info("=" * 60)

    # Create logs directory
    os.makedirs("logs", exist_ok=True)

    # Initialize database tables
    try:
        await init_db()
        logger.info("Database tables initialized successfully.")
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        logger.warning("Backend starting without database - some features will be unavailable.")

    yield

    # --- Shutdown ---
    logger.info("Shutting down NIRIKSHAK AI backend...")
    await close_db()
    logger.info("Database connections closed.")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    application = FastAPI(
        title=settings.app_name,
        description=(
            "AI-guided Legal Metrology Compliance and Citizen Trust Platform. "
            "Photograph a packaged product → extract declarations → retrieve legal knowledge → "
            "evaluate compliance → generate evidence → allow human verification."
        ),
        version=settings.app_version,
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    # --- CORS Middleware ---
    application.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Restrict in production
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # --- Register Routes ---
    application.include_router(health_router)
    application.include_router(rag_router)
    application.include_router(scans_router)
    application.include_router(reviews_router)
    application.include_router(products_router)
    application.include_router(complaints_router)
    application.include_router(rules_router)
    application.include_router(manufacturers_router)
    application.include_router(chat_router)
    application.include_router(users_router)
    application.include_router(reports_router)

    # --- Static Files ---
    from fastapi.staticfiles import StaticFiles
    import os
    os.makedirs(settings.local_storage_path, exist_ok=True)
    application.mount("/uploads", StaticFiles(directory=settings.local_storage_path), name="uploads")

    @application.get("/", tags=["Root"])
    async def root():
        """Root endpoint - API information."""
        return {
            "name": settings.app_name,
            "version": settings.app_version,
            "status": "running",
            "docs": "/docs",
            "health": "/health",
        }

    return application


# Create the application instance
app = create_app()
