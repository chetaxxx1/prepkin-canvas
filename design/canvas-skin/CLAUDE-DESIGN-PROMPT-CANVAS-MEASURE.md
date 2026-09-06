# Prompt for Claude Design — Prepkin Canvas skin, concept 2: Measure

**How to use.** Paste `CLAUDE-DESIGN-PREAMBLE-CANVAS.md` first, then everything below the line.

*Read first — `design/canvas-skin/`:* `RESEARCH.md` (Corrections block, then §8 in full, then
§3.1–§3.4, §3.6, §3.7, §3.9, §3.10, §3.11 for the pages here).

*The skin as it ships today — `extension/`:* `skin.css` · `looks.js` · `popup.html` (340px) ·
`panel.css` (360px).

---

I'm designing **Measure**, the second of three Canvas skin concepts for the Prepkin Chrome
extension. Give me one artboard per screen and state below, in this system, not in
BetterCanvas's.

## The concept

Canvas is not ugly, it is undifferentiated. Fourteen-pixel semibold grey on white, boxes nested
inside boxes, and every item on a thirty-row Modules page carrying identical weight, so nothing
on screen tells a student what to read first or what is due.

Every other direction fixes that by adding a colour, a chip, a card or a character. **Measure
fixes it by removing, then spends the whole remaining budget on the two things a printed book
solved centuries ago: a real hierarchy and a real alignment grid.** It grounds Canvas on paper,
replaces every box with a 1px hairline, sets one column of readable text on teacher-written
pages, and drops every due date in the product into the same right-hand strip of tabular
figures.

**The signature move.** Every due date is right-aligned into one 8.5rem cell of tabular figures
so thirty of them stack into a single strip you read straight down — and the thing that tells
you where you are, the module header on Modules and the title-and-due block on an assignment,
**sticks to the top of the viewport instead of scrolling away**.

Two things make this defensible where the incumbent is not. It **sets no `font-family` at all
by default**, so it cannot be got wrong under the dyslexic font, cannot flash a relayout on
load, and does not look modded on a screen-share. And it **adds zero motion** — no transition,
no transform, no animation, no keyframes, in any mode — so its reduced-motion block is spent
turning off Canvas's own motion instead of guarding its own.

**Its honest risk, and you should design knowing it.** The long reading a student does is often
a PDF inside a viewer or a Google Doc, so a beautifully set assignment page can be a
twenty-second waypoint. `.user_content` is six surfaces, not one — assignment detail, course
home front page, Pages, Syllabus, discussion prompts, classic quiz question text — but if the
reading pages come in under 90 seconds a day median at the pilot school, the prose block ships
as drawn and gets no further investment. What survives either way is the measure, the
hierarchy, the hairlines, the tabular figures, the due column, the sticky heads and dark mode.

## Primary screen, and the rest

**`M4` — Modules, Paper — is the primary screen.** Draw it first and hardest. It is the
#1-ranked complaint page, it carries the due column and the sticky head, and two independent
reviewers named it the strongest single artifact in the whole batch.

`M1` (dashboard, light) and `M9` (the reading page) are the two most important supporting
artboards. Everything else is a state.

## Artboards, in order

All 1440×900 unless noted.

| id | Artboard | Size | Note |
|---|---|---|---|
| `M1` | Dashboard, card view — Paper | 1440×900 | The index |
| `M2` | Dashboard, card view — Lamp | 1440×900 | Dark |
| `M3` | Right sidebar, close-up | 520×900 | Three panels: rest / due-soon / TA case |
| `M4` | **Modules — Paper** | 1440×900 | **PRIMARY** |
| `M5` | Assignment detail — Paper | 1440×900 | Sticky head + 34rem prose |
| `M6` | Grades — Paper | 1440×900 | The statement |
| `M7` | Global nav rail, strip | 240×900 | Paper (untouched) / Lamp (derived) |
| `M8` | Modules — Lamp | 1440×900 | The signature, in dark |
| `M9` | The reading page, close-up | 760×900 | `.user_content`, serif off and on |
| `M10` | Density dial sheet | 1120×600 | Compact / Normal / Roomy, heights printed |
| `M11` | Paper stocks sheet | 1120×760 | Six stocks, both scopes, ratios printed |
| `M12` | The seam | 1120×640 | LTI framed; Files v2 and InstUI left stock |
| `M13` | Popup | 340×560 | Two checkboxes, stock picker, density dial |
| `M14` | Degrade sheet | 1120×760 | High Contrast · `context_modules_v2` · Widget Dashboard |

