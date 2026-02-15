---
name: apify
description: Generate comprehensive API documentation from route definitions and types
---

You are being invoked via the /apify skill. Your task is to automatically extract and document all API routes, methods, and request/response types from a backend application.

## Overview

This skill helps with API documentation by:
1. Detecting backend frameworks and languages
2. Extracting all route definitions and HTTP methods
3. Inferring request/response types from code
4. Generating comprehensive API documentation
5. Creating OpenAPI/Swagger specs
6. Keeping documentation in sync with code

## Steps to Execute

### 1. Detect Backend Application

Check if this is a backend/API app by looking for:

**Node.js/TypeScript:**
- Express.js (`express` in package.json)
- Fastify (`fastify` in package.json)
- NestJS (`@nestjs/core` in package.json)
- Koa (`koa` in package.json)
- Hono (`hono` in package.json)

**Python:**
- FastAPI (`fastapi` in requirements.txt or pyproject.toml)
- Flask (`flask` in requirements.txt)
- Django (`django` in requirements.txt)

**Go:**
- Gin (`github.com/gin-gonic/gin` in go.mod)
- Echo (`github.com/labstack/echo` in go.mod)
- Chi (`github.com/go-chi/chi` in go.mod)
- Fiber (`github.com/gofiber/fiber` in go.mod)

**Rust:**
- Actix (`actix-web` in Cargo.toml)
- Axum (`axum` in Cargo.toml)
- Rocket (`rocket` in Cargo.toml)

**Other:**
- Ruby on Rails (Gemfile with `rails`)
- ASP.NET Core (`.csproj` with ASP.NET packages)
- Spring Boot (`pom.xml` or `build.gradle` with Spring)

If not a backend app, inform the user and exit.

### 2. Analyze Project Structure

Identify the framework and locate route definitions:

**Express.js:**
```javascript
// Look for patterns like:
app.get('/users', ...)
app.post('/users', ...)
router.get('/products/:id', ...)
```

**Fastify:**
```javascript
fastify.get('/users', ...)
fastify.post('/users', { schema: {...} }, ...)
```

**NestJS:**
```typescript
@Controller('users')
@Get(':id')
@Post()
```

**FastAPI:**
```python
@app.get("/users")
@app.post("/users", response_model=User)
```

**Flask:**
```python
@app.route('/users', methods=['GET', 'POST'])
```

**Django:**
```python
# urls.py
path('users/', views.users_list)
```

**Go (Gin):**
```go
r.GET("/users", getUsers)
r.POST("/users", createUser)
```

### 3. Extract Route Information

For each route, extract:
- **Path**: `/api/users/:id`
- **Method**: GET, POST, PUT, DELETE, PATCH, etc.
- **Handler function name**: `getUserById`, `createUser`, etc.
- **File location**: `src/controllers/user.controller.ts:45`
- **Middleware/Guards**: Authentication, rate limiting, etc.
- **Query parameters**: From handler code or type definitions
- **Path parameters**: `:id`, `:slug`, etc.
- **Request body type**: Inferred from TypeScript/Python types, JSDoc, or validation schemas
- **Response type**: Inferred from return statements, type annotations, or schemas
- **Status codes**: 200, 201, 400, 404, etc.
- **Description**: From comments or docstrings

### 4. Infer Types from Code

**TypeScript:**
```typescript
interface CreateUserDto {
  name: string;
  email: string;
  age?: number;
}

// Route handler
async createUser(req: Request<{}, {}, CreateUserDto>): Promise<User> {
  // Extract CreateUserDto as request type
  // Extract User as response type
}
```

**Python (FastAPI):**
```python
class UserCreate(BaseModel):
    name: str
    email: str
    age: Optional[int] = None

@app.post("/users", response_model=User)
async def create_user(user: UserCreate):
    # UserCreate is request type
    # User is response type
```

**Go:**
```go
type CreateUserRequest struct {
    Name  string `json:"name" binding:"required"`
    Email string `json:"email" binding:"required"`
}

func createUser(c *gin.Context) {
    var req CreateUserRequest
    // Infer from struct
}
```

**Validation Schemas (Zod, Joi, etc.):**
```typescript
const createUserSchema = z.object({
  name: z.string(),
  email: z.string().email(),
  age: z.number().optional(),
});
```

### 5. Generate API Documentation

Create comprehensive documentation in multiple formats:

#### A. Markdown Documentation (`docs/API.md`)

```markdown
# API Documentation

## User Management

### GET /api/users
Get all users

**Query Parameters:**
- `page` (number, optional): Page number (default: 1)
- `limit` (number, optional): Items per page (default: 20)
- `search` (string, optional): Search by name or email

**Response:** `200 OK`
```json
{
  "users": [
    {
      "id": "string",
      "name": "string",
      "email": "string",
      "createdAt": "string (ISO 8601)"
    }
  ],
  "total": "number",
  "page": "number"
}
```

**Error Responses:**
- `500 Internal Server Error`: Server error

---

### POST /api/users
Create a new user

**Request Body:**
```json
{
  "name": "string (required)",
  "email": "string (required, email format)",
  "age": "number (optional)"
}
```

**Response:** `201 Created`
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "age": "number",
  "createdAt": "string (ISO 8601)"
}
```

