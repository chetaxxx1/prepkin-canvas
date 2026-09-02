# Prompt for Claude Design — Prepkin Canvas, Learn v2 (micro-lessons)

**How to use.** Attach these, then paste everything below the line.

*Reference app (Imprint), 17 frames in flow order — `design/reference/imprint/`:*
`01-home-feed` · `02-lesson-preview-sheet` · `03-tap-zones-tutorial` ·
`04`–`08-figure-build-1…5` · `09-example-card` · `10-key-idea-card` ·
`11-saved-cards-empty` · `12-me-profile` · `13-course-map` · `14-achievements` ·
`15-learning-levels` · `16-explore` · `17-explore-cards`

*My app as it is today — `design/screenshots/`:*
`01-home.png` (the system, at its best) · `05-learn.png` (the screen being replaced) ·
`10-lesson.png` (the reader being replaced)

---

I'm rebuilding the Learn tab of my SwiftUI iPhone app, Prepkin Canvas, as a
micro-lesson reader. The 17 Imprint frames are the reference for the *format*. The 3
screenshots are my app — the visual system stays mine. Give me one artboard per screen
below, in my system, not in Imprint's.

## What the app is

A companion app for high school students. A slime chibi lives on the home screen like
Finch's bird. Real Canvas LMS assignments sync in as tasks. Finishing daily tasks —
school work and life care — earns coins. Coins upgrade the chibi and buy new chibi
species and room scenes. There are six tabs: Home, Focus, Games, Learn, Friends, Kin.

Learn today is a flat list of lessons grouped by track, and a lesson is a plain white
card in a system page-view with a centred paragraph and an emoji. It is the least
finished screen in the app. See `05-learn.png` and `10-lesson.png`.

## Rules you must not break

- Coins pay for **finishing** things, never for grades and never for correct answers. A
  right answer earns nothing extra. Finishing the lesson pays.
- **No streaks, no "1 day to complete", no challenge that resets to 0/3.** Imprint does
  all three (`14-achievements`). We refuse them. A quiet day is a quiet day. Any counter
  you show must be one that can only go up — "8 lessons this month".
- The chibi is a companion, never a meter. Never sad, starved, or punished. Quitting a
  lesson halfway is fine and silent — no confirm dialog, no guilt.
- iPhone, 390x844pt. Never draw a fake iOS status bar and never a fake keyboard.
- **No emoji anywhere.** Every icon is a drawn vector in the palette. The current Learn
  screen uses 💸 🧾 🏛️ 🤔 🧠 as track icons — that is the specific thing I want killed.
- The mascot is finished art and must be reproduced exactly, never redesigned. Soft
  dome/bell body, droplet antenna leaning right, two stubby mitten arms, pale oval belly
  patch low on the front. No neck, no legs, no outline, no shading, no texture — flat
  vector only. Exact palette: body `#51CFA0`, belly `#B1EDD4`, ink `#101820`. Nine
  approved faces, drawn by code, never invented: idle, deadpan, judging, delight, sleep,
  surprised, sad, focused, wink. Levels: Lv1 small plain, Lv2 bigger + blush, Lv3
  biggest + small gold crown.

## Design tokens already in the code — keep these

bg cream `#FAF5EC` · card `#FFFFFF` · ink `#2E2622` · warm gray `#96877F` · muted
`#B4A996` · hairline `#F0E9DC` · coral action `#FF6F61` (soft `#FFE9E5`, deep `#E4735F`)
· mint success `#57C79B` (soft `#DFF3E9`, dark `#3E9E78`) · coin `#FFC24B` (border
`#E8A62E`, soft `#FFF3D6`, dark `#A8761D`) · blush `#FF9E94`.

Rounded friendly type (Nunito), weights 700/800/900. Radii: cards 20–22, hero 24–28,
buttons 18–22, tiles 14, pills 999. 24pt screen margins, 20pt list gutters.

Navigation is settled: a floating bottom bar — dark ink capsule, filled icons, coral
rounded-square behind the active one, plus a circular mascot avatar button to the right
that opens Shop. Content fades under it with a cream scrim. The bar **hides** on the
track map and inside a lesson.

## The one licensed exception: figure colour

My UI is deliberately low-chroma and the mascot is normally the only saturated thing on
screen. Lesson **figures** get an exception, the same way room scenes do — a diagram
needs more colour than cream and coral can give. Imprint's figures are loud purple and
pink (`04`–`08`); mine should be warmer but just as confident.

Figures are flat vector on a white card. 2pt ink outline `#2E2822`. **At most three
fills per figure**, from: slime `#51CFA0` · sky `#9BC8F2` · lavender `#C3B2F0` · coin
`#FFC24B` · coral `#FF6F61` · leaf `#A5CE6B`, over paper `#FAF5EC`. No gradients, no
drop shadows, no 3D, no photography.

## The mechanic I am copying, and it is the whole point

