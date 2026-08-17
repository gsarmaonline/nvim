---
name: code-report
description: Manage the FINDINGS.md document as a whole — report status, recommend what to fix next, merge entries that share a root cause, check the table against the entries, and produce the final close-out write-up. Use when the user asks where they stand, what to fix next, or to finish the findings document.
---

You are invoked via `/code-report`. You own the **document**, not any single entry.

Division of labour — do not cross it:

| Skill | Job |
|---|---|
| `/code-finding` | Write one new entry the user spotted |
| `/code-audit` | Sweep the codebase and fill the document |
| `/code-report` | Report, re-rank, merge, check, and close out |
| `/code-fix` | Repair a defect |

If the user is describing a **new** defect, hand off to `/code-finding` rather than writing it
yourself. If they want more defects **found**, hand off to `/code-audit`.

---

## The rule

> The document is the deliverable. Code that is fixed but undocumented scores nothing.

---

## Step 0 — Locate the document

```bash
ls FINDINGS.md 2>/dev/null || rg -l '^## F[0-9]' --glob '*.md'
```

If none exists, say so in one line and offer two paths: `/code-audit` to find defects, or
`/code-finding` to file the first one by hand. Do not create an empty document.

Read the whole file before you do anything else. Every mode below depends on it.

---

## Step 1 — Read the mode

| Call | Mode | Go to |
|---|---|---|
| `/code-report` | Status | Step 2 |
| `/code-report next` | Recommend | Step 3 |
| `/code-report check` | Integrity | Step 4 |
| `/code-report merge F2 F5` | Merge | Step 5 |
| `/code-report close` | Close out | Step 6 |

When the call is ambiguous, run Status. It is cheap and it usually answers the question.

---

## Step 2 — Status

Report in under fifteen lines. The user is mid-task.

```
FINDINGS.md — 7 entries

  fixed       3   F1 F4 F6
  documented  2   F2 F7
  open        2   F3 F5

  CRITICAL 1   HIGH 3   MEDIUM 2   LOW 1
  Confirmed 5  Likely 2

  Baseline 48 passed / 2 failed   →   now 51 passed / 0 failed

NEXT   F3 HIGH Security — missing ownership check — service.py:88
       Confirmed, single-file fix, no migration needed.

RISK   F5 is still Likely. Verify it or drop it before you hand in.
```

Take the test numbers from the document or from the conversation. **Never invent them.** Write
`<not recorded>` when they are absent, and say the baseline is missing — that is worth flagging
on its own.

---

## Step 3 — Recommend what to fix next

Rank the open entries. Weigh four things, in this order:

1. **Severity.** A CRITICAL beats a HIGH.
2. **Confidence.** Never recommend a `Likely` entry ahead of a `Confirmed` one. Fixing something
   that turns out not to be a defect costs twice: the time, and the credibility.
3. **Repair cost.** Single expression, then single function, then signature change, then
   migration. Prefer the cheap one when severity is close.
4. **Time remaining.** Ask, or infer from the conversation. Do not recommend a migration-shaped
   fix with fifteen minutes left. Recommend documenting it instead, and say why.

Give one recommendation, with the reason in one sentence, and name the runner-up. Do not present
a ranked list of seven — that pushes the decision back to the user, which is the thing they asked
you to do.

Then say the command: `/code-fix F3`.

---

## Step 4 — Integrity check

This is the mode that saves the deliverable. A document maintained under time pressure drifts.
Check all of these and report only what is wrong:

- **Table against entries.** Every table row has a detail entry, and every entry has a row. Count
  both. `grep -c '^| F[0-9]'` against `grep -c '^## F[0-9]'`.
- **Status agreement.** The `**Status:**` line inside each entry matches its table cell.
- **Empty fields.** Any entry missing Root cause, Trigger, Impact, Proposed fix, Migration, or
  Test. An empty field means a question went unasked.
- **Triggers that are not triggers.** A Trigger field that states a symptom rather than a
  concrete input and a wrong result. "The page is slow" fails. Flag it.
- **Stale `Likely`.** Any entry still marked Likely with no Verification notes.
- **Claimed fixes without evidence.** Status `fixed` with no commit reference or no verification
  line.
- **Duplicate root causes.** Two entries citing the same file and line, or describing the same
  mechanism. Propose a merge; do not perform it without asking.
- **Missing baseline.** No recorded before-and-after test numbers.
- **Leaked secrets.** Any full credential quoted in a code block. Truncate it immediately, to
  first four and last four characters, and tell the user.

Report as a short list of defects in the document, each with the entry ID. Say "no issues" when
the document is clean.

---

## Step 5 — Merge entries that share a root cause

Called as `/code-report merge F2 F5`, or after Step 4 proposes one.

Confirm the shared cause first. Open both cited locations and check that one change would fix
both. **If you are not sure, ask.** Two separate entries are recoverable; a wrong merge hides a
real defect.

Then:

1. Keep the **lower** ID. Never renumber.
2. Fold the second entry's distinct content into the survivor:

```markdown
**Also causes:** the slow filter path at `views.py:31` — same root cause.
```

3. Raise the survivor's severity if the combined blast radius is larger. Say that you did.
4. Replace the merged entry's body with one line, and keep its ID so older references resolve:

```markdown
## F5 — merged into F2

Same root cause as F2: `Order.items` loads lazily at `models.py:10`.
```

5. Update both table rows.

Say it plainly in the report: collapsing several symptoms into one root cause demonstrates
diagnostic depth, and it is worth stating in the close-out.

---

## Step 6 — Close out

Run this when the work is ending. Produce the final document, in this order.

**1. Run the integrity check from Step 4 first.** Fix what it finds before writing anything else.

**2. Run the test suite** and record the real number. Compare it against the baseline. If the
suite is red, say which tests fail and whether your changes caused it.

**3. Fill the three sections that carry the most weight:**

```markdown
## Summary

| # | Sev | Domain | Finding | File | Status |
|---|-----|--------|---------|------|--------|

Fixed: N. Documented, not fixed: N. Suite: <before> → <after>.

## Documented but not fixed

Each one keeps its root cause, trigger, and proposed fix. State why it was deferred —
lower severity, or a migration that did not fit the time. Deferring deliberately is a
judgement call; leaving it unexplained looks like an oversight.

## Not audited

What you did not look at, and why. Name the subsystems, not "everything else".
```

**4. Add a one-paragraph opening** stating what you found, what you fixed, and what you would do
next with more time. Put it at the top. It is the first thing anybody reads.

**5. Commit the document on its own:**

```bash
git add FINDINGS.md
git commit -m "docs: findings from the audit, with what was fixed and what was deferred"
```

---

## Never

- **Never edit source code.** This skill writes one markdown file.
- **Never add a new finding.** That is `/code-finding`.
- **Never renumber existing IDs.** Commits and conversations already cite them.
- **Never invent test numbers, commit hashes, or severities.** Read them or ask.
- **Never upgrade `Likely` to `Confirmed`** without opening the code and confirming it yourself.
- **Never delete an entry.** Mark it withdrawn, with the reason. A withdrawn finding with an
  honest reason reads better than a gap in the numbering.
- **Never quote a full secret.** Truncate to the first four and last four characters.
