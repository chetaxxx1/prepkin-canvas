# Prepkin Canvas — Spec v0.1 (2026-08-28)

A Finch-style companion app for students. A slime chibi sits on your home screen.
Canvas (the school LMS) feeds it your real assignments through a Chrome extension.
You complete daily tasks — school work and life care — to earn coins. Coins level
up your chibi (3 levels each) and buy new chibis.

Decisions made 2026-08-28: **iOS app + Chrome extension** (not web-only), and
**placeholder-box art** for v1 (real slime art comes later).

---

## 1. The loop

1. Student logs into Canvas in Chrome. The extension quietly syncs their to-do list.
2. The iOS app shows today's tasks: Canvas assignments + study tasks + life tasks
   (sleep on time, drink water, take a break — the Finch half).
3. Completing a task pays coins. The chibi reacts (bounce/celebrate).
4. Coins upgrade the active chibi (Lv 1 → 2 → 3) or buy new chibis in the shop.

**Economy rule (carried from Prepkin research): pay per completed task, never per
grade or per correct answer.** Performance-graded rewards are the most damaging
pattern in the motivation literature. Finishing is what gets paid.

## 2. The chibi

- Sits center-stage on the home screen, like Finch's bird. Always present, never
  a meter you feed. It is glad you showed up; it does not punish you.
- **5 preset animations** (TFT-style, fixed loops, no procedural blending):

  | Animation | Trigger |
  |---|---|
  | `idle` | default — slow squish loop |
  | `bounce` | task completed |
  | `celebrate` | all of today's tasks done, or level-up |
  | `wave` | app open / greeting |
  | `sleep` | nighttime, or no activity today |

- **3 levels per chibi**, bought with coins (Lv1→2: 100, Lv2→3: 250). Levels are
  visual evolutions — 1★ the pear, 2★ longer fins, 3★ Lumen (he glows) — no stat changes, nothing gated.
- **Looks** are a second axis, per kin (`OwnedChibi.skinID`, default `classic`). A look
  rides the same three stars rather than replacing them: Ninja is band at 1★, fin wraps
  at 2★, and at 3★ the Lumen glow burns through the suit in the kin's colour. Nothing in
  the app sets `skinID` yet — how a student earns a look is still open.
- **Shop**: more chibi species purchasable with coins (300–500 each). Starter
  slime is free. Switching the active chibi is free.
- v1 renders a placeholder box wired to the real animation state machine, so
  real art (sprite sheets or Lottie/Rive) drops in without logic changes.

## 3. Daily tasks

Three kinds, one list:

- **Canvas** — synced assignments with due dates. Auto-created, auto-cleared when
  submitted (later; v1 is manual check-off).
- **Study** — user-added or preset (e.g., "20 min SAT practice").
- **Life** — Finch-style self care presets ("sleep by 11", "eat breakfast",
  "10 min walk"). User picks which ones are on their daily list.

Coins: Canvas task 30, study 20, life 10. Numbers are placeholders; tune later.

## 4. Architecture

```
Chrome extension  ──▶  bridge (TBD)  ──▶  iOS app
  reads Canvas          Supabase or         SwiftUI, offline-first,
  REST API with         similar free        tasks + chibi + coins
  session cookie        tier; keyed by      persist locally
                        pairing code
```

- **Extension** (MV3): runs on `*.instructure.com`. When the student is logged in,
  it calls Canvas's own REST API (`/api/v1/users/self/todo`,
  `/api/v1/users/self/upcoming_events`) with the session — no password stored,
  no scraping fragile HTML. Stores results in `chrome.storage.local`.
- **Bridge**: built, on the Supabase free tier. The app shows an 8-character
  pairing code and claims it on the bridge; the extension trades that code, once
  and within fifteen minutes, for its own write token. Every read and write after
  that needs a token, not the code. See `bridge/schema.sql`.
  No accounts, matching the Prepkin no-accounts position.
- **iOS app**: SwiftUI. All state persists on device. Canvas data is a bonus
  feed, not a requirement — the app fully works with study + life tasks alone.

### v1 scope (this repo, today)

- iOS app runs in the simulator: chibi stage (placeholder box, real state
  machine), today's task list with **mock** Canvas data, coins, upgrade, shop.
- Extension skeleton loads in Chrome and fetches the real Canvas to-do list into
  local storage. The bridge is stubbed with a TODO.

### Known constraints

- No Apple Developer account yet → simulator only, no device, no TestFlight,
  no CloudKit. (Same constraint as Prepkin-iOS.)
- This folder lives under `~/Desktop` (iCloud-synced) → never write build
  output into the repo. Use default DerivedData or /tmp.

## 5. Open questions (need George)

1. ~~Bridge choice~~ — settled: Supabase, token-authenticated pairing.
2. Chibi art pipeline: commissioned sprite sheets vs Rive/Lottie vs AI-generated.
3. Does completing a Canvas assignment auto-verify via the API (submission
   exists), or stay honor-system check-off?
4. Relationship to Prepkin-iOS (Chip, SAT app): separate app, or same app later?

## 6. Milestones

- **M1 (now)**: simulator app with mock data + extension skeleton. ✅ this session
- **M2**: real bridge; extension → app sync end to end.
- **M3**: real slime art for 3 levels + 5 animations; swap into the stage.
- **M4**: notifications, streak-free "glad you're back" logic, more species.
