# Prompt for Claude Design — Prepkin Canvas skin, concept 1: Receipt

**How to use.** Paste `CLAUDE-DESIGN-PREAMBLE-CANVAS.md` first, then everything below the line.

*Read first — `design/canvas-skin/`:* `RESEARCH.md` (Corrections block, then §8 in full, then
§3.4, §3.6, §3.7, §3.9, §3.10 for the pages here).

*The skin as it ships today — `extension/`:* `skin.css` (149 lines, 27 tokens, eleven bugs) ·
`looks.js` (the six-Look catalog) · `popup.html` (340px) · `panel.css` (360px).

---

I'm designing **Receipt**, the first of three Canvas skin concepts for the Prepkin Chrome
extension. Give me one artboard per screen and state below, in this system, not in
BetterCanvas's.

## The concept

Receipt's product is **absence, with proof**. It quietly takes the junk off a student's Canvas
pages — a school logo printed twice on one page, an arrow pointing at nothing, a "Show more"
whose targets are already open, 146px of information-free colour on every course card — and it
repairs the handful of things Canvas plainly gets wrong: two To Do lists, a Coming Up list cut
off at three rows, due dates scattered at a different horizontal position on every line, text a
teacher pasted out of Word in black-on-white that a dark page turns unreadable.

Then it hands the student **the receipt**: a list, in the toolbar popup, of every single thing
it changed on the page they are looking at, each with a one-click **Put back**. Nothing else in
this market can show its work.

That inverts the category's worst failure. A student cannot find a control, blames the
extension, an IT manager pulls it from every machine in the district. With a receipt, the
student clicks Put back and the list is the thing you show the IT manager.

**Receipt puts zero Prepkin pixels on any Canvas page. No mascot, no coin, no green, no
wordmark, no strip, no string.** The page is imposed; the popup is opt-in. Personality lives in
the popup, and it is the only screenshottable thing in the product. That is deliberate, and it
is also the concept's honest weakness: it does very little to make anyone install the phone app.

**The coin sink is paper.** A Look no longer means a theme. It means one of six **reading
surfaces**, each shop card printing its own measured body-text contrast ratio and its cast —
*"Manila · 11.9:1 · warm"*. Two of the six are free forever, because nobody pays for legibility.

## Primary screen, and the rest

**`R1` — Dashboard, card view, light (Newsprint) — is the primary screen.** Draw it first and
hardest. It is the page a student opens most, it carries the most removals, and it is the
before/after of the whole product.

`R8`, the receipt popup, is the second most important artboard and the only shareable one.
Everything else is a supporting state.

## Artboards, in order

All 1440×900 unless noted. Every artboard carries a visible id badge and a one-line caption
saying what changed and why.

| id | Artboard | Size | Note |
|---|---|---|---|
| `R1` | **Dashboard, card view, light — Newsprint** | 1440×900 | **PRIMARY** |
| `R2` | Dashboard, card view, dark — Carbon | 1440×900 | Same page, dark stock |
| `R3` | Right sidebar, close-up | 520×900 | Three panels: stock / Receipt / the TA case |
| `R4` | Modules, light | 1440×900 | Sticky module head + due column |
| `R5` | Assignment detail, light | 1440×900 | Prose, and the submit button untouched |
| `R6` | Grades, light | 1440×900 | |
| `R7` | Global nav rail, strip | 240×900 | Light / dark / school-brand-survives |
| `R8` | **The receipt popup** | 340×560 | Two states: dashboard page, Modules page |
| `R9` | "Show me" overlay, on `R1` | 1440×900 | The dashed reveal |
| `R10` | After a Put back | 1440×900 | One thing restored, one receipt line struck |
| `R11` | Paper stocks sheet | 1120×760 | Six stocks, ratio + cast printed on each |
| `R12` | Off-states sheet | 1120×720 | High Contrast · Widget Dashboard · toggles off |
| `R13` | The seam | 1120×640 | LTI frame framed; Files v2 left stock |
| `R14` | Toolbar badge | 480×200 | Browser chrome, the only always-visible proof |
| `R15` | Popup — "Due next" | 340×560 | The acquisition surface |

## States that must be drawn

- `R1` at rest, and one card in `:hover` — which is a **paper tint, no lift, no shadow, no
  transition**. The shipped `translateY(-3px)` is deleted, not guarded.
- `R1` with Colour Overlay **off** (Canvas sets the hero to inline `opacity: 0`): prove the
  course-colour cue survives, because Receipt never writes `opacity` and never recolours
  `.ic-DashboardCard__header-title span`.
