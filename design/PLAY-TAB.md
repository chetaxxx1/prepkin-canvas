# Play — the tab that used to be Learn (2026-09-10)

George: "change Learn to a different tab name, I want both games and learning all in
one place. Research whether we need learning, or games is all we should have, or keep
both — you decide." This is the decision, the evidence, and what changed.

## The decision

**The tab is called Play. It keeps both. The puzzles lead; the lessons follow.**

## Why both, and why the puzzles lead

The two things on this tab are the same kind of thing. `LEARN-PLAN.md` §2 says it
outright: Today's card "sits next to Daily Word as the second small daily ritual."
Every item here is a two-minute daily thing that pays coins and asks nothing else.
That is one tab's worth of idea, not two.

Puzzles go first because the retention evidence is theirs (`GAMES-PLAN.md` §2):

- 50% of 18–29s do daily puzzles regularly, more than any other age group.
- LinkedIn's daily games: 86% of today's players are back tomorrow.
- NYT Games logged 11.2 billion plays in 2025, half of weekly players doing more than
  one a day.
- George's own note that day: every game must be one his demographic already plays.

The lessons stay for three reasons. 57 of them exist, with figures — a real asset.
"Because of your week" (a lesson picked from what is actually due in Canvas) is the
one thing on this tab nobody else can do, and the reason it lives inside a Canvas app
rather than in Imprint. And BetterCampus's "bloat" complaints (`bettercampus-likes`)
are about the to-do core; a two-minute card behind its own tab is not that.

What was wrong before was not the content, it was the billing. "Learn" told a college
student "more school" on a tab whose actual job is the two-minute break that pays. And
the six puzzles sat fifth on the page, in a horizontal rail that hid four of them
off-screen, under a header that said Play inside a tab that said Learn.

## Why the word Play

Mobbin, 2026-09-10, apps that mix puzzles with light learning in one tab:

| App | Tab | What's in it |
|---|---|---|
| The New Yorker | **Play** | crossword, mini, cartoon puzzles, quizzes |
| Nibble | **Play** | "This or that", "Complete the picture" — learning *as* games |
| Elevate | Today | a daily "workout" of games + audio lessons |
| Mimo | Practice | daily review + past topics |
| NYT, Apple News | Games / Puzzles | puzzles only |

The two closest to us — an adult reading brand, and a learning app built from games —
both say Play. It was already this app's own word: the section was called Play and
`GAMES-PLAN.md` is titled "Play — the six games". Promoting the section's name to the
tab is the least invention available.

Rejected: **Today** (Home already is today), **Practice** (nothing here is practice
for anything), **Games** (orphans the lessons and the Canvas hook), **Learn** (keeps
the puzzles second-class, backwards on the evidence), **Brain / Mind** (Lumosity-speak),
**Break** (collides with the Focus timer's break).

In the bar it reads Home · Focus · **Play** · Calendar · Friends. Focus and Play are
opposites; that is a clean story to tell.

## What changed

- `RootView.Tab.learn` → `.play`, label "Play". Not persisted, so nothing migrates.
- Tab icon: `icon-tabPlay`, the Game Boy already in the set from when Play was its own
  tab (before 2026-09-06), hue-shifted from lilac to sky. Lilac sat directly next to
  Calendar's lilac, and the bar's whole findability rule is one hue family per tab;
  Learn's sky slot was free. `design/icons/icons.py` and `IconTint.swift` updated.
- `LearnView` (file name kept): the six puzzles move from fifth to first, out of the
  rail and into a two-up grid so all six are on screen at once (the NYT / New Yorker
  shape). The section is "Today's puzzles", since "Play" inside Play says nothing.
  Then Continue, Because of your week, Today's card, Tracks, Saved cards, in the old
  order.
- The header's "Start anywhere" stays — it is true of a puzzle as well as a card.

## Not changed

Coins (one daily pool, first finish banks 30; a card pays 20 on its own), the games
themselves, the lessons, routes, the reader. `LearnRoute`, `LearnView`, and the
`learn-root` flow step keep their names; renaming internals buys nothing.
