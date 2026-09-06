# Prepkin Canvas — Canvas-skin brief preamble

Paste this block first, every time, before any Canvas-skin brief. Then paste one brief.
One screen per request.

This is the parallel of `design/CLAUDE-DESIGN-PREAMBLE.md`. That one is for the SwiftUI
iPhone app. **None of it applies here.** Different surface, different geometry, different
rules. Read it for voice only.

---

You are designing one screen of a **Canvas skin**, with its states, for **Prepkin Canvas**.
The whole repo is public at `github.com/chetaxxx1/prepkin-canvas` (branch `main`). Read it
before you draw. You do not write CSS; Claude Code ports your handoff.

## What this is, and what it is not

Prepkin Canvas is a companion app for high school students. A mascot, the **kin**, lives on
the home screen of an iPhone app. Real Canvas LMS assignments sync in through a **Chrome
extension** and appear as tasks. Finishing daily tasks earns coins. Coins grow the kin.

**This brief is about the Chrome extension, not the app.** The extension does two things on
a Canvas page:

1. It ships an **opt-in panel** — a 64px launcher at `right: 18px; bottom: 18px` that opens a
   360px-wide slide-over (`#prepkin-buddy`). The student clicked it. Personality lives here.
2. It ships a **skin** — CSS over Canvas's own HTML, on every page the student opens. The
   student did not choose to see this. It is imposed on a school-owned surface.

There is also a **340px browser-toolbar popup** (`extension/popup.html`), which is also opt-in.

A skin has got an extension blocked district-wide before. One IT manager: the extension came
off every student machine in an afternoon, and a student said losing it wrecked their
organisation. **Restraint here is a feature, not timidity.** The worst outcome in this
category is not a bad review. It is a whole school losing the tool at once.

## You cannot change the HTML

Canvas's markup belongs to Instructure. You are painting over someone else's page and you
cannot add, remove or re-parent a node except in the two or three places a brief names.

**So every proposal must name the selector it rides, and carry that selector's confidence
label.** The labels come from `RESEARCH.md` and mean:

- `verified` — read in the `instructure/canvas-lms` or `instructure-ui` source, or measured
  on a live instance. Safe.
- `likely` — strong inference from verified code. Usable, never load-bearing.
- `guess` — the style exists, no emitter found. **Write the word "guess" on the artboard.**

A proposal with no selector is not a proposal. If you want to style something and it is not
in the page map, say plainly that you are guessing and design the fallback first.

**Never invent Canvas markup.** Never propose anything needing a Canvas API write, a login,
or a server.

## The canvas, and the page you do not own

Desktop artboards, **1440×900**. That is the page, not the browser window — draw no browser
chrome, no tabs, no address bar, except on a popup or toolbar artboard where the brief asks
for it. No fake OS chrome anywhere.

Draw at these positions. **They are drawing numbers only.** Canvas derives every one of them
at runtime and the skin must never write a width.

| Band | x | Width | Selector |
|---|---|---|---|
| Global nav rail | 0 – 54 | 54 | `#header.ic-app-header` (verified) |
| Course menu — course pages only | 54 – 246 | 192 | `#left-side` (verified) |
| Content column — dashboard | 78 – 1104 | 1026 | `#content.ic-Layout-contentMain` (verified) |
| Content column — course page | 270 – 1104 | 834 | same |
| Right sidebar | 1128 – 1416 | 288 | `#right-side-wrapper` (verified) |
| Right gutter | 1416 – 1440 | 24 | — |

Vertical: the breadcrumb bar `.ic-app-nav-toggle-and-crumbs` is the top ~48px of the page
area on course pages and is **absent on the dashboard**, which has
`#dashboard_header_container` instead. Content starts under whichever is present.

Four numbers that will bite you if you hardcode anything:

- The rail is **54 / 84 / 104px** — 54 collapsed, 84 expanded, 104 with the dyslexic font on.
- The course menu is **192 / 218px**, same reason.
- **≥992px** the right sidebar is a column; below that it stacks under the content. With
  `body.course-menu-expanded` that breakpoint moves to **1140px**.
- **<768px** the rail is `display: none` and a ~56px `#mobile-header` takes over.

