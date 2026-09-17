import asyncio
from sqlalchemy import text
from app.core.database import async_session_factory

async def dump_scan():
    async with async_session_factory() as session:
        query = text("""
            SELECT id, image_urls 
            FROM scans 
            ORDER BY created_at DESC 
            LIMIT 1
        """)
        result = await session.execute(query)
        row = result.fetchone()
        print(f"LATEST SCAN: {row.id}")
        print(f"IMAGE URLS: {row.image_urls}")

if __name__ == "__main__":
    asyncio.run(dump_scan())
