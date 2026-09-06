# Low Beam — Canvas skin specification

**Prepkin Canvas, concept slot 3. Written 2026-09-04 against `design/canvas-skin/RESEARCH.md` (Corrections block first, §8 in full).**

---

## 0. What changed after the three judges

Nine things in this spec contradict the concept as pitched. Stated up front so nobody implements the old version.

| Was | Is now | Why |
|---|---|---|
| Four-step dimmer on the Canvas page | **One switch on the page, three dark levels in the popup** | Nobody asked for four darks. Daylight↔dark is a toggle; the levels are a setting. §1. |
| "The veil mathematically raises text contrast" | **Deleted. It is false.** `brightness(k)` scales both terms; ratio always falls | Black-on-white 21:1 → 15.2:1 at k=.86. §6. |
| Veil factor .78 | **.94 / .90 / .86** | .78 pushes Canvas grey meta text to 3.96:1. .86 lands it at 4.21:1, and no k<1 preserves a 4.54:1 pair. §6, §9. |
| Veil on `iframe#tool_content.tool_launch` | **Never. No LTI frame is filtered, ever.** | That set includes Proctorio, LockDown, Respondus. Integrity hazard, district-block risk. §6. |
| Veil on "New Quizzes and Canvadocs" | **Both repainted for real** | Corrections 1 and 2: New Quizzes is same-origin since 2026-08-15; Canvadocs is reachable with `all_frames`. §6. |
| Hero collapses 146px → 8px | **146 / 146 / 96 / 56px, and the spine ships at every step** | Only layout subtraction in the concept; both colour cues could vanish together. §4.4. |
| Seam glyph appended to `a.files` | **Cut.** The caption moves onto the seam itself | A glyph explaining the extension's own limits, inside the student's navigation. §4.7. |
| Always-visible missing-work count | **Cut.** No aggregate number anywhere | Repo rule: every number can only go up. A count of what you are behind on is a guilt meter. §4.5. |
| "Brightest object is the submit button" | **"The only object left at full colour is the submit button."** Plus a ring that makes its boundary provable | Light text at 10.4:1 is literally brighter than a mid-blue button. The old line was unverifiable; the new one is checkable. §4.10, §9.5. |

I also **refused one judge fix**: the engineer asked for `filter: brightness(.85)` on `.btn-primary` at the deepest step to stop it blooming. That filter scales the fill *and* the white label together, so Canvas's default `#0374B5`/white pair drops from 5.04:1 to about 4.3:1 — it breaks the one control the whole concept protects. The bloom is handled with a 1px ring instead, which costs no contrast. §9.5.

---

## 1. The idea

Every competitor ships dark mode as a switch, and every one of them ships a half-darkened page: the LMS goes dark, then Files, a Canvadocs preview or a nav tray opens as a full-brightness white rectangle. At 2am, with pupils adapted, that flash is worse than never turning the lights off. Low Beam is a **lamp, not a switch**: one drawn desk-lamp control in the rail turns Canvas down, and the deeper levels — set once in the Prepkin popup, not on the school's page — re-anchor a five-step luminance ladder, a text ceiling that comes *down* at the deepest level, a weight scale that lightens as the ground darkens, the size of every image and course-colour block, and the brightness of the surfaces the skin is not allowed to repaint. Course hue is never changed, only its *area*. The dark levels are a different drawing, not an inversion: shadows go to zero and objects separate by a light caught on their top edge, the way things separate in a dark room.

**Signature move.** Everything on a Low Beam page steps down with the lamp — every surface, every teacher photo, every white frame, the course hero, the text ceiling itself — except one: Canvas's own primary button keeps the school's colour at 100% at every level, gains a 1px ring so its boundary is provably visible on any ground, and is the only object on the page that moves when you press it.

---

## 2. Tokens

Type is `system-ui`-family **only as an off-by-default option**; the default sets no `font-family` at all (§9.2). Everything below is a custom property declared on `:root` in one of four step files.

### 2.1 The luminance ladder

Five grounds per step. `L*` is CIE lightness; the ladder is what does the separating, so the 1px ring is deliberately soft.

| Token | Daylight | Dusk | Late | Low Beam | Role |
|---|---|---|---|---|---|
| `--pk-void` | `#E2DCCC` L\*87.8 | `#211D19` L\*11.1 | `#141210` L\*5.6 | `#100E0C` L\*4.1 | Body ground, nav rail field, gutters, breadcrumb strip. Never `#000`: pure black maximises halation for astigmatic and Irlen readers. |
| `--pk-page` | `#F4F1EA` L\*95.2 | `#2A2621` L\*15.4 | `#1C1916` L\*9.0 | `#151310` L\*6.0 | The reading ground. `#content`, module item rows, table rows, planner rows. |
| `--pk-card` | `#FCFAF5` L\*98.3 | `#352F29` L\*19.8 | `#252019` L\*12.6 | `#1D1A16` L\*9.5 | Dashboard card face, sidebar widget, `#student-grades-final`. Never `#FFFFFF`. |
| `--pk-raise` | `#EFEADD` L\*92.8 | `#3F3931` L\*24.3 | `#2E2922` L\*16.9 | `#26221C` L\*13.5 | Module header band, table header, row hover, active nav tab. **In dark this is elevation; in light it is recession.** Same token, opposite job — this is why the light variant is a derivative, not an inversion. |
| `--pk-band` | `#E8E2D4` L\*90.0 | `#494238` L\*28.4 | `#38322B` L\*21.2 | `#2E2921` L\*16.9 | Chips, quiet pills, grade chips, the seam caption strip. |

### 2.2 Ink

Ratios are measured against each ground, all four steps.

| Token | Daylight | Dusk | Late | Low Beam |
|---|---|---|---|---|
| `--pk-t1` primary text | `#2A2621` | `#EAE4D8` | `#E0D9CC` | `#C9C1B3` |
| on void / page / card / raise / band | 10.98 / 13.32 / 14.40 / 12.51 / 11.63 | 13.22 / 11.87 / 10.43 / 9.01 / 7.83 | 13.32 / 12.47 / 11.52 / 10.28 / 9.02 | 10.79 / 10.39 / 9.71 / 8.86 / 8.08 |
| `--pk-t2` secondary | `#5B5245` | `#C3B9A8` | `#B4AA9B` | `#A2988A` |
| on void / page / card / raise / band | 5.60 / 6.80 / 7.35 / 6.39 / 5.94 | 8.63 / 7.75 / 6.81 / 5.88 / 5.11 | 8.15 / 7.64 / 7.05 / 6.29 / 5.52 | 6.78 / 6.53 / 6.10 / 5.57 / 5.08 |
| `--pk-t3` tertiary floor | `#6A5E4E` | `#B0A695` | `#9C9284` | `#968D7E` |
| on void / page / card / raise / band | 4.62 / 5.60 / 6.06 / 5.26 / 4.89 | 6.96 / 6.25 / 5.49 / 4.74 / **4.12** | 6.10 / 5.72 / 5.28 / 4.71 / **4.13** | 5.88 / 5.66 / 5.29 / 4.83 / **4.40** |

**One rule from the bold cells: `--pk-t3` is legal on void, page, card and raise. On `--pk-band` and anything above it the floor is `--pk-t2`.** Nothing in the sheet renders below 4.5:1 — including disabled controls, which keep `--pk-t3` rather than taking WCAG's disabled-control exemption. A student needs to read a disabled submit button to learn why it is disabled.

Low Beam's `--pk-t1` is **deliberately lower** than Late's: 10.39:1 against page, down from 12.47:1. Maximum contrast is not maximum readability. Near-white on near-black haloes, and AAA's 7:1 is a floor, not a target.

### 2.3 Colour

| Token | Daylight | Dusk | Late | Low Beam | Role |
|---|---|---|---|---|---|
| `--pk-accent` | `#1E6B4C` | `#5FCFA2` | `#57C79B` | `#4FA783` | Links, active nav edge, today's mark, completion check. On page: **5.71 / 7.82 / 8.37 / 6.35**. Only ever text, a 3px edge or a stroke. Never a large fill on a dark step. |
| `--pk-accent-quiet` | `rgba(30,107,76,.10)` | `rgba(95,207,162,.12)` | `rgba(87,199,155,.13)` | `rgba(79,167,131,.11)` | The only accent fill permitted, and only behind text already at `--pk-t1`. |
| `--pk-amber` | `#F5E3C9` (tint) | `#EFAE45` | `#E8A63C` | `#CE9235` | Urgency, reading "still counts". **Tint in light, solid pill in dark** — same meaning, opposite construction, because amber and mint sit close in luminance and a deuteranope separates them by figure-ground, not hue. |
| `--pk-amber-ink` | `#7A4E11` | `#211D19` | `#141210` | `#100E0C` | Text on the amber pill: **5.71 / 8.62 / 8.86 / 7.14**. Amber is never loose coloured text. |
| `--pk-focus` | `#7A5A16` | `#F5D089` | `#F2C877` | `#DDB765` | 2px outline, 2px offset, on every focusable element the skin touches. On page: **5.64 / 10.21 / 11.09 / 9.74**. Never `outline:none`. Never removed. |
| `--pk-btn-ring` | `--pk-t3` | `--pk-t2` | `--pk-t2` | `--pk-t2` | 1px ring on Canvas's primary button. §9.5 proves the boundary. |

**There is no red anywhere in this sheet.** Canvas's `ic-flash-error` keeps the platform's own red, untouched. `#000` and `#FFF` never appear as a value.

### 2.4 Non-colour tokens

| Token | Daylight | Dusk | Late | Low Beam | Role |
|---|---|---|---|---|---|
| `--pk-veil` | `1` | `.94` | `.90` | `.86` | `brightness()` on the two same-origin surfaces the skin owns the document for but cannot select into: Files v2's `#content`, and `.tray-with-space-for-global-nav`. Nothing else. §6. |
| `--pk-img` | `1` | `.94` | `.86` | `.78` | `brightness()` on teacher-uploaded imagery: `.ic-DashboardCard__header_image`, `img` inside `.user_content`. Dimmed, never inverted — inversion wrecks photographs, diagrams and scanned maths, which is what students actually read. |
| `--pk-hero` | `146px` | `146px` | `96px` | `56px` | Height of `.ic-DashboardCard__header_hero` **and** `.ic-DashboardCard__header_image`, in the same rule. Reduces chromatic *area*, never chromatic value. `opacity` is never touched. |
| `--pk-wt-head` | `700` | `600` | `600` | `600` | Light-on-dark glyphs bloom, so the whole scale drops one step in dark. |
| `--pk-wt-mid` | `600` | `500` | `500` | `500` | |
| `--pk-track` | `0` | `.004em` | `.006em` | `.008em` | Extra letter-spacing on headings and on `--pk-t1` rows. |
| `--pk-shadow` | `0 1px 2px rgba(42,38,33,.06), 0 8px 20px rgba(42,38,33,.08)` | `none` | `none` | `none` | Drop shadows exist only at Daylight. A shadow on near-black is invisible and only muddies the step below. |
| `--pk-edge` | `inset 0 0 0 0 transparent` | `inset 0 1px 0 rgba(255,244,228,.060)` | `inset 0 1px 0 rgba(255,244,228,.055)` | `inset 0 1px 0 rgba(255,244,228,.045)` | **The dark-step replacement for shadow.** In a dark room you see edges catch light, not shadows cast. Every card, row and band carries this on its top edge. |
| `--pk-dur` | `180ms` | `180ms` | `90ms` | `0ms` | Every transition duration. §8. |
| `--pk-lamp-h` | `70` | `70` | `70` | `70` | oklch hue of the lamp. A Look moves this. §10. |
| `--pk-look-h` | `152` | `152` | `152` | `152` | oklch hue of the accent. A Look moves this. Nothing else. |

