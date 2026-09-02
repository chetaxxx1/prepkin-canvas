# Handoff: Prepkin Canvas — Friends tab

> **Changed after delivery (2026-08-31).** `Slime.dc.html` shipped as a hand-redrawn
> approximation of the mascot — wrong proportions, a fin instead of the droplet antenna,
> and arms as separate stuck-on ellipses. It has been **regenerated from the app's real
> traced art** by `tools/gen_slime_component.py`, which reads
> `design/canvas/mascot-paths.json` (body, belly, the 4 traced faces) and ports the 5
> parametric faces from `ios/Sources/SlimeView.swift`. Species colours now come from
> `Theme.species()` with the belly derived by `Slime.belly(for:)` — a 57% blend toward
> white, mint keeping its exact `#B1EDD4`. See `mascot-before-after.png`.
>
> The component contract is unchanged (`face` / `level` / `species`), so all 27 artboards
> pick it up. `screens/` holds the re-rendered PNGs; `render-screens.sh` redoes them.
> Every mascot value in the *Mascot* section below is superseded by the generator.
>
> | species | body | belly |
> |---|---|---|
> | green | `#51CFA0` | `#B1EDD4` |
> | pink | `#F7A8B8` | `#FCDAE0` |
> | sky | `#9BC8F2` | `#D4E7F9` |
> | lavender | `#C3B2F0` | `#E5DEF9` |
> | leaf | `#A5CE6B` | `#D8EABF` |

## Overview

Rebuild of the **Friends** tab of Prepkin Canvas, a SwiftUI iPhone companion app for high
school students. Friends today is a story ring, a "this week's coins" leaderboard and a flat
list of four names — generic social furniture on a pet app. This replaces all three.

The tab answers one question: **"who's around right now, and can I sit with them?"** — not
"who's winning". The mascots are the social object; the feature we want used daily is sitting
down to work at the same time as someone else.

27 screens and states are specified here. Finch, Instagram and Dolphin were references for
mechanics only; the visual system is Prepkin's.

## About the design files

The files in this bundle are **design references created in HTML** — prototypes showing
intended look and behaviour, not production code to port.

The target is the existing **SwiftUI iPhone app**. Recreate these screens in SwiftUI using the
app's established patterns and its existing colour/type definitions. Every value below is in
**points at 390×844** so it maps directly onto SwiftUI layout.

Open `Friends v2.dc.html` in a browser: 27 artboards on one canvas in two turns — turn 2
(top) is scale + notifications, turn 1 is the core tab. Each artboard has a caption saying what
changed and why. Artboards are referenced below by the ids shown as badges (`1a`, `2c`…).

## Fidelity

**High fidelity.** Final colours, type, spacing, radii and copy. The Yard scene art is the one
placeholder: flat bands and circles standing in for the real room-scene art system (see
*The Yard scene*).

---

## Non-negotiable product rules

Product rules, not styling preferences. An implementation detail must never break one.

1. **Coins pay for finishing.** Never for grades, never for correct answers, never for beating
   a friend. A shared focus session pays exactly what a solo one pays. The only social payout
   is 2 coins to the **sender** of a vibe or reaction; receiving pays nothing.
2. **No streaks, no leagues that demote, no countdown to losing something.** Every number on
   this tab can only go up. Nothing resets on Monday.
3. **Nobody's mascot is ever punished** — not yours, not a friend's. No wilting, no grey
   slime, no "Maya hasn't studied in 5 days". A quiet friend is simply not on screen, with no
   explanation offered.
4. **No free text anywhere in this tab.** No DMs, comments, captions or custom status. Every
   message is picked from a fixed set of drawn cards. This removes bullying and moderation
   from the product; do not add a "say something…" field for any reason.
5. **No camera, no photo upload.** Moments are generated from what the person did in the app.
6. **No emoji.** Every icon is a drawn vector.
7. **No fake status bar, no fake keyboard.** Artboards leave the top 46–52pt clear.
8. **No search, no contacts upload, no people-you-may-know.** A friend code is the only way in.

---

## Design tokens

