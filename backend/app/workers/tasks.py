"""
NIRIKSHAK AI - Placeholder Background Tasks.

Actual task implementations will be added in later phases.
"""

from app.workers.celery_app import celery_app


@celery_app.task(name="tasks.health_check")
def health_check_task() -> dict:
    """Simple task to verify Celery worker is operational."""
    return {"status": "worker_healthy", "message": "Celery worker is running."}
