# UMIS Admin Backend

FastAPI + PostgreSQL backend for the UMIS admin app.

## Setup

1. Create a separate PostgreSQL database named `umis_admin`, owned by `kondowe`. The API does not create databases or guess PostgreSQL credentials.
2. Copy `.env.example` to `.env` and set `DATABASE_URL`, `JWT_SECRET_KEY`, and the seed passwords.
3. Install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

4. Create the initial admin and manager:

```bash
python -m app.seed
```

5. Start the API from the `backend` directory:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The Flutter app is configured to use this API at `http://127.0.0.1:8000`. Keep the API running before logging in.

The API docs are available at `http://127.0.0.1:8000/docs`.

## Roles

- `ADMIN`: full access, including reports and user administration.
- `MANAGER`: clients, projects, expenses, dashboard, and adding staff; no reports and no staff edit/delete/block actions.
- `STAFF`: dashboard summary, services, and only the clients/projects created by that staff member. Staff can create clients and projects linked to their own clients.

Passwords are stored as Argon2 hashes. The API never returns password hashes or passwords.