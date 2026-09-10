# Home, A− to A+ — 2026-09-10

Simulator `prepkin-home` (`2A015A89`), iPhone 17 Pro, on 2026-09-10 (a Thursday).
Nothing rebuilt: the headline, the coin chip, the Day 1 offer cards, the tank and the
tab bar are untouched.

The code landed inside `de25906 "Checkpoint: the tree as found"` — another session ran
`git add -A` across the whole tree while this pass was still running, so the Home work
went in under a message that does not describe it. This file is the record.

## The seven fixes

| # | Where | What changed |
| --- | --- | --- |
| 1 | `HomeView.underGoals` | The empty day was blank space between the goals row and the grade calculator. One quiet line now: "Last list from your laptop 2h ago." Never a card, never an ask. |
| 2 | `HomeView.levelBand` | "3 stars · fully grown" drew a *full* gold capsule with nothing left to do — a meter, which PRODUCT.md bans. `StarPips` + words, no bar, at every stage. The lightning tile went too: three stars beside the word "stars" was one fact drawn twice. The band is 36pt shorter, which is why one more row now fits above the fold. |
| 3 | `HomeView.tomorrowLine`, `GameState.tomorrowLine()` | "Tomorrow: Bio quiz, Essay draft and 1 more", from Canvas work and dated tasks. Tapping opens the Calendar tab on tomorrow. Absent when tomorrow is empty. |
| 4 | `HomeCopy.underGoals` | "From your laptop 2h ago." under a full list, once that list is over an hour old. The cue used to live only inside Your day. |
| 5 | `Core/TaskTemplate.swift` | The menu leads with school: Read for one class · Start the thing due Friday · Email a professor · Go to office hours · Laundry. The wellness ones are all still there, below. Old saves get new presets merged in, switched off, in catalogue order. |
| 7 | `Tests/DebugUnlockTests.swift` | Both chip rails above the kin follow `-unlockAll` and nothing else, and both sources carry the `#if DEBUG` / `#else return false` that keeps them out of a Release build. |
| 9 | `Tests/CopySweepTests.swift` | "behind / streak / catch up / falling" banned on Home and Your day only. App-wide would fail on the Kin tab, where "the room behind your kin" is a plain word about where a thing sits. |

## Not built, on purpose

**6 — the grade calculator did not move.** It is the most undergrad-specific thing in the
app and on a four-task evening it starts at y=964 on an 874pt screen, so a busy student
never sees it. Putting it in the pinned header band is a layout change on the seam where
the tank's floor colour becomes the page, so it is a brief rather than freehand SwiftUI:
`design/CLAUDE-DESIGN-PROMPT-HOME-HEADER-BAND.md`, queued as `0d`. Moving it into
Calendar was the other option and was ruled out — that tab was another session's screen
this week.

**8 — the widget install card.** `ios/project.yml` has the app, its tests and a Live
Activity extension, and no home-screen widget target; its own comment says widgets "are
their own job". A card that opens instructions for a widget that cannot be installed is
the one thing Home must never do. Copy parked as a TODO in `HomeView.swift`.

## States

`states/`, all on the same simulator, seeded by `make-states.py`.

| File | What it shows |
| --- | --- |
| `a-no-canvas.png` | No laptop paired. Four habits, no quiet line — the goals row already says everything true. |
| `b-paired-nothing-due.png` | The state this pass was about. "Nothing due today" · "Last list from your laptop 2h ago." · "Tomorrow: Essay outline, Week 3 quiz and 2 more". |
| `c-four-tasks-two-done.png` | A normal evening: freshness line, two checked, Tomorrow line. |
| `d-all-done.png` | "All goals done today". |
| `e-day-1-offer.png` | The Day 1 notify card, unchanged. |
| `f-one-star-band.png` | The band at one star: one filled pip, two hollow, "Ready for the next star". Still no bar. |
| `g-tomorrow-opens-calendar.png` | The Tomorrow line tapped: Calendar, week view, Friday Sep 11 selected. |
| `home-light/dark/axxl.png` | The three appearances on one fixture. At accessibility-XL both new lines fit unwrapped and nothing clips. |

## Sweep

`before/` and `after/`, `test/ios-sweep.sh`, light + dark + accessibility-XL, all six
tabs plus Shop and Your day. Home's lint is clean in both: no control under 44pt, no
unlabelled button or image.

Two things to know about the sheets. The `axxl-home` frame in both sweeps lost its Canvas
rows: the sweep opens Your day, and on a fixture with a seeded list but no pairing code
that path clears the list. That state cannot happen for a real student — you cannot have
a list without having paired — so the per-appearance shots in `states/` are the honest
XL evidence. And `test/ios-sweep.sh` had five tab coordinates against six tabs, so every
tab after Home had been screenshotted off by one since Calendar landed on 2026-09-09.
Centres re-measured with `idb ui describe-all`: 47/107/167/227/287 at y=805, Kin at 361.

## Rebuilding a state

`make-states.py` writes `state.json` straight into the app's container. Two things it has
to do, both learned the hard way: terminate the app first, because it saves over you; and
null `pairingCode` and `pairingToken`, because otherwise `syncCanvas()` runs on appear,
applies an empty snapshot, and wipes the list you just seeded while stamping
`lastCanvasSyncAt` to now.

## Comparables

Run 2026-09-10, `search_screens`, platform `ios`.

- [Finch](https://mobbin.com/screens/99094ecd-8045-4de7-a865-13ea77b3a9f0) — the bird
  takes about a fifth of its scene band, so three task rows start above the fold, and an
  "Add a goal" row means the list never dead-ends.
- [Duolingo](https://mobbin.com/screens/a5b15916-fba9-4c56-9e9e-db3be35872a5) — the
  mascot sits *inside* the content instead of above it, so it costs no vertical space at
  all. The other extreme from ours.
- [Headspace](https://mobbin.com/screens/c7fcbf0d-0846-43a4-a0b5-89e681b6f4ce) — a dotted
  spine with filled and hollow dots says "where am I in today" with no bar and no number.

**The mascot band should shrink.** Ours is 184pt of drawing inside a 336pt band on a
402pt screen; Finch's pet takes a fifth of its band. Not touched — the band was made 10%
taller on 2026-09-04 so the kin had water to actually swim in, and that trade is George's
to make. Brief `0d` asks Claude Design for both heights side by side.

## Deviation from the brief

With no laptop paired and nothing due, there is no second line. The goals row already
reads "Nothing due today" and a second copy of that sentence directly under it is worse
than the space it would fill.
