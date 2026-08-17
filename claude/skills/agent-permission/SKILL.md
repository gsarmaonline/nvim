---
name: agent-permission
description: Add a bash command to auto-approved permissions in settings.json. Use when the user says stop asking me to approve X, always allow X, or is repeatedly prompted for permission to run the same command.
---

You are being invoked via the /agent-permission skill. Your task is to add a bash command to the auto-approved permissions list so Claude doesn't need to ask for permission to run it.

## Workflow:

1. **Parse the command**: Extract the command name from the user's input after `/agent-permission`
   - Example: `/agent-permission ls` → command is "ls"
   - Example: `/agent-permission tree` → command is "tree"

2. **Read settings.json**: Read the settings file at `/Users/gsarma/work/nvim/claude/settings.local.json`

3. **Check if already exists**: Verify if the command is already in the permissions.allow array

4. **Add the command**: If not present, add it to the permissions.allow array in the format:
   - `Bash(<command> *)` for commands with arguments (e.g., `Bash(tree *)`)
   - `Bash(<command>)` for commands without arguments (e.g., `Bash(pwd)`)
   - Use the wildcard format by default unless the command clearly never takes arguments

5. **Write back**: Save the updated settings.json file

6. **Confirm**: Let the user know the command was added and that it will now be auto-approved

## JSON Format:

The settings.json has this structure:
```json
{
  "permissions": {
    "allow": [
      "Bash(command *)",
      ...
    ]
  }
}
```

## Examples:

User: `/agent-permission ls`
Action: Add `"Bash(ls *)"` to the permissions.allow array

User: `/agent-permission tree`
Action: Add `"Bash(tree *)"` to the permissions.allow array

User: `/agent-permission pwd`
Action: Add `"Bash(pwd)"` (no wildcard for commands that don't take arguments)

## Important Notes:

- Maintain proper JSON formatting with correct indentation
- Keep the array sorted alphabetically for easy maintenance
- Don't add duplicates - check first
- Preserve all existing entries
- The file must remain valid JSON

Execute all steps to add the command to the auto-approved list.