### 2.5 Type, shape, rhythm

**Font stack** (declared once, on `html[data-pk-font="system"]`, off by default — §9.2):
`-apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, "Helvetica Neue", Arial, sans-serif`. Zero external requests, ever.

**Size scale, rem.** `0.8125` (13px, floor — Canvas's 12px meta text is raised) · `0.875` (14px, nav labels, secondary) · `0.9375` (15px, row titles, body UI) · `1.0625` (17px, `.user_content` prose) · `1.25` (20px, module headers) · `1.5` (24px, page h1).

**Weight scale.** Daylight 400 / 600 / 700. Dusk, Late, Low Beam 400 / 500 / 600. **No 800 or 900 exists on any dark step.**

**Prose.** `.user_content`: `1.0625rem / 1.65 / max-width: 68ch`, paragraph gap `0.9em`.

**Radii.** 12px card and primary button, 8px row, 6px chip, 999px pill. Deliberately below the Prepkin panel's 16–20px: the page is imposed, the panel is not.

**Borders: none.** Every edge is `box-shadow: inset 0 0 0 1px var(--pk-line), var(--pk-edge)`, which is layout-neutral, so a missed rule leaves a plain surface rather than a size change. `--pk-line` sits at 1.37–1.65:1 against `--pk-card` on purpose: a boundary is a hint, and a hard hairline at 2am is itself a light source.

**Spacing, 4px base.** 4 / 8 / 12 / 16 / 24 / 32. Card padding 16. Row padding 12 vertical, 14 horizontal. Section gap 24.

**States are ladder steps, never opacity changes.** Hover is surface +1, active is surface +2, disabled holds `--pk-t3` and its 4.5:1. No state change can reduce contrast, because every state is a defined ground with a measured ratio.

---

## 3. The base layer

### 3.1 The kill switch comes first

Before any token is declared, three checks. All three run; any one of them removes the skin.

```js
// [verified §4.6] — primary, DOM-readable from the isolated world
document.querySelector('link[href*="new_styles_high_contrast"]')
document.querySelector('link[href*="variables-high_contrast"]')
// [likely] — secondary, Canvas REST, cached per origin for 24h
GET /api/v1/users/self/features/enabled  →  includes "high_contrast"
```

`window.ENV.use_high_contrast` is a **page global and is not readable from a content script's isolated world**. The concept's plan to check it was wrong. The two `<link>` checks are the real hooks and they are verified in the research doc.

Timing: a `MutationObserver` on `document.documentElement` is armed at `document_start` and fires the instant either `<link>` is inserted during head parsing, which is before the body exists. On a hit the extension calls `chrome.scripting.removeCSS` for the step file and the shared sheet on that tab, and writes `highContrast: true` for that origin so no future navigation ever registers them. **Honest residual: on the very first high-contrast page load there is a theoretical few-millisecond window before the link is parsed.** No paint has happened in it, but I am not going to claim zero.

Same shape for `/login/*` (never skinned) and for the Files route.

### 3.2 Variables overridden on `:root`

All with `!important`, because Canvas's own brand stylesheet sets the same names on `:root` at equal specificity and injection order alone is not safe.

| Variable | Set to | Note |
|---|---|---|
| `--ic-brand-font-color-dark` | `var(--pk-t1)` | Drives `$ic-font-color-dark` across ~230 `var(--ic-*)` references in Canvas's own CSS. This one override does most of the text work for free. |
| `--ic-brand-font-color-dark-lightened-15` | `var(--pk-t2)` | |
| `--ic-brand-font-color-dark-lightened-28` | `var(--pk-t3)` | These are the only two lightened derivatives Canvas computes. **There is no `-lightened-30`** — the incumbent ships six dead declarations using that name. |
| `--ic-link-color` | `var(--pk-accent)` | |
| `--ic-link-color-darkened-10` | `var(--pk-accent)` | |
| `--ic-link-color-lightened-10` | `var(--pk-accent)` | |
| `--ic-brand-global-nav-ic-icon-svg-fill` | `var(--pk-t3)` | Inactive rail icons. |
| `--ic-brand-global-nav-ic-icon-svg-fill--active` | `var(--pk-t1)` | Does double duty: active icon fill **and** the slide-out label's background. §4.1 pairs it with an explicit label colour. |
| `--ic-brand-global-nav-menu-item__text-color` | `var(--pk-t2)` | |
| `--ic-brand-global-nav-menu-item__badge-bgd` | `var(--pk-amber)` | |
| `--ic-brand-global-nav-menu-item__badge-text` | `var(--pk-amber-ink)` | 8.86:1 at Late. Never red. |
| `--ic-brand-global-nav-avatar-border` | `var(--pk-line)` | |

### 3.3 Variables derived from the school, never written

The nav ground is the important one, and it is done **without writing the variable at all** — the skin *reads* the school's value inside a `color-mix()` on the element:

```css
#header.ic-app-header,
#mobile-header {
  background-color: color-mix(in oklab, var(--ic-brand-global-nav-bgd) 16%, var(--pk-void));
}
```

Mix share: **100% Daylight (untouched) / 18% Dusk / 16% Late / 12% Low Beam.** The institutional hue survives at a fraction of the light output.

Three properties of this construction matter:

1. **No circularity and no flash.** The variable is read, not set, so the correct value is available at first paint with zero JS.
2. **`color-mix` failing to parse drops the whole declaration**, and Canvas's own `background-color: var(--ic-brand-global-nav-bgd)` stands. The school's original nav is the fallback, which is the right fallback.
3. **The share is capped by measurement, not taste.** With the worst case — a school running a pure white nav — the mixed ground gives `--pk-t2` **4.84:1 at Dusk, 5.10:1 at Late, 5.03:1 at Low Beam**. Any higher share and inactive nav labels fail AA. A light-nav school does lose more of its look than a dark-nav school; that is the honest cost of a dimmer and it is stated in the popup.

`--ic-brand-button--primary-bgd-darkened-15` is **read** for the press edge (§4.10) and never written. It is one of the 14 derivatives Canvas genuinely computes.

### 3.4 Variables deliberately left alone

`--ic-brand-primary` and its six derivatives · `--ic-brand-button--primary-bgd` and `--ic-brand-button--secondary-bgd` and their four derivatives · `--ic-brand-header-image` (the school logomark) · all 16 `--ic-brand-Login-*` · every watermark, Discovery and Registration variable.

Leaving `--ic-brand-button--primary-bgd` untouched is what makes the signature move true. Canvas emits it as its own literal on `:root`, so overriding `--ic-brand-primary` does not reach it.

### 3.5 What is not attempted

No MAIN-world injection. No `CANVAS_ACTIVE_BRAND_VARIABLES` patch. InstUI ships **zero** CSS custom properties (`@instructure/ui-themes@11.7.5`, 0 occurrences of `var(--`), so a `:root` override changes nothing InstUI paints — and content scripts cannot see page globals anyway. InstUI colour is treated as unreachable, not as a hard problem, and the product says so in words (§6).

### 3.6 Delivery, and the ship blocker

The extension today registers programmatically at `runAt: 'document_end'`. A dark-first skin arriving at `document_end` paints a full-brightness white page on **every navigation** — and Canvas is Rails multi-page, so that is a real document load several times a minute. That is not a polish item; it is the exact injury the concept exists to prevent, and it is worse than not installing, because the pupil has already adapted.

The fix is architectural and it ships before any design does:

- **Five CSS files.** `skin.css` (all structure, reads tokens) plus one of `step-day.css` / `step-dusk.css` / `step-late.css` / `step-low.css` (token block only, ~40 declarations).
- **`chrome.scripting.registerContentScripts` with `runAt: "document_start"`, `css: [shared, step]`.** Declarative injection before DOM construction, no attribute on `<html>`, no async storage read in the paint path, no flash in either direction. Registration persists across browser restarts.
- **Changing the step** = `removeCSS` the old file + `insertCSS` the new file on every open Canvas tab (immediate), then re-register (future loads). Both paths covered.
- **The light server skeletons are painted in that same static CSS**: `.ic-DashboardCard__placeholder-svg .ic-DashboardCard__placeholder-animates` [verified] and the empty `aside#right-side` [verified], so neither flashes white before React mounts.

This also kills shipped bug 3 by construction. Today tokens are declared on `.prepkin-cards`, which the popup can toggle off independently of `.prepkin-dark`, and `dark:true, cards:false` collapses the whole token system. Here the tokens live on `:root` in a file that is either present or absent, and the toggle matrix reduces to three independent, individually-safe dimensions: `{step file} × {tidy.css on/off} × {two inline hue properties}`.

**Host permissions:** `https://*.instructure.com/*`, `https://*.inscloudgate.net/*`, plus one optional user-granted host for self-hosted Canvas. `"all_frames": true`. **No `<all_urls>`. No `tabs`. No `webRequest`.**

### 3.7 The four navigation mechanisms

Required by constraint 13, and ~120 lines before any design lands. Canvas is not an SPA; it is Rails multi-page with React islands plus one react-router surface.

1. Static CSS at `document_start` — the primary mechanism, and most of the skin needs nothing else.
2. One debounced `MutationObserver` on `document.documentElement`, `{childList:true, subtree:true}`, 300ms trailing, wrapped in `requestAnimationFrame`. Only for the four jobs that must touch nodes: the dashboard spine, the planner spine, the sidebar due-pill match, the prose repair. **Never** two undebounced whole-document observers — that is the documented cause of the incumbent's "everything got slow" reviews.
3. The `canvasReadyStateChange` event on `window` with `detail === 'capabilities'` [verified]. A real "Canvas has booted" signal; React mounts well after `document.readyState` is complete.
4. Patched `pushState`/`replaceState`, plus `popstate` and `hashchange` (the Calendar drives itself entirely off `window.location.hash`).

No polling.

---

## 4. Tier 1, page by page

Every rule below is paint or an additive node. Confidence labels are the research doc's own. `[ours]` marks an attribute the extension sets on `<html>` at `document_start` from `location.pathname`.

### 4.1 Global left nav rail — every page

**Before:** a saturated institutional bar, full brightness, nine identical-weight icons, a red unread pill. **After:** the same bar at 16% of its light output with the school's hue intact, inactive items quiet, the active item marked by a 3px accent edge, the unread pill amber, and one drawn desk lamp after Calendar whose cone length tells you what step you are on.

| Selector | Conf. | Move |
|---|---|---|
| `#header.ic-app-header` | verified | Ground = `color-mix(in oklab, var(--ic-brand-global-nav-bgd) 16%, var(--pk-void))`. **No width is ever declared** — 54 / 84 / 104px all stay Canvas's. |
| `li.ic-app-header__menu-list-item--active` | verified | `box-shadow: inset 3px 0 0 var(--pk-accent)`; label `--pk-t1` at `--pk-wt-mid`. Server-rendered from `active_path?`, so correct on first paint, no flash. |
| `.ic-app-header__menu-list-link .menu-item__text` | verified | Background comes from `--ic-brand-global-nav-ic-icon-svg-fill--active` = `--pk-t1`, so an explicit `color: var(--pk-void)` is set here to make the flyout a light chip with dark ink. |
| `.menu-item__badge` | verified | `--pk-amber` / `--pk-amber-ink`, 8.86:1. Empty at first paint, filled by `NavigationBadges.tsx` — paint only, no reads. |
| `.ic-avatar img` | verified | Border `--pk-line`. Carries `fs-exclude`; never read, never copied. |
| `#primaryNavToggle` | verified | Icon `--pk-t3`, hover `--pk-t2`. |
| `#skip_navigation_link` | verified | **Never styled, never reordered, never moved in the tab order.** |
| `#global_nav_calendar_link` | verified | Anchor for the injected `<li>`, inserted after it. |

**The lamp.** One `<li class="ic-app-header__menu-list-item">` appended after `#global_nav_calendar_link`, inheriting Canvas's hover label, badge slot and active styling for free.

```html
<li class="ic-app-header__menu-list-item">
  <button class="ic-app-header__menu-list-link" type="button"
          aria-pressed="false" aria-label="Low Beam: Late. Turn Canvas up.">
    <div class="menu-item-icon-container" aria-hidden="true"><svg …/></div>
    <div class="menu-item__text">Low Beam</div>
  </button>
</li>
```

- **Role and keyboard.** A real `<button>` with `aria-pressed`, sitting in DOM order between Calendar and Inbox, so it is the sixth or seventh tab stop and needs no `tabindex`. Space and Enter both toggle. `aria-label` names the current step, so a screen-reader user hears the state without seeing the cone.
- **Behaviour.** Click toggles Daylight ⇄ your chosen dark step. That is the whole page-side control. The three dark levels live in the Prepkin popup as a three-stop slider.
- **The drawing.** 26×26 viewBox to match Canvas's own nav icons. 1.6px `currentColor` stroke, round caps. A trapezoid shade, a two-segment arm, an ellipse base. Below the shade sits a cone as a filled triangle in `--pk-accent` at `0.9` alpha, with four heights: **10 / 7 / 4 / 2px** at Daylight / Dusk / Late / Low Beam. Nothing else in the icon changes between states.
- **After 21:00 local**, the hover label reads "Turn it down" instead of "Low Beam", and a 2px `--pk-accent` dot appears at the base. That is the entire time-of-day behaviour: a word and a dot. **The step never changes itself.** Today's Night Shift forces dark by clock while the popup checkbox disagrees (shipped bug 8); that whole class of bug is removed rather than patched.
- **Sign-off gate.** This is new drawn art on an imposed school surface, so it inherits constraints 18 and 22 — George signs it off before it ships. **If it is not approved, the rail ships without it and the control is popup-only.** Nothing else in the spec depends on the icon existing.

**Degrades to.** Under the `instui_nav` flag the whole header is replaced (`mountPoint.innerHTML = ''`) and every `#global_nav_*` id disappears. Feature-detect `#instui-sidenav`; if present, **skip the injection entirely** and take the control from the popup only. The variable overrides simply stop matching and the school's own nav renders untouched. Below 768px the rail is `display:none !important` and the injected `<li>` goes with it — the mobile control is in `#mobile-header` (§5.8).

### 4.2 Breadcrumb bar

**Before:** a white strip with grey crumbs, a hidden first crumb leaving an odd gap, and a lot of empty space. **After:** the same strip on `--pk-void` with the current crumb promoted and everything else quiet — and the empty space stays empty.

| Selector | Conf. | Move |
|---|---|---|
| `.ic-app-nav-toggle-and-crumbs.no-print` | verified | Ground `--pk-void`, `--pk-edge` on the bottom via `inset 0 -1px 0`. |
| `#breadcrumbs > ul > li > a .ellipsis` | verified | `--pk-t2` at 0.875rem. |
| `#breadcrumbs > ul > li:last-child a .ellipsis` | verified | `--pk-t1`. The only place the current assignment title appears above the fold on a long page. |
| `#courseMenuToggle.ic-app-course-nav-toggle` | verified | Icon `--pk-t2`, hover surface `--pk-raise`. `aria-live` region untouched. |
| `.right-of-crumbs` | verified | Inherits. No rules. |

The chevron is a background image, `/images/breadcrumb-arrow-light.svg` [verified] — a light glyph, which is correct on a dark ground and already correct on Canvas's own light one. Left alone.

**Degrades to.** Blank under `@instui_topnav` (`#react-instui-topnav` replaces the whole bar, hashed, unreachable) — the rules match nothing and the school's bar renders stock. Absent on the dashboard entirely (`user_dashboard` calls `clear_crumbs`), and `display:none` below 768px and under `body.no-headers` / `.content-only` / `.embedded`.

**Refused:** the persistent Prepkin status strip. The research names this bar as the best home for one, and I am declining. The same information is already in the sidebar and now on every Modules row, a fourth copy is noise, and a branded strip on a school page is the one thing a professor notices over a shoulder. **The empty half of the breadcrumb bar stays empty.**

### 4.3 Flash toasts and admin banners

**Before:** four coloured toasts on a white page. **After:** the same four toasts, exactly the same colours, with a defined edge so a bright toast on a near-black page does not bleed.

| Selector | Conf. | Move |
|---|---|---|
| `#flash_message_holder > div[class^='ic-flash-']` | verified | `border-radius: 12px` and `box-shadow: 0 0 0 1px var(--pk-void)`. **No fill, no text colour, nothing else.** Match by prefix — the four types are built from a template string, so never enumerate. |
| `#announcementWrapper > .ic-notification.ic-notification--admin-created` | verified | Ground `--pk-card`, ring, `--pk-t1` on `h2.ic-notification__title`, `--pk-t2` on the body. |
| `span.notification_message` | verified | **No rule.** This is `user_content(safe_html: true)` from an admin, so it is arbitrary HTML and no structure is assumed inside it. |
| `.ic-notification + .ic-dashboard-app` | verified | Element order preserved; the adjacency spacing rule is not broken. |

Canvas's `ic-flash-error` **keeps the platform's own red.** Overriding an error semantic is dangerous, and the skin adds no red of its own. Account notifications inline a `<script>` defining `showGlobalAlert()` and use an `onClick` attribute, so nodes are never removed or re-parented — dismissal keeps working.

**Degrades to.** Toasts are injected at runtime; these are pure CSS on a prefix match, so a missed hook leaves Canvas's stock toast, which is already legible.

### 4.4 Dashboard, card view

**Before:** white cards, each topped by 146px of information-free course colour, teacher photos at full brightness, and a ragged right edge from an inline-block grid with negative gutters. **After:** cards on the ladder with a light-catching top edge, a course-colour spine that is present at every step, a hero that shrinks as the lamp goes down, photos dimmed rather than hidden, and a real grid.

| Selector | Conf. | Move |
|---|---|---|
| `#DashboardCard_Container` | verified | Observer root. |
| `.ic-DashboardCard__box > .ic-DashboardCard__box__container` | verified | `display: grid; grid-template-columns: repeat(auto-fill, minmax(262px, 1fr)); gap: 24px; margin: 0;` — the `-36px` negative gutters are zeroed **in the same declaration block**, so it can never half-apply into overlap. |
| `.ic-DashboardCard` | verified | `--pk-card`, radius 12, `box-shadow: inset 0 0 0 1px var(--pk-line), var(--pk-edge)`, `width: auto`, `margin: 0`. |
| `.ic-DashboardCard__header_hero`, `.ic-DashboardCard__header_image` | verified | `height: var(--pk-hero)` **in one rule covering both**, so an image card and a colour card collapse identically. `opacity` is never read, written or `!important`-ed. |
| `.ic-DashboardCard__header_image` | verified | `filter: brightness(var(--pk-img))`. Teacher photos are the brightest object on a 2am dashboard; dimming beats the community's usual answer of hiding them. |
| `.ic-DashboardCard` (JS) | verified | A 3px left spine painted from the course's own hex, read from the hero's inline `backgroundColor` [verified §4.5]. **Present at every step, not just the deepest.** |
| `.ic-DashboardCard__header-title.ellipsis` | verified | `--pk-t1` at `--pk-wt-head`. The inner `<span style="color: …">` is **never** recoloured — with Color Overlay off it is the last colour cue on the card. |
| `.ic-DashboardCard__header-subtitle`, `.ic-DashboardCard__header-term` | verified | `--pk-t2` at 0.875rem. |
| `nav.ic-DashboardCard__action-container` | verified | `--pk-card`, `inset 0 1px 0 var(--pk-line-soft)` above. |
| `.ic-DashboardCard__action-badge` | verified | Left in `--ic-brand-primary`. Note the assignments badge is permanently 0 (Canvas bug CNVS-21227); this skin does not fill it. |
| `.ic-DashboardCard__placeholder-svg .ic-DashboardCard__placeholder-animates` | verified | Painted onto the ladder in the **static** sheet so the server-rendered light skeleton never flashes before React mounts. |
| `#dashboard_header_container.ic-Dashboard-header` | verified | `--pk-void`, h1 `--pk-t1`. `position:sticky; z-index:5` untouched. |

**Why the hero shrinks but never disappears.** 146 → 96 → 56px is a reduction in chromatic *area*; the hex is byte-for-byte Canvas's at every step. The 56px floor plus the always-on spine means the two colour cues can never both be gone. If `custom_colors` and the inline hero style are both unavailable, there is no spine — and the hero is still 56px of the course's own colour.

**Degrades to.** Everything is paint on classes Canvas hand-writes in React; an empty container matches nothing and leaves a plain dark ground. Cards are drag-reorderable and get inline `opacity: 0` while dragging — **nothing here reads or writes opacity**, so drag is untouched. Under `unpublished_courses_redesign` one container becomes two `.ic-DashboardCard__box` sections and the grid rule applies to both. Under `widget_dashboard` there is no server markup at all (`render html: "", layout: true`) — detect the absence of both `#DashboardCard_Container` and `#dashboard-planner` and hand over to the popup.

### 4.5 Dashboard, list view (Planner)

**Before:** a flat chronological list where every row has identical weight, and missing work hidden behind a bell most students never open. **After:** the list recedes into the future using nothing but the ladder — today is a card, tomorrow is the page, next week is the page at `--pk-t2` — without a single size change.

| Selector | Conf. | Move |
|---|---|---|
| `#dashboard-planner.StudentPlanner__Container` | verified | `--pk-void`. |
| `[data-testid="planner-item-raw"]` | verified | Row. `--pk-page`, radius 8, `--pk-edge`. |
| `[data-testid="day"]` | verified | Day block. First day = `--pk-card`; second = `--pk-page`; third and beyond = `--pk-page` with `--pk-t2` on the row title. Applied by index in JS, colour only. |
| `[data-testid="today-date"]` | verified | The one `--pk-accent` mark on the page. |
| `[data-testid="not-today"]` | verified | `--pk-t2`. |
| `[data-testid="planner-item-completed-checkbox"]` | verified | Checked state gets a drawn `--pk-accent` check, 2px stroke. Canvas's own state made visible. |
| `#dashboard-planner-header` | verified | `--pk-void`. |
| `.Grouping-styles__items` | **likely** | Read only, never styled: the inline `borderColor` on the grouping `<ol>` is the course colour, and it paints a 3px spine on the day block. If the class misses there is no spine and nothing else changes. |
| `#planner-app-fixed-element` | verified | **Never touched, never repositioned.** |
| `.PlannerItem-styles__*` | **disputed** | **Not used.** Verdict 2 says the CSS-Modules generation is gone from `PlannerItem/index.tsx`. This also retires shipped bug 4 (`.prepkin-dark .PlannerItem-styles__container`, which matches nothing). |

**Specificity.** Planner components inject their own `<style>` elements later in the document than any extension sheet, at equal specificity. Colour declarations here therefore carry `!important` — an important author rule beats a non-important one regardless of order — scoped as `#dashboard-planner [data-testid="…"]`. **Only colour. Never layout, never position, never display.** When a testid churns the rule stops matching and the row is a plain readable row.

**Refused: the missing-work count.** The research is right that Opportunities is hidden behind a bell most students never open, and surfacing it would be a real behaviour change. It is still cut. A number that says how far behind you are is a number that goes down, it is pinned to the dashboard every single day, and a student six assignments behind sees their failure every time they open Canvas. Individual overdue rows still get the amber "still counts" pill (§4.6). There is no aggregate anywhere in this skin.

**Degrades to.** Infinite scroll loads and unloads days in both directions, so the spine and day-index pass re-run on the debounced observer. The right sidebar is force-hidden in this view, so **nothing Prepkin owns is ever parked in `#right-side`.**

### 4.6 Right sidebar — To Do, Coming Up, Recent Feedback

**Before:** three grey widgets where the due date — the thing the student is actually scanning for — is plain grey text buried after a bullet, and the grade sits at the same weight as the teacher's comment. **After:** the due date is the brightest thing in the column, the grade is a chip you can read without reading the sentence around it, and nothing is parsed out of a translated string.

| Selector | Conf. | Move |
|---|---|---|
| `#right-side-wrapper.ic-app-main-content__secondary` | verified | `--pk-void`. Width and breakpoints inherited. |
| `aside#right-side` | verified | Painted in the **static** sheet, because on the dashboard this starts empty and is filled by an XHR to `/dashboard-sidebar`. |
| `.Sidebar__TodoListContainer` | verified | Widget → `--pk-card`, radius 12, ring, `--pk-edge`. |
| `[data-testid='ToDoSidebar'] > h2.todo-list-header` | verified | `--pk-t2`, 0.8125rem, `--pk-track`. The heading is deliberately *not* the loudest thing. |
| `.ToDoSidebarItem__Title` | verified | `--pk-t1`, 0.9375rem. |
| `.ToDoSidebarItem__Info` | verified | Due line. `display: block; margin-top: 4px; color: var(--pk-t1); font-weight: var(--pk-wt-mid); font-variant-numeric: tabular-nums;` |
| `.events_list.coming_up … li.event` | verified | Row on `--pk-page`, radius 8. |
| `b.event-details__title` | verified | `--pk-t1`. |
| `p.event-details__context` | verified | `--pk-t2`, 0.8125rem. |
| `.events_list.recent_feedback li.event a.recent_feedback_icon` | verified | Grade `<strong>` → `--pk-band` chip, `--pk-t1`, tabular-nums, radius 6. Neutral. No colour, no green, no red, no comparison. |
| `a.more_link` | verified | `min-height: 32px`, `--pk-accent`, permanent underline. |
| `ul.right-side-list.to-do-list li.todo .todo-badge` | verified | Legacy path, styled identically — a student who also TAs a course gets this markup instead of the React list. |
| `.ic-sidebar-logo img.ic-sidebar-logo__image` | verified | Untouched unless the student turns on the existing tidy option. |

**The amber pill, and why it does not parse anything.** The concept planned to regex `"N points • Sep 5 by 11:59pm"` into an urgency pill. That string is `I18n`-rendered and breaks on any non-English Canvas — the same mistake as using `#modules-link`, which this spec correctly refuses elsewhere. **The pill is driven by data the extension already has.** Per `SPEC.md §4` the extension already calls `/api/v1/users/self/todo` and `/api/v1/users/self/upcoming_events` with the session cookie and stores real ISO dates in `chrome.storage.local`. The pass matches each row's own `href` (`/courses/:id/assignments/:id`) against that list and, when the stored `due_at` is in the past, adds `class="pk-still"` to the due line, which paints `--pk-amber` / `--pk-amber-ink` at 8.86:1 and reads "still counts". No string parsing, no locale dependence, no new network request.

**Degrades to.** If the stored list is empty or the hrefs do not match, no pill — the due line is still promoted to `--pk-t1`, which is most of the value. If the observer never fires at all, the CSS still lands and the student sees Canvas's plain grey string on a correctly dark surface: quiet, not broken. Below 992px the column stacks under the content rather than hiding, and the card rules are width-agnostic.

### 4.7 Course navigation menu

**Before:** 8–14 tabs of identical weight that students navigate by position, not by word. **After:** the same list in the same order, with the four tabs a student actually opens held at `--pk-t1` and the rest quiet — hierarchy paid for out of the light budget, so nothing anyone has memorised moves.

| Selector | Conf. | Move |
|---|---|---|
| `#left-side.ic-app-course-menu.list-view` | verified | `--pk-void`. **`display` is never set** — `toggleCourseNav.js` writes inline display and a competing rule can strand the menu closed. **No width is declared**; 192px / 218px are inherited. |
| `#sticky-container.ic-sticky-frame` | verified | Transparent. `.has-scrollbar` untouched. |
| `ul#section-tabs`, `#section-tabs > li.section` | verified | Reset padding to the 4px rhythm. |
| `#section-tabs a.home, a.modules, a.assignments, a.grades` | verified | `--pk-t1`, `--pk-wt-mid`. The `css_class` is a hardcoded English token from `Course#tabs_available` and is never translated. |
| `#section-tabs a` (all others) | verified | `--pk-t3`. |
| `#section-tabs a.active`, `#section-tabs a[aria-current='page']` | verified | `--pk-raise` fill, `--pk-t1`, and a 3px `--pk-accent` left edge that replaces Canvas's own 2px border colour without changing its structure. |
| `#left-side` (JS) | verified | 3px spine in the course's own colour, read from `GET /api/v1/users/self/colors` keyed by `context-course_<id>` from the body class. Canvas gives the course nav no course colour at all; this restores the cue the dashboard already has. |
| `#modules-link`, `nav[aria-label=…]` | verified | **Never used.** `a_id` is built from the localised label (`#modulos-link` on a Spanish Canvas) and the nav label is `I18n.t`. |
| `#section-tabs-header` | guess | **Treated as absent.** No emitter in current ERB. |

**Degrades to.** External LTI tabs get an unpredictable per-institution `css_class`, so they are handled by exclusion and get the quiet `--pk-t3` treatment. The tab list is cached server-side for an hour, which is irrelevant to paint. `#left-side` is absent on `@content_only` pages and inside LTI frames.

**Cut from the concept: the seam glyph.** A 10px outlined square with an open corner, appended to `a.files` and to unknown tabs, telling the student in advance that a page comes from a system the skin cannot repaint. It is decoration wearing an information costume — it explains the extension's own limitation, inside the student's navigation, in a mark nobody will decode. The explanation belongs on the seam itself, at the moment of confusion, in words (§6). **Tab order is never changed** and no tab is ever demoted below a divider.

### 4.8 Course home

Five completely different DOM structures behind one URL, chosen by `@course_home_view`. The skin branches on the mount that is present and adds nothing that assumes the others.

| Selector | Conf. | Move |
|---|---|---|
| `#course_home_content` | verified | `--pk-page`. The one rule every variant shares. |
| `#wiki_page_show` | verified | Front Page variant → §4.9's `.user_content` prose rules apply verbatim. |
| `#announcements_on_home_page` | verified | `--pk-card` block, ring, `--pk-edge`. |
| `#course_home_content ul.recent_activity` | verified | Feed variant → the Recent Activity rules (§5.x) apply for free. |
| `#course_home_content .fake-link`, `.stream_header .links` | verified | `--pk-accent`, underlined. |
| `a.btn.button-sidebar-wide` | verified | `.btn` treatment (§4.10). |
| `body.context-course_<id>` | verified | **Read, never styled.** Used only to key the course colour lookup. |

**Refused: per-course theming.** `body.context-course_<id>` makes it trivial to give every course its own palette site-wide. It is declined. The course colour is the student's navigation cue and it works because it is small and consistent; a whole page tinted per course makes the cue meaningless and multiplies the contrast surface by the number of courses a student takes.

**Degrades to.** Front Page and Modules variants are React mounts; if `#course_home_content` is the only thing that matches, the page is a plain ground with correct text. Under `body.course-menu-expanded` the desktop breakpoint moves 992px → 1140px — no rule here declares a breakpoint, so it follows.

### 4.9 Modules — the highest-complaint page

**Before:** a grey wall where a page, a quiz, an assignment and an external link look identical, and the due date is buried mid-row inside a details cluster. **After:** module headers read as bands and their contents as rows, and every due date is right-aligned in one tabular column you can scan straight down without reading a single title.

| Selector | Conf. | Move |
|---|---|---|
| `.item-group-container#context_modules_sortable_container` | verified | `--pk-void`. |
| `.context_module` | verified | `--pk-card`, radius 12, ring, `--pk-edge`, 24px gap. |
| `.ig-header.header` | verified | `--pk-raise` band, `--pk-t1` at `--pk-wt-head`, 1.25rem, `--pk-track`. |
| `.ig-header-title.collapse_module_link` | verified | Chevron `--pk-t2`, 32px hit area. |
| `.ig-row` | verified | `--pk-page`, radius 8, 12/14 padding. Hover → `--pk-raise` (a ladder step, so it cannot reduce contrast). |
| `.ig-info` | verified | **The one layout rule on this page:** `display:flex; flex-wrap:wrap; align-items:baseline; gap:8px 16px;` |
| `.ig-details` | verified | `margin-left:auto; text-align:right;` — pushes the details cluster to the right edge of the row. |
| `.due_date_display` | verified | `--pk-t1`, `font-variant-numeric: tabular-nums; min-width: 9ch; display:inline-block; text-align:right;` **This is the due column.** |
| `.due_date_display.pk-still` | ours | Amber pill when the stored `due_at` for that href is past, at 8.86:1. Same data path as §4.6. No parsing. |
| `.ig-details__item` | verified | `--pk-t2`, 0.8125rem. |
| `.completion_requirement` | verified | Met → a drawn 2px `--pk-accent` check. Unmet → `--pk-t3` text. Canvas's own state, made visible. **No meter, no percentage, no "3 of 8".** |
| `.context_module_item.indent_1` … `.indent_5` | verified | Real 20px steps, so indent levels read as a hierarchy instead of a hint. |

**The due column, stated honestly.** This is a graft from *Margin Notes* and it is the only structural answer in this spec to the students' number-one complaint. It is one rule pair, no JS, and it also covers the Assignments index for free because `.ig-row` grammar is shared (§5.1). **It does not remove a single click.** Modules gets readability and a scannable due column; complaint 3 — "I had to click through five different links" — is untouched, and the spec does not imply otherwise.

**Degrades to.** `context_modules_v2` is a full React rewrite sitting in master where **exactly one hook survives: `className="context_module_item"` on the outer View.** Every rule above is paint or a flex container, so when `.ig-row`, `.ig-header` and `.ig-info` stop matching, the page falls back to `--pk-page` with `--pk-t1` text and stays completely readable. The one layout rule fails safely too: `flex-wrap: wrap` means a long title pushes the details cluster to a second line rather than squashing it, and if `.ig-details` is absent, `margin-left:auto` matches nothing.

**Refused: type-coded rows.** The page map verifies no per-type class on `.context_module_item`. Inventing one would be a guess. Type marks wait until a class is confirmed against a live DOM.

### 4.10 Assignment detail — the page nothing reaches today

**Before:** white prose on white, at Canvas's default measure, with a submit button somewhere below it. Today's shipped skin does **nothing at all** on this page. **After:** real reading typography at 68 characters, a due-and-points band you can read in one glance, and a submit button that is the only thing on the page still at full colour — and the only thing that moves when you press it.

| Selector | Conf. | Move |
|---|---|---|
| `#assignment_show` | verified | Legacy ERB root (274 lines). `--pk-page`. |
| `#assignment_head` | verified | `--pk-raise` band, radius 12, ring; due and points at `--pk-t1` tabular-nums; labels `--pk-t2`. |
| `[data-testid="assignments-2-student-view"]` | verified | Assignment Enhancements React root, styled **separately and independently**. Neither path depends on the other. |
| `[data-testid="student-content-flex-container"]` | verified | Inner layout container, ground only. |
| `#assignment_external_tools` | verified | Plain stable id inside the React page. Ground only. |
| `.user_content` | verified | `1.0625rem / 1.65 / 68ch`; `--pk-t1`; headings at `--pk-wt-head`; `a` → `--pk-accent` with a **permanent** underline; paragraph gap `0.9em`. **No rule assumes internal structure** — this is arbitrary teacher HTML. |
| `.user_content img` | verified | `filter: brightness(var(--pk-img))`. Never `invert()`. |

**The prose repair.** A bounded JS pass over `.user_content [style*="color"], .user_content [style*="background"]` — usually a handful of nodes. For each, measure the computed colour against the current ground; below 4.5:1, add `class="pk-ink"`, which sets `color: var(--pk-t1)`. A near-white inline background on a dark step gets `background-color: var(--pk-raise)` instead, and the text pass then re-runs against the new ground. **Bounded: first 60 matching nodes, and the whole pass aborts above 200 matches** (a pasted spreadsheet). The pass only ever *adds a class* — it never removes or rewrites markup, so a failure leaves the teacher's original inline colour intact. This is what fixes the teacher who pasted black-on-white out of Word into a page that is now dark.

**The submit affordance — the hard exception.**

```css
.btn-primary, input[type=submit] {
  /* no color, no background-color, no opacity, no filter, at any step, ever */
  border-radius: 12px;
  box-shadow: 0 0 0 1px var(--pk-btn-ring),
              0 3px 0 var(--ic-brand-button--primary-bgd-darkened-15);
  transition: transform var(--pk-dur) cubic-bezier(.2,0,0,1),
              box-shadow  var(--pk-dur) cubic-bezier(.2,0,0,1);
}
.btn-primary:active, input[type=submit]:active {
  transform: translateY(3px);
  box-shadow: 0 0 0 1px var(--pk-btn-ring), 0 0 0 var(--ic-brand-button--primary-bgd-darkened-15);
}
```

**Shape is ours, colour is theirs.** The 12px radius, the 3px edge and the press travel are Prepkin's. The fill, the label and the edge colour are Instructure's own computed values, so contrast inside the button is byte-for-byte the school's. `-button--primary-bgd-darkened-15` is one of the 14 derivatives Canvas genuinely computes [verified §4.2 rule 4] — unlike the six dead `-lightened-30` declarations the incumbent ships.

The **ring** is what makes the headline provable. A dark-navy school primary such as `#394B58` sits at 1.93:1 against `--pk-page` at Late — a submit button that is nearly invisible, which is the incumbent's worst bug arriving through the front door. The 1px `--pk-btn-ring` fixes it without touching a single colour inside the control. §9.5 has the full proof and the escalation rule.

The rule extends to **`[data-testid="assignments-2-student-view"] .btn-primary`** and **`body.native-new-quizzes`**: on both, the submit control is InstUI and unreachable, therefore *untouched*, therefore already at full institutional brightness. The guarantee is negative and holds by construction: **no container that can hold a submit affordance is ever veiled.** The only veiled surfaces are Files v2's `#content` and a nav tray, neither of which has one.

**Degrades to.** Two entirely different DOMs behind one URL, styled separately; if one root is absent its rules are inert. If `--ic-brand-button--primary-bgd-darkened-15` is absent the shorthand falls back to a flat button with a ring — no travel, still visible, still pressable.

### 4.11 Grades

**Before:** a spreadsheet — vertical rules, zebra stripes, and the one number the student came for sitting in the same weight as everything else. **After:** a list of rows with the score as the only promoted cell, and the final grade lifted out of the middle of the table to the top of the column.

| Selector | Conf. | Move |
|---|---|---|
| `#grade-summary-react` | verified | **Gate. If this element exists, every rule below is skipped.** `#grades_summary` and `.student_assignment` are already dead for any course with `restrict_quantitative_data` on, with no feature flag needed (Correction 5). |
| `#grades_summary` | verified | `border-collapse: separate`, all vertical rules and all zebra striping removed. |
| `#grades_summary tr` | verified | `--pk-page`, separated only by `box-shadow: inset 0 -1px 0 var(--pk-line-soft)` (1.12–1.24:1 — a whisper). |
| `.assignment_score .grade` | verified | The one `--pk-t1` cell, `--pk-wt-mid`, `font-variant-numeric: tabular-nums`. |
| `.possible.points_possible`, `.due`, `.details` | verified | `--pk-t2`, 0.8125rem. |
| `.letter_grade`, `.group_weight` | verified | `--pk-t3`. |
| `.comment_count` | verified | `--pk-t2`, 24px hit area. |
| `#student-grades-final` | verified | Lifted to a `--pk-card` block with a ring and `--pk-edge` at the top of `#student-grades-right-content`, instead of a table row lost mid-page. |
| `.react_pill_container` | verified | `--pk-band` chip, `--pk-t1`, radius 999 — so these React islands stop rendering as white pills on a dark table. |
| `.min`, `.max`, `.median` | verified | `--pk-t3`, and **nothing else**. |

**Degrades to.** Colour and hairlines on per-cell semantic classes, so a missed selector leaves an ordinary readable table.

**Refused:** the distribution bar, the what-if calculator, and any letter-grade colouring. `.min` / `.max` / `.median` are legible and receive no treatment at all — that is a refusal, not an oversight. A distribution bar is comparison to peers, and this product does not pay for or dramatise performance.

### 4.12 Global nav trays

**Before:** at 2am, clicking Courses opens a full-height white panel. **After:** the panel is dimmed to 86% of its light, still Canvas's own layout and typography, with each course row prefixed by the colour the student picked for it.

| Selector | Conf. | Move |
|---|---|---|
| `.navigation-tray-container` | verified | Ground `--pk-void` behind the content. The modifier is built as `` `${type}-tray` `` — `courses-`, `groups-`, `accounts-`, `profile-`, `history-`, `help-`. |
| `.navigation-tray-container .tray-with-space-for-global-nav` | verified | `filter: brightness(var(--pk-veil))`. **This is the inner offset div, not InstUI's fixed tray root** — the target is chosen specifically so the filter cannot create a containing block for the tray's own `position: fixed`. |
| `.navigation-tray-container a[href^="/courses/"]` | verified wrapper + attribute | 3px left spine in that course's colour from `/api/v1/users/self/colors`. Attribute matching, never a class. |
| `#global_nav_tray_container` | verified | The legacy React root at the end of `#header`. Ground only. |
| `.tray-with-space-for-global-nav` margin | verified | **Never declared.** It is 54px / 84px depending on rail state. |

**Why a veil here and nowhere else in chrome.** Everything inside the wrapper is InstUI with hashed names and a JS-computed theme. Repainting the ground without being able to reach the ink would produce Canvas's own dark `#2D3B45` text on a dark ground — a broken page, not a plain one. The veil lowers the white ground to `#DBDBDB` and lowers the ink with it, holding `#2D3B45` on white at **9.35:1**, down from 11.8:1. It cuts the light without ever needing to know what the ink is.

**Degrades to.** If a future InstUI version places a `position: fixed` descendant inside `.tray-with-space-for-global-nav`, it would position relative to the tray instead of the viewport. Inside a full-height tray that is a small visual difference, not a broken page, and the veil has a one-click off (§6). If `.tray-with-space-for-global-nav` disappears, the tray renders stock white — the status quo. Trays are `React.lazy`, so the DOM does not exist until first open; the spine pass runs on the debounced observer, never a one-shot query. The tray mounts into a portal **outside `#application`**, so no rule here is rooted there.

**Refused:** the tray footer ("Next due: X in 2 days"). Same reason as the breadcrumb strip.

---

## 5. Tier 2, briefly

| Page | Selectors | Move | Degrades to |
|---|---|---|---|
| **5.1 Assignments index** | `.assignment_group`, `.ig-header`, `.collectionViewItems.ig-list.draggable`, `.ig-row`, `.ig-info`, `.ig-details`, `.ig-details__item.assignment-date-due`, `.js-score`, `.item-group-condensed` — all verified | **Free.** The §4.9 Modules ruleset covers it unchanged, including the right-aligned tabular due column and the amber pill. `.js-score` gets the `--pk-band` grade chip from §4.6. | Backbone/Handlebars renders this at runtime, so it is observed, not queried once. Missed hooks leave a plain list. |
| **5.2 Inbox** | `[data-testid="conversation"]`, `-conversationListItem-Item`, `-unread-badge`, `-read-badge`, `-last-message-content`, `[data-testid^="open-conversation-for-"]` (prefix-match) — verified | Row `--pk-page` + `--pk-edge`; unread badge `--pk-amber`; preview `--pk-t2`; sender `--pk-t1`. Additive only — `ConversationListItem.tsx` has **zero** `className` attributes, so nothing here fights an InstUI rule. | Mounts into `#content`, so the legacy skeleton already carries the ground. A renamed testid leaves a correctly-dark, unstyled list. |
| **5.3 Discussions** | `[data-testid="discussion-topic-container"]`, `-highlight-container`, `-discussion-topic-reply`, plus `.discussion-topic-reply-button` (a real non-hashed legacy class inside React) — verified | Thread root `--pk-page`, entries `--pk-card` + ring + `--pk-edge`, `.user_content` prose rules from §4.10 apply verbatim. | Paint only. |
| **5.4 Quizzes (classic)** | `#quiz_show`, `#quiz-publish-link` — verified | Fully legacy, 391 lines of ERB. Header band `--pk-raise`, question blocks `--pk-card`, `.user_content` prose, and the §4.10 submit treatment. **This is not New Quizzes** (§6). | Paint only. |
| **5.5 Calendar** | `.fc-*` — FullCalendar's own public API, stable across Canvas versions | Grid lines `--pk-line-soft`, day cells `--pk-page`, today `--pk-raise` with an `--pk-accent` date. **Event colours are Canvas's, from the same `custom_colors` map as the dashcards, and are never touched.** | Hash-driven navigation, so the `hashchange` listener (mechanism 4) is required for anything JS-driven. All of the above is CSS. |
| **5.6 Pages / wiki** | Backbone shell around `.user_content` — verified | Shell chrome on the ladder; §4.10 prose rules inside. Never assume structure in teacher HTML. | Paint only. |
| **5.7 Syllabus** | Same shell; plus the syllabus table gets §4.11's no-zebra, no-vertical-rules treatment | | Paint only. |
| **5.8 Mobile header** | `#mobile-header` (verified), `.mobile-header-hamburger`, `#mobileHeaderInboxUnreadBadge`, `.mobile-header-title.expandable`, `#mobileContextNavContainer[aria-expanded='true']` | Ground = the same `color-mix` read of `--ic-brand-global-nav-bgd` as the rail, so the phone and desktop chrome agree. **The lamp control appears here as a 32px button inside `.mobile-header-space`** — the bar is ~56px and mostly empty, so it fights nothing. | `#mobile-header` is `display:none` at ≥768px, and the rail is `display:none` below it, so exactly one lamp exists at any width. **`MobileNavigation` binds `touchstart` with `preventDefault` on the hamburger** — no listener is ever added there. |

**Tier 3** — profile tray, dashboard kebab, People, profile settings, Groups, Outcomes/Rubrics/Conferences/Collaborations — inherit the ground, the link colour, `.btn`, the type scale and the focus ring from the global rules, and get **no page-specific CSS at all**. One exception: one Prepkin settings row appended to `.profile-tray`, which is how the product reads as native rather than bolted on.

---

## 6. The seam

Three tiers, chosen by what can be *proved* about a surface — not by whether it is React. The tier is stated in the product, not hidden.

### Tier A — repainted for real

Both of these were called unreachable in the concept and in §4.4 of the research. The Corrections block overturns both.

| Surface | Hook | Conf. | What happens |
|---|---|---|---|
| **New Quizzes** | `body.native-new-quizzes > #new-quizzes-root > #root` | verified (Correction 2) | Stopped being an iframe on **2026-08-15** when `new_quizzes_native_experience` was enforced. Same-origin, top-frame CSS. Container ground, spacing and typography only — the interior is module-federated InstUI, so no colour is set on any control, and the submit affordance is untouched. |
| **Canvadocs / DocViewer** | second content-script instance inside the frame | verified (Correction 1) | `"all_frames": true` plus `https://*.inscloudgate.net/*` and `https://*.instructure.com/*`. A content script is injected per frame, matched by that frame's own URL, with full DOM and CSS access. Isolated-world CSP has no `style-src`, so the host page cannot block the injected sheet. The document shell gets the ladder; the page canvas itself is left alone. |

### Tier B — veiled

Two surfaces, both same-origin, both documents the skin owns but cannot select into, neither containing a submit control.

| Surface | Hook | Conf. | Note |
|---|---|---|---|
| **Files v2** | `html[data-pk-route="files"] #content.ic-Layout-contentMain` | ours + verified | `FileFolderTable.tsx` and `FilesHeader.tsx` contain **literally zero `className` attributes**. There is nothing to select and never will be. The route attribute is set on `<html>` at `document_start` from `location.pathname`, before the body exists, so there is no flash. InstUI modals portal to `document.body`, outside `#content`, so the filter cannot reach them. |
| **Global nav trays** | `.navigation-tray-container .tray-with-space-for-global-nav` | verified | §4.12. |

**The veil's arithmetic, stated correctly.** `filter: brightness(k)` multiplies sRGB channel values by *k*, which scales the light term and leaves black at zero, so the contrast ratio **always falls**. It never rises. Measured:

| k | White ground becomes | Black ink | Canvas ink `#2D3B45` | AA-floor grey `#767676` |
|---|---|---|---|---|
| 1.00 | `#FFFFFF` | 21.00:1 | 11.83:1 | 4.54:1 |
| .94 (Dusk) | `#F0F0F0` | 18.43:1 | 10.71:1 | **4.41:1** |
| .90 (Late) | `#E6E6E6` | 16.83:1 | 10.06:1 | **4.33:1** |
| .86 (Low Beam) | `#DBDBDB` | 15.17:1 | 9.35:1 | **4.21:1** |

**There is no factor below 1.0 that preserves a pair already sitting at exactly 4.54:1.** Even .96 lands it at 4.45:1. So "pick a safer k" is not an available answer, and the concept's .78 was simply worse (3.96:1). The honest statement is: **the veil cuts emitted light and costs about 8–11% of the contrast ratio. Nothing that starts at AAA lands below AA. Text that starts at exactly the AA floor lands just under it, at 4.21:1 in the worst case, on two surfaces whose ink is overwhelmingly `#2D3B45`.**

The mitigation is control, not arithmetic: **the veil is the one thing in the sheet with a per-surface off switch** — a 24px button in the caption strip, `aria-pressed`, one click, remembered per origin. That converts a stated accessibility cost into the student's own choice, which is where it belongs.

### Tier C — named and left alone

| Surface | What the student gets |
|---|---|
| **Third-party LTI** — publisher tools (Pearson, McGraw-Hill, Cengage), Google Assignments, Office 365, Studio | `.tool_content_wrapper` [verified] gets a `--pk-void` gutter, 12px radius, a 1px `--pk-line` ring and 22px of top padding holding an absolutely-positioned `--pk-band` caption strip at `--pk-t2`, 0.8125rem: **"Your school's page. Prepkin can only dim it."** The frame itself keeps every pixel Canvas gives it. |
| **InstUI modals** | Not reached. They portal to `document.body` with no stable wrapper, and `.navigation-tray-container.{type}-tray` — the only verified wrapper — covers the six global-nav trays and nothing else. Left in Canvas's own colours. |
| **`instui_header` page headers** | Not reached. Same reason. |
| **Proctoring** — Proctorio, LockDown, Respondus | **Nothing at all.** No filter, no caption, no ring, no ground. Excluded in pure CSS with `iframe#tool_content.tool_launch:not([src*="proctor"]):not([src*="respondus"]):not([src*="lockdown"])`, and again by a route gate. |

**Why no LTI frame is ever filtered.** The concept veiled `iframe#tool_content.tool_launch`, which is *every* LTI launch — and that set includes proctoring vendors that actively detect extension interference with their frame. Dimming a proctored exam is an academic-integrity hazard for the student and the single most block-worthy thing the concept contained. It is one `:not()` chain to remove and it costs almost nothing, because Correction 2 already moved the biggest exam surface out of an iframe and into markup this skin repaints properly.

**The design idea that survives.** A surface the skin cannot prove is not half-painted and not apologised for — it is **framed**: a bounded, ringed, captioned white panel sitting in a dark page. A lit window in a dark room. That is composition, not a failure, and it is the only honest thing to do with a document whose ink you cannot see.

---

## 7. Dark

Dark is three steps, not one, and it is not an inversion. Five things happen across them that a switch cannot do.

**1. The text ceiling comes down at the deepest step.** `--pk-t1` goes `#E0D9CC` → `#C9C1B3`, and the page ratio falls **12.47:1 → 10.39:1**. That is deliberate. Near-white on near-black haloes for astigmatic and Irlen readers, and WCAG's 7:1 AAA is a floor, not a target. Every ratio in the sheet stays above AAA while absolute light output drops by roughly half.

**2. Chromatic area shrinks; chromatic value never does.** The 146px course hero steps to 96px and then 56px, and the 3px spine is present at every step. The hex is the exact value Canvas gave, still the navigation cue, just no longer a saturated 146×262px panel a foot from your face. `opacity` is never touched, so a student with `hide_dashcard_color_overlays` on sees no change from this skin at all.

**3. Shadows go to zero and objects separate by a caught edge.** `--pk-shadow` is `none` at every dark step. A drop shadow on near-black is invisible and only muddies the step below it. Instead every card, band and row carries `inset 0 1px 0 rgba(255,244,228,.055)` on its top edge — in a dark room you see edges catch light, not shadows cast. This is a graft from *Room Tone*, arrived at independently there, and it is what makes the dark steps a **different drawing** rather than an inverted one.

**4. The weight scale lightens as the ground darkens.** Light-on-dark glyphs bloom, so headings drop 700 → 600, mid drops 600 → 500, and tracking gains `.004em` → `.006em` → `.008em`. No 800 or 900 exists on any dark step.

**5. Motion stops.** `--pk-dur` is 180ms at Dusk, 90ms at Late, and **0ms at Low Beam** — the reduced-motion block's contents apply unconditionally there, and every link is underlined regardless of hue.

### The half-darkened page

The problem is not that some surfaces stay white. It is that a skin *guesses* at a surface it cannot see and produces dark-on-dark. Three responses, chosen by what is provable:

| I can prove… | Response |
|---|---|
| every text node's container and the ink is Canvas's own | **Repaint.** The semantic layer, New Quizzes' container, Canvadocs' shell. |
| I own the document, the ink is Canvas's `#2D3B45`, there is no fixed descendant and no submit control | **Veil.** Files v2, nav trays. Light drops; the ink drops with it; nothing is guessed. |
| nothing | **Frame.** Leave every pixel, bound it, ring it, caption it. Third-party LTI, InstUI modals, `instui_header`. |

**`--pk-t1` is never `#FFFFFF`. `--pk-void` is never `#000000`.** The lightest surface in the sheet is `#FCFAF5` and the darkest is `#100E0C`.

### Where the light variant differs

Daylight is a derivative of the same role system, not a parallel theme: `--pk-raise` is elevation in dark and **recession** in light, `--pk-amber` is a solid pill in dark and a **tint with dark ink** in light, and `--pk-shadow` exists only there. One token set, two behaviours, because the physics are different.

---

## 8. Motion

Canvas honours `prefers-reduced-motion` **nowhere** — measured: zero occurrences in Dartmouth's 401 KB `common.css` against 40 `transition:` and 6 `animation:` declarations, and zero across all of instructure-ui master. Every transition the skin adds is new motion, and the skin owns the entire block.

| What | Property | Duration | Curve |
|---|---|---|---|
| Nav item hover | `background-color` | `calc(var(--pk-dur) * 0.78)` → 140 / 140 / 70 / 0ms | `cubic-bezier(.2,0,0,1)` |
| Card hover | `box-shadow` | `var(--pk-dur)` → 180 / 180 / 90 / 0ms | `cubic-bezier(.2,0,0,1)` |
| Row hover (module, planner, grades, sidebar) | `background-color` | `calc(var(--pk-dur) * 0.67)` → 120 / 120 / 60 / 0ms | `cubic-bezier(.2,0,0,1)` |
| **Primary button press** | `transform`, `box-shadow` | `calc(var(--pk-dur) * 0.5)` → 90 / 90 / 45 / 0ms | `cubic-bezier(.2,0,0,1)` |
| Lamp cone crossfade | `opacity` on two stacked paths | `var(--pk-dur)` | `cubic-bezier(.2,0,0,1)` |
| Focus ring | none | 0ms, always | — |
| Step change | none | 0ms | — |

**No transform on cards.** Today's shipped `translateY(-3px)` hover lift is unguarded motion (bug 7) and a lift across a dense grid is jitter. Cards separate by shadow at Daylight and by the caught edge in dark, neither of which moves. The **only** thing on a Low Beam page that moves is the submit button, and that is the point.

**The step change is instant.** No cross-fade. A lamp switches.

### The complete `prefers-reduced-motion` block

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: .01ms !important;
    scroll-behavior: auto !important;
  }
  .btn-primary, input[type=submit] { transition-duration: .01ms !important; }
  .btn-primary:active, input[type=submit]:active { transform: none !important; }
}
```

Two notes. **First, this is deliberately global.** Since Canvas honours the preference nowhere, the skin's block also silences Canvas's own 40 transitions and 6 animations — including `#mobileContextNavContainer`'s 1.5-second `max-height` reveal, which becomes instant, which is correct. `.01ms` rather than `0` so `transitionend` handlers still fire and nothing that waits for one hangs.

