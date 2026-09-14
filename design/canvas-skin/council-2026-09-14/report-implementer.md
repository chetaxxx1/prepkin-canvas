# Council report: implementation / testability

Read-only pass on `/Users/georgeshi/Library/Developer/prepkin-worktrees/verdict` at e10d2bce. `npm test` run once: 143/143 green. Nothing edited. Every claim names its file; "did not check" means exactly that.

---

## Q1. The button rule in dark mode

### 1. Evidence inspected
- `extension/receipt.test.js` L318–334: the lint. `buttonish` regex L327; skips for `sel.includes('*')`, `:not([type="submit"])`, and `ours()` (L322, which lists `#pk-looks`, `#pk-planner`, `#pk-week`…).
- `extension/skin.css` L1–16 (the header's promises), L133–158 (surfaces block, "Never a button"; L152 excludes `[type=submit]`/`[type=button]` inputs), L371–372 (colour on the active course-tab **link**, "never on a button"), L520–640 (surfaces), L634 (`[class*="baseButton"]` exclusion; skipped by the lint's `*` rule).
- `test/receipt.test.js` L328–347 `SKIN_SELECTORS` (read off disk), L351–353 `skinReaches` (`document.querySelector` per selector), L358–383 R18, L41 `classes()`.
- `extension/boot.js` L7: a quiz-take path returns before any `pk-` class goes on. `extension/content.js` L223, L2554.
- `test/pages.test.js` L71–80 `KNOWN`, L146–158 the controls check; `test/page-audit.js` L50–52 `isButton`, L155–170 (controls need 3:1; icon-only controls skipped).
- `test/fake-canvas.js` L223–224: the fake assignment page ships `button.btn.btn-primary#assignment_submit` and `button[type=submit].btn.btn-primary#submit_text_entry`.
- Shots: `design/signoff/canvas-pages/calendar-dark.jpg`, `syllabus-dark.jpg`, `modules-dark.jpg`. `report.json` on disk holds only the last subset run (quiz light/dark); `test/pages-baseline.json` has zero button rows.
- `design/canvas-skin/RESEARCH.md` L955–956: InstUI's `baseButton` emotion label is the same for a primary and a text button.

### 2. Current behaviour
- Any Canvas-reaching selector containing `button`, `.btn`, `.Button`, `[type=submit]`, `[role=button]` fails the lint. Loophole: 46 selectors contain `*` and are skipped entirely (re-ran the lint without that skip in a scratch script: none of the 46 would fail today, so the skip can go).
- On a dark paper the calendar's month arrows (`button.navigate_prev.btn` / `navigate_next`) are plainly invisible in the shot: a dark arrow on a dark box. The syllabus case (`td.dates > span.tooltip-time-mount > span > button`, a class-less `<button>` since `path()` prints classes when there are any) reads light grey to my eye in `syllabus-dark.jpg`; I did not re-measure. The "every icon-only kebab" cost has no number: `page-audit.js` skips icon-only controls, and the student-view shots show no kebab on paper (the card kebab sits on the colour band; the calendar list's ⋮ reads fine).
- R18's proof is the **class gate**, not the selector bodies: every Canvas rule starts `html.pk-on…`, and on a quiz being taken `<html>` carries no `pk-` class (boot.js bails, R18 asserts `classes(page)` is `[]`). So no selector starting `html.pk-on` can match there, whatever follows.

### 3. Options
- **(a) Keep strict.** Zero code. Cost: the arrows stay invisible in dark on every school; the two `KNOWN` rows stay. Breaks the "controls read at 4.5:1" line of the Things/Linear dark reference.
- **(b) One rule, dark only, colour only, on background-less buttons.** ~3 lines of CSS, ~12 lines in the lint, one e2e assertion. Two traps: (i) `[class*="baseButton"]` cannot be used, because a primary and a text InstUI button carry the same label, so the rule must name Canvas's legacy classes/ids, not a family; (ii) hover. Canvas's `.btn:hover` paints a light ground; if we set light ink, the hover moment reads light on light (the B1 bug shape).
- **(c) Paint the ground instead.** A second property on a button and a repaint of Canvas's own control. No.

