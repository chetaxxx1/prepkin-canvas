# Canvas LMS — what there is to skin

Research pass, 2026-09-03. Built from 15 agents: 5 page-mappers, a BetterCanvas teardown,
an InstUI/CSP constraints report, a repo audit, a student-voice sweep, and 5 adversarial
verifiers. Sources are the `instructure/canvas-lms` and `instructure/instructure-ui`
repos, Instructure docs and release notes, Chrome extension docs, and a live production
Canvas build (Dartmouth `common.css`, 401 KB).

## Corrections applied after the synthesis was written

The synthesis below states three of five verdicts did not arrive. All five did. Three of
its conclusions are wrong as written and are corrected here. **This section wins.**

1. **Cross-origin iframes ARE reachable.** A content script is injected per frame, matched
   by that frame's own URL. `"all_frames": true` plus a `matches` entry for the frame's
   origin gives a second script instance inside the child with full DOM and CSS access.
   Isolated-world CSP has no `style-src`, so the host page cannot block injected CSS.
   §4.4's "complete unreachable list" is wrong. The real blockers are permission scope
   (third-party LTI origins are unbounded per school, so covering them means
   `<all_urls>`) and unauditable vendor markup — not technical impossibility.
   **DocViewer and Canvadocs are reachable** with `https://*.instructure.com/*` +
   `https://*.inscloudgate.net/*` and `all_frames: true`.
2. **New Quizzes is no longer an iframe.** Feature flag `new_quizzes_native_experience`
   went GA opt-in 2026-03-26, default on 2026-07-01, and **enforced 2026-08-15**. It now
   renders same-origin as `body.native-new-quizzes` > `#new-quizzes-root > #root`. Style
   the container from ordinary top-frame CSS. Its interior is module-federated InstUI, so
   container/spacing/typography only.
3. **There is no CSP font problem.** Canvas's only always-on CSP header is
   `frame-ancestors`. A Google Fonts `@font-face` loads fine. §4.4's recommendation to
   ship a system stack still stands, but for privacy and speed, not for CSP.

Two smaller corrections:

4. **`brandable_variables.json` declares 47 variables in 6 groups**, not 31. Two agents
   read the same file and disagreed; the deeper read cites the groups. Either way,
   enumerate the live `:root` on the target instance at build time.
5. **`#grades_summary` / `.student_assignment` are already dead** for any course with
   `restrict_quantitative_data` on — no feature flag needed. Detect `#grade-summary-react`
   first and skip the grades rules when present.

---

# Canvas LMS — what there is to skin

**A joint reference for design and engineering. Prepkin Canvas extension, 2026-09-03.**

**How to read this.** Every selector carries a confidence label: `verified` (read in `instructure/canvas-lms` or `instructure-ui` source, or measured on a live instance), `likely` (strong inference from verified code, or style verified but emitter not located), `guess` (style exists, no emitter found). This document merges five recon reports with five adversarial verdicts. **Where a verdict contradicts a recon report, the verdict wins**, and the override is stated in the open. Two of the five verdicts came through complete; three did not, and several recon reports were truncated in transit. Gaps are marked `[input truncated]` rather than filled with invention.

---

## 1. The one-paragraph situation

Canvas is not one visual system. It is a Rails multi-page app whose server-rendered ERB carries hand-written, semantic, decade-stable class names (`ic-*`, `ig-*`, `item-group-*`) and real ids, with React islands mounted inside it, some of which also hand-write those same stable classes and some of which render pure Instructure UI (InstUI) whose class names are content hashes that change on every deploy. A skin can repaint the entire server-rendered layer for free by overriding 31-plus `--ic-brand-*` custom properties on `:root`, and can restyle anything with an `ic-*` class or a stable id with ordinary CSS. It can reach React internals only through `data-testid` attributes and mount-point ids. It cannot touch anything InstUI paints through its JavaScript theme (Files v2, InstUI headers, trays, modals, selects), it cannot reach inside a cross-origin LTI iframe (New Quizzes, Studio, publisher tools, proctoring), and it must switch itself off entirely when the student has High Contrast on. The surface is large, it is genuinely skinnable, and it is shrinking: Canvas is mid-rewrite, with `context_modules_v2`, `files_v2`, `new_login`, `widget_dashboard` and an InstUI nav all sitting in master behind flags, each one converting a stable page into an unstyleable one.

### Where a verdict overturned a recon report

| Recon said | Verdict says (this wins) | What changes |
|---|---|---|
| Overriding `--ic-brand-*` on `:root` recolours React/InstUI pages | It recolours **Canvas's own CSS layer only**. InstUI reads the same names out of a JS object (`CANVAS_ACTIVE_BRAND_VARIABLES`), spread into an Emotion theme, then run through `darken()` / `alpha()` in JS. `@instructure/ui-themes@11.7.5` ships **zero** occurrences of `var(--`. A `:root` override changes nothing InstUI paints. | "React page" is the wrong dividing line. Many React components (dashboard cards) hand-write `ic-*` classes and **do** respond to `:root`. |
| A MAIN-world content script can patch `CANVAS_ACTIVE_BRAND_VARIABLES` to theme InstUI (`[likely]`) | Out of scope. Content scripts run in an isolated world and cannot see the page global. MAIN-world injection is subject to the page's CSP, and Canvas accounts can enable CSP (`ENV.csp` drives `ui/boot/initializers/setupCSP.js`). It would also have to win a race against React's first render, since the theme is computed once at provider mount. | **Do not build this.** Treat InstUI colour as unreachable, not as a hard problem. |
| React pages have hashed classes and are therefore unsafe to skin | Half right, wrong conclusion. Hashes are unsafe, yes. But Inbox, Discussions Redesign, Assignment Enhancements and Planner all carry dense `data-testid` hooks, mount inside the untouched legacy skeleton (`#content.ic-Layout-contentMain`), and the body carries semantic scoping classes. | Inbox, Discussions and Assignment Enhancements move **up** from "unreachable" to Tier 2 designable. |
| `[class*="-view--flex"]` is a fragile-but-usable label-anchored fallback | The label suffix does survive production builds, so the selector matches. It also matches every InstUI `View` on the page. **Never ship it.** | No hash-adjacent selectors at all, not even label-anchored ones. |
| `brandable_variables.json` declares 45 admin-editable variables in 6 groups | **31** admin-editable variables in 6 groups (Global Branding, Global Navigation, Watermarks, Login, Discovery, Registration). | Both cite the same file as verified, so this is a live disagreement. Verdict wins on the count. Practical resolution: enumerate `:root` on the target instance at build time rather than trusting either number. The recon's *measured* figure of 61 declared properties on a live `:root` (Dartmouth) includes the 14 Canvas-computed derivatives and is not in conflict. |
| Planner rows are styled by stable `.PlannerItem-styles__*` literals from `style.js` | `PlannerItem/index.tsx` imports no `.css`/`.scss` and has no `styles.*` className usage. The CSS-Modules generation is gone from that component. | Use `[data-testid="planner-item-raw"]` as the **primary** planner hook. Treat `.PlannerItem-styles__*` as opportunistic only, and never load-bearing. This directly implicates a shipped Prepkin rule (see §5). |

---

## 2. The page map

Frequency is for a **student**, not a teacher. Markup generation uses five labels, not the usual three, because the verdict proved "React vs legacy" is not the real split:

- `legacy-stable` — server-rendered ERB or Backbone/Handlebars. Semantic classes and ids. Safe forever.
- `react-stable` — React, but every `className` is a hand-written literal (`ic-DashboardCard`). Styled by ordinary Canvas SCSS. **Responds to `--ic-brand-*`.** Safe.
- `react-testid` — React/InstUI. No usable classes, but dense `data-testid` and a stable mount id. Skinnable with care.
- `react-hashed` — React/InstUI with nothing but Emotion hashes. Not skinnable.
- `iframe` — cross-origin. Unreachable by any page-level CSS.

| # | Page | URL pattern | Frequency | Markup | What a skin can do here |
|---|---|---|---|---|---|
| 1 | Global left nav rail | `*` (every authed page) | daily, always | `legacy-stable` | Full repaint via 13 nav brand vars. Inject a Prepkin `<li>` that inherits hover label, badge and active state for free. |
| 2 | Breadcrumb bar | `*` except `/` | daily, always | `legacy-stable` (`react-hashed` under `@instui_topnav`) | Persistent status strip. Half the bar is empty and it never overlaps content. |
| 3 | Flash toasts + admin banners | `*` (outside `#application`) | daily | `legacy-stable` | Restyle the four `ic-flash-*` semantics once. Render Prepkin's own toasts into the same holder. |
| 4 | Dashboard, Card view | `/`, `/dashboard` | daily | `react-stable` | Full card restyle. Hero block is 146px of information-free colour. |
| 5 | Dashboard, List view (Planner) | `/` when `dashboard_view=planner` | daily | `react-stable` + `react-testid` | Urgency colour-coding on rows. Right sidebar is force-hidden here. |
| 6 | Right sidebar (To Do / Coming Up / Recent Feedback) | `/`, `/courses/:id` | daily | mixed | Turn plain-grey due strings into urgency pills. Highest-value single change on the dashboard. |
| 7 | Course nav menu | `/courses/:id/*` | daily | `legacy-stable` | Per-tab icons and colour by `a.modules` / `a.grades`. Reorder with flex `order`. |
| 8 | Course home | `/courses/:id` | daily | mixed, 5 variants | Branch on variant. `body.context-course_<id>` gives per-course theming. |
| 9 | Modules | `/courses/:id/modules` and course home | daily | `legacy-stable` (v2 React in flight) | Deep restyle available today. Time-limited: `context_modules_v2` is a full React rewrite in master. |
| 10 | Assignment detail (student) | `/courses/:id/assignments/:id` | daily | mixed | Legacy ERB path is fully skinnable. Enhancements path needs `[data-testid="assignments-2-student-view"]`. |
| 11 | Global nav trays (Courses, Groups, History, Help) | overlay, no URL change | daily | `react-testid` + stable wrapper | `.navigation-tray-container.{type}-tray` is stable. Append a footer, prefix course rows with the course colour. |
| 12 | Mobile header + context nav | `*` at <768px | daily on phone | mixed | ~56px bar, mostly empty. Compact chip fits with nothing to fight. |
| 13 | Assignments index | `/courses/:id/assignments` | several/week | `legacy-stable` (Backbone) | `.ig-row` grammar shared with Modules. One ruleset covers both. |
| 14 | Grades (student) | `/courses/:id/grades` | several/week | `legacy-stable` + React islands | 773 lines of semantic ERB. The safest heavy restyle in Canvas. |
| 15 | Inbox | `/conversations` | weekly | `react-testid` | Skinnable via `[data-testid="conversation"]` and friends. Mounts into `#content`. |
| 16 | Discussions (index + thread) | `/courses/:id/discussion_topics[/:id]` | weekly | `react-testid` | `[data-testid="discussion-topic-container"]` plus one surviving legacy class. |
| 17 | Quizzes (classic) | `/courses/:id/quizzes[/:id]` | weekly | `legacy-stable` | 391 lines of ERB, `#quiz_show`. New Quizzes is an iframe and is not this. |
| 18 | Calendar | `/calendar` | weekly | mixed (FullCalendar + React) | `.fc-*` classes are FullCalendar's public API and are stable. Hash-driven navigation. |
| 19 | Dashboard, Recent Activity | `/` when `dashboard_view=activity` | weekly | `legacy-stable` | Safest dashboard view to restyle heavily. Same partial as course home "feed". |
| 20 | Pages / wiki | `/courses/:id/pages/*` | weekly | `legacy-stable` shell, teacher HTML inside | Style the shell. Never assume structure inside `.user_content`. |
| 21 | Syllabus | `/courses/:id/assignments/syllabus` | weekly | `legacy-stable` shell | Same as above. |
| 22 | Files | `/files`, `/courses/:id/files` | weekly | `react-hashed` | **Nothing.** `FileFolderTable.tsx` contains zero `className=`. |
| 23 | Courses index (All Courses) | `/courses` | occasional | `legacy-stable` | Plain semantic tables with per-column classes. Add a computed column. |
| 24 | Account / profile tray | overlay | occasional | `react-hashed` + stable wrapper | Only `.profile-tray` and hrefs. Good place for one Prepkin settings row. |
| 25 | Dashboard options kebab | overlay | occasional | `react-hashed` + testid | Do not restyle the popover. Render your own switcher and proxy clicks. |
| 26 | People / roster | `/courses/:id/users` | occasional | `legacy-stable` | Inherits the page wash. Low value. |
| 27 | Profile settings | `/profile/settings` | occasional | `legacy-stable` | Inherit only. |
| 28 | Groups | `/groups/:id/*` | occasional | mixed | Reuses the Recent Activity partial. Inherits. |
| 29 | Login | `/login/*` | occasional | `legacy-stable` + 16 `--ic-brand-Login-*` vars | Fully brandable, but it is the school's identity surface. Leave it. |
| 30 | Course settings | `/courses/:id/settings/*` | rare for students | react-router | Skip. |
| 31 | Outcomes / Rubrics / Conferences / Collaborations | `/courses/:id/*` | rare | mixed | Skip. Style by exclusion in the course nav. |
| 32 | New Quizzes | LTI iframe | weekly in some courses | `iframe` | Unreachable. Student sees stock white Canvas inside a dark skin. |
| 33 | Canvas Studio | LTI iframe | occasional | `iframe` | Unreachable. |
| 34 | Proctorio / LockDown / publisher LTI | LTI iframe | occasional | `iframe` | Unreachable. Actively hostile to skinning. |
| 35 | Canvadocs document preview | `canvadocs.instructure.com` iframe | weekly | `iframe` | Unreachable. |
| 36 | K5 Homeroom | `/` when `k5_user?` | daily for K-5 only | `react-hashed` | Two ids plus reused `.ic-DashboardCard`. Deprioritise unless the pilot school is K-5. |
| 37 | Widget Dashboard | `/` under `widget_dashboard` flag | daily when flagged on | `react-hashed`, **no server markup at all** | Nothing to skin. `render html: "", layout: true`. Detect and fall back. |
| 38 | SpeedGrader / Gradebook | `/courses/:id/gradebook` etc. | never (teacher) | `react-hashed` | Out of scope. |
| 39 | Canvas mobile apps | native | daily for many | n/a | Not a web surface. Reachable only through Theme Editor `mobile_css_overrides`, which is an admin path. |

### Tiers

**Tier 1 — the product. A student lives here daily. Design every pixel.**
Global nav rail (1), breadcrumb bar (2), dashboard in whichever of its three views the student uses (4, 5, 19), the right sidebar (6), course nav menu (7), course home (8), Modules (9), assignment detail (10), Grades (14). Add the global nav trays (11) because that is how most students actually change course, and flash/banners (3) because they are the only semantic colour Canvas gives a student.

**Tier 2 — seen weekly. Worth designing, less budget.**
Assignments index (13), Inbox (15), Discussions (16), classic Quizzes (17), Calendar (18), Pages (20), Syllabus (21), Courses index (23), mobile header (12).

**Tier 3 — occasional. Style by inheritance only. Do not write page-specific CSS.**
Profile tray (24), dashboard kebab (25), People (26), profile settings (27), Groups (28), Outcomes/Rubrics/Conferences/Collaborations (31). These pick up the page wash, link colour, button styling and type from the global rules and that is enough. The one exception: append one Prepkin settings row to the profile tray, because it makes the product read as native.

**Tier 4 — unreachable or not worth it, with the reason.**
- **Files (22)** — `react-hashed` with literally zero `className` attributes in `FileFolderTable.tsx` and `FilesHeader.tsx`. There is nothing to select. The page will stay stock white inside a dark skin.
- **All cross-origin LTI iframes (32-35)** — Chrome cannot inject into a cross-origin frame the extension has no host permission for, and even with permission this is a separate document with its own origin. `app/views/lti/_launch_iframe.html.erb` renders `.tool_content_wrapper > iframe#tool_content.tool_launch`. Plan for the seam or suppress the skin on those routes.
- **Widget Dashboard (37)** — the controller returns an empty body. There is no ERB scaffolding to target and it ships its own native dark mode that will fight any skin. Detect via `ENV.DASHBOARD_FEATURES` or the absence of `#DashboardCard_Container` / `#dashboard-planner` and hand over to the Prepkin panel.
- **K5 Homeroom (36)** — effectively 100% InstUI outside `#dashboard-app-container`, `#important-dates-sidebar`, and the reused `.ic-DashboardCard`. Gated on account settings most secondary and college students never hit.
- **Login (29)** — technically fully brandable through 16 dedicated variables. Excluded on judgement: it is the school's identity page, a student sees it once a session, and an extension repainting a login screen is the exact behaviour that got BetterCampus blocked by a district. The current Prepkin skin already excludes it and that call is correct.
- **Course settings (30), SpeedGrader/Gradebook (38), mobile apps (39)** — react-router surfaces, teacher tools, and native code respectively.

---

## 3. Per-page anatomy

### 3.1 Global left navigation rail — Tier 1, every page

**Regions, top to bottom.** Skip-to-content link (visually hidden until focused). Brandable logomark block. The vertical icon list: Account avatar, Admin (if adminable), Dashboard, Courses, Groups (only if enrolled in one), Calendar, Inbox, History (if page views on), LTI global-nav tools, Help. Each item is a 26x26 SVG in `.menu-item-icon-container` plus a `.menu-item__text` label that slides out on hover, plus an optional `.menu-item__badge`. Pinned to the bottom: `#primaryNavToggle`. Two empty React mounts at the end.

| Selector | Conf. | Notes |
|---|---|---|
| `#header.ic-app-header` | verified | `position:fixed; top:0; left:0; height:100%; z-index:100`. Width 54px collapsed (`$ic-header-primary-width: 84px` minus 30). `background-color: var(--ic-brand-global-nav-bgd)`. |
| `body.primary-nav-expanded #header.ic-app-header` | verified | Rail becomes 84px, or **104px with the dyslexic font on**, and gains `overflow-y:auto`. Persisted to `/api/v1/users/self/settings` as `collapse_global_nav`. |
| `body.primary-nav-transitions` | verified | Added 300ms after collapsing. Gates the label slide. Respect it or your animation fights Canvas's. |
| `#global_nav_profile_link`, `#global_nav_accounts_link`, `#global_nav_dashboard_link`, `#global_nav_courses_link`, `#global_nav_groups_link`, `#global_nav_calendar_link`, `#global_nav_conversations_link`, `#global_nav_history_link`, `#global_nav_help_link`, `#global_nav_login_link` | verified | The single most reliable hook in all of Canvas chrome. |
| `li.ic-app-header__menu-list-item--active` | verified | Server-rendered from `active_path?`, so correct on first paint. No flash. |
| `.ic-app-header__menu-list-link .menu-item__text` | verified | The slide-out label. Background is `var(--ic-brand-global-nav-ic-icon-svg-fill--active)`, with a CSS-triangle `::after` using the same var. |
| `.menu-item__badge` | verified | Unread pill. `var(--ic-brand-global-nav-menu-item__badge-bgd)` / `-text`. **Empty at first paint**, filled by `NavigationBadges.tsx`. |
| `.ic-avatar img` | verified | Carries `fs-exclude`. Border from `var(--ic-brand-global-nav-avatar-border)`. `.ic-avatar--fake-student` during masquerade. |
| `.ic-app-header__logomark` | verified | `background-image: var(--ic-brand-header-image)`. **Not rendered at all** under high contrast. |
| `#primaryNavToggle.ic-app-header__menu-list-link--nav-toggle` | verified | Collapse chevron. |
| `#skip_navigation_link` | verified | First focusable element. Do not break it. |
| `body:not(.no-headers):not(.content-only):not(.hide-global-nav) .ic-Layout-wrapper` | verified | Gets `margin-left: 54px` (84px expanded) at >=768px. **If a skin resizes the rail it must change this too.** |

**Skin opportunities.**
- Six variable overrides on `:root` reskin the entire rail with zero selector risk: `--ic-brand-global-nav-bgd`, `-ic-icon-svg-fill`, `-ic-icon-svg-fill--active`, `-menu-item__text-color`, `-menu-item__badge-bgd`, `-menu-item__badge-text`. This is the cheapest visible win in the product.
- Inject a sibling `<li class="ic-app-header__menu-list-item">` after `#global_nav_calendar_link`. It inherits hover label, badge and active styling for free.
- Overlay a progress ring on `#global_nav_dashboard_link .menu-item-icon-container` to turn the home button into a daily-goal meter without adding chrome.
- Add a left accent bar to `.ic-app-header__menu-list-item--active`. High signal, one rule.

**Risks.** The `instui_nav` feature flag **deletes this entire header** (`mountPoint.innerHTML = ''`) and renders an InstUI `<SideNavBar>`. Every `#global_nav_*_link` id disappears, replaced by `#instui-sidenav`, `#profile-tray`, `#courses-tray`, `#dashboard-tray`, `#calendar-tray`, `#conversations-tray`, `#history-tray`, `#help-tray`. Feature-detect, never assume. Below 768px the rail is `display:none !important`. `body.hide-global-nav` and `body.no-headers` also hide it.

### 3.2 Breadcrumb bar — Tier 1

**Regions.** `#courseMenuToggle` hamburger (only when the page has a left side), then `div.ic-app-crumbs > #breadcrumbs > ul > li > a > span.ellipsis`, then `#nutrition_facts_container` (empty AI-disclosure mount), then `div.right-of-crumbs` holding observer picker, Student View, immersive reader, top-nav LTI tools and `#ai-information-mount`.

