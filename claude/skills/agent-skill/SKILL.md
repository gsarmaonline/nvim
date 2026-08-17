---
name: agent-skill
description: Create a properly structured agent skill — interview for the real workflow, write a focused SKILL.md with correct frontmatter and a discoverable description, then verify it loads
---

You are invoked via the `/agent-skill` skill. You help the user turn a workflow they repeat
into a **skill another agent session will find and follow correctly**.

Most bad skills fail in one of two ways: nobody triggers them, because the description is vague;
or the agent ignores them, because the body is a wall of generic advice. Guard against both.

---

## Step 1 — Interview

Ask the user, and do not start writing until you have answers:

1. **The trigger.** What would the user type or be doing when this should fire? Get their exact
   words, not a paraphrase.
2. **The workflow.** Walk me through it as you do it today, step by step.
3. **The output.** What exists at the end — a file, a commit, a report, a running service?
4. **The mistakes.** What goes wrong when you or an agent does this badly? This becomes the
   most valuable part of the skill.
5. **The rules.** What must always happen? What must never happen?
6. **The scope.** Personal (`~/.claude/skills/`) or this project (`.claude/skills/`)?

If the user gives a one-line request, ask questions 2 and 4 at minimum. A skill written from a
one-line request is generic, and a generic skill is worse than none.

---

## Step 2 — Decide whether it should be a skill

Say so plainly if it should not be. A skill is right when the workflow is **repeated**, has
**several steps**, and has **judgement or traps** worth encoding.

It is the wrong tool when:
- It is a single command → a shell alias or an allowed permission entry.
- It is a fact about the project → `CLAUDE.md`.
- It is an automatic behaviour on an event → a hook in `settings.json`.
- It runs once → just do the task.

---

## Step 3 — Structure

```
<skills-dir>/<skill-name>/
  SKILL.md            required
  reference.md        optional — detail loaded only when needed
  scripts/            optional — helper scripts the skill runs
  templates/          optional — files the skill copies or fills
```

Name the directory in kebab-case, verb-led where natural: `ship`, `to-issues`, `code-audit`.
The directory name and the frontmatter `name` must match.

Frontmatter:

```yaml
---
name: <kebab-case, matches the directory>
description: <what it does, and the situation that triggers it>
---
```

**The description is the whole discovery mechanism.** An agent sees only the name and the
description when deciding whether to load the skill. Write it to be matched.

- Weak: `Helps with database work`
- Strong: `Generate and apply a reversible database migration — write the up and down steps,
  test the rollback, and verify against a copy of production schema`

Include the concrete nouns a user would type. Say what it produces. When the trigger is
non-obvious, state it: "Use when the user asks to ...".

---

## Step 4 — Write the body

Write for an agent that will read this once, mid-task, and act.

Structure that works:

1. **One line on the role** — "You are invoked via `/<name>`. You do X."
2. **The rule** — the single principle, as a quotable line. An agent obeys one memorable rule
   better than ten paragraphs.
3. **Numbered steps** — the workflow, in order, each one actionable.
4. **The exact commands** — real, runnable, in fenced blocks.
5. **Output templates** — the shape of the report or file, as a template to fill.
6. **What not to do** — the mistakes from interview question 4, stated as prohibitions.
7. **When to stop and ask** — the cases where the agent must involve the user.

Rules for the writing:

- **Imperative, second person.** "Read the file", not "the agent should read the file".
- **Specific over complete.** Encode this workflow's judgement. Delete anything a competent
  agent already does.
- **Show the format, do not describe it.** A template beats a paragraph about the template.
- **Order matters.** Put the step that prevents damage before the step that does work.
- **Keep `SKILL.md` under roughly 500 lines.** Move depth into `reference.md` and point at it
  from the step that needs it.
- **No praise, no filler, no restating the description.**

---

## Step 5 — Verify

```bash
ls <skills-dir>/<skill-name>/SKILL.md
head -5 <skills-dir>/<skill-name>/SKILL.md
```

Check:
- [ ] Frontmatter is valid YAML, opened and closed with `---`.
- [ ] `name` matches the directory exactly.
- [ ] The description names the trigger and the output.
- [ ] Every command in the body is real and runs in this environment.
- [ ] Every referenced file exists.
- [ ] A cold reader could follow it without the conversation.

Then read your own skill as if you had never seen it, and answer: at step 3, would I know
exactly what to type? Fix whatever fails that test.

---

## Step 6 — Report

Tell the user:
- The path to the skill.
- How to invoke it (`/<name>`), and that a new session may be needed to pick it up.
- The one thing you were unsure about and guessed, so they can correct it.

Offer to run it once on a real case. A skill's first run finds more defects than any review.
