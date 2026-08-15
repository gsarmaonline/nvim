---
name: to-issues
description: Convert a plan into independently executable GitHub issues — each one self-contained, scoped to a single deliverable, with acceptance criteria and stated dependencies
---

You are invoked via the `/to-issues` skill. You turn a plan into GitHub issues that **a stranger
can execute without reading the plan**.

The plan is in this conversation. The issues will be read months later, by someone else, in a
browser tab, with no context. Write for that reader.

---

## The test for one issue

> Can one person pick this up, finish it, and open a pull request — without asking a question
> and without waiting on another issue that is not listed as a blocker?

If not, the issue is too big, too vague, or too coupled. Split it or merge it.

---

## Step 1 — Recover the plan

Restate the plan in bullets and confirm the scope with the user before writing anything. Ask:

- Which repository? (Check `git remote -v` and `gh repo view`.)
- Is there a milestone, project, or label convention? Read existing issues to match the style:
  `gh issue list --limit 20`.
- Should this be one epic with children, or a flat list?

---

## Step 2 — Cut the plan into issues

Cut along **deliverables**, not along activities. "Write tests" is not an issue; "Rate limiter
rejects over-quota requests, with tests" is.

Rules for the cut:

- **One deliverable per issue.** It merges as one pull request.
- **Half a day to two days** of work each. Larger means split; much smaller means merge.
- **Vertical, not horizontal.** Prefer an issue that crosses layers and delivers behaviour over
  an issue that changes one layer everywhere.
- **Minimise blockers.** If eight issues all block on one, that one is the real first issue and
  should be small and early.
- **Separate the reversible from the irreversible.** Schema migrations, public contract changes,
  and data backfills get their own issue with their own review.
- **Name the unknowns.** Work that needs investigation becomes a spike issue with a time box and
  a written question to answer — never a vague implementation issue.

---

## Step 3 — Write each issue

```markdown
## Context
<why this work exists — two or three sentences, no reference to "the plan" or "our discussion">

## Scope
<exactly what to build>

## Out of scope
<what a reader might reasonably assume is included but is not, and which issue owns it>

## Acceptance criteria
- [ ] <observable, testable statement>
- [ ] <one per line, each verifiable by running something>

## Implementation notes
<the files that matter, `path:line`; the existing pattern to follow; known traps>

## Verification
```bash
<the command that proves it works>
```

## Dependencies
Blocked by: #<n> — <why>
Blocks: #<n>

## Estimate
<S | M | L>
```

Quality rules:

- **Acceptance criteria are observable.** "Handles errors correctly" fails. "Returns 429 with a
  `Retry-After` header when the caller exceeds 100 requests per minute" passes.
- **Every issue carries its own context.** Do not write "see the parent issue" for the reason it
  exists. Repeat the two sentences.
- **Cite real paths.** Verify each path exists before you write it.
- **Titles are imperative and specific.** `Add per-tenant rate limiting to the API gateway`, not
  `Rate limiting`.

---

## Step 4 — Confirm, then create

Show the full list to the user first: titles, order, and the dependency graph. Ask for approval.
Do not create issues before the user approves — issues are outward-facing and noisy to undo.

Then create them:

```bash
gh issue create --title "..." --body-file <file> --label "..." --milestone "..."
```

Create blockers first so you have real issue numbers for the `Blocked by` lines, then update the
dependents with `gh issue edit`.

If `gh` is not authenticated or the repository has no GitHub remote, stop and write the issues
to a markdown file instead. Tell the user why.

---

## Step 5 — Report

Give the user:
- The issue numbers and titles, in execution order.
- The dependency graph in three or four lines.
- The recommended first issue.
- Anything from the plan you deliberately did not turn into an issue, and why.