So: never set `width`, `display`, `position` or `order` on the rail or the course menu. If you
add a border to `#left-side` or `#right-side-wrapper`, ship `box-sizing: border-box` in the
same rule and say so on the artboard.

Type is the **system stack** — `system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue",
Arial, sans-serif`. No web font, ever. Do not set `font-family` at all unless the brief
explicitly opens that door.

## The mascot — never draw it, and mostly do not place it

The kin is **Sprout**, a finished character rendered from real assets. Wherever a kin appears,
draw a **dashed box labelled KIN** at the size you intend, and name the coat in a caption.
Never sketch, restyle or approximate the character.

Where a kin is allowed:

- Inside the **panel** (`#prepkin-buddy`, 360px, opt-in).
- Inside the **toolbar popup** (340px, opt-in).

Where a kin is not allowed — this is a hard line, not a preference:

- **No kin on any Canvas page. None. Ever.** Not on the dashboard, not in the rail, not in the
  breadcrumb bar, not on a course card, not on a module row, not in a toast, not in a footer
  strip, not in a tray, not as a favicon overlay, not at 16px, not at rest.
- No coin count, no progress ring, no badge, no Prepkin green, no Prepkin wordmark, and no
  Prepkin string of any kind on a school-owned page.

The reason is documented, not aesthetic. The student did not choose the skin, the recorded
student behaviour on Canvas chrome is **subtractive** — the most-shared tips are "remove the
weird default images", "remove the sidebar logo", "hide the default To Do" — and nothing in
the collected student voice asks for a character inside Canvas. They ask for **their own**
colours, fonts and images. Character belongs in the surface they clicked open.

**New drawn art on a school page inherits the sign-off gate.** If a brief asks for a drawn
vector that lands on a Canvas page, design it, mark it gated on George, and make sure
everything else in the brief works with the art absent.

## Rules you must not break

**The page belongs to the school**

- **Never ship a selector containing `css-`.** Not a full Emotion hash, not a label-anchored
  partial like `[class*="-view--flex"]`. Stay on the four safe tiers: `--ic-brand-*`
  variables, the legacy ERB skeleton, Canvas's own semantic classes, and `data-testid`.
- **Every rule is a no-op when its selector misses.** Additive styling. A missed hook leaves a
  plain page, never a broken one. If a proposal cannot fail that way, it does not ship. Say
  what each block degrades to.
- **Derive from the school, never replace it.** Read the computed `:root`. The school's
  logomark (`--ic-brand-header-image`), its login page, and its own brand colours survive the
  skin. A district that reads the skin as defacement blocks it.
- **Course colours are read, never written.** Take them from Canvas. Never recolour
  `.ic-DashboardCard__header-title span`, and never `!important` the hero's `opacity` — both
  destroy the last colour cue for a student who turned Colour Overlay off.
- **Never style the submit affordance into invisibility.** No rule sets `background`, `color`,
  `border` or `opacity` on a `button`, `.btn`, `[type=submit]`, `input[type=submit]` or
  `[role=button]`. The incumbent's documented worst bug is a submit button painted the colour
  of its own background, reported as "it doesn't let me submit assignments", and it helped get
  the extension blocked. Print a measured contrast number for every control state.
- **Never recolour `.ic-flash-error`.** That red is Canvas telling a student something failed.
  Softening it to stay on-brand is the skin lying on the school's behalf.
- **Design for the seam.** Some surfaces cannot be reached — third-party LTI frames, Files v2,
  InstUI tray interiors. Frame them, caption them, leave them stock. Never half-paint one, and
  never hide the limitation from the student.
- **Assume three DOM generations behind every URL.** `context_modules_v2`, `files_v2`,
  `widget_dashboard`, `instui_nav`, `instui_topnav`, `instui_header` are all in master behind
  flags. Draw the degraded page too.

**Accessibility**

- **The skin switches itself off entirely when High Contrast is on.** Canvas throws away the
  whole institutional brand config in that mode by design. Painting over it fights an
  accessibility feature.
- **Never set `font-family` when the dyslexic font is on.** Not setting it at all is the only
  version of this rule that cannot be got wrong.
