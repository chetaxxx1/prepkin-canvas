# Release checklist

App 1.0, extension 0.6.0. What is done, what George must do, and what to watch.
Rewritten 2026-09-08 after the launch-week batch. Plan of record: `design/LAUNCH-PLAN.md`
(week of 2026-09-07). Audit: `design/LAUNCH-AUDIT.md`.

## Done, verified 2026-09-08

Test counts as they stand: `npm test` 121 pass, 0 fail. iOS on a fresh simulator: 155 pass,
4 fail, the 4 being Balance, Pearls and Learn-track content tests that wait on files the games
session has not committed yet. All commits below are on `main`, none pushed.

- [x] No streaks anywhere. Extension rail says "N things finished this week" (6d782bb);
      `wordleStreak` gone from the app (b9f82ab); `copy.test.js` and `NoStreakTests` fail the
      suite if the word comes back in any string.
- [x] Copy sweep: no exclamation marks, no sync/bridge/endpoint/selector/API/token/schema/payload
      in a student-facing string, enforced by `copy-sweep.test.js` and `CopySweepTests` (e41be7f).
      "Sync now" is "Check again", "Syncing…" is "Getting your work…".
- [x] Extension renamed "Prepkin for Canvas"; `homepage_url` and `use_dynamic_url` set; the
      five-tap coin cheat deleted (e79dca8).
- [x] App name "Prepkin for Canvas", `MARKETING_VERSION` 1.0, `ITSAppUsesNonExemptEncryption` NO,
      automatic signing, `PrivacyInfo.xcprivacy` with UserDefaults CA92.1, a placeholder 1024
      icon (b9f82ab).
- [x] Truth line everywhere the old "sends nothing" was: PRODUCT.md, privacy page, README,
      clip 3 (1a9e34d). The sentence: "Reads only the Canvas you connect. Sends your coursework
      list and course grades to your own phone, and makes no other request."
- [x] Kill switches: submission pages, SpeedGrader, the `#submit` hash, an open Rich Content
      Editor (8b04707); the buddy panel stays off those pages too (6107c48).
- [x] Auto-update guard: orphaned page scripts tear down, every runtime call is guarded, open
      tabs are re-injected on update, a running focus session delays the reload (04cf640).
- [x] Extension draws Sprout, not the slime; `slime.js` deleted (edf422c).
- [x] Version handshake: the pushed list carries the extension version; the app asks for an
      update when it is below 0.6.0 (2207c0b).
- [x] Expired pairing: the app says "Your laptop's link ran out. Make a new code" instead of
      waiting forever (ab3b605).
- [x] Support address in the popup and in Settings; each half links to the other through
      prepkin.com/app and prepkin.com/chrome; `bridge/TERMS.md` drafted (f7aecea).
- [x] Store listings drafted with counted fields: `design/store/chrome-listing.md`,
      `design/store/app-store-listing.md`, `design/store/reviewer-notes.md` (1a9e34d, 9cfdb07).
- [x] Static pages for the store links: `bridge/site/privacy.html`, `terms.html`,
      `support.html`, no scripts, no external requests (9cfdb07).
- [x] App Store review ask: once, after five handed-in items and three days (ef80944).
- [x] Prepkin Plus StoreKit 2 plumbing with a `.storekit` sandbox file; no UI yet (ceede06).
- [x] Extension keeps its last 20 errors; "Copy a report" in the popup (bb0ccb7).
- [x] Audit's small bugs: 44pt back buttons, dead `ChibiStageView` removed, three Sendable
      warnings, `package.json` version matches the manifest (cd7e3a8).
- [x] Browser suites updated to today's copy and switches (7e1535c). Not run: see below.

## George, before the store

1. **Re-run `bridge/schema.sql`** in the Supabase SQL editor (pg_cron on). Until then nothing
   pairs: the live project still has the old code-only functions. Five minutes.
