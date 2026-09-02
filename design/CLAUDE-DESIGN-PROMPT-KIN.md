# Prompt for Claude Design — Prepkin Canvas, the Kin tab

**How to use.** Attach these, then paste everything below the line.

*Reference frames — `design/reference/kin/` (see its README):*
`01-finch-name-your-bird` · `02-finch-closet-items` · `03-finch-outfit-sets` ·
`04-finch-equipped-toast` · `05-finch-closet-shoes` · `06-finch-gift-picker` ·
`07-finch-empty-visit-shop` · `08-finch-mr-prickles-shop` ·
`09-replika-clothes-shop` · `10-forest-tree-store` · `11-discord-shop-featured` ·
`12-mimo-store-REFUSE` · `13-alan-avatar-picker` · `14-numo-locked-ladder` ·
`15-lifereset-locked-grid-REFUSE` · `16-withings-locked-badges-REFUSE` ·
plus my own TFT / Webkinz / Club Penguin captures, numbered `20`+.

*My app as it is today — `design/screenshots/`:*
`01-home.png` (the system at its best) · `07-shop-buddies.png` and `08-shop-scenes.png`
(the screen being replaced) · `11-learn-v2-root.png` (the most recent finished work —
match this level)

---

I'm rebuilding the **Kin** tab of my SwiftUI iPhone app, Prepkin Canvas. Give me one
artboard per screen and state below, in my visual system, not the references'.

## What the app is

A companion app for high school students. A slime chibi lives on the home screen like
Finch's bird. Real Canvas LMS assignments sync in as tasks. Finishing daily tasks —
school work and life care — earns coins. Coins level up the chibi and buy new chibi
species and room scenes. Six tabs: Home, Focus, Games, Learn, Friends, Kin.

Kin today is a two-column grid: four species, four scenes, a coin count. That is the
whole tab. See `07-shop-buddies.png`. There is no way to look at your pet, no way to
touch it, no sense that one species is a bigger prize than another, and nothing that
knows you have had it for a month.

## What I'm mixing, and what I want from each

- **Finch** — the closet, the shopkeeper, the naming flow, the calm. `01`–`08`.
- **Webkinz** — the adoption certificate and the dock of pets you own.
- **Club Penguin** — a catalog you browse for fun, not a store you transact in.
- **TFT's shop** — this is the one I care most about. Its cost badges, tier colours,
  five-slot shop row, the lock, and star pips over a unit. It makes value legible at a
  glance and my flat grid does not.

## The single biggest idea, and the reason this brief exists

**I want TFT's grammar of value without TFT's grammar of loss.**

TFT is legible because a 5-cost is gold-framed and a 1-cost is grey. You know instantly
what the prize is. My four species sit at 0, 300, 400 and 500 coins in identical white
cards, and nothing on screen tells a student what to want.

But TFT charges you to reroll and Finch's Mr. Prickles (`08`) charges 10 stones **and**
runs a `5:48:38` countdown. Both make you lose. My app pays for finishing and never
punishes, so:

- **Reroll is free and unlimited.** No cost badge on it at all.
- **Nothing is ever exclusive or expiring.** Today's picks are a *discount*, and every
  one of them is in the Collection at full price forever.
- **No countdown.** "New picks tomorrow" is the most urgency allowed.
- **The lock stays**, because it is the one TFT interaction that can only help you.

Design the shop so it looks like a TFT shop and feels like a bookshelf.

## Rules you must not break

- Coins pay for **finishing** things, never for grades and never for correct answers.
- **No meter of any kind.** No hunger, energy, mood or affection that decays. The kin is
  never hungry, never sad, never neglected, never asking for anything. Finch gates
  adventures behind energy; we refuse it.
- **No streaks, no countdowns, no daily-login pressure.** Any counter shown can only go
  up. Never one that resets to zero.
- **No padlocks and no `?` tiles.** Compare `15` and `16` — that is the pattern I am
  refusing. An unowned kin is fully drawn, named and priced. You can always see what you
  are saving for; that is the whole motivation engine.
- **Nothing sold that protects you from a punishment.** `12-mimo-store-REFUSE` sells
  League Protection and Double XP. We have no league and no penalty, so no such product.
- No loot boxes, no random pulls, no duplicate-to-shard conversion, no real money.
- iPhone, 390×844pt. Never draw a fake iOS status bar and never a fake keyboard.
- **No emoji anywhere.** Every icon is a drawn vector in the palette.
- The mascot is finished art and must be reproduced exactly, never redesigned. Soft
  dome/bell body, droplet antenna leaning right, two stubby mitten arms, pale oval belly
  patch low on the front. No neck, no legs, no outline, no shading — flat vector only.
  Exact palette: body `#51CFA0`, belly `#B1EDD4`, ink `#101820`. Nine approved faces,
  drawn in code, never invented: idle, deadpan, judging, delight, sleep, surprised, sad,
  focused, wink. Levels: Lv1 small plain, Lv2 bigger + blush, Lv3 biggest + gold crown.
- **The kin is a blob, not a body.** No joints. Arms are bulges that flow out of one
  smooth continuous silhouette. Never a limb drawn as a separate part crossing the torso.

## Design tokens already in the code — keep these