**Second, the press keeps its state change and loses its travel.** `:active` still collapses the 3px edge instantly — that is a state readout, not vestibular motion — but the 3px `translateY` is removed outright.

At **Low Beam this block's contents apply unconditionally**, whether or not the OS preference is set.

Canvas's confetti (`confetti.utils.ts`, gated on `ENV.disable_celebrations`) is a canvas-drawn animation, not CSS, and it is **not touched**. It is Instructure's feature and their preference to honour.

---

## 9. Accessibility

### 9.1 High contrast — the bail-out

Stated first because it is the repo's most serious existing gap: grepping the extension for `use_high_contrast` returns **zero hits today**. Detection and behaviour are in §3.1. On a hit the skin **removes every `--pk-*` declaration and both CSS files** rather than merely skipping paint, because Canvas throws away the institution's entire brand config in that mode by design (`application_helper.rb#active_brand_config`) and forces `ic-brand-primary: #0A5A9E`. On the React side `getTheme` ignores `brandVariables` entirely and returns `canvasHighContrastTheme`, whose own description claims WCAG 2.1 AAA. A skin painting over that is fighting an accessibility feature. Same total bail-out on `/login/*` and inside any proctoring frame.

### 9.2 The dyslexic font

**The skin sets `font-family` on nothing, by default.** It sets size, weight, line-height, tracking and measure, all of which remain helpful and none of which is affected by the preference. Constraint 7 is satisfied by construction rather than by a runtime check — which matters here, because `ENV.use_dyslexic_font` is a page global that a content script **cannot read**, and the key can be absent rather than false.

