# Handoff: Prepkin Canvas — Home (+ Focus, Shop, chibi system)

## Overview
Prepkin Canvas is an iOS companion app for high school students: real assignments flow in from Canvas LMS, and completing daily tasks (school work + life care) earns coins. Coins upgrade a slime chibi companion (3 levels per species) and buy new species and home-scene backgrounds in a Shop. This handoff covers the settled Home direction (turn 4 of the design file), plus earlier reference screens for Focus, Shop, and the chibi animation/level system.

## About the Design Files
`Prepkin Canvas.dc.html` is a **design reference created in HTML** — a prototype showing intended look and behavior, not production code. Recreate these designs in the target codebase (`prepkin-canvas`) using its existing environment and patterns; if the app environment isn't established yet, SwiftUI is the natural choice for an iPhone-only companion app. Do not ship the HTML.

The file is a design canvas of numbered options, newest at top. **Authoritative direction: option 4a** (Home). Options 1b (Focus), 1c (Shop), 3b (Shop "Scenes" section), 1d (chibi poses/levels), and 4b (mascot palette test) are supporting references. Turn 2 and options 3a and 1a are superseded iterations of Home — ignore their layouts, but 2a/3a demonstrate the same live task-completion behavior.

## Fidelity
**High-fidelity** for layout, color, type scale, spacing, and interaction behavior. **The chibi artwork is a placeholder**: a code-drawn SVG blob designed to be swapped for real character art later — treat its size, position, and animation timings as spec, not its drawing.

## Product rules (never break)
- Coins pay for FINISHING things, never for grades or correct answers.
- The chibi is a companion, not a meter: never sad, starved, or punished. Ending a focus session early just means no coins — no guilt screen.
- 6 tabs: Home, Focus, Games, Learn, Friends, Shop.
- iPhone target 390×844 pt. No custom status bar or keyboard — use system chrome.

## Screens / Views

