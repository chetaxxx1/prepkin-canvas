# Handoff: Prepkin Canvas — Learn v2 (micro-lesson reader)

## Overview

Rebuild of the **Learn** tab of Prepkin Canvas, a SwiftUI iPhone companion app for high
school students. Learn today is a flat list of lessons grouped by track, and a lesson is a
white card in a system page-view with a centred paragraph and an emoji. This replaces both
with a micro-lesson reader: short card decks, one accreting figure per lesson, a track map,
a saved-cards review deck, and a single warm "what next" screen after finishing.

14 screens/states are specified here. Format reference was Imprint; the visual system,
tone and rules are Prepkin's own.

## About the design files

The files in this bundle are **design references created in HTML** — prototypes that show
intended look and behaviour. They are not production code to port.

The target is the existing **SwiftUI iPhone app**. Recreate these screens in SwiftUI using
the app's established patterns, its existing colour and type definitions, and its existing
navigation. Every value in this README is given in **points at 390×844 (iPhone 14/15
logical size)** so it maps directly onto SwiftUI layout.

Open `Learn v2.dc.html` in a browser to see all 14 artboards on one canvas. Each artboard
carries a caption explaining what changed from the old screen and why. Artboards are
referenced below by their ids (`1a`, `1b`, …) which are also visible as badges on the
canvas.

## Fidelity

**High fidelity.** Final colours, typography, spacing, radii and copy. Recreate pixel-close
using the codebase's existing components where they exist. The only intentionally loose
items are noted inline as "not final".

---

## Non-negotiable product rules

These are product rules, not styling preferences. Do not let an implementation detail
break one of them.

1. **Coins pay for finishing, never for correctness.** A right answer on the check card
   earns nothing. Completing the lesson pays +20. The check card says so out loud.
2. **No streaks, no deadlines, no resetting counters.** No "1 day to complete", no "0/3
   challenge". Any counter shown must be one that can only go up — "8 lessons this month".
3. **The mascot is a companion, never a meter.** Never sad, starved or punished. Quitting a
   lesson halfway is silent: no confirm dialog, no guilt, position is kept.
4. **No emoji anywhere.** Every icon is a drawn vector. (The old Learn used 💸 🧾 🏛️ 🤔 🧠
   as track icons — those are what this replaces.)
5. **No fake status bar, no fake keyboard.** The artboards deliberately leave the top 46–52pt
   clear for the real status bar.
6. **No padlocks** on the track map. A locked node is a cream circle with a dot.
7. Figures are the only licensed exception to the low-chroma palette (see *Figure system*).

---

## Design tokens

Already present in the codebase; listed for completeness.

| Token | Hex | Use |
|---|---|---|
| bg cream | `#FAF5EC` | every screen background |
| card | `#FFFFFF` | cards, figure card, pill row |
| ink | `#2E2622` | primary text, tab bar capsule |
| warm gray | `#96877F` | secondary text, section labels, inactive glyphs |
| muted | `#B4A996` | tertiary text, chevrons |
| hairline | `#F0E9DC` | borders, progress track, skeleton bars |
| coral action | `#FF6F61` | primary action, current node, active tab |
| coral soft | `#FFE9E5` | reason strip, track pill, heart tile |
| coral deep | `#E4735F` | text on coral soft |
| mint success | `#57C79B` | progress fill, done node, correct answer |
| mint soft | `#DFF3E9` | key-idea panel, correct answer bg, tile bg |
| mint dark | `#3E9E78` | text on mint soft |
| coin | `#FFC24B` | coin glyph, figure fill |
| coin border | `#E8A62E` | coin glyph stroke |
| coin soft | `#FFF3D6` | coin pill bg, tile bg |
| coin dark | `#A8761D` | text on coin soft |
| blush | `#FF9E94` | mascot cheeks (Lv2+) |

Additional values used in the artboards:
`#EFE7D9` unfilled progress segment · `#DDD2C0` locked-node dot / unselected radio ·
`#E0D4C0` dotted map path · `#F5EFE3` neutral track pill bg · `#7C6F68` body text on
white when secondary · `#FFF6EF` text/glyph on coral and on ink.