| Token | Hex | Use |
|---|---|---|
| bg cream | `#FAF5EC` | screen background |
| card | `#FFFFFF` | cards, sheets, pills |
| ink | `#2E2622` | primary text, tab capsule, "you" chip |
| warm gray | `#96877F` | secondary text, section labels |
| muted | `#B4A996` | tertiary text, chevrons, "not yet" |
| hairline | `#F0E9DC` | borders, dividers |
| coral | `#FF6F61` | primary action, unseen ring, active tab |
| coral soft / deep | `#FFE9E5` / `#E4735F` | reason strips, never-push panel / warnings, Report |
| mint / soft / dark | `#57C79B` / `#DFF3E9` / `#3E9E78` | valid, done, in-a-session, progress |
| coin / border / soft / dark | `#FFC24B` / `#E8A62E` / `#FFF3D6` / `#A8761D` | coin glyph, coin pills |
| blush | `#FF9E94` | mascot cheeks (Lv2+) |

Also used: `#EFE7D9` switch-off track and unfilled segment · `#DDD2C0` unselected radio, dash ·
`#E0D4C0` dashed placeholder rings · `#E6DECF` word-grid miss tile · `#F5EFE3` neutral pill ·
`#7C6F68` secondary body on white · `#FFF6EF` text/glyph on coral and on ink · `#CFC3B2`
placeholder code text.

**Type** — Nunito, weights 700/800/900.

| Role | Size / weight / line-height |
|---|---|
| Screen title | 30 / 900 / 1.0, tracking −0.01em |
| Sheet or celebration headline | 27 / 900 / 1.2 |
| Moment headline | 32 / 900 / 1.15 |
| Room timer | 72 / 900 / 1.0, tracking −0.02em |
| Friend code (hero / inline) | 36 / 900 / 28 / 900, tracking .07em |
| Card title | 19 / 800 / 1.3 |
| List row name | 15.5–16 / 800 |
| Body | 14.5–15 / 700 / 1.5 |
| Section label | 11.5 / 800, tracking .10em, uppercase, warm gray |
| Name pill in the Yard | 10.5–11 / 800 |
| Meta / caption | 12–13 / 700 |

**Radii** — cards 20–22 · sheets/hero 24–28 · buttons 18–22 · tiles 12–15 · pills 999 ·
artboard frame 38. **Margins** — 24pt screen margins, 20pt card gutters.
**Shadows** — only where something floats: `0 4px 16px rgba(46,38,34,.08)` on a card over a
scene, `0 -6px 30px rgba(46,38,34,.22)` on the bottom action sheet. Flat elsewhere.

---

## Mascot ("Kin", the slime)

Finished art. **Reproduce exactly, never redesign.** `Slime.dc.html` is the reference
implementation; port it as a SwiftUI `Path` set or a vector asset.

- Soft dome/bell body, droplet antenna leaning right, two stubby mitten arms, pale oval belly
  patch low on the front. No neck, no legs, no outline, no shading, no texture. Flat vector.
- Geometry (100-unit box, viewBox `0 -9 100 109`): arms = ellipses at (14,66) and (86,66),
  rx 11 ry 9, **behind** the body · antenna =
  `M50 22 C48 12 54 0 62 -1 C67 6.5 60 14 56 22 Z`, behind the body · body =
  `M50 12 C33 12 22 26 20 46 C18 62 14 74 22 82 C30 90 70 90 78 82 C86 74 82 62 80 46 C78 26 67 12 50 12 Z` ·
  belly = ellipse (50,71) rx 17 ry 12.
- **Species colours** (body / belly): green `#51CFA0` / `#B1EDD4` · pink `#F7A8B8` / `#FBD3DB` ·
  sky `#9BC8F2` / `#CDE2F8` · lavender `#C3B2F0` / `#DFD7F7` · leaf `#A5CE6B` / `#D2E7B5`.
  Species is identity: it is how you recognise a friend at a glance, and it never changes.
- **Nine approved faces, never invented:** idle, deadpan, judging, delight, sleep, surprised,
  sad, focused, wink. Exact paths in `Slime.dc.html`. Faces used here: `focused` (in a live
  session), `sleep` (in a room, resting), `delight` (celebration), `wink` (greeting), `idle`
  (everything else). **`sad` is never used in this tab.**
- **Levels:** Lv1 small plain · Lv2 + blush ellipses (26,60)/(74,60) rx 5.5 ry 3.5 `#FF9E94`
  @85% · Lv3 + small gold crown `M31 14 L34 5.5 L39 11 L44 3 L49 11 L54 5.5 L57 14 Z` fill
  `#FFC24B`, **no stroke**. See *Open questions* on level and size.

