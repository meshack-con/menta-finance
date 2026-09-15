from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(80), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(20), default="STAFF", index=True)
    first_name: Mapped[str | None] = mapped_column(String(100))
    last_name: Mapped[str | None] = mapped_column(String(100))
    phone_number: Mapped[str | None] = mapped_column(String(40))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_blocked: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    clients: Mapped[list["Client"]] = relationship(back_populates="created_by")
    projects: Mapped[list["Project"]] = relationship(back_populates="created_by")

    @property
    def roles(self) -> str:
        return self.role

    @property
    def active(self) -> int:
        return 1 if self.is_active else 0

    @property
    def permissions(self) -> str:
        return "FULL" if self.role == "ADMIN" else "MANAGE" if self.role == "MANAGER" else "CLIENT_PROJECT_SELF"


class Client(Base):
    __tablename__ = "clients"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(180), index=True)
    phone: Mapped[str] = mapped_column(String(40))
    email: Mapped[str | None] = mapped_column(String(255))
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    created_by: Mapped[User] = relationship(back_populates="clients")
    projects: Mapped[list["Project"]] = relationship(back_populates="client", cascade="all, delete-orphan")


class Project(Base):
    __tablename__ = "projects"

    id: Mapped[int] = mapped_column(primary_key=True)
    client_id: Mapped[int] = mapped_column(ForeignKey("clients.id"), index=True)
    name: Mapped[str] = mapped_column(String(180), index=True)
    project_type: Mapped[str] = mapped_column(String(100))
    registered_at: Mapped[date] = mapped_column(Date)
    deadline: Mapped[date] = mapped_column(Date)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    paid: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=0)
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    client: Mapped[Client] = relationship(back_populates="projects")
    created_by: Mapped[User] = relationship(back_populates="projects")


class Expense(Base):
    __tablename__ = "expenses"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(180), index=True)
    category: Mapped[str] = mapped_column(String(100), index=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    paid_at: Mapped[date] = mapped_column(Date)
    description: Mapped[str | None] = mapped_column(Text)
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Income(Base):
    """Chanzo RASMI cha Income kwenye mfumo - kila mara Project inaposajiliwa
    ikiwa na 'paid' > 0, au Income mpya inaposajiliwa kwa Project iliyopo
    (angalia /api/income kwenye main.py), rekodi HUINGIA hapa. Dashboard na
    sehemu nyingine zinazohitaji takwimu za Income zinapaswa kutumia jedwali
    hili (siyo kuhesabu moja kwa moja kutoka Project.paid)."""

    __tablename__ = "incomes"

    id: Mapped[int] = mapped_column(primary_key=True)
    client_id: Mapped[int] = mapped_column(ForeignKey("clients.id"), index=True)
    project_id: Mapped[int] = mapped_column(ForeignKey("projects.id"), index=True)
    amount: Mapped[Decimal] = mapped_column(Numeric(14, 2))
    paid_at: Mapped[date] = mapped_column(Date)
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Service(Base):
    """Service zinazotolewa - sehemu ya 'Services' kwenye Sidebar (wadau_view /
    services_view). Ilikuwa ikihifadhiwa kwenye kumbukumbu ya muda (RAM) tu -
    sasa inahifadhiwa humu Database."""

    __tablename__ = "services"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(180), index=True)
    description: Mapped[str | None] = mapped_column(Text)
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Stakeholder(Base):
    __tablename__ = "stakeholders"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(180), index=True)
    kind: Mapped[str] = mapped_column(String(20), default="BINAFSI")
    phone_number: Mapped[str | None] = mapped_column(String(40))
    email_address: Mapped[str | None] = mapped_column(String(255))
    address: Mapped[str | None] = mapped_column(String(255))
    contact_person: Mapped[str | None] = mapped_column(String(150))
    notes: Mapped[str | None] = mapped_column(Text)
    is_blocked: Mapped[bool] = mapped_column(Boolean, default=False)
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
