# Launch audit — what LAUNCH-PLAN.md is missing

Run 2026-09-06 by 16 agents against the working tree, not against the plan. Seven areas
(Chrome store rules, Apple store rules, iOS gaps, extension gaps, Supabase bridge,
legal/privacy, build-and-test), each re-checked by a second agent that was told to
try to prove the first one wrong.

`design/LAUNCH-PLAN.md` is the plan of record and this file does not replace it. This is
the delta: what the plan gets wrong, what it leaves out, and what the audit confirmed is
already fine so nobody re-opens it.

---

## 1. Blockers the plan does not mention at all

These stop a submission. None appear anywhere in LAUNCH-PLAN.md.

| # | What | Evidence | Hours | Owner |
|---|------|----------|-------|-------|
| B1 | **The 1024×1024 App Store icon file does not exist.** Only the empty asset slot. Xcode refuses the archive, so this blocks the upload, not the review. | `ios/Resources/Assets.xcassets/AppIcon.appiconset/` holds only `Contents.json`, 109 bytes | 1–3 | both |
| B2 | **No `CFBundleDisplayName`.** The app installs to the Home Screen as `PrepkinCanvas`, one word, no space — the raw target name. It also reaches App Store Connect that way. | `grep CFBundleDisplayName` across `project.yml` and `project.pbxproj` → zero matches. `PRODUCT_NAME = "$(TARGET_NAME)"` at `project.pbxproj:509` and `:605` | 0.5 | claude |
| B3 | **Existing iOS screenshots are 1206×2622.** App Store Connect will not accept them. 6.9" wants 1320×2868. Every current shot has to be retaken. | `sips` on the simulator screenshots in `design/screenshots/` | 2–4 | claude |
| B4 | **`ITSAppUsesNonExemptEncryption` is unset**, so every single upload re-asks the export-compliance question. | not in `project.yml` | 0.2 | claude |

Add roughly **4 to 8 hours** to the plan's Tue Sept 8 block.

---

## 2. Where the plan is factually wrong

| # | Plan says | Actually | Effect |
|---|-----------|----------|--------|
| W1 | "97 uncommitted files" (Sun Sept 6 checkpoint) | **107 and climbing.** `git status` went 91 → 97 → 107 across the audit, and `dist/prepkin-canvas-0.6.0.zip` changed from 4,476,134 to 4,481,340 bytes mid-run. | The build you submit will not correspond to any commit. Freeze, commit, tag, then run `bridge/package.sh` from the tag. |
| W2 | "shoot the five 1280×800 Chrome screenshots" (8h, Wed Sept 9) | **Four already exist at exactly 1280×800**: `design/signoff/extension-ui/panel-open.png`, `banner-picker-0/1/2.png`. Found by `sips`-sweeping all 1,277 images under `design/`. | Saves 2–4h. Note `design/RELEASE-CHECKLIST.md` item 4 names four *wrong* files — they are all 1280×720. |
| W3 | Risk 8: "put-back fix within 24 hours" if a Canvas deploy breaks a page | **There is no mechanism.** Risk 2 in the same file says Chrome review is 1–3 weeks with no expedite. Nothing bridges the gap. | See M2 below. The 24-hour promise cannot currently be kept. |
| W4 | "the popup's phone card links to the App Store, and the app's unpaired Home card links to the Chrome listing" (Launch sequence, line 134) | **Neither link exists.** `grep -rn "chromewebstore\|apps.apple.com" ios/Sources extension/` → zero hits in either direction. `extension/popup.html` contains zero `<a>` tags. | Two-device onboarding dead-ends on both sides. See M3. |
| W5 | The 440×280 tile is one line in an 8-hour listing block | Confirmed genuinely absent — zero of 1,277 design images are 440×280 — and it is one of only three *mandatory* Chrome listing images. Worth its own line. | 1–2h, do not let it hide inside the listing task |

---

## 3. Missing entirely, ranked by damage

### M1 · The extension's own auto-update breaks every open Canvas tab — 3–6h
Chrome pushes updates silently. Content scripts in already-open tabs are orphaned and
`chrome.runtime.sendMessage` throws "Extension context invalidated".

