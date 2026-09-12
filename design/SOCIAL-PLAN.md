# Social plan — stress-tested, every element pinned to a working replica

Decided 2026-09-08 with George. Rewrites the first draft after a stress test.
House rule from the games build applies here too: **mechanics-identical to something
that already works, not inspired-by.**

---

## 0. The pivot that came with it

**Prepkin is no longer an SAT app** — though it turned out to be barely one already.
Checked on 2026-09-08: the only SAT in the shipped app was a single preset task, "20 min
SAT practice", now "20 min study session". The 57 lessons in `lessons.json` teach
personal finance, study skills, psychology, philosophy, people skills and work — written
for exactly this audience — so they stay. What is still SAT is the tooling in
`.claude/skills` and the question generators, which are tools and cost nothing to keep.

> Your Canvas assignments, a fish you grow, and six daily games with a friend board.

Follows the 2026-09-07 decision to aim at college undergrads, who do not take the SAT.
The app is Canvas (Today, receipt, Due next, grade calc), the Focus timer, the six daily
games, the 57 lessons, the kin and its tank, the shop, and the league.

---

## 1. What the stress test broke

Seven findings. Four changed the design.

### F1 — CRITICAL. A player-vs-player elo cannot exist yet, and may never.
There is no Apple Developer account, so no TestFlight, so **there is no second
player**. A rating built on beating other people is dark on day one, dark at launch,
and dark for every early student who has no friends on the app. The first draft put
the whole competitive layer behind a dependency we do not control.

**Fix — copy chess.com, not the chess ladder.** Chess.com's *Puzzle* rating is
player-vs-**puzzle**: every puzzle carries its own rating, you gain by solving a hard
one and lose by failing an easy one, and the maths is Glicko, the same as their game
ladder. It needs **no opponent, no server, and no network.** It works on a phone in
a dorm at 2am with nobody else on the app. It is also the mechanic our demographic
already knows from chess.com and Lichess.

That is the rating. Player-vs-player is deleted from the plan.

### F2 — CRITICAL. `Calendar.current` splits the daily board across timezones.
`PlayDeal.number(for:)` counts days from 2026-01-01 in the **device's** calendar. Two
friends in different timezones get different boards on the same wall-clock day. If the
friend board keys on the date, they get compared on different puzzles.

**Fix:** the board keys on the **puzzle number**, never the date. This is what NYT
does — Wordle is local-midnight, and the leaderboard compares puzzle 1,617 to puzzle
1,617. A friend eight hours ahead shows up on your board when you both reach the same
number, and the header says the number, not "today".

### F3 — SERIOUS. Time can be forged and time cannot be checked offline.
The stopwatch is `PlayRecord.startedAt`, a `Date` on the phone. Airplane mode plus a
clock change beats it. The first draft answered this with a server-held clock, which
re-introduces F1's dependency.

**Fix — split the two numbers by who can verify them.** Chess.com's puzzle rating
ignores the clock entirely; it only asks solved or not solved, which a phone cannot
usefully forge against itself. Time stays, but only where NYT puts it: a **friend
board**, where the stake is bragging and both people know each other.

- **Rating** = solved/failed only. Offline, honest, ships now.
- **Time** = shown on the friend board. Never feeds the rating, never feeds coins.

### F4 — SERIOUS. Three competitive boards is one more than Hick's law allows.
The first draft shipped a coin league, a game rating and a friend board. The
2026-09-06 audit already cut the app to five tabs for this reason.

