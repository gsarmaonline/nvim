---
name: envify
description: Generate .env.example from repository secrets and environment variables
---

You are being invoked via the /envify skill. Your task is to scan the repository for environment variables and secrets, then generate or update a `.env.example` file with appropriate documentation.

## Overview

This skill helps with environment configuration by:
1. Scanning the codebase for environment variable usage
2. Identifying secrets and sensitive configuration
3. Generating/updating `.env.example` with placeholders
4. Adding descriptions and grouping variables by category
5. Ensuring `.env` is in `.gitignore`
6. Providing setup documentation

## Steps to Execute

### 1. Verify .gitignore Protection

**CRITICAL SECURITY CHECK:**
Before starting, verify that `.env` and other secret files are in `.gitignore`:

```bash
# Check .gitignore
grep -E "^\.env$|^\.env\.local$|^\.env\..*$" .gitignore
```

If not present, add them:
```gitignore
# Environment variables
.env
.env.local
.env.*.local
.env.development.local
.env.test.local
.env.production.local

# Secrets
secrets.json
credentials.json
*.pem
*.key
*.cert
```

**Warn the user if `.env` exists and is not in `.gitignore`!**

### 2. Scan for Environment Variables

Search the entire codebase for environment variable references using multiple patterns:

#### Node.js/JavaScript/TypeScript
```bash
# Common patterns:
grep -r "process\.env\." --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx"
grep -r "import\.meta\.env\." --include="*.js" --include="*.ts"  # Vite
grep -r "Deno\.env\.get" --include="*.ts"  # Deno
```

Examples to find:
- `process.env.DATABASE_URL`
- `process.env.API_KEY`
- `import.meta.env.VITE_API_URL`

#### Python
```bash
grep -r "os\.environ" --include="*.py"
grep -r "os\.getenv" --include="*.py"
grep -r "getenv" --include="*.py"
```

Examples:
- `os.environ.get('DATABASE_URL')`
- `os.getenv('SECRET_KEY')`

#### Go
```bash
grep -r "os\.Getenv" --include="*.go"
```

Examples:
- `os.Getenv("DATABASE_URL")`

#### Ruby
```bash
grep -r "ENV\[" --include="*.rb"
```

Examples:
- `ENV['DATABASE_URL']`

#### PHP
```bash
grep -r "getenv\|\\$_ENV" --include="*.php"
```

Examples:
- `getenv('DATABASE_URL')`
- `$_ENV['API_KEY']`

#### Rust
```bash
grep -r "env::" --include="*.rs"
grep -r "std::env::var" --include="*.rs"
```

Examples:
- `std::env::var("DATABASE_URL")`

#### Shell Scripts
```bash
grep -r "\$\{[A-Z_]*\}" --include="*.sh" --include="*.bash"
```

Examples:
- `${DATABASE_URL}`

### 3. Check Configuration Files

Scan common config files that reference environment variables:

**Docker:**
- `Dockerfile`: Look for `ENV` and `ARG`
- `docker-compose.yml`: Check `environment:` sections

**CI/CD:**
- `.github/workflows/*.yml`: Check `env:` sections
- `.gitlab-ci.yml`
- `circle.yml`

**Framework-specific:**
- `next.config.js`: Check `env` config
- `.env.example` (existing): Use as reference
- `config/*.yml`: Rails config files
- `settings.py`: Django settings

### 3b. Detect Go + Next.js Project (Full-Stack Mode)

If the project has both `go.mod` and a `frontend/` directory (or a Next.js `package.json`), activate **full-stack mode**. In this mode, `/envify` does more than document — it also scaffolds Google OAuth and CORS code.

```bash
[ -f go.mod ] && echo "Go backend detected"
[ -f frontend/package.json ] || [ -f frontend/next.config.ts ] || [ -f frontend/next.config.js ] && echo "Next.js frontend detected"
```

If both are detected, proceed with Steps 3c through 3f before continuing to Step 4.

