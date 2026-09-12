Take the Prepkin Chrome extension from a B+ to an A by taking things out, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas/extension). The 2026-09-12 review found every surface good and the whole too much: what is due is listed in three places, the dashboard rail stacks eight things in a 206px column, every course card carries three amber lines cut at twenty characters, and the popup has two equal buttons and no "Due next". BetterCampus's users left it over bloat. This session is editing, not building. Nothing new ships from it.

Read first, in this order:
1. PRODUCT.md and DESIGN.md. The page belongs to the school; the skin subtracts and fixes, every change on the receipt with put-back; no red; amber means "still counts"; say a count once; no engineering words in a student-facing string; the popup is the funnel and the screenshot.
2. design/canvas-skin/EXTENSION-FEATURES.md (what exists and why), design/canvas-skin/research-bettercampus-likes.md (to-do + dark + grades is the product; bloat is the top complaint), design/canvas-skin/HANDOFF-2026-09-11.md (the rail mechanics worth keeping, the two Sprout hosts, the colours).
3. extension/content.js (renderWeek and the rail `#pk-week`, decorateCards, panelView, the To Do fold), popup.html and popup.js, sidepanel.html and sidepanel.js, day.js (voice(), the shared day grouping), skin.css, receipt.js, themes.js.
4. The tests: test/receipt.test.js (R18 reads every skin.css selector off disk and proves none matches a quiz being taken), test/e2e.test.js (F1–F3 are the panel), extension/copy-sweep.test.js and copy.test.js (any "!" in a JS string fails; banned words fail). `npm test`, `npm run test:receipt`, `npm run test:e2e` all green before you start; keep them green.
5. Memory facts that cost hours before: the rail's real inner width is about 176px at 1280, design for that first; Playwright cannot pierce the panel's closed shadow root, click by coordinates; never cut a skin.css block by slicing between two markers, rebuild from `git show HEAD:extension/skin.css` plus your hunks and check `.pk-card-due {` is still there; the Sprout frame `#prepkin-sprout` must never live inside anything that re-renders; another session may hold port 8443 with `design/canvas-skin/sandbox/open.js`, so do not start FakeServer if `lsof -iTCP:8443` shows a listener, launch your own Chromium through `test/harness.stageExtension` and log in as the seeded student.

The rule for every change: one place for each fact.

Do these, in this order, one commit each, tests green after each:

1. One list per place. The dashboard shows the rail. Every other Canvas page shows the side panel, opened by the popup or the Sprout launcher. The buddy panel's home view stops listing due work; it keeps the headline line, grades, what-if, themes, the term recap and ⌘K. The ⌘K palette drops its "Due soon" group and keeps Classes and Canvas pages. After this, what is due appears in exactly two surfaces, never both on one screen. Update EXTENSION-FEATURES.md section A to say so. <code>content.js panelView, searchGroups; sidepanel.js</code>

2. The rail at five things. Keep, top to bottom: the tank with Sprout, one line (voice()), Start with (title, course, one Start button and the focus length as a small text link), Then (three rows, one line each), and the foot ("N finished this week · See the week"). Remove the seven-day strip and the ring; the ring's done count moves into the foot in words. Keep the To Do fold row under the rail as it is; it is a receipt item. Measure the result at 176px and at 206px; every row one line, course names cut at ":" as today. <code>content.js renderWeek, skin.css #pk-week</code>

3. One due line per card. Each dashboard card gets one line: the soonest or the oldest slipped item, "Problem Set 7 · was due Sep 5", wrapping to two lines, never cut mid-word, and "+2 more" as plain muted text when there are more. Amber only on the slipped one. The receipt row and its put-back stay. <code>content.js decorateCards, skin.css .pk-card-due</code>

4. The popup as Due next. Top: Sprout, "Prepkin", the coin chip. Then "Due next": today across every class, then tomorrow, from the last sync, the way R9 built it on 2026-09-05 with day.js (time column, folded days, Missed in amber "still counts"), one click opens the item in Canvas. One button under it: "Open the side panel". Then "What changed on this page" (the receipt, renamed, folded closed with the count in the row), Your phone, Schools, the paper switch, the footer as one row. The two green buttons go. The first-run three steps stay exactly as they are. <code>popup.html:185-264, popup.js</code>

5. Words. "buddy" → "Sprout" everywhere a student reads it. "Receipt" → "What changed on this page". "Put back" → "Undo" on the button, "Put it all back" → "Undo all". "Quiet Canvas, with a receipt" → "Tidy Canvas". "Late work still counts" stays on the rail line and as the amber row label, and nowhere else (it is in six places today: day.js:73, sidepanel.js:67, content.js:583 and three more). "Get Prepkin for iPhone" gets one muted line, "iPhone only for now." The manifest description loses "has a Put back". Update copy.test.js's allowlist if it names any of these. <code>popup.html:195, 203, 225, 247; manifest.json; day.js; sidepanel.js</code>

6. The panel's past-due wall. Wherever a list of slipped work remains (side panel, week view), show three rows and "N more", opening the rest in place. <code>sidepanel.js, content.js weekView</code>

7. Themes: six on the sheet, then "More themes". Classic Cream, Dark Academia, Matcha, Midnight, Deep Sea, Night Shift first; the other six behind one row. Nothing is removed from the catalogue. <code>content.js looksView</code>

8. Two panel controls are 28px tall. Make them 32. <code>panel.css:430, 449</code>

Do not touch: skin rules on course pages, the kill switches, the quiz-page proof, the Sprout frame, the pairing flow, the first-run popup, the receipt's mechanics, the themes catalogue, anything in ios/.

Prove it:
- `npm test`, `npm run test:receipt`, `npm run test:e2e` green. Add tests: the panel home view contains no due rows; the popup renders Due next from a synced world with today, tomorrow and one missed item; a card with three due items renders one line and "+2 more"; the rail contains no `.pk-w-days` and no `.pk-w-ring`; "buddy" and "receipt" appear in no student-facing string (extend copy-sweep.test.js).
- Re-run R18 after every skin.css change; skin.css is 779 lines and the proof was written when it was smaller.
- Before and after on the sandbox: dashboard light and dark at 1280, the panel open, the popup, the side panel on a course page, one course card with three items. If 8443 is held by another session, use their proxy with your own Chromium as described above; if the sandbox is down, use the gallery harness (`node design/canvas-skin/gallery/build.js`, then `OUT=<dir> node design/canvas-skin/gallery/shoot.js`) and the fake Canvas (`test/fake-canvas.js`) and say so.
- Count, on the after screenshots, how many places show the number of tasks due and how many say "still counts". The answer must be one each per screen.

What an A looks like: a student opens Canvas and sees their courses, a fish, and one short list of what to do first. They open the popup and see what is due next and one button. Nothing on the page says the same thing twice, no title is cut mid-word, and every word on every surface is one they already know. The receipt is still there, one fold away, and everything it took is one click from coming back.

Finish with: before and after screenshots side by side, the count of due-lists and "still counts" per screen before and after, the test counts, and the commits, one per numbered item.
