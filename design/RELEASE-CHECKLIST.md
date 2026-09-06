# Extension release checklist

Version 0.5.0 (Receipt). What is done, what George must do, and what to watch.

## Done, verified 2026-09-05

- [x] Unit 77 · Receipt browser 13 · e2e 36 · stress 8 · live 7 · iOS 129, all green.
- [x] Packaging: `bridge/package.sh` builds `dist/prepkin-canvas-0.5.0.zip` with tests passing,
      a publishable key only, and every manifest reference resolving.
- [x] Permissions unchanged: `storage`, `alarms`, `activeTab`, `scripting`; host
      `https://*.supabase.co/*`; everything else optional and per site.
- [x] Zero external requests: no web font, no CDN, no analytics. Verified by reading every fetch.
- [x] The skin never writes a property on a button, never sets font-family, never touches the
      login page, flash errors, the skip link or the school's logo (lint in `receipt.test.js`).
- [x] Kill switches: High Contrast (school setting, OS forced colours, prefers-contrast),
      New Quizzes, widget dashboard, sign-in pages.
- [x] Reduced motion honoured on the page, in the panel and in the popup.
- [x] Every receipt row has a Put back that survives reload and navigation.
- [x] Real-Canvas smoke check (`live.test.js` L7) with rendered-pixel assertions.
- [x] Privacy text updated for the receipt (`bridge/PRIVACY.md`).

## George, before the store

1. **Re-run `bridge/schema.sql`** in the Supabase SQL editor (pg_cron on). Until then nothing
   pairs: the live project still has the old code-only functions. Five minutes.
2. **Reload the unpacked extension** in Chrome (it registers two content-script sets now) and
   pair with a fresh code from the app.
3. **Host the privacy policy** at a real URL and put it in the store listing and as
   `homepage_url` in `extension/manifest.json`. The text is `bridge/PRIVACY.md`.
4. Store listing: name, 132-char summary, screenshots at 1280×800. Candidates are in
   `design/signoff/canvas-live/` (`10-receipt-dashboard.png`, `12-carbon-dashboard.png`,
   `01b-panel-open.png`) and `design/signoff/extension-ui/` (`popup-light.png`).
5. Sign off the buddy art on Canvas pages: `looks.js` accessories are still marked provisional
   in the design queue.
6. Stop the sandbox VM when not in use (`canvas-sandbox`, Google Cloud console).

## iPhone app, 2026-09-05

- [x] Light only, app-wide (`UIUserInterfaceStyle = Light`). Dark paper is queue item 7.
- [x] Text follows the system size for reading sizes (20pt and under), capped at 1.3x.
      This is "large", not the accessibility sizes. A low-vision student at AX3 gets 1.3x.
      Say so in the listing; do not claim Dynamic Type support.
- [x] Reduce Motion: coin flight, tab spring and the tank (drift-only) all honour it.
- [x] Every button 44pt or labelled (lint in `test/ios-sweep.sh`); scripted flows in
      `test/ios-flows.sh`; the loop is the `ios-walkthrough` skill.
- [x] Reduce Motion stills the coin flight and the tab switch. Games, Daily Word, Number
      Line, adoption and the swim scene already honoured it.
- [ ] Known gap: the Home tank keeps its ambient motion under Reduce Motion (WCAG 2.2.2, AA).
      The page has no motion hook; it needs a `setReduceMotion` in the Sprout source repo
      (`~/Downloads/Sprout-handoff`), a rebuild, and a copy into `ios/SproutWeb`.
- [ ] George: GIF sign-off on nothing new this round (no motion changed).
- [ ] George: run it on a real phone for one school day (Xcode direct install, free team).

## Watch after launch

- Canvas deploys: run the live smoke check (`L7`) against the sandbox after each Canvas
  release; a hook that stops matching degrades to a plain page, and `selectors.json` says which.
- `modules_page_rewrite_student_view` and `responsive_student_grades_page` flags at real
  schools: the skin leaves those pages plain by construction.
- Districts: the receipt is the answer to "what does this change on our pages". Show them the
  popup on their own dashboard.