---

### 3c. Enforce Canonical Environment Variable Names

These names are **always used** in this project — no variations, no per-project invention. If the codebase already uses different names (e.g. `POSTGRES_URL` instead of `DATABASE_URL`), note the discrepancy and update the `.env.example` to use the canonical names.

**Canonical names:**

```bash
# Server
PORT=8080                              # backend port
APP_URL=http://localhost:3000          # frontend origin — used for CORS and OAuth redirect

# Database — always use the full URL form, not individual DB_HOST/DB_PORT vars
DATABASE_URL=postgres://postgres:postgres@localhost:5432/appname?sslmode=disable

# Auth
JWT_SECRET=                            # generate: openssl rand -base64 32
JWT_EXPIRY=24h                         # token expiry duration

# Google OAuth — always these exact names
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URL=http://localhost:8080/api/v1/auth/google/callback

# Frontend (Next.js — browser-accessible)
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

Do not use `REACT_APP_*`, `VITE_*`, or custom-prefixed names for these variables.

---

### 3d. Scaffold CORS Middleware (Go)

If Go backend is detected, create `internal/middleware/cors.go`:

```go
package middleware

import (
	"os"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// CORS returns a Gin middleware that restricts cross-origin requests to APP_URL.
// In development, APP_URL defaults to http://localhost:3000.
func CORS() gin.HandlerFunc {
	appURL := os.Getenv("APP_URL")
	if appURL == "" {
		appURL = "http://localhost:3000"
	}

	// Allow multiple origins if APP_URL is a comma-separated list
	origins := strings.Split(appURL, ",")
	for i, o := range origins {
		origins[i] = strings.TrimSpace(o)
	}

	cfg := cors.Config{
		AllowOrigins:     origins,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}

	return cors.New(cfg)
}
```

Add `github.com/gin-contrib/cors` to the module:

```bash
go get github.com/gin-contrib/cors
```

Register the middleware in `internal/server/server.go`, inside `New()`, before `registerRoutes()`:

```go
s.router.Use(middleware.CORS())
```

Add the import: `"<module>/internal/middleware"`

---

### 3e. Scaffold Google OAuth + JWT Auth (Go)

Create `internal/auth/oauth.go`:

```go
package auth

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

const oauthStateKey = "oauth_state"

func googleOAuthConfig() *oauth2.Config {
	return &oauth2.Config{
		ClientID:     os.Getenv("GOOGLE_CLIENT_ID"),
		ClientSecret: os.Getenv("GOOGLE_CLIENT_SECRET"),
		RedirectURL:  os.Getenv("GOOGLE_REDIRECT_URL"),
		Scopes:       []string{"openid", "email", "profile"},
		Endpoint:     google.Endpoint,
	}
}

// GoogleLogin redirects the user to the Google OAuth consent screen.
func GoogleLogin(c *gin.Context) {
	cfg := googleOAuthConfig()
	// Use a random state in production — this is a placeholder
	state := "random-state-replace-with-csrf-token"
	url := cfg.AuthCodeURL(state, oauth2.AccessTypeOnline)
	c.Redirect(http.StatusTemporaryRedirect, url)
}

// GoogleCallback handles the OAuth2 callback, exchanges the code for a token,
// fetches the user profile, issues a JWT, and redirects to the frontend.
func GoogleCallback(c *gin.Context) {
	cfg := googleOAuthConfig()

	code := c.Query("code")
	if code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing code"})
		return
	}

	token, err := cfg.Exchange(context.Background(), code)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "code exchange failed"})
		return
	}

	userInfo, err := fetchGoogleUserInfo(token.AccessToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch user info"})
		return
	}

	jwtToken, err := issueJWT(userInfo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to issue token"})
		return
	}

	appURL := os.Getenv("APP_URL")
	if appURL == "" {
		appURL = "http://localhost:3000"
	}
	c.Redirect(http.StatusTemporaryRedirect, fmt.Sprintf("%s/auth/callback?token=%s", appURL, jwtToken))
}

