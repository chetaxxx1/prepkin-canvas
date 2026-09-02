# Handoff: Kin tab — Prepkin Canvas

## Overview

The Kin tab is currently `ShopView(title: "Kin")` — a two-column grid of four species and four
scenes with a coin count. This handoff replaces it with three surfaces and a purchase ceremony:

| Surface | What it is | Reached from |
|---|---|---|
| **Kin** (tab root) | Your kin, large, in its owned scene. Care row. Together-since strip. | tab bar |
| **Collection** | Every kin, owned and not, grouped by tier, cheap first. | Kin root |
| **Shop** | Today's picks (5 slots) + Kin + Scenes. | Kin root, and the coin chip on Home |
| Kin detail | Sheet. Adoption card, stars, star-up, Set active. | Collection, Kin root |
| Buy → Arrival → Name → Adoption card | Sheet, then full-screen, then sheet, then keepsake. | any purchase |

The design imports TFT's grammar of value — a five-step tier ladder, star pips instead of level
text, a five-slot shop row, the lock — and refuses TFT's grammar of loss: reroll is free and
unlimited, nothing expires, no countdown, no padlocks, no `?` tiles, no meters.

## About the design files

`Kin Tab.dc.html` in this bundle is a **design reference created in HTML** — a prototype showing
intended look and behaviour, **not production code to copy**. The task is to recreate these designs
in `prepkin-canvas`'s existing SwiftUI environment using its established patterns: `Theme`,
`SlimeView`, `CardStyle`, `Scene0`, `AppState`. Do not ship the HTML and do not port it to WebKit.

Open it in any browser. It is a pannable/zoomable canvas of 23 artboards arranged in two turns,
newest at top. Every artboard carries a visible id badge (`1a`, `2c`, …) and a caption under it
stating what changed and why. Ids in this README refer to those badges.

## Fidelity

**High-fidelity.** Colours, type scale, spacing, radii and interaction timings are final and are
drawn from the tokens already in `Theme.swift` and `design/from-claude-design/HANDOFF.md`. Recreate
pixel-for-pixel at 390×844pt.

**Two exceptions:**

1. **Mascot art for the slime is production geometry, not a mock.** Every slime in the file is the
   real traced `SlimeArt.body` / `.belly` / `.faceIdle` / `.faceDelight` path data. Reproduce
   exactly; never redraw.
2. **The four new kin silhouettes in `1q` are proposals awaiting art approval.** Geometry is in
   `kin-silhouettes.json`. Faces are deliberately not drawn on them in `1q` — a dashed box marks
   where the existing code-drawn face goes, with the transform printed underneath.

---

## Data model deltas

All additive. Nothing in `Ledger` changes.

```swift
struct ChibiSpecies {
    let id: String
    let name: String
    let price: Int
    let tier: Int          // NEW: 1...5
}

struct OwnedChibi {
    let speciesID: String
    var level: Int         // unchanged 1...3 — now RENDERED as star pips, never as "Lv N"
    var name: String       // NEW: player-chosen, from the naming sheet
    var adoptedAt: Date    // NEW: drives "days together" and the adoption card
}

// GameState / AppState additions
var shopPicks: [String]      // 5 ids, kin or scene
var shopPickDay: DayKey      // rotate on day boundary
var lockedPick: String?      // survives reroll AND the day boundary
```

Catalogue grows from 4 to 6 entries:

| id | name | tier | price | `Theme.species()` |
|---|---|---|---|---|
| `slime` | Slime | 1 | 0 | `#51CFA0` (existing) |
| `ember` | Ember | 2 | 300 | `#F7A8B8` (existing) |
| `droplet` | Droplet | 3 | 400 | `#9BC8F2` (existing) |
| `sprout` | Sprout | 3 | 500 | `#A5CE6B` (existing) |
| `wisp` | Wisp | 4 | 800 | `#C3B2F0` (existing) |
| `comet` | Comet | 5 | 1200 | **NEW** `#FFC24B`, tail tip `#E8A62E` |

Scenes are unchanged — the real four from `Theme.swift` are used throughout: Study room 0,
Meadow 200, Golden hour 220, Night in 250.

**Price sanity:** at the existing earn rates (Canvas task 30, study 20, life 10, lesson 20, daily
word 30, plus focus) a full day is 120–200 coins. Uncommon is two days, Rare four, Epic a week,
Legendary about ten days of finishing everything.

---

## Design tokens

### Existing — use `Theme`, do not re-declare

```
paper       #FAF5EC   card        #FFFFFF   ink        #2E2822
muted       #988D80   dim         #B4A996   inactive   #C9BEAC
hairline    #F0E9DC   checkBorder #E5DDD0
coral       #FF6F61   coralSoft   #FFE9E5   coralIcon  #FF8A7E
mint        #57C79B   mintSoft    #E3F6EE   mintDark   #2E8C68
coin        #FFC24B   coinBorder  #E8A62E   coinSoft   #FFF3D6   coinDark  #B07A1A
slime       #51CFA0   slimeBelly  #B1EDD4   slimeInk   #101820   blush     #FF9E94
sky         #9BC8F2
```