- `R3`: stock Canvas sidebar · Receipt's sidebar · the "student who also TAs a course" case,
  which gets a second, legacy `ul.right-side-list.to-do-list` markup and must inherit the same
  treatment.
- `R7`: rail at rest and one item `:hover` with its slide-out label, in both stocks. Plus the
  proof panel: the school's own `--ic-brand-global-nav-bgd`, `--ic-brand-header-image` and the
  four button variables are **untouched**, printed as hex.
- `R8`: a page with removals, and the empty state — a page where nothing was taken.
- `R9`: the reveal on, and mid-fade at ~80ms.
- `R12`: High Contrast on → stock Canvas, everything removed. Widget Dashboard → no server
  markup at all, hand over to the panel. And the toggle matrix: `pk-on` off with `pk-dark` on
  must be stock Canvas, not a broken page.
- `R5`: primary button at rest, `:hover`, `:active`, `:focus-visible`, `[disabled]` — five
  states, each with its measured ratio printed.

## Tokens

Receipt declares its tokens **once, on `html.pk-on`**, so the panel inherits them and can never
be out of step with the page. A Look **swaps a class, never writes inline** — writing inline on
`<html>` is the cause of shipped bug 10.

**A Look moves exactly seven tokens on a Canvas page. Nothing else. No radius, no type, no
spacing, no accessory, no course colour, ever.**

`--pk-paper` · `--pk-paper-2` · `--pk-paper-sunk` · `--pk-ink` · `--pk-ink-2` · `--pk-rule` ·
`--pk-mark`

### The six paper stocks — a closed catalog

Four light, two dark. **The floor is AAA (7:1), not AA** — a student picking a paper is picking
a reading surface.

| Stock | `--pk-paper` | `--pk-paper-2` | `--pk-paper-sunk` | `--pk-ink` | `--pk-ink-2` | `--pk-rule` | `--pk-mark` | Body | Cast |
|---|---|---|---|---|---|---|---|---|---|
| **Newsprint** | `#F7F6F3` | `#FFFFFF` | `#EFEDE8` | `#1B1F24` | `#454B54` | `#E3E0D9` | `#2F6BAA` | **15.3:1** | neutral |
| **Manila** | `#F2EAD9` | `#FBF6EC` | `#E9DFC9` | `#33291F` | `#5E5142` | `#E5D7C2` | `#A9563A` | **11.9:1** | warm |
| **Bond** | `#F4F6F8` | `#FFFFFF` | `#E9EDF1` | `#12171C` | `#3E464F` | `#DDE3E9` | `#1F5FA8` | **16.6:1** | cool |
| **Vellum** | `#EFE7D8` | `#F6F1E6` | `#E5DBC8` | `#3C3730` | `#635C51` | `#DED3BE` | `#6E6A5F` | **9.6:1** | cream, softest |
| **Carbon** | `#17191D` | `#1E2126` | `#121417` | `#E6E8EA` | `#B4BAC1` | `#2C3037` | `#6FA8DC` | **14.3:1** | neutral dark |
| **Blueprint** | `#161B22` | `#1C232C` | `#11151B` | `#DDE4EC` | `#A9B4C2` | `#29323D` | `#7FB2E0` | **13.5:1** | blue-grey dark |

`R1` uses Newsprint. `R2` uses Carbon. `R11` shows all six.

**The remaining seven tokens are yours to propose.** The spec fixes fourteen tokens on
`html.pk-on` and enumerates only the seven paper ones. Propose the other seven — you will need
at least a link ink, a visited ink, a focus ring, an amber ink, an amber rule, a row-hover
tint, and a seam rule — name them `--pk-*`, print a measured ratio beside each on `R11`, and
**do not reuse any of the 27 names already in `extension/skin.css`.**

Three link variables are scoped, not global: `--ic-link-color` and its `-darkened-10` /
`-lightened-10` derivatives. Canvas computes those two server-side, so overriding only the base
leaves hover in the school's blue.

### The six Looks

| Look | Price | Accessory (panel only) | Light stock | Dark stock |
|---|---|---|---|---|
| Classic Cream | free | none | Newsprint | Carbon |
| Woodland | 300 | sprout | Manila | Carbon |
| Cozy Beanie | 300 | beanie | Vellum | Carbon |
| Tidepool | 450 | glasses | Bond | Blueprint |
| Butterscotch | 300 | scarf | Manila | Carbon |
| **Night Shift** | 500 | beanie | Bond | **Blueprint** |

Two light Looks share Manila and four share Carbon. That is fine — a paper is a reading
surface, not a badge. The Look's identity lives on the accessory, in the panel.

