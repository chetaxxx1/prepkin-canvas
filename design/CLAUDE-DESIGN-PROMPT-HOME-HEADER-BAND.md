# Brief — iOS Home, the header band

Paste `CLAUDE-DESIGN-PREAMBLE.md` first. One screen: **Home** (`ios/Sources/HomeView.swift`).

Written 2026-09-10, after a pass that took Home from A− to A+ in code. Everything in
"Already fixed" below is live on `main`, so read the file, not this list, for the truth.
This brief is only about the part that could not be fixed without a designer: **the band
between the tank and the task list**.

## The screen

Home is the best screen in the app and the one every student opens every day. It is four
stacked things, top to bottom:

1. **The tank** — a WKWebView painting the scene and the kin. Fixed height,
   `min(width × 0.836, height × 0.385)` ≈ 336pt on an iPhone 17 Pro. Name chip and
   coin chip float on top of it.
2. **The header band** — pinned, does not scroll. Today: a level band, then the goals
   row, then one quiet line. This is what the brief is about.
3. **The task list** — scrolls. `TaskRow`s, then a Tomorrow line.
4. **The grade calculator card** — the last thing in the scroll.

Screenshots of every state, taken 2026-09-10 after the code pass:
`design/screenshots/home-a-plus-2026-09-10/states/`
- `a-no-canvas.png` — four habits, no laptop paired
- `b-paired-nothing-due.png` — the empty day
- `c-four-tasks-two-done.png` — the normal evening
- `d-all-done.png`
- `e-day-1-offer.png` — the Day 1 offer card
- `home-light.png`, `home-dark.png`, `home-axxl.png` — the three appearances
Before/after contact sheets for all six tabs are in the same folder
(`before/contact-*.png`, `after/contact-*.png`).

## The problem to solve

**The grade calculator is the most undergrad-specific thing in the app and it is below
the fold on any busy day.** On a four-task evening it starts at y≈964 on an 874pt screen
(measured with `idb ui describe-all`, 2026-09-10). A student with six tasks never sees it
at all. It is a full-width card with a 44pt icon tile, a title and a subtitle — the same
weight as a task, which it is not: it is a tool you reach for twice a term, not a thing
to finish today.

The obvious move is to put it in the header band, which is pinned and always visible. But
the band is the most delicate part of Home. It already carries three things, it sits on
the seam where the tank's floor colour becomes the page, and it is the only thing between
a 336pt illustration and the list. A fourth element freehanded into it is exactly how a
screen that reads calm starts reading busy. So: **you design it, we port it.**

### What the band must still do

- **"4 goals left today" stays the headline.** It is the one line a student reads in
  three seconds at 11 PM. Nothing may outrank it. (Copy: `HomeView.goalsLine` — the
  empty variant is "Nothing due today", the finished one "All goals done today".)
- The **sliders button** (Your day) stays in the goals row, 44pt, right-aligned.
- The **quiet line** under the goals row stays. It is muted 12.5pt and says one of:
  "Last list from your laptop 2h ago." (empty day, laptop paired) or
  "From your laptop 2h ago." (full day, list older than an hour). It is absent
  otherwise. Never a card, never a button, never an ask.
- The **level band** stays: `StarPips` and up to 23 characters of words
  ("Fully grown" / "Ready for the next star" / "40 to the next"). **No bar** — a
  capsule that fills is a meter, and PRODUCT.md bans meters. Do not put one back.

### What to draw

One header band that holds the grade calculator as a **compact row or chip**, at a weight
clearly below the goals line, in all five states above — including the empty day, where
the band is nearly all there is on screen, and at accessibility-XL, where the goals line
alone is 25pt tall.

Say in the README whether the level band and the grade-calculator entrance should share a
row, and what happens to that row when the words run long at XL.

## The second question: how big is the kin?

Finch's bird takes about **a fifth** of its scene band. Ours takes almost all of it: the
drawing is 184pt wide on a 402pt screen inside a 336pt band. Compare
`design/screenshots/home-a-plus-2026-09-10/states/c-four-tasks-two-done.png` with the
Finch screens below. Finch gets three whole task rows above the fold; we get four only
because the level band lost its bar this week.

**Do not shrink the band in this brief.** George has not decided. What we want from you
is one artboard showing the band at its current 336pt and one at a smaller height, same
content, so he can look at the two side by side and choose. Say what each costs: a
shorter tank means less water for the kin to actually swim in, which was an explicit
ask on 2026-09-04 (the band was made 10% taller for exactly that reason).

## Constraints

- The page background **is the tank art's own floor colour**, continued as a gentle
  ramp (`HomeView.tankPage`). There is no card, no seam, no shadow under the tank. Do
  not introduce one.
- No meters, no streaks, no countdowns, no red, no exclamation marks. Amber only ever
  means "still counts".
- One coral button per screen. Home's coral is spent on the Day 1 offer cards.
- Every string that sits on one line is under 40 characters.
- Reuse `StarPips`, `CoinDisc`, `IconTile`, `TaskRow`, `KinChip` by name. Do not
  restyle them.
- Light only. The app forces `UIUserInterfaceStyle: Light`; dark paper is brief #7.

## Mobbin

Run these with `search_screens`, platform `ios`, and look at the images:

- "Finch home screen bird with goals list" — the comparable we keep measuring against.
  Note how little of the band the bird takes and how early the list starts.
- "Duolingo home path with mascot" — the mascot sits *inside* the content instead of
  above it, so it costs no vertical space at all. Worth knowing as the other extreme.
- "Headspace today screen" — a dotted spine joins the day's items, so "where am I"
  reads without a bar or a number. Relevant if you want progress in the band.

List what you took in the README under **References**.

## What to return

`design/handoff-home-header/` — one `.dc.html` with the artboards, one `README.md` in
the shape of `design/handoff-kin/README.md`. Claude Code ports it and writes
`BUILD-NOTES.md` back.

## Already fixed in code — do not re-solve

Landed 2026-09-10, all in `HomeView.swift` unless noted:

1. The empty day is no longer blank space: the quiet line under the goals row.
2. The level band lost its progress bar and its lightning tile. `StarPips` + words.
3. A Tomorrow line under the list — two titles then "and N more", tapping opens the
   Calendar tab on tomorrow. Absent when tomorrow is empty.
4. The freshness cue is on Home, not only inside Your day.
5. The preset menu leads with school-shaped tasks ("Read for one class", "Email a
   professor", "Go to office hours", "Start the thing due Friday", "Laundry") —
   `Core/TaskTemplate.swift`. The wellness ones are all still there, below.
6. The emote and costume chip rails above the kin are `-unlockAll` only and are not
   compiled into a Release build (`Tests/DebugUnlockTests.swift`).
7. The widget install card is **not built**: `ios/project.yml` has no widget target, so
   the card would open instructions for something that cannot be installed. The copy is
   parked as a TODO in `HomeView.swift`. Not yours unless the target lands.
