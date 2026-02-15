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

**Example structure:**

```bash
# .env.example
# Copy this file to .env and fill in your actual values
# DO NOT commit .env to version control!

# =============================================================================
# Application Configuration
# =============================================================================

# Environment (development, staging, production)
NODE_ENV=development

# Application port
PORT=3000

# Application URL (include protocol)
APP_URL=http://localhost:3000

# =============================================================================
# Database Configuration
# =============================================================================

# PostgreSQL connection string
# Format: postgresql://user:password@host:port/database
DATABASE_URL=postgresql://user:password@localhost:5432/myapp_dev

# Alternative: separate database credentials
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=myapp_dev
# DB_USER=postgres
# DB_PASSWORD=your_password_here

# Redis URL (for caching/sessions)
REDIS_URL=redis://localhost:6379

# =============================================================================
# Authentication & Security
# =============================================================================

# JWT secret key (generate with: openssl rand -base64 32)
JWT_SECRET=your-super-secret-jwt-key-change-this

# Session secret (generate with: openssl rand -base64 32)
SESSION_SECRET=your-session-secret-change-this

# Bcrypt rounds (10-12 recommended)
BCRYPT_ROUNDS=10

# =============================================================================
# Third-party API Keys
# =============================================================================

# Stripe (payment processing)
# Get your keys from: https://dashboard.stripe.com/apikeys
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key

# AWS S3 (file storage)
# Create IAM user at: https://console.aws.amazon.com/iam/
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
AWS_REGION=us-east-1
S3_BUCKET=your-bucket-name

# SendGrid (email service)
# Get API key from: https://app.sendgrid.com/settings/api_keys
SENDGRID_API_KEY=SG.your_sendgrid_api_key

# OpenAI API
# Get key from: https://platform.openai.com/api-keys
OPENAI_API_KEY=sk-your_openai_api_key

# =============================================================================
# OAuth Configuration
# =============================================================================

# Google OAuth
# Create credentials at: https://console.cloud.google.com/apis/credentials
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# GitHub OAuth
# Create app at: https://github.com/settings/developers
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# =============================================================================
# Email Configuration
# =============================================================================

# SMTP server settings
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password

# From email address
MAIL_FROM=noreply@example.com

# =============================================================================
# Frontend Environment Variables
# =============================================================================
# Note: Variables prefixed with NEXT_PUBLIC_ are exposed to the browser

# API endpoint for frontend
NEXT_PUBLIC_API_URL=http://localhost:3000/api

# Google Analytics ID (optional)
NEXT_PUBLIC_GA_ID=UA-XXXXXXXXX-X

# =============================================================================
# Optional Configuration
# =============================================================================

# Logging level (debug, info, warn, error)
LOG_LEVEL=info

# Enable debug mode (true/false)
DEBUG=false

# Rate limiting (requests per minute)
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
