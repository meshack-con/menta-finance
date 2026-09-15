from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None
    roles: str
    permissions: str = ""
    active: int
    is_blocked: bool


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    token: str
    token_type: str = "bearer"
    user: UserOut


class ClientCreate(BaseModel):
    name: str = Field(min_length=1, max_length=180)
    phone: str = Field(min_length=1, max_length=40)
    email: EmailStr | None = None


class ClientOut(ClientCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_by_id: int
    created_at: datetime


class ProjectCreate(BaseModel):
    client_id: int
    name: str = Field(min_length=1, max_length=180)
    project_type: str = Field(min_length=1, max_length=100)
    registered_at: date
    deadline: date
    amount: Decimal = Field(gt=0)
    paid: Decimal = Field(default=Decimal("0"), ge=0)


class ProjectOut(ProjectCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_by_id: int
    created_at: datetime

    @property
    def outstanding(self) -> Decimal:
        # Outstanding haiwezi kuwa hasi - inaanza na sifuri na kuishia
        # na sifuri (haiendi chini ya 0 hata kama paid > amount).
        value = self.amount - self.paid
        return value if value > Decimal("0") else Decimal("0")


class ExpenseCreate(BaseModel):
    name: str = Field(min_length=1, max_length=180)
    category: str = Field(min_length=1, max_length=100)
    amount: Decimal = Field(gt=0)
    paid_at: date
    description: str | None = None


class ExpenseOut(ExpenseCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_by_id: int
    created_at: datetime


class StaffCreate(BaseModel):
    username: str = Field(min_length=3, max_length=80)
    password: str = Field(min_length=6, max_length=128)
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None


class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(min_length=6, max_length=128)


class UserCreate(BaseModel):
    username: str = Field(min_length=3, max_length=80)
    password: str = Field(min_length=6, max_length=128)
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None
    roles: str = Field(default="STAFF")


class UserUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    phone_number: str | None = None
    roles: str | None = None
    active: int | None = None
    is_blocked: bool | None = None


class UserPasswordChange(BaseModel):
    old_password: str
    new_password: str = Field(min_length=6, max_length=128)


class UserPasswordReset(BaseModel):
    new_password: str = Field(min_length=6, max_length=128)


class IncomeCreate(BaseModel):
    client_id: int
    project_id: int
    amount: Decimal = Field(gt=0)


class IncomeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    client_id: int
    client_name: str | None = None
    project_id: int
    project_name: str | None = None
    amount: Decimal
    paid_at: date
    created_by_id: int
    created_at: datetime


class ServiceCreate(BaseModel):
    name: str = Field(min_length=1, max_length=180)
    description: str | None = None


class ServiceOut(ServiceCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_by_id: int
    created_at: datetime


class StakeholderCreate(BaseModel):
    name: str = Field(min_length=1, max_length=180)
    kind: str = Field(default="BINAFSI")
    phone_number: str | None = None
    email_address: EmailStr | None = None
    address: str | None = None
    contact_person: str | None = None
    notes: str | None = None


class StakeholderOut(StakeholderCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    is_blocked: bool
    created_by_id: int
    created_at: datetime
