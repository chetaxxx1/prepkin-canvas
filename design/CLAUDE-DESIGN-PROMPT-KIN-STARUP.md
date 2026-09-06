# Prompt for Claude Design — Kin: the star-up moments (1o / 1p)

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the line.
Attach `design/screenshots/20-kin-root.png`, `21-kin-detail-sheet.png`, and the Kin
handoff `design/handoff-kin/Kin Tab.dc.html` + `README.md`.

---

The Kin tab is built from your handoff (`design/handoff-kin/`). Two frames it named,
**`1o` star-up 1★→2★** and **`1p` star-up 2★→3★**, were described in text but never
drawn, so growing a star today happens inside the detail sheet and reports itself with a
toast (`KinToast`). That is the one place in the tab that should feel like a ceremony and
does not. Draw the two moments.

## What exists in code

- `OwnedChibi.level` 1…3. Growing costs **100** (1★→2★) and **250** (2★→3★). Paid from the
  detail sheet's coral button `Grow to 2 stars · 100` (`21-kin-detail-sheet.png`).
- `AppState.upgradeActiveChibi()` pays, bumps the level, plays `celebrate`.
- Sprout's three evolutions are the three stars. Level 3 is the full character. There is
  no crown in the Sprout art (that was the old slime) — so the 3★ reveal is the
  evolution itself, not a hat.
- `StarPips` draws pips at any size; earned fill `#FFC24B` stroke `#E8A62E`, unearned
  stroke `#DDD3C4`. Sizes used so far: 12–13 in cards, 15 on the root plate, 19 in the
  sheet. Your README reserved 24–33 for the celebration.
- `Scene0` scenes, `GlassPill(onDark:)` for pills over a dark scene, `KinToast` for the
  quiet confirmation afterwards.

## Your own spec, which I am holding you to (from `design/handoff-kin/README.md`)

> Two-star: second pip lands with two concentric coin-tinted rings behind it (52 / 38pt
> at 22% / 34%); the pip scales 1.4 → 1.0 over 260ms while the kin runs one
> squash-and-settle. Cost is reported after the fact in a quiet coinSoft pill ("100 spent")
> rather than confirmed beforehand, and the next star is priced so the ladder stays
> visible. CTA "Nice" (quiet).
>
> Three-star: the only moment in the tab that gets gold rings and coin-coloured confetti.
> Copy closes the loop instead of teasing a next tier. CTA "Show me" (coral).

Keep all of that, with one correction: the 3★ reveal is the Sprout evolution, not a
crown. The old copy "Moss wears the crown" has to go. Write the replacement.

## Artboards

1. **`1o` — 1★→2★**, full screen over the equipped scene, no tab bar. Before / land /
   settled as three frames on one artboard, with the timing written under each.
2. **`1p` — 2★→3★**, same three frames. Confetti in coin tones only, brief, and it must
   read on the dark scene (`Scene0.isDark`) too — show one dark-scene variant.
3. **The sheet afterwards.** The detail sheet as it looks the moment you return: pips
   updated, the `100 spent` / `250 spent` pill, and for 3★ the button gone with the line
   that says this is the last one.
4. **Reduce Motion** — both moments as a single still with the same copy.

## Rules specific to this brief

- The star-up is paid **before** it plays (the button already did that). Never a confirm
  step inside the celebration. Never a "not enough coins" version of these screens; the
  button handles that on the sheet.
- No "Share" here. Sharing lives on the adoption card.
- Nothing about a next tier, a next kin, or the shop. The moment is about this kin.
- Copy: name the kin by its real name (`OwnedChibi.name`). No exclamation marks.

## What I want back

Four artboards, the exact copy for both stars, and the motion spec with durations,
curves and what happens to the scene behind (dim, blur, nothing). Tell me what you
changed from your own README and why.
