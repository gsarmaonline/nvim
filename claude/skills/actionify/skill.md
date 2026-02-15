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

### 2. Identify Testing Frameworks

Detect testing frameworks for each service:

**Node.js/TypeScript:**
- Jest (`jest` in package.json)
- Vitest (`vitest` in package.json)
- Mocha (`mocha` in package.json)
- Playwright (`@playwright/test` in package.json)
- Cypress (`cypress` in package.json)

**Python:**
- pytest (`pytest` in requirements.txt)
- unittest (built-in)
- nose2 (`nose2` in requirements.txt)

**Go:**
- Built-in testing (`*_test.go` files)

**Rust:**
- Built-in testing (`#[test]` in .rs files)

**Ruby:**
- RSpec (`rspec` in Gemfile)
- Minitest (built-in)

**Java:**
- JUnit (`junit` in pom.xml or build.gradle)
- TestNG (`testng` in dependencies)

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

Create `.github/workflows/ci.yml` with comprehensive testing:

**Example for Full-Stack Node.js App:**

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  NODE_VERSION: '20.x'

jobs:
  # Lint and format check
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run ESLint
        run: npm run lint

      - name: Check formatting
        run: npm run format:check
        continue-on-error: true

  # Backend tests
  test-backend:
    name: Test Backend
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run database migrations
        run: npm run migrate:test
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db

      - name: Run backend tests
        run: npm run test:backend
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
          NODE_ENV: test

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/backend/lcov.info
          flags: backend

  # Frontend tests
  test-frontend:
    name: Test Frontend
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run frontend tests
        run: npm run test:frontend

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/frontend/lcov.info
          flags: frontend

  # E2E tests
  test-e2e:
    name: E2E Tests
    runs-on: ubuntu-latest
    needs: [test-backend, test-frontend]
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps

      - name: Run E2E tests
        run: npm run test:e2e

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30

  # Build
  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [lint, test-backend, test-frontend]
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build frontend
        run: npm run build:frontend
        env:
          NODE_ENV: production

      - name: Build backend
        run: npm run build:backend
        env:
          NODE_ENV: production

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: |
            dist/
            .next/
            build/
          retention-days: 7

  # Type checking (TypeScript)
  typecheck:
    name: Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run type check
        run: npm run typecheck
```

### 6. Create Language-Specific Workflows

**Python Backend (`.github/workflows/python-ci.yml`):**

```yaml
name: Python CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.10', '3.11', '3.12']

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run linting
        run: |
          pip install ruff
          ruff check .

      - name: Run type checking
        run: |
          pip install mypy
          mypy .

      - name: Run tests
        run: pytest --cov=. --cov-report=xml
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
          flags: backend

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Build package
        run: |
          pip install build
          python -m build

      - name: Upload package
        uses: actions/upload-artifact@v3
        with:
          name: python-package
          path: dist/
```

**Go Backend (`.github/workflows/go-ci.yml`):**

```yaml
name: Go CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
          cache: true

      - name: Install dependencies
        run: go mod download

      - name: Run linting
        uses: golangci/golangci-lint-action@v3
        with:
          version: latest

      - name: Run tests
        run: go test -v -race -coverprofile=coverage.out ./...

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.out
          flags: backend

  build:
    needs: test
    runs-on: ubuntu-latest
    strategy:
      matrix:
        goos: [linux, darwin, windows]
        goarch: [amd64, arm64]
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Build
        run: |
          GOOS=${{ matrix.goos }} GOARCH=${{ matrix.goarch }} \
          go build -o bin/app-${{ matrix.goos }}-${{ matrix.goarch }} .

      - name: Upload binary
        uses: actions/upload-artifact@v3
        with:
          name: binaries
          path: bin/
```

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
