# Friends — the build plan (2026-09-10)

George's call on 2026-09-09: Friends ships working, not hidden. This file is how, in the
fewest moving parts, with every feature the tab needs. It replaces the build orders in
`FRIENDS-PLAN.md` §8 and `SOCIAL-PLAN.md` §8, which it agrees with on direction and
disagrees with on three decisions, all marked below.

Read in this order: `SOCIAL-PLAN.md` (why nothing typed ever crosses the wire),
`bridge/schema-social.sql` (most of the backend, already written, never run), and the
three design prompts `CLAUDE-DESIGN-PROMPT-FRIENDS-V3-A/B/C.md` (the screens).

---

## 1. Where it actually stands

More is built than the tab lets on. The gap is not features; it is that nothing is
wired end to end and the schema has never been pasted into Supabase.

| Piece | State | Where |
|---|---|---|
| Player identity (uuid + token, name from word lists) | **Built, live for pods** | `schema.sql` `create_player`, `LeagueSync.swift` |
| Friend code, server-minted, rotatable | Schema written | `schema-social.sql` `my_code`, `rotate_code` |
| Add / remove friend by code | Schema written | `add_friend`, `remove_friend` |
| What a friend can see of you (kin, look, costume, scene, stars, tier) | Schema written | `public_player`, `set_tank` |
| Friend board for the six games, keyed on puzzle number | Schema written | `play_results`, `push_result`, `friend_board` |
| Vibes and tank visits, one per friend per day | Schema written | `vibes`, `send_vibe`, `fetch_visits` |
| Study Together (see who is on shift, Join) | **Built on the phone**, schema written | `StudySync.swift`, `focus_sessions` |
| Focus ready screen shows a friend on shift | **Built** | `FocusView.swift:157` |
| List my friends | **Missing** | nothing returns the list without a puzzle number |
| Block, report | **Missing** | no table, no check in `add_friend` |
| "What they did today" for moments and the weekly card | **Missing** | no daily stats row |
| Push notifications (added you, on shift, sent a vibe) | **Missing** | no device token table, no APNs |
| Share link `prepkin.app/f/CODE` | **Missing** | needs the associated-domains file on the site |
| The tab itself | Mock, being redrawn now | `FriendsView.swift`, another session is mid-edit |

What the phone stores today that has to go: `GameState.friendCode` is generated
locally by `PairingCode.generate()`, so nobody can look it up. `pendingFriendCodes` is
a list of codes that were never sent anywhere. `Friend` has `weekCoins` and a free-text
`lastActivity`. All three are replaced in §4.

---

## 2. Three decisions, decided here unless George says otherwise

**D1. No accept step. Handing someone your code is the consent.**
The V3-A prompt drew "Request received → Add back". `schema-social.sql` says the
opposite and it is right: Duolingo and Finch both add on code entry, and a pending
state doubles every screen (sent, received, expired, cancelled) for a benefit nobody
asked for. What protects the student is the code being short-lived on purpose:
**Rotate code** makes an old one stop working, and **Block** (new, §3) stops one person
for good. The "request received" card becomes a "Maya added you" card on next open,
informational, dismissed by a tap. No button on it.

**D2. Names on the wire are word-list names. Nicknames live on your own phone.**
`SOCIAL-PLAN` F6 wins over V3-A's typed display name: no student-typed string is
stored on the bridge, ever. But an undergrad adding their roommate needs to see
"Maya", not "Brisk Otter". So: when you add a friend, the sheet asks "What do you
call them?" and stores that **only in your save file**, exactly like a contact name
in Phone. The wire carries two integers. Your screen shows "Maya". Their screen shows
whatever they typed for you. Nobody moderates anything. Fourteen characters, same
rule as naming a kin.

**D3. Cheap presence forever. No live room.**
Study Together stays two independent timers with a server-set end time, which is
already built. A live room needs websockets, a presence server and a reason. Forest
ships without one. The one thing to add is a **push** when a friend starts a shift
(§5, phase 3), because a card you only see when you open the app is not an invite.

---

## 3. The whole feature list, and what each needs

Ordered by what a student does first.

