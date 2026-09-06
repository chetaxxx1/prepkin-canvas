# Prompt for Claude Design — Prepkin Canvas skin, concept 3: Low Beam

**How to use.** Paste `CLAUDE-DESIGN-PREAMBLE-CANVAS.md` first, then everything below the line.

*Read first — `design/canvas-skin/`:* `RESEARCH.md` (Corrections block, then §8 in full, then
§3.1–§3.6, §3.9–§3.12 for the pages here). **§7.1 complaint 2 is the whole reason this concept
exists — read the quotes.**

*The skin as it ships today — `extension/`:* `skin.css` · `looks.js` · `popup.html` (340px) ·
`panel.css` (360px).

---

I'm designing **Low Beam**, the third of three Canvas skin concepts for the Prepkin Chrome
extension. Give me one artboard per screen and state below, in this system, not in
BetterCanvas's.

## The concept

Every competitor ships dark mode as a switch, and every one of them ships a **half-darkened
page**: the LMS goes dark, then a file list, a document preview or a nav tray opens as a
full-brightness white rectangle. At 2am, with pupils adapted, that flash is worse than never
turning the lights off.

Low Beam is a **lamp, not a switch**. One drawn desk-lamp control in the rail turns Canvas down.
The deeper levels — set once in the popup, not on the school's page — re-anchor a five-step
luminance ladder, a text ceiling that comes **down** at the deepest step, a weight scale that
lightens as the ground darkens, the size of every image and course-colour block, and the
brightness of the surfaces the skin is not allowed to repaint.

**The dark steps are a different drawing, not an inversion.** Shadows go to zero and objects
separate by a light caught on their top edge, the way things separate in a dark room.

**The signature move.** Everything on a Low Beam page steps down with the lamp — every surface,
every teacher photo, every white frame, the course hero, the text ceiling itself — except one:
**Canvas's own primary button keeps the school's colour at 100% at every level, gains a 1px ring
so its boundary is provably visible on any ground, and is the only object on the page that moves
when you press it.** That is the exact inverse of the incumbent's documented worst bug.

**Why this matters more than taste.** The dark-mode request is eight years old, 354 comments,
still Open, opened by a student, and a meaningful share of it is disability rather than
preference — migraine, photosensitivity, astigmatism, Irlen syndrome. One quote to keep on your
desk while you draw: *"It is physically painful for me to do work in this program."*

**Its honest weakness, and you should design knowing it.** Nobody asked for four darks. Students
ask for dark. So the Canvas page carries **one switch** and the three dark levels live in the
popup. A student who never opens the popup gets exactly the product the evidence asks for — one
click, dark, done — and the ladder costs them nothing.

## Primary screen, and the rest

**`L2` — Dashboard, card view, at Late — is the primary screen.** Draw it first and hardest.
Late is the default dark step and the one most students will park on forever. If Late does not
read as a complete, finished dark mode on its own, the ladder is decoration.

`L3` (the four-step ladder strip) and `L6` (the submit button) are the two most important
supporting artboards. Everything else is a state.

## Artboards, in order

All 1440×900 unless noted.

| id | Artboard | Size | Note |
|---|---|---|---|
| `L1` | Dashboard, card view — Daylight | 1440×900 | Light, so the ladder has a top |
| `L2` | **Dashboard, card view — Late** | 1440×900 | **PRIMARY** |
| `L3` | The ladder, strip | 1440×460 | One card row at all four steps, L\* printed |
| `L4` | Right sidebar, close-up — Late | 520×900 | Promoted due line + amber pill + grade chip |
| `L5` | Modules — Late | 1440×900 | Due column, module band, indents, checks |
| `L6` | Assignment detail — Late | 1440×900 | Prose at 68ch + **the button** |
| `L7` | Grades — Late | 1440×900 | The statement |
| `L8` | Global nav rail, strip | 240×900 | Four steps, four cone heights |
| `L9` | The lamp icon sheet | 720×440 | **Gated on George** |
| `L10` | The seam, three tiers | 1120×760 | Repaint / veil / frame |
| `L11` | Nav tray — Late, veiled | 640×900 | The veil, in situ, with its off switch |
| `L12` | The prose repair | 760×900 | Word-pasted `.user_content`, before and after |
| `L13` | Popup | 340×560 | Three-stop slider, seam copy, Looks |
| `L14` | Looks sheet | 1120×760 | Two hue properties, six Looks |
| `L15` | Off-states sheet | 1120×640 | High Contrast · login · proctoring frame |

## States that must be drawn

- `L2` with Colour Overlay **off**. Low Beam never reads, writes or `!important`s `opacity`, so
  a student with that preference sees no change at all from this skin. Prove it.
