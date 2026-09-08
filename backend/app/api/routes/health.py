"""
NIRIKSHAK AI - Health Check Routes.

Provides health/readiness endpoints for the backend and all dependencies.
"""

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.database import get_db

router = APIRouter(prefix="/health", tags=["Health"])

settings = get_settings()


@router.get("")
async def health_check():
    """Basic health check - confirms the backend is running."""
    return {
        "status": "healthy",
        "service": settings.app_name,
        "version": settings.app_version,
    }


@router.get("/ready")
async def readiness_check(db: AsyncSession = Depends(get_db)):
    """
    Readiness check - verifies all critical dependencies.

    Checks:
    - PostgreSQL connection
    - ChromaDB connection
    - Redis connection
    """
    checks = {}

    # Check PostgreSQL
    try:
        result = await db.execute(text("SELECT 1"))
        result.scalar()
        checks["postgres"] = {"status": "healthy"}
    except Exception as e:
        checks["postgres"] = {"status": "unhealthy", "error": str(e)}

    # Check ChromaDB
    try:
        import chromadb

        chroma_client = chromadb.HttpClient(
            host=settings.chroma_host,
            port=settings.chroma_port,
        )
        chroma_client.heartbeat()
        checks["chromadb"] = {"status": "healthy"}
    except Exception as e:
        checks["chromadb"] = {"status": "unhealthy", "error": str(e)}

    # Check Redis
    try:
        import redis as redis_lib

        r = redis_lib.Redis(
            host=settings.redis_host,
            port=settings.redis_port,
            socket_timeout=5,
        )
        r.ping()
        r.close()
        checks["redis"] = {"status": "healthy"}
    except Exception as e:
        checks["redis"] = {"status": "unhealthy", "error": str(e)}

    # Overall status
    all_healthy = all(c["status"] == "healthy" for c in checks.values())

    return {
        "status": "ready" if all_healthy else "degraded",
        "checks": checks,
    }