### Home (option 4a — authoritative)
Purpose: see the buddy, see today's tasks, complete them.
Layout, top to bottom (390×844):
1. **Scene layer** (full-width, ~316pt tall incl. header): background is the equipped, purchasable scene. Default "linen": `linear-gradient(180deg,#F4EEE3 0%,#F1EADC 68%,#EAE1CE 68%,#EFE7D6 100%)` (the 68% hard stop is the ground line). Scenes must stay low-chroma so any mascot color pops.
   - Header row (padding 24pt sides, 24pt top, space-between): left pill — white bg, radius 999, padding 7×14, shadow `0 2px 8px rgba(46,40,34,.08)`, contents "Pip" (14pt/900 ink) + level chip "Lv 2" (11.5pt/900 #57C79B on #E3F6EE, radius 999, padding 2×8). Right pill — same white pill style, coin disc (18pt circle, #FFC24B fill, 2.5pt #E8A62E border) + balance (15pt/900 ink).
   - Chibi block (height 246pt, content bottom-aligned, 18pt bottom padding): chibi ~182×158pt centered; ground shadow ellipse 150×16pt `rgba(46,40,34,.1)` overlapping chibi bottom by 6pt.
   - **Speech bubble**: white, radius 16, padding 9×16, shadow `0 3px 10px rgba(46,40,34,.12)`, 14pt/700 ink, centered ~12pt from scene top. Shows on screen entry, **auto-hides after 3.5s**; reappears for ~2.2s on each task completion. Copy: "Pip is cheering you on — {n} to go!" / "Yay! Nice work!" (during celebrate) / "All done today! Pip is so proud."
2. **Today header** (padding 16 top, 24 sides): "Today" 18pt/900 ink, right-aligned "{done} of {total} done" 13pt/700 warm gray.
3. **Task list** (padding 0 20, 8pt gap). Row card: white, radius 20, padding 12×16, shadow `0 2px 8px rgba(46,40,34,.05)`, flex row gap 12, min height ≥44pt tap target; whole row is the tap target.
   - Left **category tile** 40×40, radius 14: school = book icon #FF8A7E on #FFE9E5; life care = heart icon #57C79B on #E3F6EE.
   - Middle: title 15pt/800 ink (line-through when done); meta line = mini coin disc (11pt) + "+{reward}" 12pt/800 #B07A1A + "· {course · due · from Canvas}" 12pt/700 warm gray, single line, ellipsized.
   - Right **checkbox** 30pt circle: undone = 2.5pt #E5DDD0 border on #FCFAF5; done = #57C79B fill, white 2.6pt check, shadow `0 2px 6px rgba(87,199,155,.4)`.
   - Done rows: 65% opacity.
4. **Tab bar**: white, top border 1pt #F0E9DC, padding 10 8 24, six evenly spaced items 56pt wide. Filled icons 23pt: inactive #C9BEAC icon + #B4A996 10pt/800 label; active tab gets a pill (radius 16, `rgba(255,111,97,.12)`, padding 6×0) with #FF6F61 icon + label. Icon set: house, clock, gamepad, book, people, tote bag (filled, rounded).

Interaction — completing a task:
- Tap row → checkbox fills, row fades to 65% + line-through, coin balance increments by reward, a "+{n}" floats up from the coin pill (1.6s: fade in 20%, rise 24pt, fade out), chibi switches to **celebrate** for 2.2s (bounce + two confetti squares #FFC24B 12pt and #FF6F61 10pt pulsing beside it, happy closed-arc eyes + open mouth), bubble shows "Yay! Nice work!". Then back to idle.
- Tap a done row → un-completes: reward subtracted, no celebration, no penalty animation.

### Focus (option 1b — reference)
Two states (ready / running). Header "Focus" 25pt/900 + coin pill. "WORKING ON" label 13pt/800 warm gray; selected task card (white, radius 18) with "Change" link (coral, ready state only). Center: 264pt ring — white disc, 10pt track #F0E9DC; running state adds coral progress arc (round caps) and timer counts down. Timer 58pt/900 tabular-nums ink; under it mini coin disc + "+25 when you finish" 14pt/800 warm gray. Chibi below ring: ready = idle + caption "Pip will nap next to you while you work"; running = sleeping (closed-arc eyes, floating "z z") + "Pip is napping. You've got this." CTA: ready = full-width coral button "Start focus" (radius 22, padding 17, shadow `0 6px 16px rgba(255,111,97,.35)`); running = quiet outline button "End early" (white, 2pt #F0E9DC border, warm-gray text) + caption "Ending early just means no coins this time. Pip won't mind." — never a confirm/guilt dialog.

### Shop (options 1c + 3b — reference)
Header "Shop" + coin pill. "Your buddy" card: chibi at current level, "Pip · Level 2" 17pt/900, subline "Level 3 adds a tiny crown", coral Upgrade button with inline coin disc + price. "New buddies" 2-col grid (12pt gap): white cards radius 22, chibi ~78pt, name 15pt/900, price chip (coin disc + amount on #FFF3D6). Locked/unknown species: desaturated silhouette, "???", "Coming soon". **Scenes section (3b)**: same 2-col grid; each card = 74pt-tall rounded preview of the scene gradient + name + price chip; owned scene shows "Owned" and an "Equipped" badge (#2E8C68 on #E3F6EE). Footer note: "Coins come from finishing tasks and focus sessions."
Update from turn 4: use the filled-icon tab bar and neutral-scene rules on this screen too.

### Chibi system (option 1d — reference)
5 preset animations (all gentle, loops):
- **idle**: squish — scaleY 1→.94 / scaleX 1→1.04, 3s ease-in-out, transform-origin bottom center.
- **bounce**: squash then hop — 30% scaleY .9, 60% translateY −16pt scaleY 1.05, 1.4s.
- **celebrate**: bounce at 1s + confetti squares pulsing (scale .7→1.15, opacity .3→1, rotated 45°) + happy eyes (upward arcs) + open oval mouth.
- **wave**: side arm nub rotating 0→−38° 1.2s from shoulder.
- **sleep**: slow squish 4.5s, closed-arc eyes, small mouth, "z" glyphs floating up (rise 14pt, fade, 2.4s staggered).
Levels are visual evolutions of one species: **Lv1** small (~64pt) plain; **Lv2** ~118pt + pink blush ellipses (#FF9E94 at 70%); **Lv3** ~132pt + gold crown (#FFC24B, #E8A62E stroke). Species colors (flat body + white specular ellipse at 45%): Pip mint #7DD8B4, Mochi pink #F7A8B8, Puff sky #9BC8F2, Wisp lavender #C3B2F0, Sprout #A5CE6B (leaf sprig).

## State Management
- `coinBalance: Int` — global; increments on completion, decrements on un-complete.
- `tasks: [Task]` — `{id, title, courseOrCategory, due?, source(.canvas|.lifeCare), reward: Int, done: Bool}`; Canvas tasks sync from the Canvas LMS API, life-care tasks are local.
- `chibi: {speciesId, level(1...3), scene}` — scene is the equipped purchasable background.
- Transient UI: `celebrating: Bool` (2.2s), `coinGain: Int?` (1.6s), `bubbleVisible: Bool` (3.5s on entry; retriggered on completion).
- Focus: `selectedTask`, `remaining: TimeInterval`, `running: Bool`. Early end awards nothing and shows no negative feedback.

## Coin economy (proposed, tune freely)
Life-care task +5 · assignment +15 · big deliverable or completed 25-min focus session +25. Upgrades: Lv2 = 150, Lv3 = 300. New species 450–900. Scenes 200–250. A steady day earns ~60–90.

## Design Tokens
Colors: bg cream `#FAF5EC`; card `#FFFFFF`; ink `#2E2822`; warm gray text `#988D80`; muted gray `#B4A996`; inactive icon `#C9BEAC`; hairline `#F0E9DC`; checkbox border `#E5DDD0`; coral action `#FF6F61` (soft `#FFE9E5`, icon `#FF8A7E`); mint success `#57C79B` (soft `#E3F6EE`, dark text `#2E8C68`); coin yellow `#FFC24B` (border `#E8A62E`, soft `#FFF3D6`, dark text `#B07A1A`); blush `#FF9E94`.
Scene gradients: linen (default, above); meadow `#DDF2E6→#EAF7F0 58%, #CBE9D6 58%→#D8EEDF`; night `#2E3550→#4A5378 62%, #3A4260 62%→#454E70`; sunset `#FFE3CE→#FFD9C4 55%, #F3C4A8 55%→#F8CDB2`; lakeside `#D9EFF7→#E8F6FA 58%, #C8E6F0 58%→#D5ECF4`.
Type: Nunito (rounded, friendly) — weights 700/800/900. Scale: 25 page title / 18 section / 15 row title / 13–14 secondary / 12 meta / 10 tab label; timer 58 tabular. On iOS, SF Rounded is an acceptable native substitute.
Radii: cards 20–22, hero cards 24–28, buttons 18–22, tiles 14, pills/chips 999. Shadows: card `0 2px 8px rgba(46,40,34,.05)`; floating `0 3px 10px rgba(46,40,34,.12)`; coral CTA `0 6px 16px rgba(255,111,97,.35)`.
Spacing: 24pt screen margins (20pt for list gutters), 8–10pt list gaps, 12pt in-row gaps.

## Assets
None external. Chibi, icons, and confetti are all code-drawn placeholders in the HTML; real chibi art (5 poses × 3 levels × species) is expected to replace the SVG blob. Coin is a pure-CSS disc.

## Files
- `Prepkin Canvas.dc.html` — the design canvas (open in a browser; options badged 1a…4b, newest turn at top; 4a and 2a/3a are interactive).