- `L2` with a **teacher-uploaded photo** on a card, at `--pk-img` brightness — dimmed, never
  inverted, because inversion wrecks photographs, diagrams and scanned maths.
- `L2` mid-drag: Canvas writes inline `opacity: 0` on a card being reordered and nothing here
  fights it.
- `L4`: a due row at rest, a due row carrying the amber `still counts` pill, and a Recent
  Feedback grade chip.
- `L6`: the primary button at **rest / hover / focus-visible / active (pressed, 3px travel
  collapsed) / disabled**, with the ring visible in all five and the ratio printed on each.
- `L8`: the rail at Daylight / Dusk / Late / Low Beam, the lamp at cone heights **10 / 7 / 4 /
  2px**, the hover label at each, and the after-21:00 state (a word and a dot, nothing else).
- `L11`: the veil on, and the veil switched off by the student.
- `L15`: High Contrast on → **every `--pk-*` declaration and both CSS files removed**, not merely
  skipped. Plus `/login/*`. Plus a proctoring frame, which gets **nothing at all** — no filter,
  no caption, no ring, no ground.
- `L13`: the slider at all three dark stops, and the state where the lamp icon is **not
  approved** so the control is popup-only.

## Tokens

### The luminance ladder — five grounds per step

`L*` is CIE lightness. The ladder is what does the separating, so the 1px ring is deliberately
soft.

| Token | Daylight | Dusk | Late | Low Beam | Role |
|---|---|---|---|---|---|
| `--pk-void` | `#E2DCCC` L\*87.8 | `#211D19` L\*11.1 | `#141210` L\*5.6 | `#100E0C` L\*4.1 | Body ground, rail field, gutters, breadcrumb strip. **Never `#000`** — pure black maximises halation. |
| `--pk-page` | `#F4F1EA` L\*95.2 | `#2A2621` L\*15.4 | `#1C1916` L\*9.0 | `#151310` L\*6.0 | The reading ground. `#content`, module rows, table rows, planner rows. |
| `--pk-card` | `#FCFAF5` L\*98.3 | `#352F29` L\*19.8 | `#252019` L\*12.6 | `#1D1A16` L\*9.5 | Card face, sidebar widget, `#student-grades-final`. **Never `#FFFFFF`.** |
| `--pk-raise` | `#EFEADD` L\*92.8 | `#3F3931` L\*24.3 | `#2E2922` L\*16.9 | `#26221C` L\*13.5 | Module header band, table header, row hover, active nav tab. **Elevation in dark, recession in light** — same token, opposite job. |
| `--pk-band` | `#E8E2D4` L\*90.0 | `#494238` L\*28.4 | `#38322B` L\*21.2 | `#2E2921` L\*16.9 | Chips, quiet pills, grade chips, the seam caption strip. |

### Ink — measured against each ground, all four steps

| Token | Daylight | Dusk | Late | Low Beam |
|---|---|---|---|---|
| `--pk-t1` primary | `#2A2621` | `#EAE4D8` | `#E0D9CC` | `#C9C1B3` |
| on void / page / card / raise / band | 10.98 / 13.32 / 14.40 / 12.51 / 11.63 | 13.22 / 11.87 / 10.43 / 9.01 / 7.83 | 13.32 / 12.47 / 11.52 / 10.28 / 9.02 | 10.79 / 10.39 / 9.71 / 8.86 / 8.08 |
| `--pk-t2` secondary | `#5B5245` | `#C3B9A8` | `#B4AA9B` | `#A2988A` |
| on void / page / card / raise / band | 5.60 / 6.80 / 7.35 / 6.39 / 5.94 | 8.63 / 7.75 / 6.81 / 5.88 / 5.11 | 8.15 / 7.64 / 7.05 / 6.29 / 5.52 | 6.78 / 6.53 / 6.10 / 5.57 / 5.08 |
| `--pk-t3` tertiary floor | `#6A5E4E` | `#B0A695` | `#9C9284` | `#968D7E` |
| on void / page / card / raise / band | 4.62 / 5.60 / 6.06 / 5.26 / 4.89 | 6.96 / 6.25 / 5.49 / 4.74 / **4.12** | 6.10 / 5.72 / 5.28 / 4.71 / **4.13** | 5.88 / 5.66 / 5.29 / 4.83 / **4.40** |

**One hard rule falls out of the bold cells: `--pk-t3` is legal on void, page, card and raise.
On `--pk-band` and anything above it the floor is `--pk-t2`.** Print that on `L3`.

