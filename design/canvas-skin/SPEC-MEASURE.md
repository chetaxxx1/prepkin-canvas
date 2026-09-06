# Measure — a Canvas skin specification

Prepkin Canvas extension · slot 2 · 2026-09-04
Renamed from the concept working title "Margin Notes". Every occurrence of the old name is gone.

---

## 1. The idea

Canvas is not ugly, it is undifferentiated. Fourteen-pixel semibold grey on white, boxes nested inside boxes, and every item on a thirty-row Modules page carrying identical weight, so nothing on the screen tells a student what to read first or what is due. Every other direction in this batch fixes that by adding a colour, a chip, a card, or a character. Measure fixes it by removing, and then spends the entire remaining budget on the two things a printed book solved centuries ago: a real hierarchy and a real alignment grid. It grounds Canvas on paper, replaces every box with a 1px hairline, sets one column of readable text on teacher-written pages, and drops every due date in the product into the same right-hand strip of tabular figures. It sets no `font-family` at all by default, which means it cannot be got wrong under OpenDyslexic, cannot flash a relayout on load, and does not look modded on a screen-share. Its worst case really is Canvas with the volume turned down, which is what keeps an extension off a district block list.

**The signature move.** Every due date is right-aligned into one 8.5rem cell of tabular figures so thirty of them stack into a single strip you read straight down, and the thing that tells you where you are — the module header on Modules, the title-and-due block on an assignment — sticks to the top of the viewport instead of scrolling away.

### 1.1 The risk this spec has to answer first

The selection decision named it: **the reading page may land on a surface nobody reads.** The long reading a student does in a course is often a PDF inside Canvadocs or a Google Doc, so a beautifully set assignment page can be a twenty-second waypoint. If that is true, the prose investment buys a rounding error.

Three responses, in order of honesty:

1. **`.user_content` is six surfaces, not one.** Assignment detail (daily), course home front page (daily), Pages (weekly), Syllabus (weekly), Discussion prompt bodies (weekly), classic Quiz question text (weekly). It is not a single page bet.
2. **The PDF is reachable, but not by typography.** Per RESEARCH.md correction 1, Canvadocs and DocViewer are reachable with `https://*.instructure.com/*` + `https://*.inscloudgate.net/*` and `all_frames: true`. Measure ships a frame pass, but a rendered PDF page is a canvas: Lamp reaches inside it, the measure and the hierarchy cannot. State that split in the product. **Lamp reaches the PDF. Measure's typography does not.**
3. **The falsifiable test, and the number that kills it.** No analytics ship (constraint 11). Instead, a one-week manual observation at the pilot school: median seconds per student per day on `/assignments/:id` + `/pages/*` versus seconds inside a `#tool_content` or Canvadocs frame. **If the reading pages come in under 90 seconds a day median, the prose block ships as written and gets no further investment**, and the whole remaining budget moves to the due column, the sticky heads and Lamp.

What survives if the test fails: the measure, the hierarchy, the hairlines, the tabular figures, the due column, the sticky heads, and Lamp. That is the informational half, it is what all three judges scored highest, and it is what ships in week one regardless.

---

## 2. Tokens

### 2.1 Why the names are `--pk-m-*`

The panel already declares 27 `--pk-*` tokens on `.prepkin-cards, #prepkin-buddy`, and `looks.js#lookVars()` writes five of them **inline on `<html>`**, which beats any class rule. If Measure reused `--pk-page` or `--pk-text-2`, wearing Woodland would set a green page against cream hairlines with none of the verified contrast holding (shipped bugs 9 and 10). Measure's page tokens are namespaced `--pk-m-*` so they cannot collide with the panel's set, and a Look **swaps a class, never writes inline**.

### 2.2 The palette

Thirteen tokens. Every one is declared **in full** on `html.pk-m-paper` **and in full** on `html.pk-m-lamp`, so no pair of popup toggles can leave a `var()` unresolved (shipped bug 3).

| Token | Paper | Lamp | Contrast (fg on ground) | Role |
|---|---|---|---|---|
| `--pk-m-page` | `#F3F0E7` | `#181614` | ground | The paper. Under every page, course menu, sidebar, table and sticky head. |
| `--pk-m-sheet` | `#FBFAF6` | `#211E1A` | 1.09:1 vs page (both) | The sheet. The only raised surface: card face, table body, code blocks. Never pure white. |
| `--pk-m-rule` | `#DDD6C7` | `#2E2A24` | 1.27:1 vs page (both) | The hairline. Every 1px border in the skin. Replaces every box. |
| `--pk-m-rule-strong` | `#B5AB95` | `#453F36` | 2.00:1 / 1.73:1 vs page | The one 2px rule. Four uses only: module head underline, grade total, blockquote margin, today's date in Planner. Never a sole information carrier. |
| `--pk-m-text` | `#22201C` | `#DDD6C7` | **14.27:1 / 12.48:1** on page | Body ink. Lamp is deliberately under pure white's 18.05:1 — halation, not contrast maximisation, is complaint #2. |
| `--pk-m-text-2` | `#6B6355` | `#9A9184` | **5.20:1 / 5.81:1** on page; 4.58 / 4.83 on `--pk-m-select` | Marginal ink. Due dates, points, captions, small-caps labels. AA at body size on every ground it touches. |
| `--pk-m-link` | `#2C4A6E` | `#9EBEE0` | **7.97:1 / 9.36:1** on page | Link ink. Always underlined, never a button. |
| `--pk-m-link-visited` | `#5A4A72` | `#B6A6CC` | **6.94:1 / 8.00:1** on page | Visited. A book's index tells you where you have been. Canvas does not. |
| `--pk-m-amber-text` | `#8A5A16` | `#D9A85C` | **5.18:1 / 8.34:1** on page; 4.56 on select | "Still counts": due soon and late. Ink only, never a fill, never red. |
| `--pk-m-amber-rule` | `#A87C2E` | `#8A6A2E` | **3.30:1 / 3.59:1** on page | The 2px left rule on a due-soon row. Raised from the concept's `#C8A25E` (2.10:1) so it clears the 3:1 non-text threshold on its own. |
| `--pk-m-select` | `#E7E2D3` | `#2A2621` | 1.14:1 / 1.20:1 vs page | Row hover and `::selection`. A paper tint. There is no hover lift anywhere in this skin. |
| `--pk-m-focus` | `#2C4A6E` | `#9EBEE0` | 7.97:1 / 9.36:1 on page | 2px focus ring at 2px offset. Never removed, restated everywhere because the grounds moved. |
| `--pk-m-seam` | `#B5AB95` | `#453F36` | see §6 | The 1px rule and caption around anything Measure cannot reach. |

**Deleted from the concept:** `--pk-text-3`. At 2.95:1 it failed AA at body size, it was declared with a comment saying never to use it, and that is a landmine for whoever edits this in six months. The page runs on two ink tones by rule.

**Measured cost of a non-white ground, stated plainly.** `L(#FFFFFF) = 1.0000`, `L(#F3F0E7) = 0.8714`. A foreground colour that sits at exactly **4.50:1 on white lands at 3.95:1 on Paper**. This is inherent to every non-white ground and no cream avoids it (at `#FBF9F4`, near-white, it is still 4.28:1). Two mitigations, both structural:

- Measure re-declares the ink on every text node it grounds, so the penalty only reaches text the skin does not touch.
- **Measure never grounds a surface it cannot also re-ink.** Files v2, InstUI headers and tray interiors keep their stock ground rather than being painted cream with stranded text.

That second rule is why `--pk-m-sheet` is near-white on purpose: stock `#FFFFFF` is **1.14:1** off the Paper ground and our own sheet is **1.09:1**. The surfaces we cannot reach read as sheets on the paper, not as holes. In Lamp they are holes, and §6 handles that.

### 2.3 Type

**No `font-family` is set anywhere by default.** This is graft 2 and it is load-bearing:

- Content scripts run in an isolated world and cannot read `window.ENV` (verdict 1), so `ENV.use_dyslexic_font === true` is not directly readable from where this skin runs. Not writing the property is the only implementation of constraint 7 that cannot be got wrong.
- A `font-family` rule applied after first paint guarantees a visible relayout on every navigation, from Canvas's 14px sans at 1,100px to serif 17px at 34rem. A colour-only skin flashes a tint. That one would flash a reflow.
- The typographic argument is about size, weight, line-height, case, tracking and measure. None of those need a face change.

**The serif is one opt-in popup checkbox**, "Book type on reading pages", default **off**. When it is on, and only after the OpenDyslexic probe in §9.2 comes back clean, the class `pk-m-serif` is added to `<html>` and exactly one declaration ships:

```css
html.pk-m-serif .user_content,
html.pk-m-serif #content > h1 {
  font-family: ui-serif, "Iowan Old Style", Charter, Georgia, "Times New Roman", serif;
}
```

Two other stacks are declared for reference and are **only** used inside the serif class or on code:

- UI: `system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`
- Mono: `ui-monospace, SFMono-Regular, Menlo, Consolas, monospace` (applied to `.user_content code, .user_content pre` in both modes, because a monospace code block is not a style choice)

Zero network requests. No `@font-face`, no CDN, no Google Fonts, in any mode (constraint 11).

**Weights: 400 / 500 / 600 only.** Nothing on a Canvas page goes above 600. This is the direct refusal of "everything at 14px semibold" and of the panel's own 800/900 scale.

| Role | Size | Line-height | Weight | Case / tracking |
|---|---|---|---|---|
| Prose body | 1.0625rem (17px) | `var(--pk-m-prose-lead)` = 1.62 default | 400 | — |
| Page `h1` (`#content > h1`) | 1.5rem | 1.25 | 600 | — |
| Prose `h2` | 1.25rem | 1.3 | 600 | 2rem above, 0.5rem below |
| Prose `h3` | 0.9375rem | 1.35 | 600 | uppercase, 0.08em |
| Prose `h4` | 0.9375rem | 1.35 | 600 | — |
| Module title | 1.125rem | 1.3 | 600 | — |
| UI row title | 0.9375rem | 1.4 | 500 | — |
| Marginalia (dates, points, captions) | 0.75rem | 1.45 | 500 | — |
| Small-caps label (section heads, crumbs, nav) | 0.6875rem | 1.3 | 500 | uppercase, 0.09em |
| Figure row (grades, min/max/median) | 0.8125rem | 1.4 | 500 | tabular |