The system stack in §2.5 exists as an off-by-default popup option (`html[data-pk-font="system"]`). It is disabled whenever `getComputedStyle(document.body).fontFamily` contains `"OpenDyslexic"` — a runtime check that is DOM-readable, locale-proof, and does not depend on a flag name.

### 9.3 The layout shift

**No width, offset or margin is hardcoded anywhere in this spec.** The rail is 54 / 84 / **104**px and the course menu is 192 / **218**px depending on the dyslexic font, and `.ic-Layout-wrapper`'s `margin-left` and `.tray-with-space-for-global-nav`'s `margin-left` follow the rail. Every one of those is left to Canvas's own rules. The skin adds only paint and, in exactly two places (`.ic-DashboardCard__box__container`, `.ig-info`), a flow change that is intrinsically sized.

### 9.4 Contrast on every interactive state

Every state is a ladder step, so a state change can never reduce contrast. Worst case per step, taken from §2.2:

| State | Ground | Ink | Daylight | Dusk | Late | Low Beam |
|---|---|---|---|---|---|---|
| Row, rest | `--pk-page` | `--pk-t1` | 13.32 | 11.87 | 12.47 | 10.39 |
| Row, hover | `--pk-raise` | `--pk-t1` | 12.51 | 9.01 | 10.28 | 8.86 |
| Row, active | `--pk-band` | `--pk-t1` | 11.63 | 7.83 | 9.02 | 8.08 |
| Meta text | `--pk-card` | `--pk-t2` | 7.35 | 6.81 | 7.05 | 6.10 |
| **Disabled control** | `--pk-page` | `--pk-t3` | 5.60 | 6.25 | 5.72 | 5.66 |
| Link | `--pk-page` | `--pk-accent` | 5.71 | 7.82 | 8.37 | 6.35 |
| Link on a chip | `--pk-band` | `--pk-accent` | 4.98 | 5.16 | 6.06 | 4.94 |
| Amber pill | `--pk-amber` | `--pk-amber-ink` | 5.71 | 8.62 | 8.86 | 7.14 |
| **Focus ring** | `--pk-page` | `--pk-focus` | 5.64 | 10.21 | 11.09 | 9.74 |
| Focus ring, worst ground | `--pk-band` | `--pk-focus` | 4.93 | 6.73 | 7.58 | 7.90 |
| Nav label, worst-case white school nav | mixed ground | `--pk-t2` | n/a | 4.84 | 5.10 | 5.03 |

