# Kin, the fish's own page — 2026-09-11

Simulator `prepkin-kin` (`77844BAC`), iPhone 17 Pro, iOS 26.5. Tests ran on their own
simulator (`prepkin-kin-tests`), never on this one, so the sticky `-unlockAll` key never
touched these shots. Brief: `design/CLAUDE-DESIGN-PROMPT-KIN.md` (rewritten the same day).

## What shipped

| Piece | Where |
| --- | --- |
| The tab: stage, bubble, one name plate with stars (tap to rename), the friendship word, care on the water's edge, doors, Season row | `ios/Sources/KinView.swift` |
| Friendship ladder — five words that only go up | `ios/Sources/Core/Friendship.swift`, `OwnedChibi.careTaps` / `stageReached` |
| Firsts — happened once, stays, with its date | `ios/Sources/Core/Firsts.swift`, `GameState.firsts` |
| The Card: certificate kept current, friend code, three numbers, Firsts, Share (story PNG) | `ios/Sources/KinCardSheet.swift`, `AdoptionCard` in `AdoptionFlow.swift` |
| The Wardrobe editor: live tank, Costume / Coat / Scene, None first, try-on, buy, saved looks | `ios/Sources/WardrobeEditor.swift`, `GameState.buyCostume` |
| Decorate: slot model + tray, behind `KinFlags.decorate` (off) | `ios/Sources/Core/TankDecor.swift`, `ios/Sources/DecorateEditor.swift` |
| Copy: "Moss is around."; the dashed Name-your-kin pill is gone | `KinView.swift` |
| Tests, 17 new | `ios/Tests/KinRedesignTests.swift` |

Gone from the tab: the Wardrobe card, the Saved looks card, the Together strip and the
Collection rail. They live behind the doors now.

## The friendship table, as built

`score = days since adoption + min(careTaps / 4, 30)`. A stage is the highest whose
threshold the score has reached; `stageReached` keeps it there if the clock runs back.

| Stage | Score | Without care | With care, earliest |
| --- | --- | --- | --- |
| Just met | 0 | day 1 | — |
| Tankmates | 3 | day 4 | day 1, 12 taps |
| Buddies | 14 | day 15 | day 1, 56 taps |
| Besties | 60 | day 61 | day 31, 120 taps |
| Old friends | 180 | day 181 | day 151, 120 taps |

("day N" is `daysTogether`, which starts at 1.) A rise is one toast: "You and Pip are
buddies now." No number, no bar, no sheet.

## Shots

- `light-kin-toast` — the tab the moment a stage rises.
- `light-kin` — the tab settled: Pip, three stars, Ninja, Reef, day 12, Buddies, three doors.
- `light-wardrobe` — the editor, Ninja on, worn tile ringed mint. `-tryon`: Blazer tried on
  (ink ring, "Wear it · 300"). `-short`: 120 coins against 300, the mint panel.
  `-buy`: the Hoodie at 150 against 120. `-coat`, `-scene`: the other two tabs.
- `light-wardrobe-zero` / `light-kin-zero` — nothing on the rack owned: every tile at full
  colour with its price, None ringed, nothing dimmed, no lock.
- `light-card`, `light-card-share`, `story-card.png` (the 1080×1920 PNG the share sheet
  gets, pulled from the app's tmp folder).
- `light-kin-firstrun`, `-pet` — day 1, no coins, "This one is yours. It's free.", Just met.
- `dark-*` — the app is light-only; these prove nothing flips.
- `axxl-*` — reading sizes at the 1.3× cap; nothing clipped, the doors stay one row.
- `contact-light/dark/axxl.png` — sheets. `sheet.py` makes them and prints the lint.

No Season row in any shot: no season runs today (Midterms starts 2026-09-22), and the
tab draws nothing between seasons.

## Not built, on purpose

- **Decorate is behind a flag.** The five shipped tanks have their props painted in;
  the keyed cut-outs the compositor makes exist only for the trial tanks
  (`design/tanks/trial/layers/`). `TankProp.catalog` is empty, so the door is hidden
  rather than opening on an empty tray (the "?" tile in another shape). Turn on
  `KinFlags.decorate` when the handoff and the props land.
- **Door icons are SF Symbols** (`tshirt.fill`, `leaf.fill`, `square.grid.2x2.fill`,
  `person.text.rectangle.fill`). Four flat icons are owed from `design/icons/`.
- **The tankmate** (Finch's micropet) is a row in `design/KIN-PLAN.md` section 11.
- **Star-up frames** `1o` / `1p` are artboards 7 and 8 of the brief, not code.
- **No new animation.** Care reuses bounce / wave / celebrate; the costume put-on reuses
  the existing bounce. Nothing needs a GIF sign-off.

## Fixed in passing

`OwnedChibi.statsAtAdoption` was never in `CodingKeys`, so every relaunch forgot it and a
kin adopted last week claimed the whole account's history on its card. It is persisted
now; older saves read as "since the beginning", which is what they did before.
