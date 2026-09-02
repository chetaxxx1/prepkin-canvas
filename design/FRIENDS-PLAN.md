# Friends tab — plan (2026-08-31)

The tab exists today as mock data: a story ring, a "this week's coins" leaderboard,
and a flat friend list (`ios/Sources/FriendsView.swift`, `design/screenshots/06-friends.png`).
That is the generic version. This document is the direction that replaces it, the
decisions already made, and what still needs George.

---

## 1. The one idea

A friends tab in a companion app should answer **"who's around, and can I sit with
them?"** — not "who's winning."

Every screen below follows from that. The mascots are the social object. You see your
friends' slimes, not their numbers. The single most-used feature should be sitting down
to work at the same time as someone else, which is the thing that actually helps a
17-year-old finish a problem set.

## 2. What each reference app contributes

| App | What we take | What we refuse |
|---|---|---|
| **Finch** (Tree Town) | Friends are a *place you visit*, not a list. Good Vibes: send a fixed, pre-written encouragement, and **the sender** gets the small reward. Goal Buddy: one shared goal with one friend. Gifts. | Nothing much — Finch is the closest fit. |
| **Instagram** | The story tray with an unseen ring, the tap-through full-bleed viewer, the reaction bar at the bottom of a story, "close friends". | Follower counts, likes as public numbers, photo upload, infinite scroll, DMs. |
| **Dolphin SAT** | Head-to-head on a timed game (Dolphin Party). A friends board. The idea that studying can look like a feed. | Streaks, leagues that **demote** you, global leaderboards against strangers, "your streak needs saving" push at 11pm. |

## 3. What we add that none of them have

1. **Study Together** — a shared focus session. Two to four slimes stand in one scene
   while one timer runs. Nobody can talk. Both sides get their coins at the end. This is
   Focusmate / Forest's "Plant Together", and it is the reason to open the tab daily.
2. **Same class** — the Chrome extension already knows the student's real Canvas course
   names. If two friends both have "BIOL 12 — Quiz 3 Friday", say so. No other app on
   this list can. Opt-in, per course, off by default.
3. **Daily Word head-to-head** — the app already ships a Wordle (`WordleView.swift`).
   Wordle's real social layer is the shared result grid. Show a friends strip for today's
   word: who solved it, in how many. Letters stay hidden until you have solved it too.

## 4. Rules this tab must not break

Carried from the Home and Learn handoffs, plus three new ones for social.

- **Coins pay for finishing.** Never for grades, never for correct answers, never for
  beating a friend. A shared focus session pays both people the same as a solo one.
- **No streaks. No leagues that demote.** Any number shown can only go up.
- **The mascot is never punished** and neither is a friend's. There is no
  "Maya hasn't studied in 5 days" and no wilting plant.
- **No free text, anywhere.** No DMs, no comments, no captions, no custom status. Every
  message a student can send is chosen from a fixed set of drawn cards. This is a
  deliberate safety decision for a teen app: it removes bullying, grooming, and content
  moderation from the product in one move.
- **No photos, no camera.** "Stories" are auto-generated from what you actually did.
- **Ranking is opt-in and never the default.** The default weekly card is a group total
  ("you and 4 friends: 41 tasks, 6h focus"), not a rank. See the open decision below.
- No emoji. Every icon a drawn vector in the palette.

## 5. Identity — decided

No accounts, no email, matching the rest of the app. A **friend code**, same alphabet as
`Core/PairingCode.swift` (`A-HJ-NP-Z2-9`, no ambiguous glyphs), plus a display name the
student types and a chosen slime. That is the whole profile. Codes are shared out of band
(text, AirDrop, in person) exactly like Finch's.

Bridge work this implies: the current `pairings` table is one row keyed by a pairing code
and holds a Canvas to-do list. Friends need a second table (a profile per friend code,
plus an accepted-edges table) and a small "today" blob per person. That is real backend
work, and it is **not** part of the design pass.

## 6. Screens

Ordered by how early a real user hits them.

1. **Empty state — no friends yet.** Every single user sees this first, and today it does
   not exist. It has to teach the friend code, show what the tab becomes, and not read
   like an ad for having friends.
2. **Add a friend** — your code, big and copyable; a field for theirs.
3. **Request received / accepted.**
4. **The Yard** — the top of the populated tab. Friends' slimes standing in one scene,
   reusing the existing scene art system. Someone in a live focus session is shown
   focused; someone who has not opened the app today is just quietly absent, never sad.
5. **Today** — a horizontal row of moment cards with an unseen ring, Instagram-shaped.
6. **Moment viewer** — full bleed, their slime, the one thing they did, a fixed reaction
   row across the bottom.
7. **Study Together — invite**, **live room**, **finished**.
8. **This week, together** — the group card. Plus the friends board as its alternate.
9. **Friend card** — tap a slime: their name, their slime at its level, what they did
   today, send a vibe, study together, and the quiet menu with remove / block / report.
10. **Send a vibe** — the fixed picker, six drawn cards.
11. **Daily Word friends strip** — two states, before and after you have solved it.
12. **Same class card** — the Canvas crossover, plus its opt-in toggle.
13. **Privacy & safety** — what friends can see, per row, with everything sensitive off
    by default.

## 7. Open decisions for George

1. **Ranking.** Default recommendation: group total, with a friends board available
   behind a toggle and ranked on **focus minutes**, not coins — ranking the currency
   makes people grind for money instead of for work. Alternative: no board at all.
2. **Same-class sharing.** Real course names are real personal data on a remote
   Supabase instance. Recommendation: ship the design, gate the build behind an explicit
   per-course opt-in, and store a hash rather than the course title if that turns out to
   be enough for matching.
3. **Study Together liveness.** A real live room needs presence (websockets or polling).
   A cheaper v1 is asynchronous: "Maya is focusing until 4:15 — join her" with both
   timers running independently. Recommendation: design the live room, build the cheap
   version first.

## 8. Build order (after the design comes back)

- M-F1: profiles + friend codes + accept, on the bridge. Empty state, add friend, friend
  card. No feed yet.
- M-F2: the Yard and Today moments, generated from the ledger the app already keeps.
- M-F3: Study Together, asynchronous version.
- M-F4: Daily Word strip, vibes, group weekly card.
- M-F5: same-class matching, behind opt-in.
