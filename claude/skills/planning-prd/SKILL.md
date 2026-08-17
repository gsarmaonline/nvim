---
name: planning-prd
description: Turn the conversation into a structured product requirements document — problem, users, scope, requirements, success measures, risks, and open questions, with every gap marked instead of invented. Use when the user asks for a PRD, a requirements document, or wants what was discussed written up as a spec.
---

You are invoked via the `/planning-prd` skill. You convert what this conversation has established into
a **product requirements document** that a designer, an engineer, and a reviewer can all work
from.

---

## The rule

> Write what was decided. Mark what was not. Invent nothing.

Every PRD generated from a conversation has holes, because conversations are partial. A hole
marked `OPEN` is useful. A hole filled with a plausible guess is a defect that ships.

---

## Step 1 — Harvest the conversation

Re-read the whole conversation. Extract and separate:

- **Decided** — the user stated it or approved it.
- **Implied** — it follows from what the user said, but they never said it. Mark it.
- **Missing** — the document needs it and the conversation never touched it.

Also read any file, issue, or document the conversation referenced. Ground the PRD in the real
system where you can.

---

## Step 2 — Ask the blocking questions

Before writing, ask the user the small number of questions where a wrong assumption would make
the document useless. Usually two to four:

- Who is the primary user, and what do they do today instead?
- What does success look like, in a number?
- What is explicitly out of scope for this version?
- Is there a deadline or a constraint that shapes the solution?

Ask them together, briefly. Then write. Do not stall the whole document on a minor unknown —
mark minor unknowns `OPEN` and continue.

---

## Step 3 — Write the document

Write to `PRD.md` unless the user names a path. Use this structure. Delete a section only if it
genuinely does not apply, and say which you deleted.

```markdown
# <Product or feature name>

**Status:** Draft   **Date:** <YYYY-MM-DD>   **Author:** <user>

## 1. Summary
<three sentences: what this is, who it serves, why now>

## 2. Problem
<the user's problem in their terms, with evidence. What do they do today, and what does that
cost them? No solution language in this section.>

## 3. Users
| User | Need | Today's workaround |
|---|---|---|

## 4. Goals
<what this must achieve — outcomes, not features>

## 5. Non-goals
<what this deliberately does not do, and why. This section prevents the most rework.>

## 6. Requirements

### Functional
| ID | Requirement | Priority | Notes |
|---|---|---|---|
| FR-1 | <the system shall ...> | Must / Should / Could | |

### Non-functional
<performance, scale, availability, security, privacy, accessibility, compliance — with numbers>

## 7. User journeys
<the two or three main paths, step by step, including the failure path>

## 8. Success measures
| Measure | Baseline | Target | How measured |
|---|---|---|---|

## 9. Scope and phasing
**V1:** <the smallest useful release>
**Later:** <what waits, and what would trigger it>

## 10. Dependencies and constraints
<teams, services, data, budget, legal, existing systems>

## 11. Risks
| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|

## 12. Open questions
| # | Question | Blocks | Owner | Needed by |
|---|---|---|---|---|

## 13. Assumptions
<every "implied" item from Step 1, listed plainly as an assumption to confirm>
```

---

## Quality rules

- **Requirements are testable.** "The system shall respond within 300 ms at the 95th percentile
  for up to 1,000 concurrent users" — not "the system shall be fast".
- **One requirement per row.** A row containing "and" is usually two rows.
- **Priorities are honest.** If everything is a Must, nothing is. Push back once if the user
  marks the whole list Must.
- **Problem section names no solution.** If the problem statement mentions the feature, it is a
  solution statement wearing a disguise.
- **Mark every gap.** Use `OPEN:` inline wherever a value is unknown, and repeat it in section
  12. Never leave a plausible placeholder unmarked.

---

## Step 4 — Report

Tell the user:
- Where the document is.
- The open questions that block the most, in priority order.
- Any assumption you had to record that they should confirm before this goes to anyone else.
