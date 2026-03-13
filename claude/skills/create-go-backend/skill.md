---
name: create-go-backend
description: Scaffold a production-ready Go backend with Gin, PostgreSQL, sqlc, Docker, Makefile, and tests
---

You are being invoked via the /create-go-backend skill. Your task is to scaffold a complete, idiomatic Go backend from scratch in the current directory.

---

## Step 1 — Gather Project Info

Ask the user (or infer from context) the following before proceeding:

1. **Module name**: e.g. `github.com/user/myapp` (required for `go mod init`)
2. **App name / binary name**: e.g. `myapp` (used for the binary, Docker image tag, Makefile targets)
3. **Port**: default `8080`
4. **Initial domain**: e.g. `users`, `orders` — used to generate the first example resource with full CRUD

If the user invoked the skill with arguments (e.g. `/create-go-backend github.com/acme/api users`), parse them directly without asking.

---

## Step 2 — Directory Structure

Create the following layout. Every directory must have at least one file (no empty dirs):

```
.
├── cmd/
│   └── server/
│       └── main.go             # Entrypoint only — no logic
├── internal/
│   ├── db/
│   │   ├── db.go               # *sql.DB initialisation and helpers
│   │   ├── queries/
│   │   │   └── <domain>.sql    # Raw SQL queries (input to sqlc)
│   │   └── sqlc/               # sqlc-generated output (do not edit)
│   │       ├── db.go
│   │       ├── models.go
│   │       └── <domain>.sql.go
│   ├── server/
│   │   ├── server.go           # Gin engine setup, middleware, route registration
│   │   └── routes.go           # Route definitions grouped by domain
│   └── <domain>/
│       ├── handler.go          # Gin handlers (HTTP layer only)
│       ├── service.go          # Business logic
│       └── service_test.go     # Unit tests for service logic
├── migrations/
│   └── 000001_create_<domain>_table.sql
├── sqlc.yaml
├── Makefile
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── .gitignore
└── go.mod
```

---

## Step 3 — Write Each File

### `cmd/server/main.go`

Thin entrypoint only. No business logic, no route definitions, no DB queries.

```go
package main

import (
	"log"

	"<module>/internal/db"
	"<module>/internal/server"
)

func main() {
	database, err := db.Connect()
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}
	defer database.Close()

	srv := server.New(database)
	if err := srv.Run(); err != nil {
		log.Fatalf("server error: %v", err)
	}
}
```

### `internal/db/db.go`

```go
package db

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/lib/pq"
)

func Connect() (*sql.DB, error) {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = fmt.Sprintf(
			"host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
			getenv("DB_HOST", "localhost"),
			getenv("DB_PORT", "5432"),
			getenv("DB_USER", "postgres"),
			getenv("DB_PASSWORD", "postgres"),
			getenv("DB_NAME", "<appname>"),
		)
	}
	return sql.Open("postgres", dsn)
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
```

### `internal/server/server.go`

```go
package server

import (
	"database/sql"
	"fmt"
	"os"

	"github.com/gin-gonic/gin"
	"<module>/internal/db/sqlc"
	"<module>/internal/<domain>"
)

type Server struct {
	router  *gin.Engine
	queries *sqlc.Queries
}

func New(database *sql.DB) *Server {
	queries := sqlc.New(database)
	s := &Server{
		router:  gin.Default(),
		queries: queries,
	}
	s.registerRoutes()
	return s
}

func (s *Server) Run() error {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	return s.router.Run(fmt.Sprintf(":%s", port))
}
```

### `internal/server/routes.go`

```go
package server

import "<module>/internal/<domain>"

func (s *Server) registerRoutes() {
	h := <domain>.NewHandler(s.queries)

	v1 := s.router.Group("/api/v1")
	{
		v1.GET("/<domain>s", h.List)
		v1.POST("/<domain>s", h.Create)
		v1.GET("/<domain>s/:id", h.Get)
		v1.PUT("/<domain>s/:id", h.Update)
		v1.DELETE("/<domain>s/:id", h.Delete)
	}
}
```

### `internal/<domain>/handler.go`

HTTP layer only. Calls service, returns JSON. No direct DB access.

