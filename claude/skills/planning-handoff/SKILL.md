---
name: planning-handoff
description: Write a complete handoff document so another agent session can continue this work cold — state, decisions, dead ends, next step, and exactly how to verify. Use when the user is ending a session, asks for a handoff, or wants another session to pick this work up cold.
---

You are invoked via the `/planning-handoff` skill. You write the document that lets a **fresh session
with no memory of this conversation** pick up the work and continue without repeating it.

The reader has the repository. The reader does not have the conversation.

---

## The test

> Could a competent stranger read this file, run one command, and know what to type next?

If not, the handoff is incomplete. Everything below serves that test.

---

## Step 1 — Collect the real state

Do not write from memory alone. Check.

```bash
git status --short
git log --oneline -10
git diff --stat
<the test command for this repo>
```

Record the actual output. A handoff that claims "tests pass" without a run is worse than no
handoff, because the next session trusts it.

Also note: running processes, open branches, uncommitted stashes, temporary files, and any
environment setup the next session needs.

---

## Step 2 — Write the document

Write to `HANDOFF.md` in the repository root, unless the user names another path. If the file
exists, read it first and replace it — do not append a second handoff below a stale one.

Use this structure:

```markdown
# Handoff — <task name>

**Date:** <YYYY-MM-DD>
**Branch:** <branch>  **Base:** <base branch and commit>
**Status:** <not started | in progress | blocked | ready for review>

## Goal
<what the user actually wants, in three sentences or fewer, in their terms>

## Where things stand
<what works now, what does not, what is half-built — be specific and honest>

## Decisions already made
<each decision, the reason, and who made it. The next session must not re-litigate these.>
- <decision> — because <reason> — decided by <user | agent>

## Dead ends — do not repeat
<approaches tried and rejected, and why each failed. This is the highest-value section.>

## The next step
<one concrete action, precise enough to start immediately: the file, the function, the change>

## After that
<the following two or three steps, in order>

## Open questions for the user
<anything blocked on a human decision — do not guess these into the plan>

## Files that matter
- `path:line` — <why this file matters to this task>

## How to verify
```bash
<setup command>
<test command>
```
Expected: <the exact result a correct state produces>
Current: <the actual result right now>

## Environment and gotchas
<services to start, env vars, credentials, slow steps, flaky tests, anything surprising>
```

---

## Rules for the content

- **Write the dead ends.** The single largest waste in a cold restart is repeating a failed
  approach. Name each one and say what failed about it.
- **One next step, not a menu.** If two paths are open, name your recommendation and put the
  alternative under open questions.
- **Absolute clarity over brevity.** This document is read once by someone with no context.
  Spell out what an insider would abbreviate.
- **No conversational references.** "As we discussed" and "the approach from earlier" mean
  nothing to the reader. Restate the content.
- **Paths and commands, not descriptions.** `src/auth/session.go:142`, not "the session code".
- **Separate fact from plan.** Anything you did not verify goes under open questions, marked as
  unverified.

---

## Step 3 — Hand over

Tell the user:
- Where you wrote the file.
- The one-line summary of the next step.
- Anything you could not determine and left as an open question.

If the user asks for the handoff in chat rather than a file, print the same structure inline.

---

## Resuming from a handoff

If the user starts a session by pointing you at a `HANDOFF.md`:
1. Read it in full.
2. Re-run the verification block and compare against the recorded "current" result.
3. If they differ, say so before doing anything else — the repository moved since the handoff.
4. Confirm the next step with the user, then start.