**Minimum anywhere in the sheet: 4.62:1** (`--pk-t3` on `--pk-void` at Daylight). Nothing is below 4.5:1, and disabled controls do not take WCAG's exemption — a student needs to be able to read a disabled submit button to learn why it is disabled.

The one rule that comes out of the numbers: **`--pk-t3` is illegal on `--pk-band` and above at Dusk (4.12), Late (4.13) and Low Beam (4.40). The floor there is `--pk-t2`.**

Focus: `outline: 2px solid var(--pk-focus); outline-offset: 2px` on every focusable element the skin touches. Never `outline: none`. Never removed. It flips with the step.

### 9.5 The submit-button check, in every theme and state

The rule is negative and absolute: **the skin sets no `color`, `background-color`, `opacity` or `filter` on `.btn-primary` or `input[type=submit]` at any step, and no container that can hold a submit affordance is ever veiled.** So the fill/label ratio inside the control is Instructure's own number, unchanged, in all four steps and in rest, hover, focus, active and disabled.

The *boundary* is the part that needs proving. Canvas's default `--ic-brand-button--primary-bgd` varies by school, and a dark navy such as `#394B58` sits at **1.93:1** against `--pk-page` at Late — invisible, and exactly the incumbent's failure. The 1px `--pk-btn-ring` fixes it. WCAG 1.4.11 is satisfied when *either* the fill or the ring clears 3:1 against the adjacent page:

| School fill | ring-vs-fill @ Low Beam | fill-vs-page @ Low Beam | best |
|---|---|---|---|
| `#394B58` navy | 3.19 | 2.05 | **3.19** ✓ |
| `#0374B5` Canvas default | 1.77 | 3.68 | **3.68** ✓ |
| `#008EE2` older default | 1.24 | 5.27 | **5.27** ✓ |
| `#FFC107` amber | 1.74 | 11.38 | **11.38** ✓ |
| `#7A003C` maroon | 3.91 | 1.67 | **3.91** ✓ |
| `#2D3B45` near-ink | 4.06 | 1.61 | **4.06** ✓ |

`--pk-btn-ring` is `--pk-t2`, which is itself **6.53–7.75:1** against the page at every dark step. The construction fails only for a fill whose luminance sits in a narrow band around `Y ≈ 0.07–0.12` (roughly a mid-grey `#5C5C5C`), where neither ratio clears. **The smoke check computes both ratios for the school's own computed `--ic-brand-button--primary-bgd` at all four steps, and escalates `--pk-btn-ring` to `--pk-t1` when neither clears** — which lifts the pathological grey case to 3.69:1. That is a one-property per-instance override, run at build time against the target Canvas, and it is a release gate, not a warning.

Retired claim: "the brightest object on a Low Beam page is always the button you are supposed to press." It is not true — `--pk-t1` at 10.39:1 has a higher luminance than any mid-toned button. **The claim that is true and checkable: at Low Beam the submit button is the only object left at full colour, and the only object that moves.**

