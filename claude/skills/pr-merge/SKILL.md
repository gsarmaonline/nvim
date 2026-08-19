---
name: pr-merge
description: Land a change on the default branch — on a feature branch it commits, pushes, opens a pull request if none exists, checks that it is safe, then squash merges and cleans up; on the default branch it commits and pushes straight there with no branch and no PR. Merges without asking for confirmation; a red gate stops it instead. A superset of /pr-ship. Use when the user says merge this, land it, ship and merge, or asks to merge an existing PR.
---

You are invoked via `/pr-merge`. You get the change landed on the default branch, whichever route
it takes.

Two routes, decided in Step 1:

- **On a feature branch** — commit, push, open a pull request if none exists, check the gates,
  squash merge, clean up. `/pr-ship` stops at the open PR; this skill goes past it.
- **Already on the default branch** — commit and push straight to it. No branch, no pull request.
  The user chose to work there; do not manufacture ceremony around that decision.

---

## The rule

> Landing on the default branch is the point of no return for everybody else. Never land on a guess.

A merge, or a direct push, lands on a shared branch, triggers deployments, and is awkward to undo.
Every gate in Step 3 exists because skipping it costs somebody else their afternoon.

The direct route has no gates to run, because there is no pull request and no CI result to read.
That is the trade the user made by working on the default branch. Read the diff carefully before
you commit, since your own reading is the only review the change will get.

---

## Step 1 — Work out which route this is

```bash
git branch --show-current
git status --short
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
gh pr view --json number,title,url,state,isDraft,baseRefName,headRefName 2>/dev/null
```

| State | Route |
|---|---|
| **On the default branch, with local changes** | **Step 1b — commit and push straight to it. Do not create a branch** |
| On a feature branch, a PR exists and is open | Step 2 |
| On a feature branch, no PR, local changes | Run the `/pr-ship` flow to open one, then Step 2 |
| PR already merged or closed | Say so and stop. Do not reopen without being asked |
| On the default branch, nothing to commit | Say there is nothing to do, and stop |

When the user names a PR number or URL, use that instead of the current branch.

---

## Step 1b — Working directly on the default branch

The user is already working on `main`. **Do not create a branch, and do not open a pull request.**
Branching would only manufacture ceremony around a decision they already made.

Commit with the same discipline `/pr-ship` uses. Read the diff before writing the message, follow
the repository's existing commit style, and stage exact paths rather than `git add -A`.

```bash
git diff                       # read it before you describe it
git log --oneline -10          # match the message style
git add <exact paths>
git commit
```

Then bring the branch up to date and push:

```bash
git fetch origin
git rev-list --count HEAD..origin/<default>     # 0 means nothing to rebase onto
git rebase origin/<default>                     # only when behind
git push origin <default>
```

Resolve any rebase conflicts exactly as `/pr-ship` does. If a conflict needs human judgement,
`git rebase --abort`, explain it, and stop without pushing.

**If the push is rejected**, do not force it. A rejection means one of two things:

| Rejection | Do |
|---|---|
| Non-fast-forward, the remote moved | Fetch and rebase again, then push |
| Branch protection refuses direct pushes | Fall back: create a branch, push it, open a PR, continue to Step 2 |

Say which happened. A protected branch is the repository telling you that direct pushes are not
allowed, so the fallback is the correct answer, not a workaround.

Then report as in Step 7 and stop. Steps 2 to 6 are about a pull request, and there is none.

---

## Step 2 — Bring the branch up to date

```bash
gh pr view --json mergeable,mergeStateStatus
```

Read `mergeStateStatus` and act on it:

| Value | Meaning | Do |
|---|---|---|
| `CLEAN` | Ready | Continue to Step 3 |
| `BEHIND` | Base branch has moved | Update the branch, below |
| `DIRTY` | Real merge conflicts | Resolve, below |
| `BLOCKED` | Review or a required check is missing | Step 3 will explain which |
| `UNSTABLE` | A non-required check failed | Step 3 decides |
| `DRAFT` | Still a draft | Ask before `gh pr ready` |
| `UNKNOWN` | GitHub is still computing | Wait and re-read once |

**Behind the base:**

```bash
git fetch origin
git rebase origin/<baseRefName>     # or: gh pr update-branch
git push --force-with-lease
```

Use `--force-with-lease`, never `--force`. Never force push to `main` or `master`.

**Conflicts:** resolve them exactly as `/pr-ship` does — read every conflicted file, keep both
sides unless they contradict, stage, continue. If the conflict needs human judgement, abort with
`git rebase --abort`, explain it, and stop. **Do not merge around a conflict you could not
resolve.**

---

## Step 3 — The gates

Check every one. Report each result. Do not merge while any gate is red.