## Identity — settled

No accounts, no email, no phone number. A student's profile is a **friend code** (8 characters,
`XXXX-XXXX`, alphabet excludes I, O, 0, 1), a display name they type, and their slime. Codes are
shared by text or in person. Sample: you are **Pip**, green, Lv 2, `K4RT-9BXM`.

Sample cast used throughout: **Maya** pink Lv3 (focused 45 min today, in a session until 4:15) ·
**Josh** sky Lv1 (solved the word in 3, shares BIOL 12) · **Ava** lavender Lv2 (finished a
lesson) · **Sam** leaf Lv1 (4 tasks done).

## Navigation

The six-tab floating bottom bar from the existing Home screen (`TabBar.dc.html` is a reference
redraw): ink `#2E2622` capsule inset 22, bottom 26, height 62, radius 999; five 23pt filled
glyphs in 46pt slots; active slot has a coral rounded square r15, active glyph `#FFF6EF`,
inactive `#8B7F79`; to its right a 62pt circular mascot avatar (cream, 3pt white ring) that
opens Shop. Content fades under it with a 170pt cream scrim.

**The bar hides** inside a moment viewer (`1i`, `1j`) and inside a live room (`1l`, `1m`).

## Shared patterns

Build these once.

- **Artboard frame** — 390×844, `#FAF5EC`, radius 38, `overflow: hidden`.
- **The Yard scene** — inset 16, `top:100`, height 330 (290 on sheets), radius 28.
  Layers bottom-up: sky `#E4EDF7`; sun circle 50pt `#FFF3D6` at right 34 / top 26; hill
  `#D6E7C8` as a band from `top:130`, height 300, radius `200px 200px 0 0`, bled 30pt past both
  edges; ground `#C6DCB4` from `top:232`, height 120; two bush circles `#B9D3A6` (42pt left 18 /
  top 198, 32pt right 20 / top 210). **This is a placeholder for the real room-scene art
  system** — the layer order (sky, hill, ground, props, slimes front-to-back by depth row) is
  what matters. Daytime/quiet variant lightens to `#E9EFF8` / `#DAE9CD` / `#C9DEB7`.
- **Name pill** — white, r999, padding 2–3 / 9–11, 10.5–11 / 800. Yours is ink with `#FFF6EF`
  text and reads "Pip · you".
- **Coin chip** — white pill, 1.5pt `#F0E9DC` border, r999, padding 7/13/7/9, 19pt coin glyph
  (circle r8.2 fill coin, 1.6pt `#E8A62E` stroke) + value 15/800.
- **Avatar circle** — 38–46pt, cream or white fill, `overflow: hidden`, slime inset ~8pt and
  offset down 5–7pt so the crop sits under the chin.
- **Bottom sheet** — full width, radius `28 28 0 0`, white, 44×5 `#F0E9DC` grabber at top 12,
  over a `rgba(46,38,34,.45)` scrim.
- **Primary button** — 52–58pt, radius 18–22, coral, label 16–18 / 800 `#FFF6EF`.
  Disabled: `#F5EFE3` fill, `#C0B4A6` label. Pressed: coral darkens to `#E4735F`.
- **Switch** — 46×28 r999, on `#57C79B` / off `#EFE7D9`, 22pt white knob inset 3.
- **Moment ring** — 70pt circle; unseen 3pt coral border, seen 2pt `#F0E9DC`, add-slot 2pt
  dashed `#E0D4C0`. Name below, 11.5/800 (seen: 700 warm gray).
- **Segmented control** — white pill container padding 5, two 42pt halves r999; selected is ink
  with `#FFF6EF` label, unselected warm gray.

---

## Screens

### Getting started

**`1a` Empty state — no friends yet.** The screen every user sees first. Yard (290 tall) holds
only your slime plus **three dashed 62pt spot rings** — the room is already a place with room
in it, so nothing has to say "you have no friends". Headline "Room for four more out here."
22/800 at `top:412`; sub explains code-only identity. Code card (white r22, `top:540`): label,
code 28/900, then Copy (cream r16) + Share (coral r16) side by side. Outlined "Enter a friend's
code" at `top:700`. Tab bar visible.