## States that must be drawn

- `M1` with Colour Overlay **off**. Measure never writes `opacity` on the hero and never
  recolours `.ic-DashboardCard__header-title span`, so both accessibility cues survive **by
  omission**. Prove it on the artboard.
- `M3`: rest · one row carrying `pk-m-soon` (amber ink on the date, 2px amber left rule) ·
  Recent Feedback with a grade, **never coloured**.
- `M4`: the top of a module, and the same module scrolled ~600px so the sticky header is
  actually stuck. Plus an inset showing **both `.ig-details` nestings**.
- `M4`: a row at rest and a row on `:hover` — hover is `--pk-m-select`, a paper tint, **instant,
  with no transition and no lift**.
- `M5`: sticky `#assignment_head` on the legacy path, and the Enhancements path where there is
  no `#assignment_head` at all, so there is no running head. Draw both and label which is which.
- `M5`: primary button at rest / hover / focus-visible / active / disabled, ratios printed.
- `M9`: serif checkbox off (the default) and on.
- `M14`: High Contrast on → no ground, no ink, no tokens, no class on `<html>`. Plus the
  `context_modules_v2` page where **exactly one hook survives** (`className="context_module_item"`)
  and the minimal second pass has to still read.

## Tokens

Namespaced `--pk-m-*` so they cannot collide with the panel's 27. **Every one is declared in
full on `html.pk-m-paper` and in full on `html.pk-m-lamp`**, so no pair of popup toggles can
leave a `var()` unresolved.

| Token | Paper | Lamp | Contrast | Role |
|---|---|---|---|---|
| `--pk-m-page` | `#F3F0E7` | `#181614` | ground | The paper. Under every page, menu, sidebar, table, sticky head. |
| `--pk-m-sheet` | `#FBFAF6` | `#211E1A` | 1.09:1 vs page | The only raised surface. Card face, table body, code blocks. Never pure white. |
| `--pk-m-rule` | `#DDD6C7` | `#2E2A24` | 1.27:1 vs page | Every 1px border in the skin. Replaces every box. |
| `--pk-m-rule-strong` | `#B5AB95` | `#453F36` | 2.00 / 1.73:1 | The one 2px rule. **Four uses only.** Never a sole information carrier. |
| `--pk-m-text` | `#22201C` | `#DDD6C7` | **14.27 / 12.48:1** | Body ink. Lamp is deliberately under pure white's 18.05:1. |
| `--pk-m-text-2` | `#6B6355` | `#9A9184` | **5.20 / 5.81:1** | Marginal ink. Due dates, points, captions, small-caps labels. |
| `--pk-m-link` | `#2C4A6E` | `#9EBEE0` | **7.97 / 9.36:1** | Always underlined, never a button. |
| `--pk-m-link-visited` | `#5A4A72` | `#B6A6CC` | **6.94 / 8.00:1** | A book's index tells you where you have been. Canvas does not. |
| `--pk-m-amber-text` | `#8A5A16` | `#D9A85C` | **5.18 / 8.34:1** | "Still counts". Ink only, never a fill, never red. |
| `--pk-m-amber-rule` | `#A87C2E` | `#8A6A2E` | **3.30 / 3.59:1** | The 2px left rule on a due-soon row. |
| `--pk-m-select` | `#E7E2D3` | `#2A2621` | 1.14 / 1.20:1 | Row hover and `::selection`. A paper tint. **No hover lift anywhere.** |
| `--pk-m-focus` | `#2C4A6E` | `#9EBEE0` | 7.97 / 9.36:1 | 2px ring at 2px offset. Never removed. |
| `--pk-m-seam` | `#B5AB95` | `#453F36` | see `M12` | The 1px rule and caption around anything Measure cannot reach. |