### New tokens

```swift
// Add to Theme
static let lavender = hex(0xC3B2F0)
static let leaf     = hex(0xA5CE6B)
static let pink     = hex(0xF7A8B8)

/// Unowned-card field. One step off `paper`, NOT a desaturation.
static let unowned  = hex(0xFBF7F0)

/// Tier accent. Appears in exactly three places — see "The tier ramp" below.
static func tier(_ t: Int) -> Color {
    switch t {
    case 2: return mint       // #57C79B
    case 3: return sky        // #9BC8F2
    case 4: return lavender   // #C3B2F0
    case 5: return coin       // #FFC24B
    default: return dim       // #B4A996
    }
}

static func tierName(_ t: Int) -> String {
    [1: "COMMON", 2: "UNCOMMON", 3: "RARE", 4: "EPIC", 5: "LEGENDARY"][t] ?? "COMMON"
}
```

Design uses `#96877F` for warm-gray body text where `Theme.muted` is `#988D80` — a 2-value
difference. **Use `Theme.muted`.** Same for `#2E7A5B` / `#3E9E78` in the can't-afford panel — use
`Theme.mintDark` and a slightly lighter sibling.

### Type

Nunito (SF Rounded is the approved native substitute), weights 700 / 800 / 900 only.

```
34 / 900   arrival headline            25-27 / 900  sheet titles, page titles
21 / 900   name-sheet question         18 / 900     section headers
17 / 900   nav bar title               15.5 / 900   list row title
15 / 900   card title, button label    14.5 / 900   name pill, card name
14 / 800   toast text                  13.5 / 700   speech bubble
13 / 700   detail-sheet row label      12.5 / 700   body copy in panels
12 / 800   secondary meta              11.5 / 800   care-row label, small meta
10.5 / 800 strip label                 10 / 900     status pill (OWNED / ACTIVE)
9.5 / 900  tier plate (letter-spacing .14em)
```

Nothing below 9.5pt. **The one known violation** is the struck-through full price inside a 64pt
picks slot at 9.5/800 — flagged as an open item below.

### Geometry

```
Radii      card 20-22 · hero 24-28 · sheet 28 top corners · button 18-22
           tile 13-16 · pill / chip 999 · scene layer bottom 30
Borders    tier card 2pt · locked slot 2.5pt · quiet button 2pt #F0E9DC
Shadows    card      0 2px 8px rgba(46,40,34,.05)
           floating  0 2px 8px rgba(46,40,34,.12)      (pills over scene)
           bubble    0 3px 10px rgba(46,40,34,.12)
           coral CTA 0 6px 16px rgba(255,111,97,.35)
           mint CTA  0 5px 14px rgba(87,199,155,.34)
           sheet     0 -8px 30px rgba(46,40,34,.16)
           toast     0 8px 24px rgba(46,40,34,.28)
           tab bar   0 8px 22px rgba(0,0,0,.22)
Margins    24pt screen · 20pt list gutters · 12pt grid gap · 6pt picks-row gap
Scrim      sheet backdrop rgba(46,40,34,.34)
```

**No fake status bar and no fake keyboard anywhere.** Content starts at 52–58pt to clear the real
one. `1m` deliberately shows no keyboard.

---

## The tier ramp

The tier colour appears in **exactly three places**, never as a large fill:

1. the **name plate** — a pill filled with the tier colour, text always ink `#2E2822`
2. the **cost badge** — a pill filled with the tier colour, coin disc + price, text ink
3. a **2pt card border**

Plate and badge text is ink at every tier, never white — all five tiers are light enough to carry
it, so type weight and colour never change across the ramp.

**One per-tier exception:** at Legendary the coin disc inverts to `#FFF3D6` fill on a `#A8761D`
border, because a `#FFC24B` disc on a `#FFC24B` badge disappears. This is the only conditional in
the whole system.

Owned cards are `Theme.card` white. Unowned cards are `Theme.unowned` cream. **The kin's own
colours are never touched** — no grey, no desaturation, no silhouette, no blur, no padlock, no `?`.
That is what makes `1c` readable without a single lock. See artboard `1r` for the ramp as a spec
sheet.

### Stars, not levels

`OwnedChibi.level` (1…3, upgrade costs 100 then 250) renders as **1/2/3 star pips on a white pill
plate** under the kin. Retire the string `"Lv \(level)"` everywhere — it currently appears in
`ShopView.speciesCard` and in `Main.dc.html`'s header pill.

