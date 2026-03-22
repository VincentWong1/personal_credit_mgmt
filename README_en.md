"No matter -- I have deep knowledge of the stack. Let me proceed with designing the full plan based on my expertise.

---

# Construction Worker Credit Risk Management System -- Implementation Plan

## 1. Recommended Tech Stack with Justification

### Backend: FastAPI (Python)
- **Why FastAPI over Flask**: Automatic OpenAPI/Swagger docs (essential for a \"professional\" deliverable to an external client), native async support, Pydantic validation for Chinese ID card numbers, type hints throughout, and significantly better performance.
- **Python 3.9+**: Already available on the system. FastAPI runs well on 3.9.
- **SQLAlchemy 2.0** (with `aiosqlite` for async): The standard Python ORM, strong migration tooling via Alembic.
- **SQLite** (development/initial deployment) with a clean path to **PostgreSQL**: SQLite is zero-config, single-file backup. The SQLAlchemy abstraction means swapping to PostgreSQL later is a config change plus one Alembic migration run.
- **Alembic**: Database migrations. Essential for production systems.
- **python-jose** + **passlib[bcrypt]**: JWT token creation/verification and password hashing.
- **Uvicorn**: ASGI server for FastAPI.

### Frontend: Vue 3 + Vite + Element Plus
- **Vue 3 Composition API**: Simpler than React for a CRUD-heavy admin panel; excellent Chinese ecosystem support.
- **Vite**: Fast dev server, straightforward build.
- **Element Plus**: The most mature Vue 3 UI component library, designed for enterprise admin panels, has excellent Chinese localization built in (date pickers, form validation messages, table components). This is critical for a Chinese market application.
- **Axios**: HTTP client with interceptor support for JWT token management.
- **Vue Router**: Client-side routing with route guards for role-based access.
- **Pinia**: Lightweight state management for auth state.

### Deployment: Docker Compose
- Single `docker-compose.yml` with two services: `backend` (FastAPI + Uvicorn) and `frontend` (Nginx serving Vue static build + reverse proxy to backend API).
- Simple `docker compose up -d` deployment.

---

## 2. Database Schema Design

### Table: `users` (System Users / Login Accounts)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `username` | VARCHAR(50) | UNIQUE, NOT NULL | Login name |
| `hashed_password` | VARCHAR(128) | NOT NULL | bcrypt hash |
| `display_name` | VARCHAR(50) | NOT NULL | Display name (Chinese name) |
| `role` | VARCHAR(20) | NOT NULL, DEFAULT 'user' | 'admin', 'operator', 'user' |
| `is_active` | BOOLEAN | NOT NULL, DEFAULT TRUE | Soft disable |
| `created_at` | DATETIME | NOT NULL, DEFAULT NOW | |
| `updated_at` | DATETIME | NOT NULL, DEFAULT NOW | |

### Table: `workers` (Construction Workers)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PK, AUTOINCREMENT | Internal surrogate key |
| `id_card_number` | VARCHAR(18) | UNIQUE, NOT NULL, INDEX | Chinese ID card number (15 or 18 digits) |
| `name` | VARCHAR(50) | NOT NULL, INDEX | Worker name |
| `gender` | VARCHAR(4) | NOT NULL | 'male' / 'female' (stored as English, displayed as Chinese) |
| `created_at` | DATETIME | NOT NULL, DEFAULT NOW | |
| `updated_at` | DATETIME | NOT NULL, DEFAULT NOW | |
| `created_by` | INTEGER | FK -> users.id, NULL | Which operator created this record |

### Table: `companies` (Associated Companies/Units)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `name` | VARCHAR(200) | UNIQUE, NOT NULL | Company name |
| `created_at` | DATETIME | NOT NULL, DEFAULT NOW | |

### Table: `projects` (Construction Projects)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `name` | VARCHAR(200) | NOT NULL | Project name |
| `company_id` | INTEGER | FK -> companies.id, NULL | Owning company |
| `created_at` | DATETIME | NOT NULL, DEFAULT NOW | |

### Table: `risk_events` (Risk Event Records)

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INTEGER | PK, AUTOINCREMENT | |
| `worker_id` | INTEGER | FK -> workers.id, NOT NULL, INDEX | |
| `event_date` | DATE | NOT NULL, INDEX | Date the risk event occurred |
| `risk_level` | VARCHAR(20) | NOT NULL | 'low', 'medium', 'high', 'critical' |
| `category` | VARCHAR(50) | NOT NULL | Event category (e.g., safety violation, quality issue, attendance, contract breach) |
| `description` | TEXT | NULL | Detailed description of the event |
| `company_id` | INTEGER | FK -> companies.id, NULL | Company associated with this event |
| `project_id` | INTEGER | FK -> projects.id, NULL | Project associated with this event |
| `created_at` | DATETIME | NOT NULL, DEFAULT NOW | |
| `updated_at` | DATETIME | NOT NULL, DEFAULT NOW | |
| `created_by` | INTEGER | FK -> users.id, NULL | Which operator recorded this event |

### Design Rationale

- **Surrogate PK everywhere**: `id_card_number` is the business key for `workers`, but an integer `id` is the PK for performance in foreign key joins. The `id_card_number` column has a unique index for lookups.
- **Companies and Projects are separate tables**: Even though the requirement says \"associated company\" and \"associated project\" per risk event, normalizing these into their own tables avoids data inconsistency (same company spelled differently). They can be created on-the-fly when adding a risk event.
- **Risk level per event, not per worker**: The requirement says \"risk level category per event.\" A worker's \"overall\" risk level can be computed at query time (highest risk level across their events), which avoids stale data.
- **Gender stored in English**: Avoids encoding issues in the database. The frontend maps 'male' -> '男', 'female' -> '女'.
- **`created_by` audit trail**: Tracks which operator created records. Important for a production system.

### Indexes (beyond PKs and UNIQUEs)

```
CREATE INDEX ix_workers_name ON workers(name);
CREATE INDEX ix_risk_events_worker_id ON risk_events(worker_id);
CREATE INDEX ix_risk_events_event_date ON risk_events(event_date DESC);
CREATE INDEX ix_projects_company_id ON projects(company_id);
```

---

## 3. API Endpoint Design

Base URL: `/api/v1`

### Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/auth/login` | None | Login, returns JWT access + refresh tokens |
| POST | `/auth/refresh` | Refresh token | Get new access token |
| GET | `/auth/me` | Any authenticated | Get current user profile |
| PUT | `/auth/password` | Any authenticated | Change own password |

### Users (Admin only, except where noted)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/users` | Admin | List all users (paginated) |
| POST | `/users` | Admin | Create a new user |
| GET | `/users/{id}` | Admin | Get user details |
| PUT | `/users/{id}` | Admin | Update user (including role change) |
| DELETE | `/users/{id}` | Admin | Deactivate user (soft delete) |

### Workers

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/workers` | Any authenticated | Search workers. Query params: `q` (searches both name and id_card_number), `page`, `page_size` |
| POST | `/workers` | Admin, Operator | Create a worker record |
| GET | `/workers/{id}` | Any authenticated | Get worker details with all risk events (events sorted by event_date DESC) |
| PUT | `/workers/{id}` | Admin, Operator | Update worker basic info |
| DELETE | `/workers/{id}` | Admin | Delete worker and associated risk events |

### Risk Events

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/workers/{worker_id}/events` | Any authenticated | List risk events for a worker (sorted by event_date DESC, paginated) |
| POST | `/workers/{worker_id}/events` | Admin, Operator | Add a risk event to a worker |
| GET | `/events/{id}` | Any authenticated | Get single risk event detail |
| PUT | `/events/{id}` | Admin, Operator | Update a risk event |
| DELETE | `/events/{id}` | Admin | Delete a risk event |

### Companies & Projects (supporting entities)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/companies` | Any authenticated | List companies (for dropdown selectors). Query param: `q` for search |
| POST | `/companies` | Admin, Operator | Create a company |
| GET | `/projects` | Any authenticated | List projects. Query param: `company_id` to filter by company |
| POST | `/projects` | Admin, Operator | Create a project |

### Dashboard / Statistics (optional but professional)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/stats/overview` | Any authenticated | Total workers, events by risk level, recent events |

### Pagination Convention

All list endpoints return:
```json
{
  \"items\": [...],
  \"total\": 150,
  \"page\": 1,
  \"page_size\": 20,
  \"pages\": 8
}
```

### Error Response Convention

```json
{
  \"detail\": \"Human-readable error message\",
  \"code\": \"MACHINE_READABLE_ERROR_CODE\"
}
```

Standard HTTP status codes: 200, 201, 400, 401, 403, 404, 422 (validation), 500.

---

## 4. Frontend Page and Component Structure

### Pages (Vue Router)

```
/login                     -- LoginPage.vue
/                          -- DashboardPage.vue (redirect target after login)
/workers                   -- WorkerListPage.vue (search + table)
/workers/:id               -- WorkerDetailPage.vue (info + risk event list)
/workers/new               -- WorkerFormPage.vue (create, operator+admin)
/workers/:id/edit          -- WorkerFormPage.vue (edit, operator+admin)
/workers/:id/events/new    -- EventFormPage.vue (add risk event)
/events/:id/edit           -- EventFormPage.vue (edit risk event)
/users                     -- UserListPage.vue (admin only)
/users/new                 -- UserFormPage.vue (admin only)
/users/:id/edit            -- UserFormPage.vue (admin only)
/profile                   -- ProfilePage.vue (change own password)
```

### Layout Components

```
AppLayout.vue              -- Main layout: sidebar + header + content area
  SidebarNav.vue           -- Navigation menu (items filtered by role)
  HeaderBar.vue            -- Top bar: user info, logout button
```

### Reusable Components

```
SearchBar.vue              -- Search input with debounce (used on WorkerListPage)
PaginationBar.vue          -- Wraps Element Plus pagination
RiskLevelTag.vue           -- Color-coded tag: green(low), yellow(medium), red(high), darkred(critical)
IdCardInput.vue            -- Input with Chinese ID card validation (18-digit format, checksum)
ConfirmDialog.vue          -- Reusable confirmation modal for delete actions
```

### Key UI Details

**WorkerListPage**: 
- Search bar at top (placeholder: \"输入姓名或身份证号搜索\")
- Element Plus `<el-table>` with columns: Name, ID Card (masked: show first 6 + last 4), Gender, Highest Risk Level (computed badge), Event Count, Actions
- Clicking a row navigates to detail page

**WorkerDetailPage**:
- Top card: Worker basic info (name, full ID card number, gender)
- Below: Risk events table sorted by date descending, with columns: Date, Risk Level (color tag), Category, Company, Project, Description (truncated), Actions
- \"Add Risk Event\" button visible only for operator/admin

**LoginPage**:
- Clean centered card with username + password fields
- System title: \"建筑工人信用风险管理系统\"

### Route Guards

```javascript
router.beforeEach((to, from, next) => {
  // Check JWT in localStorage
  // If expired, attempt refresh
  // If no token and route requires auth, redirect to /login
  // If route requires admin role and user is not admin, redirect to /
})
```

---

## 5. Authentication and Authorization Flow

### Login Flow

```
1. User submits username + password to POST /api/v1/auth/login
2. Backend verifies password hash with passlib/bcrypt
3. Backend generates:
   - Access token (JWT, 30 min expiry, contains: user_id, username, role)
   - Refresh token (JWT, 7 day expiry, contains: user_id, token_type: \"refresh\")
4. Frontend stores both tokens in localStorage
5. Frontend sets Axios default header: Authorization: Bearer <access_token>
6. Frontend decodes access token (without verification) to get role for UI rendering
```

### Token Refresh Flow

```
1. Axios response interceptor catches 401
2. If refresh token exists, POST /api/v1/auth/refresh with refresh token
3. If refresh succeeds, retry original request with new access token
4. If refresh fails (expired), redirect to login page, clear localStorage
```

### Backend Authorization Architecture

**Dependency injection pattern in FastAPI**:

```python
# dependencies.py

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    \"\"\"Decode JWT, load user from DB, raise 401 if invalid.\"\"\"
    ...

async def require_admin(user: User = Depends(get_current_user)) -> User:
    \"\"\"Raise 403 if user.role != 'admin'.\"\"\"
    ...

async def require_operator(user: User = Depends(get_current_user)) -> User:
    \"\"\"Raise 403 if user.role not in ('admin', 'operator').\"\"\"
    ...
```

**Usage in routes**:

```python
@router.post(\"/workers\")
async def create_worker(
    data: WorkerCreate,
    user: User = Depends(require_operator),  # admin or operator
    db: AsyncSession = Depends(get_db),
):
    ...

@router.delete(\"/workers/{worker_id}\")
async def delete_worker(
    worker_id: int,
    user: User = Depends(require_admin),  # admin only
    db: AsyncSession = Depends(get_db),
):
    ...
```

### Password Policy

- Minimum 8 characters
- bcrypt hashing with salt rounds = 12
- Default admin account seeded on first startup (username: `admin`, password: `changeme123`) with a forced password change flag

### ID Card Number Validation

Chinese ID card numbers have a specific format:
- 18 digits (or 15 for older cards)
- Positions 1-6: region code
- Positions 7-14: birth date (YYYYMMDD)
- Position 17: gender (odd = male, even = female)
- Position 18: checksum digit (weighted modulo)

This validation should be implemented as:
- A Pydantic validator on the backend `WorkerCreate` / `WorkerUpdate` schemas
- A matching validation function in the frontend `IdCardInput.vue` component
- Gender can be auto-filled from the ID card number

---

## 6. Deployment Strategy

### Development

```bash
# Terminal 1: Backend
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
alembic upgrade head          # Run migrations
python seed.py                # Seed default admin user
uvicorn app.main:app --reload --port 8000

# Terminal 2: Frontend
cd frontend
npm install
npm run dev                   # Vite dev server on port 5173, proxies /api to :8000
```

### Production (Docker Compose)

**`docker-compose.yml`** with two services:

```yaml
services:
  backend:
    build: ./backend
    ports:
      - \"8000:8000\"
    volumes:
      - ./data:/app/data        # SQLite file persisted here
    environment:
      - DATABASE_URL=sqlite+aiosqlite:///./data/credit_mgmt.db
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
      - ADMIN_DEFAULT_PASSWORD=${ADMIN_DEFAULT_PASSWORD:-changeme123}

  frontend:
    build: ./frontend
    ports:
      - \"80:80\"
    depends_on:
      - backend
```

**Backend Dockerfile** (`backend/Dockerfile`):

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN alembic upgrade head
CMD [\"uvicorn\", \"app.main:app\", \"--host\", \"0.0.0.0\", \"--port\", \"8000\"]
```

**Frontend Dockerfile** (`frontend/Dockerfile`):

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

**Nginx config** (`frontend/nginx.conf`):

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location /api/ {
        proxy_pass http://backend:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;  # SPA fallback
    }
}
```

### Deployment Command

```bash
# On the server:
export JWT_SECRET_KEY=$(openssl rand -hex 32)
docker compose up -d --build
```

### PostgreSQL Upgrade Path

When ready to scale beyond SQLite:
1. Add a `postgres` service to `docker-compose.yml`
2. Change `DATABASE_URL` to `postgresql+asyncpg://user:pass@postgres:5432/credit_mgmt`
3. Add `asyncpg` to `requirements.txt` (replacing `aiosqlite`)
4. Run Alembic migrations against the new database
5. Migrate data with a one-time script

---

## 7. Directory Structure

```
personal_credit_mgmt/
|
|-- docker-compose.yml
|-- .env.example                      # JWT_SECRET_KEY, ADMIN_DEFAULT_PASSWORD
|-- README.md
|
|-- backend/
|   |-- Dockerfile
|   |-- requirements.txt
|   |-- alembic.ini
|   |-- seed.py                       # Creates default admin user
|   |
|   |-- alembic/
|   |   |-- env.py
|   |   |-- versions/
|   |       |-- 001_initial_schema.py
|   |
|   |-- app/
|       |-- __init__.py
|       |-- main.py                   # FastAPI app, CORS, lifespan events
|       |-- config.py                 # Settings from env vars (pydantic-settings)
|       |-- database.py               # Engine, async session factory
|       |
|       |-- models/
|       |   |-- __init__.py
|       |   |-- user.py               # User SQLAlchemy model
|       |   |-- worker.py             # Worker SQLAlchemy model
|       |   |-- risk_event.py         # RiskEvent SQLAlchemy model
|       |   |-- company.py            # Company SQLAlchemy model
|       |   |-- project.py            # Project SQLAlchemy model
|       |
|       |-- schemas/
|       |   |-- __init__.py
|       |   |-- user.py               # UserCreate, UserUpdate, UserResponse
|       |   |-- worker.py             # WorkerCreate, WorkerUpdate, WorkerResponse, WorkerSearch
|       |   |-- risk_event.py         # EventCreate, EventUpdate, EventResponse
|       |   |-- company.py            # CompanyCreate, CompanyResponse
|       |   |-- project.py            # ProjectCreate, ProjectResponse
|       |   |-- auth.py               # LoginRequest, TokenResponse
|       |   |-- common.py             # PaginatedResponse generic
|       |
|       |-- api/
|       |   |-- __init__.py
|       |   |-- deps.py               # get_db, get_current_user, require_admin, require_operator
|       |   |-- v1/
|       |       |-- __init__.py
|       |       |-- router.py         # Aggregates all v1 routers
|       |       |-- auth.py           # /auth/* endpoints
|       |       |-- users.py          # /users/* endpoints
|       |       |-- workers.py        # /workers/* endpoints
|       |       |-- risk_events.py    # /events/* and /workers/{id}/events/* endpoints
|       |       |-- companies.py      # /companies/* endpoints
|       |       |-- projects.py       # /projects/* endpoints
|       |       |-- stats.py          # /stats/* endpoints
|       |
|       |-- services/
|       |   |-- __init__.py
|       |   |-- auth_service.py       # Password hashing, JWT creation/verification
|       |   |-- worker_service.py     # Worker CRUD logic
|       |   |-- event_service.py      # Risk event CRUD logic
|       |   |-- user_service.py       # User management logic
|       |
|       |-- utils/
|           |-- __init__.py
|           |-- id_card.py            # Chinese ID card validation + gender extraction
|           |-- pagination.py         # Paginate helper for SQLAlchemy queries
|
|-- frontend/
    |-- Dockerfile
    |-- nginx.conf
    |-- package.json
    |-- vite.config.js
    |-- index.html
    |
    |-- public/
    |   |-- favicon.ico
    |
    |-- src/
        |-- main.js                   # Vue app entry, Element Plus registration
        |-- App.vue                   # Root component
        |-- router/
        |   |-- index.js              # Route definitions + guards
        |
        |-- stores/
        |   |-- auth.js               # Pinia store: user, token, login/logout actions
        |
        |-- api/
        |   |-- index.js              # Axios instance with interceptors
        |   |-- auth.js               # login(), refresh(), getMe()
        |   |-- workers.js            # searchWorkers(), getWorker(), createWorker(), ...
        |   |-- events.js             # getEvents(), createEvent(), ...
        |   |-- users.js              # getUsers(), createUser(), ...
        |   |-- companies.js          # getCompanies(), createCompany()
        |   |-- projects.js           # getProjects(), createProject()
        |
        |-- layouts/
        |   |-- AppLayout.vue         # Sidebar + header + <router-view>
        |
        |-- views/
        |   |-- LoginPage.vue
        |   |-- DashboardPage.vue
        |   |-- WorkerListPage.vue
        |   |-- WorkerDetailPage.vue
        |   |-- WorkerFormPage.vue
        |   |-- EventFormPage.vue
        |   |-- UserListPage.vue
        |   |-- UserFormPage.vue
        |   |-- ProfilePage.vue
        |
        |-- components/
        |   |-- SearchBar.vue
        |   |-- PaginationBar.vue
        |   |-- RiskLevelTag.vue
        |   |-- IdCardInput.vue
        |   |-- ConfirmDialog.vue
        |   |-- SidebarNav.vue
        |   |-- HeaderBar.vue
        |
        |-- utils/
            |-- id-card.js            # ID card validation (mirrors backend logic)
            |-- permissions.js         # hasRole(), canEdit(), etc.
```

---

## 8. Implementation Sequence (Recommended Build Order)

### Phase 1: Backend Foundation (Day 1-2)
1. Initialize backend Python project, `requirements.txt`, `app/main.py`
2. Implement `config.py` with pydantic-settings
3. Implement `database.py` with async SQLAlchemy engine
4. Create all SQLAlchemy models
5. Set up Alembic and generate initial migration
6. Implement `utils/id_card.py` (ID card validation)
7. Implement `services/auth_service.py` (JWT + password hashing)
8. Implement `api/deps.py` (dependency injection for auth)
9. Implement auth endpoints (`POST /auth/login`, `POST /auth/refresh`, `GET /auth/me`)
10. Implement `seed.py` for default admin user

### Phase 2: Backend CRUD (Day 2-3)
1. Implement Pydantic schemas for all entities
2. Implement `utils/pagination.py`
3. Implement worker CRUD service + endpoints
4. Implement risk event CRUD service + endpoints
5. Implement company/project endpoints
6. Implement user management endpoints (admin)
7. Implement stats endpoint

### Phase 3: Frontend Foundation (Day 3-4)
1. Initialize Vue 3 + Vite project
2. Install and configure Element Plus (Chinese locale)
3. Set up Axios instance with JWT interceptors
4. Implement Pinia auth store
5. Implement Vue Router with route guards
6. Build `AppLayout.vue`, `SidebarNav.vue`, `HeaderBar.vue`
7. Build `LoginPage.vue`

### Phase 4: Frontend Pages (Day 4-5)
1. Build `WorkerListPage.vue` with search and pagination
2. Build `WorkerDetailPage.vue` with risk event table
3. Build `WorkerFormPage.vue` (create/edit)
4. Build `EventFormPage.vue`
5. Build `UserListPage.vue` and `UserFormPage.vue` (admin)
6. Build `ProfilePage.vue`
7. Build `DashboardPage.vue` with stats

### Phase 5: Polish and Deploy (Day 5-6)
1. Write `Dockerfile` for backend and frontend
2. Write `docker-compose.yml`
3. Write `nginx.conf`
4. Write `README.md` with setup/deployment instructions
5. Test full flow end-to-end in Docker
6. Create `.env.example`

---

## 9. Key Technical Decisions and Rationale

### Why async SQLAlchemy with SQLite?
SQLite does not benefit from async in terms of I/O, but using async from the start means zero code changes when migrating to PostgreSQL with `asyncpg`. The `aiosqlite` driver makes this transparent.

### Why Element Plus over Ant Design Vue?
Element Plus has more mature Chinese localization, better documentation in Chinese, and is the de facto standard for Chinese enterprise admin panels. The client (a Chinese construction industry user) will find it familiar.

### Why separate services layer?
Keeping business logic in `services/` rather than directly in route handlers allows for: (a) easier unit testing, (b) reuse across endpoints, (c) cleaner route handlers that only deal with HTTP concerns.

### Why not use Pydantic v2 model validation for ID cards at the schema level?
We should. The `WorkerCreate` schema should have a `@field_validator('id_card_number')` that calls the validation function from `utils/id_card.py`. This catches bad data before it reaches the database.

### CORS Configuration
In `main.py`, configure CORS to allow the frontend origin in development (`http://localhost:5173`). In production behind Nginx, CORS is not needed because the frontend and API share the same origin (Nginx proxies `/api/` to the backend).

### `requirements.txt` (key dependencies)

```
fastapi==0.115.*
uvicorn[standard]==0.34.*
sqlalchemy[asyncio]==2.0.*
aiosqlite==0.20.*
alembic==1.14.*
python-jose[cryptography]==3.3.*
passlib[bcrypt]==1.7.*
pydantic-settings==2.7.*
python-multipart==0.0.*
```

### `package.json` (key frontend dependencies)

```json
{
  \"dependencies\": {
    \"vue\": \"^3.5\",
    \"vue-router\": \"^4.5\",
    \"pinia\": \"^2.3\",
    \"axios\": \"^1.7\",
    \"element-plus\": \"^2.9\",
    \"dayjs\": \"^1.11\"
  },
  \"devDependencies\": {
    \"@vitejs/plugin-vue\": \"^5.2\",
    \"vite\": \"^6.1\",
    \"unplugin-auto-import\": \"^0.18\",
    \"unplugin-vue-components\": \"^0.27\"
  }
}
```

---

## 10. Potential Challenges and Mitigations

| Challenge | Mitigation |
|---|---|
| Chinese ID card checksum validation is complex | Implement once in `utils/id_card.py` with comprehensive test cases; mirror in JS |
| SQLite concurrent writes under load | Acceptable for expected user count (small team); WAL mode enabled; PostgreSQL upgrade path documented |
| JWT token expiry causing poor UX | Axios interceptor with silent refresh; 30 min access + 7 day refresh is generous |
| Client expects professional appearance | Element Plus provides enterprise-grade look; add the system logo/branding in the header |
| Data backup | SQLite: cron job copying the `.db` file; document in README |
| First-time setup complexity | `seed.py` auto-runs on startup if no admin user exists; Docker Compose makes deployment a single command |

---

### Critical Files for Implementation

- `/Users/wigi/PycharmProjects/personal_credit_mgmt/backend/app/main.py` - FastAPI application entry point: CORS, lifespan events, router mounting, and middleware configuration
- `/Users/wigi/PycharmProjects/personal_credit_mgmt/backend/app/api/deps.py` - Authentication and authorization dependency injection: get_current_user, require_admin, require_operator -- the security backbone
- `/Users/wigi/PycharmProjects/personal_credit_mgmt/backend/app/models/worker.py` - Worker SQLAlchemy model with id_card_number as the unique business key and relationships to risk_events
- `/Users/wigi/PycharmProjects/personal_credit_mgmt/frontend/src/router/index.js` - Vue Router configuration with role-based route guards; defines all page routes and access control
- `/Users/wigi/PycharmProjects/personal_credit_mgmt/docker-compose.yml` - Docker Compose orchestration file defining backend and frontend services, volumes for SQLite persistence, and environment variables"