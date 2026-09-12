Prove the Prepkin iPhone app live, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas). Every tab is an A or A− in code as of 2026-09-12 evening, and none of the social or paid parts has ever run against a real server: Friends, pods, vibes, the weekly board, pairing on the new schema, the scanner, Plus purchases, the widget with real Canvas tasks. An app cannot be an A while its Friends tab says "No pod yet" forever. This session turns mock-green into live-green, on a fresh save, and records the proof the store listing will show.

Before you start, George has to do three things (about 40 minutes), and you ask him, in one message, and wait:
1. Paste `bridge/schema.sql`, `bridge/schema-social.sql`, `bridge/schema-friends.sql` (and `bridge/schema-pacts.sql` if present) into the Supabase SQL editor, in that order.
2. Deploy the scanner (`bridge/functions/parse_schedule`, the Anthropic key, `bridge/schema-scan.sql`) per design/CALENDAR-PLAN.md "Deploying the scanner".
3. Upload one TestFlight build (the Apple team is set) so a real phone can be on the other end.
If he does only step 1, run everything except the scanner and push; say what was skipped.

Read first:
1. design/FRIENDS-BUILD-PLAN.md section 6 (testing without a second human), test/fake-friend.js if it exists, test/phone-loop.js and test/fake-phone.js (how a second player is faked against a bridge), ios/Sources/FriendSync.swift, LeagueSync.swift, StudySync.swift, Core/WeekBoard.swift.
2. Memory facts: only schema.sql was live on 2026-09-10 and three allowlists had drifted (friends-phase-1); probe the RPCs before trusting the bridge; `-unlockAll` is sticky per simulator and skips first run, so proofs run on a simulator that never had it (simulator-contention); the widget's done-marks are paid by the app on next open (widget-and-notifications-built); the Shop has never been judged on a fresh save (second-look-2026-09-12).
3. design/RELEASE-CHECKLIST.md, the "George, before the store" list, and design/store/app-store-listing.md so the proof matches what the listing claims.

Do, in this order, one commit per numbered item where code changes:

1. Bridge probe. A script that calls every RPC the app uses (create_player, my_code, add_friend, fetch_friends, push_today, fetch_today, send_vibe, fetch_visits, push_result, friend_board, start_focus, friends_focusing, join_pod, fetch_pod, push_points, claim_code, bind_writer, push_todo, fetch_todo, fetch_flags) against the live bridge with a throwaway player and prints one line each: ok, or the error. Fix every mismatch between the SQL and the Swift decoders (the allowlist drift is the known one). Delete the throwaway rows.

2. Friends, live. Two real players: the app on a fresh simulator, `test/fake-friend.js` (write it from the plan if missing) as the second. Add by code, see the fish, nickname, block, unblock by re-adding from the other side (should fail: blocked), report, rotate code and prove the old code stops working. Then vibes: send one, see the visitor in the tank, the one-per-day rule. Then the board: push results for both, open the board, Monday sheet with `-fakeMonday` replaced by a real settled week if the clock allows, otherwise say so. Then Study Together: the fake starts a shift, the app shows the row, Join starts a shift. Screenshot each.

3. Pods, live. Join a pod with the throwaway players so the pod has three; confirm the ladder, "settles Monday", and that nothing ever moves down. Screenshot.

4. Pairing, live. Pair the app with the real extension against the sandbox Canvas (or the fake Canvas if the sandbox is down; say which), confirm tasks arrive, a hand-in pays on the phone, the widget shows the real task titles, and the evening check-in names them. Screenshot Home, the widget, the notification.

5. Plus, live sandbox. Buy monthly and yearly with the StoreKit sandbox on a real device through TestFlight if step 3 above happened; otherwise the simulator's .storekit file. Restore. Refund. Confirm the gift week fires after the third Canvas task and ends without a charge. Scan one real syllabus photo if the reader is deployed; record the rows it found.

6. Fresh-save review. With no `-unlockAll` ever, walk the first run as a college student, finish three tasks, and screenshot Home, the Shop with real picks and a real shortfall, Kin with one coat, Play, Calendar with the three tasks, Friends with one friend. Grade the Shop against Finch's shop (https://mobbin.com/screens/7966062b-2480-48b7-abce-d868ca9eb345) in three lines; it has never been judged on a real save.

7. Reduce Motion. `SproutImage` ignores it app-wide (focus-a-plus). Honour it: stills instead of the swim, no celebrate, no reveal animation; the web tank already honours it. Test with the simulator's accessibility setting. One commit.

8. Cold start. Measure app launch to a drawn Home on the simulator and on the TestFlight phone (Instruments or timestamps): the tank web view boot is the known cost. Record the numbers; if Home-to-interactive is over two seconds on the phone, file it as the next session, do not fix it here.

9. Store proof. Replace the seven App Store screenshots in design/screenshots/appstore-6.9/ with shots from this fresh save at 1320×2868, and check every sentence of design/store/app-store-listing.md against what you saw. List any claim that is not yet true.

Do not: build a feature, change a layout, touch Theme.swift, or commit anything from another session's working tree. If a proof fails, fix the bug behind it if it is under fifty lines and yours; otherwise write it down with the file and line.

Finish with: the probe table (one line per RPC), the screenshots per step, the Shop grade, the Reduce Motion commit, the cold-start numbers, the listing claims that are not yet true, and the one-line status of each of George's three steps.
