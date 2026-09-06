# BetterCanvas/BetterCampus feature parity

Sources: `design/canvas-skin/RESEARCH.md` (§6, §7), `extension/content.js`,
`extension/popup.html`, `extension/skin.css`, `extension/panel.css`,
`extension/README.md`, `design/canvas-skin/CONCEPTS-SELECTION.md` and the three
SPEC files. BetterCampus feature list is from RESEARCH.md's teardown (source
code read Nov 2024, store listing checked through 2026-08-28) — I did not have
web access this session to re-check bettercanvas.org live, so treat "current"
BetterCampus claims as RESEARCH.md's, not a fresh September 2026 check.

## Feature table

| Feature | BetterCanvas/BetterCampus | Prepkin status | Where in Prepkin | Effort | Notes |
|---|---|---|---|---|---|
| Dark mode | Free (BetterCanvas); one 30,410-char CSS string, 61 `!important`s, can hide submit button | **Have** | `extension/skin.css:47` (`.prepkin-dark`), toggle `extension/content.js:41-42`, popup checkbox `extension/popup.html` "Dark mode" | — | Real CSS file with custom properties, not a string blob. Warm charcoal, not grey. |
| Dashboard card restyle (bg, corners, hover) | Free | **Have** | `extension/skin.css:124-141` (`.ic-DashboardCard`) | — | No card images/roundness/spacing *controls* — see gap below. |
| Due dates surfaced off-dashboard (Today/overdue list) | Free, core feature | **Have** | `extension/content.js:271-297` (task list + filter buttons) | — | Own panel, not a Canvas-page overlay. |
| Assignment due dates on dashboard cards themselves | Free | **Missing** | none found | S | Panel shows dates; the Canvas dashboard card itself doesn't get a due-date badge. |
| GPA calculator | Free | **Have** | `extension/content.js` (`gpa()`, `LEVELS`) | — | Unweighted estimate plus a weighted line once the student marks a class Honors (+0.5) or AP (+1.0) in the panel; saved under `levels`. |
| Grade what-if calculator | Free (targets `#grade-summary-content`) | **Have** | `extension/content.js:429` (`whatIfView`), `208-214` (`targetsFor`) | — | Per-course, asks for assignment-group weight when Canvas doesn't publish it. |
| Hide completed / hide To-Do sidebar items | Free, most-shared tip (RESEARCH §7.3) | **Missing** | none | S | Own panel already separates done/today, but native Canvas To-Do sidebar isn't touched. |
| Custom fonts / dyslexic font | Free (some forks) | **Rejected by design** | `RESEARCH.md:527` ("ship a system stack and no web font") | — | Deliberate: avoids a network call from inside a school's LMS. |
| Sidebar width / density toggle (full-width, condensed, normal) | Free (BetterCanvas ships 3 toggles) | **Have** (one toggle) | popup "Compact pages" → `skin.dense` → `html.pk-dense` in `skin.css` | — | Cards 220px with 56px heroes, tighter list rows. Hides nothing. Shot: `design/signoff/themes/dense-live-*.png`. |
| Sidebar cleanup (remove help link, logo, badge) | Free | **Partial** | `extension/skin.css:147-149` (`.prepkin-tidy`) | — | Removes 3 items; BetterCanvas removes more (e.g. logo variants) — not itemized here. |
| Card image / roundness / spacing / width controls | Free (Canvas Refined fork) | **Missing** | none | M | RESEARCH §6.4 names this as Canvas Refined's differentiator, not BetterCanvas's own. |
| Custom page background | Free (Canvas Refined) | **Missing** | none | M | Same source. |
| Focus/study timer | Not in BetterCanvas | **Have (Prepkin-only)** | `extension/content.js:299-312`, `548-578` (focus card) | — | Prepkin feature BetterCanvas doesn't have. |
| Coins/reward economy tied to real submissions | Not in BetterCanvas | **Have (Prepkin-only)** | `extension/content.js` COIN_REWARD, README "What the buddy panel does" | — | Distinct differentiator. |
| Mascot/character overlay | Not in BetterCanvas (no student asked for one, RESEARCH §7.3 item 6) | **Have, opt-out** | popup.html "Buddy on Canvas pages" toggle | — | Intentional: RESEARCH says mascot is fine because it's opt-in, panel-scoped, dismissible. |
| AI study suite / paid tier ($19/mo or $119/yr) | Paid (BetterCampus) | **Rejected by design** | Prepkin has no account, no paywall (README, popup.js "Free · no account needed") | — | Explicit non-goal; RESEARCH §6.1 and §7.3 point at the paywall revolt as an opening. |
| Custom themes / cute GIFs on cards | Paid now (was free) | **Rejected by design** | SPEC files reject decoration on the page skin; see "should not copy" below | — | Hotlinked images from Pinterest/Tumblr/Giphy are explicitly banned (`RESEARCH.md` §6.2, §8). |
| Modules page density/click reduction | Not shipped by BetterCanvas either | **Missing** | none | L | Ranked #1 in Instructure's own vote but skews instructor/admin per RESEARCH §7.1. |
| Native same-origin iframe dark mode (DocViewer/Canvadocs) | Some forks (Canvas Dark Mode) | **Missing** | none | M | RESEARCH §1 confirms these frames are reachable via `all_frames`, not yet used. |
| Selector strategy avoiding InstUI hashes | BetterCanvas fails this (79 hashed selectors, top complaint) | **Have** | `extension/skin.css` uses stable `.ic-*`/`#`/testid selectors only | — | Matches RESEARCH §8 rule 1. |
| SPA-navigation persistence (features surviving tab changes) | BetterCanvas fails this (§6.2) | Not verified this pass | — | — | RESEARCH §5.3 flags this as a shared gap; needs a live-Canvas check, not found by reading source alone. |

