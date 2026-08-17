---
name: code-setup
description: Verify a machine can build, run, and test a repository — detect the required toolchain, check versions, install what is missing, bootstrap dependencies, and prove the test suite runs
---

You are invoked via the `/code-setup` skill. Your task is to take a machine from "just cloned
this" to "tests run green", and to report exactly what you changed.

Two modes:
- **Inside a repository** — detect what that repository needs and bootstrap it.
- **Outside a repository** — verify a named toolchain ahead of time, before the code arrives.

---

## Step 1 — Detect what is required

Inside a repository, read the requirements from the files, never from a guess:

```bash
ls -la
cat .tool-versions .nvmrc .python-version 2>/dev/null
git ls-files | grep -E '(package\.json|pnpm-workspace\.ya?ml|pyproject\.toml|requirements.*\.txt|go\.mod|Cargo\.toml|\.moon/toolchain\.ya?ml|docker-compose.*\.ya?ml|Makefile|\.github/workflows/.*\.ya?ml)$'
```

Extract the pinned versions:
- `package.json` → `engines`, `packageManager`, `volta`
- `pyproject.toml` → `requires-python`
- `.moon/toolchain.yml` → the node and package-manager versions moon will enforce
- `.github/workflows/*.yml` → the versions CI actually uses. **This is the most reliable
  source.** CI is what the grader runs, so match it.
- `Dockerfile` → the base image version

If two sources disagree, follow CI, and report the drift.

---

## Step 2 — Check what is present

```bash
for t in git python3 node npm pnpm yarn moon go cargo docker; do
  printf '%-8s %s\n' "$t" "$(command -v $t >/dev/null 2>&1 && $t --version 2>&1 | head -1 || echo MISSING)"
done
docker info >/dev/null 2>&1 && echo "docker daemon: running" || echo "docker daemon: NOT running"
```

Build a table of required version, found version, and verdict.

Watch for these traps:
- **Node version managers.** With `nvm`, `fnm`, or `volta` in use, globally installed CLIs such
  as `pnpm` belong to one Node version only. After switching Node, reinstall the global CLIs, or
  they vanish from `PATH`.
- **Odd-numbered Node releases.** v21, v23, v25 are Current, not LTS. They satisfy a "v20+" rule
  but break some native modules. Prefer the LTS line.
- **Python that is too new.** A release that is only months old often has no wheels for
  `grpcio`, `psycopg2`, `numpy`, or `lxml`, and falls back to a source build that fails. Keep the
  version the repository pins.
- **A `python3` that is the system one.** On macOS `/usr/bin/python3` is old and externally
  managed. Prefer a managed interpreter.

---

## Step 3 — Install what is missing

Ask the user before you install anything, unless they already told you to proceed. Say what you
will install, with what, and what it changes on their machine. Editing a shell profile always
needs consent — read the file before you edit it, and add one clearly commented line.

Prefer these, in order: a version manager the repository already pins, then the platform package
manager, then a direct installer script.

```bash
# Node, per repository pin
fnm install --lts && fnm default <version>   # or nvm install --lts
npm install -g pnpm                          # reinstall after any Node switch

# Python, per repository pin
uv python install 3.12
uv venv --python 3.12 .venv                  # uv venvs have no pip; use `uv pip install`
```

After each install, verify by running the tool, not by trusting the installer's output.

---

## Step 4 — Bootstrap the repository

Run the repository's own bootstrap if it has one — a `Makefile` target, a `scripts/setup.sh`, or
a documented command. Only fall back to generic commands when none exists.

```bash
# Node workspace
pnpm install --frozen-lockfile     # or npm ci / yarn --immutable

# Python
uv venv --python <pinned> .venv && uv pip install --python .venv/bin/python -e ".[dev]"
# or: .venv/bin/pip install -r requirements-dev.txt

# Services
docker compose up -d && docker compose ps

# Contracts, if the repo generates clients from proto/GraphQL/OpenAPI
<the repo's generate command>

# Migrations
alembic upgrade head    # or the repo's equivalent
```

Task-graph tools (moon, turbo, nx) need a git repository with **at least one commit**. `moon`
fails with `fatal: ambiguous argument 'HEAD'` in a repository that has none.

---

## Step 5 — Prove it works

A setup is not verified until something real runs. Run all of these that apply and record the
actual output:

```bash
<backend test command>
<frontend test command>
<type check>
<lint>
<build>
```

Then start the application and confirm it answers — a health check, a page load, a gRPC
reflection call. A green test suite with a server that will not boot is a half-verified setup.

Record the numbers: "backend 48 passed, frontend 12 passed, build succeeded in 9s".

---

## Step 6 — Report

Give the user:

1. **Version table** — required, found, verdict.
2. **What you installed or changed**, including any line added to a shell profile, with the file
   and line number.
3. **The verified command list** — install, run, test, build, lint, for each part of the repo.
   These are the commands they will use, so they must be exact and tested.
4. **Anything still broken**, stated plainly, with the error and the next step.
5. **Traps specific to this machine** — for example "open a new terminal for `fnm`", or "`moon`
   needs a commit first".

---

## Notes

- Never report success for a step you did not run. Run it.
- Prefer the repository's pinned versions over the newest release, every time.
- If a native build fails, check for a wheel on a slightly older interpreter before you install a
  compiler toolchain.
- Leave the machine in a state the user understands. List every global change you made.
