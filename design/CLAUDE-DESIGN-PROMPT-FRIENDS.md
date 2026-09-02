# Prompt for Claude Design — Prepkin Canvas, Friends tab

**How to use.** Attach the files listed below, then paste everything under the line.

*My app as it is today — `design/screenshots/`:*
`01-home.png` (the system, at its best — match this) ·
`06-friends.png` (the screen being replaced) ·
`02-focus-ready.png` + `03-focus-running.png` (the focus timer I am making social) ·
`09-dailyword.png` (the daily word game) · `04-games.png`

*Reference frames, already pulled from Mobbin into `design/reference/` — 62 PNGs:*
- **`finch/`** (15) — Tree Town in six states, the friend card, the Good Vibes picker,
  Goal Buddy, the add-friend sheet. `05-tree-town-empty-slots` is the nearest existing
  thing to my screen 1.
- **`instagram/`** (11) — the stories tray, and the viewer with its segmented progress
  bar and reaction bar.
- **`together/`** (9) — Forest's Plant Together: create/join a room, a room code, the
  join-by-code error, the invite picker, and Forest's friends-vs-global focus ranking.
  This is the mechanic behind my screen 7.
- **`leaderboard/`** (5) — including `01-mimo-weekly-league-REFUSE`, which is exactly the
  league-with-a-countdown pattern I am refusing. Look at it, then don't do it.
- **`friendcode/`** (4) — four takes on "here is your code, copy or share it".
- **`dolphin/`** (18) — cut from my own screen recording of Dolphin SAT. Read its
  README. Short version: Dolphin has **no friends list and no feed** — its social layer
  is a league, a streak, and a pet. `05-league-demotion-zone-you-29th` shows a real user
  sitting inside a red DEMOTION ZONE at rank 29. That is the screen I am refusing, and I
  want you to look at it before you design screen 8.

---

I'm rebuilding the Friends tab of my SwiftUI iPhone app, Prepkin Canvas. Finch,
Instagram and Dolphin are references for **mechanics**, not for looks. The visual system
stays mine — see `01-home.png`. Give me one artboard per screen and state listed below,
drawn in my system.

## What the app is

A companion app for high school students. A slime chibi lives on the home screen like
Finch's bird. Real Canvas LMS assignments sync in from a Chrome extension and become
today's tasks, next to life-care tasks. Finishing tasks earns coins. Coins upgrade the
chibi and buy new chibi species and room scenes. Six tabs: Home, Focus, Games, Learn,
Friends, Kin. There is a focus timer where the slime naps beside you, and a daily
Wordle-style word game.

Friends today is a story ring, a "this week's coins" leaderboard, and a flat list of four
names — generic social furniture bolted onto a pet app. See `06-friends.png`. Replace it.

## The one idea, and everything follows from it

A friends tab in a companion app should answer **"who's around right now, and can I sit
with them?"** — not "who's winning."

The mascots are the social object. I want to see my friends' **slimes**, not their
numbers. The feature I most want people using every day is sitting down to work at the
same time as someone else.

## Rules you must not break

- **Coins pay for finishing things.** Never for grades, never for correct answers, never
  for beating a friend. A shared focus session pays exactly what a solo one pays.
- **No streaks. No leagues that demote you. No countdown to losing something.** Dolphin
  does all three, and `dolphin/05-league-demotion-zone-you-29th` is what it looks like on
  a real account: a red DEMOTION ZONE bar with the user highlighted inside it, after a
  week that earned 22 XP. `dolphin/10-progress-streak-calendar` is the streak on day one —
  "1 Day streak", "Longest streak 0 days". Any number on my tab must only go up.
- **Never pay for being right.** Dolphin's pet quests pay XP for "Answer 5 questions
  correctly" (`dolphin/17-pip-quests`). We pay for finishing, full stop.
- **Nobody's mascot is ever punished** — not mine, not a friend's. There is no "Maya
  hasn't studied in 5 days", no wilting, no grey slime. A quiet friend is simply not on
  screen today, with no explanation offered.
