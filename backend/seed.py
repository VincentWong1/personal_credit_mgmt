"""初始化默认管理员账户和预设风险事件类别。"""
import asyncio
from sqlalchemy import select
from app.database import engine, Base, async_session
from app.models.user import User
from app.models.risk_event import RiskCategory
from app.api.deps import hash_password
from app.config import settings

PRESET_CATEGORIES = ["安全违规", "质量问题", "考勤异常", "合同违约", "证照过期", "其他"]


async def seed():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as session:
        # Create default admin
        result = await session.execute(select(User).where(User.username == settings.DEFAULT_ADMIN_USERNAME))
        if not result.scalar_one_or_none():
            admin = User(
                username=settings.DEFAULT_ADMIN_USERNAME,
                hashed_password=hash_password(settings.DEFAULT_ADMIN_PASSWORD),
                display_name="系统管理员",
                role="admin",
            )
            session.add(admin)
            print(f"已创建默认管理员账户: {settings.DEFAULT_ADMIN_USERNAME}")
        else:
            print("管理员账户已存在，跳过创建")

        # Create preset risk categories
        for cat_name in PRESET_CATEGORIES:
            result = await session.execute(select(RiskCategory).where(RiskCategory.name == cat_name))
            if not result.scalar_one_or_none():
                session.add(RiskCategory(name=cat_name, is_preset=True))
                print(f"已创建预设类别: {cat_name}")

        await session.commit()
    print("种子数据初始化完成")


if __name__ == "__main__":
    asyncio.run(seed())
