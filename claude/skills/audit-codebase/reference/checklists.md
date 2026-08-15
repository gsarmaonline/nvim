# Audit checklists

Concrete defect shapes and the greps that surface them. Work the sections that match the stack.
Every hit is a **candidate**, never a finding — verify it against Step 3 of the skill first.

Grep with `rg` when available. Exclude `node_modules`, `.venv`, `dist`, `build`, and generated
protobuf output (`*_pb2.py`, `*_pb2_grpc.py`, `*.pb.go`, `*_pb.ts`) unless the generator config
itself is under suspicion.

---

## 1. Security

### 1a. Authentication

The classic planted defect is a check that exists on most handlers and is missing on one.
Enumerate every handler, then enumerate every protected handler, then diff the two lists.

```
# Python decorators and dependencies
@(app|router)\.(get|post|put|patch|delete)
Depends\(|Security\(|require_auth|login_required|current_user
# gRPC
class \w+Servicer|def [A-Z]\w+\(self, request, context\)
add_\w+Servicer_to_server|intercept_service|ServerInterceptor
# Node
(app|router)\.(get|post|put|patch|delete)|@UseGuards|passport\.authenticate
```

Look for:
- One handler in a service class with no auth call, when its siblings all have one.
- An interceptor that returns early for a method allowlist that is too broad — a prefix match
  such as `startswith("/Public")` matched against a method named `/PublicUserAdminDelete`.
- Token decoded but never verified: `jwt.decode(..., options={"verify_signature": False})`,
  `jwt.decode()` without a key, or `base64.b64decode` on a token.
- `verify=False` on any outbound request.
- Algorithm confusion: `algorithms=["HS256", "none"]`, or an algorithm list read from the token.
- No expiry claim set or checked.

### 1b. Authorization and IDOR

The most commonly planted defect. Authentication passes; ownership is never checked.

```
get\(\w*[Ii]d\)|filter_by\(id=|query\.get\(|\.get\(request\.
where\(\w+\.id ==
```

For every fetch by an identifier that came from the request, ask: **whose object is it?** If the
query filters only on the identifier and never on the caller, it is an IDOR.

Also look for:
- A role check that reads a role from the request body instead of from the verified token.
- A mass-assignment path: `Model(**request_dict)` or `setattr` in a loop over client keys,
  which lets a caller set `is_admin` or `owner_id`.
- Admin routes guarded only by an obscure path.

### 1c. Injection

```
# SQL
execute\(f['"]|execute\(['"].*%s.*['"] *%|text\(f['"]|\.format\(.*SELECT
session\.execute\(|engine\.execute\(|raw\(|\.query\(f['"]
# Command
subprocess\.(run|call|Popen|check_output)\(.*shell=True|os\.system\(|eval\(|exec\(
child_process\.exec\(
# Deserialization
pickle\.loads|yaml\.load\((?!.*Loader=)|marshal\.loads
```

SQLAlchemy note: `text()` is safe with bound parameters and unsafe with an f-string. Look for
interpolation into `order_by`, `ORDER BY` and column names specifically — parameters cannot bind
identifiers, so this is where injection survives an otherwise parameterized codebase.

### 1d. Secrets and crypto

```
(secret|password|passwd|token|api[_-]?key)\s*[:=]\s*['"][^'"]{6,}
SECRET_KEY|JWT_SECRET|PRIVATE_KEY|-----BEGIN
os\.getenv\(['"][^'"]+['"],\s*['"][^'"]+['"]\)
hashlib\.(md5|sha1)\(|\.hexdigest\(\)
random\.|Math\.random\(
==\s*(stored|expected)_(password|token|hash)
```

Look for:
- A default value on a secret read from the environment. The default ships to production.
- Passwords hashed with MD5 or SHA-1, hashed without a salt, or stored in plain text. The fix
  needs a migration path: verify with the old scheme, rehash on the next successful login.
- `random` instead of `secrets` for tokens, session identifiers, or password resets.
- Token or password compared with `==` instead of `hmac.compare_digest` — a timing leak.
- `.env` missing from `.gitignore`, or a real `.env` committed.
- A secret in a `VITE_`, `NEXT_PUBLIC_`, or `REACT_APP_` variable. Those ship to the browser.

### 1e. Transport and headers

