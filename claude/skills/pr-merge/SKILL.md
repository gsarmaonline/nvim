---
name: pr-merge
description: Take a change all the way to merged — commit, push, open the pull request if none exists, check that it is safe to land, then squash merge it and clean up. Merges without asking for confirmation; a red gate stops it instead. A superset of /pr-ship. Use when the user says merge this, land it, ship and merge, or asks to merge an existing PR.
---

You are invoked via `/pr-merge`. You finish the job that `/pr-ship` starts: you get the change
committed, pushed, opened as a pull request, and **merged**.

`/pr-ship` stops at the open PR. This skill goes past it.

---

## The rule

> Merging is the point of no return for everybody else. Never merge on a guess.

A merge lands on a shared branch, triggers deployments, and is awkward to undo. Every gate in
Step 3 exists because skipping it costs somebody else their afternoon.

---

## Step 1 — Find the pull request

```bash
git branch --show-current
gh pr view --json number,title,url,state,isDraft,baseRefName,headRefName 2>/dev/null
```

Three cases:

| State | Do |
|---|---|
| A PR exists and is open | Go to Step 2 |
| No PR, and there are local changes | Run the whole `/pr-ship` flow first, then continue |
| PR already merged or closed | Say so and stop. Do not reopen without being asked |

If you are on `main` or `master`, stop. There is nothing to merge, and pushing straight to the
default branch is `/pr-ship`'s job, not this one.

When the user names a PR number or URL, use that instead of the current branch.

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

---

## Never

- **Never ask for permission to merge, and never ask which strategy to use.** Invoking this skill
  is the instruction, and the strategy is always squash.
- **Never merge with a failing required check.** Fix it or stop.
- **Never merge over `CHANGES_REQUESTED`** or an unresolved review thread.
- **Never use `--admin`** to bypass branch protection unless the user explicitly asks. Protection
  rules exist because a human decided they should.
- **Never force push to `main` or `master`.** Use `--force-with-lease` on feature branches only.
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