## Top 10 gaps worth closing first

1. **Due date on the dashboard card itself** — the #1 ranked student complaint (RESEARCH §7.1) is "I cannot tell what's due"; the panel has this but the card a student's eye lands on first doesn't.
2. **Hide/collapse completed items in the native To-Do sidebar** — RESEARCH §7.3 says the most-shared community tips are subtractive; this is a cheap, high-signal one Prepkin skips entirely.
3. **Sidebar width/density toggle** — done 2026-09-05 as the Compact pages toggle.
4. **Same-origin iframe dark mode (DocViewer/Canvadocs)** — closes the "white screen at 2am" complaint fully instead of partially; confirmed technically reachable in RESEARCH §1.
5. **SPA-navigation persistence check** — BetterCanvas's top structural failure; worth a deliberate test since it's the one item this audit couldn't confirm from source alone.
6. **Card image/roundness/spacing controls** — students explicitly quote "putting gifs on my class cards" as a favorite (RESEARCH §7.2); a *safe*, non-hotlinked version (local upload, no Pinterest fetch) could capture the joy without the district-blocking risk.
7. **Custom page background** — same audience delight, same "reads nothing, sends nothing" constraint, cheap to add as CSS only.
8. **Contrast-checked submit-button audit in dark mode** — BetterCanvas's most damaging bug was hiding the submit button; worth a defensive pass even without "adding" a feature.
9. **GPA calc: weighted option** — done 2026-09-05: Regular / Honors / AP chips per class in the panel.
10. **Modules-page click reduction** — largest scope (L effort) and lower confidence it's student-driven (RESEARCH flags the vote as instructor/admin-skewed), so it's ranked last despite being Instructure's own #1 vote item.

## What NOT to copy from BetterCanvas, per the design docs

- **Paid theme tier / AI study suite behind a $19/mo paywall** — Prepkin's whole positioning is "free, no account" (README, popup onboarding copy); RESEARCH §6.1/§7.3 treats the paywall backlash as the opening, not a model.
- **Hotlinked theme images from Pinterest/Tumblr/Giphy/Reddit** — RESEARCH §6.2 counts thousands of these and calls them a privacy and reliability risk ("every dashboard load pings Pinterest"); explicitly banned.
- **A mascot/character imposed on the Canvas page itself** — RESEARCH §7.3 item 6: no student asked for a character *inside* Canvas, only customization of their own space. Prepkin's mascot stays opt-in and panel-scoped, never forced onto the page skin.
- **Selectors containing InstUI `css-` hashes** — the documented cause of BetterCanvas's #1 complaint ("dark mode broke again"); RESEARCH §8 rule 1 bans it outright, and Prepkin's CSS already avoids it.
- **Undebounced whole-document MutationObservers** — RESEARCH §5's corrective (a single debounced observer) exists specifically because this is BetterCanvas's documented cause of "canvas got slow."
- **"Never red" / at-risk labeling on grades** — RESEARCH §1 (grades section) bans performance framing and red; BetterCanvas's what-if and grade views don't carry this constraint, Prepkin's do.
- **Broad permissions (`<all_urls>`, matching calendar.google.com/outlook)** — RESEARCH §6.1 flags BetterCampus's permission escalation as a red flag; Prepkin's per-site `optional_host_permissions` model is the deliberate alternative (README "Permissions, and why").

## Added 2026-09-05, after the BetterCampus element read

See `research-bettercampus-elements.html` for the full element-by-element table.

| Element | Prepkin now | Where |
|---|---|---|
| Nav rail in the theme colour | **Have.** `rail` per theme; image themes show the wall through a wash. Receipt row `rail`, Put back restores Canvas's own. | `themes.js`, `skin.css` (rail block), R13 |
| Grade pill on course cards | **Have, opt-in.** Popup toggle "Your grade on course cards", off by default. Row `card-grade`. | `content.js` decorateCards, R14 |
| Pick a banner per course | **Have.** Worn image theme's sheet lists each class with the theme's banners. | `content.js` bannerPicker, R15 |
| Surface + link colours per theme, course nickname, card roundness | Not yet | next |