type googleUserInfo struct {
	Sub   string `json:"sub"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

func fetchGoogleUserInfo(accessToken string) (*googleUserInfo, error) {
	resp, err := http.Get("https://www.googleapis.com/oauth2/v3/userinfo?access_token=" + accessToken)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var info googleUserInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return nil, err
	}
	return &info, nil
}

func issueJWT(user *googleUserInfo) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return "", fmt.Errorf("JWT_SECRET is not set")
	}

	expiry := 24 * time.Hour
	if d := os.Getenv("JWT_EXPIRY"); d != "" {
		if parsed, err := time.ParseDuration(d); err == nil {
			expiry = parsed
		}
	}

	claims := jwt.MapClaims{
		"sub":   user.Sub,
		"email": user.Email,
		"name":  user.Name,
		"exp":   time.Now().Add(expiry).Unix(),
		"iat":   time.Now().Unix(),
	}

	t := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return t.SignedString([]byte(secret))
}
```

Create `internal/auth/middleware.go` — JWT validation for protected routes:

```go
package auth

import (
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// Required is a Gin middleware that validates the JWT in the Authorization header.
// Sets "userEmail" and "userID" (sub claim) in the Gin context for downstream handlers.
func Required(c *gin.Context) {
	header := c.GetHeader("Authorization")
	if !strings.HasPrefix(header, "Bearer ") {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
		return
	}

	tokenStr := strings.TrimPrefix(header, "Bearer ")
	secret := os.Getenv("JWT_SECRET")

	token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		return []byte(secret), nil
	})

	if err != nil || !token.Valid {
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok {
		c.Set("userEmail", claims["email"])
		c.Set("userID", claims["sub"])
	}

	c.Next()
}
```

Install required packages:

```bash
go get golang.org/x/oauth2
go get github.com/golang-jwt/jwt/v5
go mod tidy
```

Register auth routes in `internal/server/routes.go`, inside `registerRoutes()`:

```go
// Auth routes — no JWT middleware needed here
s.router.GET("/api/v1/auth/google", auth.GoogleLogin)
s.router.GET("/api/v1/auth/google/callback", auth.GoogleCallback)

// Example of a protected group:
// protected := s.router.Group("/api/v1", auth.Required)
// protected.GET("/me", handlers.Me)
```

Add import: `"<module>/internal/auth"`

Run `go build ./...` after scaffolding and fix any errors.

---

### 3f. Scaffold Google OAuth + JWT Auth (Next.js)

If a Next.js frontend is detected, create the following files in `frontend/`:

**`frontend/src/lib/auth.ts`** — auth utilities:

```typescript
const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";
const TOKEN_KEY = "jwt_token";

export const auth = {
  /** Redirect the browser to the backend Google OAuth entry point. */
  loginWithGoogle(): void {
    window.location.href = `${API_BASE}/api/v1/auth/google`;
  },

  /** Store the JWT received after OAuth callback. */
  setToken(token: string): void {
    localStorage.setItem(TOKEN_KEY, token);
  },

  getToken(): string | null {
    return typeof window !== "undefined"
      ? localStorage.getItem(TOKEN_KEY)
      : null;
  },

  logout(): void {
    localStorage.removeItem(TOKEN_KEY);
    window.location.href = "/login";
  },

  isAuthenticated(): boolean {
    const token = auth.getToken();
    if (!token) return false;
    try {
      // Decode (not verify — verification is server-side) to check expiry
      const payload = JSON.parse(atob(token.split(".")[1]));
      return payload.exp * 1000 > Date.now();
    } catch {
      return false;
    }
  },
};
```

**`frontend/src/app/login/page.tsx`** — login page:

```tsx
"use client";

import { auth } from "@/lib/auth";

export default function LoginPage() {
  return (
    <main className="flex min-h-screen items-center justify-center">
      <div className="flex flex-col items-center gap-6 p-8 rounded-xl border bg-card text-card-foreground shadow">
        <h1 className="text-2xl font-semibold">Sign in</h1>
        <button
          onClick={() => auth.loginWithGoogle()}
          className="flex items-center gap-3 px-6 py-3 rounded-lg border bg-white text-gray-800 font-medium hover:bg-gray-50 transition-colors"
        >
          <GoogleIcon />
          Continue with Google
        </button>
      </div>
    </main>
  );
}

function GoogleIcon() {
  return (
    <svg viewBox="0 0 24 24" className="w-5 h-5" aria-hidden="true">
      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" />
      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
    </svg>
  );
}
```

**`frontend/src/app/auth/callback/page.tsx`** — OAuth callback page that receives the JWT from the backend redirect:

```tsx
"use client";

import { useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { auth } from "@/lib/auth";

export default function AuthCallbackPage() {
  const router = useRouter();
  const params = useSearchParams();

  useEffect(() => {
    const token = params.get("token");
    if (token) {
      auth.setToken(token);
      router.replace("/");
    } else {
      router.replace("/login?error=auth_failed");
    }
  }, [params, router]);

  return (
    <main className="flex min-h-screen items-center justify-center">
      <p className="text-muted-foreground">Signing you in...</p>
    </main>
  );
}
```

**`frontend/src/middleware.ts`** — protect routes that require authentication:

```typescript
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

// Routes that do not require authentication
const PUBLIC_PATHS = ["/login", "/auth/callback"];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (PUBLIC_PATHS.some((p) => pathname.startsWith(p))) {
    return NextResponse.next();
  }

  // JWT is stored in localStorage (client-side only), so we rely on the
  // auth/callback page to set a cookie for server-side middleware checks.
  // For now, allow all server-side requests through and handle auth client-side.
  return NextResponse.next();
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico).*)"],
};
```

Update `frontend/src/lib/api.ts` to include the Authorization header on all requests:

```typescript
import { auth } from "./auth";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const token = auth.getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...init?.headers,
    },
    ...init,
  });
  if (res.status === 401) {
    auth.logout();
    throw new Error("Unauthorized");
  }
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

After scaffolding, run `cd frontend && npm run build` and fix any TypeScript errors.

---

### 4. Categorize Variables

Group discovered variables by category:

**Database:**
- `DATABASE_URL`
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `POSTGRES_*`, `MYSQL_*`, `MONGO_*`
- `REDIS_URL`

**Authentication/Security:**
- `JWT_SECRET`, `SESSION_SECRET`
- `ENCRYPTION_KEY`
- `BCRYPT_ROUNDS`
- `AUTH_SECRET`

**Third-party APIs:**
- `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`
- `SENDGRID_API_KEY`
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`
- `OPENAI_API_KEY`
- `GITHUB_TOKEN`

**Application:**
- `NODE_ENV`, `ENVIRONMENT`
- `PORT`, `HOST`
- `APP_NAME`, `APP_URL`
- `LOG_LEVEL`
- `DEBUG`

**Frontend (if applicable):**
- `VITE_*` (Vite)
- `REACT_APP_*` (Create React App)
- `NEXT_PUBLIC_*` (Next.js)
- `PUBLIC_*` (SvelteKit)

**Email:**
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`
- `MAIL_FROM`

**Storage:**
- `S3_BUCKET`, `S3_REGION`
- `CLOUDINARY_URL`

### 5. Detect Sensitive Patterns

Use regex to find potential secrets that might be hardcoded (security issue!):

```bash
# API keys
grep -rE "['\"]?[A-Z_]*API[_]?KEY['\"]?\s*[:=]" --include="*.js" --include="*.ts" --include="*.py"

# Tokens
grep -rE "['\"]?[A-Z_]*TOKEN['\"]?\s*[:=]" --include="*.js" --include="*.ts" --include="*.py"

# Passwords
grep -rE "['\"]?[A-Z_]*PASSWORD['\"]?\s*[:=]" --include="*.js" --include="*.ts" --include="*.py"

# Secrets
grep -rE "['\"]?[A-Z_]*SECRET['\"]?\s*[:=]" --include="*.js" --include="*.ts" --include="*.py"
```

**If hardcoded secrets are found, WARN the user immediately!**

### 6. Generate .env.example

Create or update `.env.example` with:
- All discovered environment variables
- Placeholder values (NEVER real secrets)
- Helpful comments explaining each variable
- Grouped by category
- Required vs optional indicators

**Example structure (canonical names — always use these exact var names for Go+Next.js projects):**

```bash
# .env.example
# Copy this file to .env and fill in your actual values.
# DO NOT commit .env to version control.

# =============================================================================
# Server
# =============================================================================

# Backend port
PORT=8080

# Frontend origin — used for CORS allowed origins and OAuth post-login redirect
# Must match the URL where the Next.js app is served
APP_URL=http://localhost:3000

# =============================================================================
# Database
# =============================================================================

# Full PostgreSQL connection URL — always use this form, not individual DB_* vars
# Format: postgres://user:password@host:port/dbname?sslmode=disable
DATABASE_URL=postgres://postgres:postgres@localhost:5432/appname?sslmode=disable

# =============================================================================
# Authentication
# =============================================================================

# JWT signing secret — generate with: openssl rand -base64 32
# SECURITY: Never reuse across environments. Rotating this logs out all users.
JWT_SECRET=

# JWT token expiry duration (Go time.ParseDuration format)
JWT_EXPIRY=24h

# =============================================================================
# Google OAuth
# =============================================================================
# Create credentials at: https://console.cloud.google.com/apis/credentials
# Authorised redirect URI must match GOOGLE_REDIRECT_URL exactly.

GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
# Must be registered in Google Cloud Console under "Authorised redirect URIs"
GOOGLE_REDIRECT_URL=http://localhost:8080/api/v1/auth/google/callback

# =============================================================================
# Frontend (Next.js — exposed to the browser)
# =============================================================================

# Backend API base URL — used by the Next.js API client
NEXT_PUBLIC_API_URL=http://localhost:8080

# Frontend app URL — used for absolute links and redirects
NEXT_PUBLIC_APP_URL=http://localhost:3000

# =============================================================================
# Optional
# =============================================================================

# Logging level (debug, info, warn, error)
LOG_LEVEL=info

# Rate limiting (requests per minute per IP, 0 = disabled)
RATE_LIMIT=100
```

### 7. Add Helpful Comments

For each variable, include:

**Required Information:**
- Description of what it's used for
- Format/example value
- Where to obtain it (for API keys)
- Security notes (if sensitive)

**Optional Information:**
- Default value (if applicable)
- Valid options (for enums)
- Links to documentation
- Generation commands (for secrets)

**Example:**
```bash
# JWT_SECRET - Secret key for signing JSON Web Tokens
# REQUIRED: Generate a secure random string
# Generate with: openssl rand -base64 32
# SECURITY: Keep this secret! Changing it will invalidate all existing tokens
JWT_SECRET=your-jwt-secret-here
```

### 8. Create Setup Documentation

Generate `docs/ENVIRONMENT_SETUP.md` with detailed setup instructions:

```markdown
# Environment Setup Guide

This guide explains how to set up environment variables for this project.

## Quick Start

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your actual values

3. **NEVER commit `.env` to version control!** (It's already in `.gitignore`)

## Required Variables

These variables are required for the application to run:

### DATABASE_URL
PostgreSQL connection string for the main database.

**Format:** `postgresql://user:password@host:port/database`

**Local Development:**
```bash
# Install PostgreSQL first, then create a database:
createdb myapp_dev

# Use this connection string:
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myapp_dev
```

**Production:**
Use your hosted database connection string (e.g., from Heroku, AWS RDS, etc.)

### JWT_SECRET
Secret key for signing authentication tokens.

**Generate a secure value:**
```bash
openssl rand -base64 32
```

**⚠️ Security Note:** Keep this secret! Changing it will log out all users.

## Optional Variables

These variables are optional but enable additional features:

### STRIPE_SECRET_KEY
Required only if using payment features. Get from [Stripe Dashboard](https://dashboard.stripe.com/apikeys).

### OPENAI_API_KEY
Required only if using AI features. Get from [OpenAI Platform](https://platform.openai.com/api-keys).

## Environment-Specific Setup

### Development
```bash
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug
```

### Production
```bash
NODE_ENV=production
DEBUG=false
LOG_LEVEL=warn
```

## Verifying Your Setup

Run this command to verify all required variables are set:
```bash
npm run env:check
# or
python scripts/check_env.py
```

## Common Issues

### "Missing environment variable: DATABASE_URL"
Make sure you've created a `.env` file and set the DATABASE_URL variable.

### "Invalid DATABASE_URL format"
Check that your connection string follows the format: `postgresql://user:password@host:port/database`

## Security Best Practices

1. **Never commit `.env` files** - They contain secrets!
2. **Use different values for each environment** - Don't reuse production secrets in development
3. **Rotate secrets regularly** - Especially API keys and tokens
4. **Use secret management** - Consider using services like AWS Secrets Manager or HashiCorp Vault for production
5. **Limit API key permissions** - Only grant the minimum required permissions

## CI/CD Setup

Add environment variables to your CI/CD platform:

**GitHub Actions:**
Go to Settings → Secrets and variables → Actions

**Vercel:**
Go to Project Settings → Environment Variables

**Heroku:**
```bash
heroku config:set DATABASE_URL=postgresql://...
```

## Getting Help

If you need help obtaining any API keys or setting up services:
1. Check the service's documentation (links provided in `.env.example`)
2. Ask the team for development credentials
3. See the main README for project-specific setup
```

### 9. Create Environment Validation Script

Generate a script to validate that all required environment variables are set:

**Node.js (`scripts/check-env.js`):**
```javascript
#!/usr/bin/env node

const requiredVars = [
  'DATABASE_URL',
  'JWT_SECRET',
  'SESSION_SECRET',
];

const optionalVars = [
  'STRIPE_SECRET_KEY',
  'OPENAI_API_KEY',
  'SENDGRID_API_KEY',
];

let hasErrors = false;

console.log('🔍 Checking environment variables...\n');

// Check required
requiredVars.forEach(varName => {
  if (!process.env[varName]) {
    console.error(`❌ Missing required variable: ${varName}`);
    hasErrors = true;
  } else {
    console.log(`✅ ${varName}`);
  }
});

// Check optional
console.log('\n📋 Optional variables:');
optionalVars.forEach(varName => {
  if (!process.env[varName]) {
    console.log(`⚠️  ${varName} (not set)`);
  } else {
    console.log(`✅ ${varName}`);
  }
});

if (hasErrors) {
  console.error('\n❌ Missing required environment variables!');
  console.error('Copy .env.example to .env and fill in the values.');
  process.exit(1);
}

console.log('\n✅ All required environment variables are set!');
```

**Python (`scripts/check_env.py`):**
```python
#!/usr/bin/env python3
import os
import sys

required_vars = [
    'DATABASE_URL',
    'JWT_SECRET',
    'SESSION_SECRET',
]

optional_vars = [
    'STRIPE_SECRET_KEY',
    'OPENAI_API_KEY',
    'SENDGRID_API_KEY',
]

has_errors = False

print('🔍 Checking environment variables...\n')

# Check required
for var in required_vars:
    if not os.getenv(var):
        print(f'❌ Missing required variable: {var}')
        has_errors = True
    else:
        print(f'✅ {var}')

# Check optional
print('\n📋 Optional variables:')
for var in optional_vars:
    if not os.getenv(var):
        print(f'⚠️  {var} (not set)')
    else:
        print(f'✅ {var}')

if has_errors:
    print('\n❌ Missing required environment variables!')
    print('Copy .env.example to .env and fill in the values.')
    sys.exit(1)

print('\n✅ All required environment variables are set!')
```

### 10. Update CLAUDE.md

Add environment variable management to CLAUDE.md:

```markdown
## Requirements

### Environment Variable Management

- Use the `/envify` skill to scan and update `.env.example` whenever new environment variables are added
- Before creating PRs that add new env vars, run `/envify` to update documentation
- Never commit actual secrets or `.env` files
- Always add helpful comments in `.env.example` explaining how to obtain values
- Include environment variable changes in PR descriptions
```

### 11. Add package.json Scripts (if Node.js)

```json
{
  "scripts": {
    "env:check": "node scripts/check-env.js",
    "env:example": "node scripts/generate-env-example.js"
  }
}
```

### 12. Security Warnings

If the scan detects any issues, warn the user:

**⚠️ Hardcoded secrets found:**
```
WARNING: Found potential hardcoded secrets in:
  - src/config/api.ts:12 - API_KEY appears to be hardcoded
  - src/utils/db.ts:45 - PASSWORD appears to be hardcoded

RECOMMENDATION: Move these to environment variables immediately!
```

**⚠️ .env not in .gitignore:**
```
CRITICAL: .env file exists but is NOT in .gitignore!
This is a security risk - secrets could be committed to git.

FIXING NOW: Adding .env to .gitignore
```

**⚠️ .env committed to git:**
```
CRITICAL: .env file found in git history!
Your secrets may have been exposed.

RECOMMENDED ACTIONS:
1. Rotate all secrets immediately
2. Remove .env from git history:
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" \
     --prune-empty --tag-name-filter cat -- --all
3. Force push (coordinate with team first!)
```

### 13. Report Summary

After completion, show:
- ✅ Environment variables discovered: X variables across Y categories
- 📁 Generated/updated: `.env.example`
- 📄 Created: `docs/ENVIRONMENT_SETUP.md`
- 🔧 Created validation script: `scripts/check-env.js` (or `.py`)
- 🔒 Verified: `.env` in `.gitignore`
- ⚠️  Warnings: X issues found (if any)
- 💡 Next steps: Copy `.env.example` to `.env` and fill in actual values

## Important Security Notes

- **NEVER** include actual secret values in `.env.example`
- **ALWAYS** use placeholder values like `your_api_key_here`
- **VERIFY** that `.env` is in `.gitignore` before scanning
- **WARN** users if hardcoded secrets are detected
- **CHECK** git history for accidentally committed `.env` files
- **RECOMMEND** secret rotation if `.env` was ever committed

## Example Usage

```bash
# User invokes
/envify

# Skill responds
🔍 Scanning repository for environment variables...

✓ Found 32 environment variables across 6 categories:
  - Database: 5 variables
  - Authentication: 4 variables
  - Third-party APIs: 15 variables
  - Application: 6 variables
  - Email: 2 variables

🔒 Security check:
  ✓ .env is in .gitignore
  ✓ No .env file in git history
  ⚠️  Found 2 potential hardcoded secrets (see warnings below)

📝 Generated/updated files:
  ✓ .env.example (32 variables with descriptions)
  ✓ docs/ENVIRONMENT_SETUP.md (setup guide)
  ✓ scripts/check-env.js (validation script)

⚠️  WARNINGS:
  - src/config/stripe.ts:12 - STRIPE_KEY appears to be hardcoded
  - Recommendation: Move to environment variable

Next steps:
1. Review .env.example
2. Copy to .env: cp .env.example .env
3. Fill in your actual secret values
4. Run validation: npm run env:check
5. Fix hardcoded secrets (see warnings)
```

Execute these steps to generate comprehensive environment variable documentation.
