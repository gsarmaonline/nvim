---
name: zoom-out
description: Explain unfamiliar code by widening the frame — who calls it, what it exists for, where its data comes from and goes, and what would break if it changed
---

You are invoked via the `/zoom-out` skill. The user is staring at code they do not understand.
Your job is to give them the **surrounding picture**, not a line-by-line reading.

Line-by-line reading is what they can already do. What they lack is context.

---

## The rule

> Answer "why does this exist and who depends on it" before "what does line 12 do".

---

## Step 1 — Fix the focus

The target is whatever the user pointed at: a file, a function, a class, a directory, an error,
or a diff. If they pointed at nothing, ask.

Read the target in full first. Then stop reading it, and start reading around it.

---

## Step 2 — Zoom out in four rings

Work outward. Stop when the picture is enough to act on — usually ring 3.

**Ring 0 — the thing itself.** One paragraph. What it does, in the domain's words, not the
code's words. Its inputs, its outputs, its side effects.

**Ring 1 — the immediate neighbours.**
- Who calls it? Find every caller. Group them: production paths, tests, scripts, dead code.
- What does it call? Which of those calls cross a boundary — network, disk, database, process?
- What state does it read or write that outlives the call?

**Ring 2 — the subsystem.**
- Which subsystem owns this file, and what is that subsystem responsible for?
- Where does this sit in the request or data flow? Draw the path from entry point to here to
  exit.
- What is the sibling code that does the same kind of job? Reading a sibling often explains the
  target faster than the target does.

**Ring 3 — the system and its history.**
- Where does this sit in the whole application? Entry points, layers, boundaries.
- What does `git log` say? Look for the commit that introduced it and any commit that reverted
  or reworked it. The commit message often states the reason the code cannot.
- Is there a comment, an ADR, a README, or an issue that explains the design choice?
- Is there a constraint that explains an odd shape — a legacy format, a rate limit, a workaround
  for a dependency's bug?

**Ring 4 — only if asked.** Deployment, ownership, external consumers, roadmap.

---

## Step 3 — Report

Lead with the answer. Use this shape:

```
WHAT IT IS
  <one paragraph, domain language>

WHY IT EXISTS
  <the problem it solves; the evidence — commit, comment, doc, or "inferred from usage">

HOW IT FITS
  <the flow: entry -> ... -> this -> ... -> exit>

CALLERS
  <path:line — what that caller wants from it>

DEPENDS ON
  <what it needs, and which dependencies cross a boundary>

THE NON-OBVIOUS PARTS
  <the two or three things that would confuse a new reader, explained>

IF YOU CHANGE IT
  <what breaks, who notices, what to test>

WHERE TO LOOK NEXT
  <the two files that would deepen the picture most>
```

Draw a small ASCII diagram when the flow has more than three hops. Keep it under twelve lines.

---

## Rules

- **Cite everything.** `path:line` for each claim about the code.
- **Separate fact from inference.** Say "inferred" when you are reading intent from usage. Never
  present a guess about why the code exists as history.
- **Say when something is dead.** If the only callers are tests, say so — that is usually the
  most useful sentence in the report.
- **Name the surprises.** Anything that violates the pattern used elsewhere in the repository is
  worth a line, even when you cannot explain it.
- **Do not fix anything.** This skill explains. If you see a defect, note it in one line at the
  end and leave it.
