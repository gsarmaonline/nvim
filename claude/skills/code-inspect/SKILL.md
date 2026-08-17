---
name: code-inspect
description: Review a bounded change before it ships — a diff, a staged set, a branch, a file, or a directory. Judge whether it does what it claims, what it might break, and whether its tests actually cover it. Use when the user says review my change, check this before I commit, or look over this file.
---

You are invoked via `/code-inspect`. You review a **bounded scope** — a change, a file, a
directory — and report what is wrong with it before it ships.

Know the neighbours, and do not duplicate them:

| Skill | Scope | Question it answers |
|---|---|---|
| `/code-inspect` | A change or a named file | Is **this** correct and safe to ship? |
| `/code-audit` | The whole codebase | What defects exist **anywhere**? |
| `/code-review` (built-in) | A diff or a GitHub PR | Same question, with an `ultra` cloud mode and PR comment posting |

Prefer the built-in `/code-review` when the target is a GitHub PR, or when the user wants
findings posted as inline PR comments. Use this skill for local work in progress, for a
directory or file that is not a diff, and when the user wants the review shaped around intent
rather than around a comment thread.

---

## The rule

> Review against what the change is trying to do, not against how you would have written it.

A review that lists style preferences buries the one comment that mattered.

---

## Step 1 — Fix the scope and the intent

Resolve the target explicitly. Say which you chose.

```bash
git status --short
git diff                      # unstaged
git diff --staged             # staged
git diff main...HEAD          # the branch
git log --oneline main..HEAD
```

If the user named a file or directory with no diff, review the file as it stands.

Then establish **intent** before reading the code. Take it from the commit messages, the branch
name, the issue, or ask in one line. You cannot judge a change without knowing what it was for.

Write the intent down in one sentence. Every later comment is measured against it.

---

## Step 2 — Read the change in context

Never review a diff by reading only the diff. Hunks hide their surroundings.

For each changed file, open the whole function, and read enough of its callers to know how it is
reached. Where a signature, a schema, or an exported name changed, find every caller:

```bash
rg -n '\b<changed symbol>\b'
```

For an unfamiliar area, run `/code-trace` on the central symbol first.

---

## Step 3 — Judge, in this order

Work down the list. Stop adding comments when they stop being worth the reader's time.

**1. Does it do what it claims?** Compare the code against the intent. A change that solves a
different problem than its message states is the most expensive kind of defect, because review
attention never returns to it.

**2. Is it correct?**
- Boundaries: empty input, a single item, the maximum, null, zero, negative, unicode.
- The error path. What is left half-written when it fails midway?
- Concurrency: two callers at once, a retry, an out-of-order delivery.
- Every new branch — is each one reachable, and is each one right?

**3. What does it break?** This is the highest-value section, and the one most reviews skip.
- Callers of anything whose signature, return shape, or error behaviour changed.
- Persisted data written by the old code and read by the new, or the reverse.
- A wire contract, an API response shape, an event payload.
- A default that changed. Existing deployments inherit the new default silently.
- Behaviour something else depends on, including behaviour that looks like a defect.

**4. Do the tests actually cover it?** Read the added tests against the added code.
- Which new branch has no test?
- Does any test assert on a mock instead of on behaviour?
- Would each test fail if the change were reverted? A test that passes both ways is decoration.
- For a bug fix: is there a test that reproduces the original bug?

**5. Does it fit the codebase?** Compare against the sibling code, not against your preference.
An inconsistency with the surrounding pattern is worth a comment. A difference from your personal
style is not.

**6. Security and resource shape.** Only where the change touches it: input from a request, a new
query, a new outbound call, a new file path, a new dependency. Check for a missing timeout, an
unbounded result, a query inside a loop, and a missing ownership check.

**7. Leftovers.** Debug prints, commented-out code, a stray `TODO` with no owner, a skipped test,
a hardcoded path.

---

## Step 4 — Verify before you speak

Every comment must survive these two questions, or it does not get written:

1. **Did I read the code, or pattern-match the diff?** Open the file. A diff hides the guard that
   lives twenty lines above the hunk.
2. **Can I state the failure?** Concrete input or state, then the wrong result. Without that, it
   is a preference, and preferences go unstated.

Run the tests if they are cheap to run. A review that claims a break the suite already catches is
weaker than one that says "confirmed: `test_x` fails".

---

## Step 5 — Report

Lead with the verdict. Order by severity. Cite `file:line` for everything.

```
VERDICT   ship / ship after fixes / do not ship
INTENT    <the one sentence from Step 1>
SCOPE     <N files, +X/-Y lines>  TESTS <ran: N passed, N failed | not run>

MUST FIX
  1. path:line — <defect>
     Failure: <concrete input -> wrong result>
     Fix: <the smallest correct change>

SHOULD FIX
  ...

CONSIDER
  ...

NOT COVERED BY TESTS
  path:line — <the branch with no test>

WHAT I DID NOT REVIEW
  <files skipped, and why — generated code, vendored, out of scope>
```

Say "no must-fix issues" explicitly when that is the answer. Silence reads as an unfinished
review.

---

## Never

- **Never rewrite the change.** This skill reports. Repair with `/code-fix`, one defect per loop.
- **Never comment on formatting** that a formatter owns.
- **Never pad the list.** Three real comments beat twelve, and a long list hides the important
  one.
- **Never claim a break you did not trace to a caller.** Find the caller or drop the comment.
- **Never approve code you did not open.** List it under WHAT I DID NOT REVIEW instead.