Nothing renders below 4.5:1 — **including disabled controls**, which keep `--pk-t3` rather than
taking WCAG's disabled-control exemption. A student needs to read a disabled submit button to
learn why it is disabled.

**Low Beam's `--pk-t1` is deliberately lower than Late's**: 10.39:1 against page, down from
12.47:1. Maximum contrast is not maximum readability. Near-white on near-black haloes for
astigmatic and Irlen readers, and AAA's 7:1 is a floor, not a target. Say that on `L3`.

### Colour

| Token | Daylight | Dusk | Late | Low Beam | Role |
|---|---|---|---|---|---|
| `--pk-accent` | `#1E6B4C` | `#5FCFA2` | `#57C79B` | `#4FA783` | Links, active nav edge, today's mark, completion check. On page: **5.71 / 7.82 / 8.37 / 6.35**. Only text, a 3px edge, or a stroke. **Never a large fill on a dark step.** |
| `--pk-accent-quiet` | `rgba(30,107,76,.10)` | `rgba(95,207,162,.12)` | `rgba(87,199,155,.13)` | `rgba(79,167,131,.11)` | The only accent fill, and only behind text already at `--pk-t1`. |
| `--pk-amber` | `#F5E3C9` (tint) | `#EFAE45` | `#E8A63C` | `#CE9235` | Urgency, reading "still counts". **Tint in light, solid pill in dark** — a deuteranope separates amber from mint by figure-ground, not hue. |
| `--pk-amber-ink` | `#7A4E11` | `#211D19` | `#141210` | `#100E0C` | Text on the pill: **5.71 / 8.62 / 8.86 / 7.14**. Amber is never loose coloured text. |
| `--pk-focus` | `#7A5A16` | `#F5D089` | `#F2C877` | `#DDB765` | 2px outline, 2px offset, on every focusable element the skin touches. On page: **5.64 / 10.21 / 11.09 / 9.74**. |
| `--pk-btn-ring` | `--pk-t3` | `--pk-t2` | `--pk-t2` | `--pk-t2` | 1px ring on Canvas's primary button. |

**There is no red anywhere in this sheet.** Canvas's `ic-flash-error` keeps the platform's own
red, untouched. `#000` and `#FFF` never appear as a value.

### Non-colour tokens

| Token | Daylight | Dusk | Late | Low Beam | Role |
|---|---|---|---|---|---|
| `--pk-veil` | `1` | `.94` | `.90` | `.86` | `brightness()` on the **two** same-origin surfaces the skin owns the document for but cannot select into. Nothing else. |
| `--pk-img` | `1` | `.94` | `.86` | `.78` | `brightness()` on teacher imagery. **Dimmed, never inverted.** |
| `--pk-hero` | `146px` | `146px` | `96px` | `56px` | Height of `.ic-DashboardCard__header_hero` **and** `__header_image`, in one rule. Reduces chromatic *area*, never chromatic value. `opacity` is never touched. |
| `--pk-wt-head` | `700` | `600` | `600` | `600` | Light-on-dark glyphs bloom, so the scale drops a step in dark. |
| `--pk-wt-mid` | `600` | `500` | `500` | `500` | |
| `--pk-track` | `0` | `.004em` | `.006em` | `.008em` | Extra tracking on headings and `--pk-t1` rows. |
| `--pk-shadow` | `0 1px 2px rgba(42,38,33,.06), 0 8px 20px rgba(42,38,33,.08)` | `none` | `none` | `none` | Shadows exist **only** at Daylight. |
| `--pk-edge` | `inset 0 0 0 0 transparent` | `inset 0 1px 0 rgba(255,244,228,.060)` | `.055` | `.045` | **The dark-step replacement for shadow.** In a dark room you see edges catch light, not shadows cast. Every card, row and band carries this on its top edge. |
| `--pk-dur` | `180ms` | `180ms` | `90ms` | `0ms` | Every transition duration. |
| `--pk-lamp-h` | `70` | `70` | `70` | `70` | oklch hue of the light. A Look moves this. |
| `--pk-look-h` | `152` | `152` | `152` | `152` | oklch hue of the accent. A Look moves this. Nothing else. |

### Type, shape, rhythm

**Font stack is off by default.** The system stack is declared once on `html[data-pk-font="system"]`
and is a popup option, disabled whenever the computed body font contains OpenDyslexic. Zero
external requests, ever.

**Size scale, rem.** `0.8125` (13px, floor — Canvas's 12px meta text is raised) · `0.875` (nav
labels, secondary) · `0.9375` (row titles, body UI) · `1.0625` (prose) · `1.25` (module headers)
· `1.5` (page h1).

**Weight scale.** Daylight 400 / 600 / 700. Dusk, Late, Low Beam 400 / 500 / 600. **No 800 or
900 exists on any dark step.**