```go
package <domain>

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"<module>/internal/db/sqlc"
)

type Handler struct {
	svc *Service
}

func NewHandler(q *sqlc.Queries) *Handler {
	return &Handler{svc: NewService(q)}
}

func (h *Handler) List(c *gin.Context) {
	items, err := h.svc.List(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, items)
}

func (h *Handler) Create(c *gin.Context) {
	var params sqlc.Create<Domain>Params
	if err := c.ShouldBindJSON(&params); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	item, err := h.svc.Create(c.Request.Context(), params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, item)
}

func (h *Handler) Get(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	item, err := h.svc.Get(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "not found"})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *Handler) Update(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	var params sqlc.Update<Domain>Params
	if err := c.ShouldBindJSON(&params); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	params.ID = id
	item, err := h.svc.Update(c.Request.Context(), params)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, item)
}

func (h *Handler) Delete(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid id"})
		return
	}
	if err := h.svc.Delete(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusNoContent, nil)
}
```

### `internal/<domain>/service.go`

Business logic layer. Wraps sqlc queries. Add validation and transformation here.

```go
package <domain>

import (
	"context"

	"<module>/internal/db/sqlc"
)

type Service struct {
	q *sqlc.Queries
}

func NewService(q *sqlc.Queries) *Service {
	return &Service{q: q}
}

func (s *Service) List(ctx context.Context) ([]sqlc.<Domain>, error) {
	return s.q.List<Domain>s(ctx)
}

func (s *Service) Create(ctx context.Context, params sqlc.Create<Domain>Params) (sqlc.<Domain>, error) {
	return s.q.Create<Domain>(ctx, params)
}

func (s *Service) Get(ctx context.Context, id int64) (sqlc.<Domain>, error) {
	return s.q.Get<Domain>(ctx, id)
}

func (s *Service) Update(ctx context.Context, params sqlc.Update<Domain>Params) (sqlc.<Domain>, error) {
	return s.q.Update<Domain>(ctx, params)
}

func (s *Service) Delete(ctx context.Context, id int64) error {
	return s.q.Delete<Domain>(ctx, id)
}
```

### `internal/<domain>/service_test.go`

Use a mock or stub for `sqlc.Queries`. Test service logic, not DB.

```go
package <domain>_test

import (
	"context"
	"testing"

	"<module>/internal/<domain>"
	"<module>/internal/db/sqlc"
)

// mockQueries implements a minimal stub for testing.
// Replace with a generated mock (e.g. via mockery) as the project grows.
type mockQueries struct {
	items []sqlc.<Domain>
}

func (m *mockQueries) List<Domain>s(ctx context.Context) ([]sqlc.<Domain>, error) {
	return m.items, nil
}

// Add stubs for Create, Get, Update, Delete as needed.

func TestList_ReturnsItems(t *testing.T) {
	// Adapt once sqlc types are generated — this is a placeholder.
	t.Log("service_test: placeholder — wire up mockQueries once sqlc is generated")
}
```

### `internal/db/queries/<domain>.sql`

```sql
-- name: List<Domain>s :many
SELECT * FROM <domain>s ORDER BY id;

-- name: Get<Domain> :one
SELECT * FROM <domain>s WHERE id = $1;

-- name: Create<Domain> :one
INSERT INTO <domain>s (name, created_at, updated_at)
VALUES ($1, NOW(), NOW())
RETURNING *;

-- name: Update<Domain> :one
UPDATE <domain>s
SET name = $2, updated_at = NOW()
WHERE id = $1
RETURNING *;

-- name: Delete<Domain> :exec
DELETE FROM <domain>s WHERE id = $1;
```

### `migrations/000001_create_<domain>_table.sql`

```sql
-- Up
CREATE TABLE IF NOT EXISTS <domain>s (
    id         BIGSERIAL PRIMARY KEY,
    name       TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Down
DROP TABLE IF EXISTS <domain>s;
```

### `sqlc.yaml`

```yaml
version: "2"
sql:
  - engine: "postgresql"
    queries: "internal/db/queries"
    schema: "migrations"
    gen:
      go:
        package: "sqlc"
        out: "internal/db/sqlc"
        emit_json_tags: true
        emit_prepared_queries: false
        emit_interface: false
        emit_exact_table_names: false
```

### `Makefile`