| # | Feature | Backend | Phone | Design |
|---|---|---|---|---|
| 1 | My code, big, copyable, plus Share (Messages sheet with the link) | `my_code` ✓ | `FriendSync.myCode`, share sheet | exists (add screen) |
| 2 | Add by code, instant | `add_friend` ✓ | field → call → nickname sheet → row | exists + nickname sheet |
| 3 | Friend list: kin at real look, stars, nickname, "on shift" pill | **`fetch_friends` new** | `FriendSync.friends`, cache in save | exists (kin row) |
| 4 | "Maya added you" card on next open | `fetch_friends` diff | compare to cached list | V3-A screen 1, no buttons |
| 5 | Friend card sheet: tank at their look/costume/scene, stars, friends since, today lines, Send a vibe, Study together, ··· | `public_player` ✓ + today stats | `FriendCardSheet` | V3-A screen 3 |
| 6 | Remove · Block · Report | `remove_friend` ✓, **`block_player`, `report_player` new** | quiet menu | V3-A screen 4 |
| 7 | Rotate code | `rotate_code` ✓ | one row under my code | one line |
| 8 | Study Together: friend on shift → Join | ✓ built | ✓ built | V3-B, mostly done |
| 9 | Send a vibe, their kin visits my tank today | `send_vibe`, `fetch_visits`, `fetch_sent` ✓ | six drawn cards, visitor in the web tank | V3-A cards + Sprout web build |
| 10 | Friend board, six games, today's puzzle number | `push_result`, `friend_board` ✓ | push on every game end, board screen | SOCIAL-PLAN §4 |
| 11 | Today lines and the weekly group card | **`push_today`, `fetch_today` new** | write counts on every save | V3-C screen 2, V3-A screen 6 |
| 12 | Privacy sheet (what friends see, per row) | flags on `players` **new** | toggles | V3-A screen 5 |
| 13 | Push: added you · on shift · sent a vibe | **`device_tokens` new + edge function + APNs key** | register token, handle taps | one line each |
| 14 | Share link opens the app with the code filled in | AASA file on `prepkin.app` | associated domains, URL handler | none |
| 15 | The Yard (friends' kin in your scene) | nothing new | Sprout web build draws N kin | V3-C screen 1 |
| 16 | Same class | its own decision, hashed course ids | opt-in per course | V3-C screen 5 |

Nothing in this list carries a coin across the wire, and nothing carries a string a
student typed. That is what keeps it buildable by one person.

---

## 4. How it is built

### Backend: one more additive file

`bridge/schema-friends.sql` (written alongside this plan) adds what §3 marks new,
in the exact style of `schema-social.sql`:

- `fetch_friends(p_player, p_token)` → list of `public_player` rows with
  `friends_since` and `on_shift_until` (a join on `focus_sessions`). One call draws
  the whole tab.
- `blocks(blocker, blocked)`. `block_player` deletes the friendship and inserts the
  row; `add_friend` refuses, silently, when either side has blocked the other. A
  blocked person gets the same null as a wrong code.
- `reports(reporter, reported, at)`. `report_player` inserts one row. There is no free
  text, so a report is a pair of ids and a time, and it is read by hand in the
  Supabase table view. Apple's guideline 1.2 asks for a way to report and block;
  this is the smallest one that is real.
- `daily_stats(player, day, tasks, focus_min, lessons, games)` with `push_today`
  (upsert, four small integers, capped) and `fetch_today(day)` for friends. This is
  what "Focused 45 min" and "You and 4 friends: 41 tasks, 6h focus" are made of.
  Two weeks are kept, then purged like results.
- `players.share_today boolean default true`, `players.share_board boolean default
  true`. `public_player` and `fetch_today` respect them. That is the privacy sheet.
- `device_tokens(player, token, platform, at)` and `set_device_token`. Unused until
  phase 3, harmless until then.

Run order, once, in the Supabase SQL editor: `schema.sql`, `schema-social.sql`,
`schema-friends.sql`. Every file is safe to run twice.

### Phone: one client, one model, one sheet

- **`FriendSync.swift`**, same shape as `LeagueSync.swift`: a protocol, a Supabase
  client that POSTs one function per call, a mock, and the rule that a configured
  install never falls back to sample data. Calls: `myCode`, `rotateCode`,
  `addFriend(code)`, `removeFriend`, `blockPlayer`, `reportPlayer`, `fetchFriends`,
  `pushToday`, `fetchToday`, `sendVibe`, `fetchVisits`, `fetchSent`, `pushResult`,
  `friendBoard`, `setTank`.
- **Identity is minted on demand.** `LeagueIdentity` exists only after joining a pod
  today. `AppState.ensureIdentity()` calls `create_player` the first time the Add a
  friend screen opens, and every friend call goes through it. One identity serves
  pods, friends, board and study; it already does for two of those.
- **`Friend` becomes the wire shape plus two local fields:**
  `id, adjective, noun, speciesID, lookID, costumeID, sceneID, level, tier,
  friendsSince, onShiftUntil?` from the server, and `nickname: String?` and
  `seenAt: Date` from this phone. `weekCoins` and `lastActivity` go. A friend's
  display name is `nickname ?? PodName.name(adjective:noun:)`.
- `GameState.friendCode` becomes a cache of the server's code, filled by `my_code`.
  `pendingFriendCodes` and `addPendingFriendCode` are deleted along with the
  pending card.
- **Today stats** are pushed from `Store.save` the same way the widget snapshot will
  be: tasks done today, focus minutes today, lessons finished today, games solved
  today, read from the ledger. Throttled to once a minute.
- **`FriendCardSheet.swift`**: their kin drawn by the existing web tank with their
  `TankSnapshot` (species, look, costume, scene, level) in read-only mode; stars;
  "Friends since Sep 9"; up to three today lines; Send a vibe row; Study together
  (Join when on shift, else the caption); the ··· menu.
- **Vibes** are six cards, indices 0–5 into a list the app ships. Sending one puts
  the sender's kin in the receiver's tank for the day. The visitor is drawn by the
  Sprout web build; that animation needs a GIF sign-off like every animation.
- **Push (phase 3)**: `UNUserNotificationCenter` registration is already wired for
  reminders. Add `didRegisterForRemoteNotifications` → `set_device_token`. A
  Supabase edge function `notify` is called by `add_friend`, `start_focus` and
  `send_vibe` (via `pg_net`) and sends one APNs payload with a fixed body: "Maya
  added you", "Maya is on shift until 4:15. Join?", "Maya sent you a vibe". Needs the
  APNs auth key (.p8) from the developer account, which exists since 2026-09-09.

### The tab, screen by screen

Another session is redrawing `FriendsView.swift` right now (the water hero, the pod
and ladder rows, the coral Add button). This plan does not touch layout. It only
says what each region binds to once the sync exists:

- Water hero: `friends` from `fetch_friends`, kin drawn at their look. A friend on
  shift wears the focused emote.
- Add a friend: unchanged, then the nickname sheet, then the row appears.
- "Maya added you" card: friends in the fetched list whose id is not in the cached
  list. Tap opens the friend card and marks it seen.
- Friend list rows: nickname, stars, "on shift · 12 min left" when true, the clap
  becomes vibe card 0.
- This week: `fetch_today` for the last seven days, summed, group total by default,
  "Show the board" toggle reveals focus minutes ranked. Coins are never on it.
- Friend board (games): its own screen from the Play header on Learn, and a row on
  Friends. Draw only when at least one friend exists.

---

## 5. Order of work

| Phase | What | Days | Blocked on |
|---|---|---|---|
| **0** | Paste the three schema files into Supabase. Run the bridge tests. | ½ | George, in the SQL editor |
| **1** | `FriendSync` + mock + identity on demand. New `Friend`. My code from the server, add by code, nickname sheet, friend list, "added you" card, remove, block, report, rotate. Bind the redrawn tab. `test/fake-friend.js` plays the second person against the real bridge, the way `fake-phone.js` plays the laptop. | 3 | phase 0, the other session finishing the layout |
| **2** | Friend card sheet with the read-only tank. Today stats push + fetch, today lines, weekly group card. Vibes with six cards and the visitor in the tank. Friend board for the six games. Privacy sheet. | 4 | the six cards drawn, visitor animation signed off |
| **3** | Push for added you / on shift / vibe. Share link with the AASA file on prepkin.app. TestFlight to two real phones. | 2 | APNs key, the site host serving `/.well-known/apple-app-site-association` |
| **4** | The Yard. Same class, if George decides it. | later | web build multi-kin, the course-hash decision |

Phase 1 ships alone if it has to: a student can add a friend, see their fish, see them
on shift and join. That is a working Friends tab. Everything after makes it a daily one.

---

## 6. Testing without a second human

- `test/fake-friend.js`: mints a player, sets a kin, prints its code, then loops:
  starts a 25-minute shift, pushes a game result, sends a vibe, pushes today stats.
  Point the sim at the real bridge, type the printed code, and the tab fills in.
- Two simulators against the real bridge is the true end-to-end. Not on this Mac
  while four sims are booted; the 2026-09-09 review notes the machine ran out of
  memory. One sim plus `fake-friend.js` covers everything but push.
- TestFlight is the only way to test push and the share link. The developer account
  exists now, so it is a build upload away.

---

## 7. What this plan refuses

- No accept step (D1). No typed names on the wire (D2). No live room (D3).
- No coins, ever, in any friend payload. No gifts. `SOCIAL-PLAN` F5.
- No ranking on coins. The board that can be toggled on ranks focus minutes.
- No "last seen", no greyed-out friend, no "Maya hasn't studied". A friend with no
  today row has no today lines and nothing else.
- No global search, no "find friends from contacts", no suggestions. A code, read
  out loud or sent in a text, is the only way in. That is the safety model.
