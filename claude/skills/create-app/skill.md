---
name: create-app
description: Scaffold a full-stack app (Go backend + Next.js frontend), wire everything together, verify it runs, and set up CI
---

You are being invoked via the /create-app skill. Your task is to orchestrate all relevant skills to produce a complete, runnable, tested full-stack application from scratch.

---

## Step 1 — Gather Project Info

Ask the user for (or infer from arguments):

1. **App name** (e.g. `myapp`): used as directory name, binary name, DB name, Docker image tag
2. **Go module path** (e.g. `github.com/acme/myapp`): required for `go mod init`
3. **Initial domain / resource** (e.g. `users`, `orders`): the first CRUD resource to scaffold
4. **Description** (one sentence): used in README and CLAUDE.md

If the user passes arguments (e.g. `/create-app myapp github.com/acme/myapp users "A simple task manager"`), parse them directly without asking.

Everything else (ports, directories, versions) is determined automatically in the steps below.

---

## Step 2 — Select Free Ports

Find two ports that are not already bound on the host: one for the backend API, one for the frontend.

```bash
# Find a free port starting from a candidate
find_free_port() {
  local port=$1
  while lsof -iTCP:$port -sTCP:LISTEN -t >/dev/null 2>&1; do
    port=$((port + 1))
  done
  echo $port
}
```

Use this logic (run sequentially):
1. Backend port: start scanning from `8080`, pick the first free one
2. Frontend port: start scanning from `3000`, pick the first free one (must differ from backend)

Record: `BACKEND_PORT` and `FRONTEND_PORT`. Use these in every subsequent step — never hardcode 8080 or 3000.

Run the port scan as bash:
```bash
BACKEND_PORT=8080
while lsof -iTCP:$BACKEND_PORT -sTCP:LISTEN -t >/dev/null 2>&1; do BACKEND_PORT=$((BACKEND_PORT+1)); done

FRONTEND_PORT=3000
while lsof -iTCP:$FRONTEND_PORT -sTCP:LISTEN -t >/dev/null 2>&1; do FRONTEND_PORT=$((FRONTEND_PORT+1)); done
[ "$FRONTEND_PORT" = "$BACKEND_PORT" ] && FRONTEND_PORT=$((FRONTEND_PORT+1))

echo "Backend: $BACKEND_PORT  Frontend: $FRONTEND_PORT"
```

---

## Step 3 — Initialise Git Repository

```bash
git init
echo ".env" >> .gitignore
echo "bin/" >> .gitignore
echo "coverage.out" >> .gitignore
echo "node_modules/" >> .gitignore
echo ".next/" >> .gitignore
```

Do this before any files are written so that every subsequent file is tracked from the start.

---

## Step 4 — Scaffold the Go Backend

Invoke the `/create-go-backend` skill with:
- Module: `<module>`
- App name: `<appname>`
- Port: `<BACKEND_PORT>`
- Domain: `<domain>`

Pass these values explicitly so the sub-skill does not re-prompt. After it completes, verify:

```bash
go build ./... 2>&1
go test ./... -count=1 2>&1
```

If either fails, fix the errors before continuing. Do not proceed to the next step with a broken build.

---

## Step 5 — Add Health Check Endpoint to Backend

The Go backend needs a `/health` endpoint for Docker healthchecks, CI smoke tests, and the runability verification in Step 11.

Add to `internal/server/routes.go`, inside `registerRoutes()`:

```go
s.router.GET("/health", func(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{"status": "ok"})
})
```

Ensure `"net/http"` is imported. Re-run `go build ./...` to confirm it compiles.

Update `docker-compose.yml` to use the health endpoint for the `app` service:

```yaml
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://localhost:<BACKEND_PORT>/health || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
```

---

## Step 6 — Scaffold the Next.js Frontend

Invoke the `/create-nextjs-frontend` skill with:
- App name: `<appname>-web`
- Frontend directory: `frontend/`
- Port: `<FRONTEND_PORT>`
- Backend port: `<BACKEND_PORT>` (so it can wire `NEXT_PUBLIC_API_URL`)

After it completes, verify:

```bash
cd frontend && npm run build 2>&1 | tail -5
```

A successful build is required before continuing.

---

## Step 7 — Add Root-Level Developer Makefile Targets

The `/create-go-backend` skill creates a Makefile for the backend. Add root-level convenience targets that start both services together.

Append to the root `Makefile`:

```makefile
## Development: start both backend and frontend together
dev:
	@echo "Starting backend on :<BACKEND_PORT> and frontend on :<FRONTEND_PORT>..."
	@trap 'kill 0' SIGINT; \
	  make run & \
	  (cd frontend && npm run dev) & \
	  wait

## Run all tests (backend + frontend)
test-all:
	go test ./... -race -count=1
	cd frontend && npm test -- --passWithNoTests

## Full CI check: build + test both services
ci:
	go build ./...
	go test ./... -race -count=1
	cd frontend && npm run build
	cd frontend && npm test -- --passWithNoTests
```

---

## Step 8 — Generate Environment Files

Invoke the `/envify` skill to:
- Scan all source files for environment variable references
- Generate/update `.env.example` at the project root with all required vars and helpful comments
- Ensure `DATABASE_URL`, `PORT`, `DB_*` vars and `NEXT_PUBLIC_API_URL` are all documented

Verify `.env` is not committed (check `.gitignore`).

---

## Step 9 — Write README.md

Create `README.md` at the project root:

```markdown
# <AppName>

<Description>

## Stack

- **Backend**: Go + Gin + PostgreSQL (sqlc)
- **Frontend**: Next.js (App Router, TypeScript, Tailwind)
- **Database**: PostgreSQL 16
- **Containerisation**: Docker + docker-compose

## Prerequisites

- Go 1.23+
- Node.js 20+
- Docker + docker-compose
- [sqlc](https://sqlc.dev) (`brew install sqlc`)
- [golang-migrate](https://github.com/golang-migrate/migrate) (`brew install golang-migrate`)

## Quick Start

```bash
# 1. Copy env vars
cp .env.example .env

# 2. Start all services (Postgres + backend + frontend)
make docker-up

# 3. Apply DB migrations
make migrate-up

# 4. Generate DB query code
make sqlc

# 5. Open the app
open http://localhost:<FRONTEND_PORT>
# API: http://localhost:<BACKEND_PORT>/api/v1
# Health: http://localhost:<BACKEND_PORT>/health
```

## Development

```bash
# Start both servers locally (without Docker)
make dev

# Backend only
make run

# Frontend only
make fe-dev
```

## Testing

```bash
# All tests
make test-all

# Backend only
make test

# Frontend only
make fe-test

# Full CI check
make ci
```

## API

| Method | Path | Description |
|--------|------|-------------|
| GET    | /health | Health check |
| GET    | /api/v1/<domain>s | List all |
| POST   | /api/v1/<domain>s | Create |
| GET    | /api/v1/<domain>s/:id | Get by ID |
| PUT    | /api/v1/<domain>s/:id | Update |
| DELETE | /api/v1/<domain>s/:id | Delete |

## Project Structure

```
.
├── cmd/server/main.go        # Entrypoint only
├── internal/
│   ├── db/                   # DB connection + sqlc queries
│   ├── server/               # Gin engine, routes
│   └── <domain>/             # Handler, service, tests
├── migrations/               # SQL schema files
├── frontend/                 # Next.js app
├── Makefile
├── docker-compose.yml
└── .env.example
```
```

---

## Step 10 — Write CLAUDE.md

Create `CLAUDE.md` at the project root with project-specific context for future Claude sessions:

```markdown
# <AppName> — Claude Context

## Project

<Description>

- **Backend**: Go module `<module>`, binary `<appname>`, runs on port `<BACKEND_PORT>`
- **Frontend**: Next.js in `frontend/`, runs on port `<FRONTEND_PORT>`
- **Database**: PostgreSQL, DB name `<appname>`
- **Domain**: `<domain>` (first resource, CRUD)

## Conventions

- `main.go` contains only `main()`: connect DB, create server, call Run
- Business logic lives in `internal/<domain>/service.go` — no Gin imports there
- HTTP layer lives in `internal/<domain>/handler.go` — no DB imports there
- All DB queries go through sqlc: edit `internal/db/queries/*.sql`, run `make sqlc`
- Run `make test` before committing backend changes
- Run `make fe-test` before committing frontend changes
- Run `make ci` to verify everything before opening a PR

## Key Commands

- `make dev` — start both services locally
- `make docker-up` — start full stack in Docker
- `make migrate-up` — apply DB migrations
- `make sqlc` — regenerate DB query code from SQL
- `make test-all` — run all tests
- `make ci` — full build + test check

## Port Map

- Backend API: `<BACKEND_PORT>`
- Frontend: `<FRONTEND_PORT>`
- PostgreSQL: `5432`
```

---

## Step 11 — Verify Runnable State

This step confirms the app actually works end-to-end before any CI or security setup.

```bash
# 1. Start the full stack
make docker-up

# 2. Wait for backend health (up to 30s)
for i in $(seq 1 30); do
  curl -sf http://localhost:<BACKEND_PORT>/health && break
  echo "Waiting for backend... ($i/30)"
  sleep 1
done

# 3. Hit the API
curl -sf http://localhost:<BACKEND_PORT>/api/v1/<domain>s

# 4. Run backend tests
make test

# 5. Run frontend build
make fe-build
```

If the health check does not pass within 30 seconds, run `make docker-logs` to diagnose and fix the issue. Do not proceed to the next step until the health check passes.

If `make test` fails, fix the failing tests before continuing.

---

## Step 12 — Set Up GitHub Actions

Invoke the `/actionify` skill. It will:
- Detect Go test files (`*_test.go`) and the `go test ./...` command
- Detect the Next.js test setup in `frontend/`
- Generate `.github/workflows/ci.yml` with proper postgres service, test jobs, and build gating

After it completes, verify the generated workflow references the correct test commands and that the postgres service block matches `docker-compose.yml`.

---

## Step 13 — Capture Screenshots

Invoke the `/screenshotify` skill to:
- Install Playwright in `frontend/`
- Capture screenshots of all pages at desktop, tablet, and mobile viewports
- Save to `frontend/screenshots/`

This requires the frontend dev server or Docker stack to be running (from Step 11).

---

## Step 14 — Security Baseline

Invoke the `/securify` skill to run a baseline security scan:
- `go mod audit` / `govulncheck ./...` on the backend
- `npm audit` on the frontend
- Secret detection with `trufflehog` (ensure no secrets in the initial commit)

Fix any high/critical issues before the first commit.

---

## Step 15 — Initial Git Commit

Stage all generated files and create the initial commit:

```bash
git add .
git commit -m "Initial scaffold: Go backend + Next.js frontend

- Go API with Gin, PostgreSQL (sqlc), /health endpoint, CRUD for <domain>
- Next.js frontend (App Router, TypeScript, Tailwind)
- docker-compose with backend, frontend, and Postgres services
- Makefile with dev, test, migrate, and docker targets
- GitHub Actions CI workflow
- Backend port: <BACKEND_PORT>, Frontend port: <FRONTEND_PORT>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Step 16 — Print Final Summary

```
App scaffolded successfully
============================

Name:        <appname>
Module:      <module>
Domain:      <domain>

Ports:
  Backend API   http://localhost:<BACKEND_PORT>
  Frontend      http://localhost:<FRONTEND_PORT>
  Health check  http://localhost:<BACKEND_PORT>/health
  PostgreSQL    localhost:5432

Skills invoked:
  /create-go-backend     Go API, sqlc, Makefile, Dockerfile
  /create-nextjs-frontend  Next.js app, API client, Dockerfile
  /envify                .env.example with all vars documented
  /actionify             .github/workflows/ci.yml
  /screenshotify         frontend/screenshots/
  /securify              baseline security scan

Verification:
  [PASS] go build ./...
  [PASS] go test ./...
  [PASS] docker-compose health check
  [PASS] frontend build

Files created:
  cmd/server/main.go
  internal/...
  frontend/...
  migrations/
  Makefile
  docker-compose.yml
  .env.example
  README.md
  CLAUDE.md
  .github/workflows/ci.yml

Next steps:
  1. Copy env file:      cp .env.example .env
  2. Start the stack:    make docker-up
  3. Apply migrations:   make migrate-up
  4. Generate DB code:   make sqlc
  5. Run tests:          make test-all
  6. Open app:           http://localhost:<FRONTEND_PORT>
  7. Push to GitHub and configure Actions secrets
```

---

## Important Rules

- **Port conflicts**: always scan for free ports — never hardcode 8080 or 3000
- **Build must pass** before proceeding past Step 4 and Step 6; fix compile errors inline
- **Health check must pass** before proceeding past Step 11; diagnose with `make docker-logs`
- **Tests must pass** before the initial commit; failing tests are a blocker, not a warning
- **No secrets committed**: verify `.env` is gitignored before `git add .`
- **No em dashes** in any generated files, commit messages, or output
- If a sub-skill fails or produces an error, fix the issue before invoking the next sub-skill
- Substitute all placeholders (`<appname>`, `<module>`, `<domain>`, `<BACKEND_PORT>`, `<FRONTEND_PORT>`) with real values in every file written
