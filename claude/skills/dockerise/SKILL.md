---
name: dockerise
description: Create Dockerfile(s) for a project and optionally add to docker-compose.yml
---

You are being invoked via the /dockerise skill. Your task is to create appropriate Dockerfile(s) for the current project.

## Steps:

1. **Analyze the current directory structure**:
   - Use Glob and Read tools to explore the folder contents
   - Identify the project type(s): Node.js, Python, Go, Java, Ruby, etc.
   - Look for:
     - Package managers (package.json, requirements.txt, go.mod, pom.xml, Gemfile, etc.)
     - Application entry points (main.py, app.py, index.js, server.js, main.go, etc.)
     - Build tools (Makefile, webpack.config.js, tsconfig.json, etc.)
     - Existing Docker files (Dockerfile, .dockerignore, docker-compose.yml)

2. **Detect multiple services**:
   - Check if the project contains multiple distinct services/applications
   - Examples: frontend + backend, multiple microservices, web + worker + scheduler
   - If multiple services are detected, use AskUserQuestion to ask:
     - "I detected multiple services in this project. Would you like:"
       - Option 1: "Single Dockerfile with multi-stage build"
       - Option 2: "Separate Dockerfiles for each service"
       - Option 3: "Show me what you found first"

3. **Create Dockerfile(s)**:
   - Generate production-ready Dockerfile(s) with:
     - Appropriate base image for the detected language/framework
     - Multi-stage builds when appropriate (for smaller image size)
     - Security best practices (non-root user, minimal layers, etc.)
     - Proper dependency installation
     - Appropriate EXPOSE directives for ports
     - Health checks where applicable
     - Environment variable support
   - Create .dockerignore file if it doesn't exist (include node_modules, .git, etc.)
   - For multiple Dockerfiles, use descriptive names (e.g., Dockerfile.frontend, Dockerfile.backend)

4. **Handle docker-compose.yml**:
   - Check if docker-compose.yml exists in the current directory
   - **If docker-compose.yml exists**:
     - Read the existing file
     - Add the new service(s) to it with:
       - Appropriate service names
       - Build context and dockerfile references
       - Port mappings
       - Environment variables (with placeholder values)
       - Volume mounts where appropriate
       - Dependencies between services (depends_on)
       - Network configuration if needed
     - Preserve existing services and configuration
   - **If docker-compose.yml does NOT exist**:
     - Use AskUserQuestion to ask if they want to create one:
       - "Would you like me to create a docker-compose.yml file for this project?"
       - Options: "Yes, create docker-compose.yml" or "No, just create Dockerfile(s)"
     - If yes, create a complete docker-compose.yml with the new service(s)

5. **Summary**:
   - List all files created or modified
   - Provide basic usage instructions:
     - How to build: `docker build -t <name> .` or `docker-compose build`
     - How to run: `docker run <name>` or `docker-compose up`
   - Mention any environment variables that need to be configured

## Important Notes:

- Always create production-ready, secure Dockerfiles
- Use official base images from Docker Hub
- Optimize for image size (use alpine variants when appropriate)
- Include proper error handling and logging
- Don't hardcode sensitive values (use environment variables)
- Add helpful comments in Dockerfiles
- Consider the project's specific needs (dev dependencies, build steps, etc.)
- If uncertain about project structure, ask the user for clarification

Execute these steps to dockerise the project effectively.
