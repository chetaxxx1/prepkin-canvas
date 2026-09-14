# BetterCampus 9.8.11 — Feature Teardown

Reverse-engineered from the shipped Chrome extension build (prev. "BetterCanvas"), version 9.8.11, obtained as an unpacked `.crx`. Every claim below cites a line number in the **prettified** source (`prettier@3 --parser babel`), so the numbers below do **not** match the original minified files — they match the prettified copies produced for this analysis. Both trees live under this session's scratch dir:

- Original (minified) source: `.../scratchpad/bc/9.8.11_0/`
- Prettified working copy (all citations below refer to this): `.../scratchpad/bc-analysis/pretty/` — `all.pretty.js` (189,574 lines, from `content-scripts/all.js`), `background.pretty.js` (20,208 lines), plus prettified `extension-bridge.js`, `googlecalendar.js`, `outlookcalendar.js`, `stripe.js`, `theme.js`, `viewer.js`, `all.css`, `viewer.css`.

No claim in this document is guessed. Every setting default, URL, API route, and selector cited was read directly out of the code at the line given.

## Zero-th finding: this is no longer just a Canvas extension

The settings schema and a settings-change dispatcher both contain live keys and adapter classes for **six platforms**: Canvas, Blackboard, Moodle, Brightspace/D2L, Google Classroom, and Gradescope (detected via `"www.gradescope.com" === window.location.hostname`, `all.pretty.js:189212`, and a `lms_sync_type`/`custom_domain` pair of settings). Examples: `sidebar_pages_brightspace`, `sidebar_pages_moodle`, `blackboard_sidebar_collapsed`, `classroom_hide_due_soon`, `gradescopeData`. This report follows the task brief and focuses on **Canvas** behavior; multi-LMS code is noted only where it clarifies a Canvas-specific finding.

---

## Table of contents

- (a) Settings — the master schema, and how Pro/entitlement gating actually works
- (b) Features by Canvas page
- (c) The dashboard
- (d) Grades
- (e) The Navigator + external hostnames
- (f) Themes
- (g) Sidebar
- (h) Calendar integrations
- (i) viewer.js (canvadocs)
- (j) Quiz safety
- (k) Streaks / gamification (+ the virtual-pet economy)
- (l) Performance
- (m) Telemetry / accounts / Stripe / referrals
- The full feature list, one line each
- Settings keys, raw

---

## (a) Settings — the master schema, and how Pro gating actually works

### Where it lives

There is one **central settings schema**, not scattered inline defaults: object literal `sg` at `all.pretty.js:10361-10769` (source: `content-scripts/all.js`). Every entry is `key: { syncType: "server"|"device", default: <value> }` (a few also carry `encrypted: true`). `syncType:"server"` = synced via `chrome.storage.sync` (~221 keys, cross-device); `syncType:"device"` = `chrome.storage.local` only (~40 keys — caches, popup position, device id, tour state).

Right after the schema (`all.pretty.js:~10850-10859`), two derived flat maps are built: `ug` (all server defaults) and `hg` (all device defaults), combined as `mg = {server: ug, device: hg}` (referenced elsewhere as `mg.server.card_width`, etc.).

