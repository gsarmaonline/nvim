---
name: screenshotify
description: Generate screenshots of all frontend pages using browser automation
---

You are being invoked via the /screenshotify skill. Your task is to automatically capture screenshots of all pages in a frontend application using browser automation.

## Overview

This skill helps with visual regression testing and documentation by:
1. Detecting if the project is a frontend app
2. Identifying all routes/pages
3. Setting up browser automation (Puppeteer/Playwright)
4. Capturing screenshots of each page
5. Organizing screenshots in a dedicated folder
6. Detecting visual changes for PRs

## Steps to Execute

### 1. Detect Frontend Application

Check if this is a frontend app by looking for:
- `package.json` with frontend frameworks (React, Vue, Angular, Svelte, Next.js, etc.)
- Common frontend directories: `src/`, `app/`, `pages/`, `components/`
- Frontend build tools: Vite, Webpack, Parcel, etc.

If not a frontend app, inform the user and exit.

### 2. Analyze Project Structure

Identify the frontend framework and routing:
- **Next.js**: Check `app/` or `pages/` directory for file-based routing
- **React Router**: Search for route definitions in code
- **Vue Router**: Check `router/` files
- **Angular**: Look for routing modules
- **Svelte(Kit)**: Check `routes/` directory
- **Static HTML**: Find all `.html` files

Extract all route paths and page URLs.

### 3. Check/Install Browser Automation Tool

Check if Puppeteer or Playwright is installed:
```bash
# Check for existing tools
npm list puppeteer playwright
```

Prefer **Playwright** over Puppeteer for new setups (better API, built-in server management).

Install if missing:
```bash
npm install -D playwright
npx playwright install chromium
```

### 4. Check for Existing Screenshot Framework

**Before creating any script**, check whether the project already has a screenshot framework in place:
```bash
ls frontend/scripts/screenshot.js scripts/screenshot.js 2>/dev/null
```

If `frontend/scripts/screenshot.js` (or equivalent) exists:
- Ensure Playwright is installed: `cd frontend && npm install`
- Run the existing framework: `cd frontend && npm run screenshot` (or `make screenshot`)
- Do NOT overwrite the existing script — it manages its own server lifecycle
- Skip directly to step 7 (Run Initial Screenshot Capture) using the existing script

If no framework exists, generate a script `scripts/take-screenshots.js` (or `.mjs` for ESM projects) that:

**Key features:**
- Starts the dev server (or uses production build)
- Waits for server to be ready
- Navigates to each discovered route
- Waits for page to load completely
- Takes full-page screenshots
- Saves to `screenshots/` directory
- Names files based on route (e.g., `home.png`, `about.png`, `products-id.png`)
- Handles dynamic routes with placeholders
- Captures different viewport sizes (desktop, tablet, mobile)
- Logs progress

**Example structure:**
```javascript
// scripts/take-screenshots.js
const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

const routes = [
  { path: '/', name: 'home' },
  { path: '/about', name: 'about' },
  // ... discovered routes
];

const viewports = [
  { name: 'desktop', width: 1920, height: 1080 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'mobile', width: 375, height: 667 },
];

async function takeScreenshots() {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  for (const route of routes) {
    for (const viewport of viewports) {
      await page.setViewport(viewport);
      await page.goto(`http://localhost:3000${route.path}`);
      await page.waitForLoadState('networkidle');

      const filename = `screenshots/${route.name}-${viewport.name}.png`;
      await page.screenshot({ path: filename, fullPage: true });
      console.log(`✓ Captured ${filename}`);
    }
  }

  await browser.close();
}

