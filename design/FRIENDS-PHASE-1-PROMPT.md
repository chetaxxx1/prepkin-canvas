Build phase 1 of Friends for the Prepkin iPhone app, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas).

Read first, in this order, before writing any code:
1. design/FRIENDS-BUILD-PLAN.md — the plan. Phase 1 is section 5, row 1. Decisions D1–D3 in section 2 are settled: no accept step, nicknames stored only on the phone, no live room.
2. bridge/schema-social.sql and bridge/schema-friends.sql — the backend RPCs you are calling. Do not change their signatures.
3. ios/Sources/LeagueSync.swift and ios/Sources/StudySync.swift — the client shape to copy exactly: protocol, Supabase client that POSTs one RPC per call, a Mock, and the rule that a configured install never falls back to sample data.
4. ios/Sources/FriendsView.swift and `git diff` on it — another session redrew the layout on 2026-09-09. Bind data into it; do not change its layout.
5. PRODUCT.md and design/SOCIAL-PLAN.md — the house rules. No free text on the wire, no coins in any friend payload, no streaks, no "last seen", no exclamation marks.

Build, in this order, with a failing test first for each pure rule:
- ios/Sources/FriendSync.swift: FriendClient protocol + SupabaseFriendClient + MockFriendClient. Calls: myCode, rotateCode, addFriend(code), removeFriend, blockPlayer, reportPlayer, fetchFriends, setTank. Tolerant decoders like PodMember.
- Identity on demand: AppState.ensureIdentity() calls create_player the first time Add a friend opens, reusing LeagueIdentity. One identity for pods, friends and study.
- Replace `Friend` in Core/GameState.swift with the wire shape (id, adjective, noun, speciesID, lookID, costumeID, sceneID, level, tier, friendsSince, onShiftUntil?) plus two local fields: nickname: String? and seenAt: Date. displayName = nickname ?? PodName.name. Bump Store.currentVersion and add a migration that drops old friends, pendingFriendCodes, and the locally generated friendCode.
- GameState.friendCode becomes a cache of the server code from my_code. Delete pendingFriendCodes, addPendingFriendCode, removePendingFriendCode, the pending card, and the sampleFriends DEBUG list.
- Add a friend flow: type code → addFriend → on success a nickname sheet ("What do you call them?", 14 characters, same rule as naming a kin, skippable) → row appears. A null answer shows one quiet line: "That code didn't open anything. Check it with them." Never says whether the code exists.
- "Maya added you" card: on each fetchFriends, any id not in the cached list gets a card at the top of the tab, no buttons, tap opens the friend card and sets seenAt.
- Friend rows: nickname, StarPips, "on shift · N min left" when onShiftUntil is in the future. The existing Cheer button is hidden in phase 1 (vibes are phase 2).
- Quiet menu on a friend (··· or long-press): Remove (instant, silent), Block (confirm, coral text, never red), Report (confirm). One plain line under each saying exactly what it does.
- My code screen: code from the server, big and monospaced, Copy, Share (system share sheet with the plain code; the link is phase 3), and one row "Get a new code" that calls rotateCode with a one-line note that the old one stops working.
- Push setTank (costume, scene) whenever the active kin, look, costume or scene changes, throttled.

Test plan:
- Unit tests for every pure rule (nickname fallback, added-you diff, migration, on-shift line). Keep the suite green: `xcodebuild test` on the PrepkinCanvasTests scheme.
- Write test/fake-friend.js on the pattern of test/fake-phone.js: mints a player against the real bridge, sets a kin, prints its code, starts a 25-minute shift. Point the sim at the real bridge and type that code.
- Sim rules from .claude/skills/ios-walkthrough. Check `xcrun simctl list devices booted` first; on 2026-09-09 four booted sims starved the Mac. Build with DerivedData at the Xcode default, never inside the repo (iCloud).

Do not:
- Touch FriendsView layout, LeagueView, LeagueSync, or StudySync beyond what binding needs.
- Add an accept step, a typed name on the wire, a coin field, a badge count, or any "?"/lock tile.
- Run any schema file yourself. Ask George to confirm schema.sql, schema-social.sql and schema-friends.sql have been pasted into Supabase before the first live call; until then use the Mock and say so.

Finish with: what was built (file:line), test count and result, a screenshot of the tab with one real friend from fake-friend.js, and what is left for phase 2.