**There is no third ink tone.** `--pk-text-3` is deleted, not declared-and-avoided — at 2.95:1
it failed AA at body size and a "never use this" comment is a landmine for whoever edits it in
six months.

**Print this on `M11`.** `L(#FFFFFF) = 1.0000`, `L(#F3F0E7) = 0.8714`. A foreground sitting at
exactly **4.50:1 on white lands at 3.95:1 on Paper**. Every non-white ground does this and no
cream avoids it. Two structural mitigations, and the second is a hard rule: Measure re-declares
the ink on every text node it grounds, and **Measure never grounds a surface it cannot also
re-ink.** That is why `--pk-m-sheet` is near-white on purpose — stock `#FFFFFF` is 1.14:1 off
the Paper ground and our own sheet is 1.09:1, so the surfaces we cannot reach read as sheets on
the paper, not as holes.

### Type

**No `font-family` is set anywhere by default.** Weights **400 / 500 / 600 only** — nothing on a
Canvas page goes above 600.

| Role | Size | Line-height | Weight | Case / tracking |
|---|---|---|---|---|
| Prose body | 1.0625rem (17px) | `var(--pk-m-prose-lead)` = 1.62 | 400 | — |
| Page `h1` (`#content > h1`) | 1.5rem | 1.25 | 600 | — |
| Prose `h2` | 1.25rem | 1.3 | 600 | 2rem above, 0.5rem below |
| Prose `h3` | 0.9375rem | 1.35 | 600 | uppercase, 0.08em |
| Module title | 1.125rem | 1.3 | 600 | — |
| UI row title | 0.9375rem | 1.4 | 500 | — |
| Marginalia (dates, points, captions) | 0.75rem | 1.45 | 500 | — |
| Small-caps label (section heads, crumbs, nav) | 0.6875rem | 1.3 | 500 | uppercase, 0.09em |
| Figure row (grades, min/max/median) | 0.8125rem | 1.4 | 500 | tabular |

**Measure:** prose 34rem (~66 characters at 17px). List rows 64rem. Nothing else is clamped.

**Figures:** `font-variant-numeric: tabular-nums lining-nums` set once on `#content`, inherited.
Every date, point value, grade and count is monospaced-width, so columns align without a table.

**The serif is one opt-in checkbox, default off.** When it is on, exactly one declaration ships:
`ui-serif, "Iowan Old Style", Charter, Georgia, "Times New Roman", serif` on `.user_content` and
`#content > h1`. Draw both halves of `M9`. The typographic argument is about size, weight,
line-height, case, tracking and measure — none of which need a face change.

### Shape and spacing

| Property | Value |
|---|---|
| `--pk-m-radius` | **2px.** The entire radius set. **No 999px pill exists on a Canvas page.** |
| Border | `1px solid var(--pk-m-rule)`. The only border in the skin. |
| Heavy rule | `2px solid var(--pk-m-rule-strong)`. Four uses: module head underline, grade total, blockquote margin, today's date in Planner. |
| `box-shadow` | `none`, shipped explicitly on `.ic-DashboardCard` and `.ig-list`. One exception, below. |
| Gradients | none. One exception: the Gridded stock's page texture. |
| Base unit | 4px. Grid gap 16px. Prose rhythm 27.5px (one prose line). |

### The density dial

Three steps on `<html>`, one axis, zero semantics changed.

| Token | Compact | Normal (default) | Roomy |
|---|---|---|---|
| `--pk-m-row-pad` | 6px | 9px | 13px |
| `--pk-m-block` | 18px | 24px | 32px |
| `--pk-m-section` | 32px | 40px | 52px |
| `--pk-m-prose-lead` | 1.55 | 1.62 | 1.75 |
| **Resulting row height** | **~33px** | **~39px** | **~47px** |

