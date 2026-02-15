# Project Context for Claude

This file contains important context and requirements for this project.

## Requirements

### Visual Testing for Frontend Apps

- When working on frontend applications, use the `/screenshotify` skill to set up automated screenshot capture
- Whenever frontend code changes (components, pages, styles, layouts), automatically capture updated screenshots
- Before creating PRs with frontend changes, run screenshot capture to document visual changes
- Include screenshot comparisons in PR descriptions showing before/after visual changes
- Screenshots should be organized by page and viewport size (desktop, tablet, mobile)

### API Documentation for Backend Apps

- When working on backend/API applications, use the `/apify` skill to set up automated API documentation
- Whenever API routes change (new endpoints, modified types, changed methods), automatically regenerate documentation
- Before creating PRs with API changes, run documentation generation to keep docs in sync
- Include API changes summary in PR descriptions (new/modified/removed endpoints, type changes)
- Generate OpenAPI/Swagger specs, Markdown docs, and Postman collections

## Commands and Tools

### Frontend Screenshot Commands (Auto-approved)
- `npm run screenshots` - Capture screenshots of all pages after frontend changes
- `npm run screenshots:compare` - Compare current screenshots with previous version
- These commands should be run automatically when frontend files are modified before creating PRs

### API Documentation Commands (Auto-approved)
- `npm run api-docs` - Generate/update API documentation from route definitions
- `npm run api-docs:serve` - Start local documentation server
- These commands should be run automatically when API routes or types are modified before creating PRs

## Notes

- This repository contains Claude Code configuration that is symlinked to the actual `~/.claude` folder
- The `claude/` directory in this repo stores:
  - `settings.local.json` - Claude settings configuration
  - `skills/` - Custom Claude skills
- Symlinks from `~/.claude/` point to this repository:
  - `~/.claude/settings.json` -> `/Users/gsarma/work/nvim/claude/settings.local.json`
  - `~/.claude/skills` -> `/Users/gsarma/work/nvim/claude/skills`
- This allows Claude configuration to be version controlled alongside the nvim configuration