**Error Responses:**
- `400 Bad Request`: Validation error
- `409 Conflict`: Email already exists
- `500 Internal Server Error`: Server error

---

### GET /api/users/:id
Get a specific user by ID

**Path Parameters:**
- `id` (string, required): User ID

**Response:** `200 OK`
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "age": "number",
  "createdAt": "string (ISO 8601)"
}
```

**Error Responses:**
- `404 Not Found`: User not found
- `500 Internal Server Error`: Server error
```

#### B. OpenAPI/Swagger Spec (`docs/openapi.json` or `docs/openapi.yaml`)

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "API Documentation",
    "version": "1.0.0",
    "description": "Auto-generated API documentation"
  },
  "servers": [
    {
      "url": "http://localhost:3000/api",
      "description": "Development server"
    }
  ],
  "paths": {
    "/users": {
      "get": {
        "summary": "Get all users",
        "operationId": "getUsers",
        "parameters": [
          {
            "name": "page",
            "in": "query",
            "schema": { "type": "integer", "default": 1 }
          },
          {
            "name": "limit",
            "in": "query",
            "schema": { "type": "integer", "default": 20 }
          }
        ],
        "responses": {
          "200": {
            "description": "Success",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/UserListResponse"
                }
              }
            }
          }
        }
      },
      "post": {
        "summary": "Create a new user",
        "operationId": "createUser",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "$ref": "#/components/schemas/CreateUserDto"
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Created",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/User"
                }
              }
            }
          }
        }
      }
    }
  },
  "components": {
    "schemas": {
      "User": {
        "type": "object",
        "properties": {
          "id": { "type": "string" },
          "name": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "age": { "type": "integer" },
          "createdAt": { "type": "string", "format": "date-time" }
        },
        "required": ["id", "name", "email"]
      },
      "CreateUserDto": {
        "type": "object",
        "properties": {
          "name": { "type": "string" },
          "email": { "type": "string", "format": "email" },
          "age": { "type": "integer" }
        },
        "required": ["name", "email"]
      }
    }
  }
}
```

#### C. Postman Collection (`docs/postman_collection.json`)

Generate importable Postman collection with all endpoints and example requests.

#### D. cURL Examples (`docs/API_EXAMPLES.md`)

```markdown
# API Usage Examples

## Create a user
```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "age": 30
  }'
```

## Get all users
```bash
curl http://localhost:3000/api/users?page=1&limit=10
```

## Get user by ID
```bash
curl http://localhost:3000/api/users/123
```
```

### 6. Create Documentation Scripts

Generate scripts for updating documentation:

**`scripts/generate-api-docs.js` (or `.ts`):**
```javascript
// Auto-generate docs from route definitions
// Use tools like:
// - swagger-jsdoc (extract from JSDoc comments)
// - tsoa (TypeScript OpenAPI)
// - fastapi's built-in OpenAPI generation
// - Custom route parser

const fs = require('fs');
const path = require('path');

// Scan routes
// Extract types
// Generate OpenAPI spec
// Generate markdown docs
// Generate Postman collection

console.log('✓ API documentation generated');
console.log('  - docs/API.md');
console.log('  - docs/openapi.json');
console.log('  - docs/postman_collection.json');
```

### 7. Set Up Documentation Tools

Based on the framework, install appropriate tools:

**TypeScript/Node.js:**
```bash
npm install -D swagger-jsdoc swagger-ui-express
# OR for automatic generation:
npm install -D tsoa
npm install -D @nestjs/swagger  # For NestJS
```

**Python:**
```bash
# FastAPI has built-in OpenAPI
# Access at /docs (Swagger UI) and /redoc

# For Flask:
pip install flask-swagger-ui flasgger
```

**Go:**
```bash
# Install swag for Swagger generation
go install github.com/swaggo/swag/cmd/swag@latest
swag init
```

### 8. Add Documentation Route

Set up a route to serve the documentation:

**Express/Fastify:**
```javascript
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./docs/openapi.json');

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
```

**FastAPI:**
```python
# Built-in at /docs and /redoc
# No setup needed!
```

**NestJS:**
```typescript
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

const config = new DocumentBuilder()
  .setTitle('API Documentation')
  .setVersion('1.0')
  .build();
const document = SwaggerModule.createDocument(app, config);
SwaggerModule.setup('api-docs', app, document);
```

### 9. Update CLAUDE.md

Add API documentation workflow to CLAUDE.md:

```markdown
## Requirements

### API Documentation

- Whenever backend routes change (new endpoints, modified types), automatically update API documentation
- Before creating PRs with API changes, run `/apify` to regenerate documentation
- Include API changes summary in PR descriptions
- Keep OpenAPI spec in sync with code
- Document all request/response types, status codes, and error responses