**Measure.** Prose 34rem (~66 characters at 17px). List rows 64rem. Nothing else is clamped.

**Figures.** `font-variant-numeric: tabular-nums lining-nums` is set once on `#content` and inherits. Every date, point value, grade and count is monospaced-width, so columns align without a table. This is what makes the due strip work.

### 2.4 Shape, borders, shadows, spacing

| Property | Value | Notes |
|---|---|---|
| `--pk-m-radius` | `2px` | The entire radius set. **No 999px pill exists anywhere on a Canvas page.** |
| Border | `1px solid var(--pk-m-rule)` | The only border in the skin. |
| Heavy rule | `2px solid var(--pk-m-rule-strong)` | Exactly four uses (§2.2). |
| `box-shadow` | `none`, shipped explicitly on `.ic-DashboardCard` and `.ig-list` | One exception, §9.5. |
| Gradients | none | One exception: the Gridded look's page texture (§10). |
| Base unit | 4px | |
| Grid column gap | 16px | |
| Prose rhythm | 27.5px (one prose line at 17px/1.62) | |

**Density dial (graft 3).** Three steps on `<html>`, one axis, zero semantics changed.

| Token | Compact | Normal (default) | Roomy |
|---|---|---|---|
| `--pk-m-row-pad` | 6px | 9px | 13px |
| `--pk-m-block` | 18px | 24px | 32px |
| `--pk-m-section` | 32px | 40px | 52px |
| `--pk-m-prose-lead` | 1.55 | 1.62 | 1.75 |
| Resulting list-row height | ~33px | ~39px | ~47px |

Roomy clears the 44px touch target. Normal matches Canvas's own row height. Compact is below it, which is why Compact is the coin-earned step and Roomy is free (§10), and why **Compact is disabled under `@media (pointer: coarse)`** and falls back to Normal.

**Motion.** The skin adds none. No transitions, no transforms, no animations, no keyframes. Its `prefers-reduced-motion` block therefore has a different job, described in §8.

---

## 3. The base layer: `--ic-brand-*`

Written **inline on `document.documentElement.style`**, not as a `:root` rule. Custom properties honour `!important` and Canvas's own brand stylesheet sets the same names on `:root` at equal specificity, so injection order alone is not safe (§4.2 rule 1). An inline custom property wins outright and sidesteps the `!important` question entirely. Every write happens **after** reading `getComputedStyle(document.documentElement)`, and the skin records what it wrote so switching off removes exactly what it added and nothing the school put there.

### 3.1 Overridden, both modes

| Variable | Paper | Lamp | Why |
|---|---|---|---|
| `--ic-link-color` | `#2C4A6E` | `#9EBEE0` | Canvas's default `#0374B5` is 4.42:1 on our paper. Ours is 7.97:1. One variable carries the ink to every place Canvas SCSS reads `$linkColor`. |
| `--ic-link-color-darkened-10` | `#1D314A` (11.59:1) | derived +10% L | Canvas computes derivatives server-side from the original. Overriding only the base leaves hover in the school's blue. |
| `--ic-link-color-lightened-10` | `#3B6392` (5.44:1) | derived −10% L | Same reason. |
| `--ic-brand-font-color-dark` | `#22201C` | `#DDD6C7` | Body ink through Canvas's own `$ic-font-color-dark`. |
| `--ic-brand-font-color-dark-lightened-15` | `#6B6355` | `#9A9184` | |
| `--ic-brand-font-color-dark-lightened-28` | `#6B6355` | `#9A9184` | Both derivatives collapse to the second ink tone. This is how "two ink tones by rule" is enforced through Canvas's own variables rather than by a rule of ours. |

There is **no** `--ic-brand-font-color-dark-lightened-30`. BetterCanvas references it six times and all six declarations are dead. Do not copy the name.

### 3.2 Overridden conditionally, Paper only

The school's rail is left completely alone in Paper. The single exception is the badge, and only when it fails two tests.

```
badge = getComputedStyle(root).getPropertyValue('--ic-brand-global-nav-menu-item__badge-bgd')
rail  = getComputedStyle(root).getPropertyValue('--ic-brand-global-nav-bgd')

isAlarmRed = hue(badge) in [340°,360°] ∪ [0°,20°]  AND  sat(badge) >= 40%  AND  light(badge) <= 60%
amberVisible = contrast('#8A5A16', rail) >= 3.0

if (isAlarmRed && amberVisible) {
  --ic-brand-global-nav-menu-item__badge-bgd  = #8A5A16
  --ic-brand-global-nav-menu-item__badge-text = #F3F0E7      // 5.18:1
}
// otherwise: leave Canvas's badge exactly as the school shipped it
```

Constraint 19 bans a red alarm **the skin draws**, not one the school already ships. The second gate is what stops an orange-branded school (Syracuse, Tennessee, Clemson) getting a badge that disappears into its own rail.

### 3.3 Overridden in Lamp only, by derivation

Six nav variables, derived from the school's own values, never replaced wholesale (constraint 4).

```
rail = computed --ic-brand-global-nav-bgd
if (lightness(rail) > 60%) → do nothing. Leave the rail alone entirely.
   (A light school rail plus --ic-brand-header-image is a logo designed for a light
    ground. We cannot recolour an image, so we do not darken the ground under it.
    The glare complaint stays partly unanswered for those schools. Say so.)
else:
   --ic-brand-global-nav-bgd                      = hsl(H(rail), S(rail), 12%)
   --ic-brand-global-nav-ic-icon-svg-fill         = #DDD6C7
   --ic-brand-global-nav-ic-icon-svg-fill--active = #DDD6C7
   --ic-brand-global-nav-menu-item__text-color    = #DDD6C7
   --ic-brand-global-nav-menu-item__badge-bgd     = #8A5A16   (if it passes §3.2)
   --ic-brand-global-nav-menu-item__badge-text    = #F3F0E7
   assert contrast(#DDD6C7, derivedRail) >= 4.5, else fall back to #F3F0E7
```

Worked example, Dartmouth green `#00693E` (H 155.4°, S 100%, L 20.6%) → `#003D24`. `#DDD6C7` on it measures **8.58:1**. The institution's hue survives, the glare does not.

### 3.4 Never touched, in any mode

