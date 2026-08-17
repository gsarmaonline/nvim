---
name: code-trace
description: Trace one function, endpoint, or symbol end to end — who calls it, what it calls, how data moves through it, what state it touches, and what breaks if it changes. Use when the user points at code and asks what it does, where it is used, how a value gets there, or what depends on it.
---

You are invoked via `/code-trace`. The user is pointing at one thing — a function, an endpoint, a
class, a variable, an error. They want the **surrounding picture and the flow**, not a
line-by-line reading of what is in front of them.

Line-by-line reading is what they can already do. What they lack is context and direction.

Use `/code-map` instead when the question is about the whole system rather than one symbol.

---

## The rule

> Answer "why does this exist and who depends on it" before "what does line 12 do".

---

## Step 1 — Fix the target

The target is whatever the user pointed at. If they pointed at nothing, ask once.

Read the target in full. Then stop reading it, and start reading around it.

Decide which direction they need. Say which you chose.

| They asked | Direction |
|---|---|
| "what does this do", "why does this exist" | Both, context first |
| "where is this used", "what breaks if I change it" | Upstream — callers |
| "where does this value come from" | Upstream — data provenance |
| "what happens after this", "where does it end up" | Downstream — data destination |
| "how does a request get here" | Full path, entry point to exit |

---

## Step 2 — Trace the callers, upstream

Find every caller. Do not stop at the first one.

```bash
rg -n '\b<name>\b' --type-add 'src:*.{py,ts,tsx,js,jsx,go,rs}' -tsrc
rg -n 'import.*<name>|from .* import .*<name>|require\(.*<name>'
```

Group what you find:
- **Production paths** — reached by a real request or job.
- **Tests only** — say this plainly. If tests are the only callers, that is usually the single
  most useful sentence in your report.
- **Scripts and tooling.**
- **Dead** — no reachable caller at all.

Watch for callers that static search will miss: dynamic dispatch, a registry or plugin table,
a string name in configuration, a decorator that registers the function, reflection, a generated
client, or a route table built at runtime. Search the configuration and the registration sites,
not only the code.

For each caller, record what it wants from the target. That is the real contract, and it is often
narrower than the signature suggests.

---

## Step 3 — Trace the data, downstream

Follow the values, not only the calls. For each parameter and each return path, answer:

- **Where does it originate?** A request field, a database row, an environment variable, a
  literal, a computed default. Walk back until you reach a boundary.
- **What transforms it?** Note every place the value is parsed, coerced, defaulted, truncated,
  rounded, or renamed. Defects hide in these steps.
- **Where does it end up?** A response, a database write, a log line, a queue, an outbound call,
  a file, a cache.
- **Is it validated, and where?** Name the exact place. "Validated somewhere upstream" is not an
  answer.

Mark every boundary the flow crosses — network, disk, database, process, trust. A trust boundary
matters most: that is where unvalidated input becomes trusted state.

---

## Step 4 — Map the state and the side effects

- What does it read or write that outlives the call? Database rows, cache entries, module-level
  variables, files, external services.
- Is it idempotent? What happens if it runs twice with the same input?
- Does it hold a lock, open a transaction, or depend on being inside one opened by a caller?
- What does it do on the error path? What is left half-written if it fails midway?
- Is it safe to call concurrently? Name the shared state if not.

---

## Step 5 — Widen, only as far as needed

Stop as soon as the picture is enough to act on. Usually that is ring 2.

**Ring 0 — the thing itself.** One paragraph, in the domain's words rather than the code's.

**Ring 1 — the neighbours.** Callers, callees, and which calls cross a boundary.

**Ring 2 — the subsystem.** Which subsystem owns it and what that subsystem is responsible for.
Where it sits in the request or data flow. The sibling code doing the same kind of job — reading
a sibling often explains the target faster than the target explains itself.

**Ring 3 — the system and its history.** Entry points and layers. Then `git log`:

```bash
git log --oneline -- <path>
git log -S '<symbol>' --oneline          # commits that added or removed the symbol
git log -p -1 --format='%an %ad%n%s%n%b' -- <path>
```

The commit that introduced the code often states the reason the code itself cannot. Look for a
revert or a rework — those mark a constraint someone discovered the hard way. Check for an ADR,
a README, or a linked issue.

**Ring 4 — only when asked.** Deployment, ownership, external consumers.

---

## Step 6 — Report

Lead with the answer. Drop any section that does not apply.

```
WHAT IT IS
  <one paragraph, domain language>

WHY IT EXISTS
  <the problem it solves; the evidence — commit, comment, doc, or "inferred from usage">

HOW IT FITS
  <the flow: entry -> ... -> this -> ... -> exit>

CALLERS
  <path:line — what that caller wants from it>
  <production / tests only / dead>

DATA IN
  <parameter — origin — validated at path:line, or NOT VALIDATED>

DATA OUT
  <return or side effect — where it lands>

STATE AND SIDE EFFECTS
  <what outlives the call; transaction and lock behaviour; idempotency>

THE NON-OBVIOUS PARTS
  <the two or three things that would confuse a new reader, explained>

IF YOU CHANGE IT
  <what breaks, who notices, what to test>

WHERE TO LOOK NEXT
  <the two files that would deepen the picture most>
```

Draw a small ASCII diagram when the flow has more than three hops. Keep it under twelve lines.

```
POST /orders
  └─ auth_interceptor        interceptors.py:22   ← trust boundary
     └─ OrderService.create  service.py:41
        ├─ validate_items    schema.py:18
        └─ session.add       models.py:64         ← writes orders, items
           └─ emit_receipt   billing.py:9         ← network, no timeout
```

---

## Rules

- **Cite everything.** `path:line` for every claim about the code.
- **Separate fact from inference.** Say "inferred" when you are reading intent from usage. Never
  present a guess about why code exists as if it were history.
- **Say when you could not follow something.** Dynamic dispatch, a generated client, or an
  external service ends the trace. Name where you stopped rather than inventing the next hop.
- **Say when something is dead.** Tests-only callers, or none at all.
- **Name the surprises.** Anything that breaks the pattern used elsewhere deserves a line, even
  when you cannot explain it.
- **Do not fix anything.** This skill explains. If you see a defect, add one line at the end and
  leave it. File it with `/code-finding`, repair it with `/code-fix`.