`extension/content.js` makes **13** `chrome.runtime` calls and contains exactly **1**
`catch`. There is no `chrome.runtime.onUpdateAvailable` listener anywhere, no
`chrome.runtime.id` liveness check, and no re-injection path in `background.js`.

It is worse than a dead panel: `boot.js` has already put skin classes and a `<style>` on
`<html>`, and `chrome.runtime.getURL()` stops resolving once the old context dies. The
student is left on a half-skinned Canvas page with a dead buddy panel.

This is the exact failure mode that got BetterCampus district-blocked in Sept 2025, and
the plan ships updates on Oct 12 and Nov 2 — mid-semester, both of them.

### M2 · No remote kill and no rollback — 3–5h
Every `fetch()` in `background.js` goes to Canvas or a bridge RPC. `pullWallet`
(`background.js:395–425`) reads only `coins`, `owned` and `league` out of `fetch_state`.

The plan's own trust section lists a "visible turn off on this page control" as a
shipped-build requirement. `grep -i "turn off\|off on this page"` across popup and
content → nothing.

Cheapest fix that keeps the 24-hour promise: one `skinOff` field on the state blob that
already flows to every paired laptop. Same-hour kill, no store review.

### M3 · Neither half tells the student the other half exists — 2–4h
The app says "Pair with the Chrome extension to see Canvas here." (`AppState.swift:149`)
and "Type this into the Prepkin extension in Chrome." (`DayEditorView.swift:329`). No
link, no store name, no QR code. The popup's phone card (`popup.html:206`) reads "Open
the app, tap the sliders on Today, and type the code it shows" — which assumes the app
is already installed.

Blocked until both listings exist, so it lands the week of go-live.

### M4 · No support or bug intake inside either product — 2–4h
`grep -rn mailto extension/ ios/Sources ios/Resources` → zero. The only report control
that exists is honest but write-only: `LessonDeckView.swift:544` says the report is
"written to `GameState.cardReports` on this phone and there is no backend to receive it",
and the sheet tells the student so out loud.

Both store listings require a support address. Neither product gives a student any way
to reach it.

### M5 · Zero crash or error visibility, and no decision that this is fine — 1–3h
`grep -rln "Sentry\|Crashlytics\|os_log\|Logger("` over `ios/Sources` → nothing.
PRODUCT.md forbids analytics, which is a real principle, but nobody chose the free
substitute.

iOS gets crash reports free through Xcode Organizer and ASC Metrics **if** George opts in
and looks. The extension has no equivalent at all — a service-worker exception on a
student's laptop is invisible forever, and the only signal would be a one-star review.

### M6 · The tripwires fire on numbers nothing produces — 2–3h
The plan's Sunday scorecard needs Tank Pass screen opens plus four rates
(view→install, install→pair, pair→first-coins, first-coins→buy). Only two are obtainable
today: ASC units and Chrome installs.

Pairing count means hand-querying `pairings` for rows with a bound writer. RLS is on with
zero policies (`grep 'create policy' bridge/schema.sql` → none), which is the *correct*
design because everything goes through `SECURITY DEFINER` RPCs — but it means that query
needs the service_role key in the SQL editor, and the procedure is written down nowhere.
The on-device counter does not exist.

Six dated tripwires (Oct 11, Oct 18, Nov 8, Nov 13) currently fire on nothing.

### M7 · No version handshake between extension, bridge and app — 2–4h
No version travels in either direction. Nothing in the `push_todo` / `push_state`
payloads carries one, and `bridge/schema.sql` has no version column.

Chrome auto-updates every laptop within hours of a publish; phones update whenever the
student allows it. Old-app / new-extension is guaranteed for days. The plan ships
extension 0.7 on Nov 2 and iOS 1.1 on Nov 9.

It degrades quietly today because both sides ignore unknown keys — but nothing proves
that, no test exercises a mixed pair, and there is no way to detect a mismatch. January's
`pass: true` crossing the bridge needs this first.