```
add_insecure_port|insecure_channel|grpc\.insecure
allow_origins=\[['"]\*|origin: *['"]\*|Access-Control-Allow-Origin.*\*
debug=True|DEBUG *= *True|app\.run\(.*debug
```

Wildcard CORS combined with credentials is a real defect, not a nit. `debug=True` on a
production path exposes stack traces and, in Flask, an interactive console.

### 1f. Frontend

```
dangerouslySetInnerHTML|innerHTML *=|v-html
localStorage\.setItem\(.*(token|jwt|secret)
target=['"]_blank(?!.*rel=)
```

---

## 2. Performance

### 2a. N+1 queries — check this first, it is planted most often

In SQLAlchemy, every `relationship()` without a `lazy=` argument loads lazily. Touching it
inside a loop issues one query per row.

```
relationship\(
for \w+ in .*\.(all|scalars|query)\(|for \w+ in \w+s:
selectinload|joinedload|subqueryload|contains_eager
```

The shape to hunt: a query returns a list, then a loop or a serializer reads `row.related.name`.
Read the response serializer specifically — the loop is often hidden inside it.

The fix is `selectinload` for collections and `joinedload` for many-to-one. Say which and why.

Confirm it by counting queries, not by intuition:

```python
import logging
logging.basicConfig()
logging.getLogger("sqlalchemy.engine").setLevel(logging.INFO)
```

### 2b. Indexes

Cross-reference two lists: columns that are filtered, joined, ordered, or unique-checked; and
columns that carry `index=True`, a `UniqueConstraint`, or an `Index()`. Anything in the first
list and not the second is a candidate. Foreign keys do NOT get an index automatically in
PostgreSQL.

```
filter\(|filter_by\(|where\(|order_by\(|ForeignKey\(
index=True|Index\(|unique=True|primary_key=True
```

### 2c. Unbounded and repeated work

```
\.all\(\)|\.scalars\(\)\.all\(\)|SELECT \*
\.count\(\)|len\(.*\.all\(\)\)
for .*:\n.*(session|db)\.(commit|query|execute)
```

Look for:
- A list endpoint with no limit or pagination.
- `len(query.all())` where `query.count()` would do, which pulls every row into memory.
- `commit()` inside a loop — one transaction per row instead of one for the batch.
- Filtering or sorting in Python over rows that the database could have filtered.
- A query inside a loop that could be one `IN` query.
- An engine or client created per request instead of once at startup.

### 2d. Async and blocking

```
async def .*:\n(?:.*\n)*?.*(requests\.|time\.sleep|\.read\(\)|psycopg2)
```

A synchronous database driver, `requests`, or `time.sleep` inside an `async def` blocks the
whole event loop. In a gRPC thread-pool server, check `max_workers` — a small pool plus slow
handlers is a queueing failure under load.

### 2e. Frontend

```
useEffect\(|useMemo\(|useCallback\(|key=\{(index|i)\}
```

Look for a `useEffect` with a missing or over-broad dependency array, a fetch waterfall where
requests could run in parallel, a list keyed by array index, and a context value rebuilt every
render, which re-renders every consumer.

---

## 3. Reliability

### 3a. Transactions

```
\.commit\(\)|\.rollback\(\)|begin\(\)|with session
try:|except|finally:
```

Look for:
- Two or more writes that must succeed together but sit in separate transactions.
- `commit()` with no `rollback()` on the error path, which leaves the session unusable for
  every later request that reuses it.
- A read-modify-write with no lock and no atomic update — the classic lost update. The fix is
  `SELECT ... FOR UPDATE`, an atomic `UPDATE ... SET x = x - 1`, or a version column.
- A side effect that is not transactional — an email, a webhook, a payment — fired before the
  commit that it assumes succeeded.

### 3b. Error handling

```
except:|except Exception:|except BaseException:
pass$|return None$|catch \(\w*\) *\{ *\}
```

A bare `except` that logs nothing turns a defect into silence. Also check that the error path
does not leak internals to the caller: a stack trace or a raw database message in a gRPC
`context.abort` or an HTTP body is an information leak.

### 3c. Resource lifetime

```
Session\(\)|sessionmaker|scoped_session|create_engine
open\(|socket\(|connect\(
close\(\)|with |contextmanager|__exit__
```

