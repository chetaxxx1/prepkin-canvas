# Kin — plan (2026-08-31)

The Kin tab is currently `ShopView(title: "Kin")`: a two-column grid of four species and
four scenes. It is the least designed screen in the app now that Learn v2 has shipped.
This is the plan the Claude Design brief (`CLAUDE-DESIGN-PROMPT-KIN.md`) sits on.

Four decisions George made before the brief was written:

1. **Spotlight shop, no loss.** TFT's grammar of value, none of its grammar of loss.
2. **Scope is buddy + collection + shop.** Hats, held items and room decorating are a
   later pass.
3. **Kin root is the buddy.** Shop and Collection push from it.
4. **You name your kin**, and buying one hands you an adoption card.

---

## 1. Structure

| Surface | What it is | Reached from |
|---|---|---|
| **Kin** (tab root) | Your kin, big, in its scene. Care row. Together-since strip. | tab bar |
| **Collection** | Every kin, owned and not, sorted by tier. | Kin root |
| **Shop** | Today's picks + Kin + Scenes. | Kin root, and the coin chip on Home |
| Kin detail | Sheet. Adoption card, stars, star-up, Set active. | Collection, Kin root |
| Name your kin | Sheet. Field + Shuffle. | after any purchase |

## 2. Tiers — the TFT import that pays for itself

Today four species sit in a flat grid at 0/300/400/500 coins and nothing tells you which
is the big one. TFT solves exactly this with a five-step cost ladder that is legible at a
glance, and it costs us no new art: the tier lives on the **cost badge, the name plate
and a 2pt card border only**. Never a large fill — the UI stays low-chroma and the kin
stays the most saturated thing on screen.

| Tier | Name | Price | Colour | Kin |
|---|---|---|---|---|
| 1 | Common | 0–150 | warm gray `#B4A996` | Slime (starter, free) |
| 2 | Uncommon | 200–300 | mint `#57C79B` | Ember |
| 3 | Rare | 400–500 | sky `#9BC8F2` | Droplet, Sprout |
| 4 | Epic | 700–900 | lavender `#C3B2F0` | Wisp *(new)* |
| 5 | Legendary | 1200 | coin `#FFC24B` | one new kin, to be designed |

`Theme.species()` already carries unused colours for `mochi` (pink), `puff` (sky) and
`wisp` (lavender), so the catalogue can grow to seven without touching the palette.

**Price sanity.** Earning is 30 a Canvas task, 20 study, 10 life, 20 a lesson, 30 the
daily word, plus focus. A full day is roughly 120–200 coins, so a week is 800–1200. A
Legendary is about a week and a half of finishing everything — a real goal, not a wall.

## 3. Stars — the second free import

`OwnedChibi.level` is already 1…3 at 100 and 250 coins. Render it as **1/2/3 star pips on
a plate under the kin**, the way TFT reads a unit's star level, and retire the "Lv 2"
text. The art payoff already exists: Lv3 wears the gold crown. No data model change.

## 4. Shop mechanics

- **Today's picks** — 5 slots in one horizontal row, TFT's shop bar. Each is something
  already in the Collection, at **20% off**. Rotates on the day boundary (`DayKey`).
- **Reroll is free and unlimited.** This is the deliberate break. TFT charges 2 gold;
  Finch's Mr. Prickles charges 10 stones and runs a 5-hour countdown (`08` in the
  reference set). Both are loss mechanics and both are out.
- **Lock a slot** — TFT's lock survives intact, because it is the one shop interaction
  that can only help you. It keeps that discount across a reroll and overnight.
- **No countdown.** "New picks tomorrow." Never `5:48:38`.
- **Nothing is exclusive.** Everything in the picks row is in the Collection at full
  price, always. A reroll can never cost you a thing you wanted.
- **Honesty panel** instead of TFT's odds table: one short screen saying how the picks
  are chosen and that nothing ever leaves.
- Sections under the picks: **Kin**, **Scenes**.

## 5. Care row — the Finch/Webkinz half

Three taps under the stage that cost nothing and pay nothing: **Pet**, **High five**,
**Snack**. They fire the animations that already ship — `delight`, `wave`, `bounce`.
Unlimited, always available, no cooldown.

Hard rule: **no meter.** No hunger, no energy, no mood that decays, no "your kin misses
you". Finch gates adventures behind energy; we refuse that. The kin is never unwell,
never hungry, never disappointed. Right now you cannot touch your pet at all, which is
the largest single miss on this screen.

## 6. Together since — the part only this app can do

Webkinz hands you an adoption certificate. We can fill one in with real work, because
`Ledger.entries` are dated and typed:

> **Moss** · Slime · adopted 12 August
> 23 days together · 41 assignments finished · 6 h 20 m focused · 9 lessons read

Every counter only goes up and none of them ever reset. The only new stored field is
`adoptedAt` per owned kin. This is the emotional payload of the whole tab and it is why
the pet is worth having in a school app rather than a game.

## 7. Naming

Copy Finch's flow almost exactly (`01`): a big field, a **Shuffle** die for a suggested
name, and the line *You can change this later*. Trigger it right after a purchase, on the
same screen as the arrival celebration. The name then replaces the species name in the
Home speech bubble, in Ask Kin, and on the adoption card. The tab stays "Kin".

## 8. Refusals, in one place

- No hunger, energy or mood meter. Nothing decays.
- No countdown timers in the shop.
- No paying to reroll, and no random pulls, loot boxes or duplicate-shards.
- No padlocks and no `?` mystery tiles. An unowned kin is drawn, named and priced.
- Nothing time-limited or exclusive. No FOMO.
- Nothing sold that protects you from a punishment, because there are no punishments.
- No real money anywhere. Coins are earned by finishing, never by grade.

## 9. Data model deltas this implies

Small, and all additive:

- `ChibiSpecies` gains `tier: Int` and grows to ~7 entries.
- `OwnedChibi` gains `name: String` and `adoptedAt: Date`.
- `GameState` gains `shopPicks: [String]`, `shopPickDay: DayKey`, `lockedPick: String?`.
- `Ledger` needs no change; the together-since numbers are derived from `entries`.

## 10. Open, deferred to a later pass

- Hats and held items. The kin is a smooth blob with no joints (see the `slime-is-a-blob`
  rule) — anything worn has to sit on the antenna or float, never break the silhouette.
- Room decorating / props in a scene. Webkinz and Club Penguin's core loop, and a whole
  placement editor. Not this pass.
- New kin **species art**. Ember, Droplet and Sprout are recoloured slimes today. Real
  distinct silhouettes are asked for in the brief as flat vector proposals; faces stay
  code-drawn from the nine approved set, and George approves them as art before they ship.
