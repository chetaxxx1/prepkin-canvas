# Prompt for Claude Design — Prepkin Canvas, Games tab

**How to use:** attach `design/screenshots/04-games.png` and `design/screenshots/09-dailyword.png`,
paste everything below, send.

---

These are real screenshots from my SwiftUI iPhone app, Prepkin Canvas. Both are built and
running. I want the **Games tab** redesigned. Keep the structure recognisable so I can port
it back into SwiftUI.

## What the app is

A companion app for high school students. A slime chibi lives on the home screen like
Finch's bird. Real Canvas LMS assignments sync in as tasks. Finishing daily tasks — school
work and life care — earns coins. Coins upgrade the chibi (3 levels) and buy new chibi
species and new room scenes.

Games is one of five tabs. Today it holds one playable game (Daily Word, a 5-letter,
6-guess word game worth 30 coins once a day), one locked game, and a leaderboard.

## Rules you must not break

- Coins pay for **finishing** things, never for grades or for correct answers.
- The chibi is a companion, never a meter. It is never sad, starved, or punished. Losing
  the daily word means no coins — never a guilt screen.
- iPhone, 390x844pt. Never draw a fake iOS status bar or a fake keyboard.
- The mascot is finished art and must be reproduced exactly, never redesigned. Soft
  dome/bell body, droplet antenna leaning right, two stubby mitten arms, pale oval belly
  patch low on the front. No neck, no legs, no outline, no shading, no texture — flat
  vector only. Exact palette: body `#51CFA0`, belly `#B1EDD4`, ink `#101820`. Four approved
  faces: idle (round dot eyes + small crescent smile), deadpan, judging (half-lidded),
  delight (closed happy arc eyes + open mouth). Levels: Lv1 small plain, Lv2 bigger +
  blush, Lv3 biggest + small gold crown.
- **No emoji anywhere.** Every icon must be a drawn vector in the palette below. The
  current screen uses 🟩 and ⚔️ and that is the single biggest problem with it.

## Design tokens already in the code — keep these

bg cream `#FAF5EC` · card `#FFFFFF` · ink `#2E2822` · warm gray `#988D80` · muted `#B4A996`
· inactive icon `#C9BEAC` · hairline `#F0E9DC` · checkbox border `#E5DDD0` · coral action
`#FF6F61` (soft `#FFE9E5`, icon `#FF8A7E`) · mint success `#57C79B` (soft `#E3F6EE`, dark
`#2E8C68`) · coin `#FFC24B` (border `#E8A62E`, soft `#FFF3D6`, dark `#B07A1A`) · blush
`#FF9E94`.

Rounded friendly type, weights 700/800/900. Radii: cards 20–22, hero 24–28, buttons 18–22,
tiles 14, pills 999. 24pt screen margins, 20pt list gutters.

The navigation is settled — keep it. A floating bottom bar: a dark ink capsule holding 5
filled icons (house, clock, gamepad, book, people) with a coral rounded-square badge behind
the active one, plus a separate circular mascot avatar button to its right that opens Shop.
Content fades under it with a cream scrim. The bar hides on pushed sub-screens, so the
Daily Word screen has no tab bar.

## What is on the Games tab today, and everything wrong with it

Reading `04-games.png` top to bottom: a large "Games" title, a Daily Word card, a locked
Versus card, a leaderboard card, then a third of a screen of nothing.

1. **Emoji as icons.** 🟩 renders as a flat green square that matches nothing in the
   palette. ⚔️ renders as gray metallic swords. Replace both with drawn icons.
2. **A third of the screen is empty** below the leaderboard.
3. **The screen never says whether you already played today.** The app knows this. The card
   says "+30 coins" whether the coins are still there or already claimed.
4. **Nothing accumulates.** Daily Word is a daily ritual with no streak, no history, no
   "you have solved 4 this week". There is no reason to come back tomorrow rather than
   Thursday.
5. **Roadmap jargon is on screen.** "needs friend sync (M2)" and "Sample data until friend
   sync lands." A student should never read either sentence.
6. **The leaderboard is unreadable at a glance.** It shows "2/6", "3/6", "4/6", "5/6" with
   no label. Fewer guesses is better, so rank 1 has the *smallest* number, which reads
   backwards for half a second every time.
7. **The locked card carries too much weight.** It is the second thing on the page and it
   is a dead end — a padlock with nothing to do.
8. **The mascot never appears.** Games is the only tab with no character on it, and it is
   the tab that should feel most like play.
9. **The page is thin.** One real game, and the layout does nothing to make that one game
   feel like the point.

## What actually exists in the code, so you design something buildable

Real, available today:
- whether today's word was solved and the coins claimed (a boolean)
- how many words were solved this week, plus tasks done, focus minutes, lessons, and coins
  earned this week
- the coin balance
- the active mascot's species, level and colour

Not real yet:
- **Friends and their scores are mock data.** There is no friend sync, so the leaderboard
  is invented names. Design it as if it were real; I will wire it later.
- **There is no streak.** If you design one, I will add the state to store it. Same for
  anything like "best guess count" or a played-days calendar — design it and say so, and I
  will build the storage.

Do not invent new games. Versus is the one planned second game; anything else is scope I
am not adding.

## What I want back

**One artboard: the Games tab, redesigned.** Make Daily Word the point of the page. Show it
in the state where it has not been played yet — that is the state that matters.

Then **a second artboard of the same screen after the word is solved**, so I can see what
changes: the reward is gone, something took its place, and the page still feels finished
rather than spent.

Solve these specifically:
- What replaces the empty third of the screen. Prefer better rhythm and a larger mascot
  presence over inventing new content.
- How a streak or a week's history reads without turning the page into a dashboard.
- How the leaderboard says who is ahead and why, in one glance, with a label on the number.
- How a locked game sits on the page without dominating it.
- Drawn icons for Daily Word and Versus in the palette.
- Student copy. No milestones, no "sync", no engineering words.

**If you have room, a third artboard: the Daily Word screen itself** (`09-dailyword.png`).
Its problem is the ~350pt gap between the last row of the grid and the keyboard. It needs
something in that gap — a result banner, a streak line, a "next word in 6h" — plus keys
tinted by letter state once you start guessing. Design the keyboard's *shape and colours*
but do not draw an iOS system keyboard; this one is drawn by the app.

Cozy and calm, not gamified-noisy — Finch meets a clean planner. The mascot should be the
only saturated thing on any UI surface. Tell me what you changed and why.
