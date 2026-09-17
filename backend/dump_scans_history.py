import asyncio
from sqlalchemy import text
from app.core.database import async_session_factory

async def dump_scan():
    async with async_session_factory() as session:
        query = text("""
            SELECT id, image_urls, created_at 
            FROM scans 
            ORDER BY created_at DESC 
            LIMIT 5
        """)
        result = await session.execute(query)
        rows = result.fetchall()
        for r in rows:
            print(f"[{r.created_at}] ID: {r.id} -> {str(r.image_urls)[:80]}...")

if __name__ == "__main__":
    asyncio.run(dump_scan())