Roomy clears the 44px touch target and is **free**. Normal matches Canvas's own row height and
is free. Compact is below the touch-target guideline, is **200 coins** so it is an informed
choice, and **falls back to Normal under `@media (pointer: coarse)`**.

### The stocks

A Look here is a **paper stock**, not a theme. It may move the page tokens and nothing else.
Measure, leading, weights, rules, radii, spacing and figures are constant across every Look
forever. That is what stops the treadmill.

| Stock | Price | Page (Paper / Lamp) | Ink AA (Paper / Lamp) | Link | Accessory | Note |
|---|---|---|---|---|---|---|
| **Cream Laid** | free, default | `#F3F0E7` / `#181614` | 14.27 & 5.20 / 12.48 & 5.81 | `#2C4A6E` / `#9EBEE0` | none | Within a hair of the app's own cream. The through-line. |
| **Foolscap** | **free** | `#FAFAF8` / `#161616` | 15.98 & 5.85 / 13.43 & 6.18 | `#22528C` / `#9FC2E8` | none | Near-white and neutral. Free on purpose — cream is a default, not an imposition. |
| **Manila** | 300 | `#EFE5D0` / `#1B1611` | 13.09 & 5.20 / 12.74 & 5.84 | `#5C3E14` / `#DCBE8A` | `scarf` | A filing-folder brown. |
| **Ledger** | 300 | `#E9EFE6` / `#141814` | 13.73 & 5.28 / 13.19 & 6.13 | `#2A5442` / `#9FD3BA` | `sprout` | Pale accounting green. |
| **Gridded** | 450 | `#EFF1EC` / `#171917` | as Ledger ±0.2 | as Ledger | `glasses` | Cream Laid plus a 24px `repeating-linear-gradient` at 3% alpha on `--pk-m-page` **only**, so the grid never runs under a sheet. The one gradient in the skin. |
| **Plain** | 600 | Canvas's own ground | n/a | Canvas's own | `beanie` | A coin-earned **un-skin**. Canvas back to stock with only the reading typography and the due column left on. |

Two structural fixes are required and both are load-bearing: **a Look swaps a class on `<html>`,
it never writes inline custom properties**, and **the accessory stays in the panel** — no
accessory art enters the Canvas surface, which also means nothing in this concept waits on new
art sign-off.

## What each page does

### `M4` / `M8` — Modules

```css
.context_module { background: transparent; border: 0; border-radius: 2px; box-shadow: none;
                  border-bottom: 2px solid var(--pk-m-rule-strong);
                  margin-bottom: var(--pk-m-section); }

.ig-header.header { position: sticky; top: var(--pk-m-stick, 0px); z-index: 1;
                    background: var(--pk-m-page);
                    border-bottom: 1px solid var(--pk-m-rule); max-height: 4rem; }

.ig-row { padding: var(--pk-m-row-pad) 0; border-bottom: 1px solid var(--pk-m-rule); }

.due_date_display { display: inline-block; min-width: 8.5rem; text-align: right;
                    font-variant-numeric: tabular-nums lining-nums; }

.completion_requirement { font-size: 0.6875rem; text-transform: uppercase;
                          letter-spacing: 0.08em; }
.context_module_item.indent_1 { padding-left: 1.5rem }  /* … through indent_5 at 7.5rem */
```

**Draw the nesting question as a question.** `RESEARCH.md` §3.9 does not state whether
`.ig-details` is a direct child of `.ig-row` or sits inside `.ig-info`. Ship **both passes** —
mutually exclusive, each a no-op when it misses — and draw both as insets on `M4`:

```css
.ig-row  { display: flex; align-items: baseline; column-gap: 16px; flex-wrap: wrap; }
.ig-row  > .ig-details { margin-left: auto; }
.ig-info { display: flex; align-items: baseline; column-gap: 16px; flex-wrap: wrap;
           flex: 1 1 auto; min-width: 0; }
.ig-info > .ig-details { margin-left: auto; }
```

`flex-wrap: wrap` means an unexpected third child wraps rather than overflowing. The
`min-width: 8.5rem` cell produces the column in either nesting.

