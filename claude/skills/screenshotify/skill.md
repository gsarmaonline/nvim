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

If not installed, ask user which to install:
- **Puppeteer** (lighter, Chrome-only)
- **Playwright** (heavier, multi-browser support)

Install the chosen tool:
```bash
npm install -D puppeteer
# OR
npm install -D playwright
npx playwright install chromium
```

### 4. Create Screenshot Script

Generate a script `scripts/take-screenshots.js` (or `.mjs` for ESM projects) that:

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

Start the dev server and run the screenshot script:
```bash
npm run dev &
sleep 5  # Wait for server to start
npm run screenshots
```

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