**Prose.** `.user_content`: `1.0625rem / 1.65 / max-width: 68ch`, paragraph gap `0.9em`.

**Radii.** 12px card and primary button, 8px row, 6px chip, 999px pill. Deliberately **below**
the Prepkin panel's 16–20px: the page is imposed, the panel is not.

**Borders: none.** Every edge is `box-shadow: inset 0 0 0 1px var(--pk-line), var(--pk-edge)`,
which is layout-neutral, so a missed rule leaves a plain surface rather than a size change.
`--pk-line` sits at 1.37–1.65:1 against `--pk-card` on purpose — a hard hairline at 2am is
itself a light source.

**Spacing, 4px base.** 4 / 8 / 12 / 16 / 24 / 32. Card padding 16. Row padding 12 vertical, 14
horizontal. Section gap 24.

**States are ladder steps, never opacity changes.** Hover is surface +1, active is surface +2,
disabled holds `--pk-t3` and its 4.5:1. No state change can reduce contrast, because every state
is a defined ground with a measured ratio.

## What each page does

### `L8` / `L9` — the rail, and the lamp

`#header.ic-app-header` (verified) gets its ground from a **read**, not a write:

```css
#header.ic-app-header,
#mobile-header {
  background-color: color-mix(in oklab, var(--ic-brand-global-nav-bgd) 16%, var(--pk-void));
}
```

Mix share: **100% Daylight (untouched) / 18% Dusk / 16% Late / 12% Low Beam.** The institutional
hue survives at a fraction of the light output. The variable is read, never set, so the correct
value is there at first paint with zero JS, and if `color-mix` fails to parse the whole
declaration drops and Canvas's own nav stands — the right fallback.

**The share is capped by measurement, not taste.** Worst case, a school running a pure white
nav: `--pk-t2` lands at **4.84:1 at Dusk, 5.10:1 at Late, 5.03:1 at Low Beam**. Any higher share
and inactive nav labels fail AA. Print that. A light-nav school loses more of its look than a
dark-nav school. That is the honest cost of a dimmer and it is stated in the popup.

**The lamp** is one `<li class="ic-app-header__menu-list-item">` appended after
`#global_nav_calendar_link` (verified), inheriting Canvas's hover label, badge slot and active
styling for free. A real `<button>` with `aria-pressed`, sitting in DOM order between Calendar
and Inbox, so it is the sixth or seventh tab stop and needs no `tabindex`.

Draw it on `L9`: **26×26 viewBox** to match Canvas's own nav icons, **1.6px `currentColor`
stroke, round caps**. A trapezoid shade, a two-segment arm, an ellipse base. Below the shade, a
cone as a filled triangle in `--pk-accent` at `0.9` alpha, at four heights: **10 / 7 / 4 / 2px**.
**Nothing else in the icon changes between states.**

**This is new drawn art on a school-owned surface. It is gated on George** (constraint 22). If
it is not approved, the rail ships without it and the control is popup-only. **Nothing else in
this brief may depend on the icon existing** — draw `L13` so the popup works alone.

Under `instui_nav` the whole header is replaced and every `#global_nav_*` id disappears.
Feature-detect `#instui-sidenav`; if present, **skip the injection entirely**.

### `L2` — Dashboard, card view

`.ic-DashboardCard` → `--pk-card`, radius 12,
`box-shadow: inset 0 0 0 1px var(--pk-line), var(--pk-edge)`. The container's `-36px` negative
gutters are zeroed **in the same declaration block** as the grid, so it can never half-apply
into overlap.

**Why the hero shrinks but never disappears.** 146 → 96 → 56px is a reduction in chromatic
*area*; the hex is byte-for-byte Canvas's at every step. The **3px course-colour spine is present
at every step**, read from the hero's inline `backgroundColor`. The 56px floor plus the spine
means the two colour cues can never both be gone. If both are unavailable, there is no spine and
the hero is still 56px of the course's own colour.

`.ic-DashboardCard__placeholder-svg .ic-DashboardCard__placeholder-animates` (verified) is
painted in the **static** sheet so the server-rendered light skeleton never flashes before React
mounts. Draw that state.

### `L4` — Right sidebar

`.ToDoSidebarItem__Info` (verified) is the due line, and it becomes **the brightest thing in the
column**: `display: block; margin-top: 4px; color: var(--pk-t1);
font-weight: var(--pk-wt-mid); font-variant-numeric: tabular-nums`. The heading is deliberately
*not* the loudest thing.

