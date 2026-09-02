# Reference frames — Kin design pass (Mobbin, 2026-08-31)

16 PNGs, 299-wide phone frames with a Mobbin footer band. Pulled by Claude from the
Mobbin MCP. The prompt in `design/CLAUDE-DESIGN-PROMPT-KIN.md` refers to these by number.

Frames `20`+ are reserved for George's own captures — TFT, Webkinz Next and Club Penguin
are games and are not in any UI library. See "Still to capture" at the bottom.

## Finch — `01`–`08`. The closest fit to what we are building.

- **`01-finch-name-your-bird`** — "What do you want to name your baby birb?", a text
  field, a **Shuffle** button, and the line *You can change this later*. This is the
  exact model for our name sheet, reassurance line included.
- `02-finch-closet-items` / `05-finch-closet-shoes` — the closet: pet on top in its
  colour field, a horizontal category rail of drawn icons, a 3-up item grid. **NONE** is
  always the first tile — an un-equip that is not a delete.
- `03-finch-outfit-sets` — saved outfits, and the top-right **Shop** door icon. Note the
  three floating buttons on the right edge for room / outfit / heart.
- `04-finch-equipped-toast` — "Equipped Purple Lifeguard Top" as a dark toast at the
  bottom. No modal, no confirm.
- `06-finch-gift-picker` — currency chip top-right, and a footer line that prices the
  action before you take it: *Sending a gift will cost 200*.
- `07-finch-empty-visit-shop` — an empty closet category that becomes an ad for the
  shop rather than an apology.
- **`08-finch-mr-prickles-shop`** — the most important frame in the set. A rotating
  3-item shop with tier-coloured card frames, a **50% OFF** hero, a currency chip, and a
  shopkeeper who talks. It is also where Finch does the two things we refuse:
  *Items refresh: 5:48:38* (a loss countdown) and *Spent 10 stones to refresh today's
  shop items* (paying to reroll).

## Shops — `09`–`13`.

- `09-replika-clothes-shop` — full-body avatar above, priced item grid below, category
  tabs pinned to the bottom. Coin badge sits **on** each item, bottom-left.
- `10-forest-tree-store` — Classic / Exclusive / Sound tabs, big art cards, price under
  the name. Calm and un-gamified; the closest thing to our tone.
- `11-discord-shop-featured` — a featured collection banner above a horizontal card
  rail. Good model for "today's picks" as a *spotlight*, not a slot machine.
- **`12-mimo-store-REFUSE`** — kept so the refusal is concrete. Mimo sells *7-Day
  Challenge*, *Double XP* and *League Protection*. We sell nothing that protects you
  from a punishment, because we have no punishments.
- `13-alan-avatar-picker` — priced avatars in a grid, the equipped one ringed, cheaper
  tiers first. Shows a price ladder reading as progression.

## Collection and locked states — `14`–`16`.

- `14-numo-locked-ladder` — a **Locked** section on a vertical ladder. Characters stay
  fully visible and in colour; only the number rail greys out.
- **`15-lifereset-locked-grid-REFUSE`** — 45 black tiles with `?`. You cannot want what
  you cannot see. Our unowned kin are always drawn and always priced.
- **`16-withings-locked-badges-REFUSE`** — padlock icons on blurred cards. The Learn
  pass already banned padlocks; this is why.

## Still to capture (George)

Number these `20`+ in this folder. None are on Mobbin.

1. **TFT mobile, shop row** — the 5-unit bar: cost badge, tier-coloured name plate,
   trait row, the Reroll button, the lock, and the level/odds panel. 3–4 stills.
2. **TFT, star-up moment** — a unit going 2-star, and the star pips over the head.
3. **TFT, Little Legends / collection** — the cosmetic grid with rarity frames.
4. **Webkinz Next** — the pet dock, KinzCash header, and the adoption certificate.
5. **Club Penguin (Journey or an archive video)** — the clothing catalog page turn.

A phone screen recording, then stills, is fine — that is how `dolphin/` was made.