Look for a session or connection created and never closed on the error path, a module-level
session shared across threads or requests, and a pool size that cannot serve the configured
worker count.

### 3d. Timeouts, retries, deadlines

```
requests\.(get|post)\((?!.*timeout)|httpx\.|urlopen\(
stub\.\w+\((?!.*timeout)|\.with_deadline|context\.time_remaining
retry|backoff|max_attempts
```

A network call with no timeout hangs forever and exhausts the pool. A retry with no backoff
amplifies an outage. A retry on a non-idempotent write duplicates data — that is a correctness
defect, not a reliability one.

Also check that the server shuts down gracefully: `server.stop(grace)` rather than an immediate
kill that drops in-flight calls.

### 3e. Correctness of data

```
Float|float\(|round\(|\* 100|/ 100
datetime\.now\(\)|datetime\.utcnow\(\)|date\.today\(\)
```

Money in a float loses precision — it needs `Numeric`/`Decimal` or integer minor units. A naive
`datetime.now()` without a timezone breaks across hosts; `utcnow()` is deprecated and returns a
naive object. Also check unique constraints that the code assumes but the schema does not
enforce, and nullable columns the code assumes are never null.

---

## 4. Testing

```
conftest\.py|@pytest\.fixture|scope=['"](session|module|class)['"]
mock|patch|MagicMock|monkeypatch
assert |expect\(
```

Look for:
- A fixture with `scope="session"` or `scope="module"` that mutates shared state, so tests pass
  alone and fail in a different order. Verify with `pytest -p no:randomly` versus a shuffled run.
- No database rollback or truncation between tests. A per-test transaction that rolls back is
  the standard fix.
- A test that mocks the very function it claims to test, so it asserts on the mock.
- A test with no assertion, or one asserting only that no exception was raised.
- `time.sleep` in tests, or a dependence on real wall-clock time or real randomness.
- A test that depends on the network or on a live external service.
- Critical paths with no test at all — name them.

Run the suite twice and compare. Then run it in a different order. A difference is a finding.

---

## 5. Tooling, build, and CI

### 5a. Task graph (moon, turbo, nx)

- A task that consumes another package's output but does not declare it in `deps`. It works
  locally by luck and fails on a cold cache.
- `inputs` that omit a file the task actually reads, so a real change hits a stale cache. This
  is the sharpest kind of task-graph defect: the build reports success and ships old output.
- `inputs` so broad they include the output directory, so the cache never hits.
- Missing `outputs`, so nothing is cached at all.
- `runInCI: false` on a task that guards correctness, such as type checking or tests.
- A task run through a shell chain that hides the real exit code — `a && b || true`.

Verify by clearing the cache and running the task graph cold.

### 5b. Dependencies

- A lockfile absent from version control, or `--no-frozen-lockfile` in CI.
- Unpinned Python dependencies, or a `requirements.txt` that disagrees with `pyproject.toml`.
- A generated client checked in but stale relative to its `.proto` or schema. Regenerate and
  diff — a drift here silently breaks the wire contract.

### 5c. CI

- A test suite for one language and not the other in a polyglot repository.
- A job that never fails the build, because the step swallows its exit code.
- No type check, or a type check pinned to a permissive mode while the code assumes strict.
- Secrets echoed into logs.

### 5d. Containers

```
FROM |USER |ENV |ARG |COPY \.
```

- No `USER` directive, so the process runs as root.
- A secret passed as `ARG` or `ENV`, which persists in the image layers.
- `COPY . .` with no `.dockerignore`, which ships `.env` and `.git`.
- A floating base tag such as `:latest`, so the build is not reproducible.

---

## 6. gRPC and protobuf specifics

- A field renumbered or reused after release. That breaks every deployed client.
- `required` semantics assumed in proto3, where every scalar has a zero default. Code that
  cannot distinguish "absent" from "zero" mishandles a legitimate `0` or `""`. The fix is
  `optional` or a wrapper type.
- No message size limit set, or one raised far above what the handler can hold in memory.
- An interceptor ordering defect: logging placed before authentication, so unauthenticated
  payloads reach the log.
- `context.abort` with a status code that does not match the failure — everything returned as
  `UNKNOWN` prevents the client from retrying correctly.
- Streaming handler that accumulates the whole stream in a list, defeating the point of it.
- A generated stub imported from a path that the build does not regenerate.