Star glyph: 5-point star in a 20×20 box.
`M10 1.4l2.5 5.3 5.8.7-4.3 3.9 1.2 5.7L10 14.2 4.8 17l1.2-5.7L1.7 7.4l5.8-.7z`
Earned: fill `#FFC24B`, stroke `#E8A62E` 1.4pt, `strokeLineJoin: .round`.
Unearned: no fill, stroke `#DDD3C4` 1.8pt.
Rendered at 12–13pt in cards, 15pt on the root plate, 19pt in the detail sheet, 24–33pt in the
star-up celebration.

Level visuals are unchanged from `SlimeView`: Lv1 small plain, Lv2 bigger + blush ellipses, Lv3
biggest + gold crown.

---

## Shared components

Define these once; most screens are assembled from them.

### Wallet chip
White pill, radius 999, padding 8×14, shadow `floating`. Coin disc 18pt (`#FFC24B` fill, 2.5pt
`#E8A62E` border) + balance 15/900 ink, gap 6. Tappable → Shop.
Smaller variant on pushed screens: padding 7×13, disc 16pt, value 14/900, shadow `card`.

### Tier plate
Pill, radius 999, padding 3×8 (2.5×7 in dense contexts), fill `Theme.tier(t)`, label
`Theme.tierName(t)` at 9.5/900, letter-spacing .14em, colour ink.

### Cost badge
Pill, radius 999, padding 3×10, fill `Theme.tier(t)`. Coin disc 11pt + price 12.5/900 ink, gap 4.
Unowned-at-full-price variant: white fill, 1.5pt tier border, ink text.
Legendary: coin disc becomes `#FFF3D6` on `#A8761D`.

### Kin card (Collection, Shop sections)
Radius 20–22, 2pt tier border, padding 8–10.
Owned: `Theme.card`, kin art, player name 13.5–15.5/900, star pips, then `ACTIVE` pill
(`#DFF3E9` bg, `Theme.mintDark` text, 10/900) if active.
Unowned: `Theme.unowned`, kin art at full colour, species name, cost badge.
Tiers holding a single kin render as a **full-width horizontal row** (art 64×57 left, name +
subtitle centre, stars or cost badge right, padding 9×14) rather than a 2-up grid cell with an
empty half. Tiers holding 2+ use the 2-up grid, gap 12. See `1c`.

### Sheet
`Theme.paper` background, top corners radius 28, padding 12 top / 24 sides / 34 bottom, shadow
`sheet`. Grab handle 42×5, radius 999, `#E5DDD0`, centred, 12–18pt below the top edge. Backdrop
`rgba(46,40,34,.34)`.

### Toast — NEW, and the biggest gap in the current app
See `2b`. `Theme.ink` fill, radius 16, padding 14×18, 20pt side margins, 34pt above the bottom
safe area (12pt above the tab bar where one is present), shadow `toast`. Leading glyph 15–17pt in
the tier or action colour; text white 14/800.

Rises 12pt and fades in over 180ms, holds 2.4s, fades out over 200ms. **Never more than one on
screen** — a second replaces the first in place. No dismiss control and no undo, because every
action it reports is reversible by repeating it.

Copy, verbatim:
- `"{name} is your active kin"`
- `"{scene} is your scene"`
- `"{species} held at {price} · tap to release"`
- `"Five new picks · {locked} kept"` (or `"Five new picks"` when nothing is locked)

### Care button
60×60 circle, `Theme.card`, shadow `0 2px 10px rgba(46,40,34,.09)`, 24pt icon, label 11.5/800
`Theme.muted` 7pt below. Column width 96, three across with `space-between` inside 24pt margins.
Hit target is the full 96×83 column, well over 44pt.

### Icons
All drawn vectors in a 24×24 box, no emoji anywhere, no SF Symbols with unrelated metaphors.
Exact path data is in the HTML. Set: shop door (awning + doorway), collection dock (2×2 rounded
squares), back chevron, forward chevron, check, lock (rounded body + arc shackle), reroll
(circular arrow), die (rounded square + 5 dots), info, share, bookmark, bars, Pet (three offset
arcs), High five (palm + 3 finger rounded rects), Snack (bowl + rim + two fruit circles).

---

## Screens

Full artboard index. Load-bearing screens are detailed after the table; for the rest, the HTML plus
the shared components above are the spec.