**Fix:** two surfaces, not three. The **rating is a number, not a board** — it sits
on your kin's card the way a chess rating sits under a username. The two boards are
the existing stranger **League** (weekly coins, climb-only) and the new **Friend
board** (today's six games).

### F5 — SERIOUS. Gifting currency between phones launders the honour system.
Coins are offline check-offs nobody verifies. A gift moves that unverified currency
between accounts, so two friends can mint coins for each other forever.

**Fix — copy Finch exactly.** Finch's Good Vibes "don't cost anything and don't
require Rainbow Stones": 14 preset messages, free, one visit each. Its *paid* gifts
are limited to one per friend per day and cost 200 extra stones. We take the free
half — preset reactions, no currency crosses the wire — and skip gifting entirely
until coins are verifiable.

### F6 — SERIOUS. Any free text turns this into a moderated product.
The moment two students can type at each other, Apple's user-generated-content rules
apply: we owe filtering, blocking, reporting, and a published contact. That is a
company's worth of obligation for a feature nobody asked for.

**Fix:** no free text anywhere, ever. Finch ships 14 fixed Good Vibes and that is the
entire vocabulary of its social layer. Pod names are already two integers into shipped
word lists. Friend display names will be too. There is no string a student typed
anywhere on the bridge.

### F7 — WATCH. The generator does not yet emit a difficulty.
`gen.py` has a rule-only solver per game (`bal_deduce`, `pearl_deduce`, `trace_count`)
used as a pass/fail gate. A rating needs a **number**. The solvers already know it —
how many passes, which rule was needed last — it is just thrown away.

**Fix:** the gate returns its work. See §3.

---

## 2. Every element, and the thing it copies

| Element | Copied from | How close |
|---|---|---|
| **Rating** | chess.com Puzzle rating (Glicko, player-vs-puzzle, puzzle ratings set by who solves them then locked) | Identical maths, identical shape |
| **Friend board** | NYT Games multi-game leaderboard (Wordle + Connections + Spelling Bee + Mini in one list, friends, daily, score history) | Identical: our six games, one row per friend |
| **League** | Friends board (Apple Watch scoring, Forest/Transit board, Duolingo Monday result) + the strangers pod | Rebuilt 2026-09-12, see `design/WEEKLY-BOARD.md` |
| **Tank visits** | Finch friends: see their birb in its birbhouse, friendship level, send free preset Good Vibes, their bird visits yours | Identical minus paid gifts |
| **Friend connect** | Finch / Duolingo friend code, plus a share link | Identical |

Nothing in the design is invented. Where we differ from a source we differ by
*removing* (no demotion, no gifting, no free text), never by adding.

---

## 3. The rating, in full

**Player rating.** One number, starts at 800, shown like a chess rating: `1214`,
with the day's delta. Stored in `GameState`. No server.

**Puzzle rating.** Every puzzle in `balance.json`, `pearls.json`, `trace.json`,
`ladders.json`, `threads.json` gains a `rating` field, written by `gen.py` from what
the rule-only solver had to do:

- **Balance / Pearls** — how many deduction passes, and the hardest rule reached.
- **Trace** — how many walls the generator had to add before the line was unique, and
  the solver's step count.
- **Ladder** — clue-word frequency rank; a chain of common words is easier.
- **Thread** — how far down the five clues the category is guessable.

Mapped onto 400–2000. This is a **seed**, exactly as chess.com seeds a new puzzle
before real solvers settle it, and it is the honest thing to say on screen: "these
ratings are our estimate until enough people play."

**The update.** Glicko-style, one puzzle at a time:

```
expected = 1 / (1 + 10^((puzzleRating - playerRating) / 400))
playerRating += K * (solved ? 1 : 0 - expected)
```

`K` = 32 for the first 20 puzzles (provisional, moves fast), 16 after. Puzzle ratings
do not move on device — moving them locally would give every phone a different ladder.

**Failing.** A game is failed if you open it and leave the day without solving it.
Not opening it is nothing at all, exactly like not doing a chess puzzle. This is the
one place the design can hurt, so: **the rating drop is never shown as a red number
on the home screen.** It appears on the end card and on your kin's card, nowhere else.

---

## 4. The friend board

One screen. One row per friend, one column per game, today's puzzle number in the
header. A cell is a time, a dash for not-yet, or a slash for failed. Sorted by how
many of the six are done, then by total time. You are highlighted.

Under it, "score history" the way NYT ships it: the last 7 puzzle numbers as a strip.

**It keys on the puzzle number, not the date.** (F2.)

**No cell is a coin.** Coins are earned on your own phone from the same daily pool as
today; the board is bragging only.

---

## 5. Visiting a tank

A friend taps your row and sees your kin, at its real stage, in its real look and
costume, in your real room. Read-only. Then, copying Finch:

1. **Send a vibe.** A fixed list of preset reactions. Free. No currency, no text.
2. **Your kin visits theirs.** Sending a vibe puts your fish in their tank for the
   day, which is Finch's "a visit from your birb" and is the whole reason the feature
   is worth building — it makes the mascot social, which is the gap the Dolphin
   teardown identified.
3. **One vibe per friend per day.** Finch's limit, and it is what keeps this a hello
   rather than a resource.

Guard rails: a visitor can never move decor, spend coins, or change anything. What
syncs is a `TankSnapshot` — species, look, costume, stage, room — and nothing else.
The tank itself never leaves the phone.

The animation is Sprout web-build work (a pellet drops, the fish turns and swims to
it), not Swift. Per the embed contract the page owns the mascot's safe area. Needs a
GIF sign-off before it ships, like every animation.

---

## 6. Becoming friends

Both, because they cover different rooms:

- **Share link** — `prepkin.app/f/CODE` in iMessage. Opens the app if installed,
  otherwise a page that says what Prepkin is. Universal Links need an Apple account
  for the associated-domains file; until then the link only reaches the web page and
  the code is copied off it.
- **Code** — the 8-character code that already exists, read out loud in person.

Both resolve to one server call.

---

## 6b. What `design/FRIENDS-PLAN.md` already said

That plan is from 2026-08-31 and it is not superseded. Three things in it are better
than anything above and belong in the build:

1. **Study Together.** Two to four kins in one scene while one timer runs, nobody
   talking, both sides paid the same as a solo session. That plan calls it "the reason
   to open the tab daily" and it is right — a friend board is something you glance at,
   a shared timer is something you show up for. It is Focusmate and Forest's Plant
   Together, so it is a replica like everything else here. **The cheap version first:**
   "someone is focusing until 4:15 — join" with two independent timers, no presence, no
   websockets.
2. **Same class.** The extension already knows the student's real Canvas course names,
   so the app can say two friends both have BIOL 12 Quiz 3 on Friday. Nothing else on
   the reference list can do this. Per-course opt-in, off by default, and store a hash
   rather than the course title if a hash is enough to match on.
3. **Ranking on focus minutes, not coins.** Its argument: ranking the currency makes
   people grind for money instead of for work. The league shipped on coins. Worth
   revisiting, and it is a change to `LeagueRules` and nothing else.

Two things in it have since been overtaken and should not be built as written:

- It says a student **types** a display name. The league that shipped on 2026-09-05
  makes a name two integers into a shipped word list, precisely so no student-typed
  string exists on the bridge. The later decision wins (see F6).
- Its "Daily Word friends strip" is the friend board in §4, widened from one game to six.

---

## 7. What is still blocking

1. **No Apple Developer account.** $99/year. Without it there is no second human, so
   §4, §5 and §6 cannot be tested with a person — only simulated. §3 is unaffected,
   which is why §3 is built first.
2. **`bridge/schema.sql` has never been run.** Leagues, friends, board and visits all
   read from it. Nothing pairs until it is pasted into the Supabase SQL editor.
3. Two Claude sessions are editing these files and 36 changes are uncommitted.

---

## 8. Build order

**Done 2026-09-08, 231 tests green, uncommitted.** Steps 1 and 7, plus the SAT check
in §0. `rate.py`, `Rating.swift`, `StudySync.swift`, the Study Together row on Focus,
and `bridge/schema-social.sql` (written, never run).

0. Commit the six-game build.
1. ~~**Rating.**~~ Built. `rate.py` rates 1,360 puzzles; `Rating.swift` does the
   Glicko update; the end card and the Play header show it.
2. ~~**SAT rip.**~~ Done, and it was one line: the preset task `s-1` "20 min SAT
   practice" is now "20 min study session". Nothing else in the app was SAT. The 57
   lessons stay (§0) and the daily pool keeps every earn source it had.
3. **Schema.** One additive file: friends, tank snapshots, daily results, vibes.
4. **Friends for real.** `FriendSync.swift` + mock, share link, code, one call.
5. **Friend board.** Keyed on puzzle number.
6. **Tank visits.** `TankSnapshot`, preset vibes, one per friend per day.
7. ~~**Study Together**, asynchronous version, from `FRIENDS-PLAN.md` §3.~~ Built. The
   row is on the Focus ready screen, above Start focus. `-fakeTable` seats two made-up
   friends so it can be looked at before a second real person exists.
8. League stays as built. Do not add demotion — losing lives in the rating now, where
   it is measured against a puzzle instead of against a person.

Not in this list: **Same class** (§6b.2), which is real personal data on a remote
server and wants its own decision, not a slot in a build order.

## Sources

- [chess.com — How do Puzzle ratings work?](https://support.chess.com/en/articles/8602396-how-do-puzzle-ratings-work)
- [NYT multi-game leaderboard](https://www.today.com/popculture/nyt-multi-game-leaderboard-rcna202155)
- [Finch — Sending Good Vibes](https://help.finchcare.com/hc/en-us/articles/37780369483533-Sending-Good-Vibes)
- [Finch wiki — Tree Towns / friends](https://finch.fandom.com/wiki/Tree_Towns)