`--ic-brand-primary` and its six computed derivatives. `--ic-brand-button--primary-bgd`, `--ic-brand-button--primary-text`, `--ic-brand-button--secondary-bgd`, `--ic-brand-button--secondary-text` and their four darkened derivatives. `--ic-brand-header-image`. `--ic-brand-global-nav-avatar-border`. `--ic-brand-watermark`, `--ic-brand-favicon`. All 16 `--ic-brand-Login-*` variables (the login page is excluded entirely; it is the school's identity surface and repainting it is what got BetterCampus blocked).

The four button variables are the whole of constraint 15 handled by construction. See §9.5.

**One honest regression.** `--ic-brand-primary` also drives `$ic-course-sidenav_list-item--active-font-color`. Canvas's default `#2B7ABC` measures 4.16:1 on white and **4.00:1 on our paper**. Measure removes the dependency by setting the active course-nav tab's colour explicitly to `--pk-m-text` (14.27:1), so this one instance is fixed rather than degraded. Every other place a school-brand colour lands on our ground is covered by the smoke check in §9.7, not by assumption.

---

## 4. Per page, Tier 1

Confidence labels are RESEARCH.md's own. Where the map does not state something, it says `unknown` and the guess is labelled as a guess.

### 4.1 Global left nav rail (every page)

**Before:** A 54px column of the school's brand colour with a red count badge and a slide-out label in mixed case. **After:** Identical in Paper, except the badge is amber if it was an alarm red and the labels are small-caps. In Lamp the rail drops to 12% lightness in the school's own hue with cream icons.

| Selector | Conf. |
|---|---|
| `#header.ic-app-header` | verified |
| `.ic-app-header__menu-list-link .menu-item__text` | verified |
| `li.ic-app-header__menu-list-item--active` | verified |
| `.menu-item__badge` | verified |
| `#skip_navigation_link` | verified |
| `#primaryNavToggle.ic-app-header__menu-list-link--nav-toggle` | verified |

**Moves.** `.menu-item__text` → 0.6875rem / 500 / uppercase / 0.09em. `li.ic-app-header__menu-list-item--active` → `box-shadow: inset -2px 0 0 0 currentColor` on the content edge, in the rail's own icon-fill colour, instead of a block fill. Brand vars per §3.2 and §3.3. **No `width`, no `display`, no `position`, ever** — the collapse toggle, the 54/84/104px states, `body.primary-nav-transitions` and the `.ic-Layout-wrapper` margin all keep working untouched (constraint 8).

**Degrades to.** Under `instui_nav` the whole header is deleted (`mountPoint.innerHTML = ''`), every `#global_nav_*` id and `.ic-app-header` class disappears, and these rules match nothing. The rail renders in the school's own theme, which is correct. Below 768px the rail is `display: none !important` and this block is dead weight. `#skip_navigation_link` is never selected and never obscured.

### 4.2 Breadcrumb bar

**Before:** Two competing clusters of 14px links separated by an SVG chevron image, on a white strip. **After:** One line of small-caps type on the paper ground under a single hairline, with a printed `/` separator and one fewer image request per page.

| Selector | Conf. |
|---|---|
| `.ic-app-nav-toggle-and-crumbs.no-print` | verified |
| `#breadcrumbs > ul > li` | verified |
| `#breadcrumbs > ul > li + li::before` | verified |
| `#breadcrumbs > ul > li > a .ellipsis` | verified |
| `.right-of-crumbs` | verified |
| `#courseMenuToggle.ic-app-course-nav-toggle` | verified |

**Moves.** Bar → `background: var(--pk-m-page); border-bottom: 1px solid var(--pk-m-rule); box-shadow: none`. Crumb text → 0.6875rem / 500 / uppercase / 0.08em in `--pk-m-text-2`; last crumb `--pk-m-text`. `li + li::before` → `background-image: none; content: '/'; color: var(--pk-m-text-2)`. `.right-of-crumbs` links → same small-caps size. `#courseMenuToggle` gets type only, no size or position.

**Degrades to.** Absent on the dashboard by design (`clear_crumbs`), hidden below 768px, replaced wholesale under `instui_topnav` — three clean misses. The `::before` override changes only `background-image` and `content`, so if Canvas changes the separator the worst case is a doubled mark. The first `li` stays `visibility: hidden`; we do not reclaim that gap, because doing so means fighting a deliberate Canvas rule.

### 4.3 Flash toasts and admin banners

**Before:** Four saturated full-bleed strips at the top of the page in Canvas's own semantic colours, at a size that outweighs the page content. **After:** The same four semantics at the same four colours, on the sheet, in a hairline box at 0.875rem, so a success toast stops shouting louder than the assignment underneath it.

| Selector | Conf. |
|---|---|
| `#flash_message_holder > div[class^='ic-flash-']` | verified — **match by prefix, do not enumerate** |
| `.flash-message-container` | verified |
| `#flash_message_holder`, `#flash_screenreader_holder` | verified |
| `#announcementWrapper > .ic-notification.ic-notification--admin-created.account_notification` | verified |
| `.ic-notification__icon`, `.ic-notification__content`, `h2.ic-notification__title` | verified |
| `.ic-notification + .ic-dashboard-app` | verified |

**Moves.** Toast → `border-radius: 2px; box-shadow: none; font-size: 0.875rem; line-height: 1.45`. Banner → `background: var(--pk-m-sheet); border: 1px solid var(--pk-m-rule); border-radius: 2px`, title at 0.9375rem / 600. **The four `ic-flash-*` semantic colours are not touched**, including error red: that is Canvas's own semantics and constraint 19 bans a red the skin draws, not one the platform already owns.

**Degrades to.** Toasts are injected at runtime, so all of this is static CSS with no query to miss. `span.notification_message` is `user_content(safe_html: true)` from an admin and we never assume structure inside it. The node is never removed or re-parented, because account notifications inline a `<script>` defining `showGlobalAlert()` and use an `onClick` attribute. The `.ic-notification + .ic-dashboard-app` adjacency rule means element order is preserved.

### 4.4 Dashboard, card view

**Before:** A ragged inline-block deck of 262px tiles, each with 146px of information-free colour on top and a 4px radius. **After:** An index. A real grid of entries separated by hairlines, the course colour reduced to a 3px bookmark tab, and the action badge as a superscript figure instead of a filled circle.

| Selector | Conf. |
|---|---|
| `#DashboardCard_Container` | verified |
| `.ic-DashboardCard__box > .ic-DashboardCard__box__container` | verified |
| `.ic-DashboardCard` | verified |
| `.ic-DashboardCard__header_hero` | verified |
| `.ic-DashboardCard__header_content` | verified |
| `.ic-DashboardCard__header-title` | verified (the outer element) |
| `.ic-DashboardCard__header-subtitle`, `.ic-DashboardCard__header-term` | verified |
| `nav.ic-DashboardCard__action-container` | verified |
| `.ic-DashboardCard__action-badge` | verified |
| `#dashboard_header_container.ic-Dashboard-header` | verified |
| `.ic-Dashboard-header__title` | **unverified — never selected** (shipped bug 11) |

**Moves.** Container → `display: grid; grid-template-columns: repeat(auto-fill, minmax(20rem, 1fr)); gap: 0; margin: 0; max-width: 64rem`. Card → `background: transparent; border-radius: 2px; box-shadow: none; width: auto; border-bottom: 1px solid var(--pk-m-rule)`, **no hover lift and no transition at all** (shipped bug 7 deleted rather than guarded). Hero → `height: 3px`, and **its `opacity` is never set** (shipped bug 1). Title → 0.9375rem / 500 on the outer element, and **the inner `<span>`'s `color` is never set** (shipped bug 2). Subtitle and term → 0.75rem `--pk-m-text-2`. Action nav → 1px rule above. Badge → drop the filled circle, render as a superscript tabular figure in `--pk-m-amber-text`, which is what a badge actually is. Header strip → paper ground, bottom hairline, `h1` styled **by element inside the verified container**, never via `.ic-Dashboard-header__title`.

**Degrades to.** If the container rule misses, cards stay Canvas's inline-block and every per-card rule still lands: a ragged grid of well-set entries, never a broken page. Both accessibility cues survive **by omission**, not by a condition. Under `widget_dashboard` the controller returns an empty body, every selector misses, and the page hands over to the panel. Drag-reorder writes inline `opacity: 0` on a card and nothing here fights it. Under `unpublished_courses_redesign` one container becomes two `.ic-DashboardCard__box` sections and the grid rule applies to each.

### 4.5 Dashboard, list view (Planner)

**Before:** A flat scroll of identical white cards with the date buried in each one. **After:** A daybook. Each day is a dated entry under a full-width rule, today carries the one 2px line, and rows are hairline-separated with the course colour as a 3px left rule.

| Selector | Conf. |
|---|---|
| `#dashboard-planner.StudentPlanner__Container` | verified |
| `div.PlannerApp` | verified |
| `body.dashboard-is-planner` | verified |
| `[data-testid='planner-item-raw']` | verified — **primary row hook** (shipped bug 4 fixed) |
| `[data-testid='day']`, `[data-testid='today-date']`, `[data-testid='not-today']` | verified |
| `[data-testid='planner-item-completed-checkbox']` | verified |
| `.Grouping-styles__items` | **likely** — read a colour from it, never position with it |
| `#planner-app-fixed-element` | verified — **listed only so it is never moved or removed** |
| `.PlannerItem-styles__*` | **disputed** — not used |

**Moves.** Day date line → 0.6875rem / 500 / uppercase / 0.09em on a full-width 1px rule. `[data-testid='today-date']` → 2px `--pk-m-rule-strong`. Row → `background: transparent !important; border: 0 !important; border-radius: 2px !important; box-shadow: none !important`, plus `border-bottom: 1px solid var(--pk-m-rule)` and `font-variant-numeric: tabular-nums`. Course colour read opportunistically from the inline `borderColor` on the grouping `<ol>` and re-emitted as a 3px left rule; when the class is gone the left rule falls back to `--pk-m-rule`.

**Cut from the concept:** the right-aligned time column. The engineer judge was right: `[data-testid='planner-item-raw']` is the only verified row hook, there is no verified hook for the due time, and reaching it means positioning by child order inside a React component. **The time column ships on Modules and the Assignments index only.** Planner gets tabular figures and the day rules, which is real and cheap.

**Degrades to.** Planner components inject their own `<style>` later in the document at equal specificity, so this block is written at `#dashboard-planner [data-testid=…]` specificity and uses `!important` on exactly four properties where that is not enough — `background`, `border`, `border-radius`, `box-shadow` — and on nothing else. If every testid churns, the view degrades to a plain list on the paper ground. Infinite scroll mounts and unmounts days constantly, which static CSS handles for free; only the colour read needs the observer.

**Not shipped, and why.** Making the invisible "Load prior dates" `ShowOnFocusButton` visible is a genuine fix. The map names the component and gives no selector, and we do not guess.

### 4.6 Right sidebar (To Do / Coming Up / Recent Feedback)

**Before:** Three boxed widgets where the due date — the thing the student is actually scanning for — is plain grey text buried after a bullet. **After:** The page's margin. A 1px left rule, small-caps section heads, hairline rows, and the due string set in tabular figures with due-soon carrying amber ink and a 2px left rule.

| Selector | Conf. |
|---|---|
| `#right-side-wrapper.ic-app-main-content__secondary` | verified |
| `aside#right-side` | verified |
| `.Sidebar__TodoListContainer` | verified |
| `[data-testid='ToDoSidebar'] > h2.todo-list-header` | verified |
| `.ToDoSidebarItem`, `__Info`, `__Title` | verified |
| `.events_list.coming_up ul.right-side-list.events > li.event` | verified |
| `.event-details`, `b.event-details__title` | verified |
| `.events_list.recent_feedback li.event a.recent_feedback_icon` | verified |
| `ul.right-side-list.to-do-list li.todo` | verified |
| `a.more_link` | verified — **not touched** |
| `.ic-sidebar-logo` | verified — **not touched, it is the school's** |

**Moves.** Wrapper → `background: transparent; border-left: 1px solid var(--pk-m-rule); padding-left: 24px` with `box-sizing: border-box` asserted, because the 288px width is layout math (§9.4). Section heads → 0.6875rem small-caps `--pk-m-text-2` over a full-width hairline. Rows → no box, two lines, hairline separated, title 0.8125rem / 500. `li.event > a > .event-details > p` — the "N points • due date" string the research calls the single highest-value change on the dashboard — → 0.75rem tabular. Due-soon → one JS-added class, `pk-m-soon`, giving `--pk-m-amber-text` on the date and a 2px `--pk-m-amber-rule` on the row's left edge. Recent Feedback grade → `strong` at 0.9375rem / 600 tabular, **never coloured**.

**How `pk-m-soon` is decided, without parsing a date.** The extension already syncs the real to-do list from Canvas's REST API into `chrome.storage.local` (`canvas.js`). Rows carry `a[href^='/courses/']` with the assignment id in the path. The class is applied by **joining on the href**, not by parsing a localised date string. Threshold: due within 48 hours, or past due. Zero locale risk, and it reuses infrastructure that already ships.

**Degrades to.** The sidebar starts empty, is filled by an XHR, then mutated again by React, so everything here is static CSS that applies whenever the nodes land, with no one-shot query to miss. Without the JS the date is still tabular-figure `--pk-m-text-2`, which is already better than stock. A student who also TAs a course gets the legacy `ul.right-side-list.to-do-list` markup, which inherits the same ground, type and hairlines from this block (constraint 14). Below 992px the column stacks under the content and the left rule is dropped by media query.

**Not shipped.** Auto-expanding `a.more_link`. Its hidden rows carry inline `display: none` written by Canvas and overriding that means `!important` against live JS to show information the student did not ask for.

### 4.7 Course navigation menu

**Before:** Eight to fourteen tabs of identical weight, active state marked by a thin blue border and bold. **After:** A table of contents. Hairlines between sections, a 2px ink rule on the active tab, and the five tabs a student almost never opens receding by **ink tone**, not by size.

| Selector | Conf. |
|---|---|
| `#left-side.ic-app-course-menu.ic-sticky-on.list-view` | verified |
| `#sticky-container.ic-sticky-frame` | verified |
| `ul#section-tabs`, `#section-tabs > li.section` | verified |
| `#section-tabs a.active`, `#section-tabs a[aria-current='page']` | verified |
| `#section-tabs a.outcomes / .rubrics / .collaborations / .conferences / .settings` | verified |
| `#section-tabs .nav-badge` | **likely** |
| `body.course-menu-expanded`, `body.with-left-side` | verified |
| `#section-tabs-header` | **guess — treat as absent, never styled** |
| `#modules-link`-style ids | verified **AVOID** — `a_id` is built from the localised label |
| `nav[aria-label='Courses Navigation Menu']` | verified **AVOID** — the label is `I18n.t` |

**Moves.** `#left-side` → paper ground, `border-right: 1px solid var(--pk-m-rule)`, `box-sizing: border-box`. Tabs → 0.8125rem / 500, `padding: var(--pk-m-row-pad) 0`, 1px `--pk-m-rule` between each `li.section`. Active → weight 600 plus `box-shadow: inset 2px 0 0 0 var(--pk-m-text)` and an explicit `color: var(--pk-m-text)`. Rare tabs → `color: var(--pk-m-text-2)` at the **same 0.8125rem size**.

**Changed from the concept.** The concept shrank the five rare tabs to 0.6875rem. The student judge was right that this makes small nav text smaller, saves no clicks, and hurts the student who needs Rubrics. Same hierarchy from ink tone (5.20:1, still AA), no legibility cost, no shrunken hit target.

**No reordering.** The research's own finding is that students learn this menu by position. A table of contents follows the book's order.

**Degrades to.** Nothing sets `width`, `display` or `order`, so the collapse toggle (`toggleCourseNav.js` writes inline `display`), the 192/218px dyslexic-font widths, and LTI tabs with unpredictable per-institution `css_class` all keep working — unknown tabs inherit the base row style. `.nav-badge` is `likely`; if it misses, the count renders as plain text.

### 4.8 Course home

**Before:** Five completely different pages behind one URL, each with its own visual density. **After:** All five, on the same paper, in the same hierarchy, at almost zero marginal cost — because every variant is a page Measure already styles.

| Selector | Conf. |
|---|---|
| `#course_home_content` | verified |
| `#wiki_page_show` | verified |
| `#announcements_on_home_page` | verified |
| `#course_home_content ul.recent_activity` | verified |
| `body.context-course_<id>` | verified |
| `#right-side .events_list.recent_feedback` | verified |
| `a.btn.button-sidebar-wide` | verified — **never touched, it is a button** |

**Moves.** `#course_home_content` → paper ground, `#content > h1` treatment. Then it branches for free: the **wiki** variant is the `.user_content` block (§5, Pages), the **modules** variant is §4.9 in full, the **assignments** variant is §5 Assignments index, the **syllabus** variant is `.user_content` again, and the **feed** variant is the Recent Activity block, which is the identical partial the dashboard uses. `body.context-course_<id>` is declared as an available scope and **is not used** — per-course theming is course colour written by the skin, which constraint 10 forbids.

**Degrades to.** Front Page and Modules variants are React mounts; if they churn, the ground and the ink still land through `#content`. Course home content is arbitrary teacher HTML and we never assume structure inside it. Under `body.course-menu-expanded` the desktop breakpoint moves 992px → 1140px, which we do not fight because we set no widths.

**Noted, not fixed.** On course home, Coming Up is rendered only for non-students, so a student who takes one class and uses this page as their dashboard sees Recent Feedback and no due list. That is a real missing feature and a real opportunity. It is not in this spec because it needs new markup, and Measure adds no new elements to a Canvas page.

### 4.9 Modules

**Before:** The #1 ranked complaint page. Thirty rows of identical weight, each a card inside a card, with the due date scattered mid-row at a different horizontal position on every line. **After:** A printed syllabus. No cards, hairline rows, a module header that sticks to the top while you scroll its module, and every due date in one right-hand column of tabular figures you read straight down.

| Selector | Conf. |
|---|---|
| `.item-group-container#context_modules_sortable_container` | verified |
| `#context_modules.ig-list` | verified |
| `.context_module` | verified |
| `.ig-header.header` | verified |
| `.ig-header-title.collapse_module_link` | verified |
| `.ig-list.items.context_module_items` | verified |
| `.context_module_item`, `.context_module_item.indent_1`…`indent_5` | verified |
| `.ig-row`, `.ig-row.with-completion-requirements` | verified |
| `.ig-info`, `.ig-details`, `.ig-details__item` | verified as row internals — **nesting between them is not stated in the map (see below)** |
| `.due_date_display` | verified |
| `.completion_requirement` | verified |
| `.header-bar`, `#expand_collapse_all` | verified — control never touched |

**Moves.**

```css
.context_module {
  background: transparent; border: 0; border-radius: 2px; box-shadow: none;
  border-bottom: 2px solid var(--pk-m-rule-strong);
  margin-bottom: var(--pk-m-section);
}

/* GRAFT 1 — the honest, un-indexed sticky head. */
.ig-header.header {
  position: sticky; top: var(--pk-m-stick, 0px); z-index: 1;
  background: var(--pk-m-page);
  border-bottom: 1px solid var(--pk-m-rule);
  max-height: 4rem;
}
.ig-header-title.collapse_module_link { font-size: 1.125rem; font-weight: 600; }

.ig-row { padding: var(--pk-m-row-pad) 0; border-bottom: 1px solid var(--pk-m-rule); }
.due_date_display {
  display: inline-block; min-width: 8.5rem; text-align: right;
  font-variant-numeric: tabular-nums lining-nums;
}
.ig-details { display: flex; gap: 14px; font-size: 0.75rem; color: var(--pk-m-text-2); }
.completion_requirement { font-size: 0.6875rem; text-transform: uppercase; letter-spacing: 0.08em; }
.context_module_item.indent_1 { padding-left: 1.5rem }  /* … through indent_5 at 7.5rem */
```

**The nesting problem, stated as a guess, not a fact.** RESEARCH.md §3.9 lists `.ig-handle`, `.ig-info`, `.ig-details` as "row internals" and **does not state whether `.ig-details` is a direct child of `.ig-row` or sits inside `.ig-info`**. On the assignments index, which shares this grammar, it appears to sit inside `.ig-info`. A single grid on `.ig-row` would silently no-op in that case, on the highest-value page in the skin. So Measure ships **both passes**, which are mutually exclusive and each a no-op when it misses:

```css
.ig-row  { display: flex; align-items: baseline; column-gap: 16px; flex-wrap: wrap; }
.ig-row  > .ig-details { margin-left: auto; }
.ig-info { display: flex; align-items: baseline; column-gap: 16px; flex-wrap: wrap;
           flex: 1 1 auto; min-width: 0; }
.ig-info > .ig-details { margin-left: auto; }
```

`flex-wrap: wrap` means an unexpected third child wraps to a new line rather than overflowing. The `min-width: 8.5rem` cell on `.due_date_display` produces the column in either nesting. **This is one hour on a live Modules page to settle, and it is day 1 of the Modules week in §11.** Until it is settled, it is written down as a guess.

**Complaint #3, answered.** The concept said four separate times that Modules clicks get nothing. Measure now ships three things for it: the sticky header (graft 1), which means a student scrolling a 30-row module always knows which module they are in; the due column, which removes the horizontal hunt; and `.completion_requirement` set as a real done mark at small-caps so finished rows are visible at a glance instead of being read.

**Degrades to.** `context_modules_v2` sits in master and deletes every `ig-*` class. Exactly one hook survives: `className="context_module_item"` on the outer View. So this block ships **a second minimal pass keyed only on that class** — hairline, row padding, tabular figures — correct in both DOM generations. The v2 page loses the fixed due cell, not its structure. `instui_header` swaps the page header for `#context-modules-header-root`, which we do not style at all. `position: sticky` degrades to `static` inside any ancestor with `overflow: hidden` or `auto`; `.item-group-container` is the ancestor to verify at build time, and the failure mode is an ordinary header with a hairline under it.

### 4.10 Assignment detail (student)

**Before:** A 1,100px-wide slab of 14px grey text with the due date and points at the very top, gone the moment you start reading. **After:** One narrow column on paper with a running head that keeps the title, the due date and the points in view the whole way down a 2,000-word assignment.

| Selector | Conf. |
|---|---|
| `#assignment_show` | verified — legacy ERB path |
| `#assignment_head` | verified |
| `.user_content` | verified |
| `[data-testid='assignments-2-student-view']` | verified — Enhancements path |
| `[data-testid='student-content-flex-container']` | verified |
| `#assignment_external_tools` | verified |
| `.tool_content_wrapper` | verified |
| `#content.ic-Layout-contentMain` | verified |

**Moves.** Legacy: `#assignment_show` → paper ground, 40px top padding. `#assignment_head` → `position: sticky; top: var(--pk-m-stick); z-index: 2; max-height: 4rem; background: var(--pk-m-page); border-bottom: 1px solid var(--pk-m-rule)`. We set position, ground, rule and type **on that container only and never reach inside it**, because the map verifies the id, not its children. Enhancements: the same ground, measure and link ink scoped to the two testids, with **no layout change** (there is no `#assignment_head` on that path, so the running head is legacy-only — say so in the product). Prose is the shared `.user_content` ruleset in §5. LTI frames get the seam treatment in §6.

**The sticky offset, derived not assumed.** `--pk-m-stick` is computed once at boot: sum the rendered height of any element above `#content` whose computed `position` is `sticky` or `fixed` and whose `top` is 0, cap at `4rem`. Under `@media (max-height: 700px)` the sticky heads are dropped entirely (`position: static`), because a two-line running head plus Canvas's own sticky chrome can eat a third of the reading area on a laptop.

**Degrades to.** Two DOM generations behind one URL and each block matches only its own. When both miss, the page still inherits the ground, the link ink and the `.user_content` typography, which is most of the value. `position: sticky` degrades to `static` where unsupported or inside an `overflow` ancestor.

**No rule in this skin sets `background`, `color`, `border` or `opacity` on a `button`, `.btn`, `[type=submit]` or `a.Button`.** The submit affordance keeps the school's own colours in both modes. See §9.5 for the one thing Lamp does add and why it cannot hide anything.

### 4.11 Grades (student)

**Before:** A zebra-striped spreadsheet where the score, the points possible, the due date and the class distribution all carry the same weight. **After:** A statement. No stripes, one hairline per row, every number right-aligned in tabular figures, and the total set large above a 2px rule like the total line on an invoice.

| Selector | Conf. |
|---|---|
| `#grade-summary-react` | verified — **detected first; if present, this entire block does not run** |
| `#grade-summary-content` | verified |
| `#grades_summary` | verified |
| `.student_assignment` | verified |
| `.assignment_score`, `.grade`, `.possible.points_possible`, `.letter_grade` | verified |
| `.due`, `.details`, `.comment_count`, `.group_weight` | verified |
| `.min`, `.max`, `.median` | verified |
| `#student-grades-right-content`, `#student-grades-final` | verified |
| `.react_pill_container` | verified — **given room, never restyled** |

**Moves.** Gated on the absence of `#grade-summary-react`, because `#grades_summary` and `.student_assignment` are already dead for any course with `restrict_quantitative_data` on (correction 5). Table → `background: var(--pk-m-sheet); border-collapse: collapse`, zebra striping removed with `background: transparent`, one 1px `--pk-m-rule` under every row. Scores, points possible and letter grade → right-aligned, 0.8125rem, tabular. `.due` → 0.75rem `--pk-m-text-2`. Title → 0.8125rem / 500. `#student-grades-final` → 2px `--pk-m-rule-strong` above, total at 1.5rem / 600. `.min` / `.max` / `.median` → one hairline row of three tabular figures with 0.625rem small-caps labels, because the research says the class distribution is what students actually scroll for.

**No colour on this page except the link ink.** No red, no green, no arrows, no trend line, no "at risk" language, and no what-if calculator, because that sits too close to the coins-never-pay-for-grades line.

**Degrades to.** Detecting `#grade-summary-react` first means the block does not run on the newer page instead of half-styling it. Everything else is a table cell taking type and alignment only, so a renamed class means one column falls back to Canvas's own rendering while the rest of the table still reads. Removing zebra striping is a `background: transparent` that no-ops if the stripe never existed.

### 4.12 Global navigation trays

**Before:** A full-height white overlay of InstUI rows, the way most students actually change course. **After:** The same rows on the paper ground behind one hairline, with course links set in the row type. The interior stays InstUI-painted and Measure says so.

| Selector | Conf. |
|---|---|
| `.navigation-tray-container.courses-tray` (also `groups-`, `accounts-`, `profile-`, `history-`, `help-`) | verified |
| `.tray-with-space-for-global-nav` | verified — **never touched**, it carries the 54/84px offset |
| `.navigation-tray-container` | verified |
| `#global_nav_tray_container` | verified |
| `.navigation-tray-container a[href^='/courses/']` | derived from a `likely` hook |

**Moves.** Wrapper → `background: var(--pk-m-page)`. Course links → 0.9375rem / 500 `--pk-m-text`, `text-decoration-thickness: 1px; text-underline-offset: 0.18em`. Nothing else. `min-height: 100vh` untouched.

**One thing not shipped, and why it matters.** The map offers `[class*='-tray'] a[href^='/courses/']`. That is a **label-anchored class-substring match** and it would also hit `css-<hash>-tray` on every InstUI Tray on the page. Constraint 1 bans it. Scope by the stable wrapper instead. This is exactly the selector that gets shipped by accident.

**Degrades to.** Everything inside the wrapper is InstUI with hashed names and is not reachable (verdict 1). Trays are `React.lazy`, so the DOM does not exist until first open; all of this is static CSS, so there is nothing to observe. The tray mounts into a portal **outside `#application`**, so no rule here is rooted at `#application`.

---

## 5. Per page, Tier 2

| Page | Moves | Degrades to |
|---|---|---|
| **Pages, Syllabus, and every `.user_content`** | See §5.1 below. The reading page. | Every rule is a property override on a standard HTML tag, so a missing tag is a missing rule. Teacher HTML that is one undifferentiated `<div>` still gets the ground, the ink and the link colour. |
| **Assignments index** | Shares the `.ig-row` grammar with Modules, so §4.9 covers it for free. Additionally `.ig-details__item.assignment-date-due` gets the 8.5rem right cell and `.js-score` gets tabular figures. `.ig-header` gets the module-title treatment; **no sticky**, because assignment groups are not modules and a sticky head per group would stack. | Backbone-rendered at runtime, not in the server HTML, so it is static CSS with nothing to query. `.item-group-condensed` inherits the ground. |
| **Inbox** | `[data-testid='conversation']` (verified) → hairline row, `--pk-m-row-pad`. `[data-testid='last-message-content']` (verified) → 0.8125rem `--pk-m-text-2`, one line. `[data-testid='unread-badge']` / `read-badge` (verified) → weight, never a fill. `[data-testid^='open-conversation-for-']` prefix-matched. `ConversationListItem.tsx` has zero `className` attributes, so every hook is a testid and every rule is additive. | Mounts into `#content`, so the ground and ink land through the legacy skeleton even if every testid churns. |
| **Discussions** | `[data-testid='discussion-topic-container']` (verified) → ground and `--pk-m-block` spacing. Reply bodies are `.user_content`, so §5.1 applies. `.discussion-topic-reply-button` (verified, a plain legacy class inside React) is **not touched** — it is a control. | Testid churn leaves the prose ruleset, which is the part that matters here. |
| **Quizzes (classic)** | `#quiz_show` (verified) → paper ground; question text is `.user_content`. `#quiz-publish-link` untouched. **This is not New Quizzes** (§6). | 391 lines of stable ERB. Nothing to degrade. |
| **Calendar** | `.fc-*` (FullCalendar's own public API, stable) → hairline grid instead of grey boxes, `font-variant-numeric: tabular-nums` on time gutters, 2px radius on events. Event colour is Canvas's course colour and is **read, never written**. | Hash-driven navigation, so the `hashchange` listener in §11 is required for anything JS-driven. All of the above is static CSS and needs none of it. |
| **Recent Activity** | `ul.recent_activity > li.stream-category` (verified) → hairline rows. `.unread-count` (verified) → tabular figure, not a filled pill. `td.date` (verified) → 0.75rem `--pk-m-text-2`, tabular. `.stream-activity` is **verified absent** and is never referenced. | Server-rendered empty, filled by XHR. Static CSS, applies whenever it lands. The same partial renders on course home and in Groups, which is intended. |
| **Courses index** | `#my_courses_table`, `#past_enrollments_table`, `#future_enrollments_table` (all verified) → sheet ground, hairline rows, no stripes. **Scope every rule by table id**; never `nth-child`, because a hidden accessibility column exists in the code. | Three near-identical tables on one page, each independently scoped. |
| **Mobile header** | `#mobile-header` (verified) inherits `--ic-brand-global-nav-bgd`, so §3.3 reaches it for free with no rule of our own. `.mobile-header-title.expandable` → 0.9375rem / 500. **No listener is added to `.mobile-header-hamburger`** — `MobileNavigation` binds `touchstart` with `preventDefault` and a second listener can break the native open. | `display: none` at ≥768px. `#mobileContextNavContainer` animates `max-height` over 1.5s and we do not touch it except through §8. |
| **Tier 3 (profile tray, kebab, People, profile settings, Groups, Outcomes/Rubrics/Conferences/Collaborations)** | Inheritance only. No page-specific CSS. | By definition. |

### 5.1 The reading page (`.user_content`)

One ruleset, six surfaces. This is where the concept was most wrong and where all three judges named the same rule.

**Cut: `p + p { margin-top: 0; text-indent: 1.4em }`.** All three judges named it as the one thing to cut. Canvas RCE output is full of `<p>&nbsp;</p>` spacers, `<p><img></p>` and `<p><br></p>`. Zeroing paragraph margins deletes every spacer and indents every wrapped image by 1.4em. It is a book affectation that assumes continuous prose, on the one container RESEARCH.md says twice never to assume structure in. It is gone. Paragraphs get a real vertical gap of `0.75em` instead.

**Changed: descendant selectors, not direct-child.** The concept clamped `.user_content > p`. Word- and Google-Docs-pasted pages are almost always wrapped in a `<div>` or a table, so on a large share of real pages the measure never landed. Measure clamps descendants and excludes table interiors:

```css
.user_content {
  color: var(--pk-m-text);
  font-size: 1.0625rem;
  line-height: var(--pk-m-prose-lead);
}
.user_content :is(p, ul, ol, h2, h3, h4, blockquote, pre):not(table *) {
  max-width: 34rem;
}
.user_content p:not(table *) { margin: 0 0 0.75em; }
.user_content h2 { font-size: 1.25rem; font-weight: 600; line-height: 1.3;
                   margin: 2rem 0 0.5rem; }
.user_content h3 { font-size: 0.9375rem; font-weight: 600;
                   text-transform: uppercase; letter-spacing: 0.08em;
                   margin: 1.5rem 0 0.5rem; }
.user_content ul, .user_content ol { padding-left: 1.25em; }
.user_content li::marker { color: var(--pk-m-text-2); }
.user_content blockquote {
  border: 0; background: transparent; padding: 0 0 0 1rem;
  border-left: 2px solid var(--pk-m-rule-strong);
}
.user_content a          { color: var(--pk-m-link); text-decoration-line: underline;
                           text-decoration-thickness: 1px; text-underline-offset: 0.18em; }
.user_content a:visited  { color: var(--pk-m-link-visited); }
.user_content code, .user_content pre {
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 0.9375rem; background: var(--pk-m-sheet);
}
.user_content pre { border: 1px solid var(--pk-m-rule); border-radius: 2px; padding: 12px; }
.user_content img { border: 1px solid var(--pk-m-rule); }
.user_content table { border-collapse: collapse; background: var(--pk-m-sheet); }
.user_content table td, .user_content table th { border: 1px solid var(--pk-m-rule); }
#content > h1 { font-size: 1.5rem; font-weight: 600; line-height: 1.25;
                border-bottom: 1px solid var(--pk-m-rule); padding-bottom: 0.5rem; }
```

**Nothing clamps `.user_content` itself.** No container is ever narrower than its widest child, so a table, an image or an embedded video can never be cut off, and `overflow` is never set. This is how "never assume structure inside `.user_content`" is honoured while still setting a measure.

**The kill switch.** The whole block sits behind one popup checkbox, "Book type on reading pages", separate from the serif checkbox. With it off, the page keeps Canvas's own typography with only the ground and the link colour changed.

---

## 6. The seam

RESEARCH.md's corrections change this section materially, and the concept had it wrong.

**What is no longer a seam.**

- **New Quizzes.** `new_quizzes_native_experience` was **enforced 2026-08-15**. It renders same-origin as `body.native-new-quizzes > #new-quizzes-root > #root`. Measure grounds that container and sets nothing inside it, because the interior is module-federated InstUI: container, spacing and typography only. **This is not an iframe and the concept's LTI framing of it was out of date.**
- **Canvadocs and DocViewer.** Reachable with `https://*.instructure.com/*` + `https://*.inscloudgate.net/*` and `all_frames: true`. A content script is injected per frame, matched by that frame's own URL, and isolated-world CSP has no `style-src`. Measure ships a **frame pass**: the ground, the viewer chrome, and Lamp. It cannot reflow a rendered PDF page, which is a canvas, so the measure and the hierarchy do not reach it. That split is stated in the product, not hidden.

**What is still a seam, and what the student sees.**

| Surface | Why | What Measure does |
|---|---|---|
| **Third-party LTI** (Proctorio, LockDown, Respondus, Studio, publisher tools, Google Assignments, Office 365) | Origins are unbounded per school. Covering them means `<all_urls>`, which is one of the three things that got the incumbent blocked by a district. | `.tool_content_wrapper` (verified) gets a 1px `--pk-m-seam` rule and a 0.6875rem small-caps `::before` caption reading **External tool**. The frame renders stock. |
| **Files v2** | `FileFolderTable.tsx` and `FilesHeader.tsx` contain **zero** `className` attributes. There is nothing to select. | Nothing. Per §2.2 we do not ground a surface we cannot re-ink, so the page keeps its stock white. In Paper that reads as a sheet (1.14:1 off the ground). In Lamp it is a lit rectangle, and that is honest. |
| **InstUI headers** behind `instui_header`, **tray interiors**, **InstUI modals and selects** | Painted by the JS theme from `CANVAS_ACTIVE_BRAND_VARIABLES`. `@instructure/ui-themes@11.7.5` ships **zero** `var(--`. A `:root` override changes nothing InstUI paints. MAIN-world injection is out of scope (verdict 1). | Nothing. Same reasoning. |
| **Widget Dashboard** | The controller returns `render html: "", layout: true`. There is no markup. | Detect the absence of `#DashboardCard_Container` and `#dashboard-planner`, and hand over to the Prepkin panel. |
| **Login** | Excluded on judgement. It is the school's identity surface, seen once a session, and repainting it is the exact behaviour that got BetterCampus blocked. | Nothing, in any mode. |

**The product copy for the seam**, one line in the popup, plain: *"Some pages inside Canvas belong to other companies. Measure can't reach those, so they'll look like Canvas normally does."*

---

## 7. Lamp (dark)

Lamp is not inverted paper. Inverting a warm ground gives you a grey slab, which is the failure mode of every dark mode in this category. Three moves make it a different design.

**1. Ink and paper swap roles.** Body text becomes `#DDD6C7`, the exact hex that is the hairline in Paper, on `#181614`. That is **12.48:1**, deliberately below pure white's **18.05:1**. Complaint #2 is about pain at 2am, not about maximising contrast, and `#FFF` on near-black is what produces halation for astigmatism and Irlen readers.

**2. The tone ramp collapses.** At low luminance the eye cannot reliably separate five warm greys, so Lamp runs on two inks: `--pk-m-text` at 12.48:1 and `--pk-m-text-2` at 5.81:1. The hierarchy that Paper carries partly in colour is carried entirely by size, case, tracking and position — which the sizes and small-caps labels already do in both modes, so nothing is redrawn.

**3. The sheet stops floating.** `--pk-m-sheet` is nine steps of lightness off the paper (`#211E1A` on `#181614`, 1.09:1), and there are still no shadows, so a card reads as a slightly different stock rather than a panel hovering in a void.

**The surfaces Canvas leaves white, and the half-darkened page.** This is where every dark mode in the category fails. Measure's rule: **it never grounds a surface it cannot also re-ink.** So there are exactly four classes of white left on a Lamp page, and each is handled:

| What stays light | Handling |
|---|---|
| Third-party LTI frames | 1px `--pk-m-seam` rule + "External tool" caption. Labelled as somebody else's page, not as a broken skin. |
| Files v2, InstUI headers, tray interiors | Left stock. Not grounded, not re-inked, not half-done. |
| Same-origin Canvadocs / DocViewer | **Reached.** `all_frames: true` puts the Lamp ground inside the viewer chrome, which is the single most-read long-form surface a student has. |
| Canvas's own `ic-flash-*` semantic colours | Left as Canvas set them. We change the ground behind the toast, not the semantics. |

**Two behavioural differences from Paper.** The six nav brand variables **are** derived in Lamp (§3.3), because an institutional-blue rail beside a dark page is exactly the glare in complaint #2, and in Paper we leave the school's rail alone. And Lamp adds the one box-shadow in the skin, on primary buttons only, described in §9.5.

**Lamp is a stock, not a checkbox.** It sits in the Looks catalog alongside the paper stocks (§10). That removes shipped bug 8 by construction: there is no separate dark checkbox that can disagree with the stock the student is wearing.

**Lamp is off entirely when `ENV.use_high_contrast` is true**, detected all three documented ways (§9.1), and it is off for the panel's own tokens, which are re-declared in full and are namespaced apart.

---

## 8. Motion

**Measure adds zero motion.** No `transition`, no `transform`, no `animation`, no `@keyframes`, in any mode, in any stock. That is not restraint for its own sake: the shipped `translateY(-3px)` card lift is deleted rather than wrapped, which fixes shipped bug 7 by removing the rule instead of adding a guard.

**Complete `prefers-reduced-motion` block.** Canvas honours reduced motion nowhere (0 occurrences in 401 KB of `common.css` against 40 `transition:` and 6 `animation:`), and neither does InstUI. Since Measure owns the entire block and has nothing of its own to guard, the block does something useful instead: it turns off Canvas's own motion, on the elements Measure already styles, for a student who asked the OS for it.

```css
@media (prefers-reduced-motion: reduce) {
  html.pk-m-on .ic-DashboardCard,
  html.pk-m-on .ic-DashboardCard__placeholder-animates,
  html.pk-m-on .ic-app-header__menu-list-link .menu-item__text,
  html.pk-m-on #mobileContextNavContainer,
  html.pk-m-on .ig-header.header,
  html.pk-m-on .ig-row,
  html.pk-m-on #assignment_head,
  html.pk-m-on .ToDoSidebarItem,
  html.pk-m-on li.event,
  html.pk-m-on .navigation-tray-container {
    transition-duration: 0.01ms !important;
    animation-duration:  0.01ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto !important;
  }
}
```

**Why `0.01ms` and not `none`.** `transition: none` and `animation: none` never fire `transitionend` / `animationend`. Canvas has JS that waits on those (the mobile context drawer animates `max-height` over 1.5s; `body.primary-nav-transitions` is added 300ms after collapsing). Zeroing the duration keeps the events firing and strands nothing. The list is explicit and closed: it names only elements Measure already touches, so it cannot silently break a Canvas surface the skin never looked at.

---

## 9. Accessibility

### 9.1 The high-contrast bail-out

High Contrast is a **compiled CSS variant**, not a body class. There is no `body.high-contrast`. Under it, `application_helper.rb#active_brand_config` throws away the institution's entire brand config and `getTheme` returns `canvasHighContrastTheme`, which its own description says meets WCAG 2.1 AAA. A skin painting over that is fighting an accessibility feature.

**Rule: when High Contrast is on, Measure disables itself entirely.** No ground, no ink, no tokens, no brand-variable writes, no classes on `<html>`.

**Detection, all three documented ways — and it does not need `ENV`.** Content scripts are isolated-world and cannot read `window.ENV` (verdict 1), but two of the three probes are DOM reads and work fine:

```js
const hc =
  document.querySelector('link[href*="new_styles_high_contrast"]') !== null ||
  document.querySelector('link[href*="variables-high_contrast"]')  !== null;
// window.ENV?.use_high_contrast === true is documented and is NOT readable from here.
```

This is a genuine correction to the concept, which listed the `ENV` path first. The stylesheet-href probe is the only one that works from where this skin runs.

**Flash handling, honestly.** `chrome.scripting.registerContentScripts` currently uses `runAt: 'document_end'`, and the `<link>` elements are only guaranteed present by then. So: apply `html.pk-m-on` optimistically at `document_start` from a per-origin flag cached in `chrome.storage.session` (we know from the previous page whether this user has High Contrast), then re-verify at `document_end` and remove the class if wrong. **A student's very first page load flashes once. Every load after that is clean.** That is the honest cost and it is the price of not having `ENV`.

This fixes shipped bug 5, which is the most serious accessibility gap currently in the extension. Grep for `use_high_contrast` across the repo today returns zero.

### 9.2 The dyslexic-font rule

**By default, Measure sets no `font-family` at any point, so constraint 7 cannot be violated.** That is the whole of graft 2 and it is why this is a two-line section instead of a page.

For the opt-in serif checkbox only, and because `ENV.use_dyslexic_font` is not readable from the isolated world, the probe is a computed-style read:

```js
const dys = /opendyslexic/i.test(getComputedStyle(document.body).fontFamily);
if (userWantsSerif && !dys) document.documentElement.classList.add('pk-m-serif');
```

No `ENV`, no MAIN world, no guessing at a bundle name. If the probe is somehow wrong, the failure mode is that a student who separately turned on OpenDyslexic **and** separately ticked the serif box gets serif — two opt-ins of their own, which is their choice, not ours.

Everything else survives: size, weight, line-height, measure, case, tracking, and the tabular figures.

### 9.3 What survives when the serif is off (which is the default)

The measure (34rem), the leading (1.62), the heading rhythm (2rem above / 0.5rem below), the two-tone ink, the hairlines, the tabular figures, the due column, the sticky heads, the small-caps labels, the visited-link colour, and Lamp. The identity is thinner than the concept claimed. It is also the whole informational half, and it is what ships in week one.

### 9.4 The 104px / 218px layout shift

**No width, `display`, `position` or `order` is set on `#header.ic-app-header` or on `#left-side`, anywhere in this spec.** The rail is 54 / 84 / **104**px and the course menu is 192 / **218**px depending on the dyslexic font, and `toggleCourseNav.js` writes inline `display`. Every one of those keeps working because Measure never touches the properties they use (constraint 8).

Two places where Measure adds a 1px border to an element whose width the layout depends on: `#left-side` (192/218px) and `#right-side-wrapper` (288px). Both ship `box-sizing: border-box` in the same rule so the border is drawn inside the box and the layout math is unchanged. **Verify, do not assume** — this is a smoke-check assertion, not a comment.

### 9.5 Contrast on every interactive state, and the submit-button check

**The structural rule.** No rule anywhere in Measure sets `background`, `color`, `border` or `opacity` on `button`, `.btn`, `.btn-primary`, `[type=submit]`, `a.Button`, `.Button--primary`, `.Button--secondary`, `#submit_assignment`, or a file-upload affordance. The four `--ic-brand-button--*` variables and their four darkened derivatives are never written. **The incumbent's documented worst bug — a hidden submit button that contributed to a district-wide block — is impossible here by construction, not by testing.**

**The one thing Lamp adds, and why it cannot hide anything.**

```css
html.pk-m-lamp .btn-primary,
html.pk-m-lamp .Button--primary,
html.pk-m-lamp [type="submit"] { box-shadow: 0 0 0 1px var(--pk-m-rule-strong); }
```

A school whose primary button fill happens to be near-black would otherwise vanish into Lamp's `#181614` ground. `box-shadow` changes no box metric, can only add a visible edge, and is not one of the four banned properties. It is the only shadow in the skin.

**Measured states, Canvas defaults on our grounds:**

| State | Measured | Threshold |
|---|---|---|
| White label on Canvas default primary `#2B7ABC` | **4.55:1** | 4.5:1 (AA text) — passes, and is unchanged by us |
| Primary fill `#2B7ABC` vs Paper `#F3F0E7` | **4.00:1** | 3:1 (AA non-text) — passes |
| Primary fill `#2B7ABC` vs Lamp page `#181614` | **3.96:1** | 3:1 — passes |
| Primary fill `#2B7ABC` vs Lamp sheet `#211E1A` | **3.65:1** | 3:1 — passes |
| White label on high-contrast primary `#0A5A9E` | **7.07:1** | n/a — skin is off in that mode |
| Focus ring `--pk-m-focus` vs Paper | **7.97:1** | 3:1 — passes |
| Focus ring `--pk-m-focus` vs Lamp | **9.36:1** | 3:1 — passes |
| Row hover `--pk-m-select`, body ink on it, Paper | **12.56:1** | 4.5:1 — passes |
| Row hover, marginal ink on it, Paper | **4.58:1** | 4.5:1 — passes |
| Row hover, amber ink on it, Paper | **4.56:1** | 4.5:1 — passes |
| Amber left rule vs Paper | **3.30:1** | 3:1 — passes |
| Amber left rule vs Lamp | **3.59:1** | 3:1 — passes |

**Focus is restated, never removed.** `:focus-visible { outline: 2px solid var(--pk-m-focus); outline-offset: 2px }` on every element whose ground Measure changed, because Canvas's own focus treatment on several of them is a `border-color` change that assumed the old ground. `outline: none` appears nowhere in this file. `#skip_navigation_link` is never selected and its visually-hidden-until-focused behaviour is untouched.

**Two-tone ink is AA everywhere on the page.** 14.27:1 and 5.20:1 in Paper, 12.48:1 and 5.81:1 in Lamp. Nothing on a Canvas page uses a third tone.

### 9.6 Other preferences respected

`ENV.PREFERENCES.hide_dashcard_color_overlays` — respected by **never setting `opacity` on the hero** (shipped bug 1). `ENV.PREFERENCES.custom_colors` — course colours are read, never written (constraint 10), and `.ic-DashboardCard__header-title span` is never recoloured (shipped bug 2). `ENV.SETTINGS.collapse_global_nav` — untouched, no width is set. `Underline-All-Links__enabled` body class — compatible, our links are already underlined. `ENV.disable_celebrations` — no celebration is added.

### 9.7 The smoke check

One file, `selectors.json`, holding every Canvas selector with its page, hook tier and confidence label (constraint 3). A headless run against a live Canvas instance, per Canvas release, asserting:

1. Every load-bearing selector still matches at least one node.
2. `.ig-details` nesting relative to `.ig-row` is still what the build assumes.
3. **Computed contrast on every button state** — label vs fill ≥ 4.5:1, fill vs ground ≥ 3:1 — in Paper and Lamp, in every stock, at every density.
4. Computed contrast on every school-brand foreground that lands on a Measure ground, re-measured on the real ground rather than assumed from white.
5. `box-sizing` on `#left-side` and `#right-side-wrapper` still resolves to `border-box`.
6. No selector in the file contains the substring `css-`.

---

## 10. Looks

A Look here is a **paper stock**, not a theme. It may move the page tokens and nothing else. Measure, leading, weights, rules, radii, spacing and figures are constant across every Look forever. That constraint is what stops the treadmill: there is no Look that is louder, no Look that is better, no Look that can produce a bad page, and no reason to keep shipping new ones to stay interesting, because the interesting part was never the palette.

**Two structural fixes to the existing `looks.js` model, both required.**

1. **A Look swaps a class on `<html>`, it never writes inline custom properties.** Today `lookVars()` writes five `--pk-*` names inline on `<html>`, and an inline declaration beats the panel's own matched rule — which is shipped bug 10, and would be worse here because Measure's tokens carry verified contrast. Measure ships `html.pk-m-stock-<id>` and each stock declares its **full token set** in **both** `html.pk-m-paper` and `html.pk-m-lamp` scope. That kills shipped bug 9 (all six looks render identically in dark) and shipped bug 3 (a toggle pair leaving `var()` unresolved) at the same time.
2. **The accessory stays in the panel.** A Look is still a palette plus one accessory on the existing model. The accessory is drawn on the mascot **inside the panel**, where it already lives. **No accessory art enters the Canvas surface.** That is constraint 18, and it also means nothing here inherits the provisional-art sign-off gate (constraint 22) — nothing in this spec is blocked on George.

### 10.1 The catalog

Accessories reuse the four already in `looks.js`. No new art is drawn.

| Stock | Price | Page (Paper / Lamp) | Ink AA (Paper / Lamp) | Link | Accessory | Note |
|---|---|---|---|---|---|---|
| **Cream Laid** | free, default | `#F3F0E7` / `#181614` | 14.27 & 5.20 / 12.48 & 5.81 | `#2C4A6E` (7.97) / `#9EBEE0` (9.36) | none | The default. Within a hair of the app's own `#F4F1EA` cream, which is the deliberate through-line to the iOS product. |
| **Foolscap** | **free** | `#FAFAF8` / `#161616` | 15.98 & 5.85 / 13.43 & 6.18 | `#22528C` (7.57) / `#9FC2E8` (9.79) | none | Near-white and neutral. Free on purpose: cream is the default, not an imposition, and a student who wants stock ground has it without coins. |
| **Manila** | 300 | `#EFE5D0` / `#1B1611` | 13.09 & 5.20 / 12.74 & 5.84 | `#5C3E14` (7.79) / `#DCBE8A` (10.07) | `scarf` | A filing-folder brown. |
| **Ledger** | 300 | `#E9EFE6` / `#141814` | 13.73 & 5.28 / 13.19 & 6.13 | `#2A5442` (7.34) / `#9FD3BA` (10.68) | `sprout` | Pale accounting green. |
| **Gridded** | 450 | `#EFF1EC` / `#171917` | as Ledger ±0.2 | as Ledger | `glasses` | Cream Laid plus a 24px `repeating-linear-gradient` at 3% alpha, applied to `--pk-m-page` **only**, so the grid never runs under a sheet and tables stay readable. The one gradient in the skin. |
| **Plain** | 600 | Canvas's own ground | n/a | Canvas's own | `beanie` | A coin-earned un-skin. Returns Canvas to stock with only the reading-page typography and the due column left on. Selling restraint as the top-tier reward is the honest end of this concept, and it means a student who owns everything has genuinely finished. |

Every stock is AA on both inks in both modes, computed, not eyeballed. Every stock declares all thirteen tokens in both scopes.

### 10.2 The density dial (graft 3)

A second, orthogonal axis. Three steps, `html.pk-m-density-{compact,normal,roomy}`, values in §2.4.

| Step | Price | Why |
|---|---|---|
| **Normal** | free, default | Matches Canvas's own row height. |
| **Roomy** | **free** | The accessible direction: 47px rows, clears the 44px touch target. A student who needs bigger rows should never have to earn them. |
| **Compact** | 200 | The power-user direction: 33px rows, more on screen, below the touch-target guideline. Coin-earned so it is an informed choice, and **auto-falls back to Normal under `@media (pointer: coarse)`**. |

Density changes zero semantics, moves no colour, and cannot reach any contrast ratio. The research says density preference genuinely runs both directions — the incumbent ships three toggles because students disagree — so 9px row padding is an opinion, not a finding, and it gets a control. This is the dial students will actually spend coins on, and it is the only thing a purchase can reach: **a Look sells the paper and never the ink.**

### 10.3 Shipped bugs this section closes

| Bug | Status |
|---|---|
| 1 — hero `opacity !important` overrides an accessibility preference | Fixed by never setting `opacity` |
| 2 — title span recoloured, destroying the last course-colour cue | Fixed by never setting `color` there |
| 3 — `dark: true, cards: false` collapses the token system | Fixed: all 13 tokens declared in full in both root scopes |
| 4 — `.PlannerItem-styles__container` matches nothing | Fixed: `[data-testid='planner-item-raw']` |
| 5 — no high-contrast detection anywhere | Fixed: §9.1 |
| 6 — `--pk-ink` never inverts | **Not fixed. It is a panel token and out of scope for a page skin.** |
| 7 — unguarded `translateY(-3px)` hover lift | Fixed by deleting the rule |
| 8 — Night Shift forces dark while the checkbox disagrees | Fixed: Lamp is a stock, so there is no second control to disagree with |
| 9 — all six looks render identically in dark | Fixed: every stock declares both scopes |
| 10 — look tints never reach the panel | Fixed: namespaced `--pk-m-*` tokens and a class swap, so the two systems cannot collide |
| 11 — `.ic-Dashboard-header__title` is unverified | Fixed: never selected; the `h1` is styled by element inside the verified container |

---

## 11. Build order

Ranked by student value per unit of risk. Honest about days versus weeks.

### Week 1 — The spine. Highest value, lowest risk, no JS at all.

| # | Work | Time | Why first |
|---|---|---|---|
| 1 | **Settle the `.ig-details` nesting on a live Modules page.** | **1 hour** | It decides whether the best rule in the skin works. Everything else in week 1 is blocked behind it in importance, not in schedule. |
| 2 | The token file. 13 tokens × 2 root scopes × 6 stocks × 3 densities, plus the type and spacing scale. | 1 day | Nothing else compiles without it. |
| 3 | Modules: hairline rows, sticky module head, the due column, completion marks, the second `.context_module_item`-only pass for `context_modules_v2`. | 2 days | The #1 ranked complaint, answered by alignment. Two judges independently named this the strongest single artifact in the batch. Pure CSS. |
| 4 | The global ground and ink: `#content`, tables, `#left-side`, `#right-side-wrapper`, breadcrumbs, flash, banners, trays, and the tabular-figures inheritance on `#content`. | 1 day | One rule reaches every Tier 1 and Tier 3 page. |
| 5 | `.user_content` reading block + `#content > h1`. | 1 day | Six surfaces, zero JS, one kill switch. |

**Ships at the end of week 1:** a static-CSS-only skin, Paper stock, Normal density, no dark mode, no JS, no observer, no brand-variable writes. It already answers complaint #1 and complaint #3. It is the version a district security review waves through, and it is the version that is worth shipping even if everything after it slips.

### Week 2 — Lamp, and the plumbing the repo does not have.

| # | Work | Time | Why |
|---|---|---|---|
| 6 | High-contrast detection + the `document_start` / `document_end` optimistic-class dance. | 1 day | Shipped bug 5 is the most serious accessibility gap in the extension today. Nothing dark ships before it. |
| 7 | Lamp: the full second token scope, the seam rules, the Canvadocs `all_frames` pass, the primary-button ring. | 2 days | Complaint #2, eight years and 354 comments old. |
| 8 | Brand-variable writes: read computed `:root`, the badge red-band test, the Lamp rail derivation with the light-rail bail. | 1 day | Roughly 60 lines of JS plus colour maths. |
| 9 | The four navigation mechanisms the repo lacks entirely: one debounced `MutationObserver` on `documentElement` at ~300ms, the `canvasReadyStateChange` listener, patched `pushState`/`replaceState` + `popstate`, and `hashchange` for the Calendar. | **2 days** | §5.3 says the repo has none of these. This is the single missing architectural piece and it is table stakes, not differentiation. |

### Week 3 — The reachable extras.

| # | Work | Time |
|---|---|---|
| 10 | `pk-m-soon` on the sidebar, joined on the assignment href against the already-synced to-do list. | 1 day |
| 11 | Planner: day rules, today's 2px line, the opportunistic course-colour read (needs the observer from #9). | 1 day |
| 12 | Dashboard card view, Grades, course nav, course home branch. | 2 days |
| 13 | Tier 2 sweep: Assignments index, Inbox, Discussions, classic Quizzes, Calendar, Recent Activity, Courses index, mobile header. | 1 day |

### Week 4 — Controls, catalog, and proof.

| # | Work | Time |
|---|---|---|
| 14 | Popup: the two checkboxes ("Book type on reading pages", "Serif on reading pages"), the stock picker, the density dial. Remove the duplicated `SKIN_DEFAULTS` from `popup.js:148` and `content.js:7`. | 1 day |
| 15 | The six stocks, both scopes each, with the contrast table generated rather than hand-written. | 1 day |
| 16 | `selectors.json` + the smoke check (§9.7), including the button-contrast assertions. | **2 days** |
| 17 | Sticky-offset derivation, the `max-height: 700px` bail, the `overflow` ancestor verification on `.item-group-container`. | 1 day |

### The honest totals

- **CSS:** roughly **600–750 lines**.
- **JS:** roughly **300–380 lines**, plus the four-mechanism plumbing. The concept's claim that "the only JS is adding one class name" was wrong by about an order of magnitude, and this spec does not repeat it.
- **Calendar time:** 4 weeks to the full thing, **1 week to something worth shipping**.
- **Manifest changes required:** `runAt` moves to `document_start`; `all_frames: true` is added with `https://*.instructure.com/*` and `https://*.inscloudgate.net/*` for the Canvadocs pass. **`<all_urls>` is never requested.**

---

## 12. What Measure refuses to do, and why

1. **Pills, chips and rounded tags.** Every radius on a Canvas page is 2px. An urgency pill scatters attention across a page; a column of right-aligned tabular figures under one hairline is faster to read and does not shout. This is the central bet and it is falsifiable: if students cannot find due dates faster in the column than in pills, the concept loses.

2. **Shadows, gradients, hover lifts and transitions.** `box-shadow: none` ships explicitly on cards and lists. The skin adds zero motion, so constraint 9 is satisfied by refusal rather than by guarding, and the reduced-motion block is spent turning off Canvas's own motion instead. Two named exceptions: the Gridded stock's page texture and the Lamp primary-button ring, both argued in place.

3. **Any rule that sets `background`, `color`, `border` or `opacity` on a `button`, `.btn`, `[type=submit]` or `a.Button`.** The incumbent's worst documented bug becomes structurally impossible instead of merely tested for. Buttons stay in the school's own colours and read as stamps on paper.

4. **Setting `font-family` by default.** The dyslexic-font gate cannot be read from an isolated world, and a font swap applied after first paint guarantees a visible relayout on every navigation. Not writing the property is the only implementation of constraint 7 that cannot be got wrong. The serif is one opt-in checkbox, default off.

5. **`p + p { margin-top: 0; text-indent: 1.4em }`.** All three judges named it as the one thing to cut, and they were right. It assumes continuous prose in the one container the research says twice never to assume structure in, and it would indent every image a teacher wrapped in a `<p>`.

6. **Reordering the course nav.** Students learn this menu by position. A table of contents follows the book's order. The five rare tabs recede by ink tone, not by size and not by moving.

7. **Shrinking anything to create hierarchy.** The concept demoted rare nav tabs to 0.6875rem. That makes small nav text smaller and shrinks a hit target to buy a hierarchy gain a student cannot see. Ink tone does the same job for free.

8. **Auto-expanding "N more" in the sidebar, and surfacing the invisible "Load prior dates" button.** The first means `!important` against inline `display: none` written by live JS, to show information the student did not ask for. The second is a real fix that the map names without giving a selector, and we do not guess.

9. **A grey ramp.** Two ink tones on the page, both AA on every ground they touch. `--pk-text-3` at 2.95:1 is deleted, not declared-and-avoided.

10. **Any coin, count, ring, meter, mascot or Prepkin mark on a Canvas page.** Personality lives in the panel the student opted into (constraint 18). It also means nothing here inherits the provisional-art sign-off gate (constraint 22), so no part of this spec waits on new art.

11. **Red, anywhere, including late work.** Amber ink, no fill, no alarm. Canvas's own `ic-flash-error` semantics are left exactly as the platform ships them, because constraint 19 bans a red the skin draws, not one the platform already owns.

12. **A per-course theme keyed on `body.context-course_<id>`.** It is available and verified and it would look good. It is course colour written by the skin, and constraint 10 says course colour is read, never written.

### The weakness this spec does not talk its way out of

The documented demand is self-expression. Students in the corpus ask for their own GIFs, their own colours, their own fonts. Measure answers with six paper stocks, a density dial and a serif checkbox. That is more customisation than the concept had and it is still less than a neon theme. Measure has no day-one moment — nothing here reads in a thumbnail — so install-to-day-7 will lose to a theme with a cat on it.

What it has instead is the opposite curve. A theme you notice fades within a week. A 34rem measure at 17px/1.62, a due column you read straight down, a module head that does not scroll away, and a ground that does not hurt at 2am are all still there in week nine, and they help most exactly when a student is most likely to quit. And it is the least blockable direction on offer: CSS only, zero external requests, no DOM removal, no control hidden, the school's rail left alone in light mode, and it switches itself off under High Contrast. The documented worst outcome in this category is not a bad review. It is a whole school losing the tool at once.