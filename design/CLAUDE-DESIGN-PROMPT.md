# Prompt for Claude Design — Prepkin Canvas polish pass

**How to use:** attach the 10 screenshots in `design/screenshots/` (they are numbered in
flow order), paste everything below, send.

---

These are real screenshots from my SwiftUI iPhone app, Prepkin Canvas. Everything here is
built and running — I want a polish pass on the visual design, not a rebuild. Give me one
artboard per screen, redesigned, keeping the structure recognisable so I can port your
changes back into SwiftUI.

## What the app is

A companion app for high school students. A slime chibi lives on the home screen like
Finch's bird. Real Canvas LMS assignments sync in as tasks. Finishing daily tasks — school
work and life care — earns coins. Coins upgrade the chibi (3 levels) and buy new chibi
species and new room scenes.

## Rules you must not break

- Coins pay for **finishing** things, never for grades or for correct answers.
- The chibi is a companion, never a meter. It is never sad, starved, or punished. Ending a
  focus session early just means no coins — never a guilt screen, never a confirm dialog.
- iPhone, 390x844pt. Never draw a fake iOS status bar or a fake keyboard.
- The mascot is finished art and must be reproduced exactly, never redesigned. Soft
  dome/bell body, droplet antenna leaning right, two stubby mitten arms, pale oval belly
  patch low on the front. No neck, no legs, no outline, no shading, no texture — flat
  vector only. Exact palette: body `#51CFA0`, belly `#B1EDD4`, ink `#101820`. Four approved
  faces: idle (round dot eyes + small crescent smile), deadpan, judging (half-lidded),
  delight (closed happy arc eyes + open mouth). Levels: Lv1 small plain, Lv2 bigger +
  blush, Lv3 biggest + small gold crown.

## Design tokens already in the code — keep these

bg cream `#FAF5EC` · card `#FFFFFF` · ink `#2E2822` · warm gray `#988D80` · muted `#B4A996`
· inactive icon `#C9BEAC` · hairline `#F0E9DC` · checkbox border `#E5DDD0` · coral action
`#FF6F61` (soft `#FFE9E5`, icon `#FF8A7E`) · mint success `#57C79B` (soft `#E3F6EE`, dark
`#2E8C68`) · coin `#FFC24B` (border `#E8A62E`, soft `#FFF3D6`, dark `#B07A1A`) · blush
`#FF9E94`.

Rounded friendly type, weights 700/800/900. Radii: cards 20–22, hero 24–28, buttons 18–22,
tiles 14, pills 999. 24pt screen margins, 20pt list gutters.

The navigation is settled — keep it on every screen. A floating bottom bar: a dark ink
capsule holding 5 filled icons (house, clock, gamepad, book, people) with a coral
rounded-square badge behind the active one, plus a separate circular mascot avatar button
to the right of the capsule that opens Shop. Content fades under it with a cream scrim.
The bar hides on pushed sub-screens and during a running focus session.

## The screens, and what I already know is weak

1. **01-home** — the strongest screen; refine only, don't restructure. The scene art is a
   purchasable background and the mascot stands in it.
2. **02-focus-ready** — weakest screen in the app. Enormous dead space, a system stepper
   that looks nothing like the rest of the app, no sense of what you're focusing *on*. I
   want a real ring/dial, the task you're working on, and the reward stated before you
   commit.
3. **03-focus-running** — same problems. The 💤 is a blue system emoji that fights the
   palette; replace it with drawn marks. No progress indication at all right now.
4. **04-games** — generic cards; the leaderboard is an afterthought. Daily Word should feel
   like the daily ritual it is.
5. **05-learn** — uses emoji as category icons (💸 🧾 🏛️ 🤔 🧠). Replace with drawn SVG
   icons in the palette. Tracks need stronger grouping and a sense of progress.
6. **06-friends** — stories row, weekly coin leaderboard, friend list. All sample data.
7. **07-shop-buddies** and **08-shop-scenes** — flat grid of near-identical cards. I want it
   to feel like a buddy locker, not a catalogue: lead with a big hero for the buddy you
   actually own, then buddies, then scenes. Locked species should be silhouettes with
   "???" so there's something to want.
8. **09-dailyword** — huge dead gap between the grid and the keyboard. Needs a result
   banner, a streak or "next word in" line, and keys tinted by letter state.
9. **10-lesson** — a plain card in a system page-view. Should feel like one calm idea at a
   time, with page dots and a clear "Finish · +20 coins" only on the last card.

## What I want back

One artboard per screen above, plus these three that don't exist yet and that I'd like you
to invent inside the same system:

- **Weekly summary** — the week's numbers (tasks, focus minutes, words, lessons, coins), a
  "chibi moment" card with one warm sentence, and a Share button. A slow week must read as
  a *lighter week*, never as failure.
- **Connect Canvas** — three numbered setup steps (install the Chrome extension, log into
  Canvas, enter a pairing code), a large dashed pairing-code card, and a ghost "I'll do
  this later". Skipping must feel completely fine.
- **Story viewer** — full screen, segmented progress bars, a friend's mascot celebrating
  one big stat, and a "Send a cheer…" input.

Cozy and calm, not gamified-noisy — Finch meets a clean planner. The mascot should be the
only saturated thing on any UI surface; the room scenes are the one exception.

Where a screen has real dead space, prefer better rhythm and a larger mascot presence over
inventing new content. Tell me what you changed and why, per screen.