**`1b` Add a friend.** Your code is the hero: white r24 card, code 36/900 centred, "Tap to copy"
12.5/700, full-width coral "Share my code". `or` divider. "Enter their code" field: 60pt, r18,
1.5pt hairline, placeholder `XXXX-XXXX` 22/900 in `#CFC3B2`; helper explains the excluded
letters. Add button inert (`#F5EFE3`) until 8 valid characters. Tab bar hidden.

**`1c` Code field — the three answers.** Good: 2pt mint border + mint check circle + "That's a
code. Send the request?" and a coral Send request button. Not a code: plain hairline field, one
coral-deep sentence naming the excluded characters — **no red border, no shake**. Already
friends: the friend's slime appears in the field and the helper names her.

**`1d` Request received.** Sheet from `top:334` over a dimmed Yard. Her slime 140pt at `wink`,
"Maya wants to join your yard" 23/800, then one line stating exactly what accepting shares.
Coral **Accept**; **Ignore** is a plain 15/800 warm-gray text button that sends nothing, tells
her nothing, and queues no reminder.

**`1h` First friend (once ever).** Yard 360 tall, both slimes at `delight` 104pt, a handful of
6–9pt confetti dots in species colours. "Maya moved in." 27/900, one line of what happens next,
coral **Say hi** (routes into the vibe picker), quiet "Later".

### The tab root

**`1e` The Yard + Today.** Header "Friends" 30/900 with a bell and a plus (38pt white circles).
Yard 330 tall with 5 slimes: sizes 58–74 by depth row, you largest (90pt) front-centre. Maya
carries face `focused` **and** a mint chip "Maya · in a session" — that pairing is the only
"busy" signal. **TODAY** label at `top:448`, moment row at `top:478`: 70pt rings, 14pt gaps,
unseen coral / seen hairline, plus a dashed Add slot. Week card at `top:596`: label, three
numbers 24/900 (41 tasks · 6h 20m focus · 12 lessons), "You and 4 friends".
*One moment:* the row is that one ring plus Add. *Twelve:* scrolls horizontally, unseen first.

**`1f` The Yard at eight.** Eight is the comfortable ceiling: three depth rows (44–46pt back,
58–60pt middle, you 92pt front), **name pills drop out and appear on tap** — the slimes are
already identity, so labels become noise.

**`1g` Nobody around today (invented).** The most common state on a Tuesday morning. Palette
lightens to the daytime variant, two tiny white cloud dots, you alone. Absent friends leave
**no trace at all**. Today row holds your own moment (mint ring) plus one factual line: "You
focused 25 minutes. Sam and Maya were out here yesterday." One offer, `top:606`: "Quiet out
here today." + "Open a room and leave the door unlocked" + coral **Open a room**.

**`2a` The Yard with 15 active.** Eight drawn, overflow carried by a pill at the scene's
top-left: three 18pt species dots + "7 more out here" → opens `2b`. In-session friends take the
front row (three here, all `focused`), explained by one line under the scene.

**`2b` Everyone — the flat grid.** Back, "Everyone" 30/900, "15 friends · A to Z". The
"alphabetical, always" note sits **above** the grid; grid is 3 columns, 74pt avatar + name
12.5/800 + one of three states: "in a session" (mint 11/700), "today" (muted), "—" (`#DDD2C0`).
Never sorted by activity, coins or level. Scrolls under the tab-bar scrim; last cell is Add.

### Moments

**`1i` Moment viewer — fresh.** Full bleed, tab bar hidden, tinted to her species (`#FBEDF0`
with a `#F7DFE5` band from `top:300`, radius `300px 300px 0 0`). 4 segments 4pt at `top:50`,
first filled ink. Header row: 38pt avatar, name 15.5/800, time 12.5/700, ✕. Her slime 216pt at
`focused`. One fact: "Focused 45 minutes" 32/900 centred, sub 15/700. **Fixed reaction row**:
white 66pt pill, five 46pt cream circles, drawn vectors, 1.9pt ink strokes. Footer: "Sending one
pays you 2 coins · once a day each". **No reply field, no keyboard, nothing to type.**

**`1j` Moment viewer — reacted.** The sent reaction fills coral and grows to 52pt; the other
four drop to 35% opacity and are inert for the day. A `+2` coin chip appears top-right so the
payment is visibly yours. Footer turns mint: "High five sent · +2 coins". Her side shows the
reaction and pays her nothing.

