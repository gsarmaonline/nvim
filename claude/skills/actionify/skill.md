---
name: actionify
description: Generate GitHub Actions workflows for CI/CD with testing and builds
---

You are being invoked via the /actionify skill. Your task is to automatically detect project structure and generate comprehensive GitHub Actions workflows for testing and building.

## Overview

This skill helps with CI/CD automation by:
1. Detecting project type (frontend, backend, monorepo, etc.)
2. Identifying testing frameworks and build tools
3. Generating GitHub Actions workflows
4. Setting up test automation
5. Configuring build pipelines
6. Handling multi-service repositories

## Steps to Execute

### 1. Analyze Project Structure

Detect all services and components in the repository:

**Check for:**
- Frontend applications (React, Vue, Angular, Svelte, Next.js)
- Backend services (Node.js, Python, Go, Rust, Ruby, Java)
- Mobile apps (React Native, Flutter)
- Monorepo structure (Nx, Turborepo, Lerna, workspaces)
- Databases (migrations, schema)
- Docker services
- Infrastructure as Code (Terraform, CloudFormation)

**Scan for indicators:**
```bash
# Frontend
ls package.json tsconfig.json vite.config.* next.config.* vue.config.* angular.json svelte.config.*

# Backend
ls package.json requirements.txt Pipfile pyproject.toml go.mod Cargo.toml Gemfile pom.xml build.gradle

# Monorepo
ls lerna.json nx.json turbo.json pnpm-workspace.yaml

# Docker
ls Dockerfile docker-compose.yml .dockerignore

# Mobile
ls app.json metro.config.js pubspec.yaml
```

### 2. Discover Actual Tests

Do not assume tests exist — find them. Run each check that is relevant to the detected languages.

**Go:**
```bash
# Find all test files
find . -name '*_test.go' -not -path './vendor/*' | head -20

# Check if Makefile has a test target
grep -n '^test' Makefile 2>/dev/null

# Check go.mod for the module path and Go version
cat go.mod
```

Record:
- Test command: `go test ./... -race -count=1` (standard), or the Makefile target if one exists (e.g. `make test`)
- Whether any test file imports `database/sql` or `sqlc` (signals DB is needed in CI)
- Whether docker-compose has postgres/redis services (must be wired as CI services)

**Node.js / TypeScript:**
```bash
# Read the test script from package.json
cat package.json | grep -A2 '"test"'

# Find test files
find . -name '*.test.ts' -o -name '*.test.js' -o -name '*.spec.ts' -o -name '*.spec.js' | grep -v node_modules | head -20

# Check for test framework config files
ls jest.config.* vitest.config.* playwright.config.* cypress.config.* 2>/dev/null
```

Record:
- Exact test script name from package.json (e.g. `npm test`, `npm run test`, `npm run test:unit`)
- Whether Playwright/Cypress is present (needs separate E2E job)
- Whether tests need a running server or DB

**Python:**
```bash
# Find test files
find . -name 'test_*.py' -o -name '*_test.py' | grep -v __pycache__ | head -20

# Check for pytest config
cat pytest.ini pyproject.toml setup.cfg 2>/dev/null | grep -A5 '\[tool.pytest\|pytest\]'

# Check dependencies for test framework
grep -i 'pytest\|unittest\|nose' requirements*.txt 2>/dev/null
```

Record:
- Test command: `pytest` (with any flags from config), or `python -m pytest`
- Whether tests need a DB (grep imports in test files for `psycopg2`, `sqlalchemy`, `django.db`)

**Rust:**
```bash
# Check for tests in source files
grep -rn '#\[test\]' src/ | head -10

# Check for integration tests directory
ls tests/ 2>/dev/null
```

Record: `cargo test` is always the command.

**Ruby:**
```bash
grep -E 'rspec|minitest' Gemfile 2>/dev/null
ls spec/ test/ 2>/dev/null
```

**Makefile shortcut (any language):**
```bash
# If a Makefile exists, prefer its test target — it already knows the right command
grep -n '^test\b\|^\.PHONY.*test' Makefile 2>/dev/null
```

If `make test` exists, use it as the CI test command. It avoids duplicating logic.