**Type** — Nunito. Weights used: 700 (body), 800 (labels, titles, buttons), 900 (screen
titles, celebration).

| Role | Size / weight / line-height |
|---|---|
| Screen title | 30–34 / 900 / 1.0, tracking −0.01em |
| Card body (lesson reader) | 19.5 / 700 / 1.5, **left aligned** |
| Key idea sentence | 23 / 800 / 1.4, all caps |
| Check question | 21 / 800 / 1.32 |
| Sheet title | 27 / 900 / 1.14 |
| Card title (list rows) | 16.5–17 / 800 / 1.2 |
| Section label | 11.5 / 800, tracking 0.10em, uppercase, warm gray |
| Card-type label | 12 / 800, tracking 0.14em, uppercase, warm gray |
| Meta / sub | 12.5–13 / 700, warm gray |
| Button label | 17–18 / 800 |

**Radii** — cards 20–22 · hero/sheet 24–28 · buttons 18–22 · tiles 12–15 · pills 999.
**Margins** — 24pt screen margins; 20–22pt gutters where cards run wider.
**Shadows** — used sparingly: `0 3px 12px rgba(46,38,34,.07)` on cards that float over
other content (map lesson card, empty-state demo card). Flat elsewhere.

---

## Mascot ("Kin", the slime)

Finished art. **Reproduce exactly, never redesign.** `Slime.dc.html` is the reference
implementation; port it as a SwiftUI `Shape`/`Path` set or a vector asset.

- Soft dome/bell body, droplet antenna leaning right, two stubby mitten arms, pale oval
  belly patch low on the front. No neck, no legs, no outline, no shading, no texture.
  Flat vector only.
- Palette: body `#51CFA0`, belly `#B1EDD4`, ink `#101820`.
- Geometry (100×100 unit box, viewBox `0 -9 100 109`):
  arms = ellipses at (14,66) and (86,66), rx 11 ry 9, drawn **behind** the body ·
  antenna = `M50 22 C48 12 54 0 62 -1 C67 6.5 60 14 56 22 Z`, drawn behind the body ·
  body = `M50 12 C33 12 22 26 20 46 C18 62 14 74 22 82 C30 90 70 90 78 82 C86 74 82 62 80 46 C78 26 67 12 50 12 Z` ·
  belly = ellipse (50,71) rx 17 ry 12.
- **Nine approved faces, drawn by code, never invented:** idle, deadpan, judging, delight,
  sleep, surprised, sad, focused, wink. Exact paths for each are in `Slime.dc.html`.
- **Levels:** Lv1 small plain · Lv2 bigger + blush ellipses at (26,60)/(74,60) rx 5.5 ry 3.5
  `#FF9E94` @85% · Lv3 biggest + small gold crown `M31 14 L34 5.5 L39 11 L44 3 L49 11 L54 5.5 L57 14 Z`
  fill `#FFC24B`, **no stroke**.
- Faces used in this feature: `idle` (map, what-next, saved empty), `delight` (key idea,
  finish), `wink` (Ask Kin avatar, coach overlay).

---

## Figure system

Lesson figures are the **one licensed exception** to the low-chroma palette, the same way
room scenes are.

- Flat vector on a white card. **2pt ink outline `#2E2822`.**
- **At most three fills per figure**, chosen from: slime `#51CFA0` · sky `#9BC8F2` ·
  lavender `#C3B2F0` · coin `#FFC24B` · coral `#FF6F61` · leaf `#A5CE6B`, over paper `#FAF5EC`.
- No gradients, no drop shadows, no 3D, no photography.
- **One figure per lesson that accretes across the cards.** Build each figure as **named
  layers with a fixed reveal order**. A step only ever *adds*: nothing repositions,
  recolours, resizes or disappears between cards. Implement as a single view with
  per-layer opacity/visibility driven by the card index, not as N separate drawings.

### Compound interest figure — reveal order

Reference implementation: `CompoundFigure.dc.html`, `step` prop 1…5, viewBox `0 0 320 210`.
Fills used: coin, leaf, sky (exactly three).