**Reaction set** — five, fixed, in order: **Wave** (open hand) · **Warm** (heart outline) ·
**Nice one** (star) · **Brew** (mug) · **Take a breath** (leaf). Four are shared with the vibe
cards so students learn five shapes, not eleven. Warm is viewer-only — a heart is fine as a
reaction to something that happened and too loaded as a card you post at someone.

### Study Together — the new thing

**`1k` Invite.** "Same timer, same room. Pays the same as studying alone." **WHO**: 70pt friend
avatars, selected gets a 3pt coral ring; last slot is "Open room". **HOW LONG**: three r18 pills,
25 / 45 / 60, selected is ink. **ON WHAT**: radio rows built from **real synced Canvas tasks**
("Ch. 5 Problem Set · AP Physics · due Fri") plus "Just studying" — this is how the no-free-text
rule is kept while the room still has a subject. Button: "Ask Maya to sit down". **No countdown
to accept, no "challenge" framing.**

**`1l` Live room.** The strongest screen in the set. Cool scene (`#E8EEF6` / `#DCE6F2` /
`#D3DFEE`), tab bar hidden. Header: white pill with a mint dot + "3 in the room", ✕ to leave.
Shared timer 72/900 at `top:132`, "45 minutes · started 3:32", 6pt progress bar 37% mint. Three
slimes in one scene at `focused` or `sleep`, you largest front-centre. One white card lists what
everyone is on. Footer: "No chat in here. Just company." **No chat, no reactions, no blinking
presence dots.**

**`1m` Someone left early.** The identical screen with one fewer slime: count goes 3 → 2, Josh's
line drops out of the task card, and that is the entire event — no notification, no "Josh left",
no empty seat, no shame. He keeps the minutes he sat for.

**`1n` Finished.** Both slimes at `delight`. "45 minutes, together." 28/900. Two identical rows
(avatar, name, coin pill `+30`) separated by a hairline — same number, no ordering that implies a
winner — then "Same as focusing alone. Nobody won." Someone who left early gets coins for the
time they sat, on their own screen, with no comparison shown to anyone.

### Together, not ranked

**`1o` This week, together — the default.** Segmented [Together | Who did what], Together
selected. Hero card: five overlapping 38pt avatars (−10pt margin, 2.5pt white ring) + "5 of you";
**41** at 44/900 with "TASKS FINISHED"; then 6h 20m and 12 lessons at 26/900. Second card:
"TOGETHER TIME — you sat in a room with someone for **2h 10m** of that". Footer: "Adds up from
Monday. Nothing here resets, and no number can go down."

**`1p` Who did what — the alternate.** Deliberately the second segment. Ranked on **focus
minutes, never coins**. Rows r20, 11pt padding: plain numeral (no medals), 44pt avatar, name,
minutes 16/800; your row is mint-soft. Coin-soft note explains the minutes-not-coins choice.
Footer: "No promotion, no demotion, no reset."
**Recommendation: ship `1o` as the default and the only thing on the tab root, keep `1p` one tap
away.** With five friends a ranking has one winner and four people who lost to their friends,
and the person at the bottom is usually the one having the worst week. Retire the segment
entirely above ~8 friends (see *At scale*).

### Friend, vibes, safety

**`1q` Friend card + safety menu.** Sheet from `top:296` over a dimmed Yard. Her slime 150pt at
its real level, name 27/900, coin-soft chip "Lv 3 · pink slime", one line of what she did today,
then two equal-weight buttons: outlined **Send a vibe** and coral **Study together**. A
"What Maya can see" text link. `···` top-right opens a **full-width bottom action sheet** (inset
20, bottom 16, r22): Remove friend / "She isn't told" · Block / "Your code stops working for
her" · Report / "Goes to us, not to her" — plain words, each row stating the consequence, Report
the only coral thing in it. Safety must stay this easy to reach and this undramatic.

**`1r` Send a vibe.** Sheet from `top:158`. Header: her avatar + "Send Maya a vibe" 20/900 +
"One a day each · pays you 2 coins". 2×3 grid of 112pt cards, 32pt drawn glyph + name 14/800;
selected card is white with a 2pt coral border, others cream. Coral "Send Wave". Footer: "Six
cards, no typing. That's the whole vocabulary."