**The sticky offset is derived, not assumed.** `--pk-m-stick` = the summed rendered height of
anything above `#content` that is `sticky` or `fixed` with `top: 0`, capped at `4rem`. Under
`@media (max-height: 700px)` the sticky heads drop to `static` entirely — a two-line running
head plus Canvas's own sticky chrome eats a third of a laptop's reading area.

### `M1` / `M2` — Dashboard, card view

An index, not a deck. `#DashboardCard_Container` → grid, `repeat(auto-fill, minmax(20rem, 1fr))`,
`gap: 0`, `max-width: 64rem`. Card → transparent, 2px radius, **no shadow, no hover lift, no
transition at all**. Hero → **3px**, and its `opacity` is never set. Title → 0.9375rem / 500 on
the outer element, and the inner span's `color` is never set. Badge → drop the filled circle,
render as a superscript tabular figure.

If the container rule misses, cards stay Canvas's inline-block and every per-card rule still
lands: a ragged grid of well-set entries, never a broken page. Draw that.

`.ic-Dashboard-header__title` is **unverified and never selected** — style the `h1` by element
inside the verified container.

### `M3` — Right sidebar

`#right-side-wrapper` → transparent, `border-left: 1px solid var(--pk-m-rule)`,
`padding-left: 24px`, **`box-sizing: border-box` in the same rule** because the 288px width is
layout maths. Section heads → 0.6875rem small-caps over a full-width hairline. Rows → no box,
two lines, hairline separated. The `"N points • due date"` string — which the research calls the
single highest-value change on the dashboard — → 0.75rem tabular.

**How `pk-m-soon` is decided, and it never parses a date.** The extension already syncs the real
to-do list from Canvas's REST API into `chrome.storage.local`. Rows carry
`a[href^='/courses/']` with the assignment id in the path. The class is applied by **joining on
the href**, not by reading a localised date string. Threshold: due within 48 hours, or past due.

Recent Feedback's grade is `strong` at 0.9375rem / 600 tabular, **never coloured**.
`a.more_link` is **not touched**. `.ic-sidebar-logo` is **not touched, it is the school's**.

### `M5` — Assignment detail, and `M9` — the reading page

```css
.user_content { color: var(--pk-m-text); font-size: 1.0625rem;
                line-height: var(--pk-m-prose-lead); }
.user_content :is(p, ul, ol, h2, h3, h4, blockquote, pre):not(table *) { max-width: 34rem; }
.user_content p:not(table *) { margin: 0 0 0.75em; }
.user_content blockquote { border: 0; background: transparent; padding: 0 0 0 1rem;
                           border-left: 2px solid var(--pk-m-rule-strong); }
.user_content a         { color: var(--pk-m-link); text-decoration-line: underline;
                          text-decoration-thickness: 1px; text-underline-offset: 0.18em; }
.user_content a:visited { color: var(--pk-m-link-visited); }
.user_content pre { border: 1px solid var(--pk-m-rule); border-radius: 2px; padding: 12px; }
#content > h1 { font-size: 1.5rem; font-weight: 600; line-height: 1.25;
                border-bottom: 1px solid var(--pk-m-rule); padding-bottom: 0.5rem; }
```

Two things about this block are decisions, not defaults, and both belong on the artboard:

- **`p + p { margin-top: 0; text-indent: 1.4em }` is cut.** Canvas's editor output is full of
  `<p>&nbsp;</p>` spacers, `<p><img></p>` and `<p><br></p>`. Zeroing paragraph margins deletes
  every spacer and indents every wrapped image by 1.4em. It is a book affectation applied to the
  one container the research says twice never to assume structure in. Paragraphs get a real
  `0.75em` gap instead.
- **Descendant selectors, not direct-child.** Word- and Google-Docs-pasted pages are almost
  always wrapped in a `<div>` or a table, so `.user_content > p` never lands on a large share of
  real pages.

