Make the Prepkin skin on Canvas pages perfect, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas/extension). "Perfect" has a definition here, and it is not "prettier": on every page a student meets, in every theme, light and dark, the skin takes only what the receipt lists, fixes only what it says it fixes, never touches a button or a quiz, reads at AAA, survives Canvas's own page changes, costs nothing you can feel, and looks like the same product as the phone. The 2026-09-12 review graded the skin's course pages B because nobody had looked at them on a real student course. This session looks at every page and closes every gap, one page at a time.

Read first, in this order:
1. PRODUCT.md and DESIGN.md. The page belongs to the school. Subtract and fix; every change on the receipt with a put-back; never red; never a property on a button; never hide a tab, only dim; never a web font, never a request from a Canvas page; amber means "still counts".
2. design/canvas-skin/RESEARCH.md section 3, the per-page anatomy for twenty Canvas surfaces in two tiers, and section 4, the technical floor (the target ladder, the --ic-brand strategy, SPA behaviour, iframes, course colour, the accessibility settings a skin must not fight). Section 5.3 is the honest gap list; section 6 is the BetterCanvas bar.
3. design/canvas-skin/SPEC-RECEIPT.md sections 9 (what Receipt must not fight, the button guarantee, the toggle matrix), 10 (the papers, AAA floor, the seven tokens a Look may move) and 12 (what Receipt refuses).
4. design/canvas-skin/BETTERCAMPUS-PARITY.md, the gap table: due on cards (done), To Do fold (done), density (done), same-origin iframe dark (missing), SPA persistence (built, never proven on every page), own card picture (done), custom page background (missing), submit-button audit in dark (never run), modules click reduction (missing, low confidence).
5. extension/skin.css top to bottom, with its section comments; extension/selectors.js; extension/boot.js; extension/content.js (applySkin, detectKill, the page observer, decorateCards, the title rule); extension/receipt.js; extension/themes.js.
6. The tests and tools: test/receipt.test.js (R1–R21; R18 proves no selector matches a quiz being taken, reading skin.css off disk), test/live.test.js L7 (every load-bearing selector asserted on the sandbox), the stylesheet lint (no property on a button, no font-family, no shadow, no lift, no red, no `css-` hash, no brand variable), design/site-shots/shoot.js with PAGES=1 (eight pages, light and dark) and PROBE=<path> (every text node's computed colour), design/canvas-skin/sandbox/open.js.
7. Memory facts measured on the real sandbox: most Canvas pages hide their h1 in .screenreader-only, the dashboard title is a hashed InstUI span reached by `[class*="-view-heading"]`, Grades has no on-screen title at all, an assignment's title is `h1.title`, the dashboard bar is React and is not there at document_end. Probe before writing any selector for a heading. Never cut a skin.css block by slicing between two markers; rebuild from `git show HEAD:extension/skin.css` plus your hunks, then check `.pk-card-due {` is still there. Another session may hold port 8443 with open.js; if `lsof -iTCP:8443` shows a listener, launch your own Chromium through `test/harness.stageExtension` and log in as alex@prepkin.test rather than starting FakeServer. The seeded student is a TA in the first course; use the second course for every student-page shot.

The definition of perfect, as a checklist you run on every page:
- Subtract: nothing is gone from the page that is not a row on the receipt with Put back. Show me outlines it.
- Fix: every fix in the catalogue applies where it says it applies and nowhere else.
- Buttons: no property written on button, [type=submit], input[type=submit], [role=button], in any theme, in any state. Lint proves it; a headless contrast pass on Canvas's primary button in light and in dark records the numbers.
- Quizzes: nothing runs on /quizzes/N/take, New Quizzes, or a page with the high-contrast ENV. R18 and the kill switches prove it.
- Reading: body ink on every paper at 7:1 or better; every link ink 4.5:1 or better; measured, printed on the theme cards.
- Titles: exactly one visible page title per page, Canvas's own words, never twice.
- SPA: navigate dashboard → course → modules → assignment → grades → back without a reload and the skin, the rail, the title and the receipt are right on every stop.
- Cost: the skin's style recalculation and the observer's work under 16ms on the modules page with 200 items, measured in the Performance panel once.
- Preferences: hide_dashcard_color_overlays, collapse_global_nav, Underline-All-Links, reduced motion, forced colours, all honoured. Section 9.6 table.
- One product: the paper, the mark, the amber and the hairlines match DESIGN.md's tokens; the rail's tank matches the phone's tank plate.

Do it in this order, one commit per page group, tests green after each:

1. Baseline. Run PAGES=1 in light and dark on the sandbox's second course, plus the pages PAGES does not cover yet: an assignment page, a wiki page, syllabus, files, people, announcements, quizzes (classic index), the calendar month, the inbox with a thread open, the course home in each of Canvas's three home layouts if the sandbox has them. Add the missing ones to shoot.js's page list. Put the before set in design/screenshots/canvas-skin-<date>/before/. Run the lint, R18, L7, and record the button contrast numbers. Write the findings as a table, one row per page: what is wrong, which rule, which fix.

2. Tier 1 pages, each to the checklist: global nav rail, breadcrumb bar, flash and announcement banners (never touched, verify), dashboard cards, the planner list view (RESEARCH 3.5, likely untouched today), the right sidebar, course navigation, course home, modules, the assignment page, grades, the global nav trays. For each: the page reads on every paper, the title rule holds, nothing off-receipt moved, dark holds, the observer re-applies after Canvas's own navigation.

3. Tier 2 pages: assignments index, inbox, discussions (index and a thread), classic quizzes index, calendar, recent activity, pages, syllabus, courses index, the mobile header at 768px. Same checklist. Where a page has a white box Canvas paints that the skin misses in dark, the fix is the surfaces rule in skin.css ("surfaces, not pages"), never a page-specific hack.

4. The three real gaps, each on the receipt with a put-back:
   a. Same-origin frames in dark: DocViewer and Canvadocs previews go white at 2 AM. all_frames with a same-origin check, the paper tokens only, nothing else; the veil rule stays for third-party frames. Prove the frame interior is same-origin before styling it; if it is not, the veil is the answer and say so.
   b. Page background under an image theme on course pages, not only the dashboard: the wallpaper under the paper wash the way the dashboard does it, one rule, one receipt row.
   c. Modules: a pinned module header exists; add "collapse all" state memory per course so a student who folded a module finds it folded, stored locally, on the receipt as Added. Skip the click-reduction rewrite; RESEARCH says the ask is instructor-skewed.

5. Course colour and the student's own choices. Verify the course colour is read and never written on every page it appears (cards, calendar, the rail rings, the panel dots). Verify a student's own card picture outranks every theme banner. Verify Canvas's own dark mode setting, if the sandbox has it, does not double with ours.

6. The performance pass. Modules page with 200 items: one debounced observer, no per-node work, no layout thrash. Record the numbers before and after in EXTENSION-FEATURES.md.

7. The after set. Re-run PAGES=1 plus the added pages, light and dark, every theme once on the dashboard. Put them beside the before set. Update RESEARCH.md section 5.2 ("which pages the skin reaches today") and 5.3 (the gap list) to what is now true. Update the selectors file and L7 for every new hook.

Do not: add a feature, a toggle, a setting, a theme, a request, a font, a radius, a shadow, a hover lift, a colour on a button, a page-specific selector with a `css-` hash, or anything not on the receipt. Do not touch the popup, the side panel, the panel views or the rail's content (another prompt owns those). Do not touch ios/.

Prove it:
- `npm test`, `npm run test:receipt`, `npm run test:e2e`, and `test/live.test.js` green with L7 extended to every new hook. The lint green. R18 green after the last skin.css change.
- The before and after sets, page by page, light and dark, in design/screenshots/canvas-skin-<date>/, with a README listing each page's checklist result as pass or fail and the rule behind every fail.
- The button contrast table from SPEC-RECEIPT 9.5, re-measured, appended with today's date.
- The SPA walk recorded as a short GIF: dashboard → course → modules → assignment → grades → dashboard, skin on, no reload.
- One sentence per Tier 1 page saying what Prepkin does to it, in EXTENSION-FEATURES.md, so the store listing and the privacy page can quote it.

What perfect looks like: a student on any Canvas page, in any theme, at 2 AM, sees the school's page with the junk gone and the rest easier to read, and cannot find a single thing Prepkin did that is not on the list with an Undo. Their submit button is Canvas's. Their quiz is Canvas's. Their course colours are theirs. Nothing moved that they did not ask to move, and nothing they see in the app's tank looks like a different company drew it.

Finish with: the page table (before and after, pass/fail per checklist line), the screenshots, the contrast numbers, the performance numbers, the test counts, and the commits, one per numbered item.