**Night Shift, settled.** It costs 500 coins today and its whole payload is turning dark on.
Receipt gives dark away free. So: dark is free forever, Night Shift keeps its name, its price,
its beanie and a dark page, and its dark stock becomes **Blueprint** — otherwise reachable only
by buying Tidepool. Nobody who paid loses anything. `dark: true` is deleted from the Look
object, which also fixes shipped bug 8.

### Type and shape

System stack. **Receipt never sets `font-family` on a Canvas page, in any mode.** Weights 400 /
500 / 600 only. Nothing below 13px. `font-variant-numeric: tabular-nums lining-nums` is set
once on `#content` and inherits — that is what makes the due column work.

Radius: only radii Canvas already uses. **No shadow anywhere. No hover lift. No pill.**

## What each page does

### `R1` / `R2` — Dashboard, card view

| Selector | Conf. | Move |
|---|---|---|
| `.ic-DashboardCard` | verified | Paper ground, hairline, **no shadow, no lift, no transition** |
| `.ic-DashboardCard__header_hero` | verified | Height only. **`opacity` is never written** (bug 1) |
| `.ic-DashboardCard__header-title span` | verified | **`color` is never written** (bug 2) |
| `.ic-DashboardCard__header-subtitle`, `__header-term` | verified | `--pk-ink-2` |
| `.ic-DashboardCard__action-badge` | verified | Left alone. It reads 0 even when work is due |
| `.ic-Dashboard-header__title` | **unverified** | **Never selected.** Style the `h1` by element inside the verified container (bug 11) |

**Cut, and say so on the artboard:** the dashboard assignments-badge fix. It is the only rule
in the concept that produces a *wrong answer* rather than a plain page when it goes sideways —
that badge means unsubmitted assignments in this course, and planner items are a different set.
If the count is worth having, it goes in the popup, labelled honestly.

**Cut:** `.ic-DashboardCard__box__container { display: grid }`. The container carries
`margin: -36px 0 0 -36px` negative gutters that a grid breaks, and it hardcodes 262px. It is
addition-shaped and it fails hard, not soft.

### `R3` — Right sidebar

`#right-side-wrapper` (verified) · `.Sidebar__TodoListContainer` (verified) ·
`[data-testid='ToDoSidebar'] > h2.todo-list-header` (verified) · `.ToDoSidebarItem` (verified) ·
`.events_list.coming_up ul.right-side-list.events > li.event` (verified) ·
`.events_list.recent_feedback` (verified) · `ul.right-side-list.to-do-list li.todo` (verified).

Two real repairs, the highest student value per line in the whole product:

1. **Dedupe.** A student with `render_both_to_do_lists` on sees two To Do lists. Keep one.
2. **Un-truncate Coming Up.** Scope it to `.events_list.coming_up` only — the shipped
   `#right-side a.more_link { display: none }` also hits Recent Feedback's expander while
   leaving its extra rows at inline `display: none`, permanently losing older feedback.

`.ic-sidebar-logo` (verified) is **never touched** — it is the school's. The duplicate-logo
removal is the *header* logomark, and only when it is provably the same mark twice on one page.

### `R4` — Modules

`.context_module` (verified) · `.ig-header.header` (verified) · `.ig-row` (verified) ·
`.ig-info` / `.ig-details` (verified as row internals) · `.due_date_display` (verified) ·
`.completion_requirement` (verified) · `.context_module_item.indent_1…5` (verified).

Two grafted moves, both cheap and both answering ranked complaints:

- **The due column.** `.due_date_display { display: inline-block; min-width: 8.5rem;
  text-align: right }` plus inherited tabular figures. Thirty due dates stack into one strip
  you read straight down. One rule, no JS.
- **The sticky module header.** `.ig-header.header { position: sticky; top: 0 }`. No indices,
  no offsets, no JS. A student scrolling a 30-row module always knows which module they are in.
  Draw the failure mode too: inside an `overflow` ancestor it degrades to `static`, which is an
  ordinary header with a hairline under it.

**On `.ig-details` nesting: this is a guess and must be drawn as one.** `RESEARCH.md` §3.9 does
not state whether `.ig-details` is a direct child of `.ig-row` or sits inside `.ig-info`. Draw
the row **both ways** as an inset on `R4` and print "one hour on a live Modules page to settle".

### `R5` — Assignment detail

`#assignment_show` (verified, legacy) · `#assignment_head` (verified) · `.user_content`
(verified) · `[data-testid='assignments-2-student-view']` (verified, Enhancements) ·
`.tool_content_wrapper` (verified).

Two DOM generations behind one URL. Style each separately; neither depends on the other.