**The amber pill parses nothing.** The concept planned to regex `"N points • Sep 5 by 11:59pm"`.
That string is `I18n`-rendered and breaks on any non-English Canvas. Instead the pass matches
each row's own `href` against the ISO dates the extension **already stores** in
`chrome.storage.local`, and adds `class="pk-still"` when the stored `due_at` is past. No string
parsing, no locale dependence, no new network request.

Recent Feedback's grade becomes a `--pk-band` chip in `--pk-t1`, tabular, radius 6. **Neutral. No
colour, no green, no red, no comparison.**

**Refused, and say so on the artboard: the missing-work count.** Surfacing what is hidden behind
the bell would be a real behaviour change and it is still cut. A number that says how far behind
you are goes *down*, it is pinned to the dashboard every day, and a student six assignments
behind sees their failure every time they open Canvas. Individual overdue rows still get the
amber pill. **There is no aggregate number anywhere in this skin.**

### `L5` — Modules

`.ig-info` (verified) carries **the one layout rule on the page**:
`display: flex; flex-wrap: wrap; align-items: baseline; gap: 8px 16px`. Then
`.ig-details { margin-left: auto; text-align: right }` and
`.due_date_display { font-variant-numeric: tabular-nums; min-width: 9ch;
display: inline-block; text-align: right }`. **That is the due column.**

Say it honestly on the artboard: this is one rule pair, no JS, and it covers the Assignments
index for free because `.ig-row` grammar is shared. **It does not remove a single click.** Modules
gets readability and a scannable due column; the "five different links" complaint is untouched
and the brief does not pretend otherwise.

`.completion_requirement`: met → a drawn 2px `--pk-accent` check; unmet → `--pk-t3` text. Canvas's
own state, made visible. **No meter, no percentage, no "3 of 8".**

`.context_module_item.indent_1…5` get real 20px steps, so indent levels read as a hierarchy
instead of a hint.

**Refused: type-coded rows.** The page map verifies no per-type class on `.context_module_item`.
Inventing one would be a guess.

Draw the `context_modules_v2` fallback too: **exactly one hook survives**
(`className="context_module_item"`), every rule above is paint or a flex container, and the page
falls back to `--pk-page` with `--pk-t1` text and stays completely readable.

### `L6` — Assignment detail, and `L12` — the prose repair

Prose at `1.0625rem / 1.65 / 68ch` — the measure WCAG 1.4.8 asks for and Canvas does not provide.
Links `--pk-accent` with a **permanent** underline. `.user_content img` gets
`filter: brightness(var(--pk-img))`, **never `invert()`**.

**The prose repair (`L12`).** A bounded JS pass over
`.user_content [style*="color"], .user_content [style*="background"]`. For each, measure the
computed colour against the current ground; below 4.5:1, add a class that sets
`color: var(--pk-t1)`. A near-white inline background gets `--pk-raise` instead, and the text
pass re-runs against the new ground. **Bounded: first 60 matching nodes, whole pass aborts above
200** (a pasted spreadsheet). The pass **only ever adds a class** — it never removes or rewrites
markup, so a failure leaves the teacher's original inline colour intact. Draw the before and
after side by side.

**The submit affordance — draw this at full size on `L6`.**

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
  box-shadow: 0 0 0 1px var(--pk-btn-ring),
              0 0 0 var(--ic-brand-button--primary-bgd-darkened-15);
}
```

**Shape is ours, colour is theirs.** The 12px radius, the 3px edge and the press travel are
Prepkin's. The fill, the label and the edge colour are Instructure's own computed values, so
contrast inside the button is byte-for-byte the school's.

**The ring is what makes the headline provable.** A dark-navy school primary such as `#394B58`
sits at **1.93:1** against `--pk-page` at Late — a nearly invisible submit button, the incumbent's
worst bug arriving through the front door. WCAG 1.4.11 is satisfied when *either* the fill or the
ring clears 3:1 against the adjacent page. Print this table on `L6`:

| School fill | ring-vs-fill @ Low Beam | fill-vs-page @ Low Beam | best |
|---|---|---|---|
| `#394B58` navy | 3.19 | 2.05 | **3.19** ✓ |
| `#0374B5` Canvas default | 1.77 | 3.68 | **3.68** ✓ |
| `#008EE2` older default | 1.24 | 5.27 | **5.27** ✓ |
| `#FFC107` amber | 1.74 | 11.38 | **11.38** ✓ |
| `#7A003C` maroon | 3.91 | 1.67 | **3.91** ✓ |
| `#2D3B45` near-ink | 4.06 | 1.61 | **4.06** ✓ |