- **No free text anywhere in this tab.** No DMs, no comments, no captions, no custom
  status. Every message a student can send is picked from a fixed set of drawn cards.
  This is deliberate: these are 15–18 year olds, and removing the text box removes
  bullying and moderation from the product. Design around it — do not sneak in a
  "say something…" field.
- **No camera, no photo upload.** "Stories" here are auto-generated from what the person
  actually did in the app.
- iPhone, 390×844 pt. Never draw a fake iOS status bar and never a fake keyboard.
- **No emoji anywhere.** Every icon is a drawn vector in the palette.
- The mascot is finished art and must be reproduced exactly, never redesigned. Soft
  dome/bell body, droplet antenna leaning right, two stubby mitten arms, pale oval belly
  patch low on the front. No neck, no legs, no outline, no shading, no texture — flat
  vector only. Exact palette: body `#51CFA0`, belly `#B1EDD4`, ink `#101820`. Friends'
  slimes are the same shape in other species colours: pink `#F7A8B8`, sky `#9BC8F2`,
  lavender `#C3B2F0`, leaf `#A5CE6B`. Nine approved faces, never invented: idle, deadpan,
  judging, delight, sleep, surprised, sad, focused, wink. Levels: Lv1 small plain, Lv2
  bigger + blush, Lv3 biggest + small gold crown.

## Design tokens already in the code — keep these

bg cream `#FAF5EC` · card `#FFFFFF` · ink `#2E2622` · warm gray `#96877F` · muted
`#B4A996` · hairline `#F0E9DC` · coral action `#FF6F61` (soft `#FFE9E5`, deep `#E4735F`)
· mint success `#57C79B` (soft `#DFF3E9`, dark `#3E9E78`) · coin `#FFC24B` (border
`#E8A62E`, soft `#FFF3D6`, dark `#A8761D`) · blush `#FF9E94`.

Rounded friendly type (Nunito), weights 700/800/900. Radii: cards 20–22, hero 24–28,
buttons 18–22, tiles 14, pills 999. 24pt screen margins, 20pt list gutters. The UI is
deliberately low-chroma — the mascots are the only saturated things on screen, which is
what makes four different species colours read at a glance.

Navigation: the six-tab bottom bar from `01-home.png`. It **hides** inside a moment
viewer and inside a live study room.

## Identity — settled, design to it

No accounts, no email, no phone number. A student's whole profile is a **friend code**
(8 characters, format `XXXX-XXXX`, alphabet excludes I, O, 0, 1), a display name they
type, and their slime. Codes get shared by text or in person, exactly like Finch's.
There is no search, no "people you may know", no contacts upload.

## Screens I want back

### 1. Empty state — no friends yet

**Design this one first and hardest.** Every real user sees it before they see anything
else, and my app does not have it at all. It must teach the friend code, make the tab
look worth filling, and not read like an ad for having friends. My slime is alone in the
Yard (screen 2) and that should be fine, not sad.

### 2. Add a friend

My code, big, tappable to copy, with a Share button. A field for theirs. What a good code
and a bad code look like.

### 3. Request received

Their slime, their name, Accept / Ignore. Ignoring is silent and tells them nothing.

### 4. The Yard — the top of the populated tab

This is my Tree Town (`ref/finch/`). One illustrated scene, full width, with my friends'
slimes standing around in it — reusing my room-scene art system, so it is a **place**,
not a row of avatars. Four to six slimes fit comfortably; show me what eight looks like.
A friend who is in a live focus session right now wears the `focused` face and reads as
busy. A friend who hasn't opened the app today is simply not there — no ghost, no grey.
Tapping a slime opens screen 9.

### 5. Today — the moment row

Instagram's stories tray (`ref/instagram/`), directly under the Yard. Unseen gets a coral
ring, seen goes hairline. But there is no camera: each card is generated from what the
person did — "focused 45 min", "solved the word in 3", "finished Compound interest",
"4 tasks done". Give me the row, and note in a caption what it looks like with one item
and with twelve.

### 6. Moment viewer

Full bleed, tab bar hidden, thin segmented progress bar at the top like Instagram. Their
slime big, the one thing they did, the time. Across the bottom, a **fixed reaction row**
of drawn vectors — no keyboard, no reply field. Give me two states: fresh, and after I
have reacted. Sending a reaction pays **me** 2 coins, once per friend per day — Finch
pays you for kindness and that is the right instinct. Receiving one pays nothing.

