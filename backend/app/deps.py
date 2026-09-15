from collections.abc import Callable, Generator

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from .db import get_db
from .models import User
from .security import decode_access_token

bearer = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    try:
        user_id = decode_access_token(credentials.credentials)
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token si sahihi au imekwisha") from exc
    user = db.get(User, user_id)
    if user is None or not user.is_active or user.is_blocked:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Mtumiaji hana ruhusa ya kuingia")
    return user


def require_roles(*roles: str) -> Callable:
    def dependency(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Huna ruhusa ya kufanya tendo hili")
        return user

    return dependency


def require_not_staff(user: User = Depends(get_current_user)) -> User:
    if user.role == "STAFF":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Staff hana ruhusa ya kufanya tendo hili")
    return user
