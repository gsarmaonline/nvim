---
name: agent-review-skills
description: Audit the whole skill library — check that every skill is structurally valid, correctly namespaced, and free of broken cross-references, then report the skills that belong to no category and propose a home for each. Use when the user asks to review, tidy, or re-categorise their skills.
---

You are invoked via `/agent-review-skills`. You audit the **skill library itself**, the way
`/code-audit` audits a codebase.

You report. You do not rename anything without asking — a rename costs the user their muscle
memory, so it is their call every time.

---

## The rule

> A prefix with one member is not a category. A skill in no category is not organised.

---

## Step 0 — Locate the library

```bash
SK=$(readlink ~/.claude/skills || echo ~/.claude/skills)
echo "$SK"; ls -d "$SK"/*/ | wc -l
```

Also check for project-level skills in `.claude/skills/` under the current repository, and say
which library you audited. Audit both when both exist, and keep them separate in the report.

---

## Step 1 — Structural integrity

Every skill must satisfy all of these. Report each failure with the skill name.

Read only the **frontmatter block** — the lines between the first `---` and the second. A skill
body often contains template examples with their own `name:` and `description:` lines, and
scanning the whole file reports those as duplicates.

```bash
cd "$SK"
for d in */; do
  x=${d%/}
  f=$(ls "$x" | grep -i '^skill\.md$' | head -1)
  [ -z "$f" ] && { echo "NO SKILL FILE   $x"; continue; }
  [ "$f" != "SKILL.md" ] && echo "LOWERCASE FILE  $x/$f"
  head -1 "$x/$f" | grep -q '^---$' || { echo "NO FRONTMATTER  $x"; continue; }
  fm=$(awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f' "$x/$f")
  [ -z "$fm" ] && { echo "UNCLOSED FRONTMATTER  $x"; continue; }
  nm=$(printf '%s\n' "$fm" | grep -m1 '^name:' | awk '{print $2}')
  [ "$nm" = "$x" ] || echo "NAME MISMATCH   dir=$x name=$nm"
  printf '%s\n' "$fm" | grep -q '^description:' || echo "NO DESCRIPTION  $x"
  printf '%s\n' "$fm" | grep -qiE 'use when|when the user' || echo "NO TRIGGER      $x"
done
```

**No trigger** is a warning, not a failure. The description is the only thing an agent sees when
deciding whether to load a skill without being told its name. A description that states what the
skill produces but never the situation that calls for it will only fire when the user types the
name.

What each failure costs:

- **Lowercase `skill.md`** — loads on macOS, fails on Linux. A latent portability defect, and it
  is invisible until the library moves.
- **Name mismatch** — the skill may not resolve when invoked by name.
- **Missing or unclosed frontmatter** — the skill does not load at all.
- **No description** — the skill exists but nothing will ever trigger it.

---

## Step 2 — Namespace categorisation

Derive the groups from the library itself. Do not hardcode them; the library changes.

```bash
ls -d */ | tr -d '/' | sed -n 's/^\([a-z][a-z0-9]*\)-.*/\1/p' | sort | uniq -c | sort -rn
ls -d */ | tr -d '/' | awk '!/-/'              # single-word names, definitionally unprefixed
```

Classify every skill into one of four buckets:

| Bucket | Meaning |
|---|---|
| **Categorised** | Its prefix names a group with two or more members |
| **Orphan** | No prefix, or a prefix nothing else shares |
| **Lone prefix** | A prefix with exactly one member — a group that never formed |
| **Misfiled** | Its prefix does not match what the description says it does |

**Misfiled is the finding that matters most**, and the only one needing judgement. Read the
description, not the name. A skill named `code-something` that produces a document for a human,
or a `planning-` skill that edits files, is in the wrong group. Say which group it belongs in and
why, in one line.

---

## Step 3 — Propose a home for each orphan

For every orphan, give exactly one of these verdicts. Never leave one unclassified.

