from datetime import date, datetime
from decimal import Decimal

from fastapi import Depends, FastAPI, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from .config import get_settings
from .db import Base, engine, get_db
from .deps import get_current_user, require_not_staff, require_roles
from .models import Client, Expense, Income, Project, Service, Stakeholder, User
from .schemas import (
    ClientCreate,
    ClientOut,
    ExpenseCreate,
    ExpenseOut,
    IncomeCreate,
    LoginRequest,
    LoginResponse,
    PasswordChange,
    ProjectCreate,
    ProjectOut,
    ServiceCreate,
    ServiceOut,
    StaffCreate,
    StakeholderCreate,
    StakeholderOut,
    UserCreate,
    UserOut,
    UserPasswordChange,
    UserPasswordReset,
    UserUpdate,
)

VALID_ROLES = {"ADMIN", "MANAGER", "STAFF"}
from .security import create_access_token, hash_password, verify_password

settings = get_settings()
app = FastAPI(title="UMIS Admin API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def create_tables() -> None:
    Base.metadata.create_all(bind=engine)


def user_out(user: User) -> UserOut:
    return UserOut.model_validate(user)


def compute_outstanding(amount: Decimal, paid: Decimal) -> Decimal:
    """Deni (outstanding) haliruhusiwi kuwa hasi (negative).

    Linaanza na sifuri (wakati paid == amount au paid > amount) na
    haliwezi kuzidi amount - paid inapokuwa chanya.
    """
    value = amount - paid
    return value if value > Decimal("0") else Decimal("0")


def project_out(project: Project) -> dict:
    return {
        "id": project.id,
        "client_id": project.client_id,
        "name": project.name,
        "project_type": project.project_type,
        "registered_at": project.registered_at,
        "deadline": project.deadline,
        "amount": project.amount,
        "paid": project.paid,
        "outstanding": compute_outstanding(project.amount, project.paid),
        "created_by_id": project.created_by_id,
        "created_at": project.created_at,
    }


def income_out(income: Income, db: Session) -> dict:
    client = db.get(Client, income.client_id)
    project = db.get(Project, income.project_id)
    return {
        "id": income.id,
        "client_id": income.client_id,
        "client_name": client.name if client else None,
        "project_id": income.project_id,
        "project_name": project.name if project else None,
        "amount": income.amount,
        "paid_at": income.paid_at,
        "created_by_id": income.created_by_id,
        "created_at": income.created_at,
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    user = db.scalar(select(User).where(User.username == payload.username))
    if user is None or not verify_password(payload.password, user.password_hash) or user.is_blocked or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Username au password si sahihi")
    return LoginResponse(token=create_access_token(user.id), user=user_out(user))


@app.get("/api/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)) -> UserOut:
    return user_out(user)


@app.get("/api/clients", response_model=list[ClientOut])
def list_clients(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[Client]:
    query = select(Client).order_by(Client.name)
    if user.role == "STAFF":
        query = query.where(Client.created_by_id == user.id)
    return list(db.scalars(query).all())


@app.post("/api/clients", response_model=ClientOut, status_code=status.HTTP_201_CREATED)
def create_client(payload: ClientCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> Client:
    client = Client(**payload.model_dump(), created_by_id=user.id)
    db.add(client)
    db.commit()
    db.refresh(client)
    return client


@app.get("/api/clients/{client_id}/projects")
def client_projects(client_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[dict]:
    client = db.get(Client, client_id)
    if client is None or (user.role == "STAFF" and client.created_by_id != user.id):
        raise HTTPException(status_code=404, detail="Client hakupatikana")
    return [project_out(project) for project in client.projects]


@app.get("/api/projects")
def list_projects(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[dict]:
    query = select(Project).order_by(Project.registered_at.desc())
    if user.role == "STAFF":
        query = query.where(Project.created_by_id == user.id)
    return [project_out(project) for project in db.scalars(query).all()]


@app.post("/api/projects", status_code=status.HTTP_201_CREATED)
def create_project(payload: ProjectCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    if payload.paid > payload.amount:
        raise HTTPException(status_code=422, detail="Paid haiwezi kuzidi bei ya project")
    client = db.get(Client, payload.client_id)
    if client is None or (user.role == "STAFF" and client.created_by_id != user.id):
        raise HTTPException(status_code=403, detail="Chagua client uliyesajiliwa au unaoruhusiwa")
    project = Project(**payload.model_dump(), created_by_id=user.id)
    db.add(project)
    db.flush()
    # 'paid' iliyowekwa wakati wa kusajili Project ndiyo Income ya kwanza ya
    # Project hii - inaingizwa humu ili '/api/income' ibaki CHANZO RASMI
    # kimoja cha Income kwenye mfumo mzima (ikiwemo Dashboard).
    if project.paid and project.paid > 0:
        db.add(
            Income(
                client_id=project.client_id,
                project_id=project.id,
                amount=project.paid,
                paid_at=project.registered_at,
                created_by_id=user.id,
            )
        )
    db.commit()
    db.refresh(project)
    return project_out(project)


@app.get("/api/income")
def list_income(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> list[dict]:
    query = select(Income).order_by(Income.paid_at.desc(), Income.id.desc())
    if user.role == "STAFF":
        query = query.where(Income.created_by_id == user.id)
    return [income_out(item, db) for item in db.scalars(query).all()]


@app.post("/api/income", status_code=status.HTTP_201_CREATED)
def create_income(payload: IncomeCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    client = db.get(Client, payload.client_id)
    if client is None or (user.role == "STAFF" and client.created_by_id != user.id):
        raise HTTPException(status_code=403, detail="Chagua client uliyesajiliwa au unaoruhusiwa")
    project = db.get(Project, payload.project_id)
    if project is None or project.client_id != client.id:
        raise HTTPException(status_code=404, detail="Project hii haihusiani na client aliyechaguliwa")
    if user.role == "STAFF" and project.created_by_id != user.id:
        raise HTTPException(status_code=403, detail="Huna ruhusa ya project hii")
    income = Income(
        client_id=client.id,
        project_id=project.id,
        amount=payload.amount,
        paid_at=date.today(),
        created_by_id=user.id,
    )
    db.add(income)
    project.paid = project.paid + payload.amount
    db.commit()
    db.refresh(income)
    return income_out(income, db)


@app.get("/api/services/", response_model=list[ServiceOut])
def list_services(
    q: str | None = None,
    limit: int = 200,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Service]:
    query = select(Service).order_by(Service.name)
    if q:
        query = query.where(Service.name.ilike(f"%{q}%"))
    query = query.limit(limit)
    return list(db.scalars(query).all())


@app.post("/api/services/", response_model=ServiceOut, status_code=status.HTTP_201_CREATED)
def create_service(payload: ServiceCreate, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> Service:
    service = Service(**payload.model_dump(), created_by_id=user.id)
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


@app.get("/api/expenses", response_model=list[ExpenseOut])
def list_expenses(user: User = Depends(require_not_staff), db: Session = Depends(get_db)) -> list[Expense]:
    return list(db.scalars(select(Expense).order_by(Expense.paid_at.desc())).all())


@app.post("/api/expenses", response_model=ExpenseOut, status_code=status.HTTP_201_CREATED)
def create_expense(payload: ExpenseCreate, user: User = Depends(require_not_staff), db: Session = Depends(get_db)) -> Expense:
    expense = Expense(**payload.model_dump(), created_by_id=user.id)
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


@app.get("/api/users", response_model=list[UserOut])
def list_users(user: User = Depends(require_not_staff), db: Session = Depends(get_db)) -> list[User]:
    return list(db.scalars(select(User).where(User.role == "STAFF").order_by(User.username)).all())


@app.post("/api/users/staff", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_staff(payload: StaffCreate, user: User = Depends(require_not_staff), db: Session = Depends(get_db)) -> User:
    if db.scalar(select(User).where(User.username == payload.username)) is not None:
        raise HTTPException(status_code=409, detail="Username tayari inatumika")
    staff = User(**payload.model_dump(exclude={"password"}), password_hash=hash_password(payload.password), role="STAFF")
    db.add(staff)
    db.commit()
    db.refresh(staff)
    return staff


@app.get("/api/users/", response_model=list[UserOut])
def list_users_full(
    skip: int = 0,
    limit: int = 200,
    user: User = Depends(require_not_staff),
    db: Session = Depends(get_db),
) -> list[User]:
    query = select(User).order_by(User.username).offset(skip).limit(limit)
    return list(db.scalars(query).all())


@app.post("/api/users/", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def create_user(payload: UserCreate, user: User = Depends(require_not_staff), db: Session = Depends(get_db)) -> User:
    roles = payload.roles or "STAFF"
    if roles not in VALID_ROLES:
        raise HTTPException(status_code=422, detail="Roles si sahihi (ADMIN, MANAGER au STAFF)")
    if roles in ("ADMIN", "MANAGER") and user.role != "ADMIN":
        raise HTTPException(status_code=403, detail="Ni ADMIN pekee anaweza kuongeza ADMIN au MANAGER")
    if db.scalar(select(User).where(User.username == payload.username)) is not None:
        raise HTTPException(status_code=409, detail="Username tayari inatumika")
    new_user = User(
        username=payload.username,
        password_hash=hash_password(payload.password),
        role=roles,
        first_name=payload.first_name,
        last_name=payload.last_name,
        phone_number=payload.phone_number,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@app.put("/api/users/{user_id}", response_model=UserOut)
def update_user(
    user_id: int,
    payload: UserUpdate,
    # ADMIN: anaweza kuhariri mtumiaji YEYOTE (jina, simu, role, active,
    # block/unblock). MANAGER/STAFF: wanaweza kuhariri TAARIFA ZAO WENYEWE
    # pekee (jina/simu - kupitia Settings) - hawawezi kugusa akaunti ya
    # mtu mwingine, wala kubadilisha role/active/is_blocked yao wenyewe
    # (hilo ni ADMIN pekee, hata kwa akaunti ya mtu binafsi).
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> User:
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(status_code=404, detail="Mtumiaji hakupatikana")
    is_self = current_user.id == target.id
    if current_user.role != "ADMIN" and not is_self:
        raise HTTPException(status_code=403, detail="Ni ADMIN pekee anaweza kuhariri mtumiaji mwingine")
    data = payload.model_dump(exclude_unset=True)
    if current_user.role != "ADMIN":
        # Sio ADMIN - hata akihariri taarifa zake mwenyewe, hawezi kubadilisha
        # role, active, wala is_blocked. Hizo ni za ADMIN pekee.
        for restricted_field in ("roles", "active", "is_blocked"):
            data.pop(restricted_field, None)
    if data.get("roles") is not None:
        if data["roles"] not in VALID_ROLES:
            raise HTTPException(status_code=422, detail="Roles si sahihi (ADMIN, MANAGER au STAFF)")
        target.role = data["roles"]
    if "first_name" in data:
        target.first_name = data["first_name"]
    if "last_name" in data:
        target.last_name = data["last_name"]
    if "phone_number" in data:
        target.phone_number = data["phone_number"]
    if data.get("active") is not None:
        target.is_active = bool(data["active"])
    if data.get("is_blocked") is not None:
        target.is_blocked = data["is_blocked"]
    db.commit()
    db.refresh(target)
    return target


@app.put("/api/users/{user_id}/change-password")
def change_user_password(
    user_id: int,
    payload: UserPasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Unaweza kubadilisha password yako mwenyewe tu")
    if not verify_password(payload.old_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Password ya sasa si sahihi")
    current_user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"message": "Password imebadilishwa"}


@app.put("/api/users/{user_id}/reset-password")
def reset_user_password(
    user_id: int,
    payload: UserPasswordReset,
    # Ni ADMIN pekee - MANAGER anaruhusiwa kusajili STAFF tu, hana ruhusa
    # nyingine yoyote ya kubadilisha taarifa za mtumiaji mwingine.
    current_user: User = Depends(require_roles("ADMIN")),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(status_code=404, detail="Mtumiaji hakupatikana")
    target.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"message": "Password imewekwa upya"}


@app.delete("/api/users/{user_id}")
def delete_user(
    user_id: int,
    current_user: User = Depends(require_roles("ADMIN")),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    target = db.get(User, user_id)
    if target is None:
        raise HTTPException(status_code=404, detail="Mtumiaji hakupatikana")
    if target.id == current_user.id:
        raise HTTPException(status_code=400, detail="Huwezi kujifuta mwenyewe")
    db.delete(target)
    db.commit()
    return {"message": "Mtumiaji amefutwa"}


@app.patch("/api/me/password")
def change_my_password(payload: PasswordChange, user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict[str, str]:
    if not verify_password(payload.current_password, user.password_hash):
        raise HTTPException(status_code=400, detail="Password ya sasa si sahihi")
    user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"message": "Password imebadilishwa"}


@app.get("/api/admin/dashboard/summary")
def dashboard_summary(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    project_query = select(Project)
    client_query = select(Client)
    if user.role == "STAFF":
        project_query = project_query.where(Project.created_by_id == user.id)
        client_query = client_query.where(Client.created_by_id == user.id)
    projects = list(db.scalars(project_query).all())
    return {
        "total_clients": len(list(db.scalars(client_query).all())),
        "total_projects": len(projects),
        "outstanding": sum((compute_outstanding(project.amount, project.paid) for project in projects), Decimal("0")),
        "role": user.role,
    }


@app.get("/api/reports/summary")
def reports_summary(user: User = Depends(require_roles("ADMIN")), db: Session = Depends(get_db)) -> dict:
    return {
        "clients": db.scalar(select(func.count(Client.id))) or 0,
        "projects": db.scalar(select(func.count(Project.id))) or 0,
        "expenses": db.scalar(select(func.coalesce(func.sum(Expense.amount), 0))) or 0,
    }


@app.get("/api/reports/overview")
def reports_overview(user: User = Depends(require_roles("ADMIN")), db: Session = Depends(get_db)) -> dict:
    """Ripoti KAMILI ya mfumo mzima - CHANZO ni jedwali halisi za Clients,
    Projects, Income, Expenses na Services (siyo mockup). Kila mara Income,
    Expense, Client, Project au Service mpya inaposajiliwa, ombi jipya la
    endpoint hii litarudisha takwimu MPYA papo hapo (hakuna cache upande huu)."""
    clients = list(db.scalars(select(Client)).all())
    projects = list(db.scalars(select(Project)).all())
    incomes = list(db.scalars(select(Income)).all())
    expenses = list(db.scalars(select(Expense)).all())
    services_count = db.scalar(select(func.count(Service.id))) or 0

    today = date.today()
    month_start = today.replace(day=1)

    total_income = sum((i.amount for i in incomes), Decimal("0"))
    total_expenses = sum((e.amount for e in expenses), Decimal("0"))
    income_month = sum((i.amount for i in incomes if i.paid_at >= month_start), Decimal("0"))
    expenses_month = sum((e.amount for e in expenses if e.paid_at >= month_start), Decimal("0"))
    outstanding = sum((compute_outstanding(p.amount, p.paid) for p in projects), Decimal("0"))

    months: list[tuple[int, int]] = []
    for i in range(5, -1, -1):
        month_index = today.month - i
        year = today.year
        while month_index <= 0:
            month_index += 12
            year -= 1
        months.append((year, month_index))
    month_labels_sw = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ago", "Sep", "Okt", "Nov", "Des"]
    trend = []
    for year, month in months:
        inc = sum((i.amount for i in incomes if i.paid_at.year == year and i.paid_at.month == month), Decimal("0"))
        exp = sum((e.amount for e in expenses if e.paid_at.year == year and e.paid_at.month == month), Decimal("0"))
        trend.append({"label": month_labels_sw[month - 1], "income": int(inc), "expenses": int(exp)})

    client_map = {c.id: c for c in clients}

    income_by_client: dict[int, Decimal] = {}
    for item in incomes:
        income_by_client[item.client_id] = income_by_client.get(item.client_id, Decimal("0")) + item.amount
    top_clients = sorted(
        (
            {
                "client_id": cid,
                "name": client_map[cid].name if cid in client_map else "-",
                "total_income": int(amt),
            }
            for cid, amt in income_by_client.items()
        ),
        key=lambda x: x["total_income"],
        reverse=True,
    )[:5]

    top_projects = sorted(
        (
            {
                "project_id": p.id,
                "name": p.name,
                "client_name": client_map[p.client_id].name if p.client_id in client_map else "-",
                "amount": int(p.amount),
                "paid": int(p.paid),
                "outstanding": int(compute_outstanding(p.amount, p.paid)),
            }
            for p in projects
        ),
        key=lambda x: x["paid"],
        reverse=True,
    )[:5]

    recent = [
        {
            "date": item.paid_at.isoformat(),
            "type": "INCOME",
            "name": client_map[item.client_id].name if item.client_id in client_map else "Income",
            "amount": int(item.amount),
        }
        for item in incomes
    ] + [
        {"date": e.paid_at.isoformat(), "type": "EXPENSE", "name": e.name, "amount": int(e.amount)}
        for e in expenses
    ]
    recent.sort(key=lambda t: t["date"], reverse=True)
    recent = recent[:10]

    # ---- Data zaidi (nyongeza - haziathiri funguo zilizopo hapo juu) ----
    # Zinatumika na ukurasa wa Reports (Ripoti kamili za Projects/Clients/
    # Expenses), ili ripoti za PDF ziwe na taarifa ZOTE halisi, siyo top-5 tu.
    all_projects = sorted(
        (
            {
                "project_id": p.id,
                "name": p.name,
                "project_type": p.project_type,
                "client_name": client_map[p.client_id].name if p.client_id in client_map else "-",
                "registered_at": p.registered_at.isoformat(),
                "deadline": p.deadline.isoformat(),
                "amount": int(p.amount),
                "paid": int(p.paid),
                "outstanding": int(compute_outstanding(p.amount, p.paid)),
                "progress_percent": round((float(p.paid) / float(p.amount)) * 100, 1) if p.amount else 0.0,
                "is_completed": p.paid >= p.amount,
                "is_overdue": p.paid < p.amount and p.deadline < today,
            }
            for p in projects
        ),
        key=lambda x: x["registered_at"],
        reverse=True,
    )

    projects_by_client: dict[int, list[Project]] = {}
    for p in projects:
        projects_by_client.setdefault(p.client_id, []).append(p)

    all_clients = sorted(
        (
            {
                "client_id": c.id,
                "name": c.name,
                "phone": c.phone,
                "email": c.email,
                "total_projects": len(projects_by_client.get(c.id, [])),
                "total_income": int(income_by_client.get(c.id, Decimal("0"))),
                "outstanding": int(sum((compute_outstanding(p.amount, p.paid) for p in projects_by_client.get(c.id, [])), Decimal("0"))),
            }
            for c in clients
        ),
        key=lambda x: x["total_income"],
        reverse=True,
    )

    expenses_by_category: dict[str, Decimal] = {}
    for e in expenses:
        expenses_by_category[e.category] = expenses_by_category.get(e.category, Decimal("0")) + e.amount
    expenses_by_category_list = sorted(
        ({"category": cat, "total": int(amt)} for cat, amt in expenses_by_category.items()),
        key=lambda x: x["total"],
        reverse=True,
    )

    completed_projects = sum(1 for p in projects if p.paid >= p.amount)
    overdue_projects = sum(1 for p in projects if p.paid < p.amount and p.deadline < today)

    # ---- Data ya ziada kwa "Ripoti ya Mapato na Matumizi" iliyopanuliwa ----
    # (haziathiri funguo zilizopo hapo juu - ni nyongeza tu, kwa lengo la
    # kuzalisha PDF yenye Income Register, Expense Register, mwenendo wa
    # miezi 8, na "aliyeidhinisha" kwa kila expense).
    user_map = {u.id: u for u in db.scalars(select(User)).all()}

    def _user_display_name(user_id: int) -> str:
        found = user_map.get(user_id)
        if found is None:
            return "-"
        full_name = f"{found.first_name or ''} {found.last_name or ''}".strip()
        return full_name if full_name else found.username

    project_map = {p.id: p for p in projects}

    income_register = sorted(
        (
            {
                "income_id": i.id,
                "project_name": project_map[i.project_id].name if i.project_id in project_map else "-",
                "client_name": client_map[i.client_id].name if i.client_id in client_map else "-",
                "date": i.paid_at.isoformat(),
                "amount": int(i.amount),
            }
            for i in incomes
        ),
        key=lambda x: x["date"],
    )

    expense_register = sorted(
        (
            {
                "expense_id": e.id,
                "name": e.name,
                "date": e.paid_at.isoformat(),
                "approved_by": _user_display_name(e.created_by_id),
                "category": e.category,
                "amount": int(e.amount),
            }
            for e in expenses
        ),
        key=lambda x: x["date"],
    )

    months8: list[tuple[int, int]] = []
    for i in range(7, -1, -1):
        month_index = today.month - i
        year = today.year
        while month_index <= 0:
            month_index += 12
            year -= 1
        months8.append((year, month_index))
    monthly_trend_8 = []
    for year, month in months8:
        inc = sum((i.amount for i in incomes if i.paid_at.year == year and i.paid_at.month == month), Decimal("0"))
        exp = sum((e.amount for e in expenses if e.paid_at.year == year and e.paid_at.month == month), Decimal("0"))
        monthly_trend_8.append({"label": month_labels_sw[month - 1], "income": int(inc), "expenses": int(exp)})

    return {
        "totals": {
            "clients": len(clients),
            "projects": len(projects),
            "services": services_count,
            "income_total": int(total_income),
            "income_month": int(income_month),
            "expenses_total": int(total_expenses),
            "expenses_month": int(expenses_month),
            "net_profit_month": int(income_month - expenses_month),
            "outstanding": int(outstanding),
            "completed_projects": completed_projects,
            "overdue_projects": overdue_projects,
        },
        "monthly_trend": trend,
        "top_clients": top_clients,
        "top_projects": top_projects,
        "recent_transactions": recent,
        "all_projects": all_projects,
        "all_clients": all_clients,
        "expenses_by_category": expenses_by_category_list,
        "income_register": income_register,
        "expense_register": expense_register,
        "monthly_trend_8": monthly_trend_8,
        "generated_at": datetime.now().isoformat(),
    }


@app.get("/api/dashboard/summary")
def dashboard_summary_v2(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    today = date.today()
    month_start = today.replace(day=1)

    project_query = select(Project)
    client_query = select(Client)
    expense_query = select(Expense)
    income_query = select(Income)
    if user.role == "STAFF":
        project_query = project_query.where(Project.created_by_id == user.id)
        client_query = client_query.where(Client.created_by_id == user.id)
        expense_query = expense_query.where(Expense.created_by_id == user.id)
        income_query = income_query.where(Income.created_by_id == user.id)

    projects = list(db.scalars(project_query).all())
    expenses = list(db.scalars(expense_query).all())
    incomes = list(db.scalars(income_query).all())

    # Income - CHANZO RASMI ni jedwali la Income (angalia /api/income),
    # siyo tena kuhesabu moja kwa moja kutoka Project.paid.
    income_month = sum(
        (i.amount for i in incomes if i.paid_at >= month_start),
        Decimal("0"),
    )
    expenses_month = sum(
        (e.amount for e in expenses if e.paid_at >= month_start),
        Decimal("0"),
    )
    outstanding_total = sum((compute_outstanding(p.amount, p.paid) for p in projects), Decimal("0"))
    net_profit = income_month - expenses_month

    return {
        "total_rulers": int(income_month),
        "total_leaders": int(expenses_month),
        "total_members": len(list(db.scalars(client_query).all())),
        "total_regions": int(net_profit),
        "total_branches": int(outstanding_total),
        "total_locations": 0,
        "total_users": db.scalar(select(func.count(User.id))) or 0,
    }


@app.get("/api/dashboard/charts")
def dashboard_charts_v2(user: User = Depends(get_current_user), db: Session = Depends(get_db)) -> dict:
    expense_query = select(Expense).order_by(Expense.paid_at.desc()).limit(6)
    project_query = select(Project)
    income_query = select(Income).order_by(Income.paid_at.desc()).limit(6)
    if user.role == "STAFF":
        expense_query = expense_query.where(Expense.created_by_id == user.id)
        project_query = project_query.where(Project.created_by_id == user.id)
        income_query = income_query.where(Income.created_by_id == user.id)

    recent_expenses = list(db.scalars(expense_query).all())
    projects = list(db.scalars(project_query).all())
    recent_incomes = list(db.scalars(income_query).all())

    # Recent Transactions - mchanganyiko wa Expenses (EXPENSE) na Income
    # (kutoka jedwali la Income - CHANZO RASMI), zikipangwa kwa tarehe
    # kutoka mpya kwenda ya zamani.
    recent_transactions = [
        {
            "date": e.paid_at.isoformat(),
            "type": "EXPENSE",
            "name": e.name,
            "amount": int(e.amount),
        }
        for e in recent_expenses
    ]
    recent_transactions += [
        {
            "date": i.paid_at.isoformat(),
            "type": "INCOME",
            "name": (db.get(Project, i.project_id).name if db.get(Project, i.project_id) else "Income"),
            "amount": int(i.amount),
        }
        for i in recent_incomes
    ]
    recent_transactions.sort(key=lambda t: t["date"], reverse=True)
    recent_transactions = recent_transactions[:5]

    performance_points = [
        {"label": p.name, "value": int(p.paid)} for p in projects if p.paid > 0
    ]
    performance_points.sort(key=lambda x: x["value"], reverse=True)
    performance_points = performance_points[:3]

    today = date.today()
    months: list[tuple[int, int]] = []
    for i in range(5, -1, -1):
        month_index = today.month - i
        year = today.year
        while month_index <= 0:
            month_index += 12
            year -= 1
        months.append((year, month_index))

    month_labels_sw = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ago", "Sep", "Okt", "Nov", "Des"]
    # Income Trend - Last 6 Months - sasa inatoka kwenye jedwali la Income
    # (chanzo rasmi), ikichujwa kwa 'paid_at', siyo tena Project.paid.
    income_trend_query = select(Income)
    if user.role == "STAFF":
        income_trend_query = income_trend_query.where(Income.created_by_id == user.id)
    all_incomes = list(db.scalars(income_trend_query).all())
    trend = []
    for year, month in months:
        total = sum(
            (i.amount for i in all_incomes if i.paid_at.year == year and i.paid_at.month == month),
            Decimal("0"),
        )
        trend.append({"label": month_labels_sw[month - 1], "value": int(total)})

    return {
        "recent_transactions": recent_transactions,
        "leader_vs_member": [],
        "members_by_region": performance_points,
        "registrations_by_month": trend,
    }


@app.get("/api/admin/dashboard/badges")
def dashboard_badges(user: User = Depends(require_roles("ADMIN"))) -> dict:
    return {
        "unread_messages": 0,
        "new_members_7d": 0,
        "pending_leadership": 0,
        "pending_reports": 0,
        "pending_opportunities": 0,
    }


@app.get("/api/stakeholders/", response_model=list[StakeholderOut])
def list_stakeholders(
    kind: str | None = None,
    q: str | None = None,
    limit: int = 200,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[Stakeholder]:
    query = select(Stakeholder).order_by(Stakeholder.name)
    if kind:
        query = query.where(Stakeholder.kind == kind)
    if q:
        query = query.where(Stakeholder.name.ilike(f"%{q}%"))
    query = query.limit(limit)
    return list(db.scalars(query).all())


@app.post("/api/stakeholders/", response_model=StakeholderOut, status_code=status.HTTP_201_CREATED)
def create_stakeholder(
    payload: StakeholderCreate,
    user: User = Depends(require_not_staff),
    db: Session = Depends(get_db),
) -> Stakeholder:
    item = Stakeholder(**payload.model_dump(), created_by_id=user.id)
    db.add(item)
    db.commit()
    db.refresh(item)
    return item


@app.put("/api/stakeholders/{stakeholder_id}", response_model=StakeholderOut)
def update_stakeholder(
    stakeholder_id: int,
    payload: StakeholderCreate,
    user: User = Depends(require_not_staff),
    db: Session = Depends(get_db),
) -> Stakeholder:
    item = db.get(Stakeholder, stakeholder_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Haikupatikana")
    for key, value in payload.model_dump().items():
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return item


@app.delete("/api/stakeholders/{stakeholder_id}")
def delete_stakeholder(
    stakeholder_id: int,
    user: User = Depends(require_not_staff),
    db: Session = Depends(get_db),
) -> dict[str, str]:
    item = db.get(Stakeholder, stakeholder_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Haikupatikana")
    db.delete(item)
    db.commit()
    return {"message": "Imefutwa"}