**The six vibe cards** — one per friend per day; sending pays the sender 2 coins.

| Card | Glyph | What it's for |
|---|---|---|
| Wave | open hand | "You exist and I noticed." The default, and what `1h` sends. |
| Brew | mug | Go make a tea. Care rather than encouragement, which matters at 11pm. |
| You've got this | peak | For the thing that hasn't happened yet. A hill, not a trophy. |
| Nice one | star | For the thing that already happened. Never mentions a number. |
| Take a breath | leaf | Permission to stop. The card that argues against the app. |
| Good luck tomorrow | crescent moon | Sent the night before a test. The moon means sleep, not study more. |

**`1v` Privacy & safety.** The screen a parent might read. Four switches, each with what is *not*
shared stated beside it: what I finished today (titles, never marks) **on** · my focus sessions
(minutes, and whether you're in one) **on** · my word result (after they've played) **on** · my
courses (names only, per course) **off**. Then Safety: Blocked · Report a problem · **Change my
code** (the nuclear option that quietly ends every connection). Footer: "There is no message box
anywhere in Friends, so there is nothing to moderate."

### The two app-specific screens

**`1s` Daily Word — before you've solved.** Your grid in progress (48pt tiles r12: right
`#57C79B`, close `#FFC24B`, miss `#E6DECF`, unplayed white + 2pt hairline). Friends card shows
only **that** someone solved it — mint check + "solved", or a neutral "not yet". Counts and grids
are withheld so the strip can't spoil the puzzle or set a bar before you start.

**`1t` Daily Word — after you've solved.** Each row gains a guess count 19/900 and the **shape**
of their grid as 12pt drawn tiles — Wordle's real social feature, in the app's three colours,
never emoji squares. Rows in **finishing order, not ranked**. A "share the shape" card copies it
as a small image and never reveals a letter.

**`1u` Same class + per-course opt-in.** The card only this app can show, and it sits **third**
— under the Yard and Today — so it reads as useful, not as surveillance. "You and Josh both have
BIOL 12." 19/800 + "Quiz 3 is on Friday for both of you." + his avatar and a coral **Study
together**. "Only the two of you see this match." Directly beneath: **MATCH ME ON THESE COURSES**
with a switch per course, **all off by default**; a match requires both students switched on.
Course names only — never marks, never work.

**`2c` Notifications (new).** "RIGHT NOW" card, the only one with an action: "Maya's room has a
free seat · 28 minutes left · with Josh" + coral **Sit down**. Then a TODAY list: vibe received,
code accepted, invite received. A coin-soft note states the whole push policy in one sentence.

---

## Push policy

**Pushes — four, and only four.** A friend invites you to study · a room you could join has a
free seat · a friend sends you a vibe · someone accepts your code. All four are a person doing
something *toward you*. Each is individually switchable; all four are silent 10pm–7am.

**Never pushes.** "You haven't studied today" · anything about a streak · a friend's score, rank
or level · "Maya finished 5 tasks — you've done 1" · a moment being posted · a vibe you failed to
send back · anything at all when you have been away. **A quiet week produces exactly zero
notifications. That is the feature.**

## Yard occupancy rule

Eight slots, recomputed hourly. Friends with **no activity today are never candidates**.

1. **In a session** — front row, largest, `focused` face. The only fact that earns a better
   spot, because it is an invitation rather than a score.
2. **Most recent** — active in the last hour, by recency. Middle row.
3. **Daily rotation** — remaining slots shuffle from everyone else active today, **seeded by the
   date** so the order is stable all day and different tomorrow. Stops the same four friends
   living permanently on stage.

Under eight active, everyone is drawn and the overflow pill is absent (the normal case).

## At scale — what changes past ~8 friends

- **Ranked board `1p`** — retire the segment. At 25 people it becomes the league we refused;
  the group total `1o` scales unchanged.
- **Paid vibes** — cap the payout at **3 vibes a day**, not one per friend. Extra vibes still
  send and still land warmly, they just pay nothing; otherwise 25 friends is 50 coins a day for
  tapping.
- **Same class `1u`** — collapse to one card per course ("3 friends in BIOL 12", three slimes,
  one button). Never one card per friend.
