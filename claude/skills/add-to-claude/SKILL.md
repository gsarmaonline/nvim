---
name: add-to-claude
description: Add context or requirements to CLAUDE.md file in the repository
---

You are being invoked via the /add-to-claude skill. Your task is to add information to the CLAUDE.md file in the repository.

## Workflow:

1. **Check for CLAUDE.md**: Read the CLAUDE.md file if it exists, otherwise create it with a proper header
2. **Parse user input**: The user will provide information after the command (e.g., "/add-to-claude should run puppeteer")
3. **Add the information**: Append the user's information to CLAUDE.md in a clear, organized format
4. **Confirm**: Let the user know what was added

## File Format:

If CLAUDE.md doesn't exist, create it with this structure:
```markdown
# Project Context for Claude

This file contains important context and requirements for this project.

## Requirements

[Add requirements here]

## Commands and Tools

[Add commands/tools here]

## Notes

[Add other notes here]
```

## Adding Information:

- Parse the user's input to understand what type of information they're adding
- Add it under the appropriate section
- If it's about running commands/tools, add to "Commands and Tools"
- If it's about requirements or dependencies, add to "Requirements"
- If it's general context, add to "Notes"
- Use bullet points for clarity
- Don't duplicate existing information

## Examples:

User: `/add-to-claude should run puppeteer`
Action: Add "- Should run puppeteer" under "Commands and Tools"

User: `/add-to-claude requires Node.js 18+`
Action: Add "- Requires Node.js 18+" under "Requirements"

User: `/add-to-claude this is a vim configuration repo`
Action: Add "- This is a vim configuration repo" under "Notes"

IMPORTANT:
- Always read CLAUDE.md first if it exists
- Don't remove or modify existing content unless it's a duplicate
- Keep formatting clean and consistent
- Confirm what was added to the user
