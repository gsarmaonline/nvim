---
name: blogify
description: Given a repo, task, or document, generate a well-structured technical blog post in Markdown
---

You are being invoked via the /blogify skill. Your task is to produce a high-quality technical blog post in Markdown format based on the provided input — which may be a repository, a completed task description, a document, or a combination.

The blog should read like the posts at **https://gauravsarma.com/blog**: conversational yet precise, problem-first, technically deep, and written for engineers who want to understand both the "what" and the "why".

---

## Step 1 — Understand the Subject

Determine what the blog post is about based on the user's input:

- **Repository**: Read `README.md`, `CLAUDE.md`, recent git log (`git log --oneline -20`), and key source files to understand what was built, the tech stack, and any architectural choices.
- **Task description**: Use the description directly; ask clarifying questions only if the subject is ambiguous.
- **Document**: Read and summarize the document's core content; identify the technical problem it addresses.

Identify:
1. The core problem being solved
2. The tech stack / tools / languages involved
3. Key technical decisions made and why
4. What was built or accomplished, step by step
5. Any non-obvious insights, trade-offs, or lessons learned

---

## Step 2 — Determine Output Location

Decide where to write the blog post:

- If a `docs/` directory exists → write to `docs/blog/<slug>.md`
- If a `blog/` directory exists → write to `blog/<slug>.md`
- Otherwise → write to `<slug>.md` in the project root

The slug should be a short kebab-case title derived from the topic (e.g., `building-a-rate-limiter-in-go.md`).

If the user specifies a path, use that instead.

---

## Step 3 — Write the Blog Post

Generate the blog post using the structure below. Follow the writing guidelines carefully.

### Writing Guidelines (inspired by gauravsarma.com/blog)

- **Problem-first**: Open with a real scenario, a pain point, or a question — not a definition.
- **Conversational but precise**: Write like you're explaining to a sharp colleague, not reading from a spec.
- **Show your thinking**: Include the "why" behind decisions, not just the "what".
- **Concrete over abstract**: Use real code snippets, commands, and examples wherever possible.
- **Honest about trade-offs**: Acknowledge what the approach doesn't do well.
- **No filler**: Avoid "In this blog post we will..." intros. Get to the point.

---

### Blog Post Structure

```markdown
# <Title: Direct, descriptive, action-oriented>

*<Date: YYYY-MM-DD>*

<Hook paragraph — 2-4 sentences. Start with a real problem, scenario, or question.
Do NOT start with "In this post...". Make the reader feel the pain before offering the solution.>

---

## The Problem

<Describe the specific problem being solved. Be concrete. What breaks, what's slow, what's
missing? Why does it matter? Reference real systems, numbers, or scenarios if available.>

---

## Prerequisites

<A brief, honest list of what the reader needs to know or have set up before following along.
Keep it tight — only list things that are actually required.>

- <Prerequisite 1>
- <Prerequisite 2>
- ...

---

## Technical Decisions

<Walk through the key decisions made during the build. For each decision:
- What options were considered?
- What was chosen and why?
- What trade-offs were accepted?

This section reveals the engineering judgment behind the work. It's often the most valuable part.>

### <Decision 1: e.g., "Why X over Y">

<Explanation...>

### <Decision 2>

<Explanation...>

---

## Implementation

<Step-by-step walkthrough of how it was built. Use subsections for major phases.
Include code snippets, commands, config examples, and diagrams where helpful.
Explain non-obvious choices inline.>

### <Phase 1: e.g., "Setting Up the Foundation">

<Explanation with code/commands...>

```<language>
<code snippet>
```

### <Phase 2>

<Explanation with code/commands...>

### <Phase 3>

...

---

## How It All Fits Together

<A brief synthesis section — describe the full picture now that all pieces are in place.
If helpful, include an architecture diagram in ASCII or describe the data/control flow.>

---

## Lessons Learned

<Honest reflections on what worked, what didn't, and what you'd do differently.
This is where technical writing earns trust. Don't oversell the outcome.>

---

## What's Next

<Optional: mention natural extensions, open questions, or follow-up work.
Keep brief — don't promise things that weren't built.>

---

## References

<Links to relevant documentation, papers, tools, or prior art referenced in the post.
Only include links that were genuinely useful — no padding.>

- [<Title>](<URL>)
```

---

## Step 4 — Code Snippet Standards

When including code in the post:
- Use proper fenced code blocks with language tags (` ```go `, ` ```bash `, ` ```yaml `, etc.)
- Keep snippets focused — show only the relevant portion, use `// ...` for omitted context
- Add inline comments to explain non-obvious lines
- For shell commands, use `$` prefix and show expected output where it helps

---

## Step 5 — Quality Checks

Before writing the file, verify:
- [ ] The intro starts with a problem or scenario, not a definition
- [ ] Every major technical decision includes a "why"
- [ ] Code snippets are accurate and relevant (pulled from actual source files when available)
- [ ] The prerequisites list is honest and complete
- [ ] Trade-offs are acknowledged somewhere in the post
- [ ] The post does not end abruptly — it has a natural close
- [ ] The slug and filename reflect the topic clearly

---

## Step 6 — Write and Confirm

1. Write the blog post to the determined output path using the Write tool
2. Print a summary to the user:

```
Blog post generated
===================

Title:  <title>
File:   <path/to/file.md>
Sections:
  ✓ Introduction
  ✓ The Problem
  ✓ Prerequisites
  ✓ Technical Decisions  (<N> decisions covered)
  ✓ Implementation       (<N> phases)
  ✓ Lessons Learned
  ✓ References           (<N> links)

Word count: ~<estimate>
```

---

## Important Notes

- **Do not fabricate details**: If source files, commits, or context are needed to write accurately, read them first using the Read, Glob, or Grep tools.
- **Prefer specificity over generality**: A post about "building a webhook delivery system" should name the retry strategy, queue type, and failure modes — not describe a generic webhook.
- **Match the audience**: Default to intermediate-to-senior engineers. Skip explaining what a Dockerfile is; do explain why you chose multi-stage builds.
- **Avoid hype**: No "blazing fast", "game-changing", or "revolutionary". Describe what it does and let the reader judge.
- If the user has not provided enough context to write accurately, ask for the repo path, task description, or relevant document before proceeding.
