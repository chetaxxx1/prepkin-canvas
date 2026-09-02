# Kin tab — what shipped, and where it departs from the handoff

Built 2026-08-31 from `design_handoff_kin_tab` (this folder). The handoff README is the
spec; this file records only what the code does differently, and why.

## What shipped

| Artboard | Where it lives |
|---|---|
| `1a` / `1b` root, settled and first run | `ios/Sources/KinView.swift` |
| `1c` Collection, grouped by tier | `ios/Sources/CollectionView.swift` |
| `1d` kin detail / adoption card | `KinDetailSheet` + `AdoptionCard` |
| `1e`–`1i` shop, picks, lock, scenes | `ios/Sources/KinShopView.swift` |
| `1j` honesty panel | `HonestyPanel` in `KinShopView.swift` |
| `1k`–`1n` confirm → arrival → naming → certificate | `ios/Sources/AdoptionFlow.swift` |
| `1q` new kin silhouettes | `design/handoff-kin/kin-silhouettes.json` → `ios/Sources/KinArt.swift` |
| `1r` tier ramp | `Theme.tier` / `Theme.tierName`, `TierPlate`, `KinCostBadge` |
| `2b` toast | `KinToast` + `View.kinToast` |
| `2a` dark scene | `GlassPill(onDark:)`, branched off `Scene0.isDark` |

## Departures, and the reason for each

**1. "Together since" is stored, not derived.** The handoff says these numbers come from
`Ledger.entries`. They cannot: `Ledger.compactIfNeeded` folds lines older than its window
into the opening balance, so a derived count would go **down** over time — on the one
strip whose whole promise is that it only goes up. Added `GameState.lifetime`
(`LifetimeStats`), incremented where the work is posted. The v4 migration seeds it from
whatever entries the ledger still holds, so an old save starts a little low rather than
claiming a number it cannot show its work for.

The one way a number falls is an explicit undo of a check-off, which is honest: the
student is saying the thing did not happen.

**2. The screen is not pinned to absolute y positions.** The artboards budget 20pt of top
chrome on a 390x844 canvas; a real iPhone spends about 99. The scene is sized from the
headroom that is there and everything below it scrolls. This is the same departure Home
v2 made, for the same reason.

**3. The tab bar is unchanged.** `1a` reproduces the floating dark pill from
`Main.dc.html`. The app ships the cream bar in `RootView`, and swapping it would change
all six tabs, not this one. Out of scope for this pass.

**4. Three geometry fixes to the proposed silhouettes**, all made because they broke the
"one smooth continuous outline" rule the mascot is built on:
- **Ember's mitten lobes were detached.** They ended at x=290 and the torso began at
  x=300 — a 10-unit gap, so the arms rendered as buttons pinned to the sides.
- **Wisp's crescent hood crossed the dome's outline**, which is exactly the visible join
  the blob rule forbids. Replaced by a mushroom cap folded into the torso path, so there
  is no second shape to detach. Its belly was also reaching below the hanging lobes and
  showing through the gaps; raised and narrowed.
- **Comet's tail was a constant-width sliver** ending in a ball — a stick, not a bulge.
  Rebuilt as a tapered mass rooted deep in the shoulder, with the gold tip seated inside
  the tail end.

**5. `KinArtView` compensates for the level scale.** `SlimeView.size` is the box a 3-star
kin fills, so a 1-star kin asked for at 180 came out at 140. Every measurement in the
handoff is the size the art should actually be. The footprint is pinned separately —
letting SlimeView's 35% of internal slack grow with the compensation pushed whole rows
off the side of the screen.

**6. Two icons redrawn.** The handoff's shop door (a bar over a box) read as a trash can
on device; rebuilt as a scalloped awning over a shop front with the doorway cut out.
"Pet" as three concentric arcs read as a rainbow; it now has a head for the strokes to
travel over.

**7. Scenes borrow the kin tier ramp**, banded by price, so one picks row can hold both
kinds without inventing a second colour language.

**8. The mascot's last two emoji are gone.** `SlimeView` drew `✨` and `💤` in the system
font for celebrate and sleep — the only things on screen not in the palette, and very
visible on the arrival screen. Replaced by `Spark` and `SleepZs`, drawn in code.

**9. Star-up (`1o` / `1p`) is not a full-screen moment yet.** Growing a star happens in
the detail sheet and reports itself with a toast. The two celebration screens are still
owed.

## Open items carried forward

1. **The four new silhouettes need George's art approval** before they count as shipped.
   Rendered sheet: `design/handoff-kin/kin-silhouettes.png`. Comet is the weakest — its
   tail still reads a little like a raised arm.
2. **Comet's `#E8A62E` tail tip is a second flat body colour**, which no other kin has.
   Approve or drop.
3. **The struck price in a 64pt picks slot is 9.5pt**, below the handoff's own readable
   floor. Shipped as specified; the alternative is a horizontally scrolling row that
   loses "all five at once". Still needs a decision.
4. The certificate has no **Share** action yet — `1n` pairs one with "Meet {name}".
5. Four of the nine approved faces (`surprised`, `sad`, `focused`, `wink`) exist; this
   design only uses `idle` and `delight`.
6. Not designed and not built: hats and held items, room decorating, the picks row's
   loading/offline states, haptics and VoiceOver labels.