- **Today row `1e`** — scrolls, unseen first, caps at twelve; oldest unseen drop off silently
  rather than accumulating as an obligation.
- **Daily Word `1t`** — first five in finishing order, then "and 6 others solved it" as a plain
  line. No expansion, no full ranking.

## Interactions & behaviour

- **Tap a slime in the Yard** → friend card `1q`. **Tap a moment ring** → viewer `1i`.
  **Tap the week card** → `1o`. **Tap the overflow pill** → `2b`. **Bell** → `2c`.
- **Moment viewer** — advances on tap right / back on tap left, 4s auto-advance per moment;
  cross-fade 180ms. Reaction press: fill coral, scale 1.0 → 1.15 → 1.0 over 240ms, coin chip
  slides in from the top-right.
- **Vibe / reaction limits** — one per friend per day (payout capped per *At scale*). A used
  card is inert at 35% until tomorrow, never behind a padlock and never purchasable.
- **Live room** — join animates your slime walking in over 400ms; a leaver simply fades out over
  300ms with the count decrementing. No entry or exit toast, ever.
- **Leaving a room early** is silent and keeps your minutes. No confirm dialog.
- **Ignore / Remove / Block** never notify the other person. Block also invalidates your code
  for them.
- **Press states** — coral darkens to `#E4735F`; white cards go to 97% scale with no colour
  change.
- **Tab bar** hides with a 180ms slide-down entering a viewer or a room.

## State

- `friends: [Friend]` — code, display name, species, level, `lastActiveAt`, `inSessionUntil`,
  optional `sharedCourses`.
- `yardSlots` — derived hourly by the occupancy rule; the rotation seed is the local date.
- `moments: [Moment]` — auto-generated from finished tasks, focus sessions, lessons and word
  results; `seen: Bool` per viewer; expires after 24h; tray caps at 12.
- `reactionsSentToday: [friendId: ReactionKind]`, `vibesSentToday: [friendId: VibeKind]`,
  `paidSocialActionsToday: Int` (cap 3).
- `rooms: [Room]` — participants, `startedAt`, `lengthMinutes`, task per participant.
- `weekTotals` — tasks, focusMinutes, lessons, togetherMinutes; additive, never reset.
- `privacy` — 4 flags + `courseOptIn: [courseId: Bool]` (all false by default).
- `blocked: [code]`, `hasSeenFirstFriendMoment: Bool`, `pushPrefs` (4 flags + quiet hours).
- Coins are written **only** by finishing events and by the sender of a paid social action.

## Assets

- **Mascot** — from `Slime.dc.html`; existing app art is authoritative if it differs.
- **Icons** — all drawn vectors, all in the artboards: 5 reaction / 6 vibe glyphs, 5 tab glyphs,
  bell, plus, chevron, close, check, share, copy, flag, block, remove, people, play, coin.
  No emoji, no icon font.
- **The Yard scene** needs real art from the room-scene system in four variants: evening
  (default), daytime/quiet, celebration (`1h`), and the cool study-room palette (`1l`).
- No photography, no raster assets, no camera anywhere.

## Files in this bundle

| File | What it is |
|---|---|
| `Friends v2.dc.html` | All 27 artboards on one canvas, with per-screen captions. Open this first. |
| `Slime.dc.html` | The mascot: geometry, nine faces, three levels, five species colours. |
| `TabBar.dc.html` | Floating bottom bar reference redraw. |
| `support.js` | Runtime needed to open the HTML locally. Not part of the design. |

## Open questions for the designer

1. **Level is a visible ladder.** In the Yard, size carries both depth and level, and level comes
   from coins — so a Lv1 friend is drawn smaller than a Lv3 one, a ranking rendered as art in the
   one place that is meant to have none. Either cap the level-driven size range inside the Yard
   (keep the full range on Home, where it is only your own slime) or express level with the crown
   and blush alone and let size mean depth only. **Needs a decision before build.**
2. **Live-room task titles** are the only place a friend sees your Canvas task title. Either fold
   this into the "my focus sessions" privacy switch or default the room to "just studying" unless
   you opt in.
3. **"In a session until 4:15"** tells people when you will be free. Consider "in a session" with
   no end time.
4. Undesigned: how a study invite that is never answered appears (it cannot expire loudly);
   whether you can join a room after it starts; the notification-settings screen behind the link
   on `2c`.