| Selector | Conf. | Notes |
|---|---|---|
| `.ic-app-nav-toggle-and-crumbs.no-print` | verified | Rendered only when `crumbs.length > 1` and not `@content_only`. **Absent on the dashboard** because `user_dashboard` calls `clear_crumbs`. |
| `#breadcrumbs > ul > li` | verified | `display:inline-block`, 18px. **The first `li` is `visibility:hidden`** (the home link is deliberately hidden). `li + li::before` draws the chevron from `/images/breadcrumb-arrow-light.svg`. |
| `#breadcrumbs > ul > li > a .ellipsis` | verified | Truncating span, floated right (inline-block under `body.ff`). |
| `#courseMenuToggle.ic-app-course-nav-toggle` | verified | `aria-live=polite`, label flips Hide/Show. |
| `.right-of-crumbs` | verified | Right-aligned action cluster. |
| `.instui-topnav-container #react-instui-topnav` | verified | **Replaces the whole bar** when `@instui_topnav` is on. Hashed InstUI, no `#breadcrumbs` at all. |
| `body.course-menu-expanded` | verified | Shifts `.ic-Layout-columns` by 192px and moves the desktop breakpoint from 992px to 1140px. |

**Skin opportunities.** This is the best home for a persistent, non-intrusive Prepkin status strip (next due, coins). It is full-width, almost always half empty, sits above the content, and never overlaps it. The deliberately hidden first crumb leaves an odd blank gap at the left that a skin can reclaim for a back arrow or a course-colour dot. The crumb text is the only place the current assignment title appears above the fold on a long page.

**Risks.** Not rendered on the dashboard at all. `display:none !important` below 768px, under `body.no-headers`, `body.content-only` and `body.embedded`. Blanks out entirely under `@instui_topnav`.

### 3.3 Flash messages and announcement banners — Tier 1

| Selector | Conf. | Notes |
|---|---|---|
| `#flash_message_holder > div[class^='ic-flash-']` | verified | Types: `ic-flash-success`, `-error`, `-warning`, `-info`. Built from an HTML template string in `rails-flash-notifications/jquery/helper.ts`, so **match by prefix, do not enumerate**. |
| `.flash-message-container` | verified | On every toast alongside the type class. Click is bound as dismiss. |
| `#flash_message_holder`, `#flash_screenreader_holder` | verified | Rendered **outside `#application`** so they survive open modals. |
| `#announcementWrapper > .ic-notification.ic-notification--admin-created.account_notification` | verified | Also carries `ic-notification--{question,information,warning,error,calendar}`. Inner structure: `.ic-notification__icon`, `.notification_account_content > .ic-notification__content > .ic-notification__message > h2.ic-notification__title + span.notification_message`, then `.ic-notification__actions`. |
| `.ic-notification .ic-notification__title.no_recent_messages` | verified | Empty state in Recent Activity. |
| `.ic-notification + .ic-dashboard-app` | verified | Adjacency rule for spacing under a banner. A skin restyling banners must keep element order. |

**Skin opportunities.** The four `ic-flash-*` types are the only semantic good-news/bad-news colour Canvas gives a student. Restyle them once and it lands consistently on every page. `#flash_message_holder` sits outside `#application` and above everything in z-order, which makes it the cleanest place to render Prepkin's own toasts so they stack correctly with Canvas's.

**Risks.** Toasts are injected at runtime, so observe the holder rather than querying it once. Account notifications inline a `<script>` defining `showGlobalAlert()` and use an `onClick` attribute, so removing or re-parenting the node breaks dismissal. Banner body is `user_content(safe_html: true)` from an admin, meaning arbitrary HTML. Never assume structure inside `span.notification_message`.

### 3.4 Dashboard, Card view — Tier 1

**Regions.** Sticky header strip `#dashboard_header_container.ic-Dashboard-header` (H1, observer picker, options kebab). Then `#DashboardCard_Container`, server-rendered as grey skeletons and then fully replaced by React. Then `div.ic-DashboardCard__box > div.ic-DashboardCard__box__container`, which despite the name is inline-block, not grid. Each card: a 146px colour or image hero, a white `header_content` block, a bottom row of four action icons. Right sidebar visible in this view.

| Selector | Conf. | Notes |
|---|---|---|
| `#DashboardCard_Container` | verified | Inline `display:block` when cards is the pageload view. React replaces its contents. |
| `.ic-DashboardCard__box > .ic-DashboardCard__box__container` | verified | `margin: -36px 0 0 -36px` negative gutters. `margin-left:0` below 548px. |
| `.ic-DashboardCard` | verified | `width:262px; display:inline-block; margin:36px 0 0 36px; border-radius:4px`. Full width below 548px. `data-testid="draggable-card"`. |
| `.ic-DashboardCard__header_hero` | verified | Inline `backgroundColor` = the student's course colour, and inline `opacity: hideColorOverlays ? 0 : 0.6`. When the course has an image this same class sits inside `.ic-DashboardCard__header_image`. |
| `.ic-DashboardCard__header_image` | verified | Only present when the teacher set a card image. `background-size:cover`. |
| `.ic-DashboardCard__header_content` | verified | `padding: 12px 18px 0`. A 0.125rem transparent border turns `var(--ic-brand-primary)` on focus. |
| `.ic-DashboardCard__header-title.ellipsis` | verified | Contains an inner `<span style="color: <course colour>">`. `data-testid="dashboard-card-title"`, `title` attribute holds the original course name. |
| `.ic-DashboardCard__header-subtitle`, `.ic-DashboardCard__header-term` | verified | Course code and term. `header-term` is reused for "Observing: name". |
| `nav.ic-DashboardCard__action-container` | verified | `display:flex; height:2.5rem`, kept even with zero links. |
| `a.ic-DashboardCard__action.announcements / .assignments / .discussions / .files` | verified | Second class is the tab's `css_class` from `Course#tabs_available`. Each is `flex: 0 0 25%`. |
| `.ic-DashboardCard__action-badge` | verified | 18px badge, `var(--ic-brand-primary)`, count capped at "99+". **The assignments badge is permanently 0** (Canvas bug CNVS-21227). |
| `button.ic-DashboardCard__header-button` | verified | Per-card kebab over `.ic-DashboardCard__header-button-bg`, whose inline `backgroundColor` is the course colour. |
| `.DashboardCardMenu__ColorPicker`, `__MovementItem`, `__MovementIcon` | verified | The only stable hooks inside the kebab popover. Tabs themselves are InstUI. |
| `.ic-DashboardCard__placeholder-svg .ic-DashboardCard__placeholder-animates` | verified | Grey skeletons before React mounts, count from a Rails cache of the last known card count. |
| `.unpublished_courses_redesign .ic-DashboardCard__box__header` | verified | Split layout turns one container into two `.ic-DashboardCard__box` sections. |
| `#dashboard_header_container.ic-Dashboard-header` | verified | `position:sticky; top:0; z-index:5`. Carries `data-props` JSON. |

**Skin opportunities.**
- The 146px hero carries zero information. Turn it into a real status surface: next due date, progress ring, or a per-course Prepkin surface. It will still read as a Canvas card.
- Override `.ic-DashboardCard__box__container` to `display:grid; grid-template-columns: repeat(auto-fill, minmax(262px, 1fr))`. One rule, no markup change, kills the ragged right edge.
- Swap `.ic-DashboardCard__action.files` (students almost never open Files) for Grades or Next assignment.
- Fill the permanently-zero assignments badge from the planner API. That is a fix, not decoration.
- The course colour is readable as an inline style on both the hero and the title span. Reuse it in Prepkin chrome so the page feels colour-coordinated to the student's own choices.

**Risks.** The grid is React, so observe `#DashboardCard_Container`. Cards are drag-reorderable (react-dnd); while dragging, `.ic-DashboardCard` gets inline `opacity: 0` and nodes move, so held element references go stale. `hideColorOverlays` is a per-student accessibility preference expressed as inline opacity, and a skin that paints the hero **must respect it** (see §5, where the shipped Prepkin rule does not).

### 3.5 Dashboard, List view (Planner) — Tier 1

**Regions.** `#dashboard-planner.StudentPlanner__Container` is the React root. `div.PlannerApp` is the app wrapper, with a responsive size class literally appended: `PlannerApp small` / `medium` / `large`. Per-day blocks, each with a heading and a secondary date line. Per-course groupings inside a day, with a coloured hero and an `<ol>` whose `borderColor` is the course colour. Then rows. Sticky header renders into `#dashboard-planner-header.CanvasPlanner__HeaderContainer`. Missing/late work lives in an Opportunities popover behind a bell. **No right sidebar in this view.**

| Selector | Conf. | Notes |
|---|---|---|
| `#dashboard-planner.StudentPlanner__Container` | verified | Server-rendered empty div, inline display set by `show_planner?`. |
| `div.PlannerApp` / `[data-testid="PlannerApp"]` | verified | `className` is `classnames('PlannerApp', responsiveSize)`. |
| `body.dashboard-is-planner` | verified | Added and removed by `DashboardHeader` when switching views. |
| `[data-testid="planner-item-raw"]` | verified | **Primary row hook.** Per verdict 2. |
| `[data-testid="planner-item-completed-checkbox"]`, `[data-testid="edit-event-button"]`, `[data-testid="feedback-comment"]`, `[data-testid="MissingAssignments-CourseName"]` | verified | Row internals. |
| `[data-testid="day"]`, `[data-testid="today-date"]`, `[data-testid="not-today"]` | verified | Day block and its date line. |
| `.Grouping-styles__items` | likely | The `<ol>` carrying an **inline `borderColor` equal to the course colour**. Read the inline value, do not assume the class survives. |
| `.PlannerItem-styles__root`, `__title`, `__due`, `__score`, `__completed`, `__missingItem`, `__badges`, `__feedback` | **disputed** | Recon says stable literals from `style.js`. Verdict 2 says the CSS-Modules generation is gone from `PlannerItem/index.tsx`. **Verdict wins: treat as opportunistic only.** |
| `#planner-app-fixed-element` | verified | Empty scroll/sticky sentinel. Do not remove or reposition. |
| `#dashboard-planner-header`, `#dashboard-planner-header-aux` | verified | Slots inside the dashboard header strip. |
| `.Opportunities-styles__*`, `.MissingAssignments-styles__*`, `.StickyButton-styles__*`, `.BadgeList-styles__*`, `.CompletedItemsFacade-styles__root` | likely | Same dispute as above. Opportunistic. |

**Skin opportunities.**
- Every row has identical weight today. Size and colour by urgency: today's items large and warm, next week small and quiet. That turns a flat list into a priority queue.
- Read the inline `borderColor` off the grouping `<ol>` and paint the whole day block, so a student can tell which class a row belongs to peripherally, without reading.
- "Load prior dates" is a `ShowOnFocusButton`, invisible to mouse users. Students literally cannot easily look back at what they missed. Surfacing it as a real visible control is a genuine fix.
- Opportunities (missing work) is hidden behind a bell most students never open. An always-visible count in the planner header is a real behaviour change. Note the Prepkin preamble bans urgency framing, so this must be an amber "still counts" chip, not a red alarm.

**Risks.** Each planner component injects its **own `<style>` element inline in the rendered output**, which lands later in the document than an extension stylesheet in `<head>`. Same specificity, later position, so it wins. A skin overriding planner rules must raise specificity or use `!important`. Infinite scroll loads and unloads days in both directions, so injected nodes must be re-applied on mutation. The right sidebar is force-hidden here, so any Prepkin element parked in `#right-side` vanishes when the student switches to List View.

### 3.6 Right sidebar (To Do / Coming Up / Recent Feedback) — Tier 1

**Regions.** `#right-side-wrapper > aside#right-side`, 288px (`$ic-sp * 24`) at >=992px, or >=1140px with the course nav open. Optional `.ic-sidebar-logo`. Student To Do (React) in `.Sidebar__TodoListContainer`. Legacy/teacher To Do as `ul.right-side-list.to-do-list`. Coming Up as `div.events_list.coming_up`. Recent Feedback as `div.events_list.recent_feedback`. An `a.more_link` expander.

| Selector | Conf. | Notes |
|---|---|---|
| `#right-side-wrapper.ic-app-main-content__secondary` | verified | 288px, `padding-left: 24px`, desktop breakpoint only. Hidden entirely in Planner view. |
| `aside#right-side` | verified | **On the dashboard this starts EMPTY** (or holds only `<div class="placeholder">`) and is filled by an XHR to `/dashboard-sidebar` dropped in with jQuery `.html()`. |
| `.Sidebar__TodoListContainer` | verified | React mount, targeted right after the sidebar HTML lands. A **second, later** mutation. |
| `[data-testid='ToDoSidebar'] > h2.todo-list-header` | verified | Heading of the React list. |
| `.ToDoSidebarItem`, `__Icon`, `__Info`, `__Title`, `__Close` | verified | Stable non-hashed classes, plus `data-testid="todo-sidebar-item-title"` / `-info` / `-close`. |
| `.events_list.coming_up ul.right-side-list.events > li.event` | verified | Row: `<a>` wrapping `<i class="icon-*">` plus `.event-details` with `b.event-details__title`, an optional context `<p>`, and a `<p>` holding "N points • due date". |
| `.events_list.recent_feedback li.event a.recent_feedback_icon` | verified | Row: `b.event-details__title.recent_feedback_title`, `p.event-details__context`, `<p><strong>grade</strong></p>`, and an optional comment truncated to 120 chars. |
| `ul.right-side-list.to-do-list li.todo .todo-badge` | verified | Legacy count badge. Students normally see the React list instead. |
| `a.more_link` | verified | "N more…" expander. Extra items are already in the DOM with inline `display:none`. |
| `.ic-sidebar-logo img.ic-sidebar-logo__image` | verified | Only when the account set `ic-brand-right-sidebar-logo`. |
| `a.event-list-view-calendar.icon-calendar-day` | verified | "View Calendar" link. |

**Skin opportunities.**
- **The single highest-value visual change on the whole dashboard**: the due-date string inside `li.event > a > .event-details > p` is what the student is scanning for, and it is plain grey text buried after a bullet. Parse it into a colour-coded urgency pill. Amber, not red, per the Prepkin tone rule.
- Coming Up truncates to 3 behind `a.more_link`. Auto-expand, or better, re-sort the visible three by urgency instead of Canvas's chronological order.
- Recent Feedback gives the grade and the teacher comment identical visual weight. Pull the grade into a large chip so "did I do OK?" is answerable at a glance. Keep it neutral in colour, never red.
- To Do and Coming Up overlap heavily. Merging them into one deduplicated "Next up" stack is an information-architecture win, not a repaint.
- There is a lot of vertical room below the three widgets. That is free space for a Prepkin surface that costs the student no content width.

**Risks.** Empty at page load and filled by XHR, then mutated a second time by React. A one-shot query on `DOMContentLoaded` will always find nothing. Which To Do list renders depends on the `render_both_to_do_lists` site-admin flag and on whether the user has any non-student enrolment: **a student who also TAs a course gets the legacy markup instead**. Below 992px the column stops being a sidebar and stacks under the content without being hidden, so handle the stacked case. Coming Up and Recent Feedback rows are Rails-cached (`recent_event_render3`, `recent_feedback_render3`), so surrounding HTML can be stale.

### 3.7 Course navigation menu — Tier 1

| Selector | Conf. | Notes |
|---|---|---|
| `ul#section-tabs` | verified | Built server-side as `content_tag(:ul, id: 'section-tabs')`. |
| `#section-tabs > li.section` | verified | `li_classes` is literally `%w[section]`. |
| `#section-tabs > li.section.section-hidden` | verified | Teacher/admin only. Students never render these. |
| `#section-tabs a.home, a.modules, a.assignments, a.grades, a.syllabus, a.pages, a.files, a.people, a.announcements, a.discussions, a.quizzes, a.settings, a.outcomes, a.rubrics, a.conferences, a.collaborations, a.course_paces` | verified | **THE stable per-tab hook.** `css_class` is a hardcoded English token from `Course#tabs_available` that is never translated. |
| `#section-tabs a.active`, `#section-tabs a[aria-current='page']` | verified | Both are emitted together. |
| `#modules-link`, `#grades-link` etc. | verified | **AVOID.** `a_id` is built from the **localized** label, so on a Spanish Canvas `#modules-link` becomes `#modulos-link`. |
| `nav[aria-label='Courses Navigation Menu']` | verified | Label is `I18n.t`. **Never match on it.** |
| `#left-side.ic-app-course-menu.ic-sticky-on.list-view` | verified | 192px (`$ic-sp*16`), **218px with the dyslexic font**. `.list-view` carries the nav typography and the `a.active` left-border rule, and is dropped when `@no_left_side_list_view` is set. Inline `display:none` when collapsed. |
| `#sticky-container.ic-sticky-frame` | verified | Inner sticky scroller. JS adds `.has-scrollbar` on overflow. |
| `body.course-menu-expanded`, `body.with-left-side` | verified | The reliable open/closed and existence hooks. Round-trips to the `collapse_course_nav` user setting. |
| `#section-tabs-header-subtitle.ellipsis` | verified | Enrollment-term name. Rendered **only** when the course is not in the default term, so most courses lack it. |
| `#section-tabs .nav-badge` | likely | Styled under `.list-view a.active`. Style verified, emitter not located. |
| `#section-tabs-header` | guess | Styled under an "oldskool compat" comment, no emitter in current ERB or helper. **Treat as absent.** |

**Skin opportunities.** A course shows 8-14 tabs of identical weight and students learn the menu by position, not by word. Give each known `css_class` its own leading icon and colour so the eye lands without reading. That is exactly what the Theme Editor cannot do. Canvas's active treatment is a 2px left border plus bold; a filled pill reads from across a room. Demote `a.outcomes`, `a.rubrics`, `a.collaborations`, `a.conferences`, `a.settings` below a divider and float `a.grades` and `a.modules` up. Server order is fixed, but CSS `order` on a flex `#section-tabs` re-ranks without touching the DOM. Hang a per-course accent off `#left-side` keyed to the course id, since Canvas gives the course nav no course colour at all.

**Risks.** External LTI tabs get an unpredictable per-institution `css_class`, so style them by exclusion. The nav is absent on `@content_only` pages and inside LTI iframes. `#left-side` is `display:none` until `body.course-menu-expanded`, and `toggleCourseNav.js` writes inline `display`, so a skin that sets `display` there will fight it and can strand the menu. The tab list is cached server-side for an hour.

### 3.8 Course home — Tier 1

Five completely different DOM structures behind one URL, chosen by `@course_home_view`: feed, wiki (front page), modules, assignments, syllabus. A skin must branch.

| Selector | Conf. | Notes |
|---|---|---|
| `#course_home_content` | verified | The main region for every variant. |
| `#wiki_page_show` | verified | React mount for the Front Page variant. |
| `#announcements_on_home_page` | verified | React mount, only when the course has `show_announcements_on_home_page?` and is not K5. |
| `#course_home_content ul.recent_activity` | verified | The "feed" variant renders the **identical** Recent Activity markup as the dashboard, with dedicated overrides for `#course_home_content .fake-link` and `.stream_header .links`. |
| `#right-side .events_list.recent_feedback` | verified | **On the course home page, Coming Up is rendered only for non-students.** Students get Recent Feedback only. |
| `a.btn.button-sidebar-wide` | verified | Full-width sidebar buttons. |
| `body.context-course_<id>` | verified | Layout appends `context-#{@context.asset_string}`. A stable per-course hook. |

**Skin opportunities.** Students who take one class use this page as their dashboard, and Canvas deliberately withholds Coming Up from them here. A course-scoped "due next" list is a real missing feature, not a repaint. `body.context-course_<id>` lets a skin give every course its own theme site-wide, matched to the dashcard colour the student already chose. Adding per-section progress to `#left-side` turns navigation into a progress map. When the variant is "feed", any Recent Activity work applies here for free.

**Risks.** Front Page and Modules variants are React mounts. Course home content can be arbitrary teacher-authored HTML, so never assume structure inside it. Under `body.course-menu-expanded` the desktop breakpoint moves 992px to 1140px, which changes when the right sidebar becomes a column.

### 3.9 Modules — Tier 1, and on a clock

**Regions.** `.header-bar` with `#expand_collapse_all`, then the module stack.

| Selector | Conf. | Notes |
|---|---|---|
| `.item-group-container#context_modules_sortable_container` | verified | Outer wrapper. |
| `#context_modules.ig-list` | verified | The stack. |
| `.context_module` | verified | One module. |
| `.ig-header.header`, `.ig-header-title.collapse_module_link` | verified | Module header and its collapse control. |
| `.ig-list.items.context_module_items` | verified | The item list inside a module. |
| `.context_module_item.indent_N` | verified | One item, with its indent level. |
| `.ig-row`, `.ig-row.with-completion-requirements`, `.ig-row.ig-published`, `.ig-row.student-view` | verified | The row and its state classes. |
| `.ig-handle`, `.ig-info`, `.ig-details`, `.ig-details__item`, `.due_date_display`, `.completion_requirement` | verified | Row internals. Due date and completion requirement are separately addressable. |

