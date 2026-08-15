---
name: surgical-fix
description: Repair one defect with the smallest possible change — verify the baseline, fix the root cause, prove it with a test, and commit atomically with a written justification
---

You are invoked via the `/surgical-fix` skill. You repair **one** defect, minimally, and prove
it. You do not tidy the neighbourhood.

Use this after `/audit-codebase` or when the user names a specific defect. If the user hands you
several defects, work them one at a time through this whole loop. One defect, one loop, one
commit.

---

## The rule

> Fix the problem, not the neighbourhood.

A reviewer should read the diff and see only the defect disappearing. Every line you touch that
is not required is a line that hides your reasoning and risks the existing behaviour.

Specifically, do not:
- Reformat, reorder imports, or rename anything not central to the fix.
- Upgrade a dependency unless the defect is the dependency.
- Refactor a nearby function you dislike.
- Fix a second defect in the same commit. Note it and take it in the next loop.

---

## Step 1 — Establish the baseline

Before you touch anything:

```bash
git status --short
git stash list
<the test command for this repo>
```

Record the exact pass and fail counts. If the suite is already red, note which tests were
already failing. You cannot claim "tests pass" later without this number.

If the working tree is dirty with unrelated changes, stop and tell the user. Do not commit
someone else's work inside your fix.

---

## Step 2 — Restate the defect

Write these four lines before you edit. If you cannot, you do not understand the defect yet, and
you will fix a symptom.

- **Root cause:** why the code is wrong, in one sentence.
- **Trigger:** the input or state that produces the wrong behaviour.
- **Wrong behaviour:** what happens now.
- **Correct behaviour:** what should happen.

---

## Step 3 — Write the failing test first

Add the test that fails now and passes after the fix. Run it and **watch it fail**. A test you
never saw fail proves nothing.

- Put it beside the existing tests, in their style, using their fixtures.
- Assert the behaviour, not the implementation.
- For a performance defect, assert the observable count — the number of queries issued, not the
  elapsed time. Timing assertions are flaky.
- For a security defect, assert the denial: the unauthorised caller receives an error and does
  not receive the data.
- For a concurrency defect, assert the invariant after concurrent operations, not the schedule.

If the defect genuinely cannot be tested — a build configuration, for example — say so
explicitly and describe the manual verification you ran instead.

---

## Step 4 — Make the smallest change that removes the root cause

Prefer, in this order:
1. Change the one wrong expression or the one wrong argument.
2. Add the missing guard, index, dependency, or parameter.
3. Change one function's internals.
4. Change a signature, and update every caller.
5. Anything larger — stop, and ask the user before you continue.

Read the whole function before you edit it, and read its callers. A local fix that breaks a
caller is worse than the defect.

Match the surrounding code: its naming, its error style, its comment density. Add a comment only
where the reason for the fix is not obvious from the code — a comment saying *why*, never *what*.

---

## Step 5 — Think about migration and compatibility

Ask these before you commit. Any "yes" belongs in the commit message.

- Does this change a wire contract, a public signature, a response shape, or a stored format?
- Do stored rows need a backfill? Is there a migration, and is it reversible?
- Can old and new code run at the same time during a rollout? Security fixes to a stored format
  — a password hash, a token format — usually need a dual-read phase: verify with either
  scheme, then upgrade the record on the next successful use.
- Does the fix need a configuration value? What is the safe default, and what happens if it is
  missing?
- Is there an existing behaviour that some caller depends on that you are removing? If so, say
  who and what breaks.

If the fix cannot land in one safe step, implement the safe first step and write the remaining
steps into the commit message as a stated plan. Do not silently ship a breaking change.

---

## Step 6 — Verify

```bash
<the new test alone>          # must now pass
<the full test suite>         # must match or beat the baseline
<lint and type check>
git diff --stat
```

Compare against the Step 1 baseline exactly. If any test that passed before now fails, your fix
is wrong or incomplete. Fix it or revert it. **Breaking existing behaviour is worse than leaving
the defect in place.**

Read your own diff line by line. Delete anything that is not needed. Debug prints, stray blank
lines, and commented-out code do not belong in the commit.

---

## Step 7 — Commit atomically

One defect, one commit. Stage only the relevant paths — never `git add -A` without reading what
that stages.

```bash
git add <exact paths>
git status --short
git commit
```

Use this message shape:

```
<area>: <what changed, imperative, under 72 chars>

Problem
  <root cause, one or two sentences, with file:line>

Trigger
  <the concrete input or state that exposes it>

Impact
  <severity and who is affected>

Fix
  <what changed and why this is the minimal correct change>

Alternatives considered
  <what you rejected and why — only if a reader would wonder>

Migration
  <compatibility, backfill, staged rollout, or "none needed">

Verification
  <new test name; suite before -> after>
```

Example first line: `orders: scope order lookup to the requesting user`.

Follow the repository's own conventions where they exist. If it uses Conventional Commits, use
them. Read `git log` before you write the first one.

---

## Step 8 — Report

Tell the user, briefly:
- What you fixed and where.
- The test that now covers it.
- Suite before and after.
- Anything you deliberately left alone, and why.
- The next defect you recommend, if there is a list.

Be honest. If the suite is still red for a reason you did not cause, say so and say which tests.

---

## When to stop and ask

Stop and ask the user before you continue when:
- The minimal fix would touch more than roughly five files.
- The fix requires a schema migration on data you cannot see.
- Two valid fixes exist with a real trade-off — present both in two lines each and recommend one.
- The "defect" may be deliberate behaviour that something else depends on.
- Fixing it properly needs an interface change that would break a published contract.
