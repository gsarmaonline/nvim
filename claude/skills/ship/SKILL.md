---
name: ship
description: Commit changes, push to remote, and create a pull request
---

You are being invoked via the /ship skill. Your task is to:

1. Run git status and git diff to understand all changes (never use -uall flag)
2. Run git log to see recent commit messages and follow the repository's commit style
3. Analyze all changes and create a clear, concise commit message that:
   - Accurately describes what was changed and why
   - Follows the repository's commit message conventions
   - Includes: Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
4. Stage relevant files and commit the changes using a HEREDOC for the commit message
5. Push the changes to the remote repository
6. Create a pull request using gh pr create with:
   - A clear, concise title (under 70 characters)
   - A detailed description/body with:
     - ## Summary section with 1-3 bullet points
     - ## Test plan section with a checklist
     - Footer: 🤖 Generated with [Claude Code](https://claude.com/claude-code)
   - Use a HEREDOC to pass the body for correct formatting

IMPORTANT:
- Do NOT commit files that likely contain secrets (.env, credentials, etc)
- If there are no changes to commit, inform the user
- Return the PR URL when done
- Do NOT use --no-verify or skip hooks unless explicitly requested
- Follow git safety protocols: never force push to main/master

Execute all steps in sequence to ship the changes.
