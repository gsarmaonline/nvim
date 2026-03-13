---
name: create-nextjs-frontend
description: Scaffold a Next.js frontend, detect an existing backend, and wire up Docker and Makefile commands
---

You are being invoked via the /create-nextjs-frontend skill. Your task is to scaffold a production-ready Next.js frontend in the current directory, detect any existing backend service, and integrate everything into a unified Docker and Makefile setup.

---

## Step 1 — Gather Project Info

Ask the user (or infer from context) before proceeding:

1. **App name**: e.g. `myapp-web` (used for the Docker image tag and directory name)
2. **Frontend directory**: default `frontend/` (relative to project root)
3. **Port**: default `3000`

If the user provides arguments (e.g. `/create-nextjs-frontend myapp-web frontend 3000`), parse them directly.

---

## Step 2 — Detect Existing Backend

Before scaffolding, scan the project root for a backend service:

```bash
ls go.mod Makefile docker-compose.yml 2>/dev/null
```

Check for these signals:
- `go.mod` present: Go backend
- `docker-compose.yml` present: read it to find existing services, their ports, and service names
- `Makefile` present: read it to understand existing targets before adding new ones

Record:
- **Backend service name** in docker-compose (e.g. `app`, `api`)
- **Backend internal port** (e.g. `8080`)
- **Backend URL the frontend should use**: `http://<service>:<port>` for container-to-container, `http://localhost:<port>` for local dev

---

## Step 3 — Scaffold the Next.js App

### 3a. Run `create-next-app`

```bash
npx create-next-app@latest <frontend-dir> \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --no-git
```

This generates the standard Next.js App Router structure inside `<frontend-dir>/`.

### 3b. Add API Client

Create `<frontend-dir>/src/lib/api.ts`:

```typescript
const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:<backend-port>";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { "Content-Type": "application/json", ...init?.headers },
    ...init,
  });
  if (!res.ok) {
    throw new Error(`API error ${res.status}: ${await res.text()}`);
  }
  return res.json() as Promise<T>;
}

export const api = {
  get: <T>(path: string) => request<T>(path),
  post: <T>(path: string, body: unknown) =>
    request<T>(path, { method: "POST", body: JSON.stringify(body) }),
  put: <T>(path: string, body: unknown) =>
    request<T>(path, { method: "PUT", body: JSON.stringify(body) }),
  delete: <T>(path: string) => request<T>(path, { method: "DELETE" }),
};
```

### 3c. Add `.env.local` and `.env.example`

`<frontend-dir>/.env.local`:
```bash
NEXT_PUBLIC_API_URL=http://localhost:<backend-port>
```

`<frontend-dir>/.env.example`:
```bash
# URL of the backend API, accessible from the browser
NEXT_PUBLIC_API_URL=http://localhost:<backend-port>
```

### 3d. Update `<frontend-dir>/.gitignore`

Ensure it includes:
```
.env.local
.env*.local
```

---

## Step 4 — Add Dockerfile for Frontend

Create `<frontend-dir>/Dockerfile`:

```dockerfile
# Stage 1: install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

# Stage 2: build
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
RUN npm run build

# Stage 3: run
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs && \
    adduser  --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE <frontend-port>
ENV PORT <frontend-port>

CMD ["node", "server.js"]
```

Also add to `<frontend-dir>/next.config.ts` (or `.js`):

```typescript
const nextConfig = {
  output: "standalone",
};

export default nextConfig;
```

---

## Step 5 — Update `docker-compose.yml`

### If `docker-compose.yml` exists at the project root:

Read the existing file. Add a `frontend` service without removing or breaking existing services:

```yaml
  frontend:
    build:
      context: ./<frontend-dir>
      dockerfile: Dockerfile
      args:
        NEXT_PUBLIC_API_URL: http://<backend-service>:<backend-port>
    ports:
      - "<frontend-port>:<frontend-port>"
    environment:
      NEXT_PUBLIC_API_URL: http://<backend-service>:<backend-port>
    depends_on:
      - <backend-service>
    restart: unless-stopped
```