bg cream `#FAF5EC` · card `#FFFFFF` · ink `#2E2622` · warm gray `#96877F` · muted
`#B4A996` · hairline `#F0E9DC` · coral action `#FF6F61` (soft `#FFE9E5`, deep `#E4735F`)
· mint success `#57C79B` (soft `#DFF3E9`, dark `#3E9E78`) · coin `#FFC24B` (border
`#E8A62E`, soft `#FFF3D6`, dark `#A8761D`) · sky `#9BC8F2` · lavender `#C3B2F0` · leaf
`#A5CE6B` · pink `#F7A8B8` · blush `#FF9E94`.

Rounded friendly type (Nunito), weights 700/800/900. Radii: cards 20–22, hero 24–28,
buttons 18–22, tiles 14, pills 999. 24pt screen margins. Tab bar is settled and stays.

## The tier ladder — do this in my palette

Five tiers, and the tier colour appears **only** on the cost badge, the name plate and a
2pt card border. Never as a large fill — my UI is deliberately low-chroma and the kin
must stay the most saturated thing on screen. TFT does exactly this: the art is the art,
the tier is the frame.

| Tier | Name | Price | Colour |
|---|---|---|---|
| 1 | Common | 0–150 | warm gray `#B4A996` |
| 2 | Uncommon | 200–300 | mint `#57C79B` |
| 3 | Rare | 400–500 | sky `#9BC8F2` |
| 4 | Epic | 700–900 | lavender `#C3B2F0` |
| 5 | Legendary | 1200 | coin `#FFC24B` |

**Stars, not levels.** A kin has 3 levels at 100 and 250 coins. Draw them as 1/2/3 star
pips on a small plate under the kin, the way TFT reads a unit's star level. Kill the
"Lv 2" text everywhere.

## Screens I want back

### 1. Kin (tab root) — the screen that does not exist yet

Your kin, large, standing in its owned scene (full-bleed illustrated room, same as Home).
Its name over it, star pips under it. Then:

- **A care row** — three round buttons: Pet, High five, Snack. Free, unlimited, pay
  nothing, no cooldown, no counter. They just make it react. Right now you cannot touch
  your pet at all and that is the biggest miss on this tab.
- **Together since** — one quiet strip of real numbers, e.g. *23 days together · 41
  assignments finished · 6h 20m focused*. All only ever go up.
- **Collection** and **Shop** entries. Compare the top-right shop door in `03`.

Give me **two states**: a settled kin at 2 stars, and **first run** — free starter slime
at 1 star, nothing else owned, empty wallet. First run must feel like a beginning, not a
list of things you cannot afford.

### 2. Collection — the dock

Every kin, owned and unowned, grouped by tier with the cheap tiers first (`13` gets this
ordering right). Owned shows its name and stars. Unowned is **fully drawn** in a soft
cream field with its price — never greyed out, never a silhouette, never a lock. Compare
`14`, which keeps its characters in full colour and greys only the rail.

Also: **the detail sheet** for one kin — my answer to TFT's unit tooltip. Big art, tier
plate, its name, adoption date, the together-since numbers, star progress with the cost
of the next star, and Set active. This is the Webkinz adoption certificate.

### 3. Shop — the TFT screen

Top: **Today's picks**, five cards in one horizontal row, TFT's shop bar rebuilt in
cream. Tier-coloured badge and plate on each, struck-through full price beside a 20%-off
price. Then sections for **Kin** and **Scenes** below.

Give me these states:

- the row at rest, with the wallet chip
- **one slot locked** — show the lock affordance clearly, it is the one TFT control I keep
- **mid-reroll** — how five cards change over. Free reroll button, and note in a caption
  what motion you intend
- **can't afford** — the state I care most about getting right. It must never scold or
  grey into a wall. Show what it would take instead: *3 more assignments*
- the **Scenes** section, using my four existing scenes
- an **honesty panel** — a short sheet replacing TFT's odds table: how picks are chosen,
  that rerolls are free, and that nothing ever leaves the shop

### 4. Buying — the ceremony

- **Buy confirm** — small sheet, the kin, the price, what's left after. Compare the
  footer line in `06` that prices the action before you take it.
- **Arrival** — the kin appears. This should be the warmest moment in the app.
- **Name your kin** — copy `01` closely: a big field, a **Shuffle** die, and the line
  *You can change this later*. Fires straight after arrival.
- **Adoption card** — the keepsake. Name, species, tier, the date, and room for the
  together-since numbers to fill in later. Make it worth screenshotting.
- **Star-up** — 1★ → 2★ and 2★ → 3★. The 3★ reveal is the gold crown, which already
  exists in the art. Make it land.

## Also design, in text and as flat vector

**Four new kin.** Ember, Droplet and Sprout are currently the same slime in three
colours, which is why no tier reads as a prize. Give me distinct silhouettes for tiers
2–5 in the same construction language as the slime: one smooth continuous blob, no
joints, no outline, no shading, flat vector, mitten-bulge arms, one signature feature up
top the way the slime has its droplet antenna. Faces stay code-drawn from my nine
approved ones — leave the face area clean and tell me where it goes.

## What I want back

One artboard per screen and state above. Then, in text: the tier ramp as applied to my
tokens, the reroll motion, and a note per new kin saying what makes its silhouette
different at a glance.

Cozy and calm, not gamified-noisy — Finch meets a clean planner, with TFT's clarity about
what a thing is worth. Tell me what you changed and why, per screen.
