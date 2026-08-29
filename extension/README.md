# Prepkin Canvas Sync — Chrome extension (v0.1 skeleton)

## What works
- Load it, log into Canvas, and it pulls your real to-do list from Canvas's
  REST API (`/api/v1/users/self/todo`) using your logged-in session.
- Stores the list in `chrome.storage.local` and shows the count on the icon.
- Re-syncs every 30 minutes.

## What's not built yet
- The bridge to the iOS app (M2). See `../SPEC.md` §4.

## Try it
1. Open `chrome://extensions`, turn on Developer mode.
2. "Load unpacked" → pick this `extension/` folder.
3. Log into your school's Canvas site.
4. Inspect the service worker → `chrome.storage.local.get(console.log)` to see
   the synced tasks.

Note: only matches `*.instructure.com`. If your school uses a custom Canvas
domain (e.g. `canvas.myschool.org`), add it to `host_permissions` and
`content_scripts.matches` in `manifest.json`.