- **The skin owns the entire `prefers-reduced-motion` block.** Canvas honours it nowhere and
  InstUI honours it nowhere, so every transition you add is new motion and must be guarded.
  Use `0.01ms`, never `none` — Canvas has JS waiting on `transitionend`.
- **Two ink tones on a page, both AA on every ground they touch.** Print the measured ratio
  beside every colour pair on the artboard. A third tone that fails at body size is a landmine
  for whoever edits this in six months.
- **Focus is restated, never removed.** `outline: none` appears nowhere. `#skip_navigation_link`
  is never styled, moved or reordered.
- **Nothing below 13px.** Canvas's 12px meta text is raised, not matched.

**Prepkin**

- Coins pay for **finishing**, never for grades, correct answers, or beating anyone.
- **No meters, no decay, no streaks, no countdowns, no padlocks, no `?` tiles.** Every number
  shown can only go up. Nothing is ever taken away.
- **Accessibility is never behind coins.** Dark mode is free forever. A student who does no
  work does not get a worse Canvas.
- **Urgency is amber and reads "still counts".** Never red, never an alarm, never a
  due-date colour on a Canvas page that means parsing a translated date string.
- **No emoji anywhere.** Every icon is a drawn vector.
- **Zero external network requests.** No web font, no CDN image, no analytics — not even a
  private count of what was removed. This is a district-security-review requirement and it is
  the clearest technical difference from the incumbent.
- **Every visual toggle is reversible and independently safe.** Draw the full toggle matrix,
  not the defaults. Today `dark: true, cards: false` collapses the whole token system.

## Words

Copy on any Canvas page or in the popup is read by a 16-year-old with a bio quiz on Friday.
Plain, warm, no exclamation marks. **No engineering words in student-facing copy.** The house
translations:

| Never write | Write |
|---|---|
| "stet", "fair copy", "revert" | "Put back" |
| "Canvas bug CNVS-21227" | "Canvas shows 0 here even when work is due" |
| "sync", "bridge", "M2", "observer", "selector" | say what the student sees |
| "LTI iframe", "cross-origin" | "your school's page", "another company's page" |
| "overdue", "late", "missing" as a scold | "still counts" |

A student should never read a roadmap and never read an apology.

## Read these files first

- `design/canvas-skin/RESEARCH.md` — 1,157 lines. The complete Canvas page map, per-page
  selector anatomy with confidence labels, the technical floor, an audit of what Prepkin ships
  today, a BetterCanvas teardown, student-voice research, and 22 derived constraints.
  **Read the "Corrections applied" block at the top first — it overturns three conclusions in
  the body.** Read §8 (the 22 constraints) in full. Read §3 for the pages your brief touches.
- `extension/skin.css` — the 27 `--pk-*` tokens and every rule shipping today. 149 lines. The
  eleven shipped bugs listed in `RESEARCH.md` §5.3 all live in this file.
- `extension/looks.js` — the Looks catalog: a palette plus an accessory, earned with coins.
  Six looks today. This is the existing extensibility model, and it has three bugs in it.
- `extension/panel.css`, `extension/popup.html` — the two opt-in surfaces. Panel 360px wide,
  launcher 64px at `right: 18 / bottom: 18`. Popup 340px wide.
- `SPEC.md` — the product and the coin economy.
- `design/CLAUDE-DESIGN-PREAMBLE.md` — the iPhone app's preamble. **Voice only.** None of its
  geometry, components or tokens apply to a Canvas page.
- `design/handoff-kin/README.md` — the level of handoff to match.

## What to return

One screen per handoff, as a `.dc.html` prototype plus a `README.md` in the same shape as
`design/handoff-kin/README.md`:

overview · fidelity · **layout per artboard with px values** · tokens by name, with a measured
contrast ratio printed beside every pair · **the selector each rule rides, with its confidence
label** · every state · every string of copy, verbatim · interactions and motion with durations
and curves · a reduced-motion note · **what each block degrades to when its hook misses** ·
deviations and why.

Claude Code ports it to CSS in `extension/`, and writes `BUILD-NOTES.md` back into the same
folder.
