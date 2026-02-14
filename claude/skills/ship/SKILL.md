---
name: ship
description: Commit changes and push to remote, creating a PR if on feature branch
---

You are being invoked via the /ship skill. Your task is to:

1. Check the current branch name using `git branch --show-current`
2. Run git status and git diff to understand all changes (never use -uall flag)
3. Run git log to see recent commit messages and follow the repository's commit style
4. Analyze all changes and create a clear, concise commit message that:
   - Accurately describes what was changed and why
   - Follows the repository's commit message conventions
   - Includes: Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
5. Stage relevant files and commit the changes using a HEREDOC for the commit message
6. Push the changes to the remote repository
7. **Branch-specific behavior**:
   - **If on `main` or `master` branch**: Stop here, inform the user that changes were pushed directly to the main branch
   - **If on any other branch**: Create a pull request using gh pr create with:
     - A clear, concise title (under 70 characters)
     - A detailed description/body with:
       - ## Summary section with 1-3 bullet points
       - ## Test plan section with a checklist
       - Footer: 🤖 Generated with [Claude Code](https://claude.com/claude-code)
     - Use a HEREDOC to pass the body for correct formatting
     - Return the PR URL when done

IMPORTANT:
- Do NOT commit files that likely contain secrets (.env, credentials, etc)
- If there are no changes to commit, inform the user
- Do NOT use --no-verify or skip hooks unless explicitly requested
- Follow git safety protocols: never force push to main/master

Execute all steps in sequence to ship the changes.