**Nothing clamps `.user_content` itself.** No container is ever narrower than its widest child,
so a table, an image or an embedded video can never be cut off, and `overflow` is never set.

### `M6` — Grades

Gated on the **absence** of `#grade-summary-react` — if that element exists, the whole block is
skipped rather than half-applied. Zebra striping removed, one hairline per row, every number
right-aligned tabular, `#student-grades-final` set at 1.5rem / 600 above a 2px rule like the
total line on an invoice. `.min` / `.max` / `.median` get one hairline row of three tabular
figures with 0.625rem small-caps labels.

No colour on this page except the link ink. No red, no green, no arrow, no trend, no what-if.

### `M7` — Global nav rail and course menu

The rail is **identical to stock in Paper** except the badge, and only when it is both an alarm
red and would stay visible as amber. In Lamp, six nav variables are **derived from the school's
own values** — `hsl(H(rail), S(rail), 12%)` — and if the rail's lightness is already above 60%,
Measure does nothing to it at all, because a light rail plus a school logomark is a logo
designed for a light ground and we cannot recolour an image. Say that out loud on the artboard:
**the glare complaint stays partly unanswered for those schools.**

Worked example to print: Dartmouth green `#00693E` → `#003D24`, and `#DDD6C7` on it measures
**8.58:1**.

Course menu: the five rare tabs recede by **ink tone at the same 0.8125rem size**, never by
shrinking. Shrinking small nav text makes it smaller, saves no clicks, and hurts the student who
actually needs Rubrics. **No reordering** — students learn that menu by position.

### `M12` — The seam

| Surface | What Measure does |
|---|---|
| Third-party LTI (`.tool_content_wrapper`) | 1px `--pk-m-seam` rule + a 0.6875rem small-caps `::before` caption. Frame renders stock. |
| Files v2 | **Nothing.** Zero `className` attributes to select. Keeps its stock white. In Paper that reads as a sheet at 1.14:1. In Lamp it is a lit rectangle, and that is honest. |
| InstUI headers, tray interiors, modals | **Nothing.** Same reason. |
| New Quizzes | Same-origin since 2026-08-15. Container, spacing and typography only. |
| Canvadocs / DocViewer | **Reached** with `all_frames: true` — the ground and the viewer chrome. **The measure and the hierarchy do not reach a rendered PDF page**, which is a canvas. Say that split in the product. |
| Widget Dashboard | No markup at all. Detect and hand over to the panel. |
| Login | Excluded, in every mode. |

## Copy — verbatim

- Popup checkbox 1: `Book type on reading pages`
- Popup checkbox 2: `Serif on reading pages`
- Popup section: `Paper`
- Popup section: `Row height`
- Density labels: `Compact` · `Normal` · `Roomy`
- Density note under Compact: `Smaller rows. More on screen.`
- Density note under Roomy: `Bigger rows. Free, always.`
- Seam caption on an LTI frame: `External tool`
- Seam line in the popup: `Some pages inside Canvas belong to other companies. Measure can't
  reach those, so they'll look like Canvas normally does.`
- The reading-page split, in the popup: `Measure can dim a PDF but it can't re-set the type
  inside one.`
- Due-soon, sidebar: `still counts`
- Stock card line, exactly this shape: `Manila · 13.09:1 · warm`
- Catalog footer: `Six papers and one row height. The type never changes.`
- High Contrast: `Your school has High Contrast on. Measure stays out of the way.`

## Interactions and motion

**Measure adds zero motion.** No `transition`, no `transform`, no `animation`, no `@keyframes`,
in any mode, in any stock, at any density. The shipped `translateY(-3px)` card lift is **deleted
rather than wrapped**.

Every state is a paint that lands on the next frame:

| What | Property | Duration |
|---|---|---|
| Row hover (module, planner, grades, sidebar) | `background` → `--pk-m-select` | **0ms** |
| Card hover | **nothing at all** | — |
| Stock change | class swap on `<html>` | **0ms** |
| Density change | class swap on `<html>` | **0ms** |
| Focus | `outline: 2px solid var(--pk-m-focus); outline-offset: 2px` | **0ms** |

