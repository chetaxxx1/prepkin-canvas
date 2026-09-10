# Play — the six games, plan (2026-09-08)

Prepkin already has two games: Daily Word (a Wordle-type word game, 30 coins) and
Number Line (25 coins). Both live in the Play section of the Learn tab since the
Games tab went on 2026-09-06 (`design/hicks-law-plan.md`). This plan adds four more,
picked for 19–24 year olds, and says how coins, storage, content and the Play rail
change to fit six games.

Playable prototype of all four: `design/games/prototype.html` (open in a browser).

## 0. Changed 2026-09-10: Ladder and Thread out, Sort and Weave in

George: the games are "not very good"; every one must be a brain-teaser his
demographic already plays. Research that day:

- LinkedIn's own games lead named Pinpoint and Crossclimb its **least** popular
  games and Zip its most (GamesBeat, Mar 2026). So Thread and Ladder go.
- NYT's Connections is the #2 daily game on earth (3.3B plays in 2024) with the
  strongest college-paper evidence of any game; Strands is #4 (1.3B+). So a
  Connections-type (**Sort**) and a Strands-type (**Weave**) come in.
- Daily Word, Trace, Pearls and Balance stay: Wordle, Zip, Queens and Tango are
  the four the numbers back.
- Legal picture unchanged. No enforcement against a LinkedIn clone was found.
  NYT enforces the Wordle name and the green/yellow tile look; Wordle is a
  registered US mark (Nov 2025) and LinkedIn filed Zip (Feb 2025). Sort and
  Weave use our names, our palette (group colours mint, gold, pink, lavender in
  that order, not NYT's yellow-green-blue-purple), our code and our own boards.

Content: `design/games/sorts.py` (60 hand-written boards, a 1-5 `hard` tag each)
and `design/games/weaves.py` (57 themes; `gen.py` tiles each into a 6×8 with the
spanning word touching two opposite sides, no diagonal crossings). Weave's
non-theme words check against `dictionary.txt` (the system word list, 4-10
letters, plus every theme word). Three real non-theme words earn a hint that
outlines a hidden word, as in the original. Sort allows four misses, shows the
groups on a loss, and pays nothing for a loss. Old saves keep their Ladder and
Thread records and ledger lines; the fields are read, never written.

## 1. The legal line

Copy the mechanic. Never copy the name, the art, the code, or the puzzle content.

- **Rules and mechanics are not copyrightable** in the US. What is protected is the
  *expression*: the name, logo, specific art, colour scheme, the exact look and feel,
  and the source code. *Tetris Holding v. Xio* (D.N.J. 2012) is the case that bit a
  cloner: Xio copied Tetris's rules (fine) but also its piece shapes, colours, board
  proportions and animations (not fine).
- **NYT's 2024 Wordle takedowns** targeted clones that used the word "Wordle" in the
  name or forked the original JavaScript. Copyright lawyers called the wider claim
  (5×6 grid, green/yellow tiles) an overreach. Daily Word already stays clear: own
  name, own palette, own code, own word list.
- **Names are trademarks.** Wordle (NYT), Queens / Tango / Zip / Pinpoint / Crossclimb
  (LinkedIn). Sudoku is a Nikoli trademark in Japan only. Never use any of these.
- **Every LinkedIn game is a reskin of an older, public puzzle type.** Build from the
  ancestor, not from LinkedIn's version, and the look-and-feel question mostly goes
  away:

  | LinkedIn | Ancestor | Age |
  |---|---|---|
  | Crossclimb | Doublets / word ladder, Lewis Carroll | 1879 |
  | Pinpoint | category guessing (parlour game, quiz shows) | old |
  | Tango | Takuzu / Binairo, Belgium | 2009 |
  | Queens | Star Battle (one star), World Puzzle Championship | 2003 |
  | Zip | Numberlink, Nikoli | 1990s |
  | (NYT) Connections | Only Connect "connecting wall", BBC | 2008 |

- **Puzzle content is a compilation.** A curated word list or a set of daily puzzles
  can be protected as a compilation. Generate our own. Never scrape theirs.

House rules, so the design stays ours: no crown icon, no LinkedIn purple/blue,
no LinkedIn or NYT names anywhere in the code or copy.
*Changed 2026-09-08 pm:* George played the first build and asked for near-replicas of
the games his demographic already plays, mechanics identical. So the earlier "no
sun/moon, no = and × signs, no clues on the ladder" rule is dropped. Generic symbols
and rules are not protectable; names, art, code and puzzle sets still are.

## 2. Who this is for, and what they want (research)

Audience: college undergrads, 19–24 (`design/LAUNCH-PLAN.md`).

What the numbers say:

- **Daily puzzles are a Gen Z habit, not a boomer one.** 50% of 18–29s say they
  regularly do crosswords, more than any other age group (CS Monitor / WBUR, 2026).
  NYT Games logged 11.2 billion plays in 2025; over half of weekly players play more
  than one puzzle a day (Fast Company, 2026).
- **One puzzle a day is the retention engine.** LinkedIn: 86% of today's players come
  back tomorrow, 82% are still playing next week. They call it the "finite" model:
  one edition per day, each game a few minutes, no binge (CNBC 2025, Naavik).
- **Logic beats words for this age group now.** LinkedIn's growth games are the logic
  ones (Queens, Tango, Zip, then Patches, Wend). Their puzzlemaster says word games
  skew older (GamesBeat 2025). Connections finishes 9 of 10 sessions (TechCrunch).
- **The social loop is the result line, not the game.** Gen Z plays because everyone
  is doing the same puzzle; complaining about a hard one is "an inside joke with the
  rest of the world" (Dazed). LinkedIn's compare-with-connections and solve time is
  the share hook.
- **Sessions are short.** Gen Z women in particular prefer short mobile puzzle and
  word sessions (Lab42). LinkedIn's rule: never 20 minutes.

What that means for Prepkin:

1. Six games, **one puzzle each per day**, 1–4 minutes each. No endless mode.
2. **Two logic, two word.** Pearls and Balance are the adult picks; Ladder and Thread
   carry vocabulary. Number Line and Daily Word stay.
3. Every game ends on a **one-line result you can copy**: `Prepkin Pearls 251 · 7×7 · 1:42`.
   Plain text, no emoji (house rule). This is the growth loop.
4. **A stopwatch, not a countdown.** Logic games show solve time on the end card and in
   the share line. Time is the number friends compare. No "best time" record, because
   PRODUCT.md says every number shown only goes up. Solves and streaks go up.
5. **No punishment.** A miss says "No coins today, and nothing lost." Same as Daily Word.
6. **Tone for 19–24:** short, dry, no cheerleading. "First clue. Sharp." not "Amazing job!"

## 3. The four games

### Ladder (Crossclimb-type, rebuilt 2026-09-08 pm)
The first build was Carroll's Doublets (free rungs, no clues). George: "terrible, it
doesn't tell me if I'm right or wrong." Now a Crossclimb replica: seven five-letter
words, each one letter off the next. The middle five are dealt scrambled, each with a
clue. Type a word; it is checked the moment the fifth letter lands: right locks it
mint, wrong shakes and stays to be edited. When all five are right, tap a rung to pick
it up and tap another to swap, until each is one letter off its neighbour (either way
up counts). Then the top and bottom rungs unlock with their clues. Timed from the first
letter; the time is the compare number.
*Content:* hand-written in `design/games/ladders.py` (40 so far); `gen.py candidates`
prints chains to author more. Checked: common words, one letter a rung, the middle has
exactly one order up to reversal, the deal is never the answer.

### Thread (category guessing)
Five clues, hardest first, one shown at a time. Type the link. A miss reveals the next
clue. Score is which clue you got it on (1–5). Miss all five: answer shown, no coins,
nothing lost. Different from Pinpoint by voice and content: adult categories
(loans, coffee orders, dropouts, "things that are due"), never work-speak.
*Content:* hand-written. 26 in the prototype; need ~120 to launch (a school year is
~180 days, repeats after 120 are fine). Accepted answers are a list of keywords with
loose matching (plurals and filler words stripped).

### Balance (Tango-type)
6×6, suns and moons. Three of each in every row and column, never three in a row, and
four to six signs between neighbours: = means the pair matches, × means it differs
(added 2026-09-08 pm for the replica rule). Tap cycles blank, sun, moon. Solved when
full and clean; a broken rule or sign shows coral at once.
*Generation:* fill a valid grid, read four to six true signs off it, remove cells in
random order while a solver still finds exactly one answer AND a rule-only solver
(pairs, gaps, full halves, signs) still reaches it. Measured: ~7 givens, ~5 signs.

### Pearls (Star Battle, one star)
7×7 weekdays, 8×8 on Sundays. Coloured regions ("reefs") with thick borders. One pearl
per row, column and reef; pearls never touch, not even diagonally. Tap cycles blank,
cross, pearl. Conflicts get a coral ring so the board teaches its own rules.
*Generation:* pick a random no-touch permutation as the answer, seed one region per
pearl, grow regions at random until the board is covered, keep only boards with
exactly one solution. Prototype does this live in ~1–50 attempts.
*Shipped:* a rule-only solver is the gate in `gen.py` (single candidates, confinement).

### Trace (Zip-type, added 2026-09-08 pm, replaces Number Line)
Number Line was not a replica of anything and George cut it. Trace: a 6×6 grid, numbers
1..k on some cells, a few walls on edges. Drag one line from 1 through every square,
hitting the numbers in order, ending on the last one, never crossing a wall. Dragging
back over the previous cell undoes it; Undo and Clear buttons. Timed.
*Generation:* a random Hamiltonian path; 6–9 numbers spread along it; walls only on
edges the path does not cross, added two at a time until a counting solver finds
exactly one line. ~15% of tries survive; 400 boards in about three minutes.

### Feel, shared by all six (2026-09-08 pm)
Every logic game has Undo and a Hint. Hints are free and counted (end card and share
line say "2 hints"); each one does a real move and the kin says why. A wrong mark is
fixed before anything new is placed. Pearls auto-crosses what a pearl rules out, like
Queens. A miss is always shown where it happened and cleared for the next try.

## 4. Coins: one daily pool (decided 2026-09-08)

**The first game you finish today banks 30 coins. Every game after that is for the
result line and the streak.** Reasons: "coins pay for finishing", keeps six games from
becoming a 180-coin farm that outpays real Canvas tasks, and one number is easier to
read than six.

Truth to know: today Daily Word (30) and Number Line (25) pay separately, 55 a day.
Under the pool that drops to 30. If that feels like a cut, set the pool to 40. The
code change is one constant.

Implementation:
- New `CoinReason.play`. Ledger key `play:<day>`. `playClaimedToday` replaces
  `wordleClaimedToday` and `numberLineClaimedToday` on the rail and the end cards.
- Old ledger entries keep their old keys and reasons. The ledger is append-only, so
  nothing migrates. Week stats keep counting `wordleSolved` from `.wordle` entries;
  add `.play` to the earn set in `Ledger.stats()`.
- End-card copy: first finish "+30 coins banked"; later finishes "Today's 30 banked
  by Ladder". Never "no reward".

## 5. Storage (GameState)

Per game, the same shape Daily Word already has:

```
var <game>Solved = 0          // lifetime, only goes up
var <game>Streak = 0
var <game>LastDay: DayKey?
var <game>Progress: <Codable> // today's board or rungs, so leaving mid-puzzle keeps it
var <game>ProgressDay: DayKey?
```

One shared streak instead? No. Streaks per game let a Pearls-only player have a
streak. A "Play" streak (any game today) can be derived later from the ledger.

Solve time is not stored. It is shown once and put in the share line.

## 6. Content and dealing

Ship puzzles as JSON in `ios/Resources/Content/`, loaded through `Catalog.load`
like `words.json`. Generate with a Python script in `design/games/gen.py`, verify
uniqueness there, and commit the output. Reasons: no solver at runtime, every phone
gets the same puzzle without a server, tests can check the whole year.

- `ladders.json`: `[{start, end, par}]`, 400 entries.
- `threads.json`: `[{name, accept:[...], clues:[5]}]`, 120 at launch.
- `balance.json`: `[{n:6, givens:[[...]]}]`, 400 entries.
- `pearls.json`: `[{n:7|8, regions:[[...]]}]`, 400 entries.

Deal by `puzzleNumber % count`, the same as `WordleGame.answer(for:)`. Day boundary
uses `effectiveDay`, so a solve just past midnight pays under the right day.

## 7. The Play rail on Learn

Hick's law rule 2 says five equal choices, max. Six tiles in a 2-wide grid breaks it.
Rule 6 says catalogs sort, never cut. So:

- Play becomes a **horizontal rail** of six half-width tiles, same tile as today.
- **Sort:** not played today first, then finished (their line reads "Solved · 1:42").
  The first tile is the default tap.
- Section header line: "Six today. First finish banks 30." with the coin chip.
  After banking: "Banked. Five more for the result line."
- Tile colours: Daily Word butter `FFC94D`, Number Line lavender `9B7BEA`,
  Ladder mint `57C79B`, Thread pink `F7A8B8`, Balance leaf `A5CE6B`, Pearls sea `4CA8E8`.
  Coral stays the one action colour and never a tile.
- Glyphs are drawn, not emoji: a three-rung ladder, a needle and thread, two dots
  (one filled, one ring), a pearl.

## 8. Build order

1. Generators + JSON + tests (Python, then a Swift test that loads and validates
   every puzzle: 3-and-3 rows, unique solution via a small Swift solver for Balance
   and Pearls, valid par for ladders). — 1 day
2. `CoinReason.play`, pool logic, GameState fields, Play rail sort. — half day
3. Pearls and Balance screens (share one grid component and one timer). — 1 day
4. Ladder screen (reuses the Daily Word keyboard and tile). — half day
5. Thread screen + 120 threads. — 1 day, writing is most of it
6. Sweep on `prepkin-fresh`, light only, capped type; end cards at AX XL. — half day

## 9. Open decisions (defaults in bold)

- Pool size: **30** or 40.
- Pearls Sunday 8×8: **yes**.
- Show solve time on the end card: **yes**; keep a best time: **no**.
- Share line goes to the system share sheet or just Copy: **Copy for v1**.
- Connections-type game (the most Gen Z of all of them): **not now**. Needs 4×4 of
  hand-written groups per day, the heaviest content load of any of these. Revisit
  after Thread proves we can keep up with hand-written content.

## Sources

- LinkedIn retention (86% D1, 82% W1), finite model: CNBC 2025-08-12
  <https://www.cnbc.com/2025/08/12/linkedin-mini-sudoku-games.html>; Naavik podcast
  <https://naavik.co/podcast/linkedins-gaming-strategy-using-games-to-foster-connection-and-conversation/>
- LinkedIn shift to logic games, word games skew older: GamesBeat
  <https://gamesbeat.com/how-linkedins-new-game-patches-demonstrates-its-shift-away-from-word-games/>
- "Not games for games' sake", a few minutes each: Entrepreneur
  <https://www.entrepreneur.com/business-news/heres-how-hes-shaping-linkedins-puzzle-game>
- NYT 11.2B plays 2025, multi-game daily habit: Fast Company
  <https://www.fastcompany.com/91539885/wordle-statistics-show-why-new-york-times-is-turning-game-into-nbc-tv-show>
- Connections 9/10 finish: TechCrunch
  <https://techcrunch.com/2023/08/28/connections-is-the-new-york-times-most-played-game-after-wordle>
- 50% of 18–29 do crosswords: CS Monitor 2026-06-02
  <https://www.csmonitor.com/USA/Society/2026/0602/crossword-puzzles-gen-z>; WBUR
  <https://www.wbur.org/news/2026/05/15/crosswords-gen-z>
- Why Gen Z plays (shared daily, inside joke): Dazed
  <https://www.dazeddigital.com/life-culture/article/62601/1/are-puzzles-cool-now-gen-z-nyt-connections-strands-mini-wordle>
- Gen Z women, short mobile puzzle sessions: Lab42
  <https://www.lab42.com/blog/genz-gaming-whos-playing-what>
- NYT Wordle DMCA 2024 and the overreach debate: 404 Media
  <https://www.404media.co/nytimes-files-copyright-takedowns-against-hundreds-of-wordle-clones/>;
  Copyright Lately <https://copyrightlately.com/war-of-the-wordles-did-the-new-york-times-go-too-far/>;
  NPR <https://www.npr.org/2024/03/13/1238142507/cease-desist-new-york-times-wordle-spin-offs>
- Tetris v. Xio (rules free, look and feel protected): Loeb & Loeb
  <https://www.loeb.com/en/insights/publications/2012/06/tetris-holding-llc-v-xio-interactive-inc>;
  Wikipedia <https://en.wikipedia.org/wiki/Tetris_Holding,_LLC_v._Xio_Interactive,_Inc.>
- Sudoku trademark is Japan-only: Automaton
  <https://automaton-media.com/en/news/20230830-21220/>
- Only Connect wall (2008) as Connections' ancestor: Wikipedia
  <https://en.wikipedia.org/wiki/Only_Connect>
- Game rules: Queens/Tango <https://connectsafely.ai/articles/linkedin-games>;
  Crossclimb <https://www.crossclimbtoday.com/how-to-play>;
  Pinpoint <https://contentin.io/blog/linkedin-pinpoint/>
- Generators: Battlestar (Star Battle) <https://github.com/MeepMoop/battlestar>;
  Binairo generator <https://mortoray.com/writing-a-binairo-generator/>;
  Takuzu <https://en.wikipedia.org/wiki/Takuzu>

This is research, not legal advice. If Prepkin takes money for Plus, a one-hour
review with an IP lawyer before launch is cheap.