**The Word-paste repair.** Teacher-pasted HTML carries inline colours that a dark page turns
unreadable. Repair it with an **enumerated list of the values Word actually emits** — never
`[style*="color"]` as a broad match, which also hits `background-color`, `border-color` and
`outline-color`, so an element carrying only `style="background-color:#ffff00"` got its text
repainted. Draw the repaired paragraph and the exempted case side by side.

**The submit button.** No rule in Receipt sets `background`, `color`, `border`, `border-color`,
`opacity`, `filter`, `visibility` or `display` on a `button`, `.btn`, `[type="submit"]`,
`input[type="submit"]` or `[role="button"]`, anywhere, in any theme, in any state. Print the
measured numbers, which are Canvas's own:

| Check | Canvas default | Requirement | Result |
|---|---|---|---|
| White label on `--ic-brand-button--primary-bgd` `#0374B5` | **5.0:1** | 4.5:1 | pass |
| Same, `:hover` (`-darkened-5`) | 5.4:1 | 4.5:1 | pass |
| Same, `:active` (`-darkened-15`) | 6.4:1 | 4.5:1 | pass |
| Same, `[disabled]` | 3.1:1 | — | Canvas's own, unchanged |
| Button edge vs `--pk-paper`, light | 4.4:1 | 3:1 | pass |
| Button edge vs `--pk-paper`, dark (Carbon) | **3.5:1** | 3:1 | pass |

The last row is the one that matters: on a `#17191D` page the button stays the school's
saturated blue and reads as a raised control, not a hole.

### `R6` — Grades

`#grade-summary-react` (verified) is the **gate** — if it exists, none of the rest runs.
`#grades_summary` and `.student_assignment` are already dead for any course with
`restrict_quantitative_data` on. Then `#grades_summary` (verified) · `.assignment_score`,
`.grade`, `.possible.points_possible` (verified) · `.min`, `.max`, `.median` (verified) ·
`#student-grades-final` (verified).

No colour on this page except the link ink. No red, no green, no arrow, no trend, no "at risk",
no what-if calculator. The class distribution stays — the research says it is what students
actually scroll for.

### `R7` — Global nav rail

`#header.ic-app-header` (verified) · `.ic-app-header__menu-list-link .menu-item__text`
(verified) · `li.ic-app-header__menu-list-item--active` (verified) · `.menu-item__badge`
(verified) · `#skip_navigation_link` (verified, **never styled**).

**No `width`, no `display`, no `position`, ever.** The collapse toggle, the 54/84/104px states,
`body.primary-nav-transitions` and the `.ic-Layout-wrapper` margin all keep working untouched.

**Cut, and say why on the artboard:** hiding four course-nav tabs. It was presented in the
concept as the safest call and it is the riskiest. Conferences is where some courses run the
live meeting, Collaborations is where some run all group work, and Outcomes is where a
mastery-graded student sees their standing. Demotion by **ink tone** buys the same shortened
scan for one rule instead of four `:has()` selectors, and hover brings the tab back to full ink.

### `R13` — The seam

| Surface | What Receipt does |
|---|---|
| Third-party LTI (`.tool_content_wrapper`, verified) | 1px seam rule + a small-caps caption. The frame renders stock. |
| Files v2 | Nothing. `FileFolderTable.tsx` has zero `className` attributes. It keeps its stock white. |
| InstUI headers, tray interiors, modals | Nothing. `@instructure/ui-themes` ships zero `var(--`; a `:root` override reaches none of it. |
| New Quizzes | **Not a seam any more.** Same-origin since 2026-08-15 as `body.native-new-quizzes`. Container, spacing and typography only. |
| Canvadocs / DocViewer | **Reachable** with `all_frames: true`. Ground and viewer chrome only — a rendered PDF page is a canvas. |
| Login | Never touched, in any mode. It is the school's identity surface. |

## Copy — verbatim

**Popup, receipt view**

- Title: `Receipt`
- Section: `Taken off this page`
- Section: `Fixed on this page`
- Row action, every row: `Put back`
- Footer: `Everything here is one click from coming back.`
- Empty state: `Nothing was taken from this page.`
- Reveal button: `Show me`

**Receipt rows — dashboard (`R8`, state 1)**

Taken off this page:
- `The school logo, twice — one kept`
- `An arrow pointing at nothing`
- `A "Show more" that was already open`

Fixed on this page:
- `Course colour band, thinner`
- `One To Do list instead of two`
- `Coming Up shows every row`

**Receipt rows — Modules (`R8`, state 2)**

Taken off this page:
- `Nothing`

Fixed on this page:
- `Four menu items dimmed`
- `Module header stays at the top while you scroll`
- `Due dates lined up in one column`
- `Text pasted from Word, made readable`

