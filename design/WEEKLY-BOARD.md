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

## Next slice — a race with one friend

Apple Watch's 7-day competition, one to one: invite, accept, seven days, a race pennant for
whoever has more on Sunday night. Same scoring as the board. Needs a small `pacts` table on
the bridge for the handshake, because `fetch_visits` only covers two days and an invite has
to survive a week. Designed in the artifact, not built.

## Looking at it

`-fakeFriend` seeds five friends with a spread of days, so the podium, the rows, the quest
and the "not on the board" list all draw. `-fakeFriend` is DEBUG only, like `-unlockAll`.