**Skin opportunities.** This is the #1 ranked complaint in Instructure's own community vote (741 votes for "reduce the cognitive load of modules"). Rows are visually identical whether they are a page, a quiz, an assignment or a link. Type-coded leading marks plus a real due-date treatment on `.due_date_display` is the highest-leverage single page in Canvas. `.completion_requirement` is already a discrete node, so a completion state per module is one rule away.

**Risks, stated plainly.** `context_modules_v2` is a full React rewrite sitting in master. In it, `ModuleItemStudent.tsx` is `<View>`/`<Flex>`/`<Text>` and **exactly one stable hook survives: `className="context_module_item"` on the outer View**. The same page also branches on the `instui_header` site-admin flag to swap the page header for `#context-modules-header-root`. One URL, three possible markups depending on flags. Build the Modules skin so that losing `.ig-row` degrades to a plain page, never a broken one.

### 3.10 Assignment detail (student) — Tier 1

Two entirely different pages behind one URL.

| Selector | Conf. | Notes |
|---|---|---|
| `#assignment_show`, `#assignment_head`, `#speed-grader-link-container` | verified | Legacy ERB path, 274 lines. |
| `[data-testid="assignments-2-student-view"]` | verified | Assignment Enhancements React page root. |
| `[data-testid="student-content-flex-container"]` | verified | Inner layout container. |
| `#assignment_external_tools` | verified | A plain stable id inside the React page. |
| `.user_content` | verified | Teacher-authored prose. Style typography and links only. Never assume internal structure. |

**Skin opportunities.** This is where a student reads the actual instructions, and where the current Prepkin skin does nothing at all (see §5). Prose measure, heading rhythm, link colour and a due/points header treatment are all reachable on the legacy path, and the React path gives a page root to scope to. The submission control is the most consequential button in Canvas and BetterCanvas has a documented failure where its dark mode hides it. Any Prepkin dark rule near the submit affordance needs an explicit contrast check.

### 3.11 Grades (student) — Tier 1

773 lines of semantic ERB. The safest heavy restyle on the list.

| Selector | Conf. | Notes |
|---|---|---|
| `#grades_summary` | verified | The table. |
| `#grade-summary-content`, `#student-grades-right-content`, `#student-grades-final` | verified | Page regions. |
| `.assignment_score`, `.grade`, `.possible.points_possible`, `.due`, `.details`, `.comment_count`, `.letter_grade`, `.group_weight`, `.min`, `.max`, `.median` | verified | Per-cell semantics. Everything a grade view needs is separately addressable. |
| `.react_pill_container` | verified | React islands mounted inside the legacy table. |

**Skin opportunities.** Every number a student cares about has its own class. A grade view that reads as a summary rather than a spreadsheet is pure CSS here. `.min` / `.max` / `.median` are the class distribution, which is the thing students actually scroll for. **Constraint check:** the Prepkin preamble bans performance framing, so trends stay neutral and drawn in the course colour, never red, and there are no "at risk" labels. A what-if calculator (BetterCanvas ships one, targeting `#grade-summary-content`) is possible but sits close to the "coins pay for finishing, never for grades" line and should stay a calculator, never a reward surface.

### 3.12 Global navigation trays — Tier 1

| Selector | Conf. | Notes |
|---|---|---|
| `.navigation-tray-container.courses-tray` (also `groups-`, `accounts-`, `profile-`, `history-`, `help-`) | verified | The modifier is built as `` `${type}-tray` ``. Stable. |
| `.tray-with-space-for-global-nav` | verified | Inner offset div, `margin-left: 54px` (84px expanded) at >=768px. |
| `.navigation-tray-container` | verified | `min-height: 100vh` at desktop. |
| `#global_nav_tray_container` | verified | The legacy React root, an empty div at the end of `#header`. |
| `[class*='-tray'] a[href^='/courses/']` | likely | Course links. Attribute matching beats any class here. |

**Skin opportunities.** This is how most students actually change class. Prefixing each row with the course's own dashboard colour (readable from `ENV.PREFERENCES.custom_colors`) makes the tray match the cards and removes a hunt. The wrapper is stable enough to safely append a footer ("Next due: X in 2 days") without touching a hashed class. Trays are the only full-height surface in Canvas chrome, so a Prepkin side panel here steals no content width.

**Risks.** Everything inside the wrapper is InstUI with hashed names. Trays are `React.lazy`, so the DOM does not exist until first open: use a `MutationObserver` on the portal, never a one-shot query. The tray mounts into a portal **outside `#application`**, so selectors rooted at `#application` will not match.

### 3.13 Assignments index — Tier 2

| Selector | Conf. | Notes |
|---|---|---|
| `.assignment_group`, `.ig-header`, `.ig-header-title` | verified | Group and its header. |
| `.collectionViewItems.ig-list.draggable`, `.assignment-list` | verified | The list. |
| `.ig-row`, `.ig-info`, `.ig-details` | verified | Same row grammar as Modules. |
| `.ig-details__item.assignment-date-due`, `.ig-details__item.js-score`, `.ig-details__item.modules` | verified | Due date, score, and module membership as discrete nodes. |
| `.item-group-condensed` | verified | Condensed layout wrapper. |

**Skin opportunity.** `.ig-row` is shared with Modules, so one ruleset covers two Tier 1/2 pages. `.assignment-date-due` and `.js-score` are already separate, which means the urgency-pill and grade-chip treatments from the sidebar port here directly.

**Risk.** Rendered by Backbone/Handlebars at runtime, not in the server HTML. Observe, do not query once.

### 3.14 Inbox — Tier 2 (upgraded by verdict 2)

Mounts into `#content` via `getElementById('content')`, so the legacy skeleton wraps it.

| Selector | Conf. | Notes |
|---|---|---|
| `[data-testid="conversation"]` | verified | One conversation row. |
| `[data-testid="conversationListItem-Item"]`, `[data-testid="conversationListItem-Checkbox"]` | verified | Row internals. |
| `[data-testid="unread-badge"]`, `[data-testid="read-badge"]` | verified | Read state. |
| `[data-testid="last-message-content"]` | verified | Preview text. |
| `[data-testid="visible-starred"]`, `[data-testid="visible-not-starred"]` | verified | Star state. |
| `[data-testid^="open-conversation-for-"]` | verified | Templated. **Prefix-match.** |
| `[data-testid="inbox-settings-in-header"]` | verified | Header. |

`ConversationListItem.tsx` contains **zero** `className` attributes. Every hook is a testid. Style additively: set background, spacing and type on the testid nodes rather than fighting InstUI's own rules.

### 3.15 Discussions — Tier 2 (upgraded by verdict 2)

| Selector | Conf. | Notes |
|---|---|---|
| `[data-testid="discussion-topic-container"]` | verified | Thread root. |
| `[data-testid="highlight-container"]` | verified | Outer highlight wrapper. |
| `[data-testid="discussion-topic-reply"]` | verified | Reply affordance. |
| `[data-testid="discussion-topic-closed-for-comments"]` | verified | Closed state. |
| `.discussion-topic-reply-button` | verified | A **plain, non-hashed legacy class inside React markup**. Opportunistic but real. |

### 3.16 Quizzes (classic) — Tier 2

`#quiz_show`, `#quiz-publish-link`, from `quizzes/quizzes/show.html.erb` (391 lines, `verified`). Fully legacy and fully skinnable. **This is not New Quizzes.** New Quizzes is an LTI iframe and is Tier 4. A student in a New Quizzes exam sees stock white Canvas inside a dark skin, and a skin must not hide that fact from the reader.

### 3.17 Calendar — Tier 2

FullCalendar plus a React and jQuery hybrid. `.fc-*` classes are FullCalendar's own public API and are stable across Canvas versions. The Calendar drives itself off `window.location.hash` via `dataFromDocumentHash` / `updateFragment` and is **not** in the react-router table, so a `hashchange` listener is required for anything JS-driven here. Event colour comes from the same `ENV.PREFERENCES.custom_colors` map as the dashcards.

### 3.18 Dashboard, Recent Activity — Tier 2

| Selector | Conf. | Notes |
|---|---|---|
| `#dashboard-activity.ic-Dashboard-Activity` | verified | Server-rendered **empty** with only an HTML comment. Filled by XHR to `/dashboard/stream_items`, cached in `loadedViews` so it fetches once. |
| `ul.recent_activity.unstyled_list > li.stream-category` | verified | Second class is the underscored category: `stream-announcement`, `stream-conversation`, `stream-assignment`, `stream-discussion_topic`, `stream-assessment_request`. `data-category` holds the CamelCase original. |
| `div.stream_header` | verified | Clickable category row. Contains `.image-block-image > i.icon-*` and `.image-block-content > .title + strong.unread-count + .links`. |
| `.recent_activity > li .unread-count` | verified | 20px round pill, `var(--ic-brand-primary)`, absolutely positioned. |
| `a.toggle-details[aria-controls='details_container']` | verified | Expand control. |
| `div.details_container > table.stream-details` | verified | The item table. `thead` is screenreader-only. |
| `table.stream-details a.content_summary` | verified | `<span class="fake-link">course</span> + <strong>state</strong> + summary`. |
| `table.stream-details td .unread` | verified | 10px dot, `var(--ic-brand-primary)`. |
| `a.close.ignore-item[data-url][data-remove='tr']` | verified | Dismiss X. |
| `td.date` | verified | `friendly_datetime`, a `<span>` with a `title` holding the full timestamp. |
| `.stream-activity` | verified **absent** | **Does not exist in current Canvas.** Any skin rule on it is dead code. |

**Skin opportunities.** Every category starts collapsed, so the student sees five grey headers and no content. Auto-expanding the categories that have unread items is one rule for a large usability gain. `td.date` is plain grey at the far right of a wide table; moving it inline or converting to relative time matches how people read a feed. This is the safest dashboard view to restyle heavily.

**Risk.** The same partial renders on the course home page and in groups, so a global rule here also hits those. Categories are Rails-cached for 15 minutes.

### 3.19 Pages, Syllabus, Courses index — Tier 2, brief

- **Pages / wiki, Syllabus.** Backbone-rendered shells around `.user_content`. Style the shell chrome and the prose typography. Never assume structure inside teacher HTML.
- **Courses index** (`/courses`). `#my_courses_table.course-list-table`, `#past_enrollments_table`, `#future_enrollments_table` (all `verified`), with per-column classes `course-list-star-column`, `-course-title-column`, `-nickname-column`, `-term-column`, `-enrolled-as-column`, `-published-column` from the `sortable_th` helper. `.table-overflow-container` wraps each. **Scope every rule by table id**, because three near-identical tables sit on one page. An accessibility column exists in code but is force-disabled, so use classes and never `nth-child`. `#start_new_course` is duplicated on the dashboard sidebar, so never scope by that id alone. Opportunity: the star column silently decides which courses become dashboard cards and nothing on the page says so. Labelling it fixes a genuinely confusing Canvas behaviour in one line.

### 3.20 Mobile header — Tier 2

`#mobile-header` (`verified`), `display:flex`, `background-color: var(--ic-brand-global-nav-bgd)`, descendants coloured `var(--ic-brand-global-nav-menu-item__text-color)`. `.mobile-header-hamburger` (both `touchstart` and `click` listeners). `#mobileHeaderInboxUnreadBadge` (inline `display:none` until React sets it). `.mobile-header-title.expandable`. `#mobileContextNavContainer[aria-expanded='true']` animates `max-height` over 1.5s. `#mobileHeaderArrowIcon` has its className swapped in JS.

The bar is ~56px and mostly `.mobile-header-space` divs, so a compact chip fits without fighting anything, and the context drawer already animates so an injected panel inherits the motion for free. `#mobile-header` is `display:none` at >=768px, so anything shown on desktop needs a mobile-only duplicate. `MobileNavigation` binds `touchstart` with `preventDefault` on the hamburger, so a skin adding its own listener there can break the native open.

---

## 4. The technical floor

### 4.1 The target ladder, hardest to softest

**Tier A. Ride the brand system.** Override `--ic-brand-*` on `:root`. Zero selector risk, and it is exactly how a school admin already themes Canvas, so the skin degrades gracefully instead of fighting an existing theme.

**Tier B. The legacy skeleton.** These are plain server-rendered markup, stable for years, and they wrap **every** React page: `#application.ic-app`, `#wrapper.ic-Layout-wrapper`, `#main.ic-Layout-columns`, `#left-side.ic-app-course-menu.ic-sticky-on`, `#not_right_side.ic-app-main-content`, `#content-wrapper.ic-Layout-contentWrapper`, `#content.ic-Layout-contentMain[role=main]`, `#right-side-wrapper.ic-app-main-content__secondary`, `.ic-app-nav-toggle-and-crumbs`, `.ic-app-crumbs`, `.ic-Layout-watermark`, `#sticky-container.ic-sticky-frame`, `#react-router-portals`, `#mobile-header`. All `verified`.

Page and course scoping comes from body classes, all `verified` in `application.html.erb`: `with-left-side`, `course-menu-expanded`, `with-right-side`, `padless-content`, `with-fixed-bottom`, `primary-nav-expanded`, `primary-nav-transitions`, `full-width`, `content-only`, `no-headers`, `hide-global-nav`, `is-masquerading-or-student-view`, `Underline-All-Links__enabled`, `dashboard-is-planner`, `k5-*`, the `get_active_tab` output, and `context-<asset_string>` (for example `context-course_12345`).

**Tier C. Canvas's own semantic classes.** `ic-*`, `ig-*`, `item-group-*`, `.ic-DashboardCard*`, `.context_module_items`, `#breadcrumbs`, `#section-tabs a.<css_class>`. Stable across releases and covering a great deal of React-rendered markup, because Canvas React frequently hand-writes them. **Most of the visible skin should live here.**

**Tier D. `data-testid` inside React regions.** The only way into Inbox, Discussions, Assignment Enhancements and Planner internals. Prefix-match where templated (`[data-testid^="open-conversation-for-"]`). Also useful: InstUI's `Position` exposes real attributes `data-position`, `data-position-target`, `data-position-content` on popovers, menus and tooltips.

**Tier E. Never.** Any selector containing `css-`. Not a full hash (`.css-1a2b3c-link`), and not a label-anchored partial (`[class*="-view--flex"]`) either. The full hash is a content hash of the resolved styles, so it changes on every InstUI bump, on every Canvas deploy, and potentially **between two schools with different brand configs**. The label partial matches every InstUI `View` on the page and would repaint half the UI. BetterCanvas ships 67 InstUI production hashes plus 12 older Emotion names, in two different hash formats. That is precisely why "dark mode broke again" is its top recurring complaint.

### 4.2 The `--ic-brand-*` strategy

There are two pipelines that share names and share nothing else.

**Pipeline 1, CSS. Real, and yours.** `lib/brandable_css.rb#all_brand_variable_values_as_css` emits `":root { --#{k}: #{v}; }"` and Canvas's own SCSS reads them at runtime, not compile time: `$ic-font-color-dark: var(--ic-brand-font-color-dark)`, `$linkColor: var(--ic-link-color)`, `$ic-course-sidenav_list-item--active-font-color: var(--ic-brand-primary)`. Measured on a live production build (Dartmouth `common.css`, 401 KB): ~230 `var(--ic-*)` references across 30 distinct variables. `_ic_app_header.scss` alone has ~25. `_SideNav.scss`, the newer InstUI-era nav, still has 11, because Canvas patches its own InstUI nav with SCSS.

**Pipeline 2, JavaScript. Real, and not yours.** `all_brand_variable_values_as_js` emits `CANVAS_ACTIVE_BRAND_VARIABLES = {...}` as a separate `<script>`. `ui/shared/react/index.tsx` reads it and passes it to `getTheme`, which spreads the keys as **top-level JS theme properties**. Component themes then consume them as JS values and run `darken()` and `alpha()` on them, which mathematically requires a parseable colour string. `@instructure/ui-themes@11.7.5` contains 0 occurrences of `var(--` and 44 of `ic-brand`. `ui-buttons` 0 and 31. `ui-link` 0 and 3. **InstUI ships no CSS custom properties at all.**

Only **14** brand names reach InstUI, and they reach it through JS. The rest are CSS-only.

**Practical rules.**
1. Write the overrides as `!important` on `:root`. Custom properties honour `!important`, and Canvas's own brand stylesheet also sets them on `:root` at equal specificity, so injection order alone is not safe. (`likely`, not verified against a spec.)
2. **Read `window.getComputedStyle(document.documentElement)` and derive from the school's palette rather than replacing it wholesale.** Institutional identity should survive the skin. This is also the difference between a skin a district tolerates and one a district blocks.
3. Enumerate the live `:root` at build time. The recon reports and the verdict disagree on whether `brandable_variables.json` declares 31 or 45 admin-editable variables. The verdict wins on the number, but the only number that matters is what the target instance actually emits, which includes Canvas's 14 computed derivatives.
4. Canvas computes exactly these derivatives (`verified`): `-primary-darkened-5/-10/-15`, `-primary-lightened-5/-10/-15`, `-button--primary-bgd-darkened-5/-15`, `-button--secondary-bgd-darkened-5/-15`, `-font-color-dark-lightened-15/-28`, `-link-color-darkened-10`, `-link-color-lightened-10`. **There is no `-lightened-30`.** BetterCanvas references `--ic-brand-font-color-dark-lightened-30` six times and all six declarations are dead. Do not copy their names.
5. **Do not attempt the MAIN-world `CANVAS_ACTIVE_BRAND_VARIABLES` patch.** Verdict 1 rules it out of scope: isolated worlds, page CSP, and a race against React's first render.

**What stays unskinned, and say so in the product.** Everything InstUI paints through the JS theme: InstUI Buttons, Links, Tables, Trays, Modals, Selects, Alerts. Concretely, Files v2 will not recolour at all, and any page header behind `instui_header` will not either. Expect this surface to grow: master already ships `context_modules_v2`, `files_v2`, `learning_mastery_v2`, `new_login`, `widget_dashboard` as rewrites of pages that are still legacy ERB for most schools.

### 4.3 SPA behaviour and the observer requirement

Canvas is **not** a single SPA. It is Rails multi-page with React islands plus one growing react-router surface. Every navigation between top-level areas (dashboard to course to assignment to grades to inbox) is a **real document load** that re-runs `ui/boot/index.js`.

The react-router table (`ui/boot/initializers/router.tsx`, mounted into `#react-router-portals`) covers, in full: `/users/:userId/messages[/:messageId]`, `/login/otp`, `/groups/:groupId/*`, `/users/:userId/masquerade`, `/users/:userId/admin_merge`, `/users/:userId`, `/accounts/:accountId/grading_standards`, `/accounts/site_admin/release_notes`, `/accounts/:accountId/admin_tools`, `/accounts/:accountId/settings/*`, `/accounts/:accountId/users/:userId`, `/accounts/:accountId/authentication_providers`, `/accounts`, `/courses/:courseId/settings/*`, `/courses/:courseId/search`, `/accounts/:accountId/sub_accounts`, `/accounts/:accountId/reports`, `/accounts/:accountId/statistics`, `/profile/qr_mobile_login`, `/search/all_courses`, `/courses/:courseId/assignments/new`, `/courses/:courseId/assignments/:assignmentId/edit`.

Note what is **absent**: Inbox, Planner, Gradebook, SpeedGrader, Modules. Those are React islands that mutate the DOM in place and change `location.hash` or call `history.pushState` **without** react-router. The Calendar drives itself entirely off `window.location.hash`.

**A skin needs all four mechanisms, because no single one covers Canvas.**

1. **Static CSS via `content_scripts.css`.** Injected before DOM construction, so no flash on full page loads. This is the primary mechanism and it needs no observer at all. Everything expressible in CSS belongs here.
2. **A debounced `MutationObserver` on `document.documentElement`** with `{childList: true, subtree: true}`, ~300ms. Only for things that must touch nodes (adding classes, reading inline colours). Canvas uses exactly this pattern itself in `setupCSP.js`. **Do not do what BetterCanvas does**: two undebounced whole-document observers that re-run the full pipeline on every mutation of a React app, with no route detection and no `requestAnimationFrame`. That is the documented cause of its "everything got slow" reviews.
3. **The `canvasReadyStateChange` event.** Canvas fires it on `window` with `detail === 'capabilities'` and sets `window.canvasReadyState`. A genuine, source-verified "Canvas has booted" signal, better than `DOMContentLoaded`. React mounts well after `document.readyState` is complete.
4. **History patching**: monkey-patch `pushState`/`replaceState`, plus `popstate` and `hashchange`. Required for the react-router surfaces and the hash-driven Calendar. No Canvas-specific hook exists for this (`likely`, standard technique).

Do not poll.

### 4.4 CSP, fonts, and iframes

**CSP.** Canvas's only always-on CSP response header is `frame-ancestors`. Measured live on 8 production instances, 8 of 8. **There is no `font-src` problem and no `style-src` problem for injected CSS.** Web fonts from an external host will load.

Separately, Canvas has an **account-level** CSP feature (`ENV.csp` drives `ui/boot/initializers/setupCSP.js`, which attaches a `securitypolicyviolation` listener and stamps `csp` on attachment iframes). It is per-account and off by default. Its only practical consequence for a skin is the one in §4.2: MAIN-world script injection is CSP-gated and therefore unreliable, which is one of the reasons that path is out of scope.

**Font recommendation, despite the above.** Ship a system stack and no web font. The current Prepkin panel already does this, with the reason in a code comment: it "falls back warm rather than fetching fonts from inside someone's LMS." That is the right call. A network request from inside a school's LMS to a font CDN is a support ticket and a privacy question waiting to happen, and it is one of the three things (alongside hotlinked Pinterest images and `<all_urls>` permissions) that got BetterCampus blocked by a district. See §6.

