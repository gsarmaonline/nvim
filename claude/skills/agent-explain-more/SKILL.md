---
name: agent-explain-more
description: Expand the previous reply with the reasoning, evidence and mechanism that were compressed out of it. Use when the user says explain more, go deeper, I do not follow, why is that, elaborate, or asks for detail on something you just said.
---

You are invoked via `/agent-explain-more`. The user just read your last reply and wants more from
it. Your job is to **add what was left out**, not to say the same thing at greater length.

---

## The rule

> Expansion means new information, not more words.

Every sentence you write must carry something the previous reply did not. If you cannot find
anything new to say about a point, do not restate it.

---

## Step 1 — Work out what they actually want

"Explain more" means three different things. Diagnose which before you write a word.

| Signal | They want | Give them |
|---|---|---|
| "go deeper", "why does that work", "how" | **Depth** | Mechanism, evidence, the reasoning chain |
| "I do not follow", "in simple terms", "what does X mean" | **Clarity** | Fewer assumptions, plain words, a worked example |
| "are you sure", "how do you know", "prove it" | **Justification** | The evidence chain, and your real confidence |

The middle case is the one most often got wrong. When the gap is comprehension, a longer answer
makes it worse. **More detail is not more words.** Strip the jargon instead, and build up from
something the user already knows.

If the user named a specific part, expand only that part. If they did not, go to Step 2.

---

## Step 2 — Pick the target

When no part is named, expand the point with the **highest compression ratio** — where the most
reasoning was collapsed into the fewest words. Those are usually:

- A conclusion stated without its derivation. "This is the root cause." Why?
- A number or a name with no source. Where did it come from?
- A recommendation with no alternatives. What else was considered, and why did it lose?
- A term of art used without unpacking. "It is an N+1." What does that mean here, concretely?
- A qualifier that hid something. "Mostly", "should", "roughly" each conceal a caveat.

Say which point you are expanding, in one line, before you expand it. If several deserve it, name
them and expand the most consequential first.

---

## Step 3 — Re-open the evidence

**Do not explain from memory.** The previous reply was written from files, commands, and output.
Go back to them.

```bash
sed -n '<start>,<end>p' <path>      # re-read the file the claim rests on
<the original command>              # re-run the command whose result you cited
```

Two reasons this matters. It gives you concrete detail, real line numbers and real values, that
memory cannot supply. And it is the only way to catch that the earlier claim was wrong.

**If re-reading contradicts the previous reply, say so plainly and correct it.** A request for
more detail is the moment errors surface. Do not defend the earlier wording.

---

## Step 4 — Expand

Work through whichever of these carry new information. Skip the rest.

**Mechanism.** How it actually works, one step at a time. Name the moving parts and what each one
does. This is the substance of a depth request.

**Evidence.** The specific `file:line`, the command output, the version number. Replace every
"because it does" with something checkable.

**A worked example.** Concrete input, then what happens to it, then the output. One good example
teaches more than three paragraphs. This is the strongest tool for a clarity request.

**What was left out.** The previous reply was compressed on purpose. Name what you dropped and
why. Edge cases, the version this depends on, the case where it does not hold.

**Alternatives.** What else could have been done, and the real reason it lost. "It was slower" is
weak; "it needs a second round trip per row" is an answer.

**Confidence.** Which parts you verified, and which you inferred. Say "I did not check this" where
it is true.

---

## Step 5 — Write it

- **Anchor in one line.** Name the claim you are expanding, then move on. No summary of the
  previous reply.
- **Lead with the answer**, then support it. Never build up to it.
- **Match the user's configured writing style**, the same as any other reply.
- **Stop when the new information runs out.** A short expansion that adds three real facts beats a
  long one that adds three facts and padding.

Offer one next step at the end, and only when there is a real one: something to run, read, or test
that would settle what is still open.

---

## Never

- **Never restate the previous reply.** One line of anchor is the entire allowance.
- **Never pad with generalities.** Background the user did not ask for is not expansion.
- **Never invent detail to fill the space.** If you do not know the mechanism, say so and say what
  would tell you.
- **Never lower your confidence to sound careful, or raise it to sound authoritative.** Report what
  you actually verified.
- **Never explain something different from what they asked about**, however interesting it is.
- **Never change any code.** This skill explains. Repair belongs to `/code-fix`.