| Card | Layers added | What appears |
|---|---|---|
| 1 | `stack.base`, `ground.line`, `label.principal` | Three coin discs (ellipses rx 25 ry 8 at cy 172/158/144, cx 55) on a 2pt ground line at y 180; "$1,000" 15/800 above the stack. The figure bare. |
| 2 | `curve.compound`, `chip.year1` | Leaf curve `M80 150 C150 148 205 132 245 100 C270 80 286 62 296 44`, 8pt round cap, grows out of the stack top. "+$80" chip: rounded rect (96,112,58×28,r14) coin fill, 2pt ink stroke. |
| 3 | `chip.year2`, `link.elbow` | "+$86" chip at (172,78,58×28,r14) higher up the curve, joined back to the first chip by a 2pt ink elbow `M154 126 L160 126 L160 92 L172 92`. **This is the state shown in artboard `1d`.** |
| 4 | `line.double`, `tick.nineYears`, `pill.rule72` | Dashed ink horizontal at y 62 (dash 7/5, 55% opacity) = twice the principal; dashed vertical at x 252 where the curve crosses it; "9 years" 12/800 under the axis at y 198; "72 ÷ 8 = 9" pill (24,30,92×26,r13) coin fill. |
| 6 | `curve.late`, `label.startAges` | Second sky curve `M150 178 C200 174 240 162 292 130` starting ten years along and finishing far lower; "start at 18" and "start at 28" labels, 12/800, right aligned. The whole lesson in one picture. |

Cards 5 (example) and 7 (key idea) carry no figure; card 8 is the check.

### Track icons — drawn vectors, 40-unit box, 2.2pt ink stroke

- **Personal finance** — a coin rising off two bars: bar (5,23,8×12,r2.5) coin-soft fill,
  bar (15,17,8×18,r2.5) coin fill, circle (28,13) r8 coin fill, `$` = `M28 8.5v9M25.5 11h5M25.5 14.5h5`.
  *Money that grows, not money you hold — and it shares the coin the app already uses.*
- **Philosophy** — three balanced stones: ellipse (20,31) rx13 ry6 white, ellipse (20,21)
  rx9.5 ry5.5 mint-soft, circle (20,11) r5.5 white.
  *Thinking as careful stacking rather than a borrowed Greek temple.*
- **Study skills** — a dog-eared note card: `M12 5h11l8 8v22a2 2 0 0 1-2 2H12a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2Z`,
  fold `M23 5v8h8`, rules `M15 22h11M15 28h7`.
  *What a student actually makes when a method works; echoes the card format of the reader.*

---

## Navigation chrome

**Floating bottom bar** (settled, already in the app — `TabBar.dc.html` is a reference
redraw). Ink `#2E2622` capsule, inset left/right 22, bottom 26, height 62, radius 999.
Five filled glyphs (23×23) evenly spaced in 46×46 slots; the active slot has a coral
`#FF6F61` rounded square r15 behind it; active glyph `#FFF6EF`, inactive `#8B7F79`.
To the right of the capsule, a 62pt circular mascot avatar button (cream fill, 3pt white
ring, `0 2px 8px rgba(46,38,34,.18)`) that opens Shop. Content fades under the bar with a
cream scrim: 170pt tall gradient, `#FAF5EC` at 42% → transparent.

**The bar hides** on the track map (`1b`) and inside a lesson (`1d`–`1i`).

Tab order: Home · Focus · Games · Learn · Friends. Learn's glyph is an open book
`M2.4 6c3.1-1.4 6.6-1.2 9.6.6 3-1.8 6.5-2 9.6-.6v11.7c-3.1-1.4-6.6-1.2-9.6.6-3-1.8-6.5-2-9.6-.6V6Z`.

---

## Screens

### `1a` Learn (tab root) — replaces the old flat list

**Purpose.** Pick something to read in under five seconds. Content margins 24pt, top
padding 46pt (clear of the status bar), tab bar visible with Learn active.

Vertical order, each section preceded by an 11.5/800 uppercase warm-gray label:

1. **Header** — "Learn" 34/900; under it "8 lessons this month" 13/700 warm gray (the only
   counter, and it only goes up). Right: coin chip — white pill, 1.5pt `#F0E9DC` border,
   r999, padding 7/13/7/9, 19pt coin glyph + "1,130" 15/800.
2. **CONTINUE** — white card r22, padding 14, row: 48pt tile r14 coin-soft with the finance
   icon · title "Why compound interest wins" 16.5/800 · meta "Card 3 of 8 · Personal
   finance" 12.5/700 · 5pt progress bar r999, track `#F0E9DC`, fill mint at 37% ·
   9×15 chevron `#B4A996`.
   **If there is no in-progress deck the whole section is absent** and Because of your week
   moves to the top. Never an empty state.
3. **BECAUSE OF YOUR WEEK** — 1–2 lessons chosen from the student's real Canvas
   assignments. This is why the tab lives inside this app. White card r22 padding 14:
   a coral-soft reason strip (r999, padding 5/11, 12pt coral dot + "Bio quiz · Friday"
   11.5/800 coral deep), then "How to study for a science quiz" 17/800, then "4 cards ·
   2 min · +20" 12.5/700; right, a 44pt coral circle with a white arrow.
   **If Canvas is not connected the section is absent** — never an empty state.
4. **TODAY'S CARD** — white card r22 padding 14: 48pt mint-soft tile with the study-skills
   icon · "Spaced practice beats cramming" 16.5/800 · "3 cards · 2 min" · coin-soft pill
   "+20" 13/800 coin dark.
5. **TRACKS** — horizontal shelf, 150pt cards r20 padding 13, 12pt gap, third card peeking.
   Each: 30pt drawn icon; row with the track name 14.5/800 (two lines) and a 28pt progress
   ring (track `#F0E9DC` 4pt, fill mint 4pt round cap, rotated −90°); then "3 of 8" 12/800
   warm gray. Current tracks: Personal finance 3 of 8, Philosophy 2 of 8, Study skills 1 of 6.
6. **Saved cards** — compact row, white r18 padding 11/13: 36pt coral-soft tile with a
   filled coral heart · "Saved cards" 15.5/800 · "12" 13/800 warm gray · chevron.

Tapping a lesson row opens the **preview sheet** (`1c`); tapping a track card pushes the
**track map** (`1b`); Saved cards pushes `1k`/`1l`.

### `1b` Track map — new, pushed, tab bar hidden

**Purpose.** See the shape of a track and where you are in it.

Header at y 52: 40pt white circle back button · centred "Personal finance" 18/800 · coin
chip. "3 of 8 done" 13/700 warm gray centred at y 100. Map area starts at y 140, 700pt tall.

Vertical path, nodes alternating left and right, **no unit headers** — a track is one run.
Node centres (x, y within the map area): (105,40) done · (262,118) done · (112,208) current ·
(270,358) · (112,440) · (262,520) · (118,596) locked · (268,652) badge.

- **Connector** — completed run: mint 5pt solid
  `M105 40 C150 70 230 78 262 118 C240 165 160 168 112 208`. Remainder: `#E0D4C0` 5pt,
  dash `2 14`, round cap (reads as dots).
- **Done** — 60pt mint circle, 26pt white check.
- **Current** — 76pt coral circle, `0 0 0 7px #FFE9E5` ring, white play triangle. The slime
  (58pt, idle, Lv3) sits beside it at (168,186), and a floating card sits under it:
  306pt wide, white r20, padding 13/14, shadow `0 3px 12px rgba(46,38,34,.07)`, title
  15/800 + "Card 3 of 8 · 3 min" 12/700, coral "Resume" pill 13.5/800.
- **Locked** — 60pt white circle, 2pt `#F0E9DC` border, 11pt `#DDD2C0` dot. **No padlocks.**
- **End** — 76pt coin-soft circle with a 3pt dashed `#E8A62E` border and the track icon at
  45% opacity, plus "Track badge" 12/800 coin dark. Fills solid once earned.

### `1c` Lesson preview sheet — new

