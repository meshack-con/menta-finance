from sqlalchemy import select

from .config import get_settings
from .db import Base, SessionLocal, engine
from .models import User
from .security import hash_password


def seed_user(db, username: str, password: str, role: str, first_name: str) -> None:
    user = db.scalar(select(User).where(User.username == username))
    if user is None:
        db.add(User(username=username, password_hash=hash_password(password), role=role, first_name=first_name))
    else:
        user.password_hash = hash_password(password)
        user.role = role
        user.is_active = True
        user.is_blocked = False


def main() -> None:
    settings = get_settings()
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        seed_user(db, settings.seed_admin_username, settings.seed_admin_password, "ADMIN", "System Admin")
        seed_user(db, settings.seed_manager_username, settings.seed_manager_password, "MANAGER", "System Manager")
        db.commit()
    print("Seed complete. Change default passwords before production use.")


if __name__ == "__main__":
    main()