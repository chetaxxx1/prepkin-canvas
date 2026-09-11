# Prompt for Claude Design — Kin: the fish's own page

**Rewritten 2026-09-11.** The version before this asked for a TFT shop and four new
kin silhouettes. All of that shipped (`design/handoff-kin/`, `BUILD-NOTES.md`) and the
mascot changed underneath it: the kin is **Sprout, a fish in a tank**, not a slime.
This brief is about the Kin tab as a pet's home, and it folds in the two star-up frames
(`1o` / `1p`) that the old STARUP brief owed, so that file is gone.

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the
line. Attach `design/screenshots/kin-redesign-2026-09-11/light-kin.png` (the tab as
built from this brief's code half), `light-wardrobe.png`, `light-card.png`, and
`design/handoff-kin/Kin Tab.dc.html` + `README.md` (the first Kin handoff, for the level
to match).

---

I'm redoing the **Kin** tab of Prepkin Canvas. Kin is the mascot's own page: Sprout in
the tank, and everything about it. Until today it was a tank on top and a stack of six
cards under it (care, Wardrobe, Saved looks, Season, Together, Collection), which reads
as settings, not as a pet's home. George's call on 2026-09-11: study the apps with a
real mascot page, Finch first, then the avatar and room editors, and copy the best of
them mechanic for mechanic.

Half of this is already in code (see *What is built*). Draw the whole tab anyway, so
the built half and the owed half come from one hand.

## What Kin is, in code today

- `ios/Sources/KinView.swift` — the tab. A 430pt stage (the owned tank plate, the kin
  as a still, a speech bubble, a name plate with star pips, a friendship word), care
  buttons on the water's bottom edge, a row of doors, a Season row.
- `ios/Sources/WardrobeEditor.swift` — the Wardrobe editor. Live web tank on top
  (`SproutView`, it takes `?costume=` and `?tank=`), a sheet under it with tabs
  Costume / Coat / Scene, a 3-column grid, a saved-looks row, Done.
- `ios/Sources/KinCardSheet.swift` — the Card: the adoption certificate kept current,
  the friendship stage, the friend code, three only-up numbers, the Firsts list, Share.
- `ios/Sources/Core/Friendship.swift` — five stages that only go up.
- `ios/Sources/Core/Firsts.swift` — things that happened once and stay.
- `ios/Sources/Core/Costumes.swift` — 19 costumes, ids, names, coin prices. Stage III
  only; a one- or two-star kin owns them and shows them once it grows.
- `Theme.swift` `Scene0.all` — five tanks: Lagoon (free), Reef 200, Kelp 220, Dusk
  250, Deep 280 (dark).
- The Shop and the Collection are unchanged and are not in this brief. The Shop's
  `TankTile` (every card is your own Home with one thing changed) is reusable as is.

## The references, and what to take from each

Open every link and look before you draw. Take the mechanic, never the look.

**A. The pet page is the house, not a list.** Finch's home and "Lee" tab: the bird
stands in its own room with a speech bubble; one band of chrome, the rest is the room.
[Home](https://mobbin.com/screens/18d270f7-7eb4-448f-a928-174b4a7a7aa3),
[Lee](https://mobbin.com/screens/d8ce4c68-ad5c-4400-a957-10a4d8befa2f).
Ours: the tank fills the top of the tab, the kin in whatever it is wearing, the name
plate and stars over the water, the bubble. Everything else opens from doors under the
tank, not from cards.

**B. The doors.** Finch's Bag: one sheet, four big tiles (Mail, Outfits, Furniture,
Colors), plus tiles for things not reached yet.
[Bag](https://mobbin.com/screens/0f312de8-00a7-4902-9e42-630a60c7006f).
Ours is a row of four doors under the tank, always all four, never a "?": **Wardrobe,
Decorate, Collection, Card**. Each opens an editor or a sheet.

The care buttons live **inside the scene, on the bottom edge of the water**, the way
Abode puts feed / clean / play inside the pet's room:
[Abode](https://mobbin.com/screens/df4dc946-060d-45cd-b5da-9c35cfbdee68). Take the
placement. Never the heart and mood meters above it.

**C. The editor shape.** Instagram's avatar editor: live preview on the top half, a
bottom sheet with a tab strip, sub-tabs, a 3-column grid with the price or "Free"
under each tile, one Done button.
[Style](https://mobbin.com/screens/e9d99b09-8296-4bb7-a36c-b5e76271e1b9),
[Face](https://mobbin.com/screens/387fd81d-fbe7-4c04-8885-dbd1403e105f).
Finch's closet is the same shape with a silhouette icon per category and a **NONE**
tile first: [Closet](https://mobbin.com/screens/3fba181d-6016-4ac6-a28d-bf43f367ab4a).
Ours: Wardrobe opens this editor with the tank as the live preview, tabs **Costume /
Coat / Scene**, the None tile first, owned tiles tappable, unowned tiles at full colour
with the coin price (never dimmed, never a lock), a saved-looks row.

**D. Decorate.** Replika's room: the room on top, tabs, a grid of props with a
"Purchased" badge:
[Replika](https://mobbin.com/screens/31058bb0-c060-435d-b030-caaae13e3c78). Tolan's
planet: tap a slot, a ring shows where the thing will stand, pick from a tray below:
[Tolan](https://mobbin.com/screens/1483da96-7cb5-46f9-b33f-095364d075c7).
Ours: **two prop slots per tank**, left and right, inside the window every tank plate
keeps clear (plate fractions x 0.212 and 0.788, feet at y 0.765, a prop at most 0.34 of
the plate tall). Tap a slot, the ring appears, pick a prop from the tray. A prop is a
cut-out PNG placed at a slot, never a new painting.

**E. The card.** Finch's pet profile: portrait, name and pronouns, AGE / FRIENDSHIP /
HUMAN / FRIEND CODE as label-value rows, three little growth stats, share top right:
[Profile](https://mobbin.com/screens/b2af9c62-89dd-42c0-8704-94fa5e5483ba).
Ours: the Card door opens the adoption certificate that already exists
(`AdoptionCard`), kept current: name, "Day 12 together", stars, the friendship stage,
the friend code, three only-up numbers (finished together, lengths swum, lessons read),
the Firsts list, and Share. The share image is the kin on its tank plate at story size.

**F. The friendship ladder.** Finch's friendship level sheet: "You and Lee are Buddies.
Increase your friendship level by consistently checking in, chatting and petting Lee."
[Sheet](https://mobbin.com/screens/b2af9c62-89dd-42c0-8704-94fa5e5483ba). Ours: five
named stages that only go up, earned by days together and care taps, never lost, never
a bar. The stage sits under the name plate as a word; the card explains it in one line;
a change is a quiet toast. No level number, no points, no progress bar.

**G. Firsts.** Finch's quests list, without the hints and without the counts:
[Quests](https://mobbin.com/screens/2180f7a4-b1a4-4615-8e1d-4d97d458de9b). Ours: a short
list on the card of things that happened once and stay: first costume, first scene,
first friend, first shift, three stars. Done ones show the date. Undone ones show the
words. Never a "?", never "3/5".

**H. A tankmate, later.** Finch's micropet egg hatches after N goals:
[Egg](https://mobbin.com/screens/08078a81-0ffb-4dab-b3da-b3d810bf56ac). Ours would be a
small second creature in the tank (a snail, a shrimp) after seven finished Canvas
tasks. Written down in `design/KIN-PLAN.md` section 11. **Not in this brief. Do not
draw it.**

**Deliberately not copied:** hunger, happiness or energy meters (Abode, Pou, BitePal);
"?" tiles anywhere (Finch's Bag, Duolingo ABC); XP numbers and skill bars (Ahead, Life
Reset); a text chat with the pet (Abode, Tolan, Replika); personality quizzes; day and
night as a purchase.

## Rules specific to this brief

- **No meter of any kind.** Nothing decays. The kin is never hungry, sad or waiting.
  Sprout does not eat; "Snack" is a care tap, not feeding.
- **Care is free and unlimited.** Pet, High five, Snack pay nothing and cost nothing.
  Coins come from finishing Canvas work, never from care.
- **Every number only goes up.** Days together, the three card numbers, the friendship
  stage. Never a bar, never a percentage, never a "to next level".
- **No padlocks, no "?" tiles, no dimming.** An unowned costume is drawn at full colour
  on the student's own kin with its coin price. Nothing costs anything but coins; the
  Plus looks (when art exists) sit in the same grid with the word Plus where a price
  would be, previewed on an example fish, never on the student's own.
- **The kin is never drawn by you.** Dashed box labelled KIN, coat and star count in a
  caption. The bare stage II still is the stand-in in any composite; never a costume
  still.
- **The band is 430pt tall and that number is George's.** The kin's drawn size in it
  is also his. Lay out around them; do not resize either.
- **The page owns the fish's safe area**, not Swift. In the editor's live preview he
  swims where the web page lets him; nothing may be laid over the middle of the water.
- Copy: plain, warm, no exclamation marks, no engineering words. Every string on one
  line, under 40 characters. The kin is named by its real name.
- The tab keeps the coin chip where Home keeps it (top right, y 64, 18pt gutter).
- Light only. Dark is a queued handoff (`CLAUDE-DESIGN-PROMPT-DARK-PAPER.md`).

## Artboards

### 1. The tab

402×874. From the top:

1. **Stage, 430pt**, the owned tank plate fitted to the width, its floor colour
   continuing under it, bottom corners 28pt. Coin chip top right (`WalletChip`, with
   the bag). Down the middle, bottom-aligned: the speech bubble, the name plate, the
   friendship word, the KIN (dashed box, 212pt wide, three-star coral in a costume for
   this frame), and nothing under him but water.
2. **Care, on the bottom edge of the water.** Three round buttons (`CareButton`, 60pt
   circle, label under) whose circles straddle the water's bottom edge, half in and
   half on the paper: Pet, High five, Snack. Free. No counter, no cooldown, no meter.
3. **Four doors**, one row, equal width, 18pt gutter, 10pt gaps. Each a white tile
   (`Radius.card`), a 44pt tinted circle with a drawn icon, the word under it:
   **Wardrobe** (coral tint), **Decorate** (mint), **Collection** (lilac), **Card**
   (gold). Draw the four icons as flat vectors in the icon set's language
   (`design/icons/`); SF Symbols stand in today.
4. **Season row**, one row, white tile: season name, "3 of 21 days claimed", and a
   date pill "Ends Oct 12". A date, never a clock. Tapping opens the existing
   `SeasonCard` as a sheet.
5. 90pt clear above the tab bar.

Two states on this artboard: a settled kin (three stars, a costume on, day 12,
Buddies), and **first run** (one-star mint, day 1, Just met, no coins). First run adds
one quiet line under the care row: "Free, unlimited, always. No cooldown."

### 2. The Wardrobe editor, a costume selected

Full screen, no tab bar. Top half: the live tank (the student's own scene) with the
kin in the **selected** costume, `X` top left (44pt), **Done** top right (coral text,
44pt). Bottom half: a sheet (`Radius.sheet`, paper) with:

- a tab strip **Costume · Coat · Scene** (ink capsule for the selected one, white for
  the others, the pair Focus uses for its lengths);
- for Costume: the line "Costumes fit at three stars. Moss has 2." when the kin is
  under three stars, else nothing;
- a **3-column grid**, 10pt gaps. Tile 1 is **None** (a plain paper tile with the
  word). Then the 19 costumes, cheapest first, each tile the student's own kin wearing
  it (a KIN box, 3 stars, that costume), the name under, and under that either
  nothing (owned) or the coin price in `KinCostBadge` (unowned, full colour). The worn
  tile has a 2pt mint ring. A selected-but-unowned tile has a 2pt ink ring and the
  preview above puts it on;
- when an unowned costume is selected, a footer: coral button **"Wear it · 300"**
  (coin disc before the number), or when short the mint `AffordPanel`: "120 to go",
  "280 of 400", the bar, "That's 4 more assignments finished." Never greyed, never red;
- the **saved-looks row** at the bottom: "Saved looks", chips of each saved look
  (kin in that costume, name under), and a **Save look** button. At the free limit the
  button reads "More saves · Plus".

Coat tab: one tile per kin in the catalogue, owned ones named and tappable (the active
one ringed mint), unowned ones at full colour with their price; tapping an unowned one
opens the existing kin sheet. Scene tab: one tile per tank, the plate cropped into the
tile, name under, price under that when unowned; the equipped one ringed mint.

### 3. The Decorate editor, a slot ring open

Same shell as artboard 2. Top: the tank with the kin. Two slot marks on the floor at
plate x 0.212 and 0.788, feet at y 0.765. The left one is **open**: a 2pt white ring
(with a soft ink shadow so it reads on Lagoon and on Deep) the size the prop will
stand. Bottom: a tray, one row, scrolling: **None** first, then the props for this
tank, each a cut-out on a paper tile with its name and coin price when unowned. The
kin never moves for this; he is behind the props in paint order.

State the ring's motion: scale 0.9 → 1.0, 180ms, ease-out, with a 40% opacity pulse
once. Reduce Motion: the ring appears at rest.

### 4. The Card, with Share

A sheet at 0.92 height, paper `#F1EADC`. The certificate card (`AdoptionCard`, 26pt
corner, tier stripe on top) kept current:

- "CERTIFICATE OF ADOPTION"
- the KIN (176pt, level and costume as owned)
- the name (32pt black; 24 when longer than ten characters)
- tier plate · species name (only when the name is not the species name)
- star pips (19pt)
- a hairline
- "Adopted 12 August 2026"
- "Day 12 together"
- **Friendship:** the stage word in a glass pill, "Buddies", then one line under it:
  "Days together and care move this up."
- **Friend code** as a label-value row when one exists: "Friend code · ABCD-1234"
- three numbers in a row: **41** "finished together" · **18** "lengths swum" · **9**
  "lessons read". Empty ones print an em dash in `#DDD3C4`, never a zero.
- "They fill in on their own. Never down."
- **Firsts**, five rows: "First costume", "First scene", "First friend", "First
  shift", "Three stars". A done row has a mint dot and the date on the right ("2 Sep").
  An undone row is the words in `muted`, nothing on the right. A done row whose date is
  not known (a save older than the list) shows the dot and no date.
- footer: "Prepkin Canvas" · "No. 003"

Under the card, one coral button **Share**, full width. Tapping it opens the system
share sheet with the story image.

**The story image**, 1080×1920, built and in `design/screenshots/kin-redesign-2026-09-11/story-card.png`:
paper, the tank plate as a whole 4:3 card (1000×750, 56pt corner) rather than
bled to the edges — a 9:16 crop of a 4:3 painting cuts both props off, the one thing
every plate is composed to keep — the kin standing on its floor in its costume (the one
place the KIN box is large: about 560pt of the 1080), the name plate with stars over the
water, "Day 12 together" under the card, the friendship word under that, and a small
"Prepkin Canvas" wordmark at the bottom. No coin count, no numbers other than the day.
Draw it as its own artboard beside the sheet and improve it; the built one is a first cut.

### 5. The friendship stage toast

The tab (artboard 1) with the `KinToast` over it, 104pt above the bottom, mint dot:
"You and Moss are Buddies now." One line, dark glass, no button, gone after 2.4s.
Show the five words as a small table beside it, with when each arrives, so the caption
can be checked against the code:

| Stage | Arrives | With care |
|---|---|---|
| Just met | day 1 | — |
| Tankmates | day 3 | 12 care taps bring it to day 1 |
| Buddies | day 14 | up to a month earlier |
| Besties | day 60 | up to a month earlier |
| Old friends | day 180 | up to a month earlier |

Every four care taps count as one day, at most thirty days in all, so care moves the
early stages and time moves the late ones. Nothing moves a stage down.

### 6. The tab at accessibility-XL

Artboard 1 with the reading sizes at the app's cap (1.3× — `Theme.font` caps the
system size there; display sizes do not grow). Show what wraps: the door labels, the
Season row, the care labels. Nothing on the stage grows; the chips and the plate use
`fixedFont`. The doors may go to two rows of two before a label truncates.

### 7. Star-up 1★→2★ (the old `1o`)

Full screen over the equipped tank, no tab bar. Before / land / settled as three
frames on one artboard with the timing under each. Your own spec from the first
handoff, held to: the second pip lands with two concentric coin-tinted rings behind it
(52 / 38pt at 22% / 34%); the pip scales 1.4 → 1.0 over 260ms while the kin plays
`bounce`. The cost is reported after the fact in a quiet `coinSoft` pill ("100 spent"),
never confirmed beforehand, and the next star's price stays visible so the ladder does.
CTA **Nice** (quiet). Copy names the kin.

### 8. Star-up 2★→3★ (the old `1p`)

Same three frames. The only moment on the tab with gold rings and coin-coloured
confetti; brief, and it must read on Deep (dark) too, so show one dark-tank variant.
The 3★ reveal is the **Sprout evolution itself** (the long fins), not a hat: the old
line "Moss wears the crown" is gone. Write the replacement; it closes the loop and
teases nothing. CTA **Show me** (coral). Include the sheet as it looks the moment you
return (pips updated, the "250 spent" pill, the button gone and the line that says this
is the last one), and both moments as a single Reduce Motion still.

Rules for 7 and 8: paid before it plays, never a confirm step inside the celebration,
never a "not enough coins" version of these screens, no Share here, nothing about a
next tier or the shop.

## Every string

Tab: "Moss is around." · first run "This one is yours. It's free." · care bubbles
"Moss leans into it." / "Nailed it." / "Crunch." · care "Pet" "High five" "Snack" ·
"Free, unlimited, always. No cooldown." · doors "Wardrobe" "Decorate" "Collection"
"Card" · Season row "{name}" "3 of 21 days claimed" "Ends Oct 12" · rename alert
"Name your kin" / field / "Save" "Cancel" / "You can change this any time."

Friendship: "Just met" "Tankmates" "Buddies" "Besties" "Old friends" · toast "You and
Moss are Buddies now." · card line "Days together and care move this up."

Wardrobe: "Costume" "Coat" "Scene" · "None" · "Costumes fit at three stars. Moss has
2." · "Wear it · 300" · "120 to go" "280 of 400" "Nothing here expires." · "Saved
looks" "Save look" "More saves · Plus" · "Name this look" "Save" "Cancel" · toasts
"Moss is wearing the Ninja" "Reef is your scene" "Look saved." · "Done"

Decorate: "None" · "Left slot" "Right slot" (accessibility) · "Done"

Card: "CERTIFICATE OF ADOPTION" · "Adopted 12 August 2026" · "Day 12 together" ·
"Friend code" · "finished together" "lengths swum" "lessons read" · "They fill in on
their own. Never down." · "Firsts" · "First costume" "First scene" "First friend"
"First shift" "Three stars" · "Prepkin Canvas" "No. 003" · "Share"

## What I want back

Eight artboards, in my visual system (paper `#F8F8F8`, white cards with a hairline,
coral `#FF6F61` for the one primary action, SF Pro Rounded, the five radii). Then, in
text: the four door icons as flat vectors, the ring motion, the story image's exact
type sizes, and per artboard what you changed from the built screenshots and why. List
every Mobbin screen you leaned on under **References**.