### 9.6 Everything else

- The injected lamp is a real `<button>` with `aria-pressed` and an `aria-label` that names the current step. It sits between Calendar and Inbox in DOM order and needs no `tabindex`.
- The veil's off switch is a 24px `<button>` with `aria-pressed` inside the caption strip.
- Every added hit area is ≥32px (`a.more_link`, collapse chevrons, `.comment_count`).
- Size floor 13px everywhere; Canvas's 12px meta text is raised.
- `#skip_navigation_link` is never styled, moved or reordered.
- `.ic-avatar img` carries `fs-exclude`; it is never read and never copied.
- `Underline-All-Links__enabled` is respected — the skin's own link underlines are additive and never removed.
- Prose reaches 68ch, which is the measure WCAG 1.4.8 asks for and Canvas does not provide.

---

## 10. Looks

**A Look supplies hue only. The dimmer owns every luminance value, and therefore every contrast number.** That is the whole extensibility model, and it is a graft from *Falloff*.

Two custom properties, set inline on `<html>`, which is `:root`, so an inline value beats the step file's declaration and is inert when the skin is off:

```
--pk-lamp-h : oklch hue of the light itself   (moves the five ladder grounds)
--pk-look-h : oklch hue of the accent          (moves --pk-accent and --pk-accent-quiet)
```