Replace `<backend-service>` and `<backend-port>` with the values detected in Step 2. If no backend was detected, use placeholder values and note them in the summary.

### If `docker-compose.yml` does not exist:

Create a minimal one with just the frontend service plus a note that the backend should be added:

```yaml
services:
  frontend:
    build:
      context: ./<frontend-dir>
      dockerfile: Dockerfile
    ports:
      - "<frontend-port>:<frontend-port>"
    environment:
      NEXT_PUBLIC_API_URL: http://localhost:<backend-port>
    restart: unless-stopped
```

---

## Step 6 — Update `Makefile`

### If a `Makefile` exists:

Read it first. Append the following targets without overwriting existing ones. If a target name conflicts with an existing one, prefix it with `fe-`:

```makefile
## Frontend targets
fe-install:
	cd <frontend-dir> && npm install

fe-dev:
	cd <frontend-dir> && npm run dev

fe-build:
	cd <frontend-dir> && npm run build

fe-lint:
	cd <frontend-dir> && npm run lint

fe-test:
	cd <frontend-dir> && npm test -- --passWithNoTests

## Docker targets (update or add if not present)
docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

docker-logs-fe:
	docker compose logs -f frontend
```

Only add `docker-build`, `docker-up`, `docker-down`, `docker-logs` if they are not already present in the Makefile. Never duplicate existing targets.

### If no `Makefile` exists:

Create a minimal one:

```makefile
APP := <appname>

.PHONY: fe-install fe-dev fe-build fe-lint fe-test docker-build docker-up docker-down docker-logs docker-logs-fe

fe-install:
	cd <frontend-dir> && npm install

fe-dev:
	cd <frontend-dir> && npm run dev

fe-build:
	cd <frontend-dir> && npm run build

fe-lint:
	cd <frontend-dir> && npm run lint

fe-test:
	cd <frontend-dir> && npm test -- --passWithNoTests

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

docker-logs-fe:
	docker compose logs -f frontend
```

---

## Step 7 — Verify

Run the following to confirm the frontend project was created correctly:

```bash
ls <frontend-dir>/src/app <frontend-dir>/src/lib/api.ts
```

Do NOT run `npm run build` or `npm run dev` automatically — those require the backend to be running.

---

## Step 8 — Print Summary

```
Next.js frontend scaffolded
============================

App:        <appname>
Directory:  <frontend-dir>/
Port:       <frontend-port>
Backend:    <detected backend service> on port <backend-port>  (or "none detected")

Files created / modified:
  <frontend-dir>/                          Next.js app (App Router, TypeScript, Tailwind)
  <frontend-dir>/src/lib/api.ts            Typed API client
  <frontend-dir>/.env.local               Local dev env vars
  <frontend-dir>/.env.example             Env var documentation
  <frontend-dir>/Dockerfile               Multi-stage production image
  <frontend-dir>/next.config.ts           standalone output enabled
  docker-compose.yml                       frontend service added
  Makefile                                 fe-* and docker-* targets added

Next steps:
  1. Install deps:       make fe-install
  2. Start backend:      make docker-up  (or make run if backend is local)
  3. Run dev server:     make fe-dev
  4. Build for prod:     make docker-build && make docker-up
  5. View logs:          make docker-logs-fe
```

---

## Important Rules

- Always read existing `docker-compose.yml` and `Makefile` before modifying them. Never overwrite existing content.
- Use container-to-container DNS names (service name, not `localhost`) for `NEXT_PUBLIC_API_URL` in docker-compose.
- Use `http://localhost:<backend-port>` for `.env.local` (local dev without Docker).
- `output: "standalone"` must be set in `next.config.ts` for the multi-stage Dockerfile to work.
- Do not commit `.env.local` — ensure it is in `.gitignore`.
- All placeholder tokens (`<frontend-dir>`, `<frontend-port>`, `<backend-service>`, `<backend-port>`, `<appname>`) must be substituted with real values before writing files.
