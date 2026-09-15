from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from .config import get_settings


class Base(DeclarativeBase):
    pass


engine = create_engine(get_settings().database_url, pool_pre_ping=True)
# PostgreSQL 18 with psycopg on Python 3.14 can return pg_catalog.version()
# as bytes; SQLAlchemy expects text while initializing the PostgreSQL dialect.
_original_server_version = engine.dialect._get_server_version_info


def _server_version_as_text(connection):
    value = connection.exec_driver_sql("select pg_catalog.version()").scalar()
    if isinstance(value, bytes):
        value = value.decode()
    import re

    match = re.search(r"(?:PostgreSQL|EnterpriseDB) (\d+)(?:\.(\d+))?", value)
    if match:
        return tuple(int(part or 0) for part in match.groups())
    return _original_server_version(connection)


engine.dialect._get_server_version_info = _server_version_as_text
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
