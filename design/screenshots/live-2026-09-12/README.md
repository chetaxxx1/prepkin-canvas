# Live proof — 2026-09-12

Everything here ran against the real Supabase bridge (`aetvqwwiidrxiavbfgrl`), on a
simulator (`prepkin-live`, iPhone 17 Pro, iOS 26.5) that never had `-unlockAll` and
started from an empty save. The second player is `test/fake-friend.js`; the laptop
is the real extension on a fake Canvas (`test/phone-live.js`) because the sandbox
VM was off. George did step 1 only (the four schema pastes): no scanner, no
TestFlight, so nothing here ran on a real phone.

The first-run shots and the first Friends pass were lost when the Mac rebooted
mid-session (`/tmp` was cleared). The walk was done; the shots of it are gone.
Everything from the Home screen onward was reshot.

## Bridge probe (`node test/bridge-probe.js`)

35 functions, 33 ok on the first run. The two fails were one bug: the three
allowlists (`kin_species`, `kin_looks`, `kin_costumes`) did not know the ids the
app sends (a picked coat as species, a costume id as look, 25 costume ids), so a
friend's fish was silently coalesced to slime / classic / none. Fixed in the SQL;
`bridge/patch-allowlists-2026-09-12.sql` is the paste (with the `fetch_todo` fix
below). Until it is pasted, every friend draws in this phone's coat: that is why
Maya is a coral ninja in these shots when she is butter in a hoodie.

| RPC | Result |
|---|---|
| fetch_flags | ok, `{"rules":[]}` |
| create_player | ok |
| join_pod | ok, same pod for both throwaways |
| fetch_pod | **DRIFT** species `coral`→`slime`, look `hoodie`→`classic` |
| push_points | ok (points follow the phone; the tier never drops) |
| my_code | ok, stable across asks |
| set_tank | ok |
| add_friend | own code → null; **DRIFT** costume `flannel`→`none` |
| fetch_friends | ok, `since` + `shift` keys present |
| push_today / set_sharing / fetch_today | ok |
| send_vibe | ok, second same day → false |
| fetch_visits / fetch_sent | ok |
| push_result / friend_board | ok (not called by the app; fake-friend only) |
| start_focus | ok, `2026-09-12T18:36:49.73204+00:00` parses in Swift |
| friends_focusing / end_focus | ok |
| propose_pact / answer_pact / fetch_pacts | ok |
| report_player / rotate_code / remove_friend / block_player / leave_pod | ok |
| claim_code / bind_writer / push_todo / fetch_todo / push_state / delete_pairing | ok |
| forget_player | ok, both throwaways gone |

## Friends, live (20–42)

Add by code, nickname, card, report, block, rotate, vibes both ways, board, Study
Together both ways. Blocked Maya re-adding by my code → `null`; her friend list →
`[]`. Old code after rotate → `null`, new code → my row. The Monday sheet could not
be a real settled week: today is Saturday. Not faked.

## Pods (50–51)

Six in the water, ladder says "10 more and you're in Shallows on Monday", "nothing
here ever moves you down". The 5,000-coin Helpful Sturgeon is somebody's earlier
test row on the live bridge.

## Pairing (60–64)

Fake Canvas, real extension, real bridge. Six tasks arrived on the phone; two
already-handed-in ones paid on arrival (50 → 110). Alex handed in Problem Set 7 on
the laptop, next open paid 30 (→ 140) and armed the gift week. Small and medium
widgets draw the real titles. The 4 PM check-in: see the last section.

## Plus (70)

No StoreKit sandbox: the `.storekit` file only attaches under Xcode's Run, which
this session could not drive, and there is no TestFlight build. Not proven: buy,
restore, refund. Proven: the gift week armed on the third Canvas hand-in
(`plus.giftStartedAt = 2026-09-12T19:45:59Z`, ends 09-19) with no transaction
behind it, and the Shop reads "Thanks for the Plus" on it.

## Fresh save (10, 70–73)

Home after three tasks, Shop with real picks (Reef 140 = exactly affordable, the
rest short), Kin at one star, Play, Calendar with the Canvas tasks, Friends with one
friend (32).

## Reduce Motion (80–81)

`SproutImage` now reads the environment and never fires its keyframe emotes under
it (landed inside 3b95a50, see below). The Home tank stops wandering and bubbling
but keeps a 2 px breath: that is the web build's own choice (`pose()` under
`reduceMotion` returns `sin(bob)*2`), in the Sprout repo, not here.

## Cold start (simulator only)

Five runs, `simctl launch` → first frame with the task list → first frame with the
kin in the web tank, machine load 170–400 from three other sessions:

| run | list drawn | tank kin drawn |
|---|---|---|
| 1 | 1.46 s | 4.47 s |
| 2 | 1.45 s | 13.9 s |
| 3 | 1.37 s | 5.56 s |
| 4 | 0.84 s | 3.05 s |
| 5 | 0.68 s | 2.19 s |

The list is interactive under 1.5 s. The tank web view is the cost, 1.5–3 s on top
even on the quiet runs. No phone number: no TestFlight build.

## Store shots

`design/screenshots/appstore-6.9/` was reshot from this save on an iPhone 17 Pro
Max sim (1320×2868, status bar 9:41) — the save was copied across.
