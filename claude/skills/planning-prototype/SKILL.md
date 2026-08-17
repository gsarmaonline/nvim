---
name: planning-prototype
description: Build a throwaway prototype to answer one design question fast — isolated from production code, optimised for learning speed, and deleted or rewritten once the answer arrives. Use when the user is unsure which approach works, asks to try something quickly, or wants a spike to settle a design question.
---

You are invoked via the `/planning-prototype` skill. You build something **to learn from, not to keep**.

A prototype that quietly becomes production code is the failure mode this skill exists to
prevent. Build fast, learn, write down the answer, then throw the code away.

---

## The rule

> A prototype answers one question. Name the question before you write a line.

---

## Step 1 — Name the question and the exit

Ask the user, if it is not already clear:

- **The question.** What are we unsure about? Feasibility, performance, ergonomics, a library's
  behaviour, a user interaction?
- **The answer shape.** What result ends the prototype? A number, a working path, a screenshot,
  a "yes it composes"?
- **The time box.** How long is this worth? Say your estimate and get agreement.

Write these three lines at the top of the prototype directory in a `README.md`. If you cannot
write them, you are not prototyping — you are building, and this is the wrong skill.

---

## Step 2 — Isolate it

Put the prototype somewhere it cannot be mistaken for real code:

- `prototypes/<short-name>/` in the repository, or a scratch directory outside it.
- Never inside the production source tree.
- Never wired into the build, the CI, or the deployment.
- Never imported by real code.

Start the `README.md` with a loud line:

```
THROWAWAY PROTOTYPE — not production code. Answers: <the question>. Delete after <date>.
```

If the prototype must touch real systems, use read-only credentials and a non-production
environment. Never let a prototype write to production data.

---

## Step 3 — Build for learning speed

Deliberately skip what does not serve the question:

Skip — error handling, tests, logging, configuration, abstraction, naming discipline, edge
cases, security hardening, accessibility, cleanup, documentation beyond the README.

Keep — the one thing you are measuring, and enough realism that the answer transfers. A
performance prototype on toy data answers nothing. Use realistic data volume and shape.

Hard-code freely. Duplicate freely. Use the shortest path to a result.

Two limits on the shortcuts:
1. **Realism where the question lives.** Fake everything except the thing under test.
2. **No secrets, no production writes, no destructive commands** — the throwaway status does not
   relax these.

---

## Step 4 — Run it and record what you learn

Run the prototype. Capture the actual output — numbers, errors, screenshots.

Keep a running `FINDINGS.md` as you go. Record surprises immediately; they are the real product
of a prototype and they are easy to forget an hour later.

If the answer arrives early, stop. Do not polish.

If the time box expires without an answer, stop anyway. Report what you learned and what you
would try next. An expired prototype with an honest report is a success.

---

## Step 5 — Report and dispose

Report to the user:

```
QUESTION
  <the question>

ANSWER
  <yes / no / it depends — with the evidence: numbers, output, screenshot path>

WHAT SURPRISED ME
  <the findings that change the design>

WHAT THIS DOES NOT TELL US
  <the parts faked or skipped, and what they might hide>

IF WE BUILD IT PROPERLY
  <the real design this suggests — and what must be done differently from the prototype>

THE PROTOTYPE
  <path>  — throwaway; <delete | keep until <date> as a reference>
```

Then ask the user what to do with the code. Offer three options and recommend one:
1. Delete it now.
2. Keep it as a reference for a stated period, still isolated.
3. Rewrite it properly as real work — a new task, from the design, **not** by cleaning up the
   prototype.

Never migrate prototype code into production yourself. If the user asks for that, say plainly in
one sentence that a rewrite from the learning is safer, then do what they choose.