1. **Move to an existing group** — name the group and the new skill name.
2. **Start a new group** — only when two or more orphans share a purpose. Name the prefix and
   list its members. One skill never justifies a new prefix.
3. **Legitimately standalone** — a tool-specific or one-of-a-kind skill. Say why it does not
   group, so the next audit does not re-raise it.

Be honest about verdict 3. Forcing a singleton into a group to make the table look tidy makes the
library worse, not better.

---

## Step 4 — Reference integrity

A rename breaks every mention of the old name inside other skills. Find them.

```bash
# every slash-token that appears in a skill-reference context
grep -rnE '(`/[a-z][a-z0-9-]*`|/[a-z][a-z0-9-]* skill|[Ii]nvoke the `?/[a-z])' . \
| grep -oE '/[a-z][a-z0-9-]*' | sed 's|^/||' | sort -u
```

Compare that list against the real skill names plus the Claude Code built-ins:

```
code-review  simplify  security-review  run  init  loop  schedule  dataviz
claude-api  update-config  keybindings-help  fewer-permission-prompts
artifact-design  artifact-diagramming  artifact-capabilities
```

Report anything that resolves to neither. Ignore matches that are plainly URL paths, API routes,
or CLI flags — `/health`, `/api/users`, `/metrics`. Read the line before you flag it.

Also check each skill's own opening line. "You are invoked via `/X`" must name that same skill.
A stale self-reference is the most common leftover after a rename.

---

## Step 5 — Overlap and collision

- **Two skills, one trigger.** Read the descriptions. When two would fire on the same request,
  say which should win and why, and propose either a merge or a sharper boundary in one of the
  descriptions.
- **Shadowing a built-in.** A local skill with the same name as a built-in replaces it. Name what
  the user loses. `code-review` is the one that costs the most, because its `ultra` mode has no
  local equivalent.
- **Weak descriptions.** The description is the whole discovery mechanism. Flag any that fails
  both tests: does it name the situation that triggers it, and does it name what it produces?

---

## Step 6 — Report

```
SKILL LIBRARY  <path>
  34 skills   6 groups   4 orphans

STRUCTURE
  LOWERCASE FILE   12   write-blog, scaffold-app, ...     (fails on Linux)
  NAME MISMATCH     0
  NO DESCRIPTION    0

GROUPS
  /code-       14   ok
  /planning-    4   ok
  /pr-          3   ok
  /agent-       3   ok
  /scaffold-    3   ok
  /write-       3   ok

ORPHANS
  moonrepo    standalone — tool-specific, nothing else covers moon
  caveman     → /agent-caveman   (it configures how the agent writes)
  handoff     → /write-handoff   (it produces a document)
  teach       standalone — no sibling

MISFILED
  <skill> is in /X but does <Y> — belongs in /Z

BROKEN REFERENCES
  <skill>:<line> refers to /<name>, which does not exist

OVERLAPS
  <a> and <b> both fire on "<request>" — <which should win>

RECOMMENDED, IN ORDER
  1. <the change with the largest effect>
```

Rank the recommendations by effect, not by how easy they are. Put structural failures above
categorisation, because a skill that does not load is worse than one that is filed oddly.

---

## Step 7 — Offer, do not act

End by offering to apply the changes. Wait for the user to choose which.

When they approve a rename, do all four parts or none:

1. `mv <old> <new>`
2. Update the `name:` in the frontmatter — it must match the directory.
3. Update every `/old-name` inside that skill, including the opening line.
4. Update every reference in **other** skills, and in any workspace docs or memory files that
   mention it.

Then re-run Steps 1 and 4 to prove nothing broke.

---

## Never

- **Never rename without approval.** The user pays the cost in muscle memory.
- **Never invent a group for one skill.** Two members minimum, always.
- **Never flag a legitimate standalone twice.** Record why it stands alone so the next audit
  leaves it alone.
- **Never fix a lowercase filename silently.** On a case-insensitive filesystem the rename needs
  two steps, and it shows in git history as a change the user did not ask for.
- **Never judge a skill by its name.** Read the description and the body.
