---
name: code-finding
description: Log a defect you spotted yourself into FINDINGS.md — verify the claim against the source, fill the root cause, trigger, impact, fix and test fields, assign severity, and keep the summary table in sync. Use when the user says "add a finding", "log this", "note this issue", or reports a defect they found by hand during a review or timed assessment.
---

You are invoked via `/code-finding`. The user found something themselves. You verify it, write it
up properly, and file it. You do **not** fix code and you do **not** go hunting for more.

Typical calls:

```
/code-finding orders list is N+1, service.py
/code-finding GetOrder never checks ownership — service.py:88
/code-finding F2 fixed abc1234
/code-finding
```

---

## The rule

> A finding without a trigger is a hunch. Never file a hunch as a finding.

A trigger is a concrete input or state, then the wrong result. "This looks slow" is not a
trigger. "`ListOrders` with 200 rows issues 201 queries" is.

## Budget

**90 seconds of verification, maximum.** This is typed while a clock runs. If you cannot confirm
the claim in 90 seconds, file it with `Confidence: Likely`, write what you checked, and move on.
Never make the user wait while you read the whole codebase.

---

## Step 1 — Read the call

Three forms. Detect which one you were given.

| Form | Example | Do |
|---|---|---|
| Description | `/code-finding orders list is N+1` | Steps 2 to 6 |
| Status update | `/code-finding F2 fixed abc1234` | Step 7, then stop |
| Empty | `/code-finding` | Ask one question: "What did you find, and where?" Then Step 2 |

Ask **at most one** clarifying question, and only when you cannot locate the code at all. Never
interview the user. They are mid-task, and they already know what they found. Your job is the
write-up, not the discovery.

---

## Step 2 — Locate the file

Find the exact `file:line`. The user usually gives a partial hint.

```bash
rg -n '<the symbol or string they mentioned>' --type-add 'src:*.{py,ts,tsx,js,go}' -tsrc
git ls-files | grep -i '<their hint>'
```

Read the function, and read enough of its callers to know how it is reached. If you cannot find
it, say so in one line and ask where it is. Do not guess a path.

---

## Step 3 — Verify, within the budget

Confirm all three. Each failure changes what you write, and none of them means "discard" — the
user found something and deserves an honest answer.

**1. The code says what they claim.** Read the lines. Never confirm from a grep match alone.

**2. No guard already handles it.** This kills most false findings. Search for the protection you
are assuming is absent:

- Missing auth → search for middleware, interceptors, decorators, and a base class check.
- Missing validation → search for a schema, a Pydantic model, a proto constraint.
- Missing index → check the migration files, not only the model.
- N+1 → search for `selectinload`, `joinedload`, or an eager default on the relationship.
- Race condition → search for a lock, a unique constraint, or an atomic update.

**3. You can state the trigger.** Write the sentence. If you cannot, tell the user so directly:
"I cannot state a trigger for this — here is what I checked. Do you want it filed as Likely?"

Then set confidence honestly:

| Confidence | Means |
|---|---|
| Confirmed | You read the code, found no guard, and can state the trigger |
| Likely | The shape is wrong, but reachability or the guard search is unfinished |

Never label something Confirmed to make the report look stronger. One false Confirmed costs more
credibility than three honest Likelys.

---

## Step 4 — Assign severity

| Severity | Meaning |
|---|---|
| CRITICAL | Data loss, authentication bypass, remote code execution, live credentials exposed |
| HIGH | Privilege escalation, injection, corruption under normal load, silent data loss |
| MEDIUM | Degradation at scale, missing test isolation, weak defaults, gaps that hide other defects |
| LOW | Hardening with a real but small cost |

Judge by blast radius and reachability, not by how interesting the defect is. An unreachable
CRITICAL is a MEDIUM. State the severity you chose and why in one clause.

---

## Step 5 — Open or create FINDINGS.md

```bash
ls FINDINGS.md 2>/dev/null || ls ~/work/refactor-assessment/templates/FINDINGS.md
```

If `FINDINGS.md` does not exist, create it from
`~/work/refactor-assessment/templates/FINDINGS.md` when that file is present, otherwise from the
document skeleton in `~/.claude/skills/code-report/reference/findings-schema.md`. Record the
baseline test line if the user has given you one; leave it marked `<not recorded>` if not, and
say so.

**Before writing, read the existing entries.** If this defect shares a root cause with one
already filed, do not open a new entry. Add a line to the existing one:

```markdown
**Also causes:** the slow filter path at `views.py:31` — same root cause.
```

Collapsing duplicates into one root cause is worth more than two separate entries. Tell the user
you did it.

---

## Step 6 — Write the entry

Assign the next free ID. **Never renumber existing IDs** — commit messages and conversations
already cite them. If F1 to F3 exist, the new one is F4, even after a deletion.

**Read `~/.claude/skills/code-report/reference/findings-schema.md` before you
write.** It defines the entry format, the summary table, and the vocabularies. Do not write from
memory.

Fill every one of the 14 fields. An empty field is a signal you skipped a question worth asking.
Set `Found by: manual review`.

Then update the summary table at the top of the file. Add one row:

```markdown
| F<n> | <SEV> | <Domain> | <short title> | `path:line` | open |
```

Keep the table sorted by severity, then by ID. **The table and the entries must never disagree.**
Re-read both after writing.

---

## Step 7 — Status updates

Called as `/code-finding F2 fixed abc1234`, or `documented`, `open`, or `withdrawn <reason>`.

Change two places, always both:

1. The `**Status:**` line in the entry, to `fixed in \`abc1234\``, `documented`, `open`, or
   `withdrawn`.
2. The status cell in the summary table row.

For `withdrawn`, keep the entry and its ID. Never delete it, and never renumber around it.
Replace the body with the reason:

```markdown
## F5 — withdrawn

Filed as a missing ownership check. `require_owner` at `deps.py:22` already covers this path.
Verified by reading the router's dependency chain.
```

A withdrawn finding with an honest reason reads better than a gap in the numbering. It shows you
checked your own work.

For `fixed`, also append the verification line to that entry:

```markdown
**Verification:** `<test command>` — <N passed> before, <N passed> after. New test: `<test name>`.
```

Get those numbers from the conversation or by running the suite. Do not invent them.

---

## Step 8 — Report back

Three lines, no more. The user is still working.

```
F4 HIGH Security — GetOrder has no ownership check — service.py:88 — Confirmed
Filed in FINDINGS.md. Summary table updated.
Fix it with: /code-fix F4
```

When you downgraded to Likely, say what is unproven in one extra line.

---

## Never

- **Never edit source code.** This skill writes one markdown file. Use `/code-fix` to repair.
- **Never file a finding you could not locate in the source.** Ask where it is instead.
- **Never renumber existing findings.**
- **Never let the summary table drift** from the detail entries.
- **Never mark Confirmed** when the guard search is unfinished.
- **Never print a full secret.** Truncate to the first four and last four characters.
- **Never go looking for additional defects.** The user asked you to file one. Use
  `/code-audit` for a sweep.
- **Never spend more than 90 seconds verifying.** File it as Likely and hand control back.

## Stop and ask when

- Two entries look like the same root cause but you are not certain. Ask before you merge them.
- The "defect" may be deliberate behaviour that something else depends on. File it as a question,
  not a finding, and say what would settle it.
- The user's claim contradicts what you read in the code. Show them the lines and ask. They may
  be reading a different version, or you may be reading the wrong file.