### 7. Study Together — this is the new thing, give it the most room

My Focus tab is a solo timer where my slime naps next to me (`02-`, `03-focus`). Make it
social. Three artboards:

- **Invite** — pick a friend or open a room, pick a length, what you're working on.
  Compare Forest's `together/06-forest-create-room-invite` and its room code in `02` —
  but calmer. This is co-working, not a match.
- **Live room** — the strongest screen in the set. Two to four slimes sitting in one
  scene, one shared timer, everyone's face `focused` or `sleep`. **No chat.** Show what
  happens when someone leaves early: they are just gone, no notification, no shame.
- **Finished** — both people get the same coins. Nobody won.

### 8. This week, together

Replaces the "this week's coins" leaderboard in `06-friends.png`. The **default** is a
group total, not a ranking: "you and 4 friends — 41 tasks, 6h focus, 12 lessons". Design
that card. Then design the alternate ranked board as a second artboard, ranked on **focus
minutes rather than coins** (ranking the currency makes people grind for money instead of
for work), with no demotion and no reset-to-zero. Compare Dolphin's league — mine should
feel like a group photo, not a ladder. Tell me which one you'd ship.

### 9. Friend card

Tap a slime. Their name, their slime at its real level, what they did today in one line,
and two buttons: **Send a vibe** and **Study together**. A quiet overflow menu holds
Remove, Block, Report. Design the menu — safety controls in a teen app should be easy to
find and undramatic to use.

### 10. Send a vibe

Finch's Good Vibes as a picker. **Six drawn cards** — design them and name them. Things
like a wave, a cup of tea, "you've got this", "good luck tomorrow". Warm, specific, and
sendable to a stranger without meaning anything weird. One per friend per day, and the
one-a-day limit should feel like a nice constraint, not a paywall.

### 11. Daily Word — friends strip

My app has a daily Wordle (`09-dailyword.png`). Add a friends strip. **Two states:**
before I have solved today's word, when I can see *that* Maya solved it but not how; and
after, when I see everyone's guess-count and the shape of their grid. Wordle's real
social feature was the shared grid — steal it, without the emoji squares.

### 12. Same class — the thing only my app can do

The Chrome extension knows my real Canvas courses. If two friends share one, say so:
"You and Josh both have BIOL 12 — Quiz 3, Friday." Design that card, where it sits, and
the opt-in toggle that turns it on per course (off by default — this is real personal
data). Make it look like the app knows something, not like it is watching.

### 13. Privacy & safety sheet

One row per thing a friend can see — what I did today, my focus sessions, my word result,
my courses — each switchable. Plus block list and report. Sensible-by-default, plainly
worded, no dark patterns. This screen is the one a parent might read.

## Also invent, inside the same system

- **The "nobody is around" state of the Yard** — I have friends, but none of them are
  active today. This will be the most common state on a Tuesday morning and it must not
  feel like a dead room.
- **The first-friend moment** — someone accepts. One warm beat, once.

## Sample data to lay out — use this, not lorem

- You: **Pip**, slime green, Lv 2, code `K4RT-9BXM`. 3 of 5 tasks done, 25 min focused.
- **Maya** · pink · Lv 3 · focused 45 min today · in a live session until 4:15
- **Josh** · sky · Lv 1 · solved the word in 3 · shares BIOL 12 with you
- **Ava** · lavender · Lv 2 · finished the lesson "Why compound interest wins"
- **Sam** · leaf · Lv 1 · 4 tasks done
- Week together: 41 tasks · 6h 20m focus · 12 lessons · 5 people

## What I want back

One artboard per screen and state above. Then, in text: the six vibe cards named and
described, the reaction set for the moment viewer, and your call on screen 8 — group
total or ranked board — with the reason.

Cozy and calm, not gamified-noisy. Finch meets a clean planner. Instagram's mechanics
without Instagram's anxiety, and none of Dolphin's streak pressure. Tell me what you
changed and why, per screen.
