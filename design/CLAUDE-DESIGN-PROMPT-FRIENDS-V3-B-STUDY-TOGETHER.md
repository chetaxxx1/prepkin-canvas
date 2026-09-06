# Prompt for Claude Design — Friends v3, part B: Study Together

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the line.
Attach `design/screenshots/18-focus-shift.png` (the shift screen), `22-friends-v2.png`,
`design/handoff/focus-shift-van/focus-shift-van.html`, and `design/FRIENDS-PLAN.md`.
Reference frames: Forest "Plant together", Focusmate, Finch Goal Buddy, from
`design/reference/`.

---

**Study Together** is the reason the Friends tab exists: two to four kin work at the same
time, one timer, nobody can talk, everyone gets their own coins at the end. It is the one
thing in this app that actually helps a 17-year-old finish a problem set. Nothing of it
is built or drawn yet.

## What exists in code

- Focus is a **shift**: the kin drives a delivery van for the chosen minutes
  (`ios/Sources/FocusView.swift`, `18-focus-shift.png`). Wage is 1 coin a minute. Clocking
  out early pays the minutes worked. Pause exists. A "mile" every 90 seconds and a
  best-shift count that only goes up.
- The Friends foundations from part A: friend code, `Friend`, the friend card sheet with
  a **Study together** button, and the privacy toggle "Let friends invite me".

## The one design constraint that decides everything

The first version will be **asynchronous**, not live. There is no presence server. What
the app can do: post "Maya is on shift until 4:15" to the bridge, let a friend join, and
run **both timers independently** on each phone. So the room cannot show a real-time
cursor of the other person; it can show that they clocked in, when their shift ends, and
whether they finished. Design the live-feeling room that this data can honestly support,
and tell me what you would add if presence existed later.

## Screens I want back

### 1. Invite
From the friend card or from the Focus ready screen. Pick length (the same 25 / 45 / 60
chips and stepper), pick up to three friends from the kin row, one coral **Start and
invite**. The student's own shift starts immediately — an invite never waits on anyone.
Copy that says exactly that.

### 2. Invite received
A card at the top of Friends and one notification line: "Maya is on shift until 4:15.
Join her?" **Join** starts the student's own shift for the remaining minutes (or a full
one, your call, say why). **Not now** is quiet. The invite quietly disappears when her
shift ends; it never nags.

### 3. The room (the shift screen, together)
The existing van scene, but the convoy: each kin in its own van in a row, dashed KIN
boxes with coat and stars, the student's own van in front. Per friend: clocked-in or
finished, nothing else. The student's own timer, miles, Pause and Clock out early stay
exactly as built. Show it at two kin and at four. Show the state where a friend finished
before you did (their van pulls over, parks, the kin waves — caption the emote).

Nobody can talk. There is no chat, no reaction bar while a shift runs.

### 4. Clock-out, together
Clocking out early pays the same as solo. The sheet from the Focus brief gets one extra
line: "Maya keeps driving. You can join again." Nothing else changes. Never "you let her
down".

### 5. Finished, together
The shift report from the Focus brief, with a second block: who was on the road, each
with their own minutes, and **one shared line** that only goes up ("You and Maya: 3
shifts together, 2h 10m"). Then a **Send a vibe** row (the six cards from part A) so
the first thing you can do after finishing together is say nice one.

### 6. The Focus ready screen, aware of friends
When a friend is on shift right now, the Focus tab's ready screen shows one small card
above Start: "Maya is on shift until 4:15" with **Join**. When nobody is, the card is
absent — never an empty state, never "no friends are studying".

## Rules specific to this brief

- Both sides earn exactly what a solo shift pays. No bonus for being together. The
  reward for being together is the company.
- Leaving early is fine on either side and is never reported to the other side as a
  failure. "Maya clocked out" is the most it can say, and only in the report.
- No live cursors, no typing indicators, no "Maya is looking at her phone".
- No streaks of shifts together. The shared line is a total.

## What I want back

Six artboards (the room at two sizes plus the friend-finished state), every string
including the two notification lines, the state you need per shift, and a note on what
changes if presence arrives later. Tell me what you changed and why.
