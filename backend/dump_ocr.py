import asyncio
from sqlalchemy import text
from app.core.database import async_session_factory

async def dump_ocr():
    async with async_session_factory() as session:
        query = text("""
            SELECT raw_text, image_url 
            FROM ocr_results 
            ORDER BY created_at DESC 
            LIMIT 3
        """)
        result = await session.execute(query)
        rows = result.fetchall()
        print("--- LATEST OCR RESULTS ---")
        for i, row in enumerate(rows):
            print(f"\\nIMAGE: {row.image_url}")
            print(f"RAW TEXT:\\n{row.raw_text}\\n" + "-"*40)

if __name__ == "__main__":
    asyncio.run(dump_ocr())
