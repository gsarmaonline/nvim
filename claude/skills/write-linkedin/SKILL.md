---
name: write-linkedin
description: Generate a LinkedIn post for a specified blog post, matching the writing style of existing LinkedIn posts
---

You are being invoked via the /write-linkedin skill. Your task is to generate a LinkedIn post that introduces and promotes a specified blog post, matching the writing style of existing LinkedIn posts in `blogui/content/linkedin/`.

---

## Step 1 — Identify the Blog Post

The user will provide either:
- A blog post filename or slug (e.g., "table-per-tenant-vs-shared-table")
- A blog post URL (e.g., "https://www.gauravsarma.com/posts/...")
- A topic description that matches a recent blog post

Find the corresponding blog post in `blogui/content/posts/`. Read it fully to understand the content.

If the user's input is ambiguous, list the most recent blog posts and ask which one they mean.

---

## Step 2 — Study the Existing LinkedIn Style

Read 4-5 existing posts from `blogui/content/linkedin/` to calibrate the voice and structure. The posts follow several distinct patterns depending on the topic:

### Pattern A: "Technical deep-dive teaser" (most common)
Used for database internals, systems, and storage posts. Structure:
1. Open with a bold, surprising claim or scenario (1-2 lines)
2. Explain the core mechanism in accessible terms (1-2 paragraphs)
3. Drop specific numbers or examples that make the reader go "wait, really?"
4. "A few things that surprised me while writing this:" section with 2-4 items prefixed by → arrows
5. Practical takeaways or fixes (1-2 sentences)
6. Link to the blog post
7. Close with "Do give it/this a read and happy learning!" or similar

Example posts: `sqlite-overflow-pages.md`, `data-structures-behind-text-editors.md`

### Pattern B: "Problem-first narrative"
Used for architectural/philosophical posts. Structure:
1. Open with a relatable problem or observation (1-3 sentences)
2. Brief context on why you investigated this
3. Numbered list of key findings or techniques (3-5 items)
4. "All N of them have their pros and cons" or similar bridge
5. Link to the blog post
6. Close with "Do give it a read and happy learning!"

Example posts: `checkpointing-without-stop-the-world.md`, `how-split-brain-happens.md`

### Pattern C: "Personal investigation"
Used when the post came from personal curiosity or a paper. Structure:
1. Open with how you encountered the topic
2. Describe the learning journey briefly
3. What you learned or built
4. Link to the blog post
5. Close with a recommendation for who would enjoy it

Example posts: `how-robots-see-without-lidar.md`, `mongo-write-operations.md`

### Writing Rules (apply to ALL patterns)

- **First person, conversational tone.** Write as yourself sharing something you learned or built.
- **No hashtags.** None. Ever.
- **No emojis.** Unless the existing posts use them (they don't).
- **No em dashes.** Use commas, colons, or restructure.
- **Short paragraphs.** 1-3 sentences max per paragraph. LinkedIn renders poorly with long blocks.
- **Concrete over abstract.** Use specific numbers, system names, and technical details. Avoid generic statements like "performance matters."
- **The "surprised me" pattern.** If the blog has non-obvious insights, use the "→" arrow list. This is a signature element of the LinkedIn posts.
- **Link placement.** The blog URL goes near the end, not the beginning. Build interest first.
- **Closing line.** Always end with a variation of "happy learning!" or "happy reading!" or "do give it a read!"
- **Length.** Aim for 150-300 words. Long enough to teach something, short enough to read in 30 seconds.
- **Blog URL format.** Use the gauravsarma.com URL: `https://www.gauravsarma.com/posts/<slug>`
  - The slug comes from the blog post's frontmatter `slug` field

---

## Step 3 — Write the LinkedIn Post

1. Choose the pattern (A, B, or C) that best fits the blog content
2. Draft the post following that pattern's structure and the writing rules
3. Make sure the post teaches something standalone. A reader who never clicks the link should still learn one concrete thing.
4. Do NOT summarize the entire blog. Tease the most interesting parts. Leave the reader wanting more.

---

## Step 4 — Save the Post

1. Derive a short kebab-case filename from the blog topic (e.g., `table-per-tenant.md`, `cdc-as-a-crutch.md`)
2. Write the LinkedIn post as a plain markdown file (NO frontmatter) to `blogui/content/linkedin/<filename>.md`
3. The file should contain ONLY the post text, no metadata, no title headers

---

## Step 5 — Confirm

Print a summary:

```
LinkedIn post generated
=======================

Blog:     <blog post title>
File:     blogui/content/linkedin/<filename>.md
Pattern:  <A/B/C> — <pattern name>
Words:    ~<count>
URL used: <blog URL>
```

---

## Important Notes

- **Do not fabricate blog content.** Read the actual blog post before writing. The LinkedIn post must accurately reflect what the blog covers.
- **Do not over-promote.** The tone is "I learned something interesting and want to share it," not "check out my amazing blog post."
- **Match the voice.** These posts sound like a curious engineer sharing notes with peers, not a content marketer optimizing for engagement.
- **No LinkedIn-style engagement bait.** No "Agree? 👇", no "Share if you found this useful", no "Follow me for more." Just share the knowledge and sign off.
