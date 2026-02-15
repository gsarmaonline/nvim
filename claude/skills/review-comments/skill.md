---
name: review-comments
description: Address PR review comments and fix failing GitHub Actions
---

You are being invoked via the /review-comments skill. Your task is to address review comments on a pull request and fix any failing GitHub Actions.

## Usage
The user can invoke this skill in several ways:
- `/review-comments` - Will detect the current branch's PR automatically
- `/review-comments <PR-number>` - Address comments on a specific PR number
- `/review-comments <PR-URL>` - Address comments from a PR URL

## Steps to Execute

1. **Identify the PR**:
   - If PR number/URL is provided as an argument, use that
   - Otherwise, check current branch with `git branch --show-current`
   - If not on main/master, find the PR for current branch using: `gh pr list --head <branch-name> --json number --jq '.[0].number'`
   - If no PR found, inform the user and exit

2. **Fetch PR Information**:
   - Get PR details: `gh pr view <PR-number> --json title,body,url,state,author,headRefName`
   - Get review comments: `gh pr view <PR-number> --json reviews,comments`
   - Get check status: `gh pr checks <PR-number>`
   - Display a summary of what needs to be addressed

3. **Analyze Review Comments**:
   - Parse all review comments and conversation threads
   - Identify actionable feedback that requires code changes
   - Group comments by file/topic if multiple related comments exist
   - Present a clear summary of what needs to be fixed

4. **Analyze Failing GitHub Actions**:
   - Identify which checks/actions are failing
   - For each failing check, fetch logs if possible: `gh run view <run-id> --log-failed`
   - Analyze the failure reasons (test failures, linting issues, build errors, etc.)
   - Present a clear summary of failures

5. **Create an Action Plan**:
   - List all items that need to be addressed:
     - Review comment fixes (with file paths and line numbers)
     - CI/CD fixes (test failures, lint errors, build issues)
   - Ask user if they want to proceed with automated fixes, or if they want to review the plan first
   - Use AskUserQuestion if clarification is needed on ambiguous review comments

6. **Implement Fixes**:
   - Address each review comment by:
     - Reading the relevant files
     - Making the requested changes
     - Ensuring changes align with the reviewer's intent
   - Fix failing GitHub Actions by:
     - Running tests locally if possible to understand failures
     - Fixing test failures, linting issues, or build problems
     - Ensuring all checks will pass

7. **Commit and Push**:
   - Stage all changes
   - Create a commit message that references the review comments addressed:
     ```
     Address PR review comments

     - Fixed <issue 1> as requested by <reviewer>
     - Fixed <issue 2> as requested by <reviewer>
     - Fixed failing <check-name> tests

     Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
     ```
   - Push changes to the PR branch
   - Post a comment on the PR summarizing what was fixed: `gh pr comment <PR-number> --body "..."`

8. **Verify and Report**:
   - Wait a moment for checks to start (optional)
   - Show the PR URL and summary of changes made
   - Inform user that checks are running and they should monitor the PR

## Important Notes

- **NEVER** push changes that might break the code further
- **ALWAYS** read files before editing them to understand context
- **ASK** the user if a review comment is ambiguous or unclear
- **TEST** locally when possible before pushing (run tests, linters, builds)
- **RESPECT** the reviewer's feedback - if unsure about the intent, ask the user
- **BE CAREFUL** with destructive operations or large refactors
- If tests are failing and you can't determine the fix, explain the issue to the user rather than guessing
- Use proper git commit messages that reference what was fixed
- Do NOT skip CI checks or use --no-verify unless explicitly requested

## Example Workflow

1. User runs `/review-comments 123`
2. Fetch PR #123 details and review comments
3. Display summary: "Found 3 review comments and 2 failing checks"
4. List actionable items
5. Ask user: "Should I proceed with fixing these issues?"
6. Implement fixes
7. Commit with message: "Address PR review comments - Fixed error handling as requested by @reviewer, Fixed failing lint checks"
8. Push to PR branch
9. Comment on PR: "✅ Addressed review comments and fixed failing checks"
10. Display PR URL and summary

Execute these steps in sequence to address PR review comments and fix failing checks.