**If no tests are found:** Note it in the summary and generate a CI workflow with a placeholder test step and a comment explaining where to add tests. Do not skip the workflow entirely.

### 3. Detect Build Tools

Identify how to build each component:

**Frontend:**
- Vite: `npm run build` → `dist/`
- Webpack: `npm run build` → `build/` or `dist/`
- Next.js: `npm run build` → `.next/`
- Angular: `ng build` → `dist/`

**Backend:**
- Node.js: Usually no build needed (or TypeScript compilation)
- Python: Package with `python setup.py build` or Poetry
- Go: `go build -o bin/app`
- Rust: `cargo build --release`

**Docker:**
- Build images: `docker build -t app:$VERSION .`

### 4. Create GitHub Actions Directory

```bash
mkdir -p .github/workflows
```

### 5. Generate CI Workflow

Create `.github/workflows/ci.yml` using only the languages, test commands, and services **actually detected** in Step 2. Do not generate jobs for languages or frameworks not present in the repo.

**Rules for generating the workflow:**

- Use the exact test command discovered (e.g. `make test`, `go test ./... -race`, `npm test`, `pytest`)
- Only add a `services:` block for postgres/redis if the tests actually need a DB (detected in Step 2)
- Only add a lint job if a linter is configured (e.g. `golangci-lint`, `ruff`, `eslint` in package.json)
- Only add an E2E job if Playwright or Cypress is detected
- Always gate the `build` job on `needs: [test]` so builds never run when tests fail
- Use `actions/upload-artifact@v4`, `actions/checkout@v4`, `actions/setup-go@v5`, `actions/setup-node@v4`, `actions/setup-python@v5` (latest versions)

**Go project with Postgres:**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest

    # Only include this services block if tests need Postgres (detected in Step 2)
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version-file: go.mod   # reads version from go.mod, no hardcoding
          cache: true

      - name: Download modules
        run: go mod download

      # Only include if golangci-lint is configured (.golangci.yml exists or detected)
      - name: Lint
        uses: golangci/golangci-lint-action@v6
        with:
          version: latest

      # Use the exact command found in Step 2 (make test OR go test ./... -race)
      - name: Run tests
        run: go test ./... -v -race -coverprofile=coverage.out
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/testdb?sslmode=disable

      - name: Upload coverage
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: coverage.out
          retention-days: 7

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: Build
        run: go build -o bin/app ./cmd/server   # adjust entrypoint to match detected cmd path
```

**Node.js / Next.js project:**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc   # use .nvmrc if present, else hardcode detected version
          cache: npm

      - name: Install dependencies
        run: npm ci

      # Only include if eslint/prettier script exists in package.json
      - name: Lint
        run: npm run lint

      # Use the exact script name from package.json (npm test, npm run test, etc.)
      - name: Run tests
        run: npm test

  # Only include this job if Playwright is detected
  e2e:
    name: E2E
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps chromium

      - name: Run E2E tests
        run: npx playwright test

      - name: Upload Playwright report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 14

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [test]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version-file: .nvmrc
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
```

**Python project:**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest

    # Only include if tests need Postgres
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version-file: .python-version   # use file if present, else hardcode detected version
          cache: pip

      - name: Install dependencies
        run: pip install -r requirements.txt

      # Only include if ruff/flake8/pylint is in requirements or pyproject.toml
      - name: Lint
        run: ruff check .

      # Use the exact command found in Step 2
      - name: Run tests
        run: pytest -v --tb=short
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/testdb
```

**Monorepo (Go backend + Next.js frontend in same repo):**

Generate separate jobs per service, each running only in relevant paths:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-backend:
    name: Test Backend
    runs-on: ubuntu-latest
    # Only run when backend files change
    # (omit the 'paths' filter if you want it to always run)
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true
      - run: go mod download
      - name: Run tests
        run: go test ./... -race   # or: make test

  test-frontend:
    name: Test Frontend
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend   # adjust to detected frontend dir
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version-file: frontend/.nvmrc
          cache: npm
          cache-dependency-path: frontend/package-lock.json
      - run: npm ci
      - name: Run tests
        run: npm test   # exact script from package.json

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [test-backend, test-frontend]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true
      - run: go build -o bin/app ./cmd/server
```