| id | Screen / state | Notes |
|---|---|---|
| `1a` | Kin root, settled, 2★ | Care row is live in the prototype — tap it |
| `1b` | Kin root, first run, empty wallet | No zeros, no unaffordable list |
| `1c` | Collection, grouped by tier | Full ladder visible without scrolling |
| `1d` | Kin detail sheet | Adoption certificate + star progress + Set active |
| `1e` | Shop, picks row at rest | 5 slots visible at once |
| `1f` | Shop, one slot locked | Lock reads by promotion, not by dimming |
| `1g` | Shop, mid-reroll | Frozen at ~180ms; motion spec on the artboard |
| `1h` | Shop, can't afford | The state that must never scold |
| `1i` | Shop, Scenes section | Real four scenes, real prices |
| `1j` | Honesty panel | Replaces TFT's odds table |
| `1k` | Buy confirm | Three numbers incl. wallet-after |
| `1l` | Arrival | Full screen, no chrome |
| `1m` | Name your kin | Finch's flow, no fake keyboard |
| `1n` | Adoption card | The keepsake |
| `1o` | Star-up 1★→2★ | Blush appears |
| `1p` | Star-up 2★→3★ | Gold crown reveal |
| `1q` | New kin silhouette sheet | 1120pt wide; art proposals |
| `1r` | Tier ramp spec | 520pt wide |
| `2a` | Kin root on a dark scene | `Scene0.isDark == true` |
| `2b` | Toast, in situ + all copy | Also shows Collection after a purchase |
| `2c` | Shop scrolled, sticky header | Picks row collapses to a summary pill |
| `2d` | Resilience sheet | Long name, no Canvas, Dynamic Type |
| `2e` | Reduce Motion sheet | Arrival + star-up without motion |

### `1a` — Kin root, settled

The screen that does not exist today. Layout top to bottom, 390×844:

- **Scene layer** `0 → 420`, bottom corners radius 30, `overflow: hidden`. Equipped scene image at
  390×430, `scaledToFill`, bottom-aligned. Overlay
  `radialGradient(circle at 50% 78%, white .30 → clear 62%)`.
- **Header** top 58, right 24, gap 10: shop-door button (40pt circle, `Theme.card`, shadow
  `floating`, 21pt icon) then the wallet chip.