**Purpose.** Know the size of the commitment before committing.

Presented over the dimmed Learn root: scrim `rgba(46,38,34,.42)`. Sheet from y 118 to the
bottom, white, radius 28 top corners, 24pt side padding. 44×5 `#F0E9DC` grabber at y 12;
36pt cream close circle at top-right (right 20, y 24).

Content: cover panel 178pt tall, cream r20, padding 16/14, holding the figure at reveal
step 5 · coral-soft track pill "Personal finance" 12/800 · title 27/900 · "What you'll
learn" 13.5/800 · three lines of body 15/700/1.5 in `#7C6F68` · meta row "3 min · 8 cards ·
+20 coins" 13.5/800 warm gray with the coin glyph before the coins · **Start** button
pinned at bottom 36: full width, 58pt, r22, coral, "Start" 18/800 `#FFF6EF`. No secondary
action competes with it.

### `1d`–`1g` Lesson card — the four card types

Shared chrome on all four, tab bar hidden:

- **Top bar** at y 52: 40pt white circle with a 14pt ink ✕ (left), then a **segmented
  progress bar** — 8 equal segments, 5pt tall, r999, 4pt gaps, filled mint / unfilled
  `#EFE7D9`. **No title.**
- **Bottom bar** at bottom 34: a white pill (flex 1, 52pt, r999) holding save ♡ / share /
  flag at 22pt with 26pt gaps, `#96877F` 2pt strokes (heart fills coral when saved); to its
  right the **Ask Kin** button — 52pt coral pill, r999, padding 0/18/0/7, containing a 38pt
  cream circle with the slime (wink) and "Ask Kin" 15/800 `#FFF6EF`. Ask Kin carries the
  mascot, never a generic sparkle.
- **Body copy** is always **left aligned, 19.5/700/1.5, 2–4 short lines**, left inset 24,
  right inset 26. Never centred.
- **Tap zones**: left 130pt = back, remainder = forward. Leaving mid-lesson is silent and
  the position is kept.

**`1d` figure card** (card 3 of 8, reveal step 3 of 5) — figure card at y 116, inset 20,
**404pt tall** (≈ half the screen), white r22, padding 24/20, figure centred inside at 230pt
tall. Copy: "$1,000 at 8% a year. Year 1 you earn $80. Year 2 you earn $86 — because now the
$80 is earning too."

**`1e` key idea card** (card 7 of 8) — no figure. "KEY IDEA" label at y 150. Mint-soft panel,
inset 20, y 190, r26, padding 32/26/36, sentence 23/800/1.4 all caps: "STARTING AT 18
INSTEAD OF 28 CAN ROUGHLY DOUBLE WHAT YOU END UP WITH. TIME MATTERS MORE THAN AMOUNT."
The slime (132pt, delight, Lv3) leans in from the left edge at (−30, 556) — deliberately
cropped by the screen edge — with a small white speech chip "Screenshot this one." 13.5/800
at (118,600), radius `18 18 18 6`. Heart in the bottom bar shown already filled. This is the
card people screenshot.

**`1f` example card** (card 5 of 8) — "FOR EXAMPLE" label at y 150. One small drawn spot,
not a full figure: white card (24,196,210×150) r20 holding two coin stacks on a ground line —
five coin discs at cx 52 vs two sky discs at cx 130, labelled "from 18" / "from 28" 14/800.
Copy at y 380: "Two students both put away $200 a month. One starts at 18, the other at 28.
By 60 the early one ends up with roughly twice as much."

**`1g` check card** (card 8 of 8, answered state) — "QUICK CHECK" label at y 150, question
21/800 at y 186. Three answer rows, inset 20, y 280, 10pt gaps, r18, padding 15/16, each with
a 22pt leading indicator:
- unpicked: white, 1.5pt `#F0E9DC` border, 2pt `#DDD2C0` ring, text 15.5/700 `#7C6F68`
- the answer you picked (wrong): identical, plus "you picked" 11.5/800 `#B4A996` right aligned
- correct answer: mint-soft fill, 2pt mint border, mint indicator circle with a white check,
  text 15.5/800 ink