The construction fails only for a fill whose luminance sits around `Y ≈ 0.07–0.12` — roughly a
mid-grey `#5C5C5C`. **The escalation rule: `--pk-btn-ring` goes to `--pk-t1` when neither clears**,
which lifts that case to 3.69:1. It is a release gate, not a warning. Draw the escalated state.

**Retired claim, and do not put it back:** "the brightest object on a Low Beam page is always the
button you are supposed to press". It is false — `--pk-t1` at 10.39:1 has a higher luminance than
any mid-toned button. **The claim that is true and checkable: at Low Beam the submit button is
the only object left at full colour, and the only object that moves.**

### `L7` — Grades

`#grade-summary-react` (verified) is the **gate**. Then: all vertical rules and all zebra
striping removed, rows separated only by `box-shadow: inset 0 -1px 0 var(--pk-line-soft)` at
1.12–1.24:1 — a whisper. `.assignment_score .grade` is **the one `--pk-t1` cell**.
`#student-grades-final` is lifted to a `--pk-card` block at the top of
`#student-grades-right-content` instead of a table row lost mid-page.

`.min` / `.max` / `.median` get `--pk-t3` and **nothing else**. That is a refusal, not an
oversight. No distribution bar, no what-if calculator, no letter-grade colouring.

### `L10` / `L11` — the seam, three tiers

Chosen by what can be **proved** about a surface, not by whether it is React. The tier is stated
in the product, not hidden.

**Tier A — repainted for real.**

| Surface | Hook | What happens |
|---|---|---|
| New Quizzes | `body.native-new-quizzes > #new-quizzes-root > #root` (verified) | Stopped being an iframe on 2026-08-15. Container ground, spacing and typography only. Submit affordance untouched. |
| Canvadocs / DocViewer | second content-script instance inside the frame (verified) | `all_frames: true` plus the two host origins. Document shell gets the ladder; the page canvas is left alone. |

**Tier B — veiled.** Two surfaces only, both same-origin, **neither containing a submit control**:
Files v2's `#content` (its table components have literally zero `className` attributes) and
`.navigation-tray-container .tray-with-space-for-global-nav`.

**Print the veil's arithmetic on `L10`, correctly.** `filter: brightness(k)` multiplies channel
values by *k*, so the contrast ratio **always falls**. It never rises.

| k | White ground becomes | Black ink | Canvas ink `#2D3B45` | AA-floor grey `#767676` |
|---|---|---|---|---|
| 1.00 | `#FFFFFF` | 21.00:1 | 11.83:1 | 4.54:1 |
| .94 (Dusk) | `#F0F0F0` | 18.43:1 | 10.71:1 | **4.41:1** |
| .90 (Late) | `#E6E6E6` | 16.83:1 | 10.06:1 | **4.33:1** |
| .86 (Low Beam) | `#DBDBDB` | 15.17:1 | 9.35:1 | **4.21:1** |

**There is no factor below 1.0 that preserves a pair already at 4.54:1.** So "pick a safer k" is
not an available answer. The honest statement: the veil cuts emitted light and costs about 8–11%
of the contrast ratio; nothing that starts at AAA lands below AA; text that starts at exactly the
AA floor lands just under it, at 4.21:1 worst case, on two surfaces whose ink is overwhelmingly
`#2D3B45` at 9.35:1.

The mitigation is control, not arithmetic: **the veil is the one thing in the sheet with a
per-surface off switch** — a 24px `<button>` with `aria-pressed` in the caption strip, one click,
remembered per origin. Draw it on `L11`, both states.

**Tier C — named and left alone.** Third-party LTI gets `.tool_content_wrapper` (verified) with a
`--pk-void` gutter, 12px radius, a 1px `--pk-line` ring and 22px of top padding holding an
absolutely-positioned `--pk-band` caption strip. **The frame itself keeps every pixel Canvas
gives it.** InstUI modals and `instui_header` page headers: not reached, left in Canvas's own
colours.

**Proctoring gets nothing at all.** No filter, no caption, no ring, no ground. Excluded in pure
CSS with `iframe#tool_content.tool_launch:not([src*="proctor"]):not([src*="respondus"]):not([src*="lockdown"])`,
and again by a route gate. Dimming a proctored exam is an academic-integrity hazard and the single
most block-worthy thing the concept could contain.

**The design idea that survives, and it is the point of `L10`:** a surface the skin cannot prove
is not half-painted and not apologised for — it is **framed**. A bounded, ringed, captioned white
panel in a dark page. A lit window in a dark room.

### `L14` — Looks

**A Look supplies hue only. The dimmer owns every luminance value, and therefore every contrast
number.** Two custom properties, set inline on `<html>`, with the plain hex declared first as the
parse fallback:

```css
--pk-accent: #57C79B;
--pk-accent: oklch(0.80 0.12 var(--pk-look-h));
--pk-card:   #252019;
--pk-card:   oklch(0.152 0.008 var(--pk-lamp-h));
```

| Look | Price | `--pk-lamp-h` | `--pk-look-h` | Accessory (panel only) | Status |
|---|---|---|---|---|---|
| Classic Cream | free | 70 (tungsten) | 152 (mint) | none | Existing. The default lamp. |
| Woodland | 300 | 128 | 150 | `sprout` | Existing. |
| Cozy Beanie | 300 | 300 | 300 | `beanie` | Existing. |
| Tidepool | 450 | 195 | 188 | `glasses` | Existing. |
| Butterscotch | 300 | 45 | 40 | `scarf` | Existing. |
| **Night Shift** | 500 | 258 | 205 | `beanie` | Existing, **re-jobbed** |
| **Moonlight** | 450 | 250 | 232 | `beanie` | **New.** Near-neutral and cool, for students who find warm screens nauseating. |

Three consequences to print on `L14`: twenty surface values from two inputs; **no purchase can
reach a contrast number**, because chroma is clamped at `0.008` on grounds and `0.12` on the
accent; and a Look actually reads at 2am, which retires the bug where all six looks render an
identical page in dark.

**Nothing is taken away.** An alias layer ships so every old `tints` key still resolves:
`--pk-inset: var(--pk-raise)`, `--pk-row: var(--pk-page)`, `--pk-text: var(--pk-t1)`,
`--pk-text-2: var(--pk-t2)`, `--pk-text-3: var(--pk-t3)`, `--pk-green: var(--pk-accent)`,
`--pk-mint: var(--pk-accent)`, `--pk-mint-edge: var(--pk-accent)`, `--pk-track: var(--pk-line)`,
`--pk-circle: var(--pk-t3)`, `--pk-amber-text: var(--pk-amber)`.

**Night Shift gets a new job.** It exists today only to grant dark mode, which Low Beam gives away
free — so 500 coins would have bought nothing. It becomes the one Look that also carries a preset:
wearing it sets the lamp to **Low Beam** on first wear, and it ships the indigo lamp hue nothing
else has. The coins bought a hue and a setting instead of a feature.

## Copy — verbatim

- Lamp `aria-label`, naming the current step: `Low Beam: Late. Turn Canvas up.`
- Lamp hover label, normal: `Low Beam`
- Lamp hover label, after 21:00 local: `Turn it down`
- Popup section: `The lamp`
- Popup slider stops: `Daylight` · `Dusk` · `Late` · `Low Beam`
- Popup note under the slider: `Dark is free. It always will be.`
- Popup, the light-rail school: `Your school's menu bar is light. Low Beam leaves it alone so
  the logo still reads.`
- Seam caption on an LTI frame: `Your school's page. Prepkin can only dim it.`
- Veil off switch, `aria-label`: `Turn this page's dimmer off`
- Sidebar / Modules amber pill: `still counts`
- High Contrast: `Your school has High Contrast on. Low Beam stays out of the way.`
- Popup, the seam, one line: `Some pages inside Canvas belong to other companies. Low Beam can
  dim those but it can't repaint them.`

**No countdown, no "X days left", no aggregate, no percentage, anywhere.**

## Interactions and motion

Canvas honours `prefers-reduced-motion` **nowhere** — zero occurrences in 401 KB of `common.css`
against 40 `transition:` and 6 `animation:`, and zero across instructure-ui master. Every
transition here is new motion and the skin owns the whole block.

| What | Property | Duration (Daylight / Dusk / Late / Low Beam) | Curve |
|---|---|---|---|
| Nav item hover | `background-color` | `calc(var(--pk-dur) * 0.78)` → 140 / 140 / 70 / **0**ms | `cubic-bezier(.2,0,0,1)` |
| Card hover | `box-shadow` | `var(--pk-dur)` → 180 / 180 / 90 / **0**ms | same |
| Row hover (module, planner, grades, sidebar) | `background-color` | `calc(var(--pk-dur) * 0.67)` → 120 / 120 / 60 / **0**ms | same |
| **Primary button press** | `transform`, `box-shadow` | `calc(var(--pk-dur) * 0.5)` → 90 / 90 / 45 / **0**ms | same |
| Lamp cone crossfade | `opacity` on two stacked paths | `var(--pk-dur)` | same |
| Focus ring | none | 0ms, always | — |
| **Step change** | none | **0ms. No cross-fade. A lamp switches.** | — |

