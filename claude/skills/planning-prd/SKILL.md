---
name: planning-prd
description: Turn the conversation into a structured product requirements document plus a companion design document — problem, users, scope, requirements, success measures, risks, open questions, and the objects, schema and services that carry them, with every gap marked instead of invented. Use when the user asks for a PRD, a requirements document, a spec, or wants the data model and services written up alongside it.
---

You are invoked via the `/planning-prd` skill. You convert what this conversation has established into
**two documents** that a designer, an engineer, and a reviewer can all work from:

- `PRD.md` — what must be true. Requirements.
- `DESIGN.md` — the objects, schema and services proposed to make it true.

**They are separate on purpose.** A PRD states what the system must do; a schema is one way of
doing it. A table inside a requirements document reads as a requirement, and then nobody feels
free to reject it. Keep the requirement in `PRD.md` and the proposal in `DESIGN.md`, and make
every object in the second cite the requirement in the first that it serves.

Write `DESIGN.md` whenever the conversation established enough to propose objects — which is
almost always, because a conversation that produced requirements has usually named the nouns
too. Skip it only when the work is genuinely not software with state, and say that you skipped
it.

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

Then harvest the **nouns** separately, for `DESIGN.md`:

- Every object the conversation named, and what it holds.
- Every boundary — what may know about what, and what may not.
- Every thing that runs as a process.
- Every rule that constrains the shape (a default that must be safe, a field that must never be
  blanked, a value that must outlive something else).

Also read any file, issue, or document the conversation referenced. Ground both documents in the
real system where you can. If code already exists, read the types — a design document that
contradicts the code on disk is worse than none.

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

## 14. Design
<one paragraph: the shape proposed to meet these requirements, and a pointer to DESIGN.md.
Not the schema itself — a reader who wants the objects follows the link.>
```

---

## Step 3b — Write the design document

Write to `DESIGN.md` beside the PRD. Same rule: write what was decided, mark what was not,
invent nothing. The difference is that this document is **proposed** rather than required, and
it must say so in its own status line — an engineer must feel free to reject a table here in a
way they would not feel free to reject a requirement.

```markdown
# <Product or feature name> — objects and schema

**Status:** Proposed   **Date:** <YYYY-MM-DD>   **Author:** <user>
**Companion to:** PRD.md

## 1. Modules
<the units of code, what each owns, and the direction dependencies point. State the rule —
"nothing points left" — and say whether a test enforces it. Mark which modules exist today and
which are planned.>

## 2. Core types
<per module: each type, one line on what it is, and the requirement it serves. Show real
declarations for the types that carry a rule; a table is enough for the rest.

Every field that had to be thought about gets a comment saying why: a zero value that must be
the safe one, a pointer that exists to tell unset from empty, a value carried rather than
derived.>

## 3. Persistence
<the schema, in the real DDL or the real document shape. Every field, its type, and — where it
is not obvious — why it exists.

Every index names the query it serves. An index with no named query is a guess.
Every constraint names the defect it prevents.>

## 4. Services
<what runs as a process, what talks to what, and how they are packaged. A diagram if it helps.
Say what a small deployment collapses into.>

## 5. Interfaces
<the boundary a consumer codes against: endpoints, events, the public interface. Not the
internals — the surface somebody else depends on and you cannot change quietly.>

## 6. What is not here
| Not present | Why |
|---|---|
<objects deliberately absent, each citing the non-goal or requirement that excludes it. This
table is not optional. It is what stops somebody adding a tenant column back in six weeks.>

## 7. Open
<every `OPEN:` from above, collected, cross-referenced to the PRD's open questions where they
are the same question.>
```

---

## Quality rules

### For the PRD

- **Requirements are testable.** "The system shall respond within 300 ms at the 95th percentile
  for up to 1,000 concurrent users" — not "the system shall be fast".
- **One requirement per row.** A row containing "and" is usually two rows.
- **Priorities are honest.** If everything is a Must, nothing is. Push back once if the user
  marks the whole list Must.
- **Problem section names no solution.** If the problem statement mentions the feature, it is a
  solution statement wearing a disguise.
- **Mark every gap.** Use `OPEN:` inline wherever a value is unknown, and repeat it in section
  12. Never leave a plausible placeholder unmarked.

### For the design document

- **Every object cites the requirement it serves.** An object that cites nothing is one of two
  things: a missing requirement, or speculation. Say which — do not leave it uncited and hope.
- **Do not invent fields.** A table whose columns the conversation never described is
  `OPEN:`, not a guess with plausible names. Guessed column names are the hardest kind of
  invention to spot later, because they read as decided.
- **The non-goals govern the schema.** No object for a feature PRD §5 excluded. If the schema
  needs one, the non-goal is wrong and you say so rather than quietly adding the column.
- **Name every deliberate default.** Where a zero value had to be the safe one — the visibility
  that must default to private, the state that must default to live — say so at the field. A
  reordered `const` block reverses those silently.
- **Match the code that exists.** If types are already written, read them and cite the file. A
  design document that contradicts the code on disk is worse than no design document.
- **Say what collapses.** Note where a small deployment runs one process instead of three, so
  nobody builds for a scale PRD §6 did not ask for.

---

## Step 4 — Report

Tell the user:
- Where both documents are.
- The open questions that block the most, in priority order.
- Any assumption you had to record that they should confirm before this goes to anyone else.
- Anything in `DESIGN.md` you proposed rather than harvested — the objects nobody asked for that
  the requirements seemed to need. Those are the ones most likely to be wrong, and naming them
  is what makes the document reviewable rather than merely readable.
