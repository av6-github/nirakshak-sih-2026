"""
Tests for Health Check endpoints.

Verifies the backend can start and respond to health checks.
"""

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.asyncio
async def test_root_endpoint():
    """Test the root endpoint returns API information."""
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as client:
        response = await client.get("/")

    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "NIRIKSHAK AI"
    assert data["status"] == "running"
    assert "version" in data


@pytest.mark.asyncio
async def test_health_endpoint():
    """Test the basic health check endpoint."""
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as client:
        response = await client.get("/health")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "NIRIKSHAK AI"


@pytest.mark.asyncio
async def test_openapi_docs_available():
    """Test that OpenAPI documentation is accessible."""
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as client:
        response = await client.get("/openapi.json")

    assert response.status_code == 200
    data = response.json()
    assert data["info"]["title"] == "NIRIKSHAK AI"