**No transform on cards.** The shipped `translateY(-3px)` lift is deleted, not guarded — a lift
across a dense grid is jitter. Cards separate by shadow at Daylight and by the caught edge in
dark, neither of which moves. **The only thing that moves on a Low Beam page is the submit
button, and that is the point.**

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

Two notes for the artboard. **This is deliberately global** — since Canvas honours the preference
nowhere, the block also silences Canvas's own 40 transitions and 6 animations, including the
mobile drawer's 1.5-second `max-height` reveal, which becomes instant and is correct. `.01ms`
rather than `0` so `transitionend` handlers still fire. **The press keeps its state change and
loses its travel** — `:active` still collapses the 3px edge, which is a state readout, not
vestibular motion.

**At Low Beam this block's contents apply unconditionally**, whether or not the OS preference is
set.

Canvas's confetti is a canvas-drawn animation, not CSS, and is **not touched**. It is
Instructure's feature and their preference to honour.

## What must not change

- `--ic-brand-primary` and its six derivatives. `--ic-brand-button--primary-bgd` and
  `--ic-brand-button--secondary-bgd` and their four derivatives. `--ic-brand-header-image`. All
  16 `--ic-brand-Login-*`. Every watermark, Discovery and Registration variable.
- `--ic-brand-global-nav-bgd` is **read inside a `color-mix`, never written**.
- `--ic-brand-button--primary-bgd-darkened-15` is **read for the press edge, never written**.
- `opacity`, anywhere. It is never read, written or `!important`-ed, so drag-reorder and the
  Colour Overlay preference both keep working untouched.
- Any course colour. `.ic-DashboardCard__header-title span`'s inline colour.
- `.ic-flash-error` and the other three `ic-flash-*` semantics.
- Any `width`, `display`, `position` or `order` on `#header.ic-app-header` or `#left-side`.
  `toggleCourseNav.js` writes inline `display` and a competing rule can strand the menu closed.
- `.tray-with-space-for-global-nav`'s `margin-left` — it is 54 / 84px depending on rail state.
- `#planner-app-fixed-element`. `#skip_navigation_link`. `.mobile-header-hamburger` (it binds
  `touchstart` with `preventDefault`; a second listener breaks the native open).
- The order of the course nav, and the position of any tab.
- The login page, in any mode.

## Deviations

**Allowed, if you print the number:**

- Nudge any ladder value, if every ratio in the ink table is re-measured and still ≥4.5:1, and
  the `--pk-t3`-on-`--pk-band` rule still holds.
- The `color-mix` shares, if the pure-white-nav worst case still clears AA on `--pk-t2`.
- The lamp icon's geometry entirely — the cone heights (10 / 7 / 4 / 2) are the one thing to
  preserve, because they are what makes the step legible.
- The seam caption's placement, the veil switch's icon, and the popup's whole internal layout.
- Reordering the artboards if a different sequence reads better — say so.

**Not allowed:**

- `filter: invert()`, anywhere, ever.
- `#000` or `#FFF` as a value.
- A filter on any LTI launch frame, at any step, with or without an opt-in.
- Red, anywhere Low Beam draws it.
- Any aggregate number — no missing-work count, no completion percentage, no "3 of 8", no meter,
  no countdown, no streak.
- A grade distribution, a what-if calculator, or a letter-grade colour.
- 800 or 900 weight on any dark step.
- An opacity-based hover or disabled state.
- Any kin, coin, badge, character or progress ring on a Canvas page. **The only Prepkin-drawn
  pixel on a school-owned surface is the one 26×26 lamp vector, and it is gated.**
- A persistent status strip in the breadcrumb bar, or a footer in the trays. **The empty half of
  the breadcrumb bar stays empty.**
- Automatic switching by clock. After 21:00 the lamp's hover label changes one word and a 2px dot
  appears at its base. **The step never changes itself.**
- Putting any of the four steps, the veil, the prose repair or the due column behind coins. Coins
  buy the hue of the light, never the amount of it.
- A selector containing `css-`.

## What I want back

One artboard per screen and state above. Then, in text:

1. The lamp icon at all four cone heights, plus its `aria-pressed` and `aria-label` copy at each
   step — and a note confirming the rail still works with the icon absent.
2. Every ratio in the ink and colour tables, re-measured on the ground it actually lands on.
3. The veil's arithmetic table, and the one-click off switch's full state list.
4. The submit-button ring table for all six school fills at all four steps, with the escalation
   case drawn.
5. What each per-page block degrades to under `instui_nav`, `instui_topnav`, `context_modules_v2`,
   `files_v2`, `widget_dashboard` and `restrict_quantitative_data`.

A lamp, not a switch. The worst case must be a page that is quiet, not one that is broken. Tell
me what you changed and why, per screen.