takeScreenshots();
```

### 5. Create Screenshots Directory

```bash
mkdir -p screenshots
echo "# Screenshots\n\nAuto-generated screenshots of the application.\n" > screenshots/README.md
```

Add to `.gitignore` if screenshots are large, OR commit them if you want version history.

### 6. Add NPM Scripts

Update `package.json` to add convenient commands:
```json
{
  "scripts": {
    "screenshots": "node scripts/take-screenshots.js",
    "screenshots:compare": "node scripts/compare-screenshots.js"
  }
}
```

### 7. Run Initial Screenshot Capture

If the project has a self-managing screenshot framework (e.g. `npm run screenshot`), just run it — it
handles server startup internally:
```bash
cd frontend && npm run screenshot
# Or via Makefile:
make screenshot
```

For projects without a framework, start the dev server first:
```bash
npm run dev &
sleep 5  # Wait for server to start
npm run screenshots
```

The self-managing framework supports these env vars:
- `BASE_URL` — override the default server URL (e.g. `http://localhost:3001` for docker)
- `START_SERVER=docker` — start the full docker-compose stack first
- `START_SERVER=dev` — spawn the Next.js dev server
- `STOP_SERVER=1` — stop docker-compose when done

### 8. Update CLAUDE.md

Add instructions to automatically take screenshots on frontend changes:

```markdown
## Requirements

### Visual Testing

- Whenever frontend code changes (components, pages, styles), automatically run screenshot capture
- Before creating a PR, run `npm run screenshots` to update screenshots
- Include screenshot comparisons in PR descriptions showing visual changes

## Commands and Tools

### Auto-approved Commands
- `npm run screenshots` - Capture screenshots of all pages
- `npm run screenshots:compare` - Compare screenshots with previous version

## Notes

### Screenshot Workflow
1. After making frontend changes, run `/screenshotify` or `npm run screenshots`
2. Review captured screenshots in `screenshots/` directory
3. When creating PRs, include before/after screenshot comparisons
4. Screenshots help reviewers understand visual impact of changes
```

### 9. Create Screenshot Comparison Tool (Optional)

Generate `scripts/compare-screenshots.js` that:
- Compares current screenshots with previous version (from git)
- Generates a diff report
- Outputs markdown for PR descriptions
- Uses image diff libraries like `pixelmatch` or `looks-same`

Example:
```bash
npm install -D pixelmatch pngjs
```

### 10. Integrate with PR Workflow

When creating PRs (in the `/ship` skill), automatically:
1. Check if frontend files changed
2. Run screenshot capture if needed
3. Compare with main branch screenshots
4. Add screenshot comparison section to PR body:

```markdown
## 📸 Visual Changes

### Homepage
| Before | After |
|--------|-------|
| ![](screenshots/main/home-desktop.png) | ![](screenshots/current/home-desktop.png) |

### Product Page
| Before | After |
|--------|-------|
| ![](screenshots/main/product-desktop.png) | ![](screenshots/current/product-desktop.png) |

No visual changes detected on: About, Contact
```

### 10a. Attach Screenshots to an Open PR

Images referenced by local paths (e.g. `![](screenshots/foo.png)`) do not render on GitHub — they must be served via a URL. The only reliable way to embed screenshots in a PR without an external image host is to commit them to the branch and reference them via their raw GitHub URL.

Follow these steps:

#### 1. Check for an open PR

```bash
gh pr view --json number,url,headRefName,body 2>/dev/null
```

If no open PR exists, skip this step entirely.

#### 2. Commit and push the screenshots to the current branch

Screenshots must be in the repo for GitHub to serve them. If they are gitignored, temporarily allow them:

```bash
# Stage all captured screenshots
git add screenshots/ -f   # -f to bypass .gitignore if needed

# Only commit if there are staged screenshot changes
git diff --cached --name-only | grep -q 'screenshots/' && \
  git commit -m "chore: update screenshots for PR review"

# Push so GitHub can serve the raw files
git push
```

If the push fails due to a remote conflict, rebase and retry (same logic as /ship).

#### 3. Build raw GitHub URLs for each screenshot

Get the repo owner/name and branch:

```bash
REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
BRANCH=$(git branch --show-current)
```

For each screenshot file, the raw URL is:
```
https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<path-to-file>
```

Example for `screenshots/home-desktop.png` on branch `feat/ui-update` in `acme/myapp`:
```
https://raw.githubusercontent.com/acme/myapp/feat/ui-update/screenshots/home-desktop.png
```

#### 4. Build the Visual Changes comment

Construct a markdown comment table. Group screenshots by page, with desktop/tablet/mobile columns:

```markdown
## Screenshots

> Captured at: <ISO timestamp>
> Branch: `<branch>`
> Viewports: desktop (1280px), tablet (768px), mobile (375px)

| Page | Desktop | Tablet | Mobile |
|------|---------|--------|--------|
| Home | ![home-desktop](https://raw.githubusercontent.com/<repo>/<branch>/screenshots/home-desktop.png) | ![home-tablet](...) | ![home-mobile](...) |
| Login | ![login-desktop](...) | ![login-tablet](...) | ![login-mobile](...) |
```

Only include pages where screenshots were actually captured. Skip pages that failed.

#### 5. Post as a PR comment (not body edit)

Post the table as a **new comment** on the PR so it doesn't overwrite the PR description:

```bash
gh pr comment <PR_NUMBER> --body "$(cat <<'MARKDOWN'
## Screenshots

> Captured at: 2026-03-13T10:00:00Z
> Branch: `feat/ui-update`

| Page | Desktop | Tablet | Mobile |
|------|---------|--------|--------|
| Home | ![home-desktop](https://raw.githubusercontent.com/acme/myapp/feat/ui-update/screenshots/home-desktop.png) | ![](https://...) | ![](https://...) |
MARKDOWN
)"
```

If a previous screenshotify comment already exists on the PR (check for `## Screenshots` in existing comments), delete the old one first:

```bash
# Find and delete the previous screenshot comment
OLD_ID=$(gh pr view <PR_NUMBER> --json comments \
  --jq '.comments[] | select(.body | startswith("## Screenshots")) | .id' | head -1)
[ -n "$OLD_ID" ] && gh api -X DELETE /repos/<owner>/<repo>/issues/comments/$OLD_ID
```

Then post the fresh comment.

#### 6. Notify the user

```
Screenshots posted to PR #<number>: <pr_url>
<N> pages, 3 viewports each
Raw images served from branch: <branch>
```

### 11. Report Summary

After completion, show:
- ✅ Screenshots captured: X pages × Y viewports = Z total
- 📁 Saved to: `screenshots/` directory
- 📝 Updated CLAUDE.md with screenshot workflow
- 🔧 Added npm scripts: `npm run screenshots`
- 💡 Next steps: Run screenshots before PRs, include visual diffs

## Important Notes

- **Server Detection**: Auto-detect dev server port from framework config
- **Dynamic Routes**: Handle parameterized routes with sample data or skip with warning
- **Authentication**: If pages require auth, ask user for credentials or test user
- **Loading States**: Wait for loading indicators to disappear before capturing
- **Error Handling**: Continue on failed screenshots, report at end
- **Performance**: Run captures in parallel when possible
- **CI/CD**: Can be integrated into GitHub Actions for automated visual testing

## Common Frameworks Detection

### Next.js
- Routes: `app/**/page.tsx` or `pages/**/*.tsx`
- Dev server: `npm run dev` (usually port 3000)

### React (CRA/Vite)
- Routes: Parse React Router files
- Dev server: `npm start` or `npm run dev`

### Vue
- Routes: Parse Vue Router files
- Dev server: `npm run serve` or `npm run dev`

### Angular
- Routes: Parse routing modules
- Dev server: `ng serve`

### Svelte(Kit)
- Routes: `src/routes/**/+page.svelte`
- Dev server: `npm run dev`

## Example Usage

```bash
# User invokes
/screenshotify

# Skill responds
✓ Detected Next.js application
✓ Found 8 routes in app/ directory
✓ Puppeteer already installed
✓ Created scripts/take-screenshots.js
✓ Starting dev server on port 3000...
✓ Capturing screenshots (8 pages × 3 viewports)...
  ✓ home-desktop.png
  ✓ home-tablet.png
  ✓ home-mobile.png
  ✓ about-desktop.png
  ...
✓ 24 screenshots saved to screenshots/
✓ Updated CLAUDE.md with screenshot workflow
✓ Added npm scripts

Next steps:
- Review screenshots in screenshots/ directory
- Run `npm run screenshots` before creating PRs
- Include visual diffs in PR descriptions
```

Execute these steps to set up automated screenshot capture for the frontend application.