### 6. Adapt the Workflow to Findings

After generating the base workflow from the template above, **customize it** based on Step 2 discoveries:

- Replace any placeholder commands with the exact commands found (e.g. `make test` instead of `go test ./...` if a Makefile target exists)
- Remove service blocks (postgres, redis) if no DB usage was detected in tests
- Remove lint steps if no linter config was found
- Add `working-directory:` defaults for monorepo sub-directories
- Use `go-version-file: go.mod` instead of hardcoding a Go version; use `.nvmrc` for Node if the file exists
- If no test files were found at all, generate the workflow with a placeholder step and add a comment: `# No tests detected — add your test command here`

### 7. Create Docker Build Workflow

If Dockerfile exists, create `.github/workflows/docker.yml`:

```yaml
name: Docker Build

on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### 8. Create Deployment Workflow

Create `.github/workflows/deploy.yml` for automatic deployments:

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
        env:
          NODE_ENV: production

      - name: Deploy to staging
        run: npm run deploy:staging
        env:
          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}

  deploy-production:
    name: Deploy to Production
    needs: deploy-staging
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://example.com

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
        env:
          NODE_ENV: production

      - name: Deploy to production
        run: npm run deploy:production
        env:
          DEPLOY_TOKEN: ${{ secrets.PRODUCTION_DEPLOY_TOKEN }}
```

### 9. Create Dependency Update Workflow

Create `.github/workflows/dependencies.yml` for automated dependency updates:

```yaml
name: Update Dependencies

on:
  schedule:
    - cron: '0 0 * * 1' # Weekly on Monday
  workflow_dispatch:

jobs:
  update-npm:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'

      - name: Update dependencies
        run: |
          npm update
          npm audit fix

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: 'chore: update npm dependencies'
          title: 'chore: update npm dependencies'
          body: 'Automated dependency updates'
          branch: deps/npm-updates
```

### 10. Create Monorepo Workflow (if applicable)

For monorepos with multiple packages:

```yaml
name: Monorepo CI

on: [push, pull_request]

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      frontend: ${{ steps.filter.outputs.frontend }}
      backend: ${{ steps.filter.outputs.backend }}
      shared: ${{ steps.filter.outputs.shared }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v2
        id: filter
        with:
          filters: |
            frontend:
              - 'packages/frontend/**'
            backend:
              - 'packages/backend/**'
            shared:
              - 'packages/shared/**'

  test-frontend:
    needs: changes
    if: needs.changes.outputs.frontend == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: 'npm'
      - run: npm ci
      - run: npm run test --workspace=packages/frontend

  test-backend:
    needs: changes
    if: needs.changes.outputs.backend == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: 'npm'
      - run: npm ci
      - run: npm run test --workspace=packages/backend
```

### 11. Update CLAUDE.md

Add CI/CD workflow management:

```markdown
## Requirements

### CI/CD Automation

- Use the `/actionify` skill to generate/update GitHub Actions workflows when project structure changes
- Before creating PRs that add new services or change test setup, run `/actionify` to update workflows
- Ensure all tests pass in CI before merging
- Workflows should run on push to main and on pull requests
- Build artifacts should only be generated after tests pass
```

### 12. Add Documentation

Create `.github/workflows/README.md`:

```markdown
# GitHub Actions Workflows

This directory contains CI/CD workflows for automated testing and deployment.

## Workflows

### CI (`ci.yml`)
Runs on every push and pull request:
- Linting and formatting checks
- Backend tests with database services
- Frontend tests
- E2E tests with Playwright
- TypeScript type checking
- Build verification

### Docker (`docker.yml`)
Builds and publishes Docker images:
- Runs on push to main and on tags
- Publishes to GitHub Container Registry
- Uses layer caching for faster builds

### Deploy (`deploy.yml`)
Automated deployments:
- Staging: Deploys automatically from main branch
- Production: Requires manual approval

### Dependencies (`dependencies.yml`)
Weekly dependency updates:
- Runs every Monday
- Creates PRs with updated dependencies
- Includes security fixes

## Required Secrets

Configure these secrets in GitHub Settings → Secrets:

- `STAGING_DEPLOY_TOKEN` - Deployment token for staging
- `PRODUCTION_DEPLOY_TOKEN` - Deployment token for production
- `CODECOV_TOKEN` - (Optional) For code coverage reporting

## Local Testing

Test workflows locally with [act](https://github.com/nektos/act):

```bash
# Install act
brew install act

