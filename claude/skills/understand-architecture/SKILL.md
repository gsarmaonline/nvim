---
name: understand-architecture
description: Map an unfamiliar codebase end to end — entrypoints, data flow, build graph, test infrastructure — and write an ARCHITECTURE map before changing any code
---

You are invoked via the `/understand-architecture` skill. Your task is to read an unfamiliar
repository critically and produce a compact, accurate map of it. You do NOT change code.

The output is a map a senior engineer would want on day one: where the entrypoints are, how a
request flows end to end, where state lives, how it builds, and how it is tested.

**Speed matters.** Aim to finish in 10–15 minutes of wall clock. Breadth beats depth here; the
depth comes later when a specific area is under suspicion.

---

## Step 0 — Ground rules

- Read only. Do not edit, format, or "fix" anything.
- Prefer reading configuration and entrypoints over reading every file.
- Record file paths as `path/to/file.py:42` so they stay clickable.
- If something looks wrong while you map, do NOT fix it. Add it to a **Suspicions** list at the
  end of the map. That list is the seed for a later audit.

---

## Step 1 — Shape of the repository

Run these and read the results before opening any source file.

```bash
ls -la
git log --oneline -20 2>/dev/null
git ls-files | head -200
git ls-files | wc -l
```

Identify the layout in one of these categories:
- Single package
- Monorepo with a workspace manager (`pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `.moon/`,
  `lerna.json`, Cargo workspace, Go workspace)
- Polyglot monorepo (more than one language with separate toolchains)

Find the manifests. These define the real boundaries:

```bash
git ls-files | grep -E '(package\.json|pyproject\.toml|requirements.*\.txt|go\.mod|Cargo\.toml|pom\.xml|Gemfile|\.moon/.*\.ya?ml|moon\.ya?ml|turbo\.json|nx\.json|pnpm-workspace\.ya?ml)$'
```

Also find the docs and the contracts, which are the cheapest high-value reading:

```bash
git ls-files | grep -iE '(README|CONTRIBUTING|ARCHITECTURE|CLAUDE|AGENTS)\.md$'
git ls-files | grep -E '\.(proto|graphql|openapi\.ya?ml|swagger\.ya?ml)$'
git ls-files | grep -E '(docker-compose.*\.ya?ml|Dockerfile.*|Makefile|Taskfile\.ya?ml)$'
git ls-files | grep -E '\.github/workflows/.*\.ya?ml$'
```

Read every README and every interface contract file you found. Contracts (`.proto`, GraphQL
schema, OpenAPI) tell you the whole API surface in a fraction of the reading time.

---

## Step 2 — Find the entrypoints

An entrypoint is where control enters the system. Find all of them.

**Servers and daemons**
```
if __name__ == ['"]__main__['"]
def main\(|func main\(
app = FastAPI\(|Flask\(__name__\)|express\(\)|new Hono\(
grpc\.(aio\.)?server\(|add_insecure_port|add_secure_port
uvicorn\.run|gunicorn|hypercorn
```

**Frontend roots**
```
createRoot\(|ReactDOM\.render|createApp\(
```
Plus `index.html`, `main.tsx`, `App.tsx`, and the router definition.

**Jobs, workers, CLIs**
```
@(app\.)?task|celery|@cron|schedule\.|argparse|click\.command|cobra\.Command
```

**Scripts declared in manifests** — read the `scripts` block of every `package.json` and the
`[project.scripts]` / `[tool.*]` blocks of `pyproject.toml`. These are the commands a human
actually runs, so they are the truest entrypoints.

For each entrypoint record: file, what starts it, what port or queue it binds, and what it
depends on at boot.

---

## Step 3 — Trace one request end to end

Pick the most important single operation in the system. A read path with a list response is
usually the best choice, because it exposes serialization, the ORM, and pagination at once.

Follow it through every layer and record the file and line of each hop:

1. Client call site (frontend hook, generated stub, or HTTP client)
2. Transport (route table, gRPC service registration, message handler)
3. Middleware or interceptor chain — auth, logging, tracing, error mapping
4. Handler or resolver
5. Service or domain layer
6. Data access — ORM query, raw SQL, cache lookup, outbound API call
7. Response mapping back to the wire type
8. Where the client stores and renders it

Write this as a numbered chain. This single trace teaches you more about the codebase than
reading fifty files at random.

Then note the **layering rule** the codebase follows, and whether anything violates it. For
example: "handlers must not import the ORM session directly" — then check if any do.

---

## Step 4 — Map the data layer

```bash
git ls-files | grep -iE '(models?|schema|entities|migrations?|alembic)' | head -50
```

Record:
- Where models or entities are defined.
- The relationships between them, and the loading strategy on each relationship
  (`lazy="select"` is the default in SQLAlchemy and the usual source of N+1 queries).
- Which columns carry an index, and which columns are filtered or joined on. A mismatch here is
  a performance finding.
- How migrations run, and whether the migration history matches the models.
- How a session, connection, or transaction is created, scoped, and closed. Note whether the
  scope is per request, per call, or global. A global or module-level session is a reliability
  finding.
- Where the connection string comes from, and the pool settings.

---

## Step 5 — Map the build and task graph

Read the workspace configuration and record how to run each of these, exactly:

| Action | Command |
|---|---|
| Install dependencies | |
| Build everything | |
| Run the backend | |
| Run the frontend | |
| Run backend tests | |
| Run frontend tests | |
| Lint | |
| Type check | |
| Regenerate contracts (proto/GraphQL/OpenAPI) | |

For a task-graph tool (moon, turbo, nx), also record for each important task: its `deps`, its
`inputs`, and its `outputs`. Wrong `inputs` or missing `outputs` silently break caching, and
missing `deps` cause tasks to run in the wrong order. Both are common planted defects.

If the repository uses moonrepo, invoke the `/moonrepo` skill for the command reference instead
of guessing at the syntax.

---

## Step 6 — Map the test infrastructure

```bash
git ls-files | grep -E '(conftest\.py|pytest\.ini|tox\.ini|vitest\.config|jest\.config|setup\.cfg)'
git ls-files | grep -E '(^|/)(tests?|__tests__|spec)/' | head -40
```

Record:
- The test runner and how it is invoked for each language.
- Every fixture in `conftest.py`, and the **scope** of each one. A `session` or `module` scoped
  fixture that mutates shared state leaks between tests.
- How the database is isolated per test: transaction rollback, truncate, a fresh schema, or
  nothing at all. "Nothing at all" is a finding.
- What is mocked, and whether any mock replaces the code actually under test.
- Roughly what is covered and what is not. Name the untested critical path.

Then actually run the test suite once and record the result. A map that claims the suite is
green when it is red is worse than no map.

---

## Step 7 — Map configuration and environments

- Every environment variable the code reads. Grep for `os.environ`, `getenv`, `process.env`,
  `import.meta.env`.
- Which of them have defaults, and whether any default is unsafe for production.
- Whether `.env.example` exists and matches what the code actually reads. A drift between them
  costs a new developer an hour.
- How the frontend learns the backend address.
- What Docker Compose starts, and on which ports.

Never print a real secret value. Truncate to first four and last four characters.

---

## Step 8 — Write the map

Write `ARCHITECTURE_MAP.md` at the repository root, or under a notes directory if the user
prefers. Use this structure and keep it under roughly 300 lines:

```markdown
# Architecture Map — <repo name>

_Read-only map. Generated <date>._

## 1. Summary
Three sentences: what the system does, what the pieces are, how they talk.

## 2. Layout
| Package | Path | Language | Responsibility |
|---|---|---|---|

## 3. Entrypoints
| Entrypoint | File | Starts what | Port / trigger |
|---|---|---|---|

## 4. Request trace — <operation name>
1. `file:line` — description
2. ...

## 5. Data layer
- Models: ...
- Relationships and loading strategy: ...
- Indexes vs. filtered columns: ...
- Session and transaction scope: ...
- Migrations: ...

## 6. Build and task graph
| Action | Command |
|---|---|

Task dependency notes: ...

## 7. Tests
- Runner and command: ...
- Isolation strategy: ...
- Current state: <N passed, N failed>
- Untested critical paths: ...

## 8. Configuration
| Variable | Read at | Default | Notes |
|---|---|---|---|

## 9. Suspicions
Things that looked wrong while mapping. Not verified. One line each, with `file:line`.
| # | Area | Suspicion | File |
|---|---|---|---|
```

---

## Step 9 — Report

Give the user a short spoken summary: the shape of the system, the one request trace, the exact
commands to run and test it, and the top five suspicions in priority order.

State plainly whether the test suite passes right now.

If the user wants those suspicions turned into verified findings, point them at
`/audit-codebase`. If they want a fix applied, point them at `/surgical-fix`.

---

## Notes

- Do not speculate about code you did not open. If you did not read it, say so.
- Prefer the contract files and the manifests. They are dense with truth per line read.
- Where two sources disagree — for example the README and the actual scripts — trust the code
  and record the drift as a suspicion.
