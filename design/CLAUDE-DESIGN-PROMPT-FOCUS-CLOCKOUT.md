# Prompt for Claude Design — Focus: clock-out sheet, shift report, pre-shift settings

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the line.
Attach `design/screenshots/02-focus-ready.png` (old, slime), `18-focus-shift.png` and
`19-focus-clockout-dialog.png` (today, Sprout), and the original shift handoff
`design/handoff/focus-shift-van/focus-shift-van.html`.

---

I'm finishing the **Focus** tab of Prepkin Canvas. The shift screen is built and running
(`18-focus-shift.png`, ported from `design/handoff/focus-shift-van/`). Three pieces that
handoff pointed at were never drawn, so the app is using stand-ins. Design those three.

## How Focus works today, in code (`ios/Sources/FocusView.swift`)

- Ready screen: title, the kin, a big minute count, chips 25 / 45 / 60, a − + stepper,
  a `+N coins for finishing` pill, one coral **Start focus** button.
- A shift: the kin drives a delivery van. Wage is **1 coin a minute**. The next undone
  task rides along in a pill under the scene. A "mile" ticks every 90 seconds. There is
  a `best shift` chip (miles, only ever goes up) and a Pause / Resume button.
- **Clock out early** pays for the minutes actually worked. It currently opens a native
  iOS confirmation dialog (`19-focus-clockout-dialog.png`). That is the stand-in.
- **Session end** currently just pays and drops back to the ready screen. There is no
  report. The kin plays `celebrate` at 25 minutes or more, `bounce` below.
- Strict / Sound off: the old handoff drew a segmented pill for these. Neither setting
  exists in code, so the row was left out.

## Artboard 1 — the clock-out sheet (the one I need most)

A bottom sheet over the shift screen, not a dialog. It asks one question and states the
pay, calmly. Two states:

- **Nothing earned yet** (under one minute): "The shift hasn't paid a minute yet."
  Primary quiet action **Keep working**. Secondary **Clock out** with no pay line.
- **Some minutes earned**: "14 min worked. That's what the shift pays." with the coin
  amount as a `CoinDisc` + number, and the best-shift chip if this shift already beat it.
  **Keep working** stays primary. **Clock out and take 14** is the secondary.

Rules: leaving is never scolded and never coloured as danger. No red. No "Are you sure?"
No "you'll lose". The sheet is the same visual family as the Kin buy-confirm sheet
(`design/handoff-kin/README.md`, `1k`).

## Artboard 2 — the shift report (session end)

Full screen, no tab bar, replaces the ready screen for one beat after the timer hits zero
or after a clock-out that paid something. Contents, in order of importance:

1. The kin, large, coat and stars as owned. Caption which emote you intend (`celebrate`
   for 25 min or more, `bounce` below).
2. **What the shift paid.** One big coin number. Copy: "25 minutes. 25 coins." Keep the
   arithmetic visible; it is the whole honesty of the feature.
3. The task that rode along, if any, with a **Mark it done** row that pays that task's
   own coins too (Canvas 30, Study 20, Life 10). If the task is a Canvas assignment it is
   not markable by hand — Canvas has to see the submission — so show it as "Riding along:
   Safety Seminar Quiz" with no checkbox.
4. Miles this shift and best shift, small. Only if best shift changed, say so once.
5. One coral **Done** and a quiet **Another shift**.

Never show a streak, never "come back tomorrow", never a calendar.

## Artboard 3 — pre-shift settings row (decide it, then I will decide whether to build it)

On the **ready** screen only, between the stepper and the Start button: a small
segmented pill with two switches.

- **Strict** — leaving the app clocks the shift out automatically, paying the minutes
  worked. Off by default. This is the only version of "strict" the app will allow, because
  it still pays.
- **Sound** — a quiet road loop while the van drives. Off by default.

During a shift the row is display-only (the old handoff's rule). Draw the ready screen
with the row, and the shift screen with it collapsed to two small glyphs next to the
best-shift chip. If you think the row hurts the ready screen's calm, say so and show the
screen without it as an alternate.

## Also solve

- The **task pill** under the van truncates at 22 characters. Give me the rule for long
  Canvas titles ("Quiz - International Graduate Student Com…") — two lines, or a
  course-name eyebrow with a shorter title.
- Reduce Motion: the report without the coin motion.

## What I want back

Three artboards (sheet in two states, report, ready-with-settings) plus the alternate if
you make one. The README lists every string. Tell me what you changed and why.
