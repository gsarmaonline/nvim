# FINDINGS.md — the shared schema

**This file is the single authority on the format of `FINDINGS.md`.**

Four skills write that document. They must all write it identically, or `/code-report check`
reports drift that is not really there, and real drift hides among the noise.

| Skill | What it writes |
|---|---|
| `/code-audit` | Creates the document. Appends many entries from a sweep |
| `/code-finding` | Appends one entry the user spotted. Sets status |
| `/code-fix` | Flips one entry to `fixed`, adds the verification line. Never commits the file |
| `/code-report` | Owns the whole document: status, ranking, merges, integrity, close-out |

If you change the schema, change it **here**, then check the four skills still agree.

---

## 1. Document skeleton

```markdown
# Findings — <repo name>

_<Audit only, or the assessment context>. <date>._

Baseline before any change: `<test command>` → **<N passed, N failed>**

<opening paragraph — written LAST, at close-out>

## Summary

<the table — see section 2>

Fixed: <N>. Documented, not fixed: <N>. Suite: `<before>` → `<after>`.

## Not audited

<what you did not look at, and why — name subsystems, not "everything else">

---

## F1 — <title>
<entry — see section 3>

---

## Documented but not fixed
<D-entries — see section 6>
```

Order is fixed. Summary first, then blind spots, then entries, then deferred items.

---

## 2. The summary table

Exactly six columns, exactly these headers:

```markdown
| # | Sev | Domain | Finding | File | Status |
|---|-----|--------|---------|------|--------|
| F1 | CRITICAL | Security | Missing ownership check | `service.py:88` | open |
```

- The `#` cell is **`F1`, never `1`.** `/code-report check` counts rows with
  `grep -c '^| F[0-9]'` against entries with `grep -c '^## F[0-9]'`. A bare number makes those
  counts disagree, and the document looks broken.
- Sort by severity, then by ID.
- **The table and the entries must never disagree.** Re-read both after any write.

---

## 3. The entry — 14 required fields

Every field is required. An empty field is a signal that a question went unasked. Write
"none needed" rather than leaving one blank.

Keep the field names **exactly** as written. The integrity check matches on them.

````markdown
## F<n> — <short title, under 60 characters>

- **Severity:** <CRITICAL|HIGH|MEDIUM|LOW>
- **Domain:** <Security|Performance|Reliability|Testing|Tooling>
- **Location:** `path/to/file.py:42`
- **Confidence:** <Confirmed|Likely>
- **Status:** <open|documented|fixed in `<sha>`|withdrawn>
- **Found by:** <manual review|`/code-audit`>

**What the code does**

```<lang>
<the smallest quote that shows the defect — 10 lines at most>
```

**Root cause**

<Why the code is wrong. One or two sentences. Not what happens — why.>

**Trigger**

<Concrete input or state, then the wrong result.>

**Impact**

<Who is affected and how badly.>

**Proposed fix**

<The smallest change that removes the root cause.>

**Migration and compatibility**

<Backfill needed? Wire contract changed? Can old and new run together during a rollout?
Write "none needed" when that is true — it shows you asked.>

**Test that would catch it**

<The assertion that fails before the fix and passes after.>

**Verification notes**

<What you checked, and what you did not. Required whenever Confidence is Likely.>
````

### Optional lines, appended to an entry

```markdown
**Verification:** `<test command>` — <N> passed before, <N> passed after. New test: `<name>`.
```
Added by `/code-fix` when the defect is repaired. Never invent the numbers or the sha.

```markdown
**Also causes:** the slow filter path at `views.py:31` — same root cause.
```
Use this instead of opening a second entry for a symptom that shares a root cause.

---

## 4. Vocabularies

### Status

| Value | Means |
|---|---|
| `open` | Suspected or verified, not yet repaired |
| `documented` | Diagnosed, deliberately not repaired. Say why |
| `fixed in \`<sha>\`` | Repaired, committed, and verified |
| `withdrawn` | Filed, then disproved. Keep the entry and the ID; state the evidence |

### Confidence

| Value | Means |
|---|---|
| `Confirmed` | You read the code, found no existing guard, and can state the trigger |
| `Likely` | The shape is wrong, but reachability or the guard search is unfinished |

Never label something `Confirmed` to make the report look stronger. One false `Confirmed` costs
more credibility than three honest `Likely`s.

### Severity

| Value | Means |
|---|---|
| `CRITICAL` | Data loss, authentication bypass, remote code execution, exposed live credentials |
| `HIGH` | Privilege escalation, injection, corruption under normal load, silent data loss |
| `MEDIUM` | Degradation at scale, missing isolation, weak defaults, gaps that hide other defects |
| `LOW` | Hardening with a real but small cost |

Judge by blast radius and reachability, not by how interesting the defect is. An unreachable
CRITICAL is a MEDIUM.

### Domain

`Security` · `Performance` · `Reliability` · `Testing` · `Tooling`

---

## 5. Rules that bind every writer

1. **Never renumber an ID.** Commits and conversations already cite them. After F1–F3 exist, the
   next is F4, even if one was withdrawn.
2. **Never delete an entry.** Mark it `withdrawn` with the reason.
3. **Never overwrite an existing `FINDINGS.md`.** Read it, take the next free ID, append.
4. **Never invent** a test number, a commit sha, or a severity. Read it, or ask.
5. **Never let the table drift** from the entries. Both, every time.
6. **Never print a full secret.** Truncate to the first four and last four characters.
7. **A finding without a trigger is a hunch.** Do not file a hunch.

---

## 6. Deferred entries

Findings diagnosed but not repaired. Same detail, minus the fix.

```markdown
### D1 — <title>

- **Location:** `path:line`
- **Severity:** <SEV>
- **Root cause:** ...
- **Trigger:** ...
- **Would fix by:** ...
- **Why deferred:** <lower severity than F1–F3, or a migration that did not fit the time>
```

State why. Deferring deliberately is a judgement call; leaving it unexplained looks like an
oversight.

---

## 7. Variant B — when the user was given an issue list

Add both tables above the summary. This is the artifact that shows judgement, because it
separates what they were told from what is actually wrong.

```markdown
## Their list vs. what is actually wrong

| Their issue | Reported symptom | Actual root cause | File | Status |
|---|---|---|---|---|
| #1 | Orders page slow | Lazy `Order.items`, N+1 at scale | `models.py:64` | fixed `abc1234` |
| #2 | Orders page slow on filter | Same cause as #1 | `models.py:64` | covered by #1 |
| #4 | Login sometimes fails | Not reproducible; see notes | — | not a bug |

## Not on their list

| # | Sev | Finding | File | Status |
|---|---|---|---|---|
| N1 | CRITICAL | `GetOrder` has no ownership check | `service.py:88` | fixed `def5678` |
```

The second table has five columns and no `Domain`. That is deliberate, not drift.

Two rows in that second table are worth more than five routine fixes from the first.