# Run CI workflow
act push

# Run specific job
act -j test-backend
```

## Status Badges

Add to README.md:

```markdown
![CI](https://github.com/username/repo/workflows/CI/badge.svg)
![Docker](https://github.com/username/repo/workflows/Docker%20Build/badge.svg)
```
```

### 13. Create Package.json Scripts (if Node.js)

Add helpful npm scripts for local development:

```json
{
  "scripts": {
    "test": "npm run test:backend && npm run test:frontend",
    "test:backend": "jest --config=jest.backend.config.js",
    "test:frontend": "jest --config=jest.frontend.config.js",
    "test:e2e": "playwright test",
    "test:watch": "jest --watch",
    "lint": "eslint . --ext .ts,.tsx,.js,.jsx",
    "lint:fix": "eslint . --ext .ts,.tsx,.js,.jsx --fix",
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,md}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,json,md}\"",
    "typecheck": "tsc --noEmit",
    "build": "npm run build:backend && npm run build:frontend",
    "build:backend": "tsc -p tsconfig.backend.json",
    "build:frontend": "vite build",
    "ci": "npm run lint && npm run typecheck && npm run test && npm run build"
  }
}
```

### 14. Report Summary

After completion, show:
- ✅ GitHub Actions workflows created: X workflows
- 📁 Saved to: `.github/workflows/`
- 🔧 Configured services: Postgres, Redis, etc.
- 🧪 Test frameworks detected: Jest, Playwright, etc.
- 🏗️  Build targets: Frontend, Backend, Docker
- 📝 Updated CLAUDE.md with CI/CD requirements
- 💡 Next steps: Push workflows and configure secrets

## Important Notes

- **Secrets**: Configure required secrets in GitHub repository settings
- **Services**: Database services run in Docker containers during CI
- **Caching**: Uses GitHub Actions cache for faster builds
- **Parallel**: Jobs run in parallel when possible
- **Artifacts**: Build outputs are saved as artifacts
- **Coverage**: Integrates with Codecov for coverage reporting
- **Monorepo**: Detects changes and runs only affected tests
- **Matrix**: Supports testing across multiple versions/platforms

## Example Usage

```bash
# User invokes
/actionify

# Skill responds
🔍 Analyzing project structure...

✓ Detected services:
  - Frontend: React + Vite (TypeScript)
  - Backend: Node.js + Express (TypeScript)
  - Database: PostgreSQL
  - Cache: Redis

✓ Test frameworks:
  - Unit: Jest
  - E2E: Playwright
  - Linting: ESLint + Prettier

✓ Build tools:
  - Frontend: Vite
  - Backend: TypeScript compiler
  - Docker: Multi-stage build

📝 Generated workflows:
  ✓ .github/workflows/ci.yml (main CI pipeline)
  ✓ .github/workflows/docker.yml (Docker builds)
  ✓ .github/workflows/deploy.yml (deployments)
  ✓ .github/workflows/dependencies.yml (dependency updates)
  ✓ .github/workflows/README.md (documentation)

🔧 Added npm scripts:
  - npm run ci (run full CI locally)
  - npm run test (all tests)
  - npm run lint (linting)
  - npm run build (build all)

⚙️  Next steps:
1. Push workflows to GitHub
2. Configure secrets in GitHub Settings:
   - STAGING_DEPLOY_TOKEN
   - PRODUCTION_DEPLOY_TOKEN
   - CODECOV_TOKEN (optional)
3. Workflows will run automatically on next push
4. Check Actions tab to see results

💡 Tip: Test locally with: npm run ci
```

Execute these steps to set up comprehensive GitHub Actions workflows for CI/CD.