2. **Reload the unpacked extension** in Chrome and pair with a fresh code from the app.
3. **Make the addresses real.** `support@prepkin.com` must be a mailbox somebody reads.
   `prepkin.com/privacy`, `/terms`, `/support` get the pages in `bridge/site/`. `prepkin.com/app`
   and `prepkin.com/chrome` are redirects to the two listings; they can point at a holding page
   until the listings exist. All five are already in shipped strings and in `manifest.json`.
4. **Sign off the 1024 icon** or replace it. The current file is a mint Sprout still on
   #DDF4EA, made as a placeholder so archives can run.
5. **Set the Apple team** for signing (`project.yml` is on automatic signing with no team).
6. **Answer the App Store privacy label** to match reality. `PrivacyInfo.xcprivacy` currently
   declares no collected data types, and coursework does go through Prepkin's server to the
   student's phone. One of the two must change before submit; the Chrome data disclosure in
   `design/store/chrome-listing.md` already tells the truth.
7. **Reinstall Playwright's Chromium** so the browser suites can run again: it lived in
   `~/Library/Caches/ms-playwright` and was deleted when the caches were cleared. From
   `~/Library/Developer/prepkin-canvas-test-deps`: `npx playwright install chromium`, then
   `npm run test:e2e`, `test:stress`, `test:receipt` from the repo root. The suites were updated
   blind today; expect a few stale assertions.
8. **Retake iOS screenshots** at 1320x2868 (6.9"); the current 1206x2622 set is refused.
9. **Make the 440x280 tile and 1400x560 marquee** for the Chrome listing.
10. **Install on a real phone** with free provisioning (expires every seven days).
11. **Commit the games work** in the working tree so the four failing content tests can be
    judged, and delete `PlayRecord.streak` / `playStreak()` in `GameState.swift`, now unread.
12. **Plus UI** is not built; the plumbing is. The Lamp card and the trial trigger (third
    finished assignment) are 1.0.1 work per the plan.
13. **Stop the sandbox VM** when not in use (`canvas-sandbox`, Google Cloud console).
14. **Push `main`.** Nothing from today has left this machine.

## iPhone app, 2026-09-05

- [x] Light only, app-wide (`UIUserInterfaceStyle = Light`). Dark paper is queue item 7.
- [x] Text follows the system size for reading sizes (20pt and under), capped at 1.3x.
      This is "large", not the accessibility sizes. A low-vision student at AX3 gets 1.3x.
      Say so in the listing; do not claim Dynamic Type support.
- [x] Reduce Motion: coin flight, tab spring and the tank (drift-only) all honour it.
- [x] Every button 44pt or labelled (lint in `test/ios-sweep.sh`); scripted flows in
      `test/ios-flows.sh`; the loop is the `ios-walkthrough` skill. `ios-flows.sh` has three
      stale clusters (audit section 4) still to fix.
- [ ] Known gap: the Home tank keeps its ambient motion under Reduce Motion (WCAG 2.2.2, AA).
      The page has no motion hook; it needs a `setReduceMotion` in the Sprout source repo
      (`~/Downloads/Sprout-handoff`), a rebuild, and a copy into `ios/SproutWeb`.
- [ ] George: run it on a real phone for one school day (Xcode direct install, free team).

## Watch after launch

- Canvas deploys: run the live smoke check (`L7`) against the sandbox after each Canvas
  release; a hook that stops matching degrades to a plain page, and `selectors.json` says which.
- `modules_page_rewrite_student_view` and `responsive_student_grades_page` flags at real
  schools: the skin leaves those pages plain by construction.
- Districts: the receipt is the answer to "what does this change on our pages". Show them the
  popup on their own dashboard.
- The error log: a student who writes in can paste "Copy a report" from the popup. Ask for it
  in the support auto-reply.
- Remote kill and rollback (audit M2) still do not exist. A bad Canvas deploy means a Chrome
  review cycle to fix; freeze dates in the plan are the only lever.