Then an explanation card (inset 20, y 520, white r20 padding 18): reason 16/700/1.5, and
under it "No coins for this one. Finishing the lesson pays." 12.5/800 warm gray.
**Never a red X, never a wrong buzzer, no score.** A wrong pick quietly shows the right one
and why. Getting it right earns nothing.

### `1h` Tap-zone coach overlay — first lesson only

Drawn over card 1. Scrim `rgba(46,38,34,.66)`. Two dashed zone outlines, 2pt
`rgba(255,246,239,.34)` r22: left (14 → 130) and right (146 → −14), y 126 to bottom 250.
A 2pt mint vertical divider at x 137 (y 150 → bottom 274). "tap here / to go back" 15/800
centred in the left zone; "tap here / to go forward" 21/800 in the right. At bottom 118, the
slime (78pt, wink, Lv3) beside "Leave whenever you like — I'll keep your place." 15/800
`#FFF6EF`. One coral "Got it" button, bottom 38, 56pt, r22. Shown once, ever.

### `1i` Finish card

Full progress (8/8 mint). Coin chip at (right 22, y 108). Five coin discs arc from the slime
up into the chip — radii 17→9, opacity 1 → 0.35 — so the eye lands on the chip. Slime 200pt,
delight, Lv3 at (95,326). "That's the lesson." 27/900 centred at y 566; "Why compound
interest wins · 8 cards" 13.5/700 warm gray at y 606 (the title is a footnote here).
Bottom 38: 60pt coral button r22, "Finish · ⬤ +20 coins" 18/800 with the coin glyph inline.
Coins are awarded here, for finishing.

### `1j` Lesson complete → what next — new, invented

**Purpose.** Replace "dumped back to the course map" with one warm screen and exactly one
forward move.

Close ✕ top-left, coin chip top-right showing the **new** balance (1,150). Slime 150pt,
idle, Lv3 at (120,150). One line of what you learned, 24/800/1.34 centred at y 326: "You
learned why time matters more than amount." Coin-soft pill centred at y 436: "+20 coins for
finishing" 14.5/800 coin dark. Then one card (inset 22, bottom 120, white r24 padding 20):
"NEXT IN PERSONAL FINANCE" 11.5/800 label · "Your first budget in 4 lines" 19/800 · "4 cards
· 2 min · +20" 13/700 · full-width coral "Start" button 54pt r20. Below it, one quiet
"Not now" 14.5/800 warm gray at bottom 56.

**One choice, not a menu.** When the lesson was picked *for* a Canvas assignment, the card
becomes the other single move — "Focus 15 min on Bio quiz, due Friday" — same shape, same
one button, routing into the Focus tab.

### `1k` Saved cards — filled

Back button y 52, "Saved cards" 30/900 at y 112, "12 cards you kept" 13/700 at y 150. Tab
bar visible. List inset 20 from y 196, 12pt gaps. **Each saved card keeps the shape of the
card it came from** so the deck reads as your own highlights:
- ordinary card: white r20 padding 16, a small uppercase track pill (r999, padding 4/10,
  10.5/800 — coin-soft/coin-dark for finance, mint-soft/mint-dark for study skills,
  `#F5EFE3`/warm gray for philosophy) with a filled 20pt coral heart opposite, then the
  card's line 16/700/1.45.
- key-idea card: mint-soft r20, "KEY IDEA" 10.5/800 tracking 0.14em mint dark, sentence
  15.5/800 all caps.
No sort control; newest first.

### `1l` Saved cards — empty

Same header, sub-line "Nothing kept yet". Teaches the gesture by showing it, not by
describing it: a mock card (66,236,258 wide, white r20 padding 18, shadow
`0 4px 16px rgba(46,38,34,.08)`) with three `#F0E9DC` skeleton bars and a 26pt filled coral
heart at its bottom-right, wrapped in two tap-ripple rings (2pt coral at 45% and 20%).
The slime (104pt, idle, Lv3) sits at (22,352), overlapping the card's corner. Copy centred:
"Tap the heart on a card you want to keep." 21/800 at y 494, then "They land here, and Kin
will bring one back to you now and then." 15/700 warm gray at y 568.