### M8 · An expired pairing looks exactly like a brand-new one — 1–2h
The row is deleted 30 days after the last sync (`schema.sql:47`, `:252`). `fetch_todo`
returns null for a missing row (`schema.sql:191–198`) → `BridgeError.notPairedYet` →
**"Waiting for your laptop to send its first list."** (`AppState.swift:177`).

A student back from winter break sits on "waiting" forever, with nothing telling them to
make a new code. The extension gets the mirror case exactly right already:
"Your phone unpaired this laptop. Tap New code in the app and paste it here."
(`background.js:590`). Only the phone is missing the message.

### M9 · No App Store ratings path — 1–2h
`grep -rn "SKStoreReview\|requestReview" ios/Sources` → nothing. A new app with zero
ratings is close to invisible in App Store search, yet the plan budgets 400 organic App
Store installs off that listing.

Placement matters: Apple caps `AppStore.requestReview` at three prompts a year and it must
not follow a reward. After a finished Focus shift — never after a purchase or a coin flight.

### M10 · The Canvas sandbox VM trial dies mid-finals — decision + ~1h
`design/CANVAS-TEST-PLAN.md:9,177,567` — the only real-Canvas regression suite
(`test/live.test.js`) runs against `canvas-sandbox` on a Google Cloud **trial**, reachable
only over an SSH tunnel. The trial ends about Dec 4.

"Run the live smoke check after every Canvas deploy" is the stated defence against the
exact failure that gets extensions district-blocked. It evaporates two weeks into finals,
inside the Nov 20 – Dec 18 freeze, when George is least able to react.

### M11 · No Terms of Service anywhere — 1.5–3h
Not a hard store blocker with no accounts, but the pod shows a nickname, fish and coin
count to up to 19 strangers, some of whom are minors. A short terms page (no warranty,
not affiliated with Instructure, pod acceptable use) is what an IT admin looks for after
the privacy page.

---

## 4. Real bugs found in passing

| Where | What | Hours |
|-------|------|-------|
| `extension/popup.js:9–18` | **Five taps on the version number grants 9,999 coins and every look.** Comment says "For testing". It is in the packaged 0.6.0 zip today. | 0.25 |
| `CollectionView.swift:76`, `SavedCardsView.swift:48`, `TrackMapView.swift:72` | Three back buttons at 38–40pt, under the 44pt minimum. The fix already works in `KinShopView.swift:89–93`: `.padding(3).contentShape(Rectangle()).padding(-3)` | 0.5–1 |
| `test/ios-flows.sh` | 19 pass / 7 fail, reproduced exactly. All three failure clusters are stale script assumptions, not app bugs: the button now reads "Clock out early", `flow_lesson` never calls `home()`, and `flow_shopshort` waits on a toast only scene purchases fire. | 1–2 |
| `PrepkinIcons.swift:28`, `LessonFigures.swift:2386`, `LearnIcons.swift:131` | Three Swift 6 `Sendable` warnings | 0.5–1 |
| `ios/Sources/ChibiStageView.swift` | 56 lines, zero call sites. Dead since the Sprout migration. | 0.25 |
| `package.json:4` | Says `0.5.0` while `extension/manifest.json:4` says `0.6.0` | 0.1 |
| Shop / Sprout web build | **Thirteen costume sets are fully drawn and composited by the SproutWeb JS, and nothing on the Swift side ever sets `skinID`.** They are unreachable. | 4–8 |

---

## 5. Checked and genuinely fine — do not re-open these

- **Learn content is complete**, not placeholder: 54 lessons / 365 cards across five tracks,
  and all 54 figure names resolve to a real case in `LessonFigures.swift` — zero fall
  through to `default: EmptyView()`. Daily Word has 901 answers and 14,693 guesses, about
  2.5 years with no repeat.
- **The coin economy is tuned**, not the SPEC placeholders. `Models.swift:116` still reads
  30/20/10, but the sinks around it were built out: nine species at
  0/300/400/500/700/700/800/900/1200 on a five-band tier ladder, upgrades at 100/250.
- **Save data survives a phone upgrade.** `Store.swift` is versioned (v4), keeps a backup,
  and quarantines rather than deletes an unreadable file.
