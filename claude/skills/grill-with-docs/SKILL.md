---
name: grill-with-docs
description: Challenge a plan against the project's own documentation — find where the plan contradicts the docs, where the docs are stale, and which claims neither source supports
---

You are invoked via the `/grill-with-docs` skill. You test a plan against **what this project
has already written down**, and you report every place the two disagree.

This is the evidence-based sibling of `/grill-me`. That skill attacks a plan from first
principles. This one attacks it with citations.

---

## The rule

> Every objection carries a file path and a line number, or it is not an objection.

You may say "the docs do not cover this". You may not say "I think the convention is X" without
showing where X is written.

---

## Step 1 — Fix the target

Restate the plan in three to six bullets and confirm it with the user. If no plan is in context,
ask for one.

---

## Step 2 — Build the document set

Search the repository. Read what you find. Cover, at minimum:

- `README*`, `CONTRIBUTING*`, `CLAUDE.md`, `AGENTS.md`
- `docs/`, `doc/`, `documentation/`, `rfcs/`, `adr/`, `design/`
- `ARCHITECTURE*`, `CHANGELOG*`, `MIGRATION*`, `SECURITY*`
- Package and tool configuration that encodes a rule — lint configuration, CI workflows,
  `Makefile`, `justfile`, formatter settings
- Schema, migration, and API specification files
- Long-form comments at the top of the modules the plan touches

Also read the code the plan touches. Documentation lies; code does not. When they disagree, the
disagreement is itself a finding.

If the project has almost no documentation, say so immediately and ask whether to continue with
code and configuration as the source of truth.

List what you read before you start grilling. The user must be able to see your evidence base
and correct it.

---

## Step 3 — Grill against the evidence

Work through the plan step by step. For each step ask three questions privately:

1. **Does a document forbid this?** A stated convention, a rejected alternative in an ADR, a
   security rule, a deprecation notice.
2. **Does a document require something this step skips?** A migration checklist, a required
   review, a compatibility window, a test tier.
3. **Does a document describe a system that no longer exists?** If the plan matches the docs but
   the code has moved on, the docs are the defect.

Ask the user **one question per turn**, and attach the citation.

Weak: "This may conflict with your conventions."
Strong: "`docs/adr/0012-no-shared-cache.md:31` rejects a shared cache for exactly this service.
Step 3 adds one. What changed since that decision?"

Follow the same loop discipline as `/grill-me`: one question, wait, follow the weakness, accept
good answers fast, ask for numbers, track the damage.

When the user's answer contradicts a document, ask which one is now wrong — the plan or the
document. Both answers create work, and the user should choose deliberately.

---

## Step 4 — Report

```
DOCUMENTS READ
  <path — what it governs>

CONTRADICTIONS  (plan vs docs)
  <plan step> vs <path:line> — <what disagrees> — <who is wrong, per the user>

STALE DOCUMENTATION  (docs vs code)
  <path:line> — <what it claims> — <what the code does now>

UNCOVERED
  <plan steps no document governs — these need a decision recorded>

REQUIRED BY DOCS, MISSING FROM PLAN
  <checklist items, review gates, migration steps the plan skipped>

DOC UPDATES THIS PLAN OWES
  <the documents that must change if this plan lands>
```

Finish with a one-line verdict: does the plan fit this project as documented, and what must
change first.

---

## Notes

- Quote exactly. Paraphrasing a document to fit your objection is the worst failure mode here.
- A convention followed everywhere in the code but written nowhere is still evidence — cite the
  code paths and label it "unwritten convention".
- If a document is ambiguous, show both readings and ask the user which one governs.
