---
name: remotionify
description: Given a set of text or concept, create a Remotion animation as React components
---

You are being invoked via the /remotionify skill. Your task is to create a Remotion animation based on the user's provided text, concept, or data.

Remotion renders videos programmatically using React. Each frame is a React render at a specific point in time.

---

## Step 1 — Understand the Animation Request

Parse the user's input to determine:

1. **Content type**: Is this a title card, data visualisation, explainer sequence, slide deck, code walkthrough, or other?
2. **Key messages**: What text, data, or concepts need to be communicated?
3. **Tone**: Technical, playful, minimal, bold?
4. **Duration**: If not specified, default to 5–10 seconds at 30fps

If the input is ambiguous, make a reasonable creative decision and note it in the summary.

---

## Step 2 — Detect or Scaffold the Remotion Project

### Check if Remotion is already installed

Look for `remotion` in `package.json` dependencies:

```bash
cat package.json 2>/dev/null | grep remotion
```

Also check for an existing `src/remotion/` or `src/compositions/` directory.

### If Remotion is NOT installed

Check the package manager in use (`package.json` for `packageManager` field, or presence of `bun.lockb`, `yarn.lock`, `pnpm-lock.yaml`).

Install Remotion:

```bash
# npm
npx create-video@latest

# Or add to existing project
npm install remotion @remotion/cli

# bun
bunx create-video@latest
# Or
bun add remotion @remotion/cli
```

If adding to an existing project (not scaffolding fresh), create the directory structure:

```
src/
  remotion/
    index.ts          ← registers all compositions
    compositions/
      <Name>.tsx      ← the animation component
    Root.tsx          ← Remotion root with <Composition> declarations
```

Add to `package.json` scripts:
```json
{
  "scripts": {
    "remotion": "remotion studio src/remotion/index.ts",
    "remotion:render": "remotion render src/remotion/index.ts <CompositionId> out/<name>.mp4"
  }
}
```

### If Remotion IS installed

Identify where existing compositions live and follow the same pattern.

---

## Step 2b — Rendering requires sandbox bypass

Chrome Headless Shell (required for rendering) downloads from `storage.googleapis.com`. This is blocked by the Claude Code sandbox. When running `npx remotion render` or `npx remotion still`, always use `dangerouslyDisableSandbox: true` on the Bash tool call — otherwise the render will fail with `ENOTFOUND storage.googleapis.com`.

---

## Step 3 — Design the Animation

Before writing code, plan the animation as a sequence of beats:

```
Frame 0–15:   [Beat 1 description — e.g. title fades in]
Frame 15–60:  [Beat 2 description — e.g. subtitle slides up]
Frame 60–120: [Beat 3 description — e.g. content appears word by word]
Frame 120–150:[Beat 4 description — e.g. hold, then fade out]
```

Use this to determine `durationInFrames` for the composition.

---

## Step 4 — Write the Remotion Components

### Core Remotion APIs to use

```typescript
import {
  AbsoluteFill,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  spring,
  Sequence,
  Easing,
} from 'remotion';
```

**`useCurrentFrame()`** — returns the current frame number (0-indexed).

**`interpolate(frame, [inputRange], [outputRange], options?)`** — maps frame numbers to values. Always clamp with `extrapolateLeft: 'clamp', extrapolateRight: 'clamp'`.

**`spring({ frame, fps, config? })`** — physics-based spring animation. Returns a value that starts at 0 and settles at 1.

**`<Sequence from={N} durationInFrames={M}>`** — renders children only during frames N to N+M, with `useCurrentFrame()` reset to 0 inside.

**`<AbsoluteFill>`** — full-size absolutely positioned container, equivalent to `position: absolute; top: 0; left: 0; width: 100%; height: 100%`.

### Animation patterns to use

**Fade in:**
```typescript
const opacity = interpolate(frame, [0, 20], [0, 1], {
  extrapolateRight: 'clamp',
});
```

**Slide up:**
```typescript
const translateY = interpolate(frame, [0, 20], [40, 0], {
  extrapolateRight: 'clamp',
  easing: Easing.out(Easing.ease),
});
```

**Spring pop:**
```typescript
const scale = spring({ frame, fps, config: { damping: 12, stiffness: 180 } });
```

**Word-by-word reveal:**
```typescript
const words = text.split(' ');
{words.map((word, i) => {
  const delay = i * 4; // 4 frames between each word
  const opacity = interpolate(frame, [delay, delay + 10], [0, 1], {
    extrapolateRight: 'clamp',
  });
  return <span style={{ opacity }}>{word} </span>;
})}
```

### Styling

Use inline styles — no CSS files. Remotion renders each frame as a React tree; external stylesheets may not apply consistently. Prefer:
- `fontFamily: 'Inter, sans-serif'` or system fonts
- Explicit `fontSize`, `fontWeight`, `color`, `letterSpacing`
- Flexbox for layout (`display: 'flex'`, `alignItems: 'center'`, `justifyContent: 'center'`)

### Component structure

```typescript
// src/remotion/compositions/MyAnimation.tsx

import { AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate, spring } from 'remotion';

interface Props {
  title: string;
  subtitle?: string;
}

export const MyAnimation: React.FC<Props> = ({ title, subtitle }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const titleOpacity = interpolate(frame, [0, 20], [0, 1], {
    extrapolateRight: 'clamp',
  });

  const titleY = interpolate(frame, [0, 20], [30, 0], {
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{ backgroundColor: '#0f0f0f', justifyContent: 'center', alignItems: 'center' }}>
      <div style={{ opacity: titleOpacity, transform: `translateY(${titleY}px)` }}>
        <h1 style={{ color: '#fff', fontSize: 64, fontWeight: 700 }}>{title}</h1>
      </div>
    </AbsoluteFill>
  );
};
```

