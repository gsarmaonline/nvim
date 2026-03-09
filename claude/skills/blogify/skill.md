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
- **No em dashes**: Do not use em dashes (—) anywhere in the post. Use commas, colons, or restructure the sentence instead.

---

### Blog Post Structure

Every blog post MUST begin with this exact frontmatter block before any other content:

```markdown
---
title: <Title: Direct, descriptive, action-oriented>
description: >-
  <One-sentence description of what was built and what it does>
date: "<ISO 8601 timestamp, e.g. 2026-02-26T14:33:35.671331>"
categories: []
keywords: []
slug: >-
  <kebab-case-slug-matching-the-filename>
---
```

Then the post body follows (no `# Title` or `*Date*` line — those are in the frontmatter):

```markdown
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

## Step 5b — Generate Cover Image

After writing the post, create a cover image that visually represents the topic and embed it at the top of the post.

### Check if Remotion is available

```bash
cat package.json | grep remotion
```

**If Remotion is available**, create a title-card still image:

1. Write a temporary composition file `src/remotion/compositions/CoverImage.tsx` with this structure:

```tsx
import React from 'react';
import { AbsoluteFill } from 'remotion';

// Design tokens — match the blog's dark theme
const BG = '#0d1117';
const TEXT = '#e6edf3';
const MUTED = '#8b949e';
const ACCENT = '<choose a color that fits the topic>';
const FONT = 'system-ui, -apple-system, BlinkMacSystemFont, sans-serif';

export const CoverImage: React.FC = () => (
  <AbsoluteFill style={{ backgroundColor: BG, fontFamily: FONT, padding: '80px 100px', flexDirection: 'column', justifyContent: 'center' }}>

    {/* Category label */}
    <div style={{ color: MUTED, fontSize: 22, letterSpacing: '0.14em', textTransform: 'uppercase', marginBottom: 24 }}>
      <topic category, e.g. "Storage Internals Series">
    </div>

    {/* Title */}
    <div style={{ color: TEXT, fontSize: 72, fontWeight: 700, letterSpacing: '-0.02em', lineHeight: 1.15, marginBottom: 32 }}>
      <blog title>
    </div>

    {/* Visual element — pick one that fits the topic: */}
    {/* Option A: key terms/concepts as styled pills */}
    <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
      {['<concept 1>', '<concept 2>', '<concept 3>'].map((term, i) => (
        <div key={i} style={{ background: `${ACCENT}18`, border: `1px solid ${ACCENT}44`, borderRadius: 6, padding: '8px 18px', color: ACCENT, fontSize: 20, fontWeight: 500 }}>
          {term}
        </div>
      ))}
    </div>

    {/* Option B: a simple ASCII/box diagram inline if the topic has a clear structure */}
    {/* Option C: a comparison table with two columns */}

    {/* Bottom: site attribution */}
    <div style={{ position: 'absolute', bottom: 60, right: 100, color: MUTED, fontSize: 20, letterSpacing: '0.06em' }}>
      gauravsarma.com
    </div>
  </AbsoluteFill>
);
```

Design rules for the cover image:
- Use the same dark background `#0d1117` as the blog
- Choose an accent color that fits the topic (e.g. `#4fc3f7` for SQLite/databases, `#00ed64` for MongoDB, `#f0883e` for systems/infra)
- The visual element should be content-specific: key concepts as pills, a mini diagram, a comparison, or a formula — not just decorative shapes
- Font sizes: category label 22px, title 60–80px (adjust to fit in ~3 lines), pills/diagram text 18–22px
- Canvas: **1280×672** (standard OG image ratio, 1.9:1)

2. Register it in `src/remotion/Root.tsx`:

```tsx
<Composition
  id="CoverImage"
  component={CoverImage}
  durationInFrames={1}
  fps={30}
  width={1280}
  height={672}
  defaultProps={{}}
/>
```

3. Render the still (use `dangerouslyDisableSandbox: true` — Chrome download requires network access):

```bash
npx remotion still src/remotion/index.ts CoverImage public/images/<slug>-cover.png --frame=0
```

4. Read the output PNG with the Read tool and verify it looks correct before embedding.

5. Add the image to the blog post right after the frontmatter, before the opening hook paragraph:

```markdown
![<Blog title>](<slug>-cover.png)
```

6. Clean up: remove `CoverImage` from `Root.tsx` and delete `CoverImage.tsx` — it was a one-off render.

**If Remotion is NOT available**, skip the cover image and note it in the summary.

---

## Step 6 — Write and Confirm

1. Write the blog post to the determined output path using the Write tool
2. Print a summary to the user:

```
Blog post generated
===================

Title:  <title>
File:   <path/to/file.md>
Cover:  public/images/<slug>-cover.png  (or "skipped — Remotion not available")
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
