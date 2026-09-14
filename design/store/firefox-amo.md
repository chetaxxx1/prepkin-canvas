# Firefox (AMO) — what a listing needs before we submit

Measured 2026-09-14 on the 0.7.0 build: `npm run test:firefox` passes (real Firefox
through geckodriver, the build installs, the event page starts, the skin reaches a
Canvas page). `web-ext lint`: 0 errors, 19 warnings, all `innerHTML` inside the
minified Sprout bundle (`extension/sprout/assets/index-*.js`). Nothing is submitted.

## 1. Signing

Firefox refuses an unsigned extension outside a temporary install. AMO signs it:

- A Firefox account at addons.mozilla.org, then the developer hub agreement.
- `bridge/firefox.sh` writes `build/firefox/`. Zip that folder (not `extension/`):
  `cd build/firefox && zip -r ../prepkin-canvas-firefox-0.7.0.zip .`
- Listed (on AMO, searchable) or self-hosted (signed, we serve the .xpi from
  prepkin.com). The id is already fixed in the manifest rewrite:
  `canvas@prepkin.com`, `strict_min_version` 128.0.
- The version must be unique per upload, the same rule as Chrome.

## 2. The data-collection manifest key

New AMO submissions need `browser_specific_settings.gecko.data_collection_permissions`
in the manifest (required for every new listing since late 2025; Firefox 140+ shows
it at install). `bridge/firefox.sh` does not write it yet. What it should say,
matching the Chrome data-use disclosure in `chrome-listing.md`:

```json
"data_collection_permissions": {
  "required": ["personalInfo"],
  "optional": []
}
```

"personalInfo" is the nearest category for coursework titles, due dates and grades
sent to the bridge for the student's own phone. Nothing is sold or used for ads.
Add it to the Python block in `bridge/firefox.sh` next to `browser_specific_settings`.

## 3. Source for the minified Sprout bundle

AMO reviewers require readable source for anything minified or bundled. The Sprout
web build (`extension/sprout/assets/index-*.js`, the dotlottie wasm) is a Vite build
of the separate Sprout repo. Upload with the listing:

- A zip of the Sprout source at the exact commit that produced the bundle, with the
  build steps (`npm ci && npm run build`, the Node version, and which output files
  are copied into `extension/sprout/`).
- A `README-REVIEWERS.md` in that zip that says which files in the extension come
  from that build and how to reproduce them byte-for-byte.

The rest of the extension ships as plain, unminified files and needs nothing.

## 4. Listing copy

The same text as `chrome-listing.md` works. AMO wants: summary (250 chars), a
description, a category (Productivity), the privacy policy URL, the support URL,
screenshots, and a short "why these permissions" note for `storage`, `alarms`,
the bridge host, and the optional host request.

## 5. Two things not done, on purpose

- Nothing submitted. George decides whether to list on AMO at all.
- The `sidebar_action` (Firefox's side panel) is untested by hand in Firefox; the
  automated test only checks the event page and a Canvas page.