- **Stage stack**, bottom 14, centred, gap 8, in order:
  speech bubble (`Theme.card`, radius 16, padding 9×16, 13.5/700, shadow `bubble`) →
  name pill (padding 6×15, 14.5/900) →
  kin at **212×190** with a ground shadow ellipse `cx 500, cy 878, rx 440, ry 52`, `slimeInk` at
  10% (in the kin's own 1000×897 space) →
  star plate (padding 5×12, three 15pt stars, gap 5).
- **Care row** top 436, sides 24. Pet / High five / Snack.
- **Together-since strip** top 540, sides 20. `Theme.card`, radius 20, shadow `card`, padding
  14×8. Three equal cells split by 1pt `hairline` dividers. Value 16/900 ink over label 10.5/800
  `muted`. Caption below at top 626: `"Every one of these only ever goes up."` 10.5/800 `dim`,
  centred.
- **Collection card** top 654, sides 20. `Theme.card`, radius 20, padding 14/16/12. Title row:
  dock icon + `"Collection"` 15/900 + `"2 of 6"` 12/800 `muted`, chevron right. Below, all six kin
  as 52pt-tall tiles, radius 13, gap 6: owned on `#F6F1E6`, unowned on `Theme.unowned`, 2pt border
  (`mint` if active, `Theme.tier(5)` for the Legendary, `hairline` otherwise). Art 42×38 with
  `marginBottom -4` so the kin sits on the tile floor.
- **Scrim** bottom 0, height 140, `paper` 0% → 92% at 55% → 100%.
- **Tab bar** — settled, unchanged, reproduced from `Main.dc.html`. Sides 16, bottom 30. Dark pill
  `Theme.ink`, radius 999, padding 8, five 44×40 items radius 14 with 19pt icons at
  `white.opacity(0.42)`. Kin is the sixth item: a 56pt circle, 3pt border, `#B1EDD48C` fill,
  containing the active kin at 74×66 offset `marginBottom -22`. **The border is `Theme.coral` when
  Kin is the active tab** (white otherwise). The kin svg must carry `viewBox 0 0 1000 897` and sit
  inside a non-shrinking wrapper, or it clips.

**Care row behaviour.** Pet / High five / Snack are free, unlimited, no cooldown, no counter, always
available — including on day one. They fire the animations that already ship and swap the speech
bubble copy for 3.2s:

| Button | `ChibiAnimation` | Face | Bubble copy |
|---|---|---|---|
| Pet | `.bounce` | `.delight` | `"{name} leans into it."` |
| High five | `.wave` | `.delight` | `"Nailed it."` |
| Snack | `.celebrate` | `.delight` | `"Crunch."` |

Idle copy: `"{name} is glad you came by."` No coins are spent or earned. **No meter of any kind** —
no hunger, energy, mood or affection, nothing that decays, and the kin is never hungry, sad or
neglected.

### `1b` — Kin root, first run

Deltas from `1a` only:
- Scene is Study room. Wallet reads `0`. Kin is 1★ at 164×147, plain (no blush).
- Name pill is replaced by a **dashed affordance**: `Theme.card` with a 2pt dashed `#E5DDD0`
  border, die icon + `"Name your kin"` 13.5/900 `muted`. Bubble: `"This one is yours. It's free."`
- Care row gains a caption at top 522: `"Free, unlimited, always. No cooldown."`
- **The together-since strip is replaced**, because printing `0 · 0 · 0` reads as failure on a
  strip whose whole promise is that it only goes up. Instead: `"Day 1 together"` 15/900 and one
  line of 12.5/700 `muted` naming what will appear.
- Collection card is retitled `"Five more to meet"`; the five unowned kin are drawn at full colour
  with their prices under them, 2pt tier borders, and the footer
  `"Finishing things earns coins. Nothing here ever expires."`

### `1c` — Collection

Push, no tab bar (`HideTabBar` applies). Nav row at top 52: 38pt back circle, `"Collection"`
17/900, wallet chip. Sub-line at top 98: `"2 of 6 owned · nothing here is ever locked or hidden"`
12/800 `muted`. Content from top 126, sides 20.

Groups run **cheapest tier first** — the price ladder itself is the progression signal. Each group
is a label row (tier plate + price range 10.5/800 `dim` + 1pt hairline rule, 8pt below) then the
cards. Group spacing 12. Closing line: `"That's the whole ladder. It never gets longer and nothing
on it ever leaves."`

### `1e` — Shop, picks row

- Nav row as `1c`, title `"Shop"`.
- Section head top 104: `"Today's picks"` 18/900 with `"New picks tomorrow"` 11.5/800 `muted`
  right-aligned. **Never a countdown.**
- **Picks row** top 136, sides 20, five equal slots, gap 6 (≈64pt each). Each slot: `Theme.unowned`,
  radius 16, 2pt tier border, padding 6/3/5. A `−20%` tab (8/900 ink on the tier colour) pins to
  top-right at `-7, -3`. Art 52×47 (or a 52×47 radius-11 scene thumbnail). Struck full price
  9.5/800 `dim`. Cost badge, compact: padding 2×7, disc 9pt, price 11/900.
- Legend top 262, 10.5/800 `dim`, centred: `"Struck price is the Collection price. Every pick is
  20% off. Long-press a slot to lock it."`
- **Reroll** top 292, sides 20. `Theme.card`, 2pt `hairline` border, radius 20, padding 13×18.
  Reroll icon + `"Reroll picks"` 15/900 left; `"Free · unlimited"` 12/800 `muted` right.
  **No cost badge on this control, ever.**
- `"Kin"` section head top 364, then a 2-up grid of 163pt cards, gap 12, art 86×77.
- `"Scenes"` section head top 700 with `"2 of 4"`, then 163pt cards with a 147×74 radius-14 image.

Pool is everything in the Collection the player does not own yet, drawn **evenly** — a Legendary has
the same chance as a Common. Rotate on the `DayKey` boundary. Everything in the row is also in the
Collection at full price, always, so a reroll can never cost the player a thing they wanted.

### `1f` — One locked slot

The lock is the only TFT control kept intact, because it can only help the player. It reads by
**promotion, not by dimming**:
- locked slot: `flex 1.16` (wider), `marginTop -6` (lifted), `Theme.card` (white, not cream),
  2.5pt tier border, `shadow: 0 0 0 5px tierColor@28%, 0 4px 14px rgba(46,40,34,.10)`, art 58×52,
  and a tier-coloured `LOCKED` tab centred on the top edge at `-9`.
- the other four: opacity 0.6.
- reroll label becomes `"Reroll the other four"`.
- explanatory panel at top 270 on a `#F3EFF9` field: `"{species} is held at {price}"` 13/900 over
  `"A locked slot keeps its discount through every reroll and overnight into tomorrow's picks.
  Long-press again to release it."` Copy, not a warning. No timer, no cost.

The lock persists across rerolls **and** across the day boundary.

### `1g` — Reroll motion

40ms stagger, left to right, **420ms total**. Per slot:
- outgoing card sinks 6pt, scales to 0.96, fades out over 120ms
- incoming card rises 10pt from beneath, fades in over 160ms, overshoots to 1.04 and settles on a
  soft spring
- the 2pt tier border **cross-fades** between the two colours rather than cutting — that colour
  change is the only signal of what the new thing is worth, so it must stay readable during the move
- the locked slot **does not move**; it gets one 1.02 pulse at 0ms so the player can see it was
  skipped deliberately

No spin, no reel, no card-back flip, no sound of chance. The reroll button holds a
`"Rerolling…"` state with a rotated icon in `dim` rather than disabling — there is no cost to
protect against a double tap. Then the `"Five new picks"` toast.

### `1h` — Can't afford

**The state that matters most.** Never greys into a wall, never scolds, no "not enough coins"
toast, no shake. The tapped kin opens the buy sheet in this variant:
- kin drawn full size and full colour, tier plate, struck price and off price exactly as normal
- the gap is stated on a **`Theme.mintSoft` success field**, not a red warning: `"{gap} coins to
  go"` 16/900 `mintDark` with `"{balance} of {price}"` right-aligned, a 9pt progress bar
  (`Theme.card` track, `mint` fill), then the number converted into work:
  `"That's 3 more assignments finished — or one 25-minute focus session and a lesson."`
- primary button is `"Open today's tasks"` (coral) — it goes where the coins are rather than nowhere
- closing line: `"{name} stays in the Collection at {fullPrice} forever, and comes back into the
  picks. Nothing here expires."`
- the slot behind is **not** greyed; it carries a small `"{gap} to go"` pip in `coinDark` on
  `coinSoft`.

Derive the conversion from `TaskKind.reward` — pick the smallest set of real task types that closes
the gap, preferring Canvas assignments.

### `1j` — Honesty panel

Replaces TFT's odds table. Four claims a student can check against the screen they just left:
five slots drawn evenly, a pick is only a 20% discount, reroll costs nothing ever, nothing ever
leaves. Footer: `"Coins are earned by finishing things. Never by getting them right."`
Entry point is a card at the foot of the Shop, not an info glyph in the nav bar.

### `1k` → `1n` — The ceremony

**Buy confirm (`1k`).** Sheet. Tier plate, kin at 180×161, name 27/900, `"Starts at 1 star. You'll
name it next."` Then a `Theme.card` panel with three rows in the order a student asks them:
Collection price (struck), `"Today's pick · 20% off"` with the real price 16/900, hairline, then
**`"Wallet after"`** — Finch's `06` footer moved into the sheet, because it is the question the
current shop never answers. Coral CTA `"Adopt {name}"` + coin disc + price. Quiet `"Not now"`.

**Arrival (`1l`).** The warmest moment in the app: full screen, **no header, no wallet, no tab
bar**. `radialGradient(circle at 50% 40%, tierTint → paper 62%)`, three concentric rings borrowed
from the tier (330 / 246 / 166pt, 2pt strokes at 30% / 44%, innermost filled at 18%), kin at 248×222
on `.delight`, and six flat 45°-rotated confetti squares 8–13pt in `coin` / `coral` / `mint` /
`lavender` / `pink` — the same construction the Home celebration already uses. Tier plate,
`"{species} is here."` 34/900, then `"Your third kin. It's yours for good — nothing takes it back."`
Coral CTA `"Give it a name"`, quiet `"Later"`.

**Name your kin (`1m`).** Copy Finch's `01` closely, because it is already right. White background.
Kin at 150×135 top. `"What do you want to name your {species}?"` 21/900 centred. `"You can change
this later."` 14.5/700 `muted`. One big centred field: `#F7F3EA`, 2pt `hairline` border, radius 18,
58pt tall, value 19/900 centred, clear glyph right. Then `"Shuffle"` (quiet, die icon) and
`"Next"`. **Two deliberate changes from Finch:** the commit button takes `mint`, not coral, because
naming is a completion rather than an action with a cost; and the field arrives pre-filled from
Shuffle so tapping straight through is a valid answer. Footer: `"This name replaces "{species}" on
Home, in Ask Kin and on the adoption card."` **No keyboard drawn.** Cap at 14 characters.

**Adoption card (`1n`).** The keepsake, built to be screenshotted. Warmer paper `#F1EADC` desk,
card `#FDFBF6` at radius 26 with shadow `0 8px 28px rgba(46,40,34,.13)`, an 8pt tier band across
the top so it reads at thumbnail size, and a 1.5pt `#EBE2D2` inner frame at radius 18.
`CERTIFICATE OF ADOPTION` 10/900 letter-spacing .2em. Kin at 188×169. Name 32/900. Tier plate +
species. Star pips. Hairline. `"Adopted 31 August 2026"`. Then a 2×2 grid of together-since slots
**shipped empty on purpose** — em-dashes in `#DDD3C4` with their labels, so the card is a promise on
day one and a record on day two hundred. `"These fill themselves in. None of them ever go down."`
Footer: mark + `Prepkin Canvas` + serial `No. 003`. Actions: `Share` (quiet) and `Meet {name}`
(coral). The same card, filled, is the body of the detail sheet `1d`.

### `1o` / `1p` — Star-up

Two-star: second pip lands with two concentric `coin`-tinted rings behind it (52 / 38pt at 22% /
34%); the pip scales 1.4 → 1.0 over 260ms while the kin runs one squash-and-settle, so plate and
body move together. Blush appears. Cost is reported **after the fact** in a quiet `coinSoft` pill
(`"100 spent"`) rather than confirmed beforehand, and the next star is priced so the ladder stays
visible. CTA `"Nice"` (quiet).

Three-star: the only moment in the tab that gets gold rings and coin-coloured confetti, because it
is the top of the ladder and nothing follows it. Crown drops from −40pt with a −12° tilt and
overshoots once; the third pip lands on the same frame. Copy closes the loop instead of teasing a
next tier: `"Moss wears the crown."` / `"Three stars. That's the last one — {name} stays exactly
like this from here."` CTA `"Show me"` (coral).

### `2a` — Dark scene

`Scene0.isDark == true` (Night in) already exists in `Theme.swift` with a comment promising this
treatment. Every pill over the scene flips to dark glass: `rgba(16,24,32,.54)` for controls,
`.62` for the bubble / name / star plate, 1pt `rgba(255,255,255,.18)` border, 12pt blur, white
type. **The coin disc keeps its brand colours** — it must be the same object across every scene.
Ground shadow deepens to `#050A12` at 34%. A bottom scrim
`rgba(20,26,40,0) → .30` keeps the cream section from cutting hard against the art. Scene layer
grows to 452 and the kin to 228×205; the collection card loses its thumbnail strip to pay for it.
**Everything below the scene is unchanged** — this is one branch, not a second screen.

### `2c` — Sticky header

Scrolling past the picks row loses the reason the player came, so it collapses into a sticky
summary pill: `paper` at 94% with a 14pt blur and a 1pt `hairline` bottom border, containing the
nav row and then a pill (`Theme.card`, 2pt `hairline`, padding 9×14) with an up-chevron,
`"Today's picks"` 13/900, five 9pt tier-coloured rounded squares standing in for the slots, and
`"{n} held"` in the lock colour. The squares strip is the cheapest possible restatement of "what is
on offer and what is it worth" — no art, no prices, only the ramp. At rest the header is flat
`paper` with no border.

### `2d` — Resilience

Three inputs that break every other artboard:
1. **A 13-character name.** Never truncate a name the student chose, and never let it wrap mid-word
   into the star plate. The name plate grows; the detail-sheet title drops 27 → 19pt on one line.
   Field caps at 14 characters.
2. **Canvas not connected.** The strip is derived from `Ledger.entries`, so with no Canvas link
   there are no assignment entries — and a hard `0` reads as failure on the one strip whose whole
   promise is that it only goes up. **Drop the cell and redistribute**, then offer the fix in coral
   as an action, not an error: `"Connect Canvas to count assignments here"`.
3. **Dynamic Type at XL and above.** Three columns cannot hold `"assignments done"`. Past XL the
   strip becomes rows (label 15/700 left, value 18/900 right, hairline between) and the care row's
   labels move inline beside 52pt buttons in full-width cards.

### `2e` — Reduce Motion

The rule: anything whose meaning **is** the movement is removed; anything that merely arrives with
movement gets a cross-fade at final position and final scale. Composition is identical either way.

- **Removed:** all confetti (its meaning is its trajectory), the reroll stagger, the care-row
  squash (becomes a 160ms face cross-fade plus the toast), the crown drop and tilt-overshoot, the
  star pip's 1.4 → 1.0 scale and its halo rings, and the `SlimeView.startIdle()` breathing loop —
  the kin is simply still.
- **Kept:** every ring and radial (static geometry already), the delight face, the crown itself,
  the pip plate at full size, and the full-screen no-chrome treatment.
- Arrival: kin cross-fades in at 100% scale over 260ms; copy follows on the same curve 80ms later.
  Crown fades in over 220ms already seated at its final `rotate(-12°)`.

---

## Rules that must not break

- Coins pay for **finishing** things. Never for grades, never for correct answers.
- **No meter of any kind.** No hunger, energy, mood or affection that decays. The kin is never
  hungry, sad, neglected or asking for anything.
- **No streaks, no countdowns, no daily-login pressure.** Any counter shown can only go up; never
  one that resets to zero.
- **No padlocks and no `?` tiles.** An unowned kin is fully drawn, named and priced. The player can
  always see what they are saving for — that is the whole motivation engine.
- **Nothing time-limited or exclusive.** Everything in the picks row is in the Collection at full
  price, always.
- **Nothing sold that protects the player from a punishment**, because there are no punishments.
- No loot boxes, no random pulls, no duplicate-to-shard conversion, no real money.
- **No emoji anywhere.** Every icon is a drawn vector in the palette.
- iPhone 390×844pt. Never a fake status bar, never a fake keyboard.
- The mascot is finished art. Soft dome/bell body, droplet antenna leaning right, two stubby mitten
  arms, pale oval belly patch low on the front. No neck, no legs, no outline, no shading — flat
  vector only. Body `#51CFA0`, belly `#B1EDD4`, ink `#101820`. **The kin is a blob, not a body:** no
  joints, arms are bulges flowing out of one smooth continuous silhouette, never a limb drawn as a
  separate part crossing the torso.

Note `SlimeView` currently draws `✨` and `💤` glyphs for the celebrate and sleep states. Those are
emoji and should become drawn vectors in the same pass — the flat 45°-rotated confetti squares used
throughout this design are the right replacement for the sparkles.

---

## State management

```swift
// Kin root
@State var careAnimation: ChibiAnimation = .idle   // 1.6s one-shot, back to .idle
@State var bubbleCopy: String                     // 3.2s, then idle copy
// no cooldown, no counter, no cost — deliberately

// Shop
@Published var shopPicks: [String]
@Published var shopPickDay: DayKey                // regenerate picks when this rolls over
@Published var lockedPick: String?                // excluded from reroll, survives the day boundary
@State var rerolling: Bool                        // 420ms

// Purchase flow — one path, four steps
enum AdoptionStep { case confirm, arrival, naming, certificate }
@State var adoption: (species: ChibiSpecies, step: AdoptionStep)?

// Toast
@Published var toast: String?                      // 2.4s; a new value replaces the current one

// Derived from Ledger.entries, never stored
var daysTogether: Int          // Date.now - OwnedChibi.adoptedAt
var assignmentsFinished: Int?   // nil when Canvas is not connected — see 2d
var timeFocused: TimeInterval
var lessonsRead: Int
```

Picks generation: uniform random over `Collection.filter { !owned }`, 5 without replacement, minus
the locked slot, seeded on `DayKey` so the row is stable within a day and identical across relaunch.

## Assets

- `scene-dorm.jpg`, `scene-meadow.jpg`, `scene-sunset.jpg`, `scene-night.jpg` — copied from
  `design/canvas/`. Full-resolution originals are already in `ios/Resources/Assets.xcassets` and in
  `design/scenes/`. Use those; the JPGs here are only so the HTML renders.
- `kin-silhouettes.json` — geometry for the four new/revised kin, in the same coordinate space as
  `design/canvas/mascot-paths.json`. Primitives (ellipses, circles) are given as primitives rather
  than beziers, since SwiftUI draws them directly; `trace.py` → `emit_swift.py` is only needed if
  you want them as `TracedShape` data.
- All icons, the coin disc, the star glyph and the confetti squares are drawn in code. No new image
  assets are required.

## Files

- `Kin Tab.dc.html` — the design canvas. 23 artboards, ids badged. Open in a browser; pan and zoom.
- `support.js` — runtime the HTML needs to render. Not for production.
- `kin-silhouettes.json` — new kin geometry.
- `scene-*.jpg` — scene art, for the HTML only.

Repository files this design touches:

| Area | File |
|---|---|
| Kin tab root, Collection, Shop | `ios/Sources/ShopView.swift` (replaced) |
| Tokens, tier ramp, scenes | `ios/Sources/Theme.swift` |
| `ChibiSpecies.tier`, `OwnedChibi.name` / `.adoptedAt` | `ios/Sources/Models.swift` |
| Picks, lock, toast, adoption flow | `ios/Sources/AppState.swift` |
| Star pips replacing `Lv N`; new species art | `ios/Sources/SlimeView.swift` |
| Together-since derivations | `ios/Sources/Core/` (Ledger) |
| Tab bar, scene layer reference | `design/canvas/Main.dc.html`, `ios/Sources/RootView.swift` |
| Push without tab bar | `ios/Sources/HideTabBar.swift` |

`ios/Sources/ChibiStageView.swift` is the old placeholder box and appears unused now that
`SlimeView` exists — check and delete.

## Open items

1. **The struck-through full price in a 64pt picks slot is 9.5/800**, below the readable floor. The
   brief asked for all five slots visible at once, which caps a slot at 64pt on a 390pt screen. The
   alternative is ~100pt cards in a horizontally scrolling row showing 3.4 of 5, which fixes
   legibility and loses "see all five at once". **Needs a decision before build.**
2. **Four of the nine approved faces do not exist in code.** `SlimeArt` has `faceIdle`,
   `faceDeadpan`, `faceJudging`, `faceDelight` and a placeholder `faceSleep`. The brief names nine;
   `surprised`, `sad`, `focused` and `wink` are missing. This design uses only `idle` and `delight`.
   `faceSleep` is also still marked "pending an approved sleep expression".
3. **The four new silhouettes need art approval** before implementation. `1q` states what makes each
   different at a glance; the width÷height spread (0.7 · 0.9 · 1.1 · 1.2 · 1.4 · 1.5, monotonic) is
   the property that makes them separable at 52pt — preserve the ordering if you adjust geometry.
4. **Comet's `#E8A62E` tail tip is a second flat body colour**, which no other kin has. It follows
   from the requested "gold-tipped". Approve or drop.
5. **Not designed, deferred by the plan:** hats and held items (anything worn must sit on the
   antenna or float, never break the silhouette), room decorating and props, and the loading /
   offline states for the picks row.
6. **Not specified:** haptics and VoiceOver labels. Best done as one spec sheet across all 23
   artboards rather than per screen.
