# Claude Design briefs — the social layer

Three screens, in build order. **Paste `design/CLAUDE-DESIGN-PREAMBLE.md` first, then one
brief.** One screen per request, never two.

Read `design/SOCIAL-PLAN.md` before any of them — it says what each screen copies and why.

---

## Brief 1 — Friend board

Design the **Friend board**: the screen that shows how you and your friends did on today's
six daily games. It replaces the empty middle of the Friends tab.

**Copy this, closely:** the New York Times Games multi-game leaderboard — the one that
puts Wordle, Connections, Spelling Bee and the Mini in a single friends list. Same idea,
our six games. Look at how NYT handles a friend who has not played yet today, and do the
same thing.

**The data, and there is no other data.** From `PodMember` in `ios/Sources/LeagueSync.swift`
and `PlayRecord` in `Core/GameState.swift`:

- A friend is a **generated two-word name** (`PodName`, e.g. "Quiet Otter") plus their kin
  as a species id, a look id, and a level of 1–3. There is no photo, no username, no real
  name, and there never will be. Draw the kin as a dashed KIN box, per the preamble.
- Six games, in the rail's own order: **Daily Word, Ladder, Thread, Balance, Pearls, Trace.**
- Per game per person, exactly one of: a **solve time** (`2:14`), **not played yet**, or
  **did not finish**. Nothing else is known. No score, no accuracy, no attempts.
- The header names the **puzzle number**, not the date — "Puzzles 251". Two friends in
  different time zones reach number 251 hours apart and must still land on one row
  together. Never write "Today" in the header.

**States to draw, all of them:**

1. **No friends yet.** The honest empty state. The current copy is
   "Just us for now. That's fine by me." — keep that voice. One button: Add a friend.
2. **One friend, neither of you has played.** The state most people meet first.
3. **Full board, four friends,** a mix of times, blanks and did-not-finish.
4. **You are last.** This must not read as a punishment. Nothing red, no arrow, no
   "behind" — that word is banned in this app and `NotificationPlannerTests` enforces it.

**Under the board:** the last seven puzzle numbers as a small strip, so a good week is
visible. NYT calls it score history. Draw it, but it is one row, not a chart.

**What must not appear:** coins on this screen (the board is bragging, never pay), a
demotion zone, a rank number bigger than the names, anyone's rating, any free text.

---

## Brief 2 — Visiting a friend's tank

Design **the screen a student sees when they tap a friend on the board**: that friend's
kin, in that friend's room, and the one thing you can do about it.

**Copy this, closely:** Finch's friend screen — you see their birb in its birbhouse, you
see the friendship level, and you send a free **Good Vibe** from a fixed list of 14. The
vibe costs nothing, arrives as a cheerful in-app message, and sends your bird over to
visit theirs. We are copying the free half of Finch and skipping the paid gifts entirely,
because our coins are honour-system and a gift would launder them.

**What is on the screen:**

- The friend's kin at its real stage, in its real look and costume, in their real room
  scene. Read-only. Dashed KIN box, caption the coat and the star count.
- Their two-word name and the six-game result strip from Brief 1, small.
- **One action: Send a vibe.** A row of drawn preset cards. Draw **eight**, named and
  drawn, no emoji: they are the entire vocabulary of this app's social layer. Warm and
  plain — a wave, a high five, a "nice one", a "good luck today". Nothing that implies
  competition, pity, or a nudge to study.
- After sending: your kin appears in their tank for the rest of the day, and the button
  becomes a settled state. **One vibe per friend per day** — Finch's limit. Draw the sent
  state and say exactly what it says.

**Guard rails to make visible in the design:** a visitor can never move decor, spend
coins, change a look, or type anything. If a control could be mistaken for one of those,
redraw it.

**States:** not yet visited today · sent · a friend whose kin you have never seen before ·
a friend who has not opened the app in a while (say nothing about that — draw the normal
screen; absence is not a status).

---

## Brief 3 — Add a friend

Design the **Add a friend** sheet. `FriendsView.swift` already has one; this replaces it
now that the codes will actually reach a server.

**Copy this, closely:** Finch's and Duolingo's friend-code flows. Two ways in, one call:

1. **Share a link.** The primary action. `prepkin.app/f/CODE`, sent in Messages. Draw the
   iOS share sheet trigger, not the sheet itself.
2. **Your code**, eight characters in the existing `XXXX-XXXX` shape, large and tappable
   to copy.
3. **Enter theirs.** The field that already exists.

**The honest line.** Until an Apple Developer account exists, a shared link opens a web
page rather than the app. Write one plain sentence that tells a student what will happen
when their friend taps the link. Do not hide it and do not apologise for it.

**States:** empty · code entered and waiting · added · a code that does not exist ·
your own code entered by mistake.

**Not in this sheet:** contacts access, any permission ask, QR codes, "find friends
nearby", or a count of how many people are on the app.