**Cross-origin iframes, the complete unreachable list.** Every LTI tool renders as `.tool_content_wrapper > iframe#tool_content.tool_launch` pointing at a third-party origin (`verified`, `app/views/lti/_launch_iframe.html.erb`).

| Surface | Origin | Reachable? |
|---|---|---|
| New Quizzes | Instructure quiz-lti host | No |
| Canvas Studio | Instructure Studio host | No |
| Canvadocs document preview | `canvadocs.instructure.com` | No |
| Proctorio / LockDown / Respondus wrappers | vendor | No |
| Publisher tools (Pearson, McGraw-Hill, Cengage) | vendor | No |
| Google Assignments / Office 365 LTI | Google / Microsoft | No |
| **Same-origin** embedded frames | the Canvas host | Yes, via `frame.contentDocument` |

Plan for the seam. Either accept a white rectangle in a dark skin, or suppress the skin on routes known to launch a tool. Do not pretend the seam does not exist.

### 4.5 Course colour preservation

Course colours are the student's own choices and the primary way they navigate. They come from Canvas, never from the skin.

- **Source of truth:** `ENV.PREFERENCES.custom_colors`, an object keyed by asset string: `{ "course_1234": "#0078bf", "group_88": "#e5326e" }` (`verified`). Read at boot by `DashboardCardBackgroundStore.ts`.
- **Where they appear as inline styles** (read these, do not recompute): `.ic-DashboardCard__header_hero` `backgroundColor`; the inner `<span>` inside `.ic-DashboardCard__header-title` `color`; `.ic-DashboardCard__header-button-bg` `backgroundColor`; the planner grouping `<ol>` `borderColor`; FullCalendar event colours.
- **The overlay preference.** `ENV.PREFERENCES.hide_dashcard_color_overlays` (`verified`). When true, Canvas sets the hero to `opacity: 0` and the header-button backing to `opacity: 1`. **When overlays are hidden, the course colour on the title span is the only remaining colour cue on the card.** A skin that recolours that title destroys it. A skin that forces the hero visible overrides the preference.

### 4.6 Accessibility settings a skin must not fight

**High Contrast is a compiled CSS variant, not a body class.** `css_variant` produces `new_styles_high_contrast_*` bundles, and `config/brandable_css.yml` lists all 8 variants. There is no `body.high-contrast` to hook.

Detect all three ways:
```js
window.ENV?.use_high_contrast === true
document.querySelector('link[href*="new_styles_high_contrast"]')
document.querySelector('link[href*="variables-high_contrast"]')
```

**Copy Canvas's own behaviour.** `application_helper.rb#active_brand_config` **throws away the institution's entire brand config** under high contrast, and `BrandableCSS.high_contrast_overrides` forces `ic-brand-primary: #0A5A9E` and `ic-link-color: #09508C`. On the React side, `getTheme` ignores `brandVariables` completely and returns `canvasHighContrastTheme`, whose own description says it meets WCAG 2.1 AAA for colour contrast.

**Rule: when `ENV.use_high_contrast` is true, the skin disables itself entirely.** Anything less contradicts Canvas's own accessibility contract.

**OpenDyslexic.** `ENV.use_dyslexic_font` is set **only** when the user can see the feature flag and is not on a mobile device, so the key may be **absent rather than false**. Check `=== true`. When it is on: do not set `font-family` anywhere (font size, weight and line-height are still fine and still helpful), and remember the layout constants change. The rail goes 84px to **104px** and the course menu goes 192px to **218px**. Any skin with hardcoded 54/84/192 offsets breaks for those students.

**Reduced motion.** Canvas does not honour `prefers-reduced-motion` and neither does InstUI. Measured: 0 occurrences in Dartmouth's 401 KB `common.css` against 40 `transition:` and 6 `animation:` declarations, and 0 occurrences across all of instructure-ui master. InstUI's only motion escape hatch zeroes durations when `NODE_ENV === 'test'`.

**Rule: any motion the skin adds is motion Canvas never had. The skin owns the entire `@media (prefers-reduced-motion: reduce)` block. There is no platform behaviour to inherit.**

**Other preferences worth respecting:** `ENV.disable_celebrations` (`prefers_no_celebrations?`), `ENV.disable_keyboard_shortcuts`, `ENV.SETTINGS.collapse_global_nav`, and the `Underline-All-Links__enabled` body class.

### 4.7 The `data-testid` caveat, stated once

`data-testid` is a real, durable hook and it is the only way into React internals. It is **not** a published API contract. Instructure renames testids when they refactor their own Jest specs. They churn far less than Emotion hashes but they do churn. Two operational consequences:

1. **Write every rule so a missed selector is a no-op, never a broken layout.** Additive styling, not overrides of InstUI's own rules.
2. **Keep every Canvas selector in one file** with the page and testid noted, and add a smoke check that asserts the load-bearing selectors still match. Run it against each Canvas release. Assume markup churn is the default state of this codebase, not an exception.

---

## 5. What Prepkin already has

### 5.1 The `--pk-*` token system

27 tokens, declared in exactly two places: `extension/skin.css:14` (light) and `:47` (dark). Both blocks are matched by the same double selector, `.prepkin-cards, #prepkin-buddy`.

| Token | Light | Dark | Controls |
|---|---|---|---|
| `--pk-page` | `#f0eee9` | `#1b1f1b` | Canvas page background; border ring on the count badge |
| `--pk-card` | `#ffffff` | `#242923` | Panel shell, tab, bubble, timer, sheet, dashboard card face, every dark-swept Canvas surface |
| `--pk-inset` | `#f4f1ea` | `#2c322b` | Header zone, filter pills off, week strip, grades block, context, empty row |
| `--pk-row` | `#ffffff` | `#262c26` | Task rows only |
| `--pk-line` | `#eae5da` | `#3b423a` | 1px inset rings; dark-sweep `border-color` |
| `--pk-line-soft` | `#e5dfd2` | `#3b423a` | Softer rings on inputs and rules |
| `--pk-text` | `#33291f` | `#f4f1ea` | Primary text; dark-sweep headings, labels, paragraphs, cells |
| `--pk-text-mid` | `#5e5142` | `#d3cabb` | Only the what-if answer subline |
| `--pk-text-2` | `#8a7a66` | `#bdb2a0` | Secondary text, labels, points, chevrons, card subtitle and term |
| `--pk-text-3` | `#a8977f` | `#8f887b` | Footnotes; completed task title |
| `--pk-mint` | `#51cfa0` | **not overridden** | Brand accent: primary button fill, progress fill, count badge, wearing ring |
| `--pk-mint-edge` | `#35a87d` | **not overridden** | The 3px pressable bottom edge |
| `--pk-soft` | `#b1edd4` | **not overridden** | Soft button variant on overdue rows |
| `--pk-soft-edge` | `#8ad1b4` | **not overridden** | Soft button edge |
| `--pk-green` | `#2e7d57` | `#7fddb8` | **Canvas link colour**, back arrow, done chip, active filter, GPA number |
| `--pk-ink` | `#101820` | **not overridden** | The one dark chip: coin pill background |
| `--pk-on-ink` | `#fff7e8` | `#f4f1ea` | Text on that chip |
| `--pk-coin` | `#de9a22` | `#ecb35c` | Coin disc; overdue dot ring |
| `--pk-coin-ring` | `#fff9ec` | `#101820` | Inner ring of the coin disc |
| `--pk-amber-text` | `#a0722b` | `#ecb35c` | Overdue copy, reward chip, worried state |
| `--pk-circle` | `#c9bca4` | `#5a6156` | Empty task-row dot ring |
| `--pk-track` | `#e5dfd2` | `#3b423a` | Progress troughs; empty week dots |
| `--pk-mint-tint` | `rgba(81,207,160,.12)` | `.1` | Hero card fill, result fill |
| `--pk-mint-tint-strong` | `rgba(81,207,160,.16)` | `.18` | Active pill, active minutes, active target |
| `--pk-mint-border` | `rgba(81,207,160,.35)` | `.3` | Ring on hero card, result, active minutes |
| `--pk-amber-tint` | `rgba(222,154,34,.14)` | `rgba(236,179,92,.14)` | Reward chip fill, amber filter pill |
| `--pk-shadow` | `rgba(51,41,31,.22)` | `rgba(0,0,0,.45)` | Every drop shadow |

Plus `color-scheme: dark` in the dark block.

### 5.2 Which Canvas pages the skin actually reaches today

**Tier 1 of the current skin, every page, colour only.** `.prepkin-cards` paints `body`, `#application`, `#wrapper`, `#main`, `.ic-Layout-contentWrapper`, `.ic-Layout-columns`, `#content`, `#right-side-wrapper`, `#right-side` with `--pk-page` and `--pk-text`, and recolours `a:not(.btn):not(.Button)` to `--pk-green`. That is the entire cross-page contribution. A cream wash and green links. No card, no radius, no type, no spacing.

**Tier 2 of the current skin, dashboard only.** Nine rules on `.ic-DashboardCard*`: 16px radius, inset 1px ring, overflow hidden, `translateY(-3px)` hover lift, hero collapsed to an 8px strip, title bolded to 800 in `--pk-text`, subtitle and term in `--pk-text-2`. **This is the entire before/after of the product.**

**Tier 3 of the current skin, dark sweep.** A broad structural repaint that incidentally touches Modules, the Assignments index, the Planner and the course nav, but only as "paint it dark". No Prepkin visual language reaches any of them.

| Canvas page | Cards on | Dark on |
|---|---|---|
| Dashboard, card view | Real skin | Yes |
| Dashboard, list view | Background only | One rule, probably dead (see below) |
| Course home / Modules | Background only | `.context_module`, `.ig-list`, `.ig-row` darkened |
| Assignments index | Background only | `.item-group-condensed` darkened |
| **Assignment show page** | Background only | **Nothing.** `.user_content` prose stays white on white |
| **Quizzes** | Background only | **Nothing** |
| **Grades** | Background only | Only via the generic `table` rule |
| **Discussions, Inbox, Files, Pages, Calendar, Syllabus, People** | Background only | **Nothing** |
| Global nav | Untouched, deliberate | Untouched |
| Login, iframes | Excluded on purpose | Excluded on purpose |

One designed page, a colour wash everywhere, and a dark sweep covering maybe five page types structurally and a dozen not at all.

### 5.3 The honest gap list

**Bugs, in severity order.**

1. **`.prepkin-cards .ic-DashboardCard__header_hero { opacity: 1 !important }` (skin.css:140) overrides an accessibility preference.** When the student has turned Color Overlay off, Canvas sets the hero to inline `opacity: 0`. The `!important` beats the inline style and forces the colour strip back. Fix: condition on `ENV.PREFERENCES.hide_dashcard_color_overlays`, or drop the `!important` on opacity and keep it only on height.
2. **`.prepkin-cards .ic-DashboardCard__header-title span { color: var(--pk-text) !important }` (skin.css:142) destroys the last course-colour cue.** With overlays hidden, that span is the *only* remaining colour signal on the card. Fix: leave the span colour alone, or restore it as a swatch elsewhere on the card.
3. **Dark mode breaks when "Warm theme & cards" is off.** Tokens are declared only on `.prepkin-cards` and `#prepkin-buddy`, but `applySkin` toggles `prepkin-dark` and `prepkin-cards` independently, and the popup exposes both. With `cards: false, dark: true`, `var(--pk-text)` resolves to nothing, the value is invalid at computed-value time, and the whole dark sweep collapses. Fix: declare tokens on `.prepkin-dark` too, or gate the dark toggle on cards.
4. **`.prepkin-dark .PlannerItem-styles__container` (skin.css:110) almost certainly matches nothing.** No recon report lists `__container` among the verified planner classes (`__root`, `__title`, `__type`, `__due`, `__score`, `__badges`, and so on), and verdict 2 says the CSS-Modules generation is gone from that component entirely. Fix: switch to `[data-testid="planner-item-raw"]`.
5. **No high-contrast detection anywhere.** Grep for `use_high_contrast` returns zero hits across the extension. A student with High Contrast on gets the Prepkin skin painted over a WCAG AAA variant that Canvas deliberately stripped of branding. This is the most serious accessibility gap in the extension.
6. **`--pk-ink: #101820` never inverts, so the coin chip is near-invisible on the `#1b1f1b` dark page.** The V4 brief flagged this and it was never fixed.
7. **`.prepkin-cards .ic-DashboardCard:hover { transform: translateY(-3px) }` is motion added to Canvas with no reduced-motion guard.** The two existing `prefers-reduced-motion` blocks cover only `#prepkin-buddy` internals.
8. **Night Shift forces dark on but the popup checkbox does not reflect it**, so the toggle and the actual state can visibly disagree.
9. **Look tints never apply in dark mode** (`if (!s.cards || dark) return`), so all six looks render an identical page in dark and only the accessory differs.
10. **Look tints never reach the panel.** They are set inline on `<html>`, but `#prepkin-buddy` re-declares all 27 tokens in its own matched rule, and a declared value beats an inherited one. Wearing Woodland turns Canvas green while the panel stays mint.
11. **`.ic-Dashboard-header__title` (skin.css:95) is unverified.** The recon verified `.ic-Dashboard-header`, `__layout` and `__actions` but not `__title`. Check it against a live DOM.

**Architecture gaps.**

- **No `MutationObserver`, no `webNavigation`, no history patching, no `popstate` listener anywhere in the repo.** Registration is programmatic at `runAt: 'document_end'`, once per document load, and the only re-render trigger is `chrome.storage.onChanged`, which fires on **data** change, never on **page** change. The CSS keeps working because it lives on `<html>` classes, but anything that needs to *see* the page is blind after the first paint. Per §4.3 this is the single missing piece.
- **The manifest has no `webNavigation` permission**, so option 3 in the audit's list of seams needs a manifest change.
- **`SKIN_DEFAULTS` is duplicated** in `popup.js:148` and `content.js:7`.
- **The popup exposes no Looks UI**, despite V4 Prompt 2 asking for one. Looks shipped inside the panel instead.

**Content gaps.** Nothing reaches: assignment detail prose, Grades, Quizzes, Discussions, Inbox, Files, Pages, Calendar, Syllabus, People. The Modules page, the highest-complaint page in Canvas, gets a background colour and nothing else.

**One live contradiction to resolve before any new art ships.** The design preamble says the mascot is **Sprout, a finished character rendered from real assets**, six coats, never sketched or approximated. The extension still ships **the slime** (`slime.js`), and `looks.js` carries a header comment calling its four accessories "PROVISIONAL ART" that "need George's sign-off." `CLAUDE-DESIGN-QUEUE.md` still lists "the extension Look accessories" under **"Needs George before any of these ship."** They are unapproved. Any new mascot-adjacent art in a Canvas skin inherits that gate, and memory records that animations additionally need a GIF sign-off.

---

## 6. BetterCanvas: the bar

### 6.1 What it is now

It renamed to **BetterCampus**, rewrote itself as an AI study suite, went closed-source, and put themes behind **$19/month or $119/year**. The Chrome listing shows 9.8.6, updated 2026-08-28, 4.7 stars from 4.3K ratings, 2M+ users. Its own marketing claims "5/5, 8.5k reviews" which contradicts its own store page, so treat the marketing number as inflated. The public GitHub source is four major versions stale (last code commit 2024-11-19, v5.12.6) while the listing still advertises "open-source." `bettercanvas.io` no longer resolves. The Firefox build is stuck on the 2024 code and reviewers say so. It also acquired **Tasks for Canvas** (800K users) and is winding it down, which cost users their multi-hundred-day streaks and generated a second wave of anger.

**Permission escalation, verified from change history:** 5.12.6 had `permissions: ["storage"]` only. 6.0.0 added host permission `*://*/*`. 7.0.0 added `tabs`. 8.0.1 added `<all_urls>`. Content scripts now also match `calendar.google.com`, `outlook.*`, and `canvadocs.instructure.com`. chrome-stats rates it **High risk impact / Moderate risk likelihood** and flags an abnormal rating trend.

### 6.2 What it does badly, precisely

| Weakness | Evidence | The opening |
|---|---|---|
| **79 hashed selectors** (67 InstUI production hashes plus 12 older Emotion names) out of 511 class selectors in the dark blob, shipped in **two different hash formats** because the scheme changed under them | read from `content.js` v5.12.6 | Every one of those breaks on a Canvas deploy. This is the direct cause of the #1 review complaint. A skin built on Tiers A-D of §4.1 simply does not have this failure mode. |
| **Dark mode is one 30,410-character string literal** with 69 rules and 61 `!important`s, injected as `<style id="darkcss">` | read from source | Unmaintainable and untestable. Canvas Refined's whole differentiator is that it moved this into a real CSS file. |
| **Two undebounced whole-document MutationObservers**, no route detection, no `pushState` hook, no `requestAnimationFrame` | read from source | The documented cause of "a lot of the newer features seem to slow down canvas itself." §4.3 is the corrective. |
| **It can hide the submit button.** A user reported "it doesn't let me submit assignments"; the dev replied that their dark mode colours were probably all the same | review + dev reply | A skin that can hide the most consequential control in Canvas is a product defect. Contrast-check every state. |
| **All features vanish on SPA navigation.** "All BetterCampus features disappear when navigating to any tab other than 'Dashboard', and features never reappear." | Extpose, 2026-06-29 | Exactly the gap Prepkin also has today (§5.3). Fixing it is table stakes, not differentiation. |
| **Hotlinked theme images**: 1,863 from `i.pinimg.com`, 197 Tumblr, 150 `encrypted-tbn0.gstatic.com` (Google Images thumbnails), 86+70 Tenor, 64 Twitter, 61 Giphy, 44 Imgur, 42+29 Reddit | counted in `popup.js` | Every dashboard load pings Pinterest and Reddit with a referrer. Links rot. Any school blocking Pinterest gets broken cards. Ship no external image requests at all. |
| **Wrong variable name.** `var(--ic-brand-font-color-dark-lightened-30)` used 6 times; Canvas computes only `-15` and `-28` | verified against `brandable_css.rb` | Six dead declarations. Free correctness win. |
| **Firefox abandoned**, institutional blocking at Sequoia Union HSD (Sept 2025) after students could not open quizzes or log in | two independent school papers, plus a named district manager | The block is the cautionary tale. A skin that touches only CSS, requests no external resources, and disables itself under High Contrast is much harder to blame for a login failure. |
| **The paywall revolt.** "20 dollars a month….2 whole hamilton's a month"; "all of my cute custom themes that I spent hours on are all gone"; "I regret updating, so much stuff is now behind a paywall" | feedback.bettercampus.com | A free, calm, non-extractive skin has an unusually receptive audience right now. |

### 6.3 The legal trap

The repo's LICENSE was MIT (2024-02-11), then **deleted and re-created as AGPL-3.0 on 2025-02-08, ten minutes apart**. The README then adds clauses on top of AGPL prohibiting commercial use, public redistribution, and "a public or private alternative to BetterCanvas, even if the service is offered for free." Those clauses are incompatible with AGPL §7, which forbids adding further restrictions, so the licence is legally incoherent. **Do not litigate this. Do not fork. Do not read their CSS for structure.** They have already sent a cease-and-desist to one fork over the name. Write original CSS from scratch and use a product name containing neither "Canvas" nor "Better" (Instructure reportedly told BetterCampus that even *they* cannot use "Canvas" in a product name, which is why "BetterCampus" exists).

### 6.4 The rest of the field, briefly

**Canvas Refined** (MIT fork of pre-Feb-2025 BetterCanvas, 124 stars, 2 CWS users): moved dark mode into a real CSS file, added card image/roundness/spacing/width controls, custom page background, working theme search. Free and FOSS. **PrettyCanvas** (v1.0.3, 3.0 stars): sidebar width and density controls, explicit self-hosted Canvas support, declares zero data collection. **Canvas Dark Mode** (two of them, 40K and 147 users): the tiny 8.95 KiB one explicitly targets embedded same-origin iframes so frames do not stay white. **Stylus / userstyles.world**: highest-install is Canvas Tokyo Night at 7,190, and notably one of the top entries is "Fixed Better Canvas Dark Mode | Northwestern Univ" at 722 installs, which is the community patching BetterCanvas. **Dark Reader**: works everywhere with zero maintenance, and its weakness is exactly what BetterCanvas reviewers praised: artifacts and inverted images.

### 6.5 Instructure's own position

Native dark mode is **building, not shipped**. `widget_dashboard` and `widget_dashboard_dark_mode` are both `state: hidden`, `applies_to: RootAccount`. It is **dashboard-only** (courses, modules, assignments, grades, inbox stay white) and it is a **JS colour object in React context**, not CSS custom properties, so it is not extensible and you cannot ride it. Dark colours are `pageBackground #1B2330`, `cardBackground #1F2D3D`, `border #2E3E4E`, `textPrimary #FFFFFF`, `textLink #5A9FD4`.

Meanwhile the Theme Editor idea "Dark Theme/Dark Mode for Canvas" (opened by a student, 22 Apr 2018, 354 comments) is still **status Open**, and an Instructure moderator confirmed in Jan 2025 that it is "the most viewed/visited idea in the Community each quarter." Another Instructure staffer in the same thread recommends BetterCanvas by name as the workaround. **That is the incumbent's distribution moat and it is currently unguarded.** You have a window, not forever.