**The reduced-motion block therefore has a different job.** Canvas honours the preference
nowhere — zero occurrences in 401 KB of `common.css` against 40 `transition:` and 6
`animation:` — so Measure owns the block and spends it turning off **Canvas's own** motion, on
the elements Measure already styles, for a student who asked the OS for it:

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

`0.01ms` and not `none`, because Canvas has JS waiting on `transitionend` / `animationend`. The
list is explicit and closed — it names only elements Measure already touches, so it cannot
silently break a Canvas surface the skin never looked at.

## What must not change

- `font-family`, by default, anywhere. The serif is one checkbox, off.
- The four `--ic-brand-button--*` variables and their four darkened derivatives.
  `--ic-brand-primary` and its six derivatives. `--ic-brand-header-image`. All 16
  `--ic-brand-Login-*`.
- `background`, `color`, `border` or `opacity` on `button`, `.btn`, `.btn-primary`,
  `[type=submit]`, `a.Button`, `.Button--primary`, `.Button--secondary`, `#submit_assignment`,
  or a file-upload affordance. **One exception, argued in place:**
  `html.pk-m-lamp :is(.btn-primary, .Button--primary, [type="submit"])
  { box-shadow: 0 0 0 1px var(--pk-m-rule-strong) }` — a school whose primary fill is near-black
  would otherwise vanish into `#181614`. `box-shadow` changes no box metric, can only add a
  visible edge, and is not one of the four banned properties. **It is the only shadow in the
  skin.** Print it as an exception on `M5`.
- The hero's `opacity`. The title span's `color`. Any course colour.
- The four `ic-flash-*` semantic colours, error red included.
- Any width, `display`, `position` or `order` on `#header.ic-app-header` or `#left-side`.
- The order of the course nav.
- The school's rail, in Paper, entirely.
- The login page, in any mode.
- `a.more_link`. `.ic-sidebar-logo`. `#skip_navigation_link`. `#planner-app-fixed-element`.
- The measure, leading, weights, rules, radii, spacing and figures — across every Look, forever.

## Deviations

**Allowed, if you print the number:**

- Nudge any stock's hexes, if both inks stay AA in both modes and the new measurements are
  reprinted on `M11`.
- The exact prose measure (34rem) and leading (1.62) — argue a different value and show it.
- The density step values, if Roomy still clears 44px and Compact is still labelled as below it.
- The small-caps tracking and the heading rhythm.
- The popup's internal layout, spacing and iconography.
- Reordering the artboards if a different sequence reads better — say so.

**Not allowed:**

- A pill, a chip, a rounded tag, or any radius above 2px on a Canvas page.
- A shadow (except the one Lamp button ring), a gradient (except the Gridded texture), a hover
  lift, or any transition at all.
- A third ink tone.
- Setting `font-family` by default.
- Reordering the course nav, or shrinking anything to create hierarchy.
- Any kin, coin, count, ring, meter or Prepkin mark on a Canvas page.
- Red, anywhere Measure draws it. Amber ink only, no fill.
- A per-course theme keyed on `body.context-course_<id>`. It is verified, it would look good,
  and it is course colour written by the skin.
- A selector containing `css-`.
- Putting the density dial's Roomy step, or dark mode, behind coins.

## What I want back

One artboard per screen and state above. Then, in text:

1. The `.ig-details` nesting question, drawn both ways, with the one-hour live test written down.
2. Every ratio in the token table re-measured on the ground it actually lands on, not assumed
   from white — including every school-brand foreground that touches a Measure ground.
3. What each per-page block degrades to under `context_modules_v2`, `instui_nav`,
   `instui_topnav`, `instui_header`, `widget_dashboard` and `restrict_quantitative_data`.
4. The full toggle matrix — Paper/Lamp × six stocks × three densities × two checkboxes × High
   Contrast — and confirmation that no cell leaves a `var()` unresolved.

Quiet, printed, and legible. Canvas with the volume turned down and a real grid under it. Tell
me what you changed and why, per screen.
