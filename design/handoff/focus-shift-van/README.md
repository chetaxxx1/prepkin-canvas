# Handoff: Focus Shift — Delivery Van (Kin drives)

## Overview
The Focus session ("shift") screen for Prepkin Canvas. When a student starts a focus session, the mascot Kin clocks into a job and works for the duration. The chosen job: **Kin drives a delivery van**. The screen shows a continuous driving loop inside a circular scene, the session timer, a secondary "miles driven" count, and Pause / Clock out early controls. Kin earns coins as wages per minute worked; clocking out early still pays for time completed.

## About the Design Files
`focus-shift-van.html` is a **design reference created in HTML** — a prototype showing intended look and behavior, not production code. The task is to **recreate this design in the target codebase** (`prepkin-canvas/ios`, SwiftUI) using its established patterns. The vehicle/scene shapes are placeholder geometry; final illustrated assets may replace them, but layout, palette, and animation timing below are the spec.

## Fidelity
**High-fidelity** for layout, palette, typography scale, spacing, and animation choreography. **Placeholder** for illustration: the van, wheels, and scenery are simple shapes standing in for final art. Kin's SVG body/face paths are final (they match the mascot used across the app; Swift path data can be regenerated via `design/slime-trace/emit_swift.py` in the repo).

## Screen: Focus Running (390×844, iPhone)
White background (#FFFFFF) top to bottom. Vertical flex, centered.

1. **Status bar** — 9:41 + battery glyphs, #33291F at 50% opacity, 12.5px/800, padding 14px 26px 0.
2. **Mode row** — padding 16px 22px 0, space-between:
   - Segmented pill (left): container #F4F1EA, radius 999, padding 5px. Active segment "Strict": white bg, shadow 0 1px 2px rgba(20,14,8,.12), 12px/900 #33291F, padding 7px 13px. Inactive "Sound off": 12px/800 #8A7A66.
   - Best-shift pill (right): #F4F1EA, radius 999, padding 7px 12px; 15px parcel icon (amber box #C08F42 with cream #FFF9EC tape stripe), "11" 12.5px/900 #33291F, "best shift" 11px/800 #8A7A66.
3. **Heading** — margin-top 30, centered: "Kin is on shift" 27px/900 #33291F, letter-spacing −0.8; subtitle "Put the phone down and let him work" 14.5px/800 #5E5142, margin-top 7.
4. **Scene circle** — margin-top 28, 250×250, radius 50%, bg #F6EEDC, inner shadow inset 0 −14px 30px rgba(120,92,50,.10), overflow hidden. Contents (positions relative to circle, y from bottom):
   - Ground band: full width, bottom 0, height 42, #F1E6CC.
   - Cloud: 44×13 white pill at top 52, 90% opacity, drifting right→left (9s linear loop, translateX 160 → −230).
   - Bush: 38×17 half-round #3AA678 sitting on ground (bottom 42), drifting right→left (4.5s linear loop, same travel).
   - Road dashes: 5px-tall strip at bottom 36, overflow hidden; 26×5 rounded dashes #D8C6A2, 18px gaps, scrolling left 44px per 0.55s (linear loop).
   - **Van group** at left 44, bottom 44, 172×110, bobbing (1.1s ease-in-out loop, translateY 0 → −3 → 0):
     - Cargo box: 104×62 at left 0, bottom 16, #DE9A22, radius 10/4/4/8; cream label plate 52×22 (#FFF9EC, radius 5) centered-ish (left 16, top 16) reading "KIN CO" 10px/900 #DE9A22, letter-spacing .5.
     - Cab: 58×46 at left 102, bottom 16, #DE9A22, radius 4/18/6/6 (rounded nose).
     - Window: 30×23 at left 110, bottom 36, #FFF9EC, radius 4/10/2/2, overflow hidden. Kin's face crops into it: mascot SVG at 54px wide, offset margin −9px 0 0 −7px so the eyes+smile center in the glass.
     - Wheels ×2: 30px circles #33291F at left 26 and left 122, bottom −8; hub 11px #8A7A66 with a 3×7 spoke notch; spinning 360°/0.8s linear.
     - **Parcel toss** (once per 6s cycle): 17px amber box #C08F42 with cream tape stripe, origin at the back of the box (left −4, bottom 64). Timeline: hidden 0–70% → pops up-back (translate −10,−18, rotate −24°) at 74% → lands on road (translate −44,+26, rotate −100°) at 86% → fades out by 92%. Ease-in-out.
   - Task pill (overlaps circle bottom edge, centered, bottom −6): white, radius 999, padding 8px 15px, shadow 0 3px 10px rgba(20,14,8,.13); 7px amber dot #DE9A22, task name 12.5px/900 #33291F, course code 11.5px/800 #8A7A66. Content comes from the paired Canvas task (e.g. "Essay outline" / "ENGL 210").
5. **Timer** — margin-top 36, centered: remaining time 66px/900 #33291F, letter-spacing −3.2, tabular numerals.
6. **Progress bar** — 250×9, radius 999, track #EAE5DA, margin-top 16. Fill #DE9A22 from left (fraction elapsed). Thumb: 17px white circle, shadow 0 2px 6px rgba(20,14,8,.2), amber 7px dot, centered on fill edge. Optional milestone tick: 2×21 #8A7A66 at 50% opacity (e.g. break marker).
7. **Count block** — margin-top 28, centered: "4" 34px/900 #33291F (letter-spacing −1.4) + "miles driven" 14.5px/800 #5E5142; below, "NEXT IN 1:24 · BEST SHIFT 11" 11.5px/800 #8A7A66, letter-spacing .3, uppercase.
8. **Buttons** — pinned to bottom, padding 0 22px 26px, 9px gap:
   - Pause: full-width, 56px, radius 18, #33291F bg, #FFF7EA text 16px/900.
   - Clock out early: full-width, 44px, transparent, #8A7A66 text 14.5px/800.

## Interactions & Behavior
- **Driving loop**: environment moves, Kin holds one pose. All animations loop forever; the scene is identical at minute 2 and minute 48 (by design — nothing accumulates).
- **Miles**: +1 mile every 90 seconds. The count block updates with no animation beyond a numeral swap (optionally a quick scale pop, 150ms).
- **Parcel toss**: purely decorative flavor on a 6s cycle; not tied to the count.
- **Pause**: freezes all scene animation (wheels, dashes, scenery, bob) and the timer; button becomes "Resume".
- **Clock out early**: opens the quit sheet (designed separately in the canvas, turn "quit sheet"): confirms, pays wages for completed minutes.
- **Session end**: transitions to the finish report screen (coins earned = minutes × rate; proposed economy 10/20/30 coins for 25/50/full-length sessions — pending confirmation).
- **Strict / Sound off** toggles: pre-session settings, disabled (display-only) while running.
- Lock screen: a Live Activity mirrors timer + miles (separate design, same tokens).

## State Management
- `sessionDuration`, `elapsed` (drives timer, progress fill, miles = floor(elapsed/90s), "next in" countdown = 90s − elapsed % 90s).
- `isPaused` (freezes clock + animations).
- `bestShift` (persisted max miles in one session).
- `pairedTask` {title, courseCode} from Canvas LMS pairing.
- Coin wage accrual: minutes completed × rate; settle on clock-out.

## Design Tokens
Colors: ink #33291F · secondary text #5E5142 · muted #8A7A66 · card/pill bg #F4F1EA · scene circle #F6EEDC · ground #F1E6CC · road dash / tray #D8C6A2 · amber accent / van #DE9A22 · parcel #C08F42 · cream #FFF9EC · button text #FFF7EA · bush #3AA678 · red (car alt / stamp) #E2574C · Kin body #51CFA0 · Kin belly #B1EDD4 · Kin face #101820.
Type: Nunito (600–900). Scale: 66 timer / 34 count / 27 heading / 16 button / 14.5 subtitle / 12.5 pills / 11.5 caption.
Radii: 999 pills · 18 primary button · 10–16 vehicle shapes. Spacing rhythm: 28/30/36 between major blocks; 22px screen gutters.
Animation: bob 1.1s ease-in-out · wheels 0.8s linear · dashes 0.55s linear · bush 4.5s linear · cloud 9s linear · parcel cycle 6s ease-in-out.

## Assets
- Kin mascot vector paths: inlined in the HTML reference; canonical source `design/slime-trace/slime.svg` and `design/canvas/mascot-paths.json` in the repo (`emit_swift.py` generates Swift `Path` code). Face variants (idle/deadpan/judging/delight) exist in the same SVG.
- Van, wheels, scenery: placeholder shapes drawn in code — no external assets. Final illustrated van to be commissioned; keep the window crop for Kin's face.
- Parcel icon (best-shift pill) drawn in code.

## Files
- `focus-shift-van.html` — self-contained 26b design reference with live animations (open in any browser).
- Source exploration: `Prepkin Canvas.dc.html` in the design project (turn 26, option 26b; turns 22–25 document rejected directions: barista, stamping, orchard).

---

## Built — 2026-08-30

Shipped as `ios/Sources/FocusView.swift` (running screen) + `ios/Sources/ShiftSceneView.swift` (the van scene). `bestShift` added to `GameState`. All 70 unit tests pass.

Five deliberate deviations, each marked in the code:

1. **Palette mapped to the app, not the handoff.** Layout, spacing and timing are followed exactly, but the near-black button became `Theme.coral` and the amber fill became `Theme.coin`, so Focus matches every other tab. The van keeps its amber — `Theme.coinBorder` (#E8A62E) is a hair off the handoff's #DE9A22 and reads the same. The cream scene colours are illustration-only and live in `ShiftScene`, not `Theme`.
2. **No Strict / Sound off segment.** Neither setting exists in the app, and the handoff makes both display-only during a shift. The row carries the live best-shift chip alone rather than two dead controls.
3. **No quit sheet.** Clock-out uses a native confirmation dialog until that frame is designed. It asks the same question and states the pay.
4. **No milestone tick on the progress bar.** There are no breaks inside a shift yet.
5. **Task pill strings are cut to length.** Real Canvas course names are sentences ("Thayer Welcome and Orientation"), so the pill shows the course *code* only when the sync gives a short one, and the title is clipped at 22 characters. Keeps the pill hugging its content the way the frame draws it.

Economy unchanged: 1 coin a minute, as the app already paid. The handoff's proposed 10/20/30 flat rates are marked "pending confirmation" there and were not applied. Clocking out early now pays for minutes worked — previously it paid nothing.

The scene is scaled as a whole below 844pt so it degrades on an iPhone SE instead of clipping. Session end still returns to the ready screen; the finish report screen the handoff mentions does not exist yet, and neither does the Live Activity.
