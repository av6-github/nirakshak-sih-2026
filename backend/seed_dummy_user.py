import asyncio
import uuid
from datetime import datetime
from sqlalchemy import text
from app.core.database import async_session_factory

async def seed_user():
    async with async_session_factory() as session:
        # Insert a dummy user with the specific UUID
        user_id = "00000000-0000-0000-0000-000000000001"
        query = text("""
            INSERT INTO users (id, email, full_name, role, is_active, created_at, updated_at, hashed_password, reward_points) 
            VALUES (:id, :email, :full_name, :role, :is_active, :created_at, :updated_at, :hashed_password, :reward_points)
            ON CONFLICT (id) DO NOTHING
        """)
        await session.execute(query, {
            "id": user_id,
            "email": "test@example.com",
            "full_name": "Test User",
            "role": "CITIZEN",
            "is_active": True,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "hashed_password": "dummy_password_hash",
            "reward_points": 0
        })
        await session.commit()
        print("Dummy user created successfully!")

if __name__ == "__main__":
    asyncio.run(seed_user())