**One distribution note worth more than the extension.** `app/models/brand_config.rb` defines `OVERRIDE_TYPES = %i[js_overrides css_overrides mobile_js_overrides mobile_css_overrides]`. A school admin can already ship arbitrary CSS **and JS**, including a mobile channel that reaches the apps' web views, with no extension at all. For a single-school pilot that is a better path than the Chrome Web Store.

---

## 7. What students actually say

### 7.1 The three complaints, ranked

**1. "I cannot tell what is due."** This is the complaint the entire extension market exists to solve.
- "Absolutely love this extension, especially with how easy it is to view when everything is due, rather than having to navigate every single assignment page of every single unit." (Firefox, novadev)
- "it's saved my ass from missing due dates enough times that I thought I should share it." (r/UMD)
- A role-based Canvas usability study found "students desired better ways to track missing tasks and assignments" and "a broader need for improved information architecture."
- Instructure's own KB admits the cross-course missing-work view is "technically already possible for students but not obvious."

**2. The white screen at 2am.** Eight years, 354 comments, still Open, most-visited idea every quarter. Opened by a student. A meaningful share of it is **disability, not vanity**: migraine, photosensitivity, astigmatism, colour blindness, Irlen syndrome.
- "Yes, dark mode please. I have frequent migraines and can't just stop working. Dark mode makes it at least tolerable."
- "It is physically painful for me to do work in this program/suite due to bilateral astigmatism."
- "As someone who is colorblind (all reds and most dark blues), I have found that using white or light themes are worse on my eyes"

**3. Modules cost too many clicks.** Ranked #1 in Instructure's own Dec 2023 vote (741 of 2,896 participants: "Streamline the experience and reduce the cognitive load of modules"). Caveat: those voters skew heavily instructor and admin, not student. Read it as "everyone agrees modules are expensive," not "students voted."
- "the user interface of regular Canvas was difficult to navigate, and I had to click through five different links before I found the page I was looking for." (high-school opinion piece, Dec 2024)

**Scale.** Roughly **2.5 million students** have installed a third-party skin for their LMS. That market is not speculative.

### 7.2 The case FOR a cute skin

Canvas itself ships cute, officially. `confetti.utils.ts` fires butterfly, gnome, panda, panda_unicycle, pizza_slice, four_leaf_clover, unicorn-adjacent flavours on an on-time submission. Instructure's own Ryan Lufkin: "the introduction of the feature in Canvas has been met with overwhelmingly positive feedback… Students of all ages express their love for the feature. Confetti has become the motivation for submitting work on time."

Student voices:
- "I got really annoyed when my Canvas was ugly." (sophomore, M-A Chronicle). This is the emotional core of the category.
- "Seeing the completion wheel full for each week is almost like an incentive to complete all my work… **But the best part is putting gifs on my class cards.**"
- "i love the extension! it lets me customize the course cards and makes everything so aesthetic."
- "Using this as an accessibility tool has been wonderful."
- "This is such a fun app, makes me want to open canvas more now! :)"

### 7.3 The case AGAINST, stated fairly

This is not a small counter-case and it should shape the default.