Individual features read live values with `hp(["key"])` (sync read) / `Gp(["key"])` (reactive hook) / `up(["key"])` (async read), and write with `mp({key: value})`. A separate **settings-change dispatcher** (`all.pretty.js:~183196-183461`, a big `switch` on key name) lists every key that triggers a live UI reload when changed, grouped by which feature reloads — e.g. `dark_mode`/`dark_preset`/`light_preset`/`device_dark`/`auto_dark_start`/`auto_dark_end`/**`quiz_safe_mode`** are all grouped under one `"darkModeToggle"` action, meaning quiz-safe-mode is implemented as part of the dark-mode/theme system rather than a standalone kill-switch (see section (j)).

### messages.json is vestigial — do not trust it for current labels

`_locales/en/messages.json` has only 90 keys. But `grep -c 'i18n.getMessage'` across both `all.pretty.js` and `background.pretty.js` returns **zero**. The current React/JSX settings UI hardcodes English strings inline; it does not call `chrome.i18n.getMessage` anywhere. Several message IDs there don't correspond to any live storage key any more — `hide_school_logo`, `universal_search`, `show_past_due`, `useddmm`, `todo_remind`, `todo_hr24` all return **zero** hits as literal strings elsewhere in the codebase (the live equivalents are `hide_bettercanvas_logo`/`remlogo`, `global_search`, `todo_overdues`, a `date_format` picker, unfound, and `todo_24hr`, respectively). Treat messages.json as a historical artifact of an older UI, kept only so `default_locale` in the manifest resolves. `manifest.json` itself also hardcodes its name/description as plain strings rather than `__MSG_name__` placeholders.

### Pro / entitlement gating — the real mechanism

**Almost none of the ~221 individual settings toggles are themselves flagged Free vs. Pro.** Nearly every dashboard/todo/card/sidebar/theme toggle is available to a signed-out user. Gating instead happens through two systems layered on top of the settings:

**1. A paywall/entitlement registry** — object `Rf`, `all.pretty.js:10047-10108`, mapping a feature key to a `paywall_id` and trigger type, fired via `Ife(featureKey)`:

| Feature key | `paywall_id` | Trigger | What it gates |
|---|---|---|---|
| `notesLimit` | `rd_notes_limit_reached` | limit_reached | Notes count/storage-byte cap. Exact UI copy: *"You've reached your notes limit (`{count}/{limit}`). Upgrade to create unlimited notes."* (`all.pretty.js:79522-79525`) |
| `themeSwapLimit` | `rd_theme_swap_limit_reached` | limit_reached | Free theme-swap cap (see section f) |
| `themeSaveLimit` | `rd_theme_save_limit_reached` | limit_reached | Free custom-theme-save cap |
| `transcriptTrialLimit` / `transcriptFairUseLimit` | `rd_transcript_trial_limit` / `rd_transcript_fair_use_limit` | limit_reached | AI audio/video transcription — trial minutes, then an ongoing fair-use cap even on paid plans |
| `filesaiTrialLimit` / `filesaiFairUseLimit` | `rd_filesai_trial_limit` / `rd_filesai_fair_use_limit` | limit_reached | "Files AI" (AI chat over course files) — trial uses, then fair-use cap |
| `accountRequired` / `accountRequiredUpgraded` | `rd_account_required_feature_gate` / `..._upgraded_feature_gate` | feature_gate | Generic "needs a free account" vs. "needs a paid account" gates |
| `annotationsAccountRequired` | `rd_annotations_account_required` | feature_gate | PDF annotation requires an account |
| `quoteWidget` / `musicWidget` / `breatheWidget` | `rd_{name}_widget_feature_gate` | feature_gate | The three dashboard widgets require an account |
| `upgradePage` / `upgrade` | `um_generic_upgrade_cta` | upgrade_cta | Generic "Upgrade" CTA |

Related gate codes in the same block (`all.pretty.js:10111-10116`): `TG_STUDY_FILES_LIMIT_REACHED`, `TG_THEME_SWAP_LIMIT_REACHED`, `TG_STICKER_SLOTS_LIMIT_REACHED`, `TG_POST_SIGNUP_TRIAL_OFFER_FEATURE_GATE`. `Ife("themeSwapLimit")` is actually called from theme-picker click handlers at `all.pretty.js:144444,144571,144578`; `Ife("sticker_slots")` at `all.pretty.js:154249`.

**2. A numeric entitlement/quota system.** Array `Ao` (`all.pretty.js:4952-4968`) names the quota types a plan can carry: `planned_assignments, audio_tokens, text_tokens, smart_notes, streak_restores, note_storage_bytes, note_file_uploads, theme_remixes, theme_creations, theme_swaps, note_highlights, study_sets, study_highlights, study_chats, study_storage_bytes, study_file_count, private_material_count`. The actual numeric caps per plan are **not hardcoded client-side** — enforcement is server-driven off the user's plan entitlements.

Plan-tier arrays: `wo = ["none","free","trial","unlimited"]`, `ko = ["trialThenPro","prolite","pro","style","limited"]` (`all.pretty.js:~4945-4947`). The `"trialThenPro"` tier, plus settings `trial_card_dismissed` (10471) and `trial_end_dismissed`/`trial_2d_dismissed` (10648-10649), confirm new signups get a **temporary free trial of Pro that then reverts to Free**. Plan state reads as `user.app_metadata.plan_type` off the stored `auth` object (default `null`, `all.pretty.js:10560`) — a Supabase-style auth user (Supabase project `tgsubtjsssttyptpovop.supabase.co`, found in `background.pretty.js`).

**One concrete free-tier number in the schema itself:** `noaccount_swaps: { syncType: "server", default: 5 }` (`all.pretty.js:10597`) — a key literally named "swaps allowed with no account." **5** is the strongest citable answer to "how many free theme swaps": five, before BetterCampus asks a signed-out user to create an account. A second, smaller, server-controlled cap then applies once signed in on Free (enforced through the `themeSwapLimit` paywall above; that number is not present client-side).

Standard trial length is **7 days** ("the usual week"); a referral bumps a new signup's trial to **14 days**, and credits the referrer **14 days of Pro** too, once their invitee starts a trial (paraphrased from four transactional-email templates at `all.pretty.js:14078-14122` — see section m).

### A found bug/typo

Schema key `gradent_cards` (`all.pretty.js:10413`, default `false`) — misspelled "gradient" — while `_locales/en/messages.json`'s id for the same idea is spelled correctly (`gradient_cards`, "Gradient Cards"), and a correctly-spelled `gradient_cards` is also used elsewhere in card-visual code (e.g. `all.pretty.js:136397-136420`). Looks like an orphaned key left behind by a rename.

### How the extension's UI actually opens — there is no popup.html

`manifest.json`'s `action` block has **no `default_popup`** (confirmed by direct read of the file). Instead, clicking the toolbar icon fires `(chrome.action ?? chrome.browserAction).onClicked` in the service worker (`background.pretty.js:19739-19798`), which branches three ways:
1. If `pending_hide_logo_confirmation` is true, the click IS the confirmation step of the "Hide BetterCampus Logo" flow (see section g.4) — it flips `hide_bettercanvas_logo:true` and closes the `puzzleIconGuide` tour, nothing else (`background.pretty.js:19745-19751`).
2. Else if the user hasn't configured a Canvas domain yet (`custom_domain`/`lms_sync_type` empty), it opens `/welcome?setup=lms-url` on `ext.bettercampus.com` in a new or existing tab (`background.pretty.js:19758-19783`) — i.e. first click routes to onboarding.
3. Else it messages the active tab's content script: `{action:"openEmbeddedSettingsMenu", launchOrigin:"toolbar"}` (`background.pretty.js:19786-19797`). **The toolbar icon has no popup of its own — it asks the Canvas-page content script to open an in-page (shadow-DOM) settings panel.**

---

## (b) Features by Canvas page

### How Canvas is detected and how page routing works

Two independent checks decide "is this Canvas": a hostname allowlist `{instructure.com, www.instructure.com, community.canvaslms.com}` (matched as a suffix, so any `*.instructure.com` counts), plus a DOM-probe fallback (`footer a[href*="instructure"]`, `#wrapper.ic-Layout-wrapper`) to recognize Canvas on a school's white-labeled custom domain. Once detected, the Canvas adapter's `init()` bails out entirely (returns `null`, loads nothing at all) on login-family paths: `^/(login|logout|signup|register|forgot_password)(?:/|$)`.

Feature dispatch is a real **`{matches: RegExp, feature: instance}` registry** (26 entries for Canvas specifically, `all.pretty.js:133495-133530`, extending a 13-entry shared-base default table), tested against `location.pathname` both on initial load and on every Canvas SPA route change (`pushState`/`popstate`), loading/unloading features live as you navigate without a full page reload. The named matcher constants: `UZe=/.*/ ` ("everywhere"), `XZe=/^\/$/` (dashboard root only), `ZZe=/^\/.+/` (any subpage), `JZe=/^(?:\/$|\/courses\/\d+)$/` (dashboard or a course home exactly). A handful of pages are handled *outside* this registry via ad-hoc pathname regexes instead (Files, Calendar/Conversations/Groups nav-badge sync).

### By page

| Page | Matcher | What's injected / computed | Key selectors |
|---|---|---|---|
| Login/logout/signup/register/forgot-password | `VZe` regex, checked in `init()` | **Nothing** — the entire Canvas adapter (sidebar, dashboard widgets, theme CSS, everything) refuses to load on these paths. | n/a |
| Dashboard (`/`) | `XZe` (14 registry entries use it) | New-vs-old dashboard detection; dashboard-ready detection via a `.ic-DashboardCard` MutationObserver; course card color/customization (real colors pulled from `GET /api/v1/users/self/colors`); assignment-count + grade badges on cards; drag-reorderable card order; the dashboard-notes sticky widget; GPA-calculator widget; a calendar-"Sync" shortcut; the search bar mounted at the dashboard header; new-dashboard grid restyled (radius/gap/size) via an injected style tag. | `#dashboard.ic-dashboard-app`, `.ic-DashboardCard`, `.ic-DashboardCard__header-button`, new-dash `div[data-testid^="course-grade-card"]` |
| Course home (`/courses/:id`) | `JZe` (todo widget) + `ZZe` (edit CTA) | The to-do widget also renders here, not just the dashboard. A "Customize/Edit" CTA button is mounted into the breadcrumb bar (permission-gated). | `.ic-app-nav-toggle-and-crumbs`, `.ic-app-crumbs a[href="/courses/{id}"]` |
| Assignments list (`/courses/:id/assignments`) | inline regex, 3 features | (1) A details button on each row fetches `GET /api/v1/courses/:id/assignments/:id` on click and classifies status/type from the row's own text. (2) A calendar-"Sync" button opens the Google/Outlook sync panel (gated by the `calendarSync` entitlement check). (3) A custom section is injected into the assignment-groups list. | `.ig-row[data-item-id]`, InstUI grid row class, `#ag-list` |
| Files (`/courses/:id/files*`) | raw regex tested directly, not via the registry | Toggles a class on `<html>` that scopes dark-mode/theme CSS to the file table. Separately, a popup promoting the extension's PDF-annotation viewer watches for Canvas's file-preview overlay (registry entry `matches: UZe`, so technically loaded everywhere but only activates on a file preview). | `.ic-Table`, `.ef-header`, `.ef-directory-header`, `.ef-file-preview-overlay`, `#file-preview-iframe` |
| Grades (`/courses/:id/grades`) | no dedicated matcher — reached via the sitewide sidebar stylesheet | The BetterCampus sidebar (~180px) is wider than the 84px Canvas assumes when laying out this page, so an injected fix (internal ticket "ENG-6986" cited in a code comment) shrinks the score/comment/details columns to percentage widths and, below 1200px viewport, hides the right-side rail so the grades table can reclaim width. | `#grades_summary th.assignment_score`, `#right-side-wrapper:has(#student-grades-right-content)` |
| Quizzes (`/courses/:id/quizzes*`) | **none found** — no dedicated matcher or pathname regex anywhere | Only sitewide dark-mode CSS reaches the quiz UI (present regardless, since `darkMode` matches "everywhere"). Quiz items get calendar-sync ICS URLs built for due-date export, and a Canvas quiz-metadata API is called for that same purpose. | `#quiz_show`, `#quiz_edit_wrapper`, `#questions .group_top` |
| Modules (`/courses/:id/modules*`) | **none found** | No dedicated feature — confirmed absent after 3 grep passes. Only effect: a static "Modules" link in the sidebar's per-course quick-link list, and sitewide hover-state CSS happening to restyle the native modules hover state. | sidebar link builder, `.context_module_item_hover` |
| Calendar (`/calendar`) | plain `pathname.startsWith("/calendar")`, used only for nav-badge sync | Maps the current path to Canvas's own nav-link id so the sidebar shows a matching highlight/badge. FullCalendar (Canvas's own widget) restyled by sitewide dark CSS. | `#calendar-app .fc-event`, `#minical` |
| Conversations/Inbox (`/conversations`) | same nav-badge mechanism | Message list restyled by sitewide dark CSS; no other feature. | `#inbox-conversation-holder`, `message-list .messages > li` |
| Groups / People (`/groups*`) | same nav-badge mechanism | Only the badge mapping. **No dedicated People/roster (`/courses/:id/users`) feature was found** after explicit greps for "people"/"roster"/"/users/" — treat as not specifically handled beyond generic theme CSS. | n/a |
| Discussions (`/courses/:id/discussion_topics*`) | **none found** | Sitewide dark CSS only; discussion-topic URLs are built for the planner/search data layer, not as a live-page feature. | `.discussion_entry`, `.discussions-v2__wrapper` |
| Pages (`/courses/:id/wiki_pages*`) | **none found** — no literal `wiki_pages` string anywhere | Sitewide dark CSS only. | `.pages.show .page-title` |
| Announcements (`/courses/:id/announcements`) | **none found** | Sitewide dark CSS on the live page; separately (not page-gated) a background layer computes an unread/read announcement map feeding the to-do aggregator. | `#announcementWrapper > div > div` |
| Syllabus (`/courses/:id/assignments/syllabus`) | **none found** for the live page | Sitewide dark CSS restyles the schedule table. A *separate* "Syllabus Import" feature (opened from the extension's own UI, not gated to being on this page) lets a user paste/drop a syllabus file or link that's parsed to auto-detect grade-cutoff boundaries for the GPA calculator. | `#syllabus tr.date.date_passed` |
| Profile (`/profile`) | **none found** | No dedicated feature. The only "profile" touchpoint reads the avatar out of Canvas's own persistent top-nav profile icon to auto-fill the extension's theming UI, plus a general (not page-gated) `GET /api/v1/users/self/profile` call. | `#global_nav_profile_link` |

**Cross-cutting**: "RCE dark mode" applies wherever Canvas's Rich Content Editor (TinyMCE) is present — the shared WYSIWYG used when creating/editing Assignments, Discussions, Announcements, and Pages — effectively a fourth "page" this reaches without its own route. The multi-LMS registry pattern repeats identically for Blackboard, Brightspace/D2L, Google Classroom, and Moodle, each a sibling adapter class with its own matcher constants — confirming the same `{matches, feature}` dispatch mechanism is shared across all six supported platforms, not special-cased per LMS.

---

## (c) The dashboard

### Better to-do list — data source and caching

30 literal `/api/v1/` Canvas call sites exist. The two that matter for the dashboard:
- **`GET /api/v1/planner/items?start_date=&end_date=&per_page=100`** (paginated via the `Link` header) — the primary to-do/planner feed (assignments, quizzes, discussions, planner notes, announcements).
- **`POST`/`PUT /api/v1/planner/overrides(/{id})`** — create/update a completion override (mark done/undone).

(The other 28 endpoints found feed adjacent features sharing the same file — grades/GPA, course tools/files/modules, an educator "needs grading" list via `GET /api/v1/users/self/todo` for instructor accounts, and `/api/graphql` for the search bar below.)

Caching is two-layered: (1) an **in-memory date-range "coverage" cache** (not persisted) that pads every fetch by at least 7 days beyond what was asked, so nearby follow-up queries are usually already covered; (2) the persisted device setting **`cached_planned_assignments`** (default `{}`), which holds the "planned"/custom side of the merge — notably, `planned_assignments` is also one of the plan-entitlement quota types (section a), suggesting planned-item generation may be server-computed and quota-limited (the generation endpoint itself wasn't located). A function `combineAllItems` reconciles three sources into one list: the Canvas planner cache, local custom items extracted from `overrides`, and `cached_planned_assignments` patches.

### Ring / progress indicator

Setting `todo_style` has **8 enum values**: `none, circle, rainbow, linear, heart, cloud, oiia, hellokitty` (default `circle`). `circle`/`rainbow` render concentric SVG arc rings, one per active course, sized to that course's complete/total ratio. `heart`/`cloud` clip the same progress math into a heart or cloud silhouette. `linear` renders one horizontal segmented bar. **`oiia` loads an actual video loop** (`https://assets.bettercampus.com/oiia.webm` — the "spinning cat" meme) as the progress visual instead of a static shape. **`hellokitty` is defined in the schema enum but has zero matching render code anywhere in the file — selecting it would currently render nothing** (a dead/orphaned option). Ring color per course reuses the same `cards[id].color` used for dashboard card theming, so the ring and the cards always match.

### Day / Week / Month views — a correction to the brief's own framing

`todo_time` (default `"week"`) is the view-range selector: **Day / Week / Month / Custom** — there is no "3 Days" value here. What the brief's "3 Days" likely refers to is a *separate* setting, `todo_overdue_viewable_period` (default `"week"`, enum `never/3days/week/month/always`) — how far back overdue/incomplete items keep showing. A `todo_custom_value`(default 7)/`todo_custom_unit`(days/weeks/months) pair lets a user pick an arbitrary window under "Custom." `todo_period_start` (default `"rolling"`, or a fixed weekday) controls whether the window is a rolling 7 days from today or a real calendar week. Switching views re-primes the coverage cache rather than bypassing it.

### New Assignment / custom task feature

Default task shape: `{id, title:"New Task", description, type:"assignment", course, due, points, url, duration, plannedAt, status, score, priority}`. Built-in types are Assignment/Quiz/Discussion/Study Session; `custom_assignment_types` adds global custom type names (≤30 chars, unique); `course_custom_types` adds per-course type lists that can also **import real Canvas Assignment Groups** so a custom task can be filed under an existing grading category. Supports **recurrence** — a recurrence template expands into N independent dated entries in one create call. Custom tasks are stored in the `overrides` setting as `custom_<uuid>` keys, but are **not purely local**: creates/deletes reconcile through to BetterCampus's own backend (not Canvas's), tolerating 404s on delete as a soft success. Completing a real Canvas item also pushes the completion back to Canvas via the planner-overrides API above.

### Card tasks, card grades, condensed cards, card images/colors

- **Card tasks** (`card_assignments`, default true): shows up to `num_assignments` items (default 4; UI slider goes 0-11 where 11 means "show all, no limit") per course card, from the same merged to-do pipeline. `card_display_mode` (`manual`/`balanced`, default `manual`): in "balanced" mode every card shows the same row count — the *minimum* count across all visible cards, not each card's own count. `card_crossout` controls whether a completed item still inside the date window is struck-through (kept visible) or simply dropped once done.
- **Card grades** (`dashboard_grades`, default true): reads `GET /courses?include[]=computed_current_score&include[]=current_grading_period_scores`. **`card_grade_target` (canvas/bettercampus) does NOT change the grade value shown — both display the same Canvas-computed score.** It only changes what clicking the pill does: `"canvas"` opens Canvas's native `/courses/{id}/grades` page; `"bettercampus"` intercepts the click and opens BetterCampus's own in-panel grades view instead (middle/ctrl/cmd/shift-click always falls through to the native Canvas link either way).
- **Condensed cards** (`condensed_cards`, default false): appears in the schema and in the settings-reload dispatcher (grouped with the other card-visual keys), but **no literal render-time consumer of this specific key was found** in `all.pretty.js` — its concrete effect is presumably applied inside a per-LMS "cardCustomizations" module not reachable by a direct grep of the setting name. Flagged as inconclusive rather than guessed.
- **Cards — full per-course data shape**: `{default (immutable original name), defaultColor, name, originalName, code, img, hidden, custom_links[], url, color, visual_type, gradient_color, gradient_angle, image_filter_intensity, overlay_colors[], overlay_opacity, order, active}`. `visual_type` enum: `default` (unstyled) / `solid` (flat color) / `gradient` / `image` / `sync` (still following Canvas's own image, not yet user-customized). Default course color falls back to Canvas's own `GET /api/v1/users/self/colors` when nothing is stored.

### Hover grade

`grade_hover` (default false) adds a CSS class making the grade pill `opacity:0` at rest, fading to `opacity:1` only on `:hover` of that course's card (`transition: opacity 200ms`) — a screen-share-friendly privacy toggle, presented in the UI as a two-way "Hover" vs. "Always" choice rather than a checkbox.

### Universal search bar — a correction to the brief's speculation

`global_search` (default true), opened via a "Search" pill or **⌘K/Ctrl+K**. After 3+ typed characters (debounced 500ms) it POSTs a hand-built GraphQL query straight to **Canvas's own `/api/graphql` endpoint** — not BetterCampus's backend — requesting `pagesConnection`/`assignmentsConnection` with `searchTerm`, `last: 3` each, across `allCourses`. **It searches Pages and Assignment titles only (top 3 of each, per course) — not courses, files, people, or grades**, contrary to the task brief's guess.

### Widgets

Two overlapping systems are both live simultaneously: a **legacy boolean map** `dashboard_widgets` (planner/notes/study/grades/grades_gpa/grades_trend, all default false), and a **newer size-variant catalog** (`dashboard_widget_variants`/`_order`/`_layout`) driving a drag-reorderable grid with entries like `planner.planned.small/.large`, `notes.quick-access.small/.large`, `notes.lecture.small/.large` ("start recording a lecture straight from your dashboard" — a lecture-recording widget not otherwise documented), `study.overview` (behind remote flag `feature_flags.study`), `themes.current` (show off your applied theme), `grades.gpa-trend.medium` (behind `feature_flags.grades`). A third, older "native" set renders straight from its own settings: `gpa_calc`/`gpa_calc_size` → a **"GPA Overview"** card (current-semester + cumulative GPA), `dashboard_notes`/`_size` → a sticky-notes widget, `doge_widget`/`_size` → the meme-clicker widget from section (a)'s extra findings.

**Quote / Music / Breathe widgets — all three Pro-gated** (`quoteWidget`/`musicWidget`/`breatheWidget` in the paywall registry, `trigger:"feature_gate"`):
- **Quote** — a rotating/auto-scrolling motivational-quote carousel (`quote_widget_preferences`: category filter, loop mode, auto-scroll duration).
- **Music** — paste a **Spotify, YouTube, YouTube Music, or Apple Music** URL; it's converted client-side to an embeddable player and plays inline on the dashboard.
- **Breathe** — a full-screen animated breathing-exercise overlay (inhale/exhale/rest phases, animated gradient background) with a configurable "Cycle Count" (complete breathing cycles per session) and a live current/total-cycle counter.

### Streak on the dashboard

A streak indicator renders as the very first element inside the to-do widget (above the "To-Do List" header), gated by `todo_streaks` (default true). It shows a streak icon/skin (`streak_icon`, default `365` — likely a variant id, not literally 365 days), the current count, and streak-restore affordances for paid streak recovery when a streak breaks — consistent with `streak_restores` being one of the metered plan entitlements (section a). Broader gamification mechanics are covered in section (k).

---

## (d) Grades

### Two rendering systems — why some findings hit a wall

Grades content renders two ways: **native shadow-DOM widgets** coded directly in `all.pretty.js` (e.g. the small "GPA Overview" dashboard card), and **cloud/iframe widgets** — a widget catalog entry with `surface:"iframe"` loads `{PAGES_URL}/widgets?...&bridgeId=...` from the separately-hosted `ext.bettercampus.com` web app. **Grade Trends is registered this way**, same as Planner/Notes/Study/Theme widgets — its actual chart-drawing code is not present in this extension bundle; that's a genuine reach limit of static analysis, not a guess. There's also a full native page, `bc-grades`/`?bettercampuspage=grades`, almost certainly what the three demo videos (`Goals.webm`, `Trends.webm`, `WhatIf.webm`) tour as onboarding tabs.

### GPA calculator

`gpa_calc_cumulative` and `gpa_calc_weighted` are **dead/unused settings** — grepping the whole file for these exact strings finds only their schema-default declarations, no read call, no UI control. What actually happens instead: the widget always shows **both** current-semester and cumulative GPA side by side, unconditionally — no toggle needed. Formula: `cumulativeGPA = (Σ pastSemester.gpa×creditHours + currentSemesterGPA×currentCreditHours) / (Σ pastSemester.creditHours + currentCreditHours)`, with a default of 3 credit hours per class if none is set. "Weighted" GPA is real, just controlled elsewhere: a school-level `isWeightedGPA` flag (set in the Grades page's own school-settings UI, not the dashboard-widget settings), applied per-class only when that class is flagged `isHonorsAP` — true weighted-scale letter grades (A=5.0, A-=4.7...) vs. the unweighted table (A=4.0) swap in per class, not globally. **Does read real Canvas grades** via the same API calls used by What-If below. A "Past GPA" flow lets a student manually enter old semester GPA+credit-hours, or **upload a transcript file** (PDF/PNG/JPG/JPEG/WebP) that's parsed and imported — this is the third AI provider from section (e) (Cloudflare Workers AI), and explicitly "requires a BetterCampus account."

### What-If grades — entirely BetterCampus's own overlay, not Canvas's native feature

**Confirmed: it does not touch Canvas's native what-if-grades feature or write anything back to Canvas at all** — only `GET` requests were found anywhere in the What-If code paths. All hypothetical state lives in local browser storage under extension-local keys (`bettercanvas_hypothetical_grades`, `..._course_grades`, `..._hidden_assignments`, plus a separate `bettercanvas_real_grade_overrides` map) — never sent to any Canvas endpoint. A local view-mode flag (`"live"` vs `"what-if"`) toggles the display; the recompute engine reruns BetterCampus's own weighted-average formula (the same one behind the GPA calculator) against the hypothetical numbers, entirely in the browser. The underlying real course/assignment data comes from `GET /api/v1/courses?...&include[]=term` and `GET /api/v1/courses/{id}/assignment_groups?include[]=assignments&include[]=submission&include[]=score_statistics`, using the student's own Canvas session. A one-time "What-If welcome" onboarding modal is tracked by `hasSeenWhatIfWelcome` (matches the `WhatIf.webm` first-time folder exactly — and independently confirmed via the `extension-bridge.js` RPC `getGradeViewState`, default `{hasSeenWhatIfWelcome:false}`, found separately during this analysis). Bonus: the same data layer exposes a client-side CSV/JSON grade export (no network call).

### Grade trends

Catalog entry: `id:"grades.gpa-trend.medium"`, description "Historical GPA trend chart," `surface:"iframe"`, gated behind remote flag `feature_flags.grades`. Data blends the live current-semester numbers with the same "Past GPA" history described above. **A confirmed consent checkbox** appears before saving past-semester history: *"I agree that BetterCampus can save my grade history to show my trends, use anonymous, combined data to improve the product, and that I can delete it anytime"* — plus *"Transcript-derived grade history is stored encrypted for your security."* This directly matches (and is independently confirmed by) the separately-discovered `bettercanvas_grade_snapshots` local storage schema in `extension-bridge.js` (per-user, per-course daily `{capturedOn, score 0-150, source:"snapshot"|"backfill"}` entries — see the extra findings above). **Time granularity for the *Trends widget itself* is per-semester** (`{name, gpa, creditHours}`, ordered Fall/Winter/Spring/Summer), not daily — the daily-snapshot storage found separately may feed a different/finer-grained view not reachable in this bundle.

### Goals

**The data model is real and wired in; the actual goal-setting input UI could not be located in this bundle after an exhaustive search — reported plainly rather than guessed.** Confirmed: a per-class `goalGrade` field (e.g. "I want a B+ in this class") and a per-semester `semesterGoalGPA` field exist in the grade-settings data model, plus two modal-open flags (`isEditTargetGradeModalOpen`, `isSetSemesterGoalModalOpen`). Goals are treated as precious: disabling GPA calculation for a class pops a confirmation titled **"Reset All Goals?"** warning that it will wipe every class goal and the semester goal, and confirming does in fact clear them. But despite grepping every case variant of "goal" and the literal property names (property-key strings survive minification, so this search is reliable), **no call site was found anywhere that ever sets these fields to a real value or opens either modal with `true`** — every occurrence is a read-for-existence check or a clear. Best-supported explanation: like Trends, the actual goal-input UI likely lives in the externally-hosted iframe app, out of reach of this static bundle — stated as inference, not fact.

### Assignment-group weighting

**Reads Canvas's real weights; there is no user-override mechanism for the weights themselves.** Canvas's `group_weight` per assignment group is copied straight into BetterCampus's internal scoring; whether to apply group weighting at all is auto-derived (true if any group has `group_weight > 0`), not a user toggle. The dashboard-card grade path reads Canvas's own `apply_assignment_group_weights` boolean directly, alongside Canvas's own pre-computed `computed_current_score` for cross-reference. Grepped `weightOverride`/`customWeight`/`editWeight`/`overrideWeight` — zero hits. **BetterCampus displays and computes with Canvas's real weights; it does not let a student type in their own hypothetical "Homework 30% / Exams 70%" split.**

### "Hidden" grades

**No evidence BetterCampus detects, reveals, or flags Canvas's instructor-side hidden/muted-grades feature** — explicit negative result after multiple searches (`muted` only ever matches Tailwind's `text-muted-foreground` utility class; `unposted`, `hide_points`, `hidden_at`, `restrict_quantitative_data` all return zero hits). The 8 occurrences of `isHidden:` in the file are all the **What-If simulator's own** "student manually excludes this assignment from my hypothetical calc" toggle — a student-controlled feature, unrelated to instructor-side muting. A separate, adjacent-but-different finding: a scaffolded `privacy:{hideGPA:false, hideGrades:false}` object exists in the grade-settings defaults, but has **zero consumption sites** — like Goals, this looks like wired-but-unshipped state, not a live feature.

### Pro-gating on grades

**None found.** The paywall registry has no `grades`/`gpa`/`whatIf`/`trend`/`goal` key, and no `Ife(...)` paywall-trigger call site anywhere passes a grades-related argument. The only gating that exists is a remote **feature flag** (`feature_flags.grades`, default true) acting as a rollout kill-switch, not a plan-tier restriction — and the transcript-upload "Past GPA" import specifically requires a free account (not necessarily a paid one). **Conclusion: GPA calc, What-If, Trends, and Goals all appear to be free-tier features**, gated only by a feature flag and (for transcript import) an account requirement, unlike the Pro-paywall mechanism used for notes/themes/AI-transcription/Files-AI limits.

---

## (e) The Navigator + external hostnames

### What "Navigator" actually is

No code literally says "Navigator" (the word only shows up as the standard `window.navigator` browser API). What the task's screenshots document is what the code itself calls the **embedded app**, referenced via the marker element `<bettercampus-navigator>` (no `customElements.define` anywhere — same unregistered-shadow-host pattern as the sidebar in section g).

**Primary trigger — a URL query parameter**: `?bettercampuspage=<page>`, where `<page>` is one of `study | planner (alias "tasks") | notes | grades | insights` — declared as array `cqe = ["planner","study","notes","grades","insights"]` (`all.pretty.js:105550`). Parsed by `k_()` (`:50918-50936`), written back by `j_()` (`:50939+`). Sidebar quick-nav buttons link directly to these, e.g. `href:"/?bettercampuspage=study"` (`:129201-129245`) — this matches, and is confirmed by, the `syncPageUrl`/`bettercampuspage` mechanism independently found in `extension-bridge.pretty.js` (see the entry-point note above): the same URL contract drives both the top-level page and the embedded iframe.

**It's an iframe, not an in-page React tree.** `Efe()`/`Nfe()` (`:73529-73560`) force-open/close the "embedded app" by posting `{type:"bettercampus-embedded-app-toggle", forceOpen/forceClose, page}`. A receiving handler (`:167670-167715`) checks `e.source === K.current?.contentWindow` (a React ref to an `<iframe>`) and `e.origin === new URL(VITE_PAGES_URL ?? "https://ext.bettercampus.com").origin`, with handshake messages `EMBED_APP_MOUNTED`/`BRIDGE_PAGE_READY`. **So the Navigator's page-level UI is rendered by a separate web app hosted at `ext.bettercampus.com` and loaded in an iframe** — the content script only owns routing, entry points, settings, and paywall gating around that iframe.

There's also a third, internal **deep-link scheme** (`:73505-73527`) — `app:create`, `app:grades[:ID][?view=what-if|settings=past-gpa]`, `app:notes:ID[...]`, `app:study:ID[?material=…]`, `app:planner?focus=1`, `app:locker:all`, `app:explore:...` — these look built for programmatic/AI-generated links (e.g., a clickable reference inside an AI chat answer) that jump straight to a specific note/study-set/grades view. No keyboard shortcut exists (checked all `keydown` registrations — only generic Radix UI focus-trap internals). A full-screen loading overlay uses the shipped `navigator/guy_loader.png` mascot image (`:139804`) — but the other `navigator_*.png`/`themes_*.png` files have **no literal path match anywhere in the bundle**; they're most likely reference screenshots for this task, not shipped assets. The four "png" filenames that DO exist as real assets (`announcements.png`, `assignments.png`, `discussion_topics.png`, `files.png`) are a generic content-type icon lookup (`:19087-19090`), not distinct Navigator sections.

### The five sections

| Page | Sidebar entry | Backend calls | Notes |
|---|---|---|---|
| Study | "Study" / `bc-study` | `/study/sessions/start,{id}/finish,{id}/progress`, `/study/notebooks/{id}/documents` | AI document chat, flashcards, quizzes — see AI features below |
| Planner (alias Tasks) | "Planner" / `bc-assignments` | `/schedules/import,/sync`, `/syllabi/import`, `/overrides/sync-calendar,/reset,/update` | Schedule/syllabus import parses an uploaded file/URL/text into structured course data |
| Notes | "Notes" / `bc-notes` | `/notes/create-note,/update-note,/upload-file,/folders/*,/images/sign-bulk,/metadata,/recently-deleted,/recount,/check-storage-usage,/count,/course-data,/load-note` | `notes_sort_mode` default `"recent"`; Files AI layers on top |
| Grades | "Grades" / `bc-grades` | `/users/grade-history` PUT/DELETE, `/grades/past-gpa/import` | Supports "what-if" GPA calc + "past-gpa" import (see section d) |
| Insights | **not in the sidebar button list** | none found | See below |

**Insights is thin.** The string "insight" appears only **6 times in 189,574 lines**: the page-list array, an id mapping (`insights → "bc-insights"`, `:129258`), a DOM-id fallback check, and the settings key `insights: {syncType:"server", default:{}}` (`:10544`, exactly matching the task's own hint). No dedicated component, copy string, or API route was found. Given the iframe architecture above, Insights' real UI most likely lives inside the `ext.bettercampus.com` iframe app — outside the six content-script files available for this analysis. Stated as inferred, not confirmed.

### Three distinct AI features (easy to conflate by name)

All three are separately paywall-gated via the registry in section (a), and each has a one-time "have you used this" flag: `has_used_files_ai`/`has_used_transcribe` (defaults `false`, `all.pretty.js:10441-10442`).

1. **Files AI** — AI document-chat panel layered over Study/Notes (settings `filesai_open`=true, `filesai_width`=380, `filesai_mode`="sidebar"/"floating", `filesai_sidebar`=true). Self-disclosed in an in-app AI-transparency panel (`:165201-165320`): **Base Model = GPT-4o-mini**, not trained on user data, data shared with the model = "questions, uploaded documents, and conversation history," 30-day file cache, logged for service improvement, PII not exposed. Paywall: `filesaiTrialLimit`/`filesaiFairUseLimit`.
2. **Transcribe** — lecture audio-to-text, a separate pipeline. Backend error strings name the provider directly: *"Groq API key not configured"* (`:178926-178927`) — **powered by Groq**, not GPT-4o-mini. Audio stored on Cloudflare R2 (implied by a `"Missing R2 credentials"` error). Monthly quota (*"Monthly transcription limit exceeded"*). Marketing copy: "Record class, get a live transcript." Paywall: `transcriptTrialLimit`/`transcriptFairUseLimit`.
3. **GPA "transcript" import** (section d) — uploading a PDF/PNG/JPG/WebP report card to backfill grade history. A `503` error names the provider directly too: *"Cloudflare AI is not configured for local transcript import. Set CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN..."* (`:178071-178073`) — **runs on Cloudflare Workers AI**, a third distinct provider. Requires an account; result stored "encrypted."

**Related but separately metered**: Study Sets (flashcards) — entitlement `study_sets`, with usage-warning emails at 80% and 100% of the monthly cap (`all.pretty.js:14288-14318`).

### External hostname inventory

37 unique `https://` hosts in `all.pretty.js`, 16 in `background.pretty.js` (a subset). **No `ws://`/`wss://` URL exists anywhere in either file.**

| Hostname | Purpose |
|---|---|
| `api.bettercampus.com` | Backend API base (`VITE_CLOUDFLARE_URL`) — the entire 354-route REST surface |
| `ext.bettercampus.com` | The embedded-app/auth-pages host, loaded in an iframe — where Navigator page UI actually renders |
| `bettercampus.com` | Marketing/frontend site |
| `assets.bettercampus.com` | Static asset/video CDN (onboarding intro video, an easter-egg "spinning cat" clip) |
| `tgsubtjsssttyptpovop.supabase.co` | Supabase project — backs the `auth` setting |
| `us.i.posthog.com` | PostHog analytics ingestion (US Cloud) — `POST /i/v0/e` with `api_key`/`distinct_id`/`$set` for `school_url`/`plan_type` |
| `canvas.instructure.com`, `www.instructure.com` | Default Canvas host / Instructure provider-metadata link |
| `www.d2l.com`, `moodle.com`, `www.anthology.com`, `classroom.google.com` | Provider-metadata links for Brightspace/Moodle/Blackboard(Anthology)/Classroom — plus live host-detection for the Classroom adapter |
| `www.gradescope.com` | Gradescope adapter — **fetched directly client-side** (`fetch("https://www.gradescope.com/courses/"+id)` then `DOMParser`-scrapes the assignments table; no official API used) |
| `www.cengage.com`, `ssl.gstatic.com` | Favicon fallbacks for WebAssign / Google Docs links in a generic "get favicon for this link" helper |
| `fonts.googleapis.com` | Google Fonts CSS loader for custom theme/note fonts |
| `open.spotify.com`, `www.youtube.com` | Embed-URL rewriting for a dashboard music widget (normalizes pasted links into `.../embed/...` iframes) |
| `chromedino.com` | Embeds the Chrome Dino runner game in an iframe — a mini-game/break widget |
| `chromewebstore.google.com`, `microsoftedge.microsoft.com` | Links to the extension's own store listings (review-prompt UI) |
| `encrypted-tbn1.gstatic.com`, `i.pinimg.com`, `parade.com` | Sample image URLs baked into an old debug/migration **test fixture** for saved themes (`all.pretty.js:~8807-8980`) — not live traffic |

Everything else found (`developer.mozilla.org`, `github.com`, `json-schema.org`, `radix-ui.com`, `react.dev`, `wxt.dev`) is a documentation link embedded in a bundled third-party library's own error/warning text, never fetched; and a handful (`https://example.com`, `https://placeholder.local`, `https://blocked.invalid`) are placeholder/sentinel strings, not real destinations.

---

## (f) Themes

### The theme model

Themes apply entirely through a `--bc*` CSS custom-property namespace set at runtime; the shipped stylesheet just reads `var(--bcXXX, <light-fallback>)` everywhere so pages render correctly even before the variables are set. 21 distinct `--bc*` variables were found across `all.pretty.css`/`all.pretty.js`, including `--bcbackground-0/1/2`, `--bcborders`, `--bcbuttons`, `--bccards`, `--bcfont`, `--bclinks`, `--bcshadow`, `--bcsidebar(-text)`, `--bcsidebarwidth`, `--bctext-0/1/2`, `--bcwidget-*`, `--bcmodalz`/`--bcpagez` (z-index tokens), `--bc-course-ring`, and `--bc-cursor-default`/`-pointer`. A marker string `"bettercanvas-theme-preset"` is used as the DOM/style id when (re)injecting the active preset's CSS. The seed hex palette for the two built-in modes is the `rg`(light)/`ag`(dark) object literals already shown in section (a)'s raw settings block.

### Built-in presets: only two — the messages.json names are dead

**Only `"lighter"` and `"darker"` exist as built-in presets** (`default_preset` default `"darker"`), each a single flat hex palette. The `_locales/en/messages.json` preset names (Catppuccin, Coral, Mint, Sage, Unicorn, Pink, Burn, Blue, with author credits like "By Angel"/"By Superchido") are **confirmed fully dead** — zero matches for any of those literal ids, zero matches for the author-credit strings, and no compiled-in `{code,name,author}`-shaped array exists anywhere. What replaced them: a **full server-hosted theme marketplace** — REST routes `/themes` (list), `/themes/:code`, `/themes/:code/like`, `/themes/check-limits`, `/themes/user-themes`, `/themes/auto-rotate`, `/themes/history`, `/themes/submit`, `/themes/unpublish`, `/themes/comments(/add)`, `/themes/edit`, `/themes/apply`. Named community themes with real author attribution are fetched at runtime from this API, not compiled into the extension — which is exactly why the old preset names don't show up in a static grep any more. (A separate object holding sample Pinterest-image URLs and font names like `Jost`/`Rubik`, at `all.pretty.js:~8804-9223`, is a **debug/QA storage-migration fixture** literally named `"Empty (Debug)"`/`"v5.12.6"` — not shipped default content, easy to mistake for a preset catalog.)

### Scheduled dark mode

`auto_dark` (default false) is the master switch. `auto_dark_behavior` (default `"match_device"`) is either `"match_device"` (follow OS `prefers-color-scheme`) or `"scheduled"` (fixed daily window). If a user switches to "scheduled" without changing the times, it defaults to **8:00 PM – 8:00 AM**. Theme auto-rotation is a separate feature: `auto_rotate_theme` (off by default) rotates between a "mine" (created/remixed/liked) or "community" (trending/new) pool on a `6h / 12h / 24h / weekly` cadence (`auto_rotate_interval` enum, `auto_rotate_source` picks the pool).

### Custom fonts — real Google Fonts integration

UI copy states this directly: *"Uses Google Fonts. Add by exact font family name."* The `custom_font` setting stores `{family, link}` where `link` is a Google Fonts CSS2 query fragment; a loader appends `<link href="https://fonts.googleapis.com/css2?family=${family}:wght@400;500;600;700&display=swap">`. Two picker tabs: a **Library** tab with 36 curated Google Font names (Arimo, Barriecito, Barlow, Caveat, Cinzel, Comfortaa, Corben, DM Sans, Gluten, Inconsolata, Jost, Kanit, Karla, Lobster, Lora, Montserrat, Open Sans, Oswald, Permanent Marker, Playfair Display, Poppins, Quicksand, Roboto Mono, Rubik, Silkscreen, and others), and a **Custom** tab for free-text "any Google Font" entry. (Distinct from the extension's own UI font, Figtree, self-hosted at `fonts/figtree-latin.woff2`.)

### Cursors

Two independently configurable slots — `default` and `pointer` — each either browser-default, a solid color dot, or a custom uploaded cursor image, applied via `--bc-cursor-default`/`--bc-cursor-pointer` CSS vars forced onto `html,body`/links/buttons with `!important`. A `[data-bc-safe-cursor]` escape hatch forces specific elements back to normal cursors (presumably text fields).

### Stickers

Per-theme sticker placement (`theme_sticker_palette`, keyed to theme code), with a "Sticker Library" popover ("Click a sticker to drop it on your page, then drag to position") supporting PNG/JPG/GIF/WEBP uploads or pasted image URLs. **Free-plan cap: 3 saved stickers per theme** (`u.length >= 3` check), beyond which the uploader calls the `sticker_slots` paywall (`TG_STICKER_SLOTS_LIMIT_REACHED`).

### Readability/contrast checker — warns only while editing; enforced on publish

`theme_contrast_threshold` (default `"off"`, enum `off/low/medium/high`) controls **live warnings only** — UI copy states explicitly: *"Publishing always enforces a minimum contrast level, regardless of this setting."* An "Auto-fix contrast issue" action can fail outright (*"No color can hit the desired contrast here."*) if the two colors are fundamentally incompatible. The math is standard WCAG: relative luminance with sRGB gamma correction (weights 0.2126/0.7152/0.0722), contrast ratio `(L1+0.05)/(L2+0.05)`, with a `level()` helper mapping ratio ≥7→"AAA", ≥4.5→"AA" — the canonical WCAG 2.x text thresholds. A separate hardcoded **4.5:1 floor** is used when auto-adjusting an overlay color against a background.

### Free theme swap count — confirmed

`noaccount_swaps` (default **5**) applies **only to logged-out users** — once logged in, the local counter is effectively unlimited (`999999999`) and a separate server-enforced `themeSwapLimit` paywall takes over instead. It decrements by 1 only when a logged-out user applies a **community-origin** theme (re-applying one of your own themes doesn't cost a swap). A related but distinct gate exists on the "Theme History" panel: only your 2 most-recent applied themes stay unlocked; older history entries are paywalled separately (`themeSaveLimit`/theme-history gating), each tracked with its own analytics event (`upgrade_swap_limit_viewed` vs. `upgrade_save_limit_viewed`) even though both stem from the same underlying theme-entitlement concept.

---

## (g) Sidebar

### Not a registered Web Component

The task brief's assumption of a `customElements.define`d `<bettercanvas-sidebar>` is **not what's shipped** — there is no `customElements.define` call anywhere in any of the extension's scripts (checked all six). Instead, a generic shadow-DOM-host helper does `document.createElement("bettercanvas-sidebar")` then `.attachShadow({mode})` directly, with no registration step — legal because any hyphenated tag name can host a shadow root without being a real Custom Element (it just gets no lifecycle callbacks). React then renders the actual UI into that shadow root. Two distinct references share the name and shouldn't be confused: the outer shadow-host tag (styled from outside via `::part()`) and a plain `<div id="bettercanvas-sidebar">` rendered inside the shadow root — the latter is the real visible flex container.

### Contents, top to bottom

1. **Header/icon row** — always rendered; shows Canvas's own institution logo (via Canvas's `--ic-brand-header-image` var) and the logged-in user's Canvas avatar/name, respecting `remlogo`/`hide_bettercanvas_logo`.
2. **Pages section** — gated by `sidebar_expanded_sections.pages` (expanded) / `sidebar_collapsed_sections_visibility.pages` (collapsed) — the 4 toggleable shortcuts (`bc-assignments`,`bc-study`,`bc-notes`,`bc-grades`), all off by default.
3. **Courses section** — same gating pattern on `.courses`.
4. **Bottom CTA button.**

(Do not confuse `sidebar_pages` — what shows in the real Canvas sidebar — with `sidebar_settings_pages`, which is the unrelated left-nav tab list of BetterCampus's own settings popup: general/appearance/courseDetails/dashboard/todo/sidebar/other/advanced.)

### Width / density / icon settings

| Key | Default | Options | Effect |
|---|---|---|---|
| `sidebar_small` | false | boolean | compact-width variant |
| `sidebar_label_density` | "compact" | compact / cozy | row gap 0px vs 6px |
| `sidebar_size_scale` | "medium" | tiny/small/medium/large/xlarge | icon-scale multiplier 0.7–1.3× |
| `sidebar_collapsed_show_labels` | true | boolean | keep text labels when collapsed to an icon rail |

The live pixel width is written as CSS var `--bcsidebarwidth`, which also resizes Canvas's own `#header` and shifts `#wrapper`'s margin in sync, and is explicitly zeroed for print media. The collapse toggle is a 2px hover strip on the sidebar's right edge with an "Expand/Collapse Sidebar" tooltip.

### Hide school logo vs. hide BetterCampus logo — two different toggles

- **`remlogo`** ("Hide School Logo", default false) hides Canvas's own institution logo — a plain instant toggle. Disabled on Google Classroom specifically ("Google Classroom doesn't have a school logo").
- **`hide_bettercanvas_logo`** ("Hide BetterCampus Logo", default false) hides the extension's own branding — turning this **ON** is not instant: it sets `pending_hide_logo_confirmation:true` and shows a full-screen `puzzleIconGuide` modal overlay explaining how to find/reopen the extension via Chrome's toolbar puzzle-piece icon once its in-page logo disappears; clicking the toolbar icon while this is pending IS the confirmation step (see the entry-point note in section a). Turning it OFF skips confirmation and clears both flags immediately. Across every supported LMS adapter (Canvas, Blackboard, Brightspace, Moodle), this setting consistently tears down that platform's in-page nav-button mount point when true.

---

## (h) Calendar integrations

**Neither `googlecalendar.pretty.js` nor `outlookcalendar.pretty.js` calls the Google Calendar API or Microsoft Graph API.** Grep for `googleapis.com`, `calendar/v3`, `events.insert`, `events.list`, `graph.microsoft.com`, `/me/events` across both files, plus `all.pretty.js`/`background.pretty.js`/`extension-bridge.pretty.js`, returns **zero hits everywhere in the extension**. Whatever OAuth + API work actually syncs calendars happens server-side (their own backend at `api.bettercampus.com`) or in their web app at `ext.bettercampus.com` — not in the client bundles available here.

Both files are ~90% a bundled Zod library plus a duplicated copy of the master settings schema; the entire page-specific logic is one small `main()` at the end of each file:

- **`googlecalendar.pretty.js:4429-4467`**: on first click anywhere on the Google Calendar page, sets a one-way flag `external_calendar_accessed:true` (not calendar data). If local flag `calendar_tasks_should_check` is true, it polls the DOM every second looking for Google Calendar's own native "Tasks" sidebar checkbox (`li div[data-text='Tasks' i]`) and auto-clicks it if unchecked — it only ensures Google's own Tasks layer is visible, it doesn't read/write events.
- **`outlookcalendar.pretty.js:4429-4452`**: only the `external_calendar_accessed` click flag — no DOM automation at all.
- **No UI is injected into either calendar page.** No injected styles, no rendered elements beyond the one checkbox click. Neither file sets `cssInjectionMode`, unlike viewer.js/stripe.js which both declare `cssInjectionMode:"ui"`.
- **No poll loop, alarm, or background sync** exists for calendar data in either file, and `background.pretty.js` has zero `.alarms.` calls anywhere in the whole extension.
- **Read direction confirmed elsewhere**: `all.pretty.js:168914-168944` and `:168990-169019` show a React hook that reads cached `google_cal_events`/`microsoft_cal_events` (+ `..._last_sync` timestamps) out of storage and merges them into BetterCampus's own to-do/planner UI — i.e. pulling the user's calendar **into** Canvas's side panel. No write-direction call (pushing Canvas assignments out as new calendar events) was found anywhere in the available code. `google_cal_push_settings`/`microsoft_cal_push_settings` exist only as schema declarations with no code path found in any bundle — stated as unconfirmed, not guessed.
- **Sync trigger**: a manual "Sync" button in the main panel (`all.pretty.js:104803-104849`) requires login, runs a paywall check (`Tfe("calendarSync")`), and opens a "calendar" settings panel — sync setup is user-initiated, not an automatic background poll, though the actual sync execution isn't visible in these bundles.

---

## (i) viewer.js (canvadocs.instructure.com)

Entry point `viewer.pretty.js:34878-34970` (`matches:["https://canvadocs.instructure.com/*"]`, `cssInjectionMode:"ui"`, `document_idle`, `allFrames:true`). `main()` only fully activates when `document.referrer` contains `"files"` (`:34884`).

**Dark mode: yes**, a full theme re-skin, not a simple toggle — it reuses BetterCampus's whole `--bcbackground-0`/`--bctext-0`/`--bcborders` CSS-variable system (`viewer.pretty.css:684-688,7599-7639,9417-9439`).
- Resolver `Pl()` (`:34836-34849`): `device_dark` → OS `prefers-color-scheme`; else `auto_dark` → minutes-since-midnight window check against `auto_dark_start`/`auto_dark_end` (default 20:00-08:00); else the plain `dark_mode` boolean.
- CSS generator `ic()` (`:9339+`) builds a `:root{--bc...}` string from `dark_preset`/`light_preset`; applied in `main()` (`:34913-34920`) via a `<style id="bettercanvas-dark-css">` tag.
- A `chrome.storage.onChanged` listener forces a full iframe reload whenever the `annotations` setting changes (`:34895-34900`).

**Annotations: yes — a full toolset**, gated behind `annotations` (default true), initialized once the Canvadocs page DOM exists (`Gp().annotations && Rh()`, `:34935`). Toolbar `Rh()` (`:33453+`) has six tools: **Select** (cursor), **Drawing** (freehand highlight + eraser, color/size sliders), **Shape** (rectangle/circle/arrow/line), **Comment** (pinned text note), **Textbox**, **Text Highlight** (select real PDF text, highlight it). Annotation records carry id/type/x/y/content/color/size/timestamp/pageIndex/pathData; cached client-side under IndexedDB key `"local:filesai"` (`:34948`) — note this shares storage with the Files-AI feature, not a coincidence, likely the same "materials" subsystem. Cross-frame sync via `postMessage` (`fileInfoResponse`/`deleteAnnotation`/`updateAnnotations`/`annotationsUpdated`). **Paywall confirmed live**: `annotationsAccountRequired`→`rd_annotations_account_required` is in viewer.js's own schema copy (`:5325-5326`); every toolbar button except Select gets a small crown badge when the resolved plan is `"none"` (`Lh(toolId,plan)`, `:33406-33407`, reading `auth.user.app_metadata.plan_type` at `:33455`).

**Bonus feature found, not in the original checklist: an AI "Explain" button.** Selecting text with the Select tool pops a floating toolbar (`#text-explain-toolbar`, `:32989-33083`) with a highlighter button and an **Explain** button (`:33083-33143`) that builds the prompt `Please explain the following text (from page N): "<selection>"` and posts `{type:"navigateToTab", data:{tabId:"chat"}}` then `{type:"explainText", ...}` to the parent frame — handing the selection to BetterCampus's AI chat panel.

**Not found**: no custom zoom controls, no download-button modification, no print controls specific to this file (checked directly, all zero hits).

---

## (j) Quiz safety

**Bottom line: the extension never disables itself on a quiz page.** The content script has no manifest exclusion for quiz/exam URLs (`content-scripts/all.js` matches `<all_urls>` at `document_start`, no `exclude_matches` for Canvas quiz paths). Two narrow, independent mechanisms exist instead:

**1. `quiz_safe_mode` — theme/dark-mode suppression only, opt-in, default OFF.** Settings UI label: "Quiz Safe Mode," description verbatim **"Disables themes on quizzes"** — it doesn't claim to do anything beyond that. A gate function (duplicated in two bundle chunks) returns "suppress" only if `quiz_safe_mode === true` **and** the pathname matches `/\/courses\/\d+\/(quizzes|assignments)\/\d+/` (deliberately matches assignments too, since New Quizzes/Quizzes.Next often routes through `/assignments/…`) **or** a Quizzes-2 LTI form/iframe is present in the DOM. When triggered, it: clears the injected `#bettercanvas-theme-preset` style tag (theme CSS gone, native Canvas colors return), and removes the dark-mode style injected into the Rich Content Editor's TinyMCE iframe (for quiz questions with rich-text answer boxes). **Confirms the section (a) hint precisely**: the settings-change dispatcher groups `quiz_safe_mode` under the exact same `case` block as `dark_mode`/`dark_preset`/`light_preset`/`device_dark`/`auto_dark_start`/`auto_dark_end`, all routing to one `"darkModeToggle"` reload action — it is implemented as part of the dark-mode system, not a standalone "pause the extension" switch. Nothing else (todo widget, sidebar, grade tools, dashboard cards, search bar) is touched by this setting. By default (`quiz_safe_mode=false`), BetterCampus's custom theme keeps recoloring the quiz-taking page — the injected theme CSS string directly targets quiz selectors (`#quiz_show`, `.quiz-submission`, `.quiz_comment`, `.quiz-header`).

**2. An unconditional, non-toggleable guard on promotional overlays.** A separate hardcoded check (not gated by any setting) blocks BetterCampus's own marketing/upsell "campaign" overlay system whenever the URL contains `/quizzes/` or `/exams/`, or quiz-taking DOM markers (`#quiz_show`, `#quiz-taking`, `#quiz_form`, a Quizzes-2 LTI form/iframe) are present, or the tab isn't visible/focused. So independent of the `quiz_safe_mode` toggle, **promotional popups are always suppressed during a quiz** — but this only concerns marketing overlays, not the extension's functional widgets, which keep running.

**Net assessment**: no code path fully disables the extension, hides the todo sidebar, hides grade tools, or hides dashboard widgets during a quiz — the only quiz-specific behaviors found are (opt-in) theme suppression and (always-on) marketing-popup suppression.

---

## (k) Streaks / gamification

### The streak mechanic

Default object (matches the schema's `streak` device key exactly): `{started_at, high, last_verified, last_expired, restored_at, push_dirty, last_sync}`. A recompute function derives the streak from the user's **completed-on-time assignment/todo history**: if no `started_at` exists yet, it backfills by scanning up to **1 year** back for the earliest qualifying completion day; a **2-day grace window** off `last_verified` means a short gap in opening the app doesn't immediately reset the count.

**Server-validated, not purely client-trusted**: after recomputing, the client `POST`s `{streak_started_at, streak_high, streak_last_sync}` to `/streak`. If the server responds `won:false`, the client logs a warning and leaves the update "dirty" to retry later rather than accepting the client-side number — a lightweight anti-spoofing check. A 1-hour debounce window protects a locally-dirty streak from being clobbered by an incoming background sync.

**Streak restores are a monetized, plan-gated entitlement.** The whole restore UI is invisible unless two server-controlled feature flags (`feature_flags.streak`, `feature_flags.streak_restores`, both default off) are both enabled. Eligibility requires: the broken streak being within a threshold of your personal best (14 days in production, 1 in dev), the streak having actually broken, not having already restored since, and being within a **48-hour** window of the break. Consuming a restore (`POST /streak/restores/consume`) that returns a 429 "no allowance" **and** the user is on the free plan routes straight into the upgrade/paywall flow — confirming restores are Pro-gated; free/logged-out users see a simplified "1 available" UI, but the real quota is enforced server-side at consume time. A hidden internal "Streak Debug" panel (override date, force-break, reset) confirms this logic is deliberately test-covered.

A **streak-length percentile stat** exists: a lookup table pairs day-count milestones with a rarity percentage (91% for day 1, decaying toward ~0–1% past ~day 300), rendered as an "On-time Streak" percentile once a streak reaches an "extended" display state — a social-proof/rarity nudge similar to Duolingo's streak-society framing.

### Confetti / celebration system

Setting `celebration_style` has 6 options: `confetti` (default), `fireworks`, `stars`, `hearts`, `sparkle`, `none`; `todo_confetti_amount` scales intensity: `none/normal/extra/insane` (default `normal`). Completing a todo item adds its id to an "already celebrated" ledger (`todo_celebrated`) so each task only celebrates once, ever. The confetti style is a `react-confetti`-shaped component with a custom blue/purple brand palette; fireworks uses a real, byte-for-byte match of the open-source **fireworks-js** library's config shape. Settings UI: Settings → To-Do → "Celebrations," a style dropdown plus an amount dropdown, both disabled unless `better_todo` is on.

**Sound effects exist in the vendored library but are never activated.** The fireworks-js library ships a real, working Web Audio API sound manager with 3 explosion mp3 filenames and a `sound.enabled` flag — but grepping every `sound: {`/`sound.enabled =` in the entire codebase found **no place BetterCampus's own code ever sets it to `true`**. `Audio(` the constructor: zero matches anywhere. **Conclusion: dead code — no sound effect can currently play**, despite the library fully supporting it.

### "Wrapped" (yearly recap) and dead settings

`wrapped_viewed` (default false) and `feature_flags.wrapped` (default **off**, a server rollout flag) both exist, and a real backend route (`GET /activity/wrapped?year=`) is live — but **no frontend component renders it** in this bundle (grepped "Wrapped" and "recap" case-sensitively; zero hits beyond the settings keys and the API route itself). Best-supported read: the feature is flag-gated and currently off, or its renderer uses different naming than searched — stated as inconclusive, not confirmed absent. `semester_recap` is **confirmed dead**: it appears exactly once, inside a hand-maintained list of legacy storage keys kept only so an old synced value still routes correctly for existing users — consistent with having been superseded by "Wrapped," though Wrapped's own shipped status is itself unconfirmed. `streak_disabled` (default false) also has **zero read sites anywhere** — schema-defined, never wired to any logic.

---

## (l) Performance

### The three requested counts, independently re-verified

| Metric | Count | Verified |
|---|---|---|
| `!important` in `content-scripts/all.css` | **74** | confirmed exact |
| Distinct `.css-*` (Emotion/InstUI hash) selectors in the static `all.css` | **0** | confirmed exact |
| `new MutationObserver` instantiations in `all.js` | **41** | confirmed exact |

`content-scripts/all.css` opens with a Tailwind v4.1.18 banner comment — it's Tailwind-generated utility CSS for the extension's **own** UI chrome (widgets, settings panel), not a Canvas-overriding stylesheet, which is why it targets zero Emotion-hash classes: it isn't meant to reach into Canvas's own React internals. **The actual Canvas-theming CSS lives elsewhere** — a giant template string built and injected as a runtime `<style>` tag from inside the JS bundle. That runtime-generated stylesheet *does* hardcode a handful of Emotion/InstUI hash selectors as override targets (e.g. `.css-26xxi8-view--block`, `.css-9fqfm7-view--block`) — a fragile pattern, since Emotion hashes aren't guaranteed stable across Canvas's own future builds. So "0 hash selectors" is accurate for the shipped static CSS file specifically, but not for the full theming system.

### MutationObserver usage — inconsistent rigor

Debounce/throttle census: the literal string `"debounce"` appears 9 times total, in exactly two places — a touch/swipe gesture coalescer, and one grade-hover-pills observer with a real 250ms debounce plus a capped `[300,800,1500,3000,6000]`ms retry schedule (the one place the team clearly hardened against Canvas's own async rendering races). The literal `"throttle"` has zero relevant occurrences. Meanwhile, the broadest-scope observer found — a shadow-DOM/iframe theme injector watching `document.documentElement` with `{childList:true, subtree:true}` — is **not debounced**, runs a full `querySelectorAll("*")` over every newly-inserted node's entire subtree, and schedules two extra forced re-checks per match. On a page that inserts DOM nodes frequently (a large gradebook, a long discussion thread, an infinite-scroll module list), this is the most plausible source of visible jank in the extension. Most of the other 41 observers narrow their scope (`childList` only, no `subtree`, or a single `attributeFilter`) or are short-lived and self-disconnecting on first match, keeping steady-state cost low — and not all 41 are active simultaneously, since most attach only when their owning widget/feature is enabled. Overall: a moderate number for a 6-LMS-adapter extension, with real (if inconsistent) attention paid to avoiding unbounded re-render loops.

---

## (m) Telemetry / accounts / Stripe / referrals

### Where analytics events go

Every event funnels through one sender function (85 call sites), gated by three checks in order: (1) production build only — silently no-ops in dev/staging; (2) the PostHog project key must be configured; (3) **consent**: `browser_data_collection_granted !== false && anonymous_usage_data === true`. If all three pass, it resolves a stable id (real user id if logged in, else a persisted random UUID), applies deterministic per-user sampling (an FNV-1a-style hash keyed on event name + user id + sample rate, so the same user/event pair is consistently included or excluded across sessions), and **POSTs directly to `https://us.i.posthog.com/i/v0/e`** with a hardcoded PostHog project key — confirmed PostHog, not Amplitude/Mixpanel/Segment (the only "amplitude" hits anywhere in the codebase are an unrelated SVG-filter-attribute allowlist).

**Payload includes**: a distinct id, extension version, `planType`, **`school_url`** (the origin of whichever Canvas/LMS tab the event fired from — i.e. which school you attend is disclosed with every event), browser + OS (parsed from user-agent), and an `email_domain` (domain portion only, lowercased — not the full email address). A cooldown helper prevents the same "viewed"-style event from re-firing more than once per 60 minutes by default. Representative event names found as literal strings (23 of the 85 call sites; others likely build the name dynamically): `auth_modal_closed`, `theme_view_opened`, `themes_community_opened`, `upgrade_modal_viewed`, `upgrade_breathe_widget_viewed`, `upgrade_filesai_trial_limit_viewed`, `upgrade_notes_limit_viewed`, `upgrade_quote_widget_viewed`, `upgrade_swap_limit_viewed`, `upgrade_transcript_trial_limit_viewed`, and others matching the paywall keys from section (a) one-to-one.

### Login flow

Confirmed Supabase-backed (hardcoded Supabase project URL, section a), but the extension does not talk to Supabase directly for auth — real auth operations go through BetterCampus's own backend: `POST /auth/email-session` (a **passwordless, one-time-code (OTP) email login** — no password field anywhere), `/auth/session`, `/auth/logout`, `/auth/refresh-session`. The only direct Supabase call found client-side is an unrelated health-check ping (`/rest/v1/rpc/ping_health_check`). **Where login happens**: since there's no `default_popup` and no `identity`/`oauth2` manifest permission, it's neither a classic extension popup nor Chrome's native OAuth flow — it's an **in-page modal injected directly into the Canvas page** by the content script (at the top frame) or requested via `postMessage` from a child iframe. The same mechanism opens the Pro-upgrade/paywall panel.

### Consent — telemetry defaults ON, no in-extension opt-out UI found

`anonymous_usage_data` (default **true**) is the sole positive-consent condition actually read. `browser_data_collection_granted` (default `null`, device-only) is read in the same gate but **never written anywhere** in any of the seven bundled scripts — since the check is `!== false`, a `null` value always evaluates as granted. `analytics_enabled` (default true) is a **fully dead setting** — zero read/write sites anywhere outside its own schema line. After exhaustively grepping all seven scripts for any checkbox/toggle UI wired to either consent key, **none was found inside the extension package** — every reference is inside the read-only consent-check function or the schema default itself. (This covers only the extension's bundled code; a control could exist on the bettercampus.com website's own account-settings page, which ships no code inside this package and was out of scope for a static teardown.)

### Referral program

Confirmed real and fully built out server-side: `POST /referrals/claim` (body `{code}`, blocks self-referral), `POST /referrals/claim-reward`, `GET /referrals/info` (dashboard data), `POST /referrals/invite` (body `{email}`, blocks self-invite, **rate-limited**: `429 "Daily invite limit reached — try again tomorrow."`), `GET /referrals/invites`, `POST /referrals/invites/remind`. A referral code picked up from a link is cached client-side (`pending_referral_code`) until the user actually creates an account, then claimed automatically. `"app:referrals"` is a first-class page in the extension's internal router, alongside Hub/Planner/Study/Locker/Grades/Notes/Settings/Explore — referrals get a dedicated screen, not just a modal. The shipped `referrals/wall-of-love.png` asset (73,506 bytes) ships alongside this feature, though no literal code reference to that exact filename was found (likely loaded via a hashed build path) — consistent with a testimonials/"wall of love" page. **The concrete reward was independently confirmed during this analysis** (section a): four transactional-email templates (`all.pretty.js:14078-14122`) state the reward directly — referring a friend gives the new signup a **14-day Pro trial** (instead of the standard 7-day trial) and credits the referrer **14 days of Pro** once their invitee starts that trial.

### Stripe / billing

`stripe.pretty.js` (registered on `https://*.bettercampus.com/*`) does **not** mount Stripe Elements or Checkout — zero hits for `Stripe(`, `elements()`, `confirmPayment`, `clientSecret`, or any `pk_live_`/`pk_test_` key anywhere in the file. It's purely a **post-checkout return-page listener**: it only activates on the `/success` or `/payment-success` paths, polls `GET /users/subscription-status` until the plan is active, then posts `SUBSCRIPTION_ACTIVATED` to the parent frame and asks the background worker to reopen the Canvas tab. The bundled API-route registry lists the full Stripe-adjacent billing surface (`create-stripe-checkout`, `create-portal-session`, `cancel/pause/resume/refund-subscription`, `extend-trial`, `switch-to-annual`, `get-stripe-prices`) — but none of those routes are actually called from this file, strongly implying the backend creates a Stripe-hosted Checkout Session server-side and simply bounces the user back to this listener afterward. **No pricing amounts, plan names, or product IDs are hardcoded anywhere in the client** — `planType` is read generically off the JSON response, and prices are fetched live server-side via `get-stripe-prices`. A build-time env block confirms the full hosting stack: frontend at `bettercampus.com`, the embedded app at `ext.bettercampus.com`, the backend API at `api.bettercampus.com` (Cloudflare-fronted), a client PostHog key, and the Supabase project URL/anon key (a Supabase anon key is meant to be public by design, not a leaked secret).

---

## The full feature list, one line each

Free/Pro reflects what the code actually gates (paywall registry, entitlement quotas, or a hard "account required"), not marketing claims. "Canvas page/area" is where it lives, not every page dark-mode CSS happens to reach.

| # | Feature | Free / Pro | Canvas page / area |
|---|---|---|---|
| 1 | Dark mode (manual toggle) | Free | Global |
| 2 | Dark mode presets (Lighter / Darker, only 2 built-in) | Free | Theme editor |
| 3 | Community theme marketplace (browse/like/comment) | Free to browse | Theme editor (iframe/API) |
| 4 | Apply a community theme, logged out | Free — 5 swaps (`noaccount_swaps`) then account required | Theme editor |
| 5 | Apply a community theme, logged in on Free | Pro-gated (`themeSwapLimit`) | Theme editor |
| 6 | Save a custom theme | Pro-gated past a cap (`themeSaveLimit`) | Theme editor |
| 7 | Theme History (recent applied themes) | First 2 free, older entries Pro-gated | Theme editor |
| 8 | Scheduled dark mode (time window or match-device) | Free | Global |
| 9 | Custom fonts (Google Fonts, 36 curated + free-text) | Free | Theme editor |
| 10 | Custom cursors (default + pointer, solid or image) | Free | Theme editor |
| 11 | Theme stickers | Free up to 3/theme, then Pro-gated | Theme editor |
| 12 | Contrast/readability checker (warns; enforced on publish) | Free | Theme editor |
| 13 | Theme auto-rotate on a schedule | Free | Theme editor |
| 14 | Apply the active theme to bettercampus.com itself | Free | Global |
| 15 | Better to-do list (Canvas planner feed) | Free | Dashboard, course home |
| 16 | To-do Day / Week / Month / Custom views | Free | Dashboard |
| 17 | Overdue-item visibility window (Never/3 Days/Week/Month/Always) | Free | Dashboard |
| 18 | Progress ring/bar (8 styles incl. a video-loop "spinning cat" style; 1 dead option) | Free | Dashboard |
| 19 | Hide completed tasks | Free | Dashboard |
| 20 | Relative due dates | Free | Dashboard |
| 21 | Todo reminders | Free | Dashboard |
| 22 | New Assignment / custom task (with recurrence) | Free | Dashboard |
| 23 | Custom task types (global + per-course, can import real Canvas Assignment Groups) | Free, ≤10 per course | Dashboard |
| 24 | Card tasks (assignments under course cards) | Free | Dashboard |
| 25 | Card grades | Free | Dashboard |
| 26 | Grade-pill click destination (Canvas page vs. BetterCampus panel) | Free | Dashboard |
| 27 | Hover-only grade reveal (privacy) | Free | Dashboard |
| 28 | Condensed cards | Free (effect not confirmed in this bundle) | Dashboard |
| 29 | Card images / colors / gradients / roundness / size | Free | Dashboard |
| 30 | Card create-course button, bookmark icons | Free | Dashboard |
| 31 | Dashboard card limit (25) | Free | Dashboard |
| 32 | Universal search (⌘K/Ctrl+K, Pages + Assignments only) | Free | Dashboard |
| 33 | Widget: Planner | Free | Dashboard |
| 34 | Widget: Notes | Free up to a cap, then Pro-gated (`notesLimit`) | Dashboard |
| 35 | Widget: Study overview | Free (remote flag) | Dashboard |
| 36 | Widget: Grades / GPA / GPA Trend | Free (remote flag) | Dashboard |
| 37 | Widget: Theme showcase | Free | Dashboard |
| 38 | Widget: Quote carousel | Pro-gated (account) | Dashboard |
| 39 | Widget: Music player (Spotify/YouTube/Apple Music) | Pro-gated (account) | Dashboard |
| 40 | Widget: Breathe (guided breathing exercise) | Pro-gated (account) | Dashboard |
| 41 | Widget: "Doge" meme clicker | Free | Dashboard |
| 42 | Widget: Pet / virtual-pet habitat & inventory economy | Gating not confirmed | Dashboard |
| 43 | Lecture-recording widget | Free (not otherwise documented) | Dashboard |
| 44 | GPA calculator (current + cumulative, always shown together) | Free | Dashboard/Grades |
| 45 | Weighted GPA (via school-level Honors/AP flag, not the dashboard toggle) | Free | Grades settings |
| 46 | Import a past-semester GPA (manual entry) | Free | Grades |
| 47 | Import a past transcript (AI-parsed, Cloudflare Workers AI) | Requires account | Grades |
| 48 | What-If grades simulator (local-only, never writes to Canvas) | Free | Grades |
| 49 | Grade Trends chart (per-semester GPA history) | Free (remote flag) | Grades (iframe) |
| 50 | Goals (per-class + per-semester target grade) | Free (data model only; input UI not located) | Grades (likely iframe) |
| 51 | "Reset All Goals?" confirmation on disabling GPA calc | Free | Grades |
| 52 | Assignment-group weighting (reads Canvas's real weights) | Free | Grades |
| 53 | Grade history CSV/JSON export | Free | Grades |
| 54 | Sidebar (courses/pages/widgets rail) | Free | Global |
| 55 | Sidebar collapse/expand, width/density/icon-scale | Free | Global |
| 56 | Hide School Logo | Free | Global sidebar |
| 57 | Hide BetterCampus Logo (with confirmation flow) | Free | Global sidebar |
| 58 | Notes (rich text course notes, folders) | Free up to a cap | Notes / sidebar |
| 59 | Smart Notes (AI note enhancement) | Entitlement-capped | Notes |
| 60 | Files AI (AI document chat, GPT-4o-mini) | Free trial then Pro (`filesaiTrialLimit`/fair-use) | Files sidebar |
| 61 | Lecture transcription (AI, Groq) | Free trial then Pro (`transcriptTrialLimit`/fair-use) | Study/course pages |
| 62 | Study Sets (flashcards), Study Sessions (timed) | Entitlement-capped | Study (navigator) |
| 63 | PDF/document viewer dark mode | Free | canvadocs (Files) |
| 64 | PDF annotations (6 tools) | Requires account | canvadocs (Files) |
| 65 | AI "Explain selected text" | Presumably tied to Files AI gating | canvadocs (Files) |
| 66 | Calendar sync — Google Calendar (read into to-do only; no confirmed write) | Free | External Google Calendar page + Dashboard |
| 67 | Calendar sync — Outlook/Microsoft Calendar (read into to-do only) | Free | External Outlook page + Dashboard |
| 68 | Google Calendar "Tasks" auto-enable | Free | External Google Calendar page |
| 69 | Syllabus import/parsing (auto-detect grade cutoffs) | Free | Course syllabus / Grades setup |
| 70 | Custom-task overrides sync (interval remotely tunable) | Free | Dashboard |
| 71 | Quiz Safe Mode (suppresses theme only, opt-in) | Free | Quizzes/Assignments |
| 72 | Marketing-popup suppression during quizzes (always on) | N/A | Quizzes/Exams |
| 73 | Streak tracking (server-validated, 2-day grace, 1-year backfill) | Free | Dashboard |
| 74 | Streak restore after a break | Pro-gated (`streak_restores`, 48-hour window) | Dashboard |
| 75 | Streak rarity/percentile stat | Free | Dashboard |
| 76 | Celebration animations (confetti/fireworks/stars/hearts/sparkle) | Free | Dashboard |
| 77 | Celebration sound effects | Built but inert — no code path ever enables sound | Dashboard |
| 78 | "Wrapped" yearly recap | Backend live, frontend not located (likely unshipped) | Popup/dashboard |
| 79 | Referral program (invite a friend) | N/A — 14-day Pro trial to both sides | Popup, `app:referrals` |
| 80 | Friends (social) | Free | Popup/dashboard |
| 81 | "Wall of love" testimonials asset | Free (read-only) | Marketing/popup |
| 82 | Account login (passwordless email OTP, in-page modal) | N/A | Global |
| 83 | Free trial (7 days standard) | N/A | Account |
| 84 | Subscription billing (Stripe-hosted Checkout, monthly/annual) | N/A | bettercampus.com |
| 85 | Billing portal, invoice history, pause/cancel/resume subscription | N/A | bettercampus.com |
| 86 | Push/email notification preferences (12 categories) | Free | Settings |
| 87 | Onboarding tours (per-feature) | Free | Various |
| 88 | Age verification | N/A (compliance) | Account |
| 89 | QR cross-device login handshake | Free | Account/popup |
| 90 | Anonymous usage analytics (PostHog) | Opt-in by default, no in-extension opt-out UI found | Global |
| 91 | Uninstall feedback survey | N/A | Browser |
| 92 | RCE (Rich Content Editor) dark mode | Free | Assignments/Discussions/Announcements/Pages create-edit forms |
| 93 | Course-home "Customize/Edit" CTA | Free | Course home |
| 94 | Assignment-row details button + status classification | Free | Assignments list |
| 95 | Assignment-page calendar-"Sync" button | Free | Assignments list |
| 96 | Custom section injected into assignment groups | Free | Assignments list |
| 97 | Grades-page sidebar-width layout fix | Free | Grades |
| 98 | Nav-badge sync for Calendar/Conversations/Groups | Free | Calendar, Inbox, Groups |
| 99 | Chrome Dino game easter egg (iframe embed) | Free | Dashboard widget area |
| 100 | Multi-LMS support (Blackboard, Moodle, Brightspace, Google Classroom, Gradescope) | Free | Global (out of scope for this report) |

---

## Settings keys, raw

Complete transcription of every key in the master settings schema (object `sg`, `all.pretty.js:10361-10769`). `syncType:"server"` (cloud-synced via `chrome.storage.sync`) unless marked `[device]` (local-only, `chrome.storage.local`). Object/array defaults are written out in full; a few reference other in-scope variables (noted inline).

```
# --- todo_* block (generated via a spread from a sub-object, all "server") ---
todo_colors=true
todo_24hr=false
todo_openall=false
todo_overdues=true
todo_overdue_viewable_period="week"
todo_question=false
todo_completed=[]
todo_history=[]
todo_read=[]
todo_style="circle"
todo_style_general="modern"
todo_time="week"
todo_custom_value=7
todo_custom_unit="days"
todo_period_start="rolling"
todo_celebrated=[]
todo_confetti_amount="normal"
celebration_style="confetti"
todo_show_courses=false
todo_show_date_buttons=true
todo_streaks=true
relative_dues=false
todo_open_target="new_tab"
todo_active_only=true
todo_date_grouping=true
todo_urgent_highlight=true
todo_completion_mode="auto"
todo_educator_tasks=true
todo_educator_tasks_progress=true

# --- main block ---
campaign_state=<variable `ci`, not a literal> [device]
dark_preset=<dark palette object `ag`: background-0 #212121, background-1 #2a2a2a, background-2 #333333, borders #3d3d3d, buttons #333333, links #56Caf0, sidebar var(--ic-brand-global-nav-bgd__dark), sidebar-text var(--ic-brand-global-nav-menu-item__text-color__dark), text-0 #f5f5f5, text-1 #e2e2e2, text-2 #ababab, cards #2a2a2a>
light_preset=<light palette object `rg`: background-0 #ffffff, background-1 #f2f1f4, background-2 #d7d5dd, borders #d7d5dd, buttons #f2f1f4, links #4a90e2, sidebar var(--ic-brand-global-nav-bgd), sidebar-text var(--ic-brand-global-nav-menu-item__text-color), text-0 #273540, text-1 #777777, text-2 #737373, cards #ffffff>
default_preset="darker"
theme_contrast_threshold="off"
new_install=true
notes_sort_mode="recent"
assignments_due=true
card_overlay_opacity=65
gpa_calc=false
gpa_calc_size="medium"
gpa_calc_cumulative=false
gpa_calc_prepend=true
gpa_calc_weighted=false
dark_mode=false
dark_mode_before_theme=null
gradent_cards=false   # [sic -- typo for gradient_cards, see section a]
disable_color_overlay=false
card_bookmark_icons=true
card_create_button=true
auto_dark=false
auto_dark_behavior="match_device"
auto_dark_start={hour:"20",minute:"00"}
auto_dark_end={hour:"08",minute:"00"}
num_assignments=4
custom_domain=[""]
card_width=262
dashboard_grades=true
card_grade_target="canvas"
assignment_date_format=false
dashboard_notes=false
dashboard_notes_size="small"
doge_widget=false
doge_widget_size="small"
dashboard_notes_height=""
dashboard_notes_text=""
better_todo=true
condensed_cards=false
has_used_files_ai=false
has_used_transcribe=false
custom_assignment_types=[]
grade_hover=false
hide_completed=false
num_todo_items=4
custom_font=""
hover_preview=true
remlogo=false
hide_bettercanvas_logo=false
pending_hide_logo_confirmation=false
date_format="mm/dd"
clock_format="12"
date_text_type="numeric"
hide_feedback=false
classroom_hide_due_soon=false
classroom_hide_learning_tools=false
dark_mode_fix=false
tab_icons=false
device_dark=false
show_updates=false
card_method_date=false
card_method_dashboard=false
card_limit=25
remind=false
reminder_count=1
multi_remind=false
id=""
onboard=false
token=""
trial_card_dismissed=false
planned={}
clean_sidebar=true
custom_types_migrated=false
course_custom_types={}
sidebar_pages=[{id:"bc-assignments",active:false},{id:"bc-study",active:false},{id:"bc-notes",active:false},{id:"bc-grades",active:false}]
sidebar_pages_brightspace=[{id:"bc-assignments",active:false},{id:"bc-study",active:false},{id:"bc-notes",active:false},{id:"bc-grades",active:false}]
sidebar_pages_moodle=[{id:"moodle-nav-home",active:true,label:"Home"},{id:"moodle-nav-myhome",active:true,label:"Dashboard"},{id:"moodle-nav-mycourses",active:true,label:"My courses"},{id:"bc-assignments",active:false},{id:"bc-study",active:false},{id:"bc-notes",active:false},{id:"bc-grades",active:false}]
sidebar_settings_pages=[{id:"general",active:false,alternatives:["appearance","courseDetails","dashboard","todo","sidebar","other","advanced"]},{id:"themes",active:false,alternatives:[]}]
sidebar_collapsed=false
blackboard_sidebar_collapsed=false
sidebar_collapsed_sections=[]
sidebar_small=false
sidebar_label_density="compact"
sidebar_size_scale="medium"
sidebar_collapsed_show_labels=true
sidebar_collapsed_separate_pins=false
sidebar_expanded_sections={widgets:true,pages:true,courses:true}
sidebar_collapsed_sections_visibility={widgets:true,pages:true,courses:true}
global_search=true
rounder_cards=true
card_assignments=true
insights={}
streakBegin=Date.now()   # evaluated at load time
assignments_unassigned_period=7
assignments_minical_days=1
assignments_week_days=7
assignments_calendar_view_type="week"
assignments_zoom=100
assignments_view="due"
assignments_auto_plan={days:1,time:"morning"}
assignments_display_off=["planned"]
auth=null
auth_state=null
card_image_size=2
card_roundness=10
card_gap=15
filesai_open=true
filesai_width=380
filesai_mode="sidebar"
todo_reminders_time=[3]
planned_session_reminders_time=[3]
notes_prompts_time=[10]
study_prompts_time=[2]
planner_prompts_time=[3]
todo_reminders=false
selected_theme=null
theme_enabled=false
theme_apply_to_bettercampus=false
cursors=null
anonymous_usage_data=true
card_timeframe="week"
has_seen_spotlight=false
has_clicked_sync=false
microsoft_calendars={}
google_calendars={}
microsoft_cal_last_sync=0
popup_onboarding_active=false
analytics_enabled=true
quote_widget_preferences={default_category:null,loop_mode:"infinite",auto_scroll_duration:10}
card_crossout=false
card_display_mode="manual"
noaccount_swaps=5
changelog_dont_show_again=false
file_annotation_dont_show_again=false
stored_extension_version=""
custom_assignments_section_expanded=true
notification_preferences={task_due_soon:{browser:true,mobile:false,email:false},task_due_today:{browser:true,mobile:false,email:false},overdue_task:{browser:false,mobile:false,email:false},task_reminders:{browser:true,mobile:false,email:false},planned_session_reminders:{browser:false,mobile:false,email:false},class_start_reminder:{browser:true,mobile:false,email:false},study_prompts:{browser:true,mobile:false,email:false},billing_events:{browser:false,mobile:false,email:false},account_security:{browser:false,mobile:false,email:false},webstore_review_prompts:{browser:false,mobile:false,email:false},grades_prompts:{browser:false,mobile:false,email:false},planner_prompts:{browser:true,mobile:false,email:false}}
browser_show_notifications=["canvas"]
show_changelog_popups=false
fileviewer=true
annotations=true
filesai_sidebar=true
auto_rotate_theme=false
auto_rotate_interval="24"
auto_rotate_last_rotated=0
auto_rotate_start="3:0"
auto_rotate_source="mine"
auto_rotate_selections_mine=["created","remixed","liked"]
auto_rotate_selections_community=["trending","new"]
card_show_status=true
show_assignments_integrations=true
grades_setup_complete=false
navigator_time_period="month"
last_announcement_check=0
trial_end_dismissed=false
trial_2d_dismissed=false
fresh_install_tour_pending=false [device]
should_show_spotlight=false [device]
spotlight_active=false [device]
hub_tour_active=false [device]
browser_data_collection_granted=null [device]
should_apply_anti_flicker=true
assignments_onboarding_viewed=false
assignments_setup_complete=false
notes_onboarding_viewed=false
study_onboarding_viewed=false
dont_show_recording_explanation=false
quiz_safe_mode=false
dashboard_widget_variants=[]
dashboard_widget_order=[]
dashboard_widget_layout={}
dashboard_widgets={planner:false,planner_expanded:false,notes:false,notes_expanded:false,study:false,grades:false,grades_gpa:false,grades_trend:false}
streak_icon=365
streak_disabled=false
wrapped_viewed=false
lms_sync_type=null
encryption_key="" [device]
notes_recently_opened=[] [device]
errors=[] [device]
saved_themes={} [device]
cached_theme_likes={} [device]
request_cache={} [device]
request_response_cache={} [device]
cached_friend_ids={} [device]
cached_streak_restores=null [device]
theme_sticker_palette=null [device]
sticker_mode={kind:"off"} [device]
sticker_session=null [device]
pending_theme_edits=false [device]
bc_sidebar_pages_default_off_applied=false [device]
pages_blocked_verdict=null [device]
pages_blocked_ack=false [device]
cached_planned_assignments={} [device]
overrides={} [device]
dirtyOverrides={} [device]
lms_completion_pushed={} [device]
device_id="" [device]
calendarMeta={} [device]
calendar_tasks_enabled=false [device]
should_sync_calendar=false [device]
calendar_providers=[] [device]
todo_dropdown_state={} [device]
calendar_tasks_should_check=false [device]
feature_flags={interval_popups_enabled:false,anonymous_campaigns_enabled:false,study:true,grades:true,streak:false,streak_restores:false,grades_ext_page:true,dashboard_widgets:false,dashboard_widget_grid:false,intro_video:false,show_mobile_app:false,overrides_sync_interval_minutes:15,payment_failure_modal:false,dark_mode_patches:[],hooks:{},enable_sync:false,wrapped:false,did_you_know:true,course_card_create_button:true} [device]
feedback_prompt_submitted=false [device]
feedback_prompt_dismissed_at=0 [device]
feedback_prompt_force_show=false [device]
last_flag_refresh=0 [device]
last_sync_time=<new Date(0).toISOString(), i.e. "1970-01-01T00:00:00.000Z"> [device]
suppress_push_until=0 [device]
tour_state_by_user={} [device]
encEventData={} [device]
gradescopeData={} [device]
reminders_enabled=false [device]
streak={started_at:"",high:0,last_verified:"",last_expired:"",restored_at:"",push_dirty:null,last_sync:""} [device]
study_notebooks_cache=null [device]
pet_profile_updated_at=0 [device]
study_sets_updated_at=0 [device]
notes_updated_at=0 [device]
cached_game_home=null [device]
cards={} [encrypted=true]
```