The step file computes everything from them, with the plain hex declared first as the parse fallback:

```css
--pk-accent: #57C79B;
--pk-accent: oklch(0.80 0.12 var(--pk-look-h));
--pk-card:   #252019;
--pk-card:   oklch(0.152 0.008 var(--pk-lamp-h));
```

Three consequences:

1. **Twenty surface values from two inputs.** A Look is two numbers, not a thirty-token theme, and the four-step ladder does not multiply the catalog.
2. **No purchase can reach a contrast number.** Chroma is clamped at `0.008` on grounds and `0.12` on the accent by the ladder, so no Look can make the page a saturated colour or push a ratio below the table in §9.4. Nobody can buy an unreadable Canvas.
3. **A Look reads at 2am.** This retires shipped bug 9 — today `if (!s.cards || dark) return` means all six looks render an identical page in dark mode and only the accessory differs.

### The catalog

Finite, and it says so. The dimmer itself — all four steps, the veil, the prose repair, the due column, every accessibility behaviour — is **free on install and cannot be bought.** Coins buy the hue of the light, never the amount of it.

| Look | Price | `--pk-lamp-h` | `--pk-look-h` | Accessory (panel only) | Status |
|---|---|---|---|---|---|
| **Classic Cream** | free | 70 (tungsten) | 152 (mint) | none | Existing. Now the default lamp. |
| **Woodland** | 300 | 128 | 150 | `sprout` | Existing. `tints` block retired; hues carry it. |
| **Tidepool** | 450 | 195 | 188 | `glasses` | Existing. |
| **Butterscotch** | 300 | 45 | 40 | `scarf` | Existing. |
| **Night Shift** | 500 | 258 | 205 | `beanie` | Existing, **re-jobbed** — see below. |
| **Moonlight** | 450 | 250 | 232 | `beanie` | **New.** Near-neutral and cool, for students who find warm screens nauseating. A real, under-served preference. |

*Cozy Beanie* (300, hue 300 violet, `beanie`) is kept as a sixth owned entry and aliased the same way; it is omitted from the table only to keep it readable.

### Nothing is taken away

The keeper judge is right that the concept silently orphaned five paid Looks. Every `tints` block in `looks.js` points at `--pk-page`, `--pk-inset`, `--pk-line`, `--pk-mint`, `--pk-mint-edge`, `--pk-green`, `--pk-text-2` and the three `--pk-mint-tint*` variables — and this spec drops all of them. Two things fix that:

1. **An alias layer** ships in the step files: `--pk-inset: var(--pk-raise)`, `--pk-row: var(--pk-page)`, `--pk-text: var(--pk-t1)`, `--pk-text-2: var(--pk-t2)`, `--pk-text-3: var(--pk-t3)`, `--pk-green: var(--pk-accent)`, `--pk-mint: var(--pk-accent)`, `--pk-mint-edge: var(--pk-accent)`, `--pk-track: var(--pk-line)`, `--pk-circle: var(--pk-t3)`, `--pk-amber-text: var(--pk-amber)`. Old declarations resolve; old `tints` blocks become dead but harmless; the panel keeps working through the transition with no coordinated release.
2. **Night Shift gets a new job.** It exists today solely to grant dark mode, which Low Beam gives away free — so 500 coins would have bought nothing. It becomes the one Look that also carries a preset: wearing it sets the lamp to **Low Beam** on first wear, and it ships the indigo lamp hue nothing else has. The coins bought a hue and a setting instead of a feature.

This also fixes shipped bug 10. Today a Look's tints are set inline on `<html>` but `#prepkin-buddy` re-declares all 27 tokens in its own matched rule, and a declared value beats an inherited one — so wearing Woodland turns Canvas green while the panel stays mint. Under hue-only, the panel reads the same two inline properties from `:root` and both surfaces move together.

**And the split stays deliberate: the page gets the light, the panel gets the character.** The accessory is drawn on the kin inside the Prepkin panel and appears on **no Canvas page, ever** (constraint 18). The coin sink stays where it belongs, in the phone app's kin and rooms.

---

## 11. Build order

Ranked by student value per unit of risk. Roughly **3.5 weeks** and about **950 lines of CSS plus 380 of JS**. Honest about days versus weeks.

**Phase 0 — the ship blocker. One week. No visible design at all.**
The four navigation mechanisms (§3.7), the `registerContentScripts` / `insertCSS` step-file mechanism (§3.6), the high-contrast bail-out (§3.1), the single annotated selector manifest, and the smoke check that asserts every load-bearing selector still matches plus the submit-button ratios in §9.5. This is roughly 120 lines of JS for navigation, 90 for the bail-out and route gates, and a day for the manifest and the check. **Nothing ships before it**, because a dark-first skin arriving at `document_end` paints a white page on every navigation and is actively worse than not installing.

**Phase 1 — two steps, the pages a student lives on. Three days.**
Daylight and Late only. Base layer (§3), global rail, breadcrumb, flash, dashboard cards, right sidebar, course nav, Modules including the due column, assignment detail, Grades. The whole ladder and the alias layer land here; Dusk and Low Beam are two more token files and cost hours, not days, once this is right.

**Phase 2 — the button. Two days.**
The ring, the press, the `-darkened-15` read, the escalation rule, and the contrast check wired into the release gate. Small, and it is the headline.

**Phase 3 — Dusk, Low Beam, and the seam. Four days.**
The other two token files. The veil on Files v2 and nav trays plus its off switch and caption. The `.tool_content_wrapper` frame. The proctoring exclusions. The route gates.

**Phase 4 — the surfaces nobody else reaches. Four days.**
The `all_frames` script for Canvadocs, the `body.native-new-quizzes` container, the manifest host permissions and their district-review write-up. This is the part that makes the product different from a warm dark mode, so it is not optional — but it is genuinely harder to test than anything above it, because it needs a live course with a DocViewer submission and a New Quizzes assignment.

**Phase 5 — Tier 2 and Looks. Three days.**
Assignments index (free), Inbox, Discussions, classic Quizzes, Calendar, Pages, Syllabus, mobile header. The two hue properties, the six-Look catalog, the popup's three-stop slider.

**Gated separately, on George, at any point:** the drawn lamp icon (constraint 22). Until it is signed off the rail ships without it and the control is popup-only. Nothing above depends on the art.

---

## 12. What this concept refuses to do

1. **No `filter: invert()`, ever, anywhere.** Inversion wrecks photographs, diagrams, scanned maths and teacher screenshots — the things students actually read on Canvas. Every unreachable surface is dimmed or framed, never flipped.
2. **No red of its own.** Canvas's `ic-flash-error` keeps the platform's red because overriding an error semantic is dangerous. Urgency is amber and reads "still counts". There is no red hex in the sheet.
3. **No pure black and no pure white.** `#000` and `#FFF` never appear as a value.
4. **No aggregate number, anywhere.** No missing-work count, no completion percentage, no "3 of 8", no meter, no countdown, no streak. Every number this skin shows is a due date or a score Canvas already rendered in the same place.
5. **No grade distribution, no what-if calculator, no letter-grade colouring.** `.min` / `.max` / `.median` are legible and receive nothing else. A distribution bar is comparison to peers.
6. **No reordering of the course nav.** Students learn that menu by position, not by word. Hierarchy is paid for out of the light budget, which changes nothing anyone has memorised.
7. **No 800 or 900 weight on any dark step.** A heavy weight on a dark ground is a smear, not emphasis.
8. **No opacity-based hover or disabled state.** Every state is a ladder step with a measured ratio, so no state change can reduce contrast, and disabled controls hold 4.5:1.
9. **No filtering of any LTI launch frame.** That set includes proctoring vendors. Never, at any step, with or without an opt-in.
10. **No mascot, no coin count, no badge, no character, no progress ring on any Canvas page.** The only Prepkin-drawn pixel on a school-owned surface is one 26×26 lamp vector in a rail that already holds nine icons — and that is gated on sign-off.
11. **No persistent status strip in the breadcrumb bar and no footer in the trays.** The empty space stays empty.
12. **No automatic switching by clock.** The step is seeded once from `prefers-color-scheme` on install and never moves itself. After 21:00 the lamp's hover label changes one word. That is all.
13. **No paywalled accessibility.** All four steps, the veil, the prose repair, the due column and every behaviour in §9 are free forever on install. Coins buy the hue of the light, never the amount of it.
14. **No selector containing `css-`.** Not a full hash, not a label-anchored partial like `[class*="-view--flex"]`. The incumbent ships 79 of them in two hash formats and it is the direct cause of its top recurring complaint.
15. **No `<all_urls>`, no `tabs` permission, no MAIN-world injection, no external network request of any kind.** System font stack or nothing. This is what makes the extension defensible in a district security review, and it is the clearest technical difference from an incumbent that hotlinks 1,863 Pinterest images from inside a school network.
16. **No skin at all** when high contrast is on, on `/login/*`, or inside a proctoring frame.

---

## 13. The weakness, stated plainly

**Nobody asked for four darks.** Not one line of collected student voice asks for granularity — students ask for dark, and BetterCanvas ships a binary switch to two million of them. This spec's answer is structural rather than rhetorical: **the Canvas page carries a switch, and the three dark levels live in the Prepkin popup.** A student who never opens the popup gets exactly the product the evidence asks for — one click, dark, done — and the ladder costs them nothing, because the default step is a complete dark mode on its own. The dial is there for the minority of a minority who genuinely need step three, and it is one control away rather than in their face. If ninety percent park on Late and never touch it, the ladder was cheap: four token files of forty declarations each.

**It still spends most of its budget on complaint #2.** The due column on Modules and the promoted due line in the sidebar are the whole structural answer to complaint #1, and they are a repaint plus one flex rule — real, and one page. This skin does not merge To Do with Coming Up, does not build a cross-course missing-work view, and does not remove a single click from Modules. A concept that made the due-date problem structurally better would beat this on the students' own ranking, and the quotes prove it: *"it's saved my ass from missing due dates"* is about information, and reviews about themes only appear when the themes are taken away.

**And the honest competitive fact: a student with a migraine and a school-issued laptop is likelier to install Dark Reader, which works on every site they open, than to learn a lamp icon inside one LMS.** Three things are true against that. Dark Reader inverts, and inversion wrecks the diagrams and scanned maths students read on Canvas. Dark Reader cannot hold the submit button at the school's own colour, and it cannot know that the surface behind an LTI launch should be framed rather than half-painted. And a skin that ships with zero external requests, no `<all_urls>`, no hashed selectors and a total bail-out under High Contrast survives a district security review, which is the failure mode that took the incumbent off two million machines in one district and is the only thing that actually loses a student the tool.