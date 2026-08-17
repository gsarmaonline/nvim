---
name: code-audit
description: Audit an existing codebase for real defects across security, performance, reliability, testing, and tooling — diagnose root causes, verify each finding against the source, and rank them for repair. Use when the user asks to audit a codebase, find the bugs or issues across a project, or review an unfamiliar repository for defects.
---

You are invoked via the `/code-audit` skill. Your task is to find genuine defects in an
existing codebase, prove each one against the source, explain the root cause, and rank them.

This skill does NOT change code. It produces a findings list. Use `/code-fix` to repair
one finding at a time.

Companion skills: `/code-map` maps the system first. `/code-security` runs a deeper
dependency and secret scan. Prefer `/code-security` when the request is purely about security.

---

## Ground rules

1. **A finding must be provable.** Every finding cites `file:line` and a concrete trigger. If
   you cannot write the trigger, it is not a finding — it is a hunch. Drop it.
2. **Report root causes, not symptoms.** "This endpoint is slow" is a symptom. "The `items`
   relationship loads lazily, so rendering N orders issues N+1 queries" is a root cause.
3. **No style opinions.** Naming, formatting, and personal preference are out of scope unless
   they cause a defect.
4. **Do not fix anything here.** Resist it. Mixing audit and repair loses both.
5. **Say what you did not cover.** An audit that hides its blind spots is misleading.

---

## Step 1 — Orient

If an architecture map already exists (`ARCHITECTURE_MAP.md` or similar), read it and start
from its **Suspicions** list. If not, spend five minutes on the cheap orientation:

```bash
ls -la && git log --oneline -15 2>/dev/null
git ls-files | wc -l
git ls-files | grep -E '(package\.json|pyproject\.toml|go\.mod|Cargo\.toml|moon\.ya?ml)$'
```

Identify the stacks in play. Then load `reference/checklists.md` from this skill directory and
select the checklist sections that apply.

Run the test suite once and record the baseline. You need to know what was already broken
before you claim anything.

---

## Step 1b — If someone already provided a list of issues

Check for one before you sweep:

```bash
gh issue list 2>/dev/null
git ls-files | grep -iE '(ISSUES|BUGS|TODO|TASKS)'
rg -n 'TODO|FIXME|HACK|XXX|BUG'
```

When a list exists — a tracker, a document, seeded TODO markers, or a deliberately red test
suite — it changes your method but not your job.

**A provided ticket is a symptom report written by somebody else.** It is evidence, not a
specification, and it may be wrong. Each one is exactly one of these, and you must prove which:

1. Correct, and it points at the real cause.
2. Correct about the symptom, wrong about the location. The cause lives elsewhere.
3. A duplicate of another ticket, already fixed, or not a defect at all.

Do this:

- **Reproduce each one first**, before reading the code around it. A ticket you cannot reproduce
  is itself a finding — record what you tried.
- **Collapse the list into root causes.** Ten tickets rarely mean ten defects. Stating that three
  of them share one cause shows more diagnostic depth than three separate repairs, and it saves
  time.
- **Ignore any fix the ticket proposes** until you have judged it. Tickets frequently suggest a
  repair that treats the symptom — a cache in front of an N+1 query, a retry around a race.
- **Still run the full sweep in Step 2.** Defects absent from their list are the most valuable
  thing you can report, because whoever wrote the list already knows what is on it.
- **Report the non-bugs**, with evidence. Never "fix" intended behaviour to close a ticket.

Structure the report around two tables: their list mapped to actual root causes, and a separate
table of what you found that they did not list.

---

## Step 2 — Sweep by domain

Cover all five domains. Do not stop at the first interesting bug — planted defects are usually
spread across domains on purpose.

| Domain | What you are hunting |
|---|---|
| Security | Authentication and authorization gaps, injection, weak crypto, exposed secrets, insecure transport |
| Performance | N+1 queries, missing indexes, unbounded results, work repeated in a loop, blocking calls on an async path |
| Reliability | Missing transactions, swallowed errors, absent timeouts, leaked sessions, race conditions, precision loss |
| Testing | Shared state between tests, mocks covering the code under test, missing assertions, untested critical paths |
| Tooling and CI | Broken task caching, missing task dependencies, unpinned dependencies, tests absent from CI, insecure container build |

`reference/checklists.md` holds the concrete grep patterns and the specific defect shapes for
each domain. Work through it — it is the substance of this skill.

**If subagents are available and the codebase is large,** run one agent per domain in parallel,
each returning findings as structured data. Then verify their claims yourself in Step 3. Never
put an unverified subagent claim into the report.

---

## Step 3 — Verify every candidate

For each candidate finding, open the cited file and confirm all four of these. Delete the
finding if any one fails.

1. **The code really says that.** Read the lines. Do not trust a grep match or a memory.
2. **There is no guard elsewhere.** Search for the protection you assume is missing. A
   middleware, an interceptor, a database constraint, or a caller-side check may already handle
   it. This step kills most false positives.
3. **You can state a trigger.** Concrete input or state, then the wrong behaviour. For example:
   "`GET /orders` with 200 rows issues 201 queries" or "user A sends `order_id` belonging to
   user B and receives it".
4. **It matters.** Assign real severity, based on blast radius and how reachable it is.

Then write the root cause in one sentence, and the smallest fix that addresses it.

---

## Step 4 — Rank

Sort by severity, then by confidence, then by repair cost.

| Severity | Meaning |
|---|---|
| CRITICAL | Data loss, authentication bypass, remote code execution, exposed live credentials |
| HIGH | Privilege escalation, injection, corruption under normal load, silent data loss |
| MEDIUM | Degradation at scale, missing isolation, weak defaults, gaps that hide other defects |
| LOW | Hardening, tidiness with a real if small cost |

Mark confidence as **Confirmed** (you read the code and the trigger holds) or **Likely** (the
shape is wrong but you could not fully verify the reachability). Never present Likely as
Confirmed.

---

## Step 5 — Write the findings file

Write `FINDINGS.md` at the repository root, or to the path the user names.

````markdown
# Findings — <repo name>

_Audit only. No code changed. <date>._

Baseline before audit: `<test command>` → <N passed, N failed>.

## Summary

| # | Severity | Domain | Finding | File | Confidence |
|---|---|---|---|---|---|
| 1 | CRITICAL | Security | ... | `path:line` | Confirmed |

## Coverage and blind spots
Audited: ...
Not audited, and why: ...

---

## F1 — <short title>

- **Severity:** CRITICAL
- **Domain:** Security
- **Location:** `path/to/file.py:42`
- **Confidence:** Confirmed

**What the code does**
```python
<the smallest quote that shows the defect>
```

**Root cause**
One or two sentences. Why the code is wrong, not just that it is.

**Trigger**
Concrete input or state, then the wrong result.

**Impact**
Who is affected, and how badly.

**Proposed fix**
The smallest change that removes the root cause. Note if it needs a migration or a staged
rollout, and say what preserves backwards compatibility.

**Test that would catch it**
The assertion that fails before the fix and passes after.
````

---

## Step 6 — Report

Speak a short summary: the counts per severity, the top three findings with one line each, the
baseline test state, and your blind spots.

Recommend an order of repair. Put the findings you can fix confidently and cheaply first, not
the most impressive ones. A thorough fix on two findings beats a shallow pass on five.

---

## Notes

- Never print a full secret. Truncate to the first four and last four characters.
- If a domain yields nothing, write "No issues found" for it. Silence reads as "not checked".
- When you are unsure whether something is a defect or a deliberate design choice, record it as
  a question rather than a finding, and say what would settle it.