## Commands and Tools

### API Documentation Commands (Auto-approved)
- `npm run api-docs` - Generate/update API documentation
- `npm run api-docs:serve` - Start documentation server locally
- These commands should be run automatically when API routes or types are modified
```

### 10. Generate Summary Report

Create a summary file `docs/API_SUMMARY.md`:

```markdown
# API Summary

**Last Updated:** 2026-02-15
**Total Endpoints:** 24

## Endpoints by Category

### User Management (8 endpoints)
- `GET /api/users` - List all users
- `POST /api/users` - Create user
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user
- `POST /api/users/:id/avatar` - Upload avatar
- `GET /api/users/:id/posts` - Get user posts
- `POST /api/users/:id/follow` - Follow user

### Posts (6 endpoints)
- `GET /api/posts` - List all posts
- `POST /api/posts` - Create post
- `GET /api/posts/:id` - Get post by ID
- `PUT /api/posts/:id` - Update post
- `DELETE /api/posts/:id` - Delete post
- `POST /api/posts/:id/like` - Like post

### Authentication (3 endpoints)
- `POST /api/auth/login` - Login
- `POST /api/auth/register` - Register
- `POST /api/auth/refresh` - Refresh token

## Type Definitions

**User:**
- id: string
- name: string
- email: string
- age?: number
- createdAt: Date

**Post:**
- id: string
- title: string
- content: string
- authorId: string
- createdAt: Date
- updatedAt: Date

## Authentication

Most endpoints require Bearer token authentication:
```
Authorization: Bearer <token>
```

## Rate Limiting

- 100 requests per minute per IP
- 1000 requests per hour per authenticated user
```

### 11. Integrate with PR Workflow

When creating PRs (in `/ship` skill), automatically:
1. Detect if backend/API files changed
2. Run `/apify` to regenerate documentation
3. Compare with previous API spec
4. Add API changes section to PR body:

```markdown
## 🔌 API Changes

### New Endpoints
- `POST /api/users/:id/follow` - Follow a user
- `DELETE /api/users/:id/follow` - Unfollow a user

### Modified Endpoints
- `GET /api/users` - Added `search` query parameter

### Removed Endpoints
- None

### Type Changes
- `User` - Added optional `bio: string` field
- `CreateUserDto` - Email validation now required

### Documentation
- 📄 [View full API docs](./docs/API.md)
- 🔍 [OpenAPI Spec](./docs/openapi.json)
- 📮 [Postman Collection](./docs/postman_collection.json)
```

### 12. Report Summary

After completion, show:
- ✅ API routes discovered: X endpoints across Y categories
- 📁 Documentation saved to: `docs/` directory
- 📝 Updated CLAUDE.md with API documentation workflow
- 🔧 Added npm scripts: `npm run api-docs`
- 🌐 Documentation server: `npm run api-docs:serve`
- 💡 Next steps: Access docs at http://localhost:3000/api-docs

## Important Notes

- **Type Safety**: Prioritize frameworks with strong typing (TypeScript, FastAPI, etc.)
- **Validation**: Document validation rules from schemas (Zod, Joi, Pydantic)
- **Authentication**: Document auth requirements clearly
- **Versioning**: Support API versioning (v1, v2, etc.)
- **Deprecation**: Mark deprecated endpoints clearly
- **Examples**: Include realistic request/response examples
- **Error Codes**: Document all possible error responses
- **Rate Limits**: Document rate limiting if present
- **Webhooks**: Document webhook endpoints if present

## Framework-Specific Features

### FastAPI
- Use built-in `/docs` (Swagger UI) and `/redoc` (ReDoc)
- Leverage Pydantic models for automatic schema generation
- Use `response_model` for response typing

### NestJS
- Use `@nestjs/swagger` decorators
- `@ApiTags()`, `@ApiOperation()`, `@ApiResponse()`
- Automatic DTO validation documentation

### Express + TypeScript
- Use `tsoa` for automatic OpenAPI generation from TypeScript
- Or use `swagger-jsdoc` with JSDoc comments

### Go
- Use `swag` comments above handlers
- Generate with `swag init`

## Example Usage

```bash
# User invokes
/apify

# Skill responds
✓ Detected Express.js (TypeScript) backend
✓ Found 24 API endpoints across 5 controllers
✓ Extracted TypeScript types and DTOs
✓ Generated documentation:
  - docs/API.md (Markdown)
  - docs/openapi.json (OpenAPI 3.0)
  - docs/postman_collection.json (Postman)
  - docs/API_EXAMPLES.md (cURL examples)
  - docs/API_SUMMARY.md (Overview)
✓ Installed swagger-ui-express
✓ Added /api-docs route
✓ Updated CLAUDE.md with API docs workflow
✓ Added npm scripts

Documentation server: http://localhost:3000/api-docs

Next steps:
- Review generated docs in docs/ directory
- Run `npm run api-docs` after API changes
- Include API changes in PR descriptions
```

Execute these steps to set up comprehensive API documentation generation.