```makefile
APP      := <appname>
MODULE   := <module>
PORT     := 8080
GOFLAGS  :=

.PHONY: all build run test lint sqlc migrate docker-build docker-up docker-down docker-logs clean

all: build

## Build the binary
build:
	go build $(GOFLAGS) -o bin/$(APP) ./cmd/server

## Run locally (requires Postgres running)
run:
	go run ./cmd/server

## Run all tests
test:
	go test ./... -v -race -count=1

## Run tests with coverage
test-cover:
	go test ./... -coverprofile=coverage.out
	go tool cover -html=coverage.out -o coverage.html

## Lint (requires golangci-lint)
lint:
	golangci-lint run ./...

## Generate sqlc code from queries
sqlc:
	sqlc generate

## Apply migrations (requires migrate CLI and DATABASE_URL set)
migrate-up:
	migrate -path migrations -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path migrations -database "$(DATABASE_URL)" down 1

## Docker targets
docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

## Remove build artifacts
clean:
	rm -rf bin/ coverage.out coverage.html
```

### `Dockerfile`

Multi-stage: builder compiles the binary, runner is a minimal image.

```dockerfile
# Stage 1: build
FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o /bin/<appname> ./cmd/server

# Stage 2: run
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /bin/<appname> /app/<appname>

EXPOSE <port>

USER nobody

ENTRYPOINT ["/app/<appname>"]
```

### `docker-compose.yml`

```yaml
services:
  app:
    build: .
    ports:
      - "<port>:<port>"
    environment:
      PORT: "<port>"
      DB_HOST: postgres
      DB_PORT: "5432"
      DB_USER: postgres
      DB_PASSWORD: postgres
      DB_NAME: <appname>
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: <appname>
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

### `.env.example`

```bash
# Server
PORT=8080

# Database (choose one approach)
DATABASE_URL=postgres://postgres:postgres@localhost:5432/<appname>?sslmode=disable

# Or individual vars (used when DATABASE_URL is not set)
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=<appname>
```

### `.gitignore`

```
bin/
coverage.out
coverage.html
.env
*.local
```

---

## Step 4 — Initialise Go Module and Install Dependencies

Run these commands after writing all files:

```bash
go mod init <module>
go get github.com/gin-gonic/gin
go get github.com/lib/pq
go mod tidy
```

Do NOT run `sqlc generate` yet — the user needs sqlc installed locally or via Docker, and the DB schema must exist first.

---

## Step 5 — Generate sqlc Stubs (Placeholder)

Since `sqlc generate` requires the sqlc binary, write placeholder files in `internal/db/sqlc/` that compile but are intentionally minimal:

- `db.go`: package declaration + `New(db DBTX) *Queries` constructor
- `models.go`: a `<Domain>` struct matching the migration columns (`ID int64`, `Name string`, `CreatedAt`, `UpdatedAt time.Time`)
- `<domain>.sql.go`: stub implementations of `List<Domain>s`, `Get<Domain>`, `Create<Domain>`, `Update<Domain>`, `Delete<Domain>` that call through to `*sql.DB`

Make these compile correctly so `go build ./...` passes before the user installs sqlc. Add a comment at the top of each file:

```go
// Code generated by sqlc. DO NOT EDIT — run `make sqlc` to regenerate.
```

---

## Step 6 — Verify the Build

Run the following and fix any compile errors before finishing:

```bash
go build ./...
go test ./... -count=1
```

If `go test` fails because Postgres is not running, that is acceptable — surface the error to the user and explain they need `make docker-up` first.

---

## Step 7 — Print Summary

```
Go backend scaffolded
=====================

Module:     <module>
Binary:     bin/<appname>
Port:       <port>
Domain:     <domain> (CRUD: List, Get, Create, Update, Delete)

Structure:
  cmd/server/main.go           entrypoint only
  internal/server/             Gin engine and routes
  internal/<domain>/           handler, service, tests
  internal/db/                 DB connection + sqlc queries
  migrations/                  SQL schema files

Files created:
  <list every file written>

Next steps:
  1. Install sqlc:       brew install sqlc  (or via Docker)
  2. Start Postgres:     make docker-up
  3. Run migrations:     make migrate-up
  4. Generate DB code:   make sqlc
  5. Run the server:     make run
  6. Run tests:          make test
```

---

## Important Rules

- `main.go` must contain ONLY the `main()` function: connect DB, create server, call Run. Nothing else.
- No DB queries or SQL strings outside `internal/db/`.
- No Gin handler logic in `internal/<domain>/service.go` — services are HTTP-agnostic.
- No business logic in `handler.go` — handlers only parse input, call service, return JSON.
- All placeholder `<domain>`, `<Domain>`, `<module>`, `<appname>`, `<port>` tokens must be substituted with real values before writing files.
- Do not leave TODO comments or unresolved placeholders in written files.