### `1m` Figure accretion — interactive reference

Not a screen to build: a live version of `1d` where the right two-thirds advances the reveal
step and the left third goes back, 1 → 5. Use it to check the accretion is additive before
you commit the figure code.

### `1n` Spec panel

The reveal order and track icons, on canvas, in the same words as this README.

---

## Interactions & behaviour

- **Lesson reader** — tap right two-thirds forward, left third back; no swipe required
  (support swipe as well if the codebase already does). Card transitions: cross-fade
  180–220ms ease-out; figure layers fade+rise 8pt over 260ms ease-out as they are added.
  Nothing else in the figure moves.
- **Close ✕** — dismisses immediately, no confirm dialog, no guilt copy. Deck position is
  persisted and surfaces again in Continue on `1a`.
- **Save ♡** — fills coral with a small scale bounce (1.0 → 1.15 → 1.0, 240ms). Adds to
  Saved cards. No toast.
- **Check card** — tapping a choice locks all three, reveals the correct row in mint and the
  explanation below with a 200ms fade. No coins, no score, no retry pressure. Tapping
  forward continues as normal.
- **Finish** — button press awards +20; coins animate along the arc into the coin chip
  (staggered 60ms, 420ms each, ease-in-out), chip value counts up, then push `1j`.
- **Coach overlay** — appears once on the first lesson ever opened, dismissed by "Got it";
  persist the flag.
- **Press states** — coral buttons darken to `#E4735F`; white cards drop to 97% scale with
  no colour change; tab bar items have no press state beyond the coral pad.
- **Tab bar** — hides on `1b` and `1d`–`1i` (slide down 180ms).

## State

- `deckProgress[lessonId] → cardIndex` — drives Continue, the map's current node, and
  resuming. Written on every card advance.
- `revealStep` — derived from `cardIndex` via the lesson's figure map; never stored
  separately.
- `answeredChoice[cardId]` — nil until answered, then the picked index. Locks the row set.
- `savedCards: [CardRef]` — hearted cards, newest first, with the card's type so `1k` can
  render it in its original shape.
- `coins` — incremented **only** by lesson completion (+20) and other finishing events.
- `lessonsThisMonth` — monotonic counter for the header line.
- `hasSeenTapCoach: Bool`.
- `canvasConnected: Bool` — when false, "Because of your week" is not rendered at all.
- Data needed: lesson catalogue (track, title, card list, card types, figure id, coin
  value), Canvas assignment sync (title, course, due date) for the picked lessons.

## Assets

- **Mascot** — reproduce from `Slime.dc.html` (paths above). Existing app art is
  authoritative if it differs.
- **Icons** — all drawn vectors, all specified above: three track icons, five tab glyphs,
  chevron, close ✕, check, heart, share, flag, arrow, play, coin. No emoji, no icon font.
- **Figures** — one per lesson, authored as named layers. Only the compound-interest figure
  is drawn here (`CompoundFigure.dc.html`); the rest of the catalogue needs the same
  treatment before those lessons ship.
- No photography, no raster assets.

## Files in this bundle

| File | What it is |
|---|---|
| `Learn v2.dc.html` | All 14 artboards on one canvas, with per-screen captions. Open this first. |
| `CompoundFigure.dc.html` | The accreting figure, `step` 1–5. |
| `Slime.dc.html` | The mascot: geometry, nine faces, three levels. |
| `TabBar.dc.html` | Floating bottom bar reference redraw. |
| `support.js` | Runtime needed to open the HTML files locally. Not part of the design. |

## Open questions for the designer

1. Track-map connector geometry is hand-tuned for 8 nodes; a 6- or 10-node track needs a
   generated path. Not final.
2. Example-card copy on `1f` and the "Screenshot this one." chip on `1e` are written here,
   not from the catalogue — confirm before shipping.
3. Only one lesson's figure exists. Every other lesson needs a layered figure with a stated
   reveal order before its deck can ship.