1. **Canvas is not universally hated.** The only peer-reviewed SUS score found is **68.9, slightly above the 68 average** (SIGITE '23). Its think-aloud participants "all agreed that navigation in Canvas was relatively easy to figure out." Caveat in both directions: those participants were **ten faculty at one R1 university, zero students**, so it measures whether professors can find the gradebook. But it does mean Canvas is a competent, boring, above-average tool that fails specifically at cross-course triage and at 2am, not a disaster.

2. **The loudest wins are utility, not decoration.** Every top-ranked complaint is informational: what is due, can I read this, how many clicks. The GPA calculator, the due-list on cards, and the completion ring get quoted far more often than the themes do. The themes get quoted when they are *taken away*.

3. **Students actively use these tools to remove personality, not add it.** The most-shared tips are subtractive: "Remove weird default images professors add," "Remove sidebar logo," "Hide default To Do sidebar," "Hide recent feedback." A skin that adds a character to a page a student is trying to declutter is working against the documented behaviour.

4. **Density preference runs both directions.** BetterCanvas ships full-width, condensed-cards and normal as three separate toggles because students genuinely disagree. A skin needs a control here, not an opinion.

5. **Cute has a failure mode that plain does not.** An extension that hides a submit button, or slows the LMS, or pings Pinterest from inside a school network, gets blocked district-wide. One district manager: "if the BetterCanvas extension was removed, all the problems went away… So we blocked the extension." A student then said "After BetterCampus was blocked, I was so distraught from not being organized that it impacted my work." The downside of over-reaching is not a bad review, it is a student losing the tool entirely.

6. **A mascot on a school-owned surface is a different object than a mascot in your own app.** Nothing in the collected student voice asks for a character inside Canvas. They ask for their own GIFs, their own colours, their own fonts. The evidence supports *customisation* strongly and *authorship* weakly.

**Reading of the split.** Cute reads as welcome when it is **the student's choice, opt-in, and reversible**, and it reads as condescending when it is **imposed on a surface the student did not choose and is trying to get through**. The Prepkin panel is opt-in and dismissible, so it is on the safe side. The page skin is imposed, so it should be quiet, and its most valuable work is informational (urgency pills, due dates, readable dark mode), not ornamental.

---

## 8. Design constraints that fall out of all this

These are derived from the merged evidence, not restated from the repo. Where a repo rule and a technical finding converge, both are cited.

1. **Never ship a selector containing `css-`.** Not a full hash, not a label-anchored partial like `[class*="-view"]`. Emotion hashes vary by InstUI version, by props, **and by school brand config**. This is the single defect that made BetterCanvas's dark mode a recurring failure. (§4.1)

2. **Every rule must be a no-op when its selector misses.** Additive styling only. Never a layout override that leaves a broken page when a `data-testid` gets renamed or a v2 rewrite lands. (§4.7)

3. **All Canvas selectors live in one file, annotated with page and hook type, and are covered by a smoke check that runs against each Canvas release.** Markup churn is the default state of this codebase. (§4.7)

4. **Override `--ic-brand-*` on `:root` with `!important`, and derive from the school's existing values rather than replacing them.** Read the computed `:root` at runtime. Institutional identity must survive the skin. This is also what keeps a district from treating the extension as a defacement. (§4.2)

5. **Do not attempt MAIN-world injection or any InstUI theming.** Isolated worlds, page CSP, and a race against React's first mount all rule it out. Say plainly in the product that Files and some headers will not recolour. (§4.2, verdict 1)

6. **The skin disables itself completely when `ENV.use_high_contrast` is true.** Canvas throws away the entire institutional brand config in that mode by design. A skin that paints over a WCAG AAA variant is fighting an accessibility feature. Detect via `ENV`, the stylesheet variant href, and the variables href. (§4.6)

7. **Never set `font-family` when `ENV.use_dyslexic_font === true`.** Check `=== true`, because the key can be absent rather than false. Size, weight and line-height remain fair game. (§4.6)

8. **No hardcoded rail or nav widths.** The rail is 54/84/**104**px and the course menu is 192/**218**px depending on the dyslexic font. Derive from the live computed value or use the existing layout rules. (§4.6)

9. **The skin owns the entire `@media (prefers-reduced-motion: reduce)` block.** Canvas honours it nowhere, InstUI honours it nowhere. Any motion the skin adds is new motion, so every transition and transform the skin introduces must be inside that guard, including hover lifts on dashboard cards. (§4.6, and §5.3 bug 7)

10. **Course colour is read, never written and never overridden.** Take it from `ENV.PREFERENCES.custom_colors` or from Canvas's inline styles. Never recolour `.ic-DashboardCard__header-title span`, and never `!important` the hero's opacity, because both destroy the last colour cue for a student who turned Color Overlay off. (§4.5, and §5.3 bugs 1 and 2)

11. **Zero external network requests from a page inside a school's LMS.** No web fonts, no CDN images, no analytics. System font stack only. This is the single clearest technical difference from the incumbent and it is what makes the extension defensible in a district security review. (§4.4, §6.2)

12. **Ship static CSS as the primary mechanism, and use JS only for what CSS cannot do.** A `content_scripts.css` file injected before DOM construction has no flash, no observer, and no performance cost. Everything expressible there belongs there. (§4.3)

13. **When JS is required, use all four navigation mechanisms and debounce.** A single debounced `MutationObserver` on `document.documentElement`, the `canvasReadyStateChange` event, patched `pushState`/`replaceState` plus `popstate`, and `hashchange` for the Calendar. Never poll. Never run an undebounced whole-document observer over a React app. (§4.3)

14. **Assume three DOM generations behind every URL and branch, never assume.** Feature-detect `instui_nav`, `instui_topnav`, `instui_header`, `context_modules_v2`, `files_v2`, `widget_dashboard`, `render_both_to_do_lists`, `unpublished_courses_redesign`, and `k5_user?`. A student who also TAs a course gets different To Do markup than one who does not. (§2, §3.6)

15. **Never style the submit affordance into invisibility.** Every interactive control the skin touches gets an explicit contrast check in both themes and in every state. The incumbent's documented worst bug is a hidden submit button, and a district blocked it partly because students could not complete quizzes. (§6.2)

16. **Design for the seam.** Cross-origin LTI iframes (New Quizzes, Studio, canvadocs, proctoring, publisher tools) will render stock white inside a dark skin. Either accept the seam visually or suppress the skin on tool-launch routes. Do not hide the limitation from the student. (§4.4)

17. **Informational changes outrank ornamental ones.** Every top-ranked student complaint is about information, not decoration: what is due, can I read this at 2am, how many clicks. Rank work by that. Urgency pills on due dates, a readable dark mode on assignment prose, and a legible Modules page beat any amount of theming. (§7)

18. **The page skin is quiet; the panel is where personality lives.** The student chose to open the panel. They did not choose the skin, and the documented student behaviour on Canvas chrome is subtractive (remove the logo, remove the images, hide the duplicate To Do). Character belongs in the opt-in surface. (§7.3)

19. **Urgency is amber and reads "still counts", never red and never an alarm.** This is a repo rule and it is also the correct read of the student evidence, where the emotional complaint is about pressure and eye strain, not about needing louder warnings. It also keeps the skin clear of Canvas's own red error semantics. (repo preamble, §7.2)

20. **No streaks, no decay, no countdowns, no padlocks.** Repo rule, and the field evidence backs it: multiple users lost 500-600 day streaks in the Tasks for Canvas migration and it produced the angriest reviews in the category. A number that can be reset is a liability. (repo preamble, §6.1)

21. **Every visual toggle is reversible and independently safe.** Today `dark: true, cards: false` collapses the token system. Any two toggles a user can reach must produce a coherent page. Test the full toggle matrix, not the defaults. (§5.3 bug 3)

22. **New mascot-adjacent art in the skin inherits the sign-off gate.** The Look accessories are still marked provisional in source and still listed under "Needs George before any of these ship," and animations additionally need a GIF sign-off. Resolve the slime-versus-Sprout contradiction before drawing anything new for Canvas. (§5.3)

---

**`[input truncated]` notes.** The page inventory cut off mid-entry at "Course home - Modules layout"; the technical-constraints report cut off inside §6 (course colours); the competitive report cut off inside the Theme Editor login group; the repo audit cut off mid-sentence on the slime/Sprout contradiction; the student-voice report cut off mid-quote in §4. Three of the five promised adversarial verdicts did not arrive. Anything those sections would have added is absent here rather than guessed at. The two verdicts that did arrive are applied in full and are marked wherever they overturn a recon claim.
---

# Appendix — the five adversarial verdicts, in full

## Verdict 1 — REFUTED (confidence: high)

**Claim tested.** That overriding the --ic-brand-* CSS custom properties on :root from a content script actually recolours React/InstUI pages in Canvas.

### What is actually true

There are TWO separate ic-brand pipelines in Canvas that share a name but not a mechanism.

(1) CSS pipeline — REAL, and a :root override does work on it. Canvas emits `:root { --ic-brand-primary: ...; }` server-side, and Canvas's own hand-written SCSS reads those with `var(--ic-brand-*)` at runtime. Anything styled by Canvas's compiled SCSS recolours: global nav, SideNavBar, links, legacy `.btn-primary`, breadcrumbs, dashboard cards, focus rings, badges. Note this includes plenty of REACT-rendered markup, because many Canvas React components hand-write stable `ic-*` class names and are styled by ordinary SCSS (e.g. DashboardCard renders `className="ic-DashboardCard"`, styled in app/stylesheets/bundles/dashboard_card.scss which uses `var(--ic-brand-primary)`). So "React page" is NOT the dividing line.

(2) JS pipeline — this is what actually paints InstUI, and a :root override does NOTHING to it. InstUI is styled by Emotion from a plain JavaScript theme object. That theme object contains keys literally spelled `'ic-brand-primary'`, `'ic-link-color'`, `'ic-brand-button--primary-bgd'` — but they are JS string values (hex), not CSS custom properties. Canvas fills them from the page global `CANVAS_ACTIVE_BRAND_VARIABLES` (a separate `<script>`, not the stylesheet) and spreads them over the theme. InstUI component theme generators then run `darken()` and `alpha()` on those values in JavaScript, which mathematically requires a parseable colour — `var(--ic-brand-primary)` would break them. The output is a literal hex/rgba baked into a hashed Emotion class like `css-1a2b3c-link`.

Proof of the separation: the shipped InstUI packages contain ZERO occurrences of `var(--` and 78 occurrences of `ic-brand` — all JS keys.

So: the correct statement is "overriding --ic-brand-* on :root recolours Canvas's own CSS layer, including React components that use stable ic-* classes, but has no effect on anything InstUI renders through Emotion." Pages that are pure InstUI (Files v2, and increasingly headers behind the `instui_header` flag) will not budge at all.

Content scripts also cannot reach the JS pipeline. Chrome content scripts run in an isolated world: "none of these (web page, content scripts, and any running extensions) can access the context and variables of the others." So the extension cannot rewrite `window.CANVAS_ACTIVE_BRAND_VARIABLES` from a normal content script. Injecting into the MAIN world could — but "When a content script is injected into the main world, the CSP of the page applies," and Canvas accounts can have CSP enabled (ENV.csp drives ui/boot/initializers/setupCSP.js). And even a MAIN-world override would have to land before React first renders, because the theme is computed once at provider mount.

### Consequence for the skin

Do not describe or build the skin as ':root variable override = whole-Canvas recolour'. Build it as three tiers, and be honest in the UI about what tier 3 costs.

TIER 1 — SAFE, DO THIS FIRST. Override the 31 --ic-brand-* properties on :root from injected CSS. Confirmed to repaint: global nav and SideNavBar, links, breadcrumbs, legacy .btn/.btn-primary, dashboard card accents and badges, focus rings, watermarks, login page. Ride the exact variable names an admin would set in Theme Editor so the skin degrades gracefully and never fights an existing school theme. Practical note (likely, not verified against a spec): write these as `!important` on `:root` — custom properties do honour !important, and Canvas's own brand stylesheet also sets them on :root at equal specificity, so injection order alone is not a safe bet.

TIER 2 — SAFE, ALSO DO THIS. Target Canvas's hand-written semantic classes directly: ic-*, ig-*, item-group-*, .ic-DashboardCard*, .ic-app-header, .ig-list, .context_module_items, #breadcrumbs, .ic-Layout-contentMain. These are stable across releases and cover a lot of React-rendered markup too, because Canvas React components frequently hand-write them. This is where most of the visible skin should live.

TIER 3 — DO NOT SHIP. Anything selecting a hashed Emotion class (`css-1x2y3z-link`). Those hashes are content hashes of the resolved theme, so they change on every InstUI bump, on every Canvas deploy, and potentially between two schools with different brand configs. A skin built on them looks perfect on your test instance and is broken silently for someone else the same week. If you must reach InstUI internals, use structural and ARIA selectors instead ([role="tablist"], [data-testid], element/attribute structure) and accept partial coverage.

WHAT WILL STAY UNSKINNED, AND YOU SHOULD SAY SO. Everything InstUI paints through the JS theme: InstUI Buttons, Links, Tables, Trays, Modals, Selects, Alerts. Concretely that means Files v2 will not recolour at all, and any page header behind the instui_header flag will not recolour. Expect this surface to grow, not shrink — canvas-lms master already ships context_modules_v2, files_v2, learning_mastery_v2, new_login, widget_dashboard as React/InstUI rewrites of pages that are still legacy ERB for most schools today.

THE ONE REAL LEVER FOR INSTUI IS NOT YOURS TO PULL. InstUI colour comes from window.CANVAS_ACTIVE_BRAND_VARIABLES, a page JS global. A content script is in an isolated world and cannot touch it. MAIN-world injection could, but the page's CSP applies there and Canvas accounts can have CSP on — and you would have to win the race against React's first render, since the theme is computed once at provider mount. Treat this as out of scope rather than as a hard problem to solve.

BUILD-PROCESS ADVICE. Write a smoke test that loads a real Canvas page and asserts your selectors still match, and run it against each Canvas release. Assume markup churn is the default state of this codebase, not an exception.

### Evidence

- VERIFIED — lib/brandable_css.rb: `all_brand_variable_values_as_css` emits exactly `":root {" + values.map { |k, v| "--#{k}: #{v};" } + "}"`. So the CSS custom properties are real and live on :root. Sibling method `all_brand_variable_values_as_js` emits `"CANVAS_ACTIVE_BRAND_VARIABLES = #{json};"` — a SEPARATE JS global, not derived from the CSS at runtime.
- VERIFIED — app/models/brand_config.rb: `to_css` -> BrandableCSS.all_brand_variable_values_as_css; `to_js` -> ...as_js. Two independent outputs from one config.
- VERIFIED — app/helpers/application_helper.rb line 193: `paths << active_brand_config_url("js")` inside `include_head_js`. Canvas loads the brand JS as its own <script> in <head>, independent of the brand stylesheet.
- VERIFIED — app/stylesheets/brandable_variables.json: 31 admin-editable variables in 6 groups (Global Branding, Global Navigation, Watermarks, Login, Discovery, Registration). Includes ic-brand-primary (#2B7ABC), ic-link-color, ic-brand-font-color-dark, ic-brand-button--primary-bgd/text, ic-brand-button--secondary-bgd/text. These are exactly what a school admin can already set in Theme Editor.
- VERIFIED — app/stylesheets/base/_variables.scss consumes them at runtime, not compile time: `$ic-font-color-dark: var(--ic-brand-font-color-dark);` (L279), `$linkColor: var(--ic-link-color);` (L316), `$ic-course-sidenav_list-item--active-font-color: var(--ic-brand-primary);` (L330). This is the proof the :root override DOES work on Canvas's own CSS.
- VERIFIED — app/stylesheets/base/_ic_app_header.scss: ~25 uses, e.g. `background-color: var(--ic-brand-global-nav-bgd);` (L63), `fill: var(--ic-brand-global-nav-ic-icon-svg-fill);` (L194), `background-image: var(--ic-brand-header-image);` (L299). Global nav is fully :root-skinnable.
- VERIFIED — app/stylesheets/base/_SideNav.scss (the newer nav): 11 uses of var(--ic-brand-global-nav-*). Even the InstUI-era nav is patched by Canvas SCSS, so it still responds to :root.
- VERIFIED — app/stylesheets/bundles/dashboard_card.scss: `border-color: var(--ic-brand-primary);` (L145), `@include ic-badge-maker(18px, var(--ic-brand-primary), $ic-color-light);` (L215), hover colors L241/L261. Paired with ui/shared/dashboard-card/react/DashboardCard.tsx which hand-writes `className="ic-DashboardCard"`, `ic-DashboardCard__header`, `ic-DashboardCard__link`, `ic-DashboardCard__header-title`. THIS IS A REACT COMPONENT WITH STABLE CLASSES THAT DOES RESPOND TO :root. The claim's framing of 'React pages' as a single bucket is wrong.
- VERIFIED (this is the refutation) — instructure-ui packages/ui-themes/src/themes/canvas/index.ts defines `const brandVariables = { 'ic-brand-primary': colors?.contrasts?.blue4570, 'ic-link-color': colors?.contrasts?.blue5782, 'ic-brand-button--primary-bgd': colors?.contrasts?.blue4570, ... }` and spreads them into the theme object: `const theme = { ...legacySharedThemeTokens, colors, ...brandVariables }`. These are JS object keys holding hex values. Comments in that file even say `// used by Link and links in Billboard`, `// Used by BaseButton`, `// these are used only by SideNavBar`, and `'ic-brand-button--secondary-bgd': ... // unused!`.
- VERIFIED — instructure-ui packages/ui-buttons/src/BaseButton/v1/theme.ts: `primaryBackground: theme['ic-brand-button--primary-bgd']!`, `primaryHoverBackground: darken(theme['ic-brand-button--primary-bgd']!)`, `primaryGhostHoverBackground: alpha(darken(theme['ic-brand-button--primary-bgd']!), 10)`. darken()/alpha() from @instructure/ui-color-utils run in JS and need a parseable colour string — a CSS var() reference cannot survive this path.
- VERIFIED — instructure-ui packages/ui-link/src/Link/v1/theme.ts: `canvas: { color: theme['ic-link-color'], focusOutlineColor: theme['ic-brand-primary'], hoverColor: darken(theme['ic-link-color'], 10) }`. Same JS-only story for links.
- VERIFIED (decisive) — downloaded the published tarballs and grepped: @instructure/ui-themes@11.7.5 -> 0 occurrences of `var(--`, 44 of `ic-brand`; @instructure/ui-buttons@11.7.5 -> 0 / 31; @instructure/ui-link@11.7.5 -> 0 / 3; @instructure/emotion@11.7.5 -> 0 / 0. InstUI ships no CSS custom properties at all. Every ic-brand reference is a JS theme key.
- VERIFIED — instructure-ui packages/emotion/src/useStyle.ts and withStyle.tsx: `generateComponentTheme(theme)` then `generateStyle(componentTheme, props, state)` returns a plain JS style object. Styles are computed from the JS theme at render, never read from the document.
- VERIFIED — hashed class names are real and labelled: packages/ui-link/src/Link/v1/styles.ts contains `label: 'link'` (L190) and `label: 'icon'` (L208). Emotion renders these as `css-<hash>-link`. The hash is a content hash of the resolved styles, so it changes whenever the theme, the props, or the InstUI version changes. Any selector written against it breaks on the next Canvas deploy — and can even differ between two Canvas instances with different brand configs.
- VERIFIED — @instructure/platform-instui-bindings@0.6.4 (the package Canvas imports; see ui/shared/k5/react/k5-theme.ts importing getTypography from it). Its dist/DynamicInstUISettingProvider.d.ts says verbatim: 'Computes the InstUI theme from explicit settings props rather than reading from window.ENV or window.CANVAS_ACTIVE_BRAND_VARIABLES.' Its dist/theme.d.ts declares `getTheme({ highContrast, brandVariables, k5User, ... })` with `type BrandVariables = Record<string, unknown>`. The minified getTheme body spreads them: `{ ...canvasTheme, ...brandVariables, ...transitionOverride, typography: {...} }`. Confirms the brand values reach InstUI as a JS object, and confirms a sibling code path reads window.CANVAS_ACTIVE_BRAND_VARIABLES.
- VERIFIED — developer.chrome.com content-scripts docs: 'Not only does each extension run in its own isolated world, but content scripts and the web page do too. This means that none of these (web page, content scripts, and any running extensions) can access the context and variables of the others.' And: 'When a content script is injected into the main world, the CSP of the page applies.' So a normal content script cannot patch CANVAS_ACTIVE_BRAND_VARIABLES, and the MAIN-world escape hatch is CSP-gated.
- VERIFIED — ui/boot/initializers/setupCSP.js reads `ENV.csp` and attaches a `securitypolicyviolation` listener plus stamps `csp` on attachment iframes. Canvas accounts can have CSP turned on; whether it is on is per-account, so the extension cannot assume MAIN-world injection will work everywhere.
- VERIFIED (page generation split) — app/views/context_modules/index.html.erb -> renders _content_next.html.erb, which is ERB with legacy markup; app/views/context_modules/items_html.html.erb emits `class="ig-list items context_module_items ..."` (stable, targetable). BUT the same partial branches on `Account.site_admin.feature_enabled?(:instui_header)` to swap the page header for an InstUI React header. And ui/features/context_modules_v2 is a full React rewrite sitting in the tree. Same page, three possible markups depending on flags.
- VERIFIED (pure-InstUI page, zero hooks) — ui/features/files_v2/react/components/FileFolderTable/FileFolderTable.tsx contains 0 occurrences of `className=`; FilesHeader.tsx imports only `@instructure/ui-flex`, `@instructure/ui-heading` and writes no classes. Files v2 offers nothing stable to select. Nothing but hashed Emotion classes.
- VERIFIED (scale of the churn) — canvas-lms master has 232 bundles under ui/features/, including v2 rewrites sitting alongside originals: context_modules AND context_modules_v2, files AND files_v2, learning_mastery AND learning_mastery_v2, jobs AND jobs_v2, login AND new_login, dashboard AND widget_dashboard, assignments_show_teacher AND assignments_show_teacher_deprecated. Which one a given school sees depends on feature flags.

## Verdict 2 — REFUTED (confidence: high)

**Claim tested.** Class names on Canvas React pages (Inbox, Planner/List View, Discussions Redesign, Assignment Enhancements) are hashed and unstable, making them unsafe skin targets.

### What is actually true

The claim is half right and its conclusion is wrong. VERIFIED TRUE: InstUI/Emotion class names on these pages are content-hashed and unstable — never target them. VERIFIED FALSE: that this makes the pages unsafe to skin. All four React pages carry dense, stable `data-testid` hooks, they mount inside the untouched legacy ERB layout skeleton (`#content.ic-Layout-contentMain` etc.), and the body carries semantic scoping classes. There is plenty to hang a skin on.

EXACT EMITTED FORMAT (verified): `css-<hash>-<label>`, e.g. `css-1x2y3z-view`, `css-abc123-view--block`. Emotion builds it as `hashString(styles) + identifierName` where identifierName is `-` + each `label:` found in the serialized style string. Two consequences most people get wrong:
1. The label suffix DOES survive production builds (no NODE_ENV guard on that code path), so `[class*="-view"]` technically matches. But labels are generic component names, so that selector hits every InstUI View on the page. Usable only as a blunt reset, useless for targeting one element.
2. The hash is computed over the RESOLVED style string, and InstUI interpolates literal theme values (`componentTheme.borderColorBrand` → a hex string), emitting zero `var(--...)`. So the hash changes on any InstUI upgrade, any Canvas release, AND potentially between two schools with different brand configs. It is not even stable across instances, let alone across time.

Generation map for the four pages: all four are React/InstUI (hashed classes), not legacy ERB. But each still sits inside legacy markup and each emits its own testids. Planner specifically no longer uses the old canvas-planner CSS-Modules pattern — `ui/shared/planner/components/PlannerItem/index.tsx` imports no .css/.scss and has no `styles.*` className usage.

Stability caveat, stated plainly: `data-testid` is a real, durable hook but it is NOT a published API contract. Instructure renames testids when they refactor their own Jest specs. They churn far less than hashes but they do churn. Treat every selector as needing a periodic re-check, and write the skin to degrade gracefully when one misses.

### Consequence for the skin

Build the skin on a four-tier hook strategy, hardest to softest.

TIER 1, ride the brand system. Anything expressible through `--ic-brand-*` should be, since those are official, versioned, and already how admins theme Canvas. Set them on `:root` or `body` and let Canvas's own SCSS cascade do the work. Zero breakage risk.

TIER 2, anchor layout on the legacy ERB skeleton. `#application.ic-app`, `#wrapper`, `#main`, `#content`, `#content-wrapper`, `#left-side`, `.ic-app-crumbs`. These are plain server-rendered markup, have been stable for years, and wrap every React page including all four in question. Do page scoping with body classes (`body.context-course_123`, the active-tab class, `primary-nav-expanded`).

TIER 3, target `data-testid` inside React regions. Use attribute selectors: `[data-testid="assignments-2-student-view"]`, `[data-testid="discussion-topic-container"]`, `[data-testid="conversation"]`, `[data-testid="planner-item-raw"]`. This is the only viable way into React internals. Prefix-match where testids are templated, e.g. `[data-testid^="open-conversation-for-"]`.

TIER 4, opportunistic legacy classes that survive inside React, like `.discussion-topic-reply-button` and `#assignment_external_tools`. Nice when present, never assume.

NEVER: any selector containing `css-`. Not the full hash, and not `[class*="-view"]` either. The full hash breaks on every Canvas release and possibly per school. The bare label matches every InstUI View on the page, so it will repaint half the UI.

Operational requirements this creates. Write CSS so a missing selector is a no-op, never a broken layout, since testids can be renamed without notice. Keep every Canvas selector in one file with the page and testid noted, so a breakage audit is a single read. Add a smoke check that asserts the handful of load-bearing testids still exist on each of the four pages, and run it against each Canvas release. Prefer additive styling over overriding InstUI's own rules: InstUI injects its styles at runtime with high specificity, so expect to need specificity bumps or `!important` on color and spacing overrides inside React regions, and confirm that on a real page before committing to a design.

### Evidence

- VERIFIED (emotion-js/emotion, packages/serialize/src/index.ts, main branch): line 364 `let labelPattern = /label:\s*([^\s;{]+)\s*(;|$)/g`; line 429-430 `while ((match = labelPattern.exec(styles)) !== null) { identifierName += '-' + match[1] }`; line 433 `let name = hashString(styles) + identifierName`. No NODE_ENV guard wraps this, so the label suffix ships in production. Class format is therefore `css-<hash>-<label>` and the hash is over style CONTENT, not component identity.
- VERIFIED (published build @instructure/ui-view/es/View/styles.js via jsdelivr): contains explicit `label: 'view'`, `label: 'view--block'`, `label: 'view--inline'`, `label: 'view--inlineBlock'`, `label: 'view--flex'`, `label: 'view--inlineFlex'`. Confirms InstUI sets Emotion labels, so real emitted classes look like `css-1a2b3c-view--block`.
- VERIFIED (same file): theme values are interpolated as literals — `borderColor: componentTheme.borderColorBrand`, `outlineWidth: componentTheme.focusOutlineWidth`, `` outlineOffset: `calc(${componentTheme.focusOutlineOffset} - ${componentTheme.focusOutlineWidth})` ``. grep for `var(--` returns 0 matches in the built styles. INFERRED from this + the hash formula: the hash varies with resolved theme values, so it can differ per brand config and definitely differs per InstUI version.
- VERIFIED — INBOX (canvas-lms ui/features/inbox/react/components/ConversationListHolder/ConversationListItem.tsx, master): ZERO `className` attributes, many testids. `data-testid="conversation"` (L112), `"conversationListItem-Item"` (L119), `"conversationListItem-Checkbox"` (L142), `"unread-badge"`/`"read-badge"` (L209), `"last-message-content"` (L257), `"visible-starred"`/`"visible-not-starred"` (L276), `` `open-conversation-for-${props.conversation._id}` `` (L289, L308).
- VERIFIED — INBOX SHELL (ui/features/inbox/react/containers/CanvasInbox.tsx): `data-testid="inbox-settings-in-header"`. Mount point (ui/features/inbox/index.tsx L25): `getElementById('content')` — the React app is injected into the legacy stable `#content` wrapper.
- VERIFIED — DISCUSSIONS REDESIGN (ui/features/discussion_topics_post/react/containers/DiscussionTopicContainer/DiscussionTopicContainer.tsx): `data-testid="highlight-container"` (L455), `"discussion-topic-container"` (L456), `"discussion-topic-closed-for-comments"` (L615), `"discussion-topic-reply"` (L635), `"add_rubric_url"` (L811). ALSO a plain non-hashed legacy class at L630: `<span className="discussion-topic-reply-button">` — a stable semantic class inside React markup.
- VERIFIED — ASSIGNMENT ENHANCEMENTS (ui/features/assignments_show_student/react/components/StudentContent.jsx): `data-testid="assignments-2-student-view"` (L373, the page root), `data-testid="student-content-flex-container"` (L225), and a plain stable id `<div id="assignment_external_tools" />` (L279).
- VERIFIED — PLANNER / LIST VIEW (ui/shared/planner/components/PlannerItem/index.tsx, 30KB): `data-testid="planner-item-raw"`, `"planner-item-completed-checkbox"`, `"edit-event-button"`, `"feedback-comment"`, `"MissingAssignments-CourseName"`, and `data-testid={enabled ? 'join-button-hot' : 'join-button'}`. No `styles.*` className usage and no .css/.scss import — the old CSS-Modules generation is gone from this component.
- VERIFIED (negative evidence, moderate strength) — data-testid is NOT stripped in production. canvas-lms package.json lists only `babel-plugin-transform-react-remove-prop-types` (strips propTypes, not attributes). ui-build/webpack/index.js contains no testid/attribute-removal transform. No babel.config.js or .babelrc at repo root. So source testids reach the shipped DOM.
- VERIFIED — STABLE LEGACY LAYOUT SKELETON (app/views/layouts/application.html.erb, plain ERB, not React): `#application.ic-app` (L132), `#wrapper.ic-Layout-wrapper` (L140), `#main.ic-Layout-columns` (L211), `#left-side.ic-app-course-menu.ic-sticky-on` (L222-223), `#content-wrapper.ic-Layout-contentWrapper` (L242), `#content.ic-Layout-contentMain` (L269), `.ic-app-nav-toggle-and-crumbs` (L147), `.ic-app-crumbs` (L154), `#react-instui-topnav.instui-topnav-container` (L142-143), `.ic-Layout-watermark` (L213), `#sticky-container.ic-sticky-frame` (L226). These wrap every React page and are the safest anchors on Canvas.
- VERIFIED — BODY SCOPING CLASSES (same layout, L85-113, `<body class="<%= body_classes.uniq.join(' ') %>">`): `with-left-side`, `course-menu-expanded`, `with-right-side`, `padless-content`, `with-fixed-bottom`, `pages`, `get_active_tab` output, `primary-nav-expanded` / `primary-nav-transitions`, `full-width`, `context-course_<id>` (from `"context-#{@context.asset_string}"`), `content-only`, `no-headers`, `hide-global-nav`, `is-masquerading-or-student-view`. These give per-page and per-course CSS scoping without touching any React class.
- VERIFIED — THEME EDITOR VARIABLES a school admin can already set (app/stylesheets/brandable_variables.json), exposed as `--ic-brand-*` custom properties (confirmed `--ic-brand-primary`, `--ic-brand-font-color-dark` in app/stylesheets/base/_variables.scss): ic-brand-primary, ic-brand-font-color-dark, ic-link-color, ic-brand-button--primary-bgd, ic-brand-button--primary-text, ic-brand-button--secondary-bgd, ic-brand-button--secondary-text, ic-brand-global-nav-bgd, ic-brand-global-nav-ic-icon-svg-fill(--active), ic-brand-global-nav-menu-item__text-color(--active), ic-brand-global-nav-avatar-border, ic-brand-global-nav-menu-item__badge-bgd/text(--active), ic-brand-global-nav-logo-bgd, ic-brand-header-image, ic-brand-mobile-global-nav-logo, ic-brand-watermark(-opacity), ic-brand-favicon, ic-brand-apple-touch-icon, ic-brand-msapplication-tile-*, ic-brand-right-sidebar-logo, and the full ic-brand-Login-* set.
- NOT VERIFIED / limitation: I confirmed testids in source only. I could not read a live authenticated Canvas DOM to confirm the rendered attributes, and I could not run GitHub code search across all four features (API rate limit hit after the Inbox count of 25 files and Planner count of 22 files with data-testid). Confidence that source testids reach the DOM: high, based on the absence of any stripping transform.
- LIKELY (not a written contract): data-testid names are driven by Instructure's own test suites, so they change on refactors. They are far more durable than Emotion hashes but carry no stability guarantee from Instructure. No Instructure doc was found that promises testid stability.

## Verdict 3 — REFUTED (confidence: high)

**Claim tested.** New Quizzes, DocViewer and LTI tools render in cross-origin iframes that a Chrome content script cannot style, even with broad host permissions.

### What is actually true

The claim is right about the frames and wrong about the conclusion, and it is now partly out of date on New Quizzes.

PART 1 — "cannot be styled" is FALSE (the load-bearing error).
A Chrome content script is injected per frame, matched by that frame's own URL, not by the top page's origin. `"all_frames": true` in a manifest content_scripts entry injects JS and CSS into every frame whose URL matches `matches`. Same-origin policy stops the PARENT frame's script from reaching into the child's DOM — that is the kernel of truth — but it does not stop the extension from having a SECOND script instance running inside the child frame with full DOM and CSS access there. The two instances just cannot talk via the DOM; they coordinate through the service worker. Content scripts default to the ISOLATED world, whose CSP is `script-src 'self' 'wasm-unsafe-eval' 'inline-speculation-rules' chrome-extension://<id>/; object-src 'self'` — there is NO style-src clause, so the host page's CSP does not block extension-injected CSS. (Page CSP only applies when you opt a script into MAIN world.) Extension-hosted assets referenced from that CSS — fonts, background images — must be declared in `web_accessible_resources`, with a `matches` entry covering the iframe origin too.

PART 2 — New Quizzes is NO LONGER in an iframe as of Aug 2026 (verified, Canvas source + Instructure product blog).
Canvas feature flag `new_quizzes_native_experience`, defined in `config/feature_flags/quizzes_release_flags.yml`, description verbatim: "Enabling this feature moves the New Quizzes experience out of its isolation layer (iframe) to run natively within the main Canvas page. Note: This feature option will be removed on July 1st, 2026, as the native integration becomes the standard experience for all production environments." Instructure's product blog gives the timeline: GA opt-in 2026-03-26, default ON 2026-07-01, ENFORCED 2026-08-15. Today is 2026-09-03, so it is enforced. New Quizzes now loads as a module-federation React remote into `<div id="new-quizzes-root">` inside the normal Canvas layout, with `body.native-new-quizzes full-width`. Canvas's own stylesheet says so verbatim: "In native launch, quizzes-ui renders directly in the Canvas DOM (not in an iframe like LTI)". Same origin. No iframe. Fully reachable by ordinary top-frame CSS.

PART 3 — DocViewer and generic LTI ARE still cross-origin iframes (verified).
LTI: `app/views/lti/_launch_iframe.html.erb` renders `<div class="tool_content_wrapper"><iframe id="tool_content" name="tool_content" class="tool_launch" src="about:blank">` and a hidden `<form id="tool_form" target="tool_content" method="POST">` that navigates the frame to the vendor origin. No `sandbox` attribute (the `iframe()` helper in `application_helper.rb:525` never adds one).
DocViewer: `app/views/submissions/show_preview.html.erb` renders `<iframe class="ef-file-preview-frame annotated-document-submission" src="<canvadoc_url>">`; `ui/shared/files/react/components/FilePreview.jsx` renders `iframe.ef-file-preview-frame` at `/courses/:id/files/:id/file_preview`, and `FilePreviewsController#show` 302-redirects that frame to the canvadocs session URL. Origin is `canvadocs.instructure.com` (regional prod) / `canvadocs-beta.inscloudgate.net`. No sandbox attribute. Reachable with `all_frames` + a matching host permission; the interior markup is closed-source and cannot be audited, so treat every selector inside it as a guess.
Third-party LTI (Turnitin, Panopto, Pearson, proctoring): origins are unbounded per institution, so you cannot enumerate them in `matches`. That needs `<all_urls>` (triggers the "read and change all your data on all websites" warning and Chrome Web Store review friction) or `optional_host_permissions` granted at runtime. That is the REAL blocker for LTI — permission scope and unknowable vendor DOM, not any technical impossibility.

PART 4 — THE ACTUAL FRAGILITY: two markup generations, both inside the same page.
Legacy ERB / jQuery / Backbone markup — stable, semantic, safe to target (all VERIFIED in canvas-lms source):
• Page shell, `app/views/layouts/application.html.erb`: `body.ic-app`, `#application`, `#content`, `#content-wrapper`, `.ic-Layout-wrapper`, `.ic-Layout-columns`, `.ic-Layout-contentWrapper`, `.ic-Layout-contentMain`, `.ic-app-main-content`, `.ic-app-course-menu`, `.ic-app-nav-toggle-and-crumbs`, `.ic-app-crumbs`, `.ic-sticky-frame`, `.ic-Layout-watermark`.
• Global nav: `.ic-app-header` (`app/views/shared/_new_nav_header.html.erb`, `app/stylesheets/base/_ic_app_header.scss`).
• Modules page, `app/views/context_modules/_context_module_next.html.erb`: `.ig-header`, `.ig-header-title`, `.ig-header-admin`, `.module_header_items`, `.collapse_module_link`, `.expand_module_link`, `.requirements_message`, `.completion_status`, `.module-publish-icon`, plus `icon-*` glyph classes.
• Dashboard cards: `.ic-DashboardCard` and children (`app/views/shared/_dashboard_card.html.erb`, `app/stylesheets/bundles/dashboard_card.scss`, `ui/shared/dashboard-card/react/DashboardCard.tsx` — React, but hand-written stable classNames).
• File preview: `.ef-file-preview-stretch`, `.ef-file-preview-frame`, `.ef-file-preview-header-info`, `.ef-file-not-found` (`app/stylesheets/pages/react_files/_FilePreview.scss`).
• LTI wrapper: `.tool_content_wrapper`, `#tool_content.tool_launch`, `#tool_form`.
• Native New Quizzes container: `body.native-new-quizzes`, `#new-quizzes-root`, `#new-quizzes-root > #root` (`app/stylesheets/bundles/native_new_quizzes.scss`).

InstUI / React markup — HASHED, will break (VERIFIED in instructure-ui source):
InstUI v11 (`@instructure/emotion@11.7.5`) depends on `@emotion/react`. Component style objects carry explicit emotion `label` keys — e.g. `packages/ui-view/src/View/v1/styles.ts` has `label: 'view'`, `label: 'view--flex'`, `label: 'view--inlineBlock'`; `packages/ui-buttons/src/BaseButton/v1/styles.ts` has `label: 'baseButton'`, `label: 'baseButton__content'`, `label: 'baseButton__children'`, `label: 'baseButton__iconSVG'`, `label: 'baseButton__iconOnly'`. Emotion emits `css-<hash>-<label>`, so the live DOM reads `css-1x2y3z-view`, `css-abc123-baseButton__content`.
IMPORTANT AND USEFUL: because the label is set explicitly INSIDE the style object (not via emotion's dev-only `autoLabel` babel option), the label SURVIVES production builds. The hash is volatile — it changes with theme values, props and InstUI version — but the trailing label is stable. So `[class*="-baseButton__content"]` or `[class$="-view"]` is a semi-stable hook. It is still second-class: InstUI can rename a label in any minor release, and there is no compatibility promise.
Pages that are InstUI-first (hashed): the new SideNav (`ui/features/navigation_header/react/SideNav.tsx`, built from `@instructure/ui-side-nav-bar`), Discussions Redesign (`ui/features/discussion_topics_post`), the student assignment page (`ui/features/assignments_show_student`), Modules Rewrite (`ui/features/context_modules_v2`), the widget dashboard (`ui/features/widget_dashboard`), and the module-federated New Quizzes UI itself.
Canvas leaves escape hatches even in InstUI screens: `SideNav.tsx` sets `className="ic-app-header__main-navigation"` and `id="instui-sidenav"` on InstUI elements, and 47 files under `ui/features/assignments_show_student` carry `data-testid` attributes. Those are more durable than hashes, though `data-testid` is a test contract, not a public API.

PART 5 — Theme Editor: 47 `--ic-brand-*` variables an admin can already set, no extension needed.
`app/stylesheets/brandable_variables.json` defines 47 variables in 6 groups: global_branding, global_navigation, watermarks, login, discovery, registration. Key ones: `ic-brand-primary` (#2B7ABC), `ic-brand-font-color-dark` (#273540), `ic-link-color` (#0E68B3), `ic-brand-button--primary-bgd/--primary-text`, `ic-brand-button--secondary-bgd/--secondary-text`, `ic-brand-global-nav-bgd` (#334451), `ic-brand-global-nav-ic-icon-svg-fill`, `ic-brand-global-nav-menu-item__text-color`, `ic-brand-global-nav-menu-item__badge-bgd`, `ic-brand-header-image`, `ic-brand-favicon`, `ic-brand-watermark`. These are set through the Canvas Theme Editor and are the correct layer for brand color — a skin should read and ride them rather than hard-coding hexes.

### Consequence for the skin

Do not build the skin around "iframes are unreachable." Build it around two real constraints: permission scope, and markup generation.

1. New Quizzes needs NO iframe handling any more. Since 2026-08-15 it renders same-origin under `body.native-new-quizzes #new-quizzes-root > #root`. Target that container from the ordinary top-frame stylesheet. Its interior is a module-federated InstUI React app, so style the container, spacing, background and typography inheritance — not its internals.

2. DocViewer and third-party LTI stay cross-origin, and ARE reachable: add a second content_scripts entry with `"all_frames": true` and `matches` for the DocViewer hosts (`https://*.instructure.com/*`, plus `https://*.inscloudgate.net/*` for beta). Page CSP will not block the CSS — isolated-world CSP has no style-src. Any font or image the CSS pulls from the extension must be in `web_accessible_resources` with a `matches` entry covering those iframe origins too.

3. Do NOT chase generic LTI vendors. Their origins are unbounded per institution, so covering them means `<all_urls>`, which buys the "read and change all your data on all websites" warning and Web Store review friction, to style a vendor DOM you cannot see, audit or version-pin. Ship a neutral frame treatment on the Canvas side instead: style `.tool_content_wrapper` and `#tool_content.tool_launch` (border, radius, background, height) and leave the interior alone.

4. Selector policy, in priority order:
   a. `--ic-brand-*` custom properties first — 47 of them, already the supported branding layer, already respected by every legacy stylesheet. Read them, ride them, override them at `:root` rather than hard-coding hexes.
   b. Legacy ERB classes second — `.ic-app`, `.ic-Layout-contentMain`, `#content`, `.ic-app-header`, `.ig-header`, `.ic-DashboardCard`, `.ef-file-preview-frame`, `.tool_content_wrapper`. These are stable and carry most of the visual weight.
   c. `id` and hand-written `className` escape hatches inside InstUI screens third — `#instui-sidenav`, `.ic-app-header__main-navigation`, `.navigation-tray-container`, `#new-quizzes-root`.
   d. `data-testid` fourth, knowingly, as a test contract that can move.
   e. Emotion labels last and only when nothing else works: `[class*="-baseButton__content"]`, `[class$="-view"]`. The label survives production builds (it is set explicitly in each component's styles.ts, not by autoLabel), but the `css-<hash>-` prefix is volatile and the label itself can be renamed in any InstUI minor. `ui-view` and `ui-buttons` already ship both `v1/` and `v2/` style generations, so this WILL churn.
   NEVER write a full hashed class such as `.css-1x2y3z-view`. It is a build artifact and will break.

5. Budget for churn on the pages Canvas is actively rewriting: modules (context_modules_v2), the dashboard (widget_dashboard), the student assignment page, discussions (discussion_topics_post), and the side nav. Each is legacy ERB today at most institutions and InstUI tomorrow. Write the skin so those five surfaces degrade to "unstyled but not broken" rather than "visually wrong."

### Evidence

- VERIFIED (developer.chrome.com, manifest content_scripts reference) — all_frames: "Defaults to false, meaning that only the top frame is matched. If set to true, it will inject into all frames, even if the frame is not the topmost frame in the tab." Injection is matched per frame against that frame's own URL; cross-origin is not a barrier to injection, only to parent-to-child DOM access.
- VERIFIED (developer.chrome.com, Content scripts concepts page, 'Content Security Policy' section) — "Content scripts running in isolated worlds have the following Content Security Policy (CSP): script-src 'self' 'wasm-unsafe-eval' 'inline-speculation-rules' chrome-extension://abcdefghijklmopqrstuvwxyz/; object-src 'self';" and "When a content script is injected into the main world, the CSP of the page applies." No style-src clause => page CSP does not block extension-injected CSS in the default ISOLATED world.
- VERIFIED (developer.chrome.com, same page) — extension-hosted fonts/images used from injected CSS must be listed in web_accessible_resources with a matches entry; the doc shows a @font-face example paired with a web_accessible_resources block.
- VERIFIED (developer.chrome.com) — static content_scripts inject on `matches`; PROGRAMMATIC injection additionally requires host permissions or activeTab: "To inject a content script programmatically, your extension needs host permissions for the page it's trying to inject scripts into."
- VERIFIED (canvas-lms, config/feature_flags/quizzes_release_flags.yml, lines 131-142) — new_quizzes_native_experience, display_name 'New Quizzes Canvas Native Integration', state: hidden, applies_to: Course. Description verbatim: "Enabling this feature moves the New Quizzes experience out of its isolation layer (iframe) to run natively within the main Canvas page. Note: This feature option will be removed on July 1st, 2026, as the native integration becomes the standard experience for all production environments." Sibling flags: new_quizzes_native_experience_respondus, _sessionless, _api_gateway.
- VERIFIED (Instructure product blog, community.instructure.com/en/discussion/665555, 'New Quizzes Native Integration in Canvas | Q1 2026', by Amy_Haskell) — "Release Timing: Generally Available March 26, 2026 as a Feature Option. This feature will be enabled by default for all users July 1, 2026 and will be enforced August 15, 2026." and "moves the New Quizzes experience out of its legacy iFrame layer and into the Canvas page". Today is 2026-09-03, so this is enforced.
- VERIFIED (canvas-lms, app/stylesheets/bundles/native_new_quizzes.scss, (C) 2025) — comment verbatim: "In native launch, quizzes-ui renders directly in the Canvas DOM (not in an iframe like LTI), so these styles bleed into quiz headings." Selectors defined: body.native-new-quizzes, .ic-Layout-wrapper, .ic-Layout-columns, .ic-app-main-content, .ic-Layout-contentWrapper, .ic-app-course-menu, .ic-app-nav-toggle-and-crumbs, .ic-Layout-contentMain, #new-quizzes-root, #new-quizzes-root > #root, and &.embedded #new-quizzes-root.
- VERIFIED (canvas-lms, app/views/assignments/native_new_quizzes.html.erb) — entire body is `<div id="new-quizzes-root"></div>`. Mounted by ui/features/new_quizzes/index.tsx via react-router createBrowserRouter into NEW_QUIZZES_CONTAINER_ID = 'new-quizzes-root'.
- VERIFIED (canvas-lms, app/helpers/new_quizzes_helper.rb) — setup_new_quizzes_env calls add_body_class("native-new-quizzes full-width"), js_bundle :new_quizzes, css_bundle :native_new_quizzes, gated on @context.feature_enabled?(:new_quizzes_native_experience).
- VERIFIED (canvas-lms, app/controllers/new_quizzes_controller.rb, (C) 2025) — header comment: "Controller for New Quizzes native experience (module federation)." Routes: /courses/:course_id/assignments/:assignment_id/{build,reporting,moderation,exports,taking,observing}/*, /courses/:course_id/banks/*, /accounts/:account_id/banks/*. Renders 'assignments/native_new_quizzes' with layout 'application'.
- VERIFIED (canvas-lms, app/views/lti/_launch_iframe.html.erb) — LTI launch markup: outer <div class="tool_content_wrapper" data-tool-wrapper-id=...>, hidden <form id="tool_form" (or tool_form_<id>) method="POST" target="tool_content" data-tool-launch-type data-tool-id data-tool-path data-message-type>, and iframe("about:blank", name/id: tool_content (or tool_content_<id>), class: "tool_launch", allowfullscreen, tabindex 0, style height/width from tool_dimensions, allow: <FRAME_ALLOWANCES>, data-lti-launch: true). The frame starts at about:blank and is navigated to the vendor origin by the form POST.
- VERIFIED (canvas-lms, app/helpers/application_helper.rb:525-548) — the iframe() helper does NOT add a sandbox attribute. So LTI and DocViewer frames are unsandboxed: content scripts inject normally.
- VERIFIED (canvas-lms, app/models/lti/launch.rb) — FRAME_ALLOWANCES = geolocation, microphone, camera, midi, encrypted-media, autoplay, clipboard-write, display-capture, fullscreen; each emitted as '<feature> *' in the iframe allow attribute.
- VERIFIED (canvas-lms, app/views/submissions/show_preview.html.erb) — student_annotation branch: <div class="ef-file-preview-stretch"><iframe allowfullscreen class="ef-file-preview-frame annotated-document-submission" src="<annotation_context.attachment.canvadoc_url(...)>" style="height:100vh;width:100%">. Also shows the modal preview trigger a.modal_preview_link.Button--link with data-attachment_id / data-submission_id, and discussion preview #discussion_preview_iframe.ef-file-preview-frame.
- VERIFIED (canvas-lms, ui/shared/files/react/components/FilePreview.jsx, renderCanvasPlayer) — iframe classes ef-file-preview-frame / ef-file-preview-frame-html / attachment-html-iframe; sandbox is classnames('allow-same-origin','allow-downloads', {'allow-scripts': !html}). allow-same-origin means no opaque origin, so content scripts inject normally.
- VERIFIED (canvas-lms, app/controllers/file_previews_controller.rb#show) — `if (url = @file.canvadoc_url(@current_user)) redirect_to url` — the same-origin /file_preview URL 302s the iframe to the canvadocs origin. So the frame ends cross-origin at canvadocs.instructure.com (or canvadocs-beta.inscloudgate.net for beta).
- VERIFIED (canvas-lms, app/views/files/show.html.erb:59-66) — the only other sandboxed frame: iframe#file_content sandbox="allow-same-origin" for text/html, "allow-scripts allow-same-origin" otherwise, gated on FEATURES.disable_iframe_sandbox_file_show. Still allow-same-origin, so still injectable.
- VERIFIED (instructure-ui, packages/emotion/package.json @ 11.7.5) — dependencies include "@emotion/react": "^11". withStyle.tsx passes generated style objects through @emotion/react/jsx-runtime; class names are emotion-generated.
- VERIFIED (instructure-ui, packages/ui-view/src/View/v1/styles.ts) — explicit emotion labels at lines 286,290,294,299,303,308,312,316,320,324,328,445: 'view--inline','view--block','view--inlineBlock','view--flex','view--inlineFlex','view--contents','view--inherit','view--initial','view--revert','view--revertLayer','view--unset','view'.
- VERIFIED (instructure-ui, packages/ui-buttons/src/BaseButton/v1/styles.ts) — explicit labels at lines 358,402,406,455,475,483,499,510,524: 'baseButton','baseButton__content','baseButton__children','baseButton__iconSVG','baseButton__childrenLayout','baseButton__iconOnly','baseButton__iconWrapper','baseButton__childrenWrapper'. Labels are in the style object, not autoLabel, so they persist in production builds => rendered class is css-<hash>-baseButton__content.
- VERIFIED (instructure-ui, packages/ui-view/src/View and packages/ui-buttons/src/BaseButton) — both now contain v1/ and v2/ subdirectories, i.e. a second styling generation is already landing. Another reason label strings are not a durable contract.
- VERIFIED (canvas-lms, app/views/layouts/application.html.erb) — stable shell hooks: body class ic-app (+ @context.asset_string + body_classes), #application, #content, #content-wrapper, .ic-Layout-wrapper, .ic-Layout-columns, .ic-Layout-contentWrapper, .ic-Layout-contentMain, .ic-Layout-watermark, .ic-app-main-content, .ic-app-main-content__secondary, .ic-app-course-menu.ic-sticky-on, .ic-app-nav-toggle-and-crumbs.no-print, .ic-app-crumbs, .ic-sticky-frame, #courseMenuToggle, .Button.Button--link.ic-app-course-nav-toggle, .ic-notification/.ic-notification__content, plus mount points #drawer-layout-mount-point, #immersive_reader_mount_point, #ai-information-mount, #learning_agent_mount_point, #group-switch-mount-point. Also 'instui-topnav-container' (new InstUI top nav appearing in the shell).
- VERIFIED (canvas-lms, app/views/context_modules/_context_module_next.html.erb) — Modules page is legacy ERB with stable classes: ig-header header, ig-header-title collapse_module_link ellipsis, ig-header-title expand_module_link ellipsis, module_header_items, ig-header-admin, requirements_message, pill, completion_status, module-publish-icon, sortable-handle reorder_module_link, add_module_item_link Button--icon-action, al-trigger / al-options, edit_module_link, move_module_link, assign_module_link, delete_module_link, duplicate_module_link, module_send_to, estimated_duration_header_title/_minutes, plus icon-* glyphs.
- VERIFIED (canvas-lms, ui/features/) — a React replacement exists for most of the legacy surface: context_modules_v2, widget_dashboard, assignments_show_student, assignments_show_teacher, discussion_topics_post, discussion_topic_edit_v2, enhanced_individual_gradebook, new_quizzes. Legacy siblings (context_modules, dashboard, quizzes) still ship alongside them.
- VERIFIED (canvas-lms, ui/features/navigation_header/react/SideNav.tsx) — imports SideNavBar, Badge, CloseButton, Spinner, Tray, View, Avatar, Img from @instructure/ui-* (=> hashed classes), but still sets className="ic-app-header__main-navigation" (line 222), id="instui-sidenav" (line 226), and className={`navigation-tray-container ${activeTray}-tray`} (line 521), .tray-with-space-for-global-nav (line 530). Sibling file OldSideNav.tsx confirms two generations coexist.
- VERIFIED (canvas-lms) — 47 files under ui/features/assignments_show_student carry data-testid attributes; Canvas React features generally do. More durable than emotion hashes, but a test contract, not a public API.
- VERIFIED (canvas-lms, app/stylesheets/brandable_variables.json) — 47 variables across 6 group_keys: global_branding, global_navigation, watermarks, login, discovery, registration. Defaults include ic-brand-primary #2B7ABC, ic-brand-font-color-dark #273540, ic-link-color #0E68B3, ic-brand-button--primary-bgd $ic-brand-primary, ic-brand-button--primary-text #ffffff, ic-brand-button--secondary-bgd #273540, ic-brand-global-nav-bgd #334451, ic-brand-global-nav-ic-icon-svg-fill #ffffff, ic-brand-global-nav-menu-item__text-color #ffffff, ic-brand-global-nav-menu-item__badge-bgd #ffffff, ic-brand-header-image /images/canvas_logomark_only@2x.png, ic-brand-favicon, ic-brand-watermark, ic-brand-watermark-opacity.
- LIKELY (Instructure Community + institutional Canvas support pages) — New Quizzes LTI launch URL is https://<institution>.quiz-lti-<region>-prod.instructure.com/lti/launch (e.g. quiz-lti-iad-prod.instructure.com). Per-region and per-institution subdomains mean this cannot be covered by one narrow match pattern.
- LIKELY (Instructure DocViewer API docs, canvadocs.instructure.com/docs/docs/loadInIframe.html and .../environments.html) — DocViewer is embedded as <iframe src="<base>/1/sessions/<SESSION_ID>/view" allowfullscreen="1">; regional prod hosts under canvadocs.instructure.com, beta at canvadocs-beta.inscloudgate.net. The environments.html page 404'd on direct fetch, so treat the exact host list as unconfirmed.
- NOT VERIFIABLE — canvadocs (DocViewer) and the module-federated quizzes-ui bundle are closed source. Their internal class names appear in no public repo. Any selector aimed inside DocViewer is a guess with no way to audit it.
- NO EVIDENCE FOUND — nothing in Instructure release notes or the canvas-lms repo indicates DocViewer is leaving its iframe. Assume it stays cross-origin.

## Verdict 4 — REFUTED (confidence: high)

**Claim tested.** That the Canvas Content-Security-Policy blocks an extension from loading a Google Fonts webfont into an instructure.com page.

### What is actually true

Canvas does not ship a font-src, style-src, or default-src at all. Live production Canvas sends exactly one CSP directive: frame-ancestors. That directive governs who may iframe Canvas. It has zero effect on fonts, CSS, or images. So an extension-injected @font-face pointing at https://fonts.gstatic.com loads fine on a stock Canvas page.

Even in the maximal opt-in configuration, fonts are still not blocked. Canvas's CSP feature is gated on a per-account feature flag (javascript_csp) plus an explicit "Enable Content Security Policy" toggle, and its documented purpose is restricting custom JavaScript. When fully on, the enforced header is frame-src / script-src / object-src. None of those fall back to font-src. Only default-src falls back to font-src, and default-src appears only under a second, separate account flag (default_source_csp_logging) — and even that string explicitly allows data:, so a base64 font would survive it.

On the extension side, the claim also gets the Chrome mechanics backwards in one place and right in another:
- A chrome-extension:// URL bypasses the page CSP entirely. Verified in Chromium main: chrome/common/chrome_content_client.cc pushes extensions::kExtensionScheme into schemes->csp_bypassing_schemes; blink scheme_registry.cc registers every such scheme with kPolicyAreaAll; ContentSecurityPolicy::ShouldBypassContentSecurityPolicy consults that registry. kPolicyAreaAll includes font-src. So bundling the .woff2 in the extension and declaring it in web_accessible_resources is bypass-proof against any page CSP, on any site — not just Canvas.
- A data: URL font does NOT get that bypass. data: is not in csp_bypassing_schemes, so a base64-inlined font is checked against the page's font-src/default-src like any page resource.
- "Content scripts have special CSP status" is only half true and does not cover this case. The isolated world exempts the content script's own execution and its own direct fetches (ContentSecurityPolicy::ShouldBypassMainWorldDeprecated, gated on IsolatedWorldCSP). It does NOT exempt a <style> element the script appends to the page. Once that stylesheet lives in the page's document, the font fetch it triggers during style resolution is attributed to the document and is checked against the page CSP. That is the real failure mode on CSP-heavy sites — but Canvas is not one of them.

### Consequence for the skin

Do not architect around a Canvas CSP that does not exist. Concretely:

1. A plain `<link rel=stylesheet href=https://fonts.googleapis.com/...>` or an injected @font-face pointing at fonts.gstatic.com will work on Canvas today. No workaround needed.
2. Still bundle the font locally anyway — for speed and offline, not for CSP. Ship the .woff2 in the extension, declare it in web_accessible_resources with `"matches": ["*://*.instructure.com/*", ...]` plus each school's vanity host, and reference it with chrome.runtime.getURL(). That path is verified immune to any page CSP a school might later switch on, and it removes a third-party request from every Canvas page load.
3. Do NOT reach for a base64 data: font as the "safe" fallback. data: gets no scheme bypass. It is the one option that a future Canvas default-src could actually block (though Canvas's own default-src string happens to allow data:). chrome-extension:// is strictly safer than data:.
4. The one thing that could bite later is script-src, not font-src. If a school turns on the CSP toggle, the enforced header carries script-src with an allowlist. That is aimed squarely at injected JavaScript. A content script's own execution is unaffected (isolated world), but anything the skin does by appending a <script> tag into the page's main world would be blocked. Keep all logic in the content script; never inject page-context script tags.
5. Ride the Theme Editor where possible. A Canvas admin already controls --ic-brand-* CSS custom properties (primary color, global nav background, link color, font colors) plus account-level custom CSS/JS uploads. A skin that reads and layers on those variables survives a school rebrand instead of fighting it. (Confidence: likely — I verified the CSP code paths here, not the current --ic-brand-* variable list.)

Out of scope for this check, flagged not verified: the legacy-ERB vs React/InstUI markup split and which Canvas pages have hashed InstUI class names. I did not examine app/views/*.erb or ui/features this pass. Treat any selector list you have as unverified until someone actually reads those directories.

### Evidence

- VERIFIED (live headers, 2026-09-03, curl): canvas.dartmouth.edu/login/canvas -> `content-security-policy: frame-ancestors 'self' canvas.dartmouth.edu dartmouth.instructure.com dartmouth.beta.instructure.com dartmouth.test.instructure.com dartmouth2.instructure.com dartmouth2.beta.instructure.com dartmouth2.test.instructure.com;` — that is the entire header. No font-src, no default-src, no style-src.
- VERIFIED (live headers): canvas.harvard.edu -> `frame-ancestors 'self' canvas.harvard.edu harvard.instructure.com harvard.beta.instructure.com harvard.test.instructure.com;`. canvas.ubc.ca -> same shape. Three independent production instances, all frame-ancestors-only. (canvas.instructure.com itself returned 503 to curl — bot/geo block, not a CSP signal.)
- VERIFIED (canvas-lms source, app/controllers/application_controller.rb, set_response_headers): `directives = "frame-ancestors 'self' #{csp_frame_ancestors&.uniq&.join(\" \")};"` then `append_to_header("Content-Security-Policy", directives)`. This is the always-on path and it emits frame-ancestors only.
- VERIFIED (canvas-lms source, app/helpers/application_helper.rb, add_csp_for_root): `return unless csp_enabled?` ... `directives = "frame-src 'self' blob: rldb: #{allow_list_domains(include_tools: true)}; "` + `default_csp_logging_directives`. The opt-in header carries frame-src, and (via csp_iframe_attribute) script-src and object-src. font-src is absent and does not inherit from any of these.
- VERIFIED (canvas-lms source): `def csp_enabled?; csp_context&.root_account&.feature_enabled?(:javascript_csp); end` and `def csp_enforced?; csp_enabled? && csp_context.csp_enabled?; end`. Two gates: an account feature flag AND an account/course toggle. Off by default.
- VERIFIED (canvas-lms source, default_csp_logging_directives): gated on a SECOND flag, `feature_enabled?(:default_source_csp_logging)`. Only then does `default-src 'self' 'unsafe-inline' data: blob: #{allow_list_domains};` appear. Note `data:` is explicitly allowed there — so even this worst case permits a base64-inlined font.
- VERIFIED (Instructure Admin Guide, 'How do I manage the Content Security Policy for an account?'): the Security tab 'only displays in Account Settings if you have enabled the Content Security Policy feature option', and CSP is described as a way to 'restrict custom JavaScript that runs in your instance of Canvas'. Confirms opt-in and JS-scoped intent, matching the source.
- VERIFIED (Chromium main, chrome/common/chrome_content_client.cc, ChromeContentClient::AddAdditionalSchemes): `schemes->csp_bypassing_schemes.push_back(extensions::kExtensionScheme);` under `#if BUILDFLAG(ENABLE_EXTENSIONS_CORE)`.
- VERIFIED (Chromium main, third_party/blink/renderer/platform/weborigin/scheme_registry.cc): `for (auto& scheme : url::GetCSPBypassingSchemes()) { content_security_policy_bypassing_schemes.insert(String(scheme), SchemeRegistry::kPolicyAreaAll); }` — kPolicyAreaAll, so the bypass covers font-src, not just script/style.
- VERIFIED (Chromium main, blink content_security_policy.cc): `ContentSecurityPolicy::ShouldBypassContentSecurityPolicy` delegates to `SchemeRegistry::SchemeShouldBypassContentSecurityPolicy(url.Protocol(), area)`. This is the code path that makes chrome-extension:// font URLs immune to a page font-src.
- VERIFIED (same file): `ShouldBypassMainWorldDeprecated(const DOMWrapperWorld* world)` returns true only when `world->IsIsolatedWorld()` AND `IsolatedWorldCSP::Get().HasContentSecurityPolicy(world->GetWorldId())`. The isolated-world exemption is tied to the content script's own execution context, not to DOM nodes it leaves behind in the page.
- VERIFIED (developer.chrome.com, Content scripts): content scripts run under `script-src 'self' 'wasm-unsafe-eval' 'inline-speculation-rules' chrome-extension://[id]/; object-src 'self';` and 'When a content script is injected into the main world, the CSP of the page applies.' Also: 'All assets must be declared as web accessible resources in the manifest.json file' for CSS, fonts, and images.
- VERIFIED (Chromium extensions/docs/security_faq.md): 'Extensions are considered more privileged than the web pages they are allowed to run on. As such, they are allowed to circumvent restrictions put in place by those web pages.'
- LIKELY (MDN, WebExtensions Content Security Policy): 'In Chrome, many DOM APIs are covered by the extension CSP instead of the web page's CSP (crbug 896041).' Secondary, and it is a known Chrome deviation, not a rule to build on.
- REFUTES-THE-REFUTATION, noted honestly (DebugBear, secondary): extension-injected stylesheets on CSP-heavy sites do commonly succeed while the https:// fonts they reference get blocked. That is real Chrome behavior — it just does not apply to Canvas, which sends no font-src.

## Verdict 5 — REFUTED (confidence: high)

**Claim tested.** All seven legacy selectors (.ic-DashboardCard, #grades_summary, .context_module, .ig-row, #section-tabs, .fc-event, .student_assignment) are still present in current Canvas as of 2025/2026 and have not been rewritten.

### What is actually true

SPLIT VERDICT. The first half of the claim survives: all seven selectors exist in canvas-lms master today, and I found each one in primary source. The second half — "have not been rewritten" — is FALSE. Two of the seven sit on pages Instructure has already rewritten in React, with the rewrite shipped behind hidden feature flags that a school admin does not control and cannot see. One of them (#grades_summary / .student_assignment) is ALREADY dead today for any course with restrict_quantitative_data enabled, with no flag flip needed.

PER-SELECTOR VERDICT (all "verified" = read in canvas-lms master source unless noted):

1. .ic-DashboardCard — SAFE. verified.
   Legacy skeleton: app/views/shared/_dashboard_card.html.erb (`<div class="ic-DashboardCard__box">`, `<div class="ic-DashboardCard">`).
   Live React: ui/shared/dashboard-card/react/DashboardCard.tsx emits STABLE BEM strings, not hashed — line 312 `className="ic-DashboardCard"`, plus __header, __header_hero, __header-title, __header-subtitle, __header-term, __link, __action-container. This is React that deliberately keeps hand-written classes.
   Styles: app/stylesheets/bundles/dashboard_card.scss. Reused by K5 (ui/features/k5_dashboard/react/HomeroomPage.jsx).
   Caveat: an `unpublished_courses_redesign` body class adds variant rules; `dashboard_graphql_integration` changes the data fetch, not the markup.

2. #grades_summary — HIGH RISK, PARTLY ALREADY GONE. verified.
   app/views/gradebooks/grade_summary.html.erb line 145 has `<table id="grades_summary" class="... ic-Table ic-Table--hover-row ...">`.
   BUT line 139 gates it: `<% if Account.site_admin.feature_enabled?(:student_grade_summary_upgrade) || @context.restrict_quantitative_data?(@current_user) %>` → renders `<div id="grade-summary-react"></div>` and NOTHING else. Flag def (config/feature_flags/…): `student_grade_summary_upgrade: state: hidden, applies_to: SiteAdmin, display_name: "Update grade summary table to use a modern framework"`.
   So the table vanishes on two independent triggers, and one of them (restrict_quantitative_data, a normal course/account setting) is live in production right now at some schools.

3. .context_module — SURVIVES BOTH GENERATIONS, but its children do not. verified.
   Legacy: app/views/context_modules/_context_module_next.html.erb line 33 `class="item-group-condensed context_module ..."`.
   React v2: ui/features/context_modules_v2/react/componentsTeacher/Module.tsx line 111 `className={`context_module module_${id} ${isExpanded ? 'expanded' : 'collapsed'}`}` and line 112 `id={`context_module_${id}`}`. ModuleItem.tsx lines 114-115 keep `id={`context_module_item_${_id}`}` / `className="context_module_item"`.
   Gate: app/models/course.rb:4928 `use_modules_rewrite_view?` → root_account flag `modules_page_rewrite` (teacher) or course flag `modules_page_rewrite_student_view` (student), both `state: hidden` in config/feature_flags/learning_foundations_release_flags.yml. On the v2 path app/controllers/context_modules_controller.rb:385 does `render html: ""` — the ERB body is EMPTY and React mounts everything. So `.context_module` is a rare stable survivor, but it is an InstUI `<View>` wrapper whose entire interior is InstUI-generated.

4. .ig-row — MIXED. verified.
   Defined app/stylesheets/components/_item-groups.scss:112 (`.ig-list .ig-row`), plus _item-groups-condensed.scss.
   Emitted by (full 38-hit search): assignments index Backbone handlebars (ui/features/assignment_index/jst/AssignmentListItem.handlebars, AssignmentGroupList.handlebars, backbone/views/AssignmentListItemView.jsx), quizzes index (ui/features/quizzes_index/jst/QuizItemView.handlebars, QuizItemGroupView.handlebars), modules item rows (app/views/context_modules/_module_item_next.html.erb, _module_item_conditional_next.html.erb), conferences, mastery paths, epub exports.
   NOT emitted by the discussions index or the pages index — both absent from the complete search result. Do not assume .ig-row covers those.
   Dies on the modules page under modules_page_rewrite; survives on assignments and quizzes.

5. #section-tabs — SAFE TODAY. verified.
   app/helpers/section_tab_helper.rb line 74 `content_tag(:ul, id: "section-tabs")`, rendered by app/views/layouts/application.html.erb line 236 inside `<div id="left-side">`, with sibling ids `#section-tabs-header-subtitle`. Styled in app/stylesheets/base/_ic_app_layout.scss and components/_components.scss. Per-tab `<a>` classes come from `SectionTabHelper#a_classes` = the tab's css_class downcased with whitespace→dash (so `.assignments`, `.modules`, `.grades` etc.).
   Unverified risk: an `instui_nav` flag exists (`state: hidden, applies_to: RootAccount, "New InstUI navbar being implemented with react router in mind"`) and ui/shared/top-navigation/react/hooks/useToggleCourseNav.ts references section-tabs. I could NOT confirm whether instui_nav replaces the course nav `<ul>` or only the global top bar. Treat as unknown, not as safe.

6. .fc-event — SAFE, on borrowed time. verified.
   package.json line 149 pins `"fullcalendar": "3.10.5"`. FullCalendar v3 emits `.fc-event`. Canvas styles it in app/stylesheets/jst/calendar/calendarApp.scss and bundles/agenda_view.scss; used in ui/features/calendar/jquery/index.js, MiniCalendar.js, UndatedEventsList.js.
   FC 3.10.5 is end-of-life (final v3 release, 2019). If Instructure upgrades to FC 6, `.fc-event` itself survives but every wrapper around it changes (`.fc-daygrid-event`, `.fc-event-main`, `.fc-event-title`), so anything you target INSIDE the event breaks.

7. .student_assignment — HIGH RISK, same fate as #grades_summary. verified.
   app/presenters/grade_summary_assignment_presenter.rb lines 189-197: `classes = ["student_assignment"]` then appends assignment_graded / special_class / excused / extended / has_sub_assignments. Applied at grade_summary.html.erb line 172 `<tr class="<%= assignment_presenter.classes %>">`. Also on the sidebar totals (lines 39, 43: `class="student_assignment final_grade"`).
   Sits inside the same feature-flagged block as #grades_summary, so it disappears under the same two triggers.

TWO-GENERATION MAP (the thing that decides whether a skin holds):
LEGACY, stable hand-written classes, safe to target deeply — Dashboard cards, course nav (#section-tabs), Calendar (FC3), Assignments index (.ig-row), Quizzes index (.ig-row), Modules on the default path.
FLAGGED FOR REACT/InstUI, hashed classes inside, only the outer hook is stable — Modules under modules_page_rewrite (outer .context_module / .context_module_item survive, everything inside is InstUI), Student Grades under student_grade_summary_upgrade or restrict_quantitative_data (NOTHING survives — the whole table is replaced by a bare `<div id="grade-summary-react">`).
InstUI hashed class names look like `css-1x2y3z-view-flexItem`. They change on every InstUI version bump. Never target them.

THEME EDITOR — ride this, it is real CSS custom properties, not SASS-only. verified.
lib/brandable_css.rb lines 205-209: `all_brand_variable_values_as_css` emits literally `:root { --ic-brand-primary: #2B7ABC; ... }`. app/stylesheets/base/_variables.scss consumes them via `var(--ic-brand-font-color-dark)` etc. Full variable list in app/stylesheets/brandable_variables.json — includes --ic-brand-primary, --ic-brand-font-color-dark, --ic-link-color, --ic-brand-button--primary-bgd/-text, --ic-brand-button--secondary-bgd, --ic-brand-global-nav-bgd, --ic-brand-global-nav-menu-item__text-color(--active), --ic-brand-global-nav-ic-icon-svg-fill(--active), --ic-brand-global-nav-avatar-border, --ic-brand-watermark, --ic-brand-favicon, plus the Login/Discovery/Registration groups.
A skin that overrides these on :root recolors global nav, buttons, and links across BOTH generations at once, including InstUI-hashed components, without touching a single class name. That is the only structure-proof lever available.

### Consequence for the skin

Do not ship one flat stylesheet that assumes all seven hooks hold. Tier the skin by page, and make it fail soft.

TIER A, safe to style deeply (stable hand-written classes, both generations): Dashboard (.ic-DashboardCard and its __ children), course nav (#section-tabs and the per-tab .assignments/.modules/.grades link classes), Calendar (.fc-event, but only the event box itself — not its interior, FC3 is EOL), Assignments index and Quizzes index (.ig-row, .ig-header, .ig-list).

TIER B, style the outer box only: Modules. .context_module and .context_module_item survive the React rewrite by design, so a border, background, radius, or spacing rule on those holds on both paths. Anything targeting the interior (.ig-row inside a module, .item-group-condensed, publish icons) works today and dies the moment modules_page_rewrite flips. Write those rules so their absence is invisible, not so their absence leaves a half-styled page.

TIER C, treat as already broken: Student Grades. #grades_summary and .student_assignment are gone right now for any course with restrict_quantitative_data on, and gone for everyone when student_grade_summary_upgrade flips. Detect `#grade-summary-react` first; if it is present, skip the grades rules entirely and fall back to the brand-variable layer. Do not let the skin render a table style over a React grid.

Never target InstUI hashed classes (css-1x2y3z-view). They change on every InstUI bump and are the majority of the DOM on every rewritten page.

Ride the Theme Editor variables as the base layer. Overriding --ic-brand-primary, --ic-link-color, --ic-brand-button--primary-bgd/--text, and the --ic-brand-global-nav-* set on :root recolors legacy AND InstUI components at once, survives every rewrite above, and costs zero selectors. Build the skin as: brand variables for all color, then a thin per-page layer for layout and shape, guarded by a presence check for the React mount points (#grade-summary-react, and the empty-body signature on Modules v2).

Add a cheap runtime canary: on each page, assert the expected hook exists before applying its rules, and log/no-op when it does not. Two of your seven anchors are on pages Instructure is actively replacing, and the flags that swap them are invisible to the user.

### Evidence

- VERIFIED — app/views/gradebooks/grade_summary.html.erb line 139-141: `<% if Account.site_admin.feature_enabled?(:student_grade_summary_upgrade) || @context.restrict_quantitative_data?(@current_user) %>` then `<div id="grade-summary-react"></div>` — the #grades_summary table is skipped entirely on that branch.
- VERIFIED — app/views/gradebooks/grade_summary.html.erb line 145: `id="grades_summary"` with class `ic-Table ic-Table--hover-row`, and line 172 `<tr class="<%= assignment_presenter.classes %>"`.
- VERIFIED — app/presenters/grade_summary_assignment_presenter.rb:189-197: `def classes; classes = ["student_assignment"]; classes << "assignment_graded" if graded?; classes << special_class; ...` confirms .student_assignment is on every row.
- VERIFIED — feature flag def: `student_grade_summary_upgrade: state: hidden, display_name: Update grade summary table to use a modern framework, applies_to: SiteAdmin`.
- VERIFIED — ui/shared/dashboard-card/react/DashboardCard.tsx line 312 `className="ic-DashboardCard"`, line 317 `ic-DashboardCard__header`, 331 `ic-DashboardCard__link`, 334 `ic-DashboardCard__header-title ellipsis`, 372 `ic-DashboardCard__action-container`. Stable BEM in React, not hashed.
- VERIFIED — app/views/shared/_dashboard_card.html.erb: `<div class="ic-DashboardCard__box">` and `<div class="ic-DashboardCard">` placeholder skeleton still shipped.
- VERIFIED — ui/features/context_modules_v2/react/componentsTeacher/Module.tsx line 111: className={`context_module module_${id} ${isExpanded ? 'expanded' : 'collapsed'}`}, line 112 id={`context_module_${id}`} — on an InstUI <View>. The React rewrite deliberately preserves .context_module.
- VERIFIED — ui/features/context_modules_v2/react/componentsTeacher/ModuleItem.tsx lines 114-115: id={`context_module_item_${_id}`} className="context_module_item".
- VERIFIED — app/models/course.rb:4928-4936 `def use_modules_rewrite_view?(user, session)` → `root_account.feature_enabled?(:modules_page_rewrite)` for admins, `feature_enabled?(:modules_page_rewrite_student_view)` for students.
- VERIFIED — app/controllers/context_modules_controller.rb lines 382-390: v2 branch does `js_bundle :context_modules_v2` then `render html: "", layout: true`; the else branch does `js_bundle :context_modules` and `render stream:`. On v2 the ERB body is empty, so all legacy inner markup is absent.
- VERIFIED — config/feature_flags/learning_foundations_release_flags.yml: `modules_page_rewrite: state: hidden, display_name: Modules Page Rewrite Teacher View, applies_to: RootAccount` and `modules_page_rewrite_student_view: state: hidden, applies_to: Course`.
- VERIFIED — app/views/context_modules/_context_module_next.html.erb line 33: `class="item-group-condensed context_module` (legacy path still ships).
- VERIFIED — app/stylesheets/components/_item-groups.scss line 112 `.ig-list .ig-row`, line 83 `.ig-list`, line 47 `.ig-header`, line 93 `.ig-row__layout`, line 166 `&.ig-row-empty`.
- VERIFIED — full 38-result code search for "ig-row" in canvas-lms: emitted by ui/features/assignment_index/jst/AssignmentListItem.handlebars, ui/features/quizzes_index/jst/QuizItemView.handlebars, app/views/context_modules/_module_item_next.html.erb, ui/features/conferences/jst/*.handlebars. NO hit in discussion_topics_index or wiki_page_index — .ig-row does not cover Discussions or Pages.
- VERIFIED — app/helpers/section_tab_helper.rb line 74: `content_tag(:ul, id: "section-tabs") do`; line 184 `def a_classes` = `[@tab.css_class.downcase.replace_whitespace("-")]`; line 283 `content_tag(:li, a_tag, { class: li_classes })`.
- VERIFIED — app/views/layouts/application.html.erb line 222 `<div id="left-side"`, line 234 `<span id="section-tabs-header-subtitle">`, line 236 `<%= section_tabs %>`.
- VERIFIED — package.json line 149: `"fullcalendar": "3.10.5"` — FullCalendar v3, which emits .fc-event. Styled in app/stylesheets/jst/calendar/calendarApp.scss and app/stylesheets/bundles/agenda_view.scss; consumed in ui/features/calendar/jquery/index.js.
- VERIFIED — lib/brandable_css.rb lines 205-209: `def all_brand_variable_values_as_css` returns `":root {" + values.map { |k, v| "--#{k}: #{v};" } + "}"`. Canvas emits genuine CSS custom properties from the Theme Editor.
- VERIFIED — app/stylesheets/base/_variables.scss lines 279, 285, 291, 303: `$ic-font-color-dark: var(--ic-brand-font-color-dark);`, `var(--ic-brand-font-color-dark-lightened-15)`, etc. — the SCSS consumes the runtime custom properties.
- VERIFIED — app/stylesheets/brandable_variables.json: --ic-brand-primary (#2B7ABC), --ic-link-color (#0E68B3), --ic-brand-button--primary-bgd, --ic-brand-global-nav-bgd (#334451), --ic-brand-global-nav-menu-item__text-color, --ic-brand-global-nav-ic-icon-svg-fill--active, --ic-brand-watermark, --ic-brand-favicon, plus Login/Discovery/Registration groups.
- VERIFIED — feature flag `instui_nav: state: hidden, applies_to: RootAccount, description: This is a new navbar being implemented with react router in mind`; and `instui_header: state: hidden, applies_to: SiteAdmin, If enabled, pages will use the new InstUI headers`. app/views/context_modules/_content_next.html.erb line 42 already branches on instui_header.
- UNVERIFIED — whether Instructure has enabled modules_page_rewrite, student_grade_summary_upgrade, or instui_nav on production/beta for any real tenant. All three are `state: hidden`, meaning off by default and flippable only by Instructure or a site admin, but I found no release-note evidence either way. Do not read 'hidden' as 'not shipping'.
- UNVERIFIED — whether instui_nav replaces the #section-tabs course nav <ul> or only the global top bar. ui/shared/top-navigation/react/hooks/useToggleCourseNav.ts references section-tabs, which is suggestive but not proof.
- METHOD NOTE — GitHub anonymous code search and api.github.com both 403; all results above come from authenticated `gh api search/code` plus raw.githubusercontent.com reads of instructure/canvas-lms master. No blog posts or secondary sources were used.