### Register the composition

```typescript
// src/remotion/Root.tsx

import { Composition } from 'remotion';
import { MyAnimation } from './compositions/MyAnimation';

export const RemotionRoot: React.FC = () => {
  return (
    <>
      <Composition
        id="MyAnimation"
        component={MyAnimation}
        durationInFrames={150}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={{
          title: 'Hello World',
          subtitle: 'A Remotion animation',
        }}
      />
    </>
  );
};
```

```typescript
// src/remotion/index.ts
import { registerRoot } from 'remotion';
import { RemotionRoot } from './Root';

registerRoot(RemotionRoot);
```

---

## Step 5 — Multi-Scene Animations

For longer animations with distinct sections, use `<Sequence>` to compose scenes:

```typescript
export const MultiScene: React.FC = () => {
  return (
    <AbsoluteFill>
      <Sequence from={0} durationInFrames={60}>
        <IntroScene />
      </Sequence>
      <Sequence from={60} durationInFrames={90}>
        <ContentScene />
      </Sequence>
      <Sequence from={150} durationInFrames={30}>
        <OutroScene />
      </Sequence>
    </AbsoluteFill>
  );
};
```

Each scene component uses `useCurrentFrame()` which starts at 0 within its `<Sequence>`.

---

## Step 6 — Preview and Verify Before Final Render

### Always verify with a still frame first

Before doing a full render (which takes time), render a single still frame at the last frame of the composition to check for layout issues, especially overflow:

```bash
# Check the final frame for overflow/clipping
npx remotion still src/remotion/index.ts <CompositionId> /tmp/check.png --frame=<durationInFrames-1>
```

Read the output PNG with the Read tool (it supports images) and visually confirm:
- All content is visible and not clipped at the edges
- Font sizes are readable at the expected display size
- Nothing overflows the canvas boundaries

Only proceed to full render once the still looks correct.

### Canvas height: size to content, not the other way around

Do NOT try to squeeze content into a fixed height by reducing font sizes until they're illegible. Instead:
- Estimate the content height before coding
- Set `height` in the Composition to fit the content (e.g. 900 or 1080 for tall layouts)
- Vertical stacks of 3+ boxes with connectors will almost always need more than 720px

Standard choices:
- Simple single-screen layouts: **1280×720**
- Two-column comparisons with many steps: **1280×720** (often fits if content is balanced)
- Tall vertical flows (3+ stacked boxes + arrows + title + footer): **1280×900** or **1280×1080**
- The video will display proportionally in the browser — a taller canvas is fine

### Font sizing for web embedding

If videos will be embedded in a blog or web page (displayed at ~700–800px wide), fonts must be much larger than typical web sizes:

| Display context | Scale factor | Min readable font |
|---|---|---|
| 1920×1080 embedded at 768px | 0.40× | 13px → appears 5px — **too small** |
| 1280×720 embedded at 768px  | 0.60× | 18px → appears 11px — acceptable |
| 1280×900 embedded at 768px  | 0.60× | 18px → appears 11px — acceptable |

**Rule of thumb**: design with fonts at least **18–22px** for detail text and **44–52px** for titles when targeting 1280-wide video embedded on the web.

### Full render command

```bash
# Render to video (remember: dangerouslyDisableSandbox required)
npx remotion render src/remotion/index.ts MyAnimation out/animation.mp4
```

---

## Step 7 — Summary

Print a summary:

```
Animation created
=================

Composition: <Name>
File:        src/remotion/compositions/<Name>.tsx
Duration:    <N> frames at <fps>fps = <seconds>s
Resolution:  <width>x<height>

Scenes:
  ✓ <Scene 1 description> (frames 0–N)
  ✓ <Scene 2 description> (frames N–M)
  ...

Preview: npm run remotion → http://localhost:3000
Render:  npx remotion render src/remotion/index.ts <Name> out/<name>.mp4
```

---

## Important Notes

- **Never use `setTimeout` or `setInterval`** — all animation must be driven by `useCurrentFrame()`. Remotion renders frames non-linearly (it may render frame 42 before frame 1 during preview scrubbing).
- **No random values in render** — `Math.random()` will differ per frame. Use `useCurrentFrame()` to derive deterministic values.
- **Keep components pure** — each frame must render identically given the same frame number.
- **Prefer `interpolate` over manual math** — it handles edge cases, clamping, and easing cleanly.
- **Font loading**: If using custom fonts, use `@remotion/google-fonts` or `staticFile()` — don't rely on system fonts being present in the render environment.
- If the user's input is data (numbers, a table, a list), create a data visualisation animation — bar charts, counters, timelines — driven by the data, not placeholder values.
- **`transform: scale()` does NOT affect layout** — it is a visual-only transform. Using it to "scale down" overflowing content will not clip it; the layout still overflows. Fix overflow by changing the canvas height or reducing actual layout values.
- **Inline `scaleY` for reveal animations** — apply `transform: scaleY(progress)` + `transformOrigin: 'top'` directly on a section div to animate it growing downward. This works well for boxes and bars that should "draw in" from the top.
- **Check all compositions after any resize** — changing `width`/`height` in Root.tsx requires re-rendering all affected compositions. Render a still from each before doing full renders.
- **Autoplay in web embedding** — for videos embedded in blog posts, set `video.muted = true` and use IntersectionObserver to play/pause based on viewport visibility. Browsers block autoplay on unmuted videos.