**One figure per lesson that accretes across the cards.** Look at `04` → `05` → `06` →
`07` → `08` in order. It is one iceberg the whole time. Card 1 shows it bare. Card 2
adds the word UNCONSCIOUS. Card 3 adds a CONSCIOUS pill and a leader line. Card 4 adds a
pink PRECONSCIOUS band. Card 7 adds a SUPER-EGO wedge inside it. Eight cards, one
drawing, each card revealing one more layer.

Design every figure as **named layers with a stated reveal order**, because that is what
I have to build. Don't hand me eight separate illustrations.

## Screens I want back

### 1. Learn (tab root) — replaces `05-learn.png`

Top to bottom:

- **Continue** — the deck you're partway through, thin progress bar. Show the state
  where it exists; note in a caption what the screen looks like when it doesn't.
- **Because of your week** — 1–2 lessons chosen from the student's *real* Canvas
  assignments. "Bio quiz Friday → How to study for a science quiz." This is the reason
  this tab lives inside this app instead of being Imprint. Make it look like it knows
  something. If Canvas isn't connected the section is absent — never an empty state.
- **Today's card** — one lesson picked for today, +20 coins.
- **Tracks** — cards with a drawn icon and a progress ring (3 of 8). Current tracks:
  Personal finance, Philosophy, Study skills. Design the icons.
- **Saved cards** — entry to the review deck.

### 2. Track map — new, pushed, tab bar hidden

Compare `13-course-map`. Vertical path, 6–10 nodes alternating left and right. Done =
mint with a check. Current = coral, larger, with the slime sitting beside it. Locked =
cream circle with a dot — **no padlocks**, a padlock reads as a wall. No "Unit 1 / Unit
2" headers; a track is one run. Ends in a track badge you keep.

### 3. Lesson preview sheet — new

Compare `02-lesson-preview-sheet`. Figure or cover art, track pill, title, "What you'll
learn" in about three lines, "3 min · 8 cards · +20 coins", one big Start button. I want
to know the size of the commitment before I commit.

### 4. Lesson card — the core, replaces `10-lesson.png`

Full bleed, no tab bar. X on the left, a thin segmented progress bar, no title. Figure
takes about half the height. Body copy below it is **2–4 short lines, left aligned**,
19–20pt — my current version centres a paragraph and it reads badly. Bottom: a soft pill
row (save ♡, share, flag) and an **Ask Kin** button on the right — my version of
Imprint's ASK, and it should carry the mascot, not a generic sparkle.

Give me **four states of this card**, which are the four card types:

- **figure card** — figure at reveal step 3 of 5, so I can see the accretion.
- **key idea card** — no figure. A "Key Idea" label, one all-caps sentence in a tinted
  card, slime peeking in from an edge. Compare `10-key-idea-card`. This is the card
  people screenshot; make it worth screenshotting.
- **example card** — mostly text, one small drawn spot illustration. Compare
  `09-example-card`, which is the weakest thing in Imprint — a card with nothing on it.
- **check card** — one recall question with three answer choices, and the answered state
  showing the explanation. Getting it right earns no coins. Never a red X, never a wrong
  buzzer; a wrong pick just quietly shows the right one and why.

Plus the **tap-zone coach overlay** shown once on first lesson (compare
`03-tap-zones-tutorial`) and the **finish card** — "Finish · +20 coins", slime
celebrating, coins flying to the coin chip.

### 5. Saved cards — new

Compare `11-saved-cards-empty`. Hearted cards become a review deck. Give me the filled
state and the empty state. The empty state should teach the gesture, the way Imprint's
does, without sounding like a tooltip.

## Also invent, inside the same system

**Lesson complete → what next.** Imprint dumps you back to a course map. I want one
warm screen: what you just learned in one line, the coins, and exactly one forward move
— next lesson, or a 15-minute focus session on the assignment this lesson was picked
for. One choice, not a menu.

## Sample content to lay out

Use a real lesson from my catalogue so the copy is honest, not lorem:

> **Why compound interest wins** — Personal finance
> 1. Compound interest means you earn interest on your interest. Money grows faster the
>    longer it sits.
> 2. $1,000 at 8% a year. Year 1 you earn $80. Year 2 you earn $86 — because now the $80
>    is earning too.
> 3. The rule of 72: divide 72 by the rate to see how many years it takes to double. At
>    8%, that's 9 years.
> 4. **Key idea:** starting at 18 instead of 28 can roughly double what you end up with.
>    Time matters more than amount.

The natural figure is a stack of coins, or two curves, that grows a layer per card.
Design it as layers and name them.

## What I want back

One artboard per screen and state above. Then, in text: the reveal order for the
compound-interest figure, layer by layer, and the drawn icons for the three tracks.

Cozy and calm, not gamified-noisy — Finch meets a clean planner. Imprint is the format
reference and nothing else; it is white, clinical, and has no character in it at all.
Mine has a slime, and the slime is why anyone opens the app. Tell me what you changed
and why, per screen.