### 4. Edge cases
- Hover/focus: solved by `:not(:hover)` on the selector, so while hovered Canvas owns both colours again, whatever its hover ground is. Unverified what `.navigate_prev.btn:hover` paints; `:not(:hover)` makes the answer not matter.
- `#calendar_header` is a surface the skin already names (skin.css L532); whether the arrows sit inside it is unverified. If not, scope with `#content` and keep the class.
- A school that themes `.btn` via `--ic-brand-button-*`: untouched, because only two ids' buttons are named.
- Canvas moves the calendar header to InstUI: the selector matches nothing; `pages.test.js` re-flags it as a finding.
- Light mode untouched (`.pk-dark` gate).
- Submit buttons: `.btn-primary`, `[type=submit]`, `#submit_quiz_button` are never named; a lint line makes that a rule, not a habit.

### 5. Recommendation
**Option (b), narrow: one block, dark only, `color` only, `:not(:hover)`, on the two measured controls, and the lint permits exactly those selectors and only that property.**

What the student sees: in dark, the calendar's month arrows and the syllabus due-by times in the paper's ink; hover them and they are Canvas's own again. Light mode unchanged. Submit buttons unchanged everywhere.

CSS (skin.css, after L372's link rule):
```css
/* Words Canvas draws as background-less <button>s, measured on the real
 * sandbox in dark (2026-09-14): the calendar's month arrows and the
 * syllabus's due-by times. Colour only, dark only, never a submit, and not
 * while hovered, so Canvas's own hover pair stays whole. */
html.pk-on.pk-dark:not(.pk-back-paper) #calendar_header button.navigate_prev:not(:hover),
html.pk-on.pk-dark:not(.pk-back-paper) #calendar_header button.navigate_next:not(:hover),
html.pk-on.pk-dark:not(.pk-back-paper) #syllabus td.dates button:not(:hover) { color: var(--pk-ink) !important; }
```
Lint (extension/receipt.test.js, replaces L326–334):
```js
// The one carve-out: dark-only colour on the background-less Canvas buttons
// measured on 2026-09-14. Listed whole, so a new one is a deliberate edit here.
const TEXT_BUTTON_OK = new Set([
  'html.pk-on.pk-dark:not(.pk-back-paper) #calendar_header button.navigate_prev:not(:hover)',
  'html.pk-on.pk-dark:not(.pk-back-paper) #calendar_header button.navigate_next:not(:hover)',
  'html.pk-on.pk-dark:not(.pk-back-paper) #syllabus td.dates button:not(:hover)',
]);
test('no rule in the skin writes any property on a button', () => {
  const buttonish = /(^|[\s,>+~(])(button|\.btn|\.Button|\[type="?submit"?\]|input\[type="?submit"?\]|\[role="?button"?\])/i;
  for (const r of rules) {
    for (const raw of r.selectors.split(',')) {
      const sel = raw.trim();
      if (sel.includes(':not([type="submit"])') || ours(sel)) continue;   // the `*` skip is gone: nothing needed it
      if (TEXT_BUTTON_OK.has(sel)) {
        assert.ok(sel.startsWith('html.pk-on.pk-dark:not(.pk-back-paper) '), `dark only, under Put back: ${sel}`);
        assert.doesNotMatch(sel, /submit|primary|quiz|\[type/i, `never a submit: ${sel}`);
        assert.match(r.body.replace(/\s+/g, ''), /^color:var\(--pk-ink\)!important;?$/, `colour and nothing else: ${sel}`);
        continue;
      }
      assert.doesNotMatch(sel, buttonish, `selects a button: ${sel}`);
    }
  }
});
```
Proof that R18 still holds: the new selectors begin `html.pk-on.pk-dark`; R18 first asserts the html element has no `pk-` class on `/quizzes/1/take`, then asserts `skinReaches` is empty; the first makes the second true for any `html.pk-on…` selector. The lint's `startsWith` line pins that.
Proof that a submit button is never touched (new e2e in `test/receipt.test.js`, fake Canvas, ~8 lines): open `/courses/1/assignments/11` with `skin.dark: true`, read `color`/`backgroundColor` of `#assignment_submit` and `#submit_text_entry` with the `style()` helper (L42), then `putBack: { paper: true }`, read again, `assert.deepEqual`. Then on the sandbox: delete the two `KNOWN` rows and run `PAGES=calendar,syllabus MODES=dark node --test test/pages.test.js`.
Also update the header comment in skin.css L10–12 and HANDOFF L42 to say "colour only, dark only, on the three named".

### 6. Confidence
High on the lint shape and the R18 argument (read the code paths). Medium on the syllabus selector: the shot suggests it may already read, so re-measure with `KNOWN` emptied before spending a line on it. Unverified: `#calendar_header` contains the arrows; what `.btn:hover` paints on the calendar.

---

## Q2. Tick a row done (where implementation cost changes the answer)

Every surface already branches on `t.submittedAt` (`dueRowsFor`/`nextUpFor` content.js L1361–1389, `plColumns` planner.js, sidepanel.js, popup.js, and `ownTasks` already writes `submittedAt` on a tick at content.js L2253). So the cheap design is not a second field but one fold: keep `done: { [taskId]: isoAt }` in `chrome.storage.local`, and apply it in exactly two places, where `data.tasks` is read from `lastPayload` in content.js and where `send()` builds `forBridge` in background.js L466–490 (`t.submittedAt ?? done[t.id]`, plus `doneBy: 'tick'`). Then the rail, the card line, the planner, the side panel, the popup and the phone all show it done with no per-surface code; the only per-surface cost is drawing the circle (five places, one `classTile`-style helper). Reconciliation is free: a later Canvas `submittedAt` shadows the tick; a later `missing` does not un-tick (the student's word stands locally; the phone paid once by task id through `applyDoneMarks`). Undo is `delete done[id]` behind the receipt's existing Undo row. Reward: the widget already pays a tick without proof, so the honest rule is "the phone pays a tick the same 30, once per task id"; cap paid ticks at 5 a day in the app's ledger to bound "tick everything". No write to Canvas anywhere in that path.

---

## Q3. Looks tiles as real renders

### 1. Evidence inspected
- `extension/receipt.js` L15–53 `PAPERS` (16 stocks), L105–109 `stockFor`, L210–236 `themeStyle` (accent, wash, rail, rail image, `--pk-wallpaper`, `--pk-paper-wash` alpha, `--pk-card-art-1..4`).
- `extension/themes.js` L28–104 (18 themes) + L110–151 (8 image themes) = 26; L163–171 `artFor` (placeholder svg fallback), L174–178 `textureImage`.
- `extension/planner.js` L430–528 `renderLooks` / `plLookTile`: today's tile is the paper with a 48px card silhouette (accent bar, two lines), name, vibe, tick, price; image tiles already paint the full wallpaper `cover` under a .62 scrim (L506); rebuild is key-guarded (L436). Course colours come from `plannerState().data.courses[].colorHex` (canvas.js L75, from `/users/self/colors`), the same source `classTile` uses (content.js L1687–1693). `decorateCards` (L1391) never reads a colour off the DOM.
- `extension/skin.css` L247–329 (texture layers, wash, image-theme body/hero rules), L958–1024 tile CSS (4-up grid, 2-up under 1100px, `.preview` 64px). `extension/receipt.test.js` L322: `#pk-looks` is `ours`, so tile CSS is outside the button/shadow lints.
- `extension/art/*`: wallpapers 1920×1072/1080 webp, 220–880 KB per folder, 4.4 MB total; `card-N.webp` 1200×510. `art/manifest.js` lists the 8 folders.
- `test/receipt.test.js` L616–620 (the current tile test), L42 `style()`. `test/pages.test.js` L176–192 mount test (best of 3, 2 s allowance) at whatever `dashTab` is stored; `planner.js` L26 remembers the tab, so tiles cost the dashboard load only when a student left Looks open.

### 2. Current behaviour
Twenty-six tiles, all built when the Looks tab opens; no rail, no course colour, no page shape; wallpaper only as a scrim. Locked ones priced, worn one ticked (tested).

### 3. Options and cost
- **(a) CSS mini-page from tokens.** ~14 nodes per tile, 26 tiles ≈ 360 nodes and 26 inline `style` strings; build < 5 ms, one layout. No scaling step at all if the drawing is written in container units (`cqw`, Chrome 105+/Firefox 110+): the tile *is* the page at 4:3. A pure `tileTokens(look, dark, courses, art)` in themes.js is unit-testable in node. Image cost is unchanged from today: the same 8 wallpapers already decode for the current tiles (a 1920×1080 decode is ~8 MB of bitmap each; Chrome does not decode smaller for a small `cover` paint, known-from-experience, not measured). A follow-up: `bridge/art-pack.sh` also writes `wallpaper-thumb.webp` (480×270, ~20 KB) per theme and tiles use that: 8 files, 160 KB, decode cost gone.
- **(b) Clone the live DOM into a shadow root per tile.** Canvas's card markup is ~40 nodes; two cards plus the rail cloned 26 times ≈ 4–5k nodes, and the skin cannot reach inside a shadow root (it hangs off `html.pk-on.pk-theme-x`), so each tile needs a rewritten copy of skin.css injected; a student's own card picture gets cloned 26 times; the test depends on Canvas markup being present. High cost, low fidelity. No.
- **(c) Offscreen iframe per theme.** 26 documents; a Canvas iframe is 26 page loads (network, forbidden); a `srcdoc` iframe still needs the skin and its images per frame. No.
- **(d) Pre-rendered images.** Cannot show this student's colours or dark/light without 26×2×N pictures; that is today's tile with more bytes. No, except the thumb wallpapers in (a).

### 4. Edge cases
- Fewer than two courses, or `colorHex` null (the colours endpoint 401s on some schools; `safeColor` rejects junk): fall back to `p.mark`, then `p.rule`. The tile still renders.
- Dark toggle: tile shows the current mode's stock (the key already includes `skin.dark`).
- Image theme whose folder is missing: `artFor` gives the placeholder svg; tile still works.
- Banner rotation is `nth-child(4n+k)` on the page; a tile shows card-1 and card-2 on its two cards: close enough, say so in the comment.
- The tick must not sit on the price: tick top-right of the scene, price under the name (as today).
- Own card pictures stay out of tiles (no extra decode, and the tile sells the theme, not the photo).
- 768 wide: the existing 2-up rule keeps tiles ≥ 300px; at 4:3 that is 225px tall, fine.
- Reduced motion: no animation in tiles; the existing `transform: translateY(-1px)` hover is on `ours` CSS and untouched.

### 5. Recommendation
**Option (a): each tile is a 4:3 mini dashboard drawn from the theme's tokens and the student's first two course colours in container units, with the token maths in one pure function that node tests and one e2e assertion per token.**

What the student sees: paper (or wallpaper under the theme's wash), the rail strip in the theme's rail colour, a title bar and a link line in the accent, two cards with their own classes' colour bands (image themes: the banner over the colour strip), the rail card beside them; worn one ticked, locked ones priced.

DOM of one tile (planner.js `plLookTile`):
```html
<div class="pk-pl-look wearing" role="button" aria-pressed="true" data-look="matcha"
     style="--tp:#EEF3EC;--tp2:#F6F9F5;--tr:#D7E1D6;--ti:#1E2620;--ti2:#4A5A4E;--ta:#3F7A52;--trail:#2F5A3C;--tc1:#5A92E5;--tc2:#B23B62;--twall:none;--twash:transparent;--tcard1:none;--tcard2:none">
  <div class="scene" aria-hidden="true">
    <i class="rail"></i>
    <div class="page">
      <b class="title"></b><i class="link"></i>
      <span class="card"><i class="band" style="--band:var(--tc1);--art:var(--tcard1)"></i><em></em><em></em></span>
      <span class="card"><i class="band" style="--band:var(--tc2);--art:var(--tcard2)"></i><em></em><em></em></span>
      <span class="side"><em></em><em></em><em></em></span>
    </div>
  </div>
  <span class="tick">✓</span>
  <b>Matcha</b><small>sage, clay, quiet morning</small>
</div>
```
CSS that sizes it (skin.css, under `#pk-looks`):
```css
#pk-looks .pk-pl-look .scene { container-type: inline-size; width: 100%; aspect-ratio: 4 / 3; border-radius: 8px; overflow: hidden;
  display: grid; grid-template-columns: 11cqw 1fr; color: var(--ti);
  background: linear-gradient(var(--twash), var(--twash)), var(--twall) center / cover, var(--tp); }
#pk-looks .pk-pl-look .rail { background: var(--trail); }
#pk-looks .pk-pl-look .page { padding: 6cqw 6cqw 0; display: grid; grid-template-columns: 1fr 1fr 32cqw; gap: 4cqw; align-content: start; }
#pk-looks .pk-pl-look .title { grid-column: 1 / 3; height: 5cqw; width: 34cqw; border-radius: 1cqw; background: var(--ti); }
#pk-looks .pk-pl-look .link { grid-column: 3; height: 5cqw; width: 18cqw; border-radius: 2.5cqw; background: var(--ta); justify-self: end; }
#pk-looks .pk-pl-look .card, #pk-looks .pk-pl-look .side { background: var(--tp2); border: 1px solid var(--tr); border-radius: 3cqw; overflow: hidden; height: 42cqw; }
#pk-looks .pk-pl-look .band { display: block; height: 14cqw; background: var(--art, none) top / cover no-repeat, var(--band); }
#pk-looks .pk-pl-look em { display: block; margin: 3cqw 3cqw 0; height: 2.5cqw; border-radius: 1cqw; background: var(--ti2); opacity: .55; }
#pk-looks .pk-pl-look em:nth-of-type(2) { width: 55%; }
```
`tileTokens(look, dark, courses, art)` lives in themes.js next to `artFor`: stock via `stockFor`, accent/rail/wash/wallpaper exactly as `themeStyle` computes them (share the two small helpers rather than copying), `--tc1/--tc2` from `courses[0..1].colorHex ?? p.mark`.

Tests:
- Node (`extension/receipt.test.js`): `tileTokens(THEMES_BY_ID.graffiti, true, [{ colorHex: '#112233' }], art)` contains `--tp:#17191D`, `--tc1:#112233`, `--tc2:#6FA8DC`, `--twall:url("x.webp")`, `--twash:rgba(23, 25, 29, 0.72)`; and for every theme in both modes the string has no `undefined`.
- E2E (`test/receipt.test.js`, extend L616): with `rgb()` from the hex, `style(page, '#pk-looks .pk-pl-look[data-look="matcha"] .scene', 'backgroundColor') === rgb(PAPERS[stockFor(look,false)].paper)`; `.rail` `backgroundColor === rgb(look.rail.light)`; `.card:first-of-type .band` `backgroundColor === rgb(courses[0].colorHex)` (the fake's first course colour); `.link` `backgroundColor === rgb(look.accent.light)`; graffiti's `.scene` `backgroundImage` matches `/art\/graffiti\/wallpaper\.webp/`; toggle `skin.dark` and the matcha scene becomes `rgb` of the `moss` paper.
- Zero network: collect `page.on('request')` from the tab click to `networkidle`; assert every URL starts `chrome-extension://`.
- Budget: a second `dashboard: the skin does not delay the cards` run with `dashTab: 'looks'` in storage, same `on <= off + 2000` rule (expect well under +100 ms).

### 6. Confidence
High on (a) and the tests. Medium on the decode numbers (not measured; the thumb follow-up removes the question). Unknown: whether `cqw` inside the dashboard's `#content` hits any Canvas `container-type` ancestor (would only change the unit's base; the tile sets its own container).

---

## Q4. The Planner tab shape (where implementation cost changes the answer)

(d) is settled by reading, not guessing: the buddy panel opens only through `openSearch()` (content.js L1574, L2205: ⌘K and the search pill) in the `search` view; the buddy's own button no longer opens it (L2226–2233, "No panel behind him any more"); the header with the coins button (`data-view="looks"`, L2168) renders only when `ui.view === 'panel'` (L2144); and every door into `weekView` (`data-filter="week"` L2297), `addTaskView` (L598), `courseView`/`whatIfView` (L788/790 inside `gradesCard`) and `recapView` (L600) is rendered by `panelView`, which nothing reaches. So `panelView`, `panelViewFallback`, `weekView`, `looksView`, `addTaskView`, `gradesCard`, `leagueCard`, `courseView`, `whatIfView` and `recapView` are dead from the UI; no test in `test/*.js` or `extension/*.test.js` names any of them (grep, zero hits), only the export list at L2576. Deleting them is cheap; moving `whatIfView`/`courseView`/`recapView` onto the Planner tab means porting their maths, not their markup (they are template strings for the shadow panel). On (a): vertical at every width is one layout and one test, and B7 is a column-width bug that vertical removes for free; columns above some width would keep both layouts alive in `pages.test.js` at 1280 and 768.

---

## Q5. Order and cuts, and Firefox

### 1. Evidence inspected
- `extension/manifest.json` (every key). `extension/background.js` L11–12 script lists, L20–30 `importScripts` ×3, L59–62 `self.addEventListener`, L66/L80 `onInstalled`/`onStartup`, L107–160 `chrome.scripting.registerContentScripts`/`executeScript`, L378/403 `chrome.permissions`, L804 `chrome.action.setBadgeText`, six `chrome.alarms.create`, `chrome.runtime.onUpdateAvailable`/`reload`.
- `extension/popup.js` L454–470 (`chrome.sidePanel?.open` guarded, `chrome.windows.getCurrent`), L134 `permissions.request`, L64 `navigator.clipboard`. `extension/planner.js` L121 `chrome.storage.local.set(...).catch(...)` (promise style; ~40 such chains across files). `extension/content.js` L1263/1294/1300 `OffscreenCanvas`/`createImageBitmap`, L1952/L2010 the Sprout iframe at `chrome.runtime.getURL('sprout/index.html')`. `extension/sprout/assets/`: a minified Vite bundle (297 KB js) plus a 1.2 MB dotlottie wasm.
- `extension/skin.css`: `:has()` ×7, `text-wrap: pretty` L178, `container-type`; `panel.css` `:has()` ×1.
- `test/harness.js` L14–56: Playwright **Chromium** with `--load-extension`. `bridge/package.sh`: one zip of `extension/`, Chrome only.
- Fetched today: MDN `manifest.json/background`, `sidebar_action`, `browser_specific_settings`, `host_permissions`, `Content_Security_Policy`; browser-compat-data JSON for `background`, `side_panel`, `web_accessible_resources`, `optional_host_permissions`, `content_security_policy`, `api/sidebarAction`.

### 2. Current behaviour
Chrome-only manifest and packaging; the code itself uses no Chrome-only API except `chrome.sidePanel` (already guarded) and `importScripts`.

### 3. What breaks on Firefox MV3, item by item
| # | Item | Fact | Source |
|---|---|---|---|
| 1 | `background.service_worker` | Firefox: `version_added: false`. Needs `background.scripts: ["errlog.js","canvas.js","config.js","background.js"]`. From Firefox 121 the page starts even when `service_worker` is also present; from Chrome 121 `scripts` is ignored. One manifest can carry both **only if** `minimum_chrome_version` goes from 116 to 121 (Chrome 116–120 refuse `scripts`). | BCD + MDN, fetched |
| 2 | `importScripts(...)` L20/24/28 | Worker-only global; an event page throws `ReferenceError` on line 20 and the background is dead. Guard with `typeof importScripts === 'function'` and list the files in `scripts`; `config.js` must then always exist (the try/catch around it stops working), so `apply-config.sh` writes a `null` config rather than none. | verified-by-reading |
| 3 | `self.addEventListener('error'…)` L59 | Works on a page (`self === window`). | known-from-docs |
| 4 | `side_panel` key, `sidePanel` permission | Firefox: `side_panel` `version_added: false`. Firefox wants `sidebar_action: { default_panel: "sidepanel.html", default_title, default_icon }` (MV3 ok; `browser_style` not). `browser.sidebarAction.open()` exists since Firefox 57; call it in popup.js's click handler beside the `chrome.sidePanel` branch. Whether Firefox errors or only warns on the unknown `sidePanel` permission string: **unverified**. | BCD + MDN, fetched |
| 5 | `use_dynamic_url: true` | Firefox: `version_added: false` (ignored; resources sit at the per-install `moz-extension://<uuid>/`). Sprout iframe still resolves. Whether AMO's linter warns: **unverified**. | BCD, fetched |
| 6 | `host_permissions: supabase` | Firefox treats host permissions as user-grantable; MV3 shows them at install from 127 but the grant is the user's. The bridge `fetch` from the background may still pass on CORS alone (Supabase REST answers `*`): **unverified**. Safe fix: ask for the supabase origin in the same `permissions.request` the popup already makes for the school (L134). `optional_host_permissions`: Firefox 128+. So the floor is **Firefox 128**. | MDN + BCD, fetched |
| 7 | `browser_specific_settings.gecko.id` | Mandatory for MV3 signing (AMO or self-hosted); Chrome ignores the key. Add `strict_min_version: "128.0"`. AMO's newer `gecko.data_collection_permissions` requirement: **unverified**. | MDN, fetched |
| 8 | `chrome.scripting.registerContentScripts` with `css`, `runAt`, per-origin after the grant | Firefox 101+ MV3; needs the host permission first (the popup asks first, so fine). `persistAcrossSessions` on Firefox: **unverified**; `onStartup` (L80) re-registers anyway. | MDN, fetched |
| 9 | Promise style on `chrome.*` (`.then/.catch`, `await`) everywhere | MDN's cross-browser page only says Firefox supports callbacks on `chrome.*` and recommends `browser.*` for promises. Whether `chrome.storage.local.set()` returns a promise in Firefox MV3 is **unverified**; if it does not, ~40 chains throw. Five-minute check in a Firefox: `typeof chrome.storage.local.get('x')?.then`. Fix if needed: `const api = globalThis.browser ?? chrome` and replace `chrome.` in the six files (`chrome` itself cannot be redeclared). | unverified |
| 10 | Web platform: `AbortSignal.timeout`, `OffscreenCanvas`, `createImageBitmap`, `:has()`, `cqw`, `-webkit-line-clamp` | All in Firefox ≤ 121; `text-wrap: pretty` is ignored harmlessly. | known-from-docs, versions from memory |
| 11 | CSP `'wasm-unsafe-eval'` | Allowed from Firefox 102; the Sprout wasm keeps working. | MDN, fetched |
| 12 | `minimum_chrome_version` | Chrome-only key; Firefox ignores it (warn or silent: **unverified**). | MDN |
| 13 | `chrome.action`, `alarms`, `tabs.query`, `runtime.reload`, `onUpdateAvailable`, `storage.onChanged` | All in Firefox MV3. | known-from-docs |
| 14 | AMO review | The Sprout bundle is minified: AMO requires the source (`ios/SproutWeb`) and build steps with the submission. | known-from-docs (AMO policy); our bundle verified-by-reading |
| 15 | Tests | `harness.js` is Chromium-only and Playwright cannot load Firefox extensions. Firefox proof = `web-ext lint` in CI (static, catches items 1, 4, 5, 7, 12) plus one `web-ext run` smoke against `test/fake-canvas.js` (login → dashboard carries `pk-on`) driven by geckodriver. The 39-test e2e suite does not port cheaply. | known-from-docs |

### 4. Edge cases
- One manifest for both browsers is possible (items 1, 4, 5, 7 are all "ignored by the other side") but hinges on the unverified warn-vs-error behaviour in item 4 and a Chrome floor of 121; the two-manifest build step (`bridge/package.sh --firefox`: copy `extension/`, rewrite the eight keys with ~30 lines of python, zip) has no unknowns.
- Firefox's per-install UUID means `use_dynamic_url`'s fingerprint goal is already met there.
- Item 9 is the one that could turn a packaging day into a refactor day; check it first.

### 5. Recommendation
**Keep the order 4 → 10, fold step 7 (course-home next-three) into step 5 because both reuse the rail row (`classTile` + the row shape) and the planner's list code, cut nothing, and time-box Firefox to one day behind a `web-ext lint` CI job, with item 9 checked in the first ten minutes.** Concretely for Firefox: (1) `web-ext lint` on `dist/firefox/` in CI; (2) `package.sh --firefox` writes the second manifest (items 1, 4, 5, 6, 7, 12); (3) the `importScripts` guard and the `sidebarAction.open` branch (items 2, 4); (4) the supabase origin joins the popup's permission request (item 6); (5) one smoke test with geckodriver against the fake Canvas; (6) the Sprout source zip for AMO (item 14).

### 6. Confidence
High on items 1, 2, 4, 5, 7, 11, 15 (fetched or read). Medium on 6, 8, 10, 13 (docs from memory). Low on 9, 12, and AMO's newer keys: marked unverified above; none of them needs more than a Firefox and ten minutes to settle.

---

## Two things noticed on the way (not asked)
- The button lint skips every selector containing `*` (`sel.includes('*')`, receipt.test.js L329): 46 selectors today, none of which would fail. Remove the skip in the same commit as the carve-out so `[class*="baseButton"]`-style selectors are linted too.
- `design/signoff/canvas-pages/report.json` only holds the last subset run (quiz light/dark). The full-run numbers the verdict quotes (B8 mount times) are not on disk in this checkout.