- **Day 2 / day 7 / holidays are handled.** `Core/Notifications.swift` has evening nudges
  dropped once the list is clear, a three-day "still here" comeback, an 8am quiet-hours
  floor, and a header rule that nothing counts a streak or warns about loss.
- **The skin's degrade-to-plain-page and kill switches are real**, and the extension works
  fully with the bridge unreachable.
- **The stale-course filter shipped** — `enrollment_state` / `term.end_at` / `workflow_state`
  handling is committed and correct. Release-prompts item 4 is closed.
- **No network destination outside Canvas and the configured bridge.** No eval, no remote
  code, no CDN, no web font, no analytics. Verified by reading every fetch.
- **The coin shop is IAP-safe as designed** — coins are earned, never sold.
- **The public repo carries no real student data.** 190 tracked signoff images and 321
  tracked screenshots opened and checked: sandbox student "Alex Rivera" and mock courses
  only. The 60 *untracked* screenshots still need a look before the push.
- **COPPA, Illinois SOPPA and NY Ed Law 2-d are out of scope.** California SOPIPA is the
  one worth a real lawyer's read.
- **The data deletion path exists and works.** Verified end to end.

---

## 6. Corrected hours

Focused working hours for one person with an agent. External waiting is excluded.

| Bucket | Agent hours | George hours |
|--------|-------------|--------------|
| Chrome Web Store, everything to "submitted" | 3–8 | 3–8 |
| App Store, everything to "submitted" (excl. Tank Pass) | 8–17 | 5–11 |
| Blockers this file adds (§1) | 4–8 | 0.5 |
| Missing work this file adds (§3) | 18–36 | 2–4 |
| Bugs found in passing (§4) | 7–13 | 0 |
| Tank Pass build + art (already in the plan) | 27–36 | sign-off |

The plan's own build list totals about 100 hours to Sept 30. This audit adds **29 to 57**,
of which about 8 are hard blockers.

George's own clicking and deciding across both stores is **8 to 17 hours**. That is not the
bottleneck. The calendar is set by three things only he can start, two of which have an
external clock: Apple enrollment, the support inbox, and the hosted privacy page.

---

## 7. The five risks that could cost a week or more

1. **Chrome drops the extension into in-depth review** over `optional_host_permissions:
   https://*/*` plus `scripting`. Warning sign: "Pending review" past five business days.
   Mitigation: submit with the one-origin justification already written — `popup.js:121`
   requests exactly one origin behind the Connect button, and `background.js:38–41`
   registers content scripts per site at runtime. Keep a narrowed build as plan B. Never
   cancel and resubmit; it resets the queue.

2. **Apple rejects under 5.2.1 / 5.2.2** for "Canvas" in the app's own name. Decide the
   name *before* creating the App Store Connect record — a rename after rejection costs the
   full resubmit cycle plus every screenshot. The plan already settles on "Prepkin for
   Canvas"; `extension/manifest.json:3` still says "Prepkin Canvas Sync".

3. **Apple enrollment stalls.** Choose Individual, not Organization — Organization needs a
   D-U-N-S number (1–5 business days) and a verification call, turning a 2-day wait into a
   2-week one. 2026 forum reports show individuals stuck 2 to 9 weeks.

4. **`schema.sql` has never been executed against a real Postgres.** The bridge tests mock
   all seven functions in JavaScript (`test/fake-canvas.js:8`). "Safe to re-run" comes from
   reading the SQL, not running it. The free tier allows two projects — rehearse it on a
   throwaway one first. Watch for the `pg_cron is not enabled` **warning**
   (`schema.sql:255–262`, `:1119–1128`): it does not stop the script, it just silently
   leaves cleanup unscheduled.

5. **The submitted build corresponds to no commit.** Watched it happen live during this
   audit. Freeze the tree, review, commit, tag, then package from the tag. Never hand-zip
   `extension/` — `package.sh` is the only path that gates the write on passing tests.

Runner-up, worth naming on its own: **no human has ever run this app on a physical iPhone.**
The tank, the haptics and a real Canvas pair exist only there. This needs no developer
account — a free Xcode team installs it today.
