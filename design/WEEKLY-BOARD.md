# The weekly board — the league, rebuilt around real friends

Decided 2026-09-12 with George. Design artifact: "The Weekly Board"
(https://claude.ai/code/artifact/de986f2f-2ca6-4667-bb6d-904ccbbf8644), which holds the
reference screens and the ship-size mockups. This file is the part that is not in the code.

## What was wrong

The league was a solo coin bar with a water name on it. The tier never depended on
another person, so the strangers pod was decoration; the reward for a week was a hollow
flag filling in; and friends could do nothing together beyond one wave a day.

## George's two calls

- **C — both on the tab.** The friends board is the league and opens the Friends tab.
  The strangers pod is drawn on the tab too, once you have joined one; before that it is
  a row into the ladder screen, where the full offer lives.
- **Rank numerals: yes.** On the board rows and on the pod rows. The last row still has
  no mark of any kind.

## The rules, each pinned to a working app

| Piece | Copied from | Rule |
|---|---|---|
| Week points | Apple Watch competition (per-ring points, capped per day) | A day is worth up to 400: tasks (3 = 100), focus (45 min = 100), a lesson (100), games (3 = 100). Scored day by day, then summed. `WeekPoints` in `Core/WeekBoard.swift`. |
| The board | Forest Deep Focus Ranking, Transit "Top contributors" podium | You + every friend with at least one shared day this week. Top three on sand mounds, the rest in rows. Ties share a place (1, 2, 2, 4). Friends with no shared day are listed under "Not on the board this week". |
| The crown | Duolingo's Monday result | A Monday card, once: "Last week: 2nd of 6". Gold / silver / bronze pennants kept on the ladder's shelf. A board of one places nobody. |
| Promotion | Duolingo top-N advance, minus demotion | The bar as before, **or** win the week on a board of three or more. Up only. `LeagueRules.winPromotes`, applied by `LeagueState.award`. |
| Group quest | Duolingo Friends Quest, for the whole board | One goal a week, kind rotates by ISO week number (tasks / focus / lessons / games), sized per head (10 tasks, 150 min, 3 lessons, 6 games). Clears → quest pennant for everybody. Nudge = the existing wave, aimed at the lowest contributor below you. |
| Clap | Strava kudos, Finch Good Vibes | The one-a-day wave, from the row. |
| Live desk | YPT "studying now" | Green dot + "on shift · 12 min left" on the row. Already on the wire. |
| Sharing | Apple "Share activity" | `share_today` stays **off** by default. The board asks once, in place: "Show my week". You are on other people's boards only after yes. |

Kept: no countdown ("Settles Monday"), no demotion, no red, no free text, no coins on the
wire. Nothing new crosses the bridge — the board is built on the phone from the
`daily_stats` rows `fetch_today` already sends, now over a fortnight so Monday can score
last week.

## The look, each piece copied from a real screen (2026-09-12, second pass)

George: "make it better for design too, find direct references to copy as much as you can."

| Piece | Copied from | What was taken |
|---|---|---|
| The scene | Finch Tree Town (`design/reference/finch/01-tree-town.png`) | The tab *is* the scene: full bleed under the status bar, the pets stand in it, empty places are marked, "＋ Add a friend" is a white pill floating in the scene. |
| The water | Our own Reef Route (`SwimSceneView`) | The same traced kelp, corals, far mounds, sand and light rays the Focus shift swims through. `FriendsWater.reef`. |
| The stands | Transit "Top contributors" (Mobbin d1aa00b6) | Three on stands, winner in the middle and tallest, a 1st / 2nd / 3rd rosette on the metal under each face. `PlaceRosette`. |
| The rows | Duolingo league list (Mobbin aea875c3) | Coloured numeral, avatar, name, number on the right, your row tinted. |
| The quest | Duolingo Friends Quest (Mobbin db515e34) | Eyebrow + time on the right, picture band with the people in it, goal in bold, bar with the fraction inside, a dotted row per person, an outlined Nudge button. |
| Monday | Duolingo's result screen (Mobbin 99e7f2d1, 790f98ad) | The trophy big in the middle with sparks, "You finished 2nd last week", "You moved up to Shallows", Continue. A sheet, not a takeover. `MondaySheet`. |
| The ladder rail | Duolingo's league rail (same screen) | Every water's pennant in one row, the one you are looking at big and tinted, earned ones in colour, the rest hollow (no padlocks). |

Left out on purpose: Duolingo's exclamation marks and padlocks, Transit's shouting caps,
Finch's night sky (the water is the tier's colour).

`-fakeMonday` (DEBUG) seeds a second-of-six, bar-cleared last week so the sheet can be
looked at.

## The badges (2026-09-12, third pass)

George: the hollow pennants were "ugly and shitty". They were hand-drawn `Path` shapes;
the rest of the app's icons are a generated flat-vector family (`design/icons`, memory
`icon-set-v1`). The badges now come from the same pipeline, a sheet at a time against
`grid-a` as the style reference:

- `grid-h` — the six waters as **Duolingo's league trophy shape** (a shield on a
  pedestal) with one sea emblem each: scallop, starfish, coral, kelp, wave, anglerfish
  lantern. Darker in order. George picked these over `grid-i` (award rosettes, kept for
  the record).
- `grid-j` — gold / silver / bronze medals on ribbons, the quest chest, the pod (a school
  of fish), the crown.
- `grid-k` — the eye (what friends see), the wave (was the hand-drawn clap), race flags
  (for the next slice), and three spares.

Swift: `TierPennant` and `MedalPennant` keep their names and call sites but draw the
imagesets; `BadgeMark` draws the small marks bare. The `LARGE` set in `icons.py` packs at
512px so the Monday sheet's 132pt badge is sharp. Not-yet-earned is the badge drained of
colour (saturation 0.15, opacity 0.45) — Duolingo's grey trophy without its padlock.
Deleted: `PennantShape`, `PennantFoldShape`, `PlaceRosette`, `CrownGlyph`, `ClapGlyph`,
`AddFriendGlyph`. `TierLadder` in `LeagueView.swift` was already dead before this and is
left alone.

## Good vibes and the two notes (2026-09-12, fourth pass)

- **Finch's Good Vibes picker** (`design/reference/finch/11`, `13`): `VibePickerSheet` —
  your kin with a bubble naming the card, a 3×2 grid of round cards from the app's own
  icons, the chosen one ringed, one button that says what it sends. Six cards: Hello,
  High five, Nice one free; Drink water, Stretch, Sleep well with Plus (PLUS-SPEC
  signature 8, which George signed). One per friend per day, any card. The received
  card on the tab and the friend card say which one came ("Maya sent you a high five").
- **Finch's friend-profile tiles** (`09`): the friend card's actions are square tiles,
  Good vibes and Sit down (while they are at a desk). Plus a line for their place on your
  board this week.
- **Duolingo's two league notes**, without the countdown: Sunday 18:00 "The board settles
  tonight", Monday 09:00 "Last week's board is in". Only with a friend; behind the
  reminders switch like everything else the app says unprompted.

## Why the score is not coins

Coins are what the pod ranks on and they are unverifiable check-offs. The four counts are
the same honour system, but capped per day they cannot be stacked: a forged Saturday is
worth exactly a real one. And the counts are what friends already agreed to share; adding
coins to the friend wire would reopen SOCIAL-PLAN F5.

## Where the placement comes from

The week settles locally in `settleLeagueWeekIfNeeded` (off `advance(to:)`), with no
placement. The first `refreshToday` after that scores last week from the fetched rows and
calls `LeagueState.award`, which fills the receipt, bumps the shelf, and promotes on a win.
Only the newest settled week is scored. If the fortnight passes first, the receipt stays
unplaced — the tier is unaffected, only the medal is missed.

## The race (2026-09-12, fifth pass) — built, dark until `bridge/schema-pacts.sql` is pasted

Apple Watch's Activity competition, one to one: invite a friend from their card, they get a
card on the tab ("Crisp Harbor wants to race you this week", Race / Not this week), and once
accepted both phones draw the race card — two sides, a split bar, "You're ahead by 60".
The window is the ISO week the invite was sent in, the same window the board scores, so the
race needs no clock and **no score on the bridge**: the `pacts` table holds only the
handshake (who, whom, which week, accepted or declined), and each phone works the standing
out from the day rows it already fetches. One race a week. Ahead or level on Sunday night
keeps a race pennant (`racesWon`, the shelf's fifth tile); the other keeps everything.

- SQL: `bridge/schema-pacts.sql` — `propose_pact`, `answer_pact`, `fetch_pacts`,
  `pact_row`, `purge_pacts`. Paste after schema-friends.sql. Unrun, unlinted (no local
  Postgres). `test/live-pacts.js` walks it against the real bridge once pasted.
- Swift: `Core/Race.swift` (`Pact`, `RaceStanding`, `RaceResult`, `RaceRules`),
  `FriendClient` + three calls, `LeagueState.races` / `racesWon` / `settleRace`,
  `AppState.inviteToRace` / `answerRace` / `refreshRaces`, the two cards in
  `FriendsView`, the tile in `FriendCardSheet`, the line in `MondaySheet`.
- `-fakeFriend` seeds a race that is on and an invite waiting, so both cards draw.
- Held: a race starts counting from Monday even if accepted Thursday (both sides have the
  whole week's rows, so it is fair either way and needs no second clock).

## Looking at it

`-fakeFriend` seeds five friends with a spread of days, so the podium, the rows, the quest
and the "not on the board" list all draw. `-fakeFriend` is DEBUG only, like `-unlockAll`.
