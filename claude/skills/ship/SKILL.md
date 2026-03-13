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
5. **Update README if feasible**: Before staging, check if a README exists (README.md, README.rst, etc.) and if the changes warrant documentation updates:
   - New features, commands, skills, or tools added → update relevant sections or add new ones
   - Removed or renamed features → remove/update outdated references
   - Changed configuration, setup steps, or usage instructions → reflect those changes
   - Pure internal refactors, bug fixes, or test changes → skip README update
   - If updating, keep changes minimal and accurate — only document what actually changed
6. Stage relevant files (including updated README if modified) and commit the changes using a HEREDOC for the commit message
7. **Before pushing, check for and resolve merge conflicts**:

   a. Fetch the latest remote state without merging:
   ```bash
   git fetch origin
   ```

   b. Check whether the local branch is behind the remote:
   ```bash
   git status
   # or: git rev-list --count HEAD..origin/<branch>
   ```

   c. If the remote has new commits (local branch is behind):
   - Attempt a rebase onto the remote branch:
     ```bash
     git rebase origin/<branch>
     ```
   - If the rebase succeeds with no conflicts, continue to push.
   - If there are rebase conflicts:
     1. Read every conflicted file using the Read tool
     2. Resolve each conflict by choosing the correct lines (keep both sets of changes unless they are logically contradictory)
     3. Stage the resolved files: `git add <file>`
     4. Continue the rebase: `git rebase --continue`
     5. Repeat until the rebase completes
   - If the conflict cannot be safely resolved automatically (e.g. both sides deleted the same function, or there are semantic conflicts requiring human judgement), abort the rebase with `git rebase --abort`, explain the conflict to the user, and stop without pushing.

   d. Only push once the working tree is clean and the rebase is complete.

8. Push the changes to the remote repository
9. **Branch-specific behavior**:
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
- Do NOT use em dashes (—) in commit messages or PR descriptions. Use commas, colons, or restructure the sentence instead.

Execute all steps in sequence to ship the changes.