**Popup, "Due next" (`R15`)**

- Section: `Due next`
- Amber line on a past-due row: `still counts`
- Section: `Missed`
- On the dashcard badge: `Canvas shows 0 here even when work is due`

**Seam caption (`R13`)**

`Some pages inside Canvas belong to other companies. Receipt can't reach those, so they'll
look like Canvas normally does.`

**Shop, paper stocks (`R11`)**

- Card line, exactly this shape: `Manila · 11.9:1 · warm`
- Free-stock note: `Dark is free. It always will be.`
- Catalog footer: `Six papers. It never gets longer and nothing on it ever leaves.`

**Off-states (`R12`)**

- `Your school has High Contrast on. Receipt stays out of the way.`

## Interactions and motion

Receipt adds almost no motion, on purpose.

| What | Property | Duration | Curve |
|---|---|---|---|
| "Show me" reveal, in | `opacity` on the dashed outlines | 160ms | `cubic-bezier(.2,0,0,1)` |
| "Show me" reveal, out | `opacity` | 120ms | same |
| Receipt row strikes through after Put back | `opacity`, `text-decoration-color` | 140ms | same |
| Row hover, everywhere | `background-color` to `--pk-paper-sunk` | **0ms — instant** | — |
| Card hover | **none. No lift, no shadow, no transition.** | — | — |
| Put back restoring the element | **none.** It is simply there on the next paint. | — | — |
| Stock change | **none.** | — | — |

The "Show me" outline is 1.5px dashed in `--pk-mark`, 4/3 dash, at 3px offset, with a
small-caps label. It never pulses and never loops.

**Reduced motion.** Receipt owns the whole block. Everything above goes to `0.01ms`, never
`none` — Canvas has JS waiting on `transitionend` (the mobile drawer animates `max-height` over
1.5s; `body.primary-nav-transitions` lands 300ms after a collapse). **Do not ship
`animation-iteration-count: 1`** — it freezes Canvas's infinite spinners after one cycle, which
reads as a hung page to the exact student who asked for reduced motion.

## What must not change

- `--ic-brand-primary` and its six derivatives. The four `--ic-brand-button--*` variables and
  their four darkened derivatives. `--ic-brand-header-image`. All 16 `--ic-brand-Login-*`.
- The hero's `opacity`. The title span's `color`. Any course colour.
- `.ic-flash-error`'s red, or any of the four `ic-flash-*` semantics.
- `font-family`, anywhere, in any mode.
- Any radius Canvas did not already use. No shadow is added. No hover lift.
- The order of the course nav. Students learn that menu by position.
- `#skip_navigation_link`, `.ic-sidebar-logo`, the Help link, any heading, any label, any link.
- `a.more_link` on Recent Feedback.
- Any width on `#header.ic-app-header` or `#left-side`.
- The login page, in any mode.

## Deviations

**Allowed, if you print the number:**

- Nudge a paper stock's hexes, if the body ratio stays ≥7:1 and the new measurement is
  reprinted on `R11`.
- Propose the seven unnamed tokens however you like, inside the naming rule above.
- The popup's internal layout, spacing and iconography are entirely yours.
- The dashed reveal's stroke pattern, offset and label placement.
- Any icon in the popup, as a drawn vector.
- Reordering the artboards if a different sequence reads better — say so.

**Not allowed:**

- Any Prepkin pixel on a Canvas page. No kin, no coin, no green, no wordmark, no strip, no
  string. The one exception in the whole concept is a **dashed KIN box at 16px, at rest, in the
  popup** — and if 16px is too small to read as anything, say so on the artboard and propose
  the smallest size that reads. Do not silently enlarge it.
- Renaming or adding to the seven Look-movable tokens.
- Putting dark mode, or any accessibility behaviour, behind coins.
- A padlock, a `?` tile, a countdown, a streak, a meter, or any number that can go down.
- Red, anywhere Receipt draws it.
- A selector containing `css-`.
- A rule that leaves a broken page when its hook misses.

## What I want back

One artboard per screen and state above. Then, in text:

1. The seven unnamed tokens, with a measured ratio for every pair they can form.
2. The `.ig-details` nesting question, drawn both ways, with the one-hour test written down.
3. The full toggle matrix — `pk-on` × `pk-dark` × six stocks × High Contrast — and what each
   cell renders.
4. What each per-page block degrades to when `context_modules_v2`, `widget_dashboard`,
   `instui_nav` or `instui_topnav` is on.

Quiet, plain, and provable. The worst case must be **Canvas, unchanged** — that is the whole
bet, and it is the only concept in the set that can say it. Tell me what you changed and why,
per screen.