```bash
gh pr checks
gh pr view --json reviewDecision,statusCheckRollup,isDraft,mergeable,autoMergeRequest
gh pr view --comments
```

| Gate | Pass condition |
|---|---|
| **Checks** | Every required check is green. Not "mostly green" |
| **Checks still running** | See auto-merge, below |
| **Review** | `reviewDecision` is `APPROVED`, or the repository requires no review |
| **Changes requested** | None outstanding. `CHANGES_REQUESTED` is a hard stop |
| **Unresolved threads** | None. Point the user at `/pr-review-comments` if there are |
| **Draft** | Not a draft |
| **Base branch** | It is the branch the user expects. Say which one you read |

**When a check fails:** stop and report which one, with the failing output. Offer
`/pr-review-comments`, which fixes failing Actions. Do not merge and do not rerun the job hoping
it passes.

**When checks are still running,** offer auto-merge instead of waiting:

```bash
gh pr merge --auto --squash --delete-branch
```

GitHub then merges by itself once every check passes. Say clearly that the merge will happen
later, without you watching.

---

## Step 4 — State what you are doing, then do it

**Do not ask for permission to merge.** Invoking this skill is the instruction. Print the summary
and proceed straight to Step 5.

```
PR #142  Add order pagination
  main ← feat/order-pagination
  checks    7 passed
  review    approved by 1
  strategy  squash, delete branch after
  Merging.
```

The gates in Step 3 still hold. Not asking is not the same as not checking: a red gate stops the
merge, and you report it instead.

---

## Step 5 — Merge

**Always squash.** Do not ask, and do not weigh the repository's commit history against it. One
commit per pull request on the default branch.

Only check the strategy when a squash merge fails:

```bash
gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed
```

If `squashMergeAllowed` is false, say so, name the strategies the repository does allow, and stop.
Do not silently merge a different way.

```bash
gh pr merge <number> --squash --delete-branch
```

For a squash merge, review the commit message GitHub proposes. It defaults to the PR title plus
every commit subject, which is usually noise. Pass a clean one with `--subject` and `--body`
when the default is poor. Keep the repository's conventions, and no em dashes.

---

## Step 6 — Clean up locally

```bash
git checkout <baseRefName>
git pull
git branch -d <headRefName>        # -d, never -D
git fetch --prune
```

Use `-d`. It refuses to delete a branch that was not merged, which is exactly the safety you
want. If it refuses, something went wrong upstream — investigate rather than forcing it.

---

## Step 7 — Report

```
MERGED  #142  Add order pagination  →  main
  strategy   squash
  commit     abc1234
  branches   remote deleted, local deleted
  url        https://github.com/org/repo/pull/142
```

If you queued auto-merge instead, say so plainly and state what still has to pass.

When you pushed straight to the default branch (Step 1b), report that shape instead. Say plainly
that no pull request was involved, so nobody reading later assumes one was reviewed:

```
PUSHED  main  (direct, no PR)
  commit     abc1234  Add order pagination
  files      3 changed, +48 / -12
  remote     origin/main up to date
```

---

## Never

- **Never ask for permission to merge, and never ask which strategy to use.** Invoking this skill
  is the instruction, and the strategy is always squash.
- **Never merge with a failing required check.** Fix it or stop.
- **Never merge over `CHANGES_REQUESTED`** or an unresolved review thread.
- **Never use `--admin`** to bypass branch protection unless the user explicitly asks. Protection
  rules exist because a human decided they should.
- **Never force push to `main` or `master`**, on either route. Use `--force-with-lease` on feature
  branches only. A rejected push to the default branch means rebase or fall back to a PR, never
  force.
- **Never open a pull request when the user is already working on the default branch.** Branching
  around a decision they already made is ceremony, not safety.
- **Never delete a branch with `-D`.**
- **Never merge a draft** without asking first.
- **Never commit a file that likely holds a secret** — `.env`, credentials, keys.
- **Never use `--no-verify`** or skip hooks unless asked.
- **Never use em dashes** in commit messages, PR titles, or PR bodies.

## Stop when

These are not permission questions. Each one means the merge should not happen yet.

- **A gate in Step 3 is red.** Report which, and what would clear it.
- **Squash merge is disallowed** by the repository.
- **A conflict needs human judgement.** Abort the rebase and explain it.
- **The base branch is not the default branch** — a stacked PR targeting another feature branch.
  Name the base and confirm that is intended, because merging into the wrong base is expensive to
  undo.

## Say, then proceed

Report these in one line and merge anyway. They are worth knowing, not worth blocking on.

- The PR touches migrations, infrastructure, or anything that deploys on merge. Name what merging
  will trigger.
- The diff has grown well past what the conversation covered. Give the file count.
