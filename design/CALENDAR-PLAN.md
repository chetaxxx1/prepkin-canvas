# Calendar — plan, 2026-09-09

Three things George named as must-haves:

1. Canvas keeps the calendar up to date (due dates, events, and changes).
2. Students add their own dated tasks. High schoolers especially, whose teachers
   often skip Canvas or use a paper syllabus.
3. Point the camera at a syllabus, a whiteboard, a planner page, or a handout,
   printed or handwritten, and the app turns it into dated tasks.

And one shape change: games and micro-lessons share one tab (already true since
2026-09-06, the Play rail on Learn), and a calendar gets a home.

## Where it stands today

| Piece | Now | Gap |
|---|---|---|
| Tab bar (`RootView.swift:23`) | Home, Focus, Learn, Friends, Kin | No calendar. Five is the cap (hicks-law-plan house rule 2). |
| Canvas feed (`extension/background.js:604-636`) | Assignments per course + `/users/self/todo` | No `calendar_events` (class meetings, exam dates teachers add by hand). Changes to a due date do flow, since each sync replaces the list. |
| Own tasks (`GameState.addTask`) | Repeating templates: daily / weekdays / weekly | No one-off dated task. No "due Friday." |
| Task model (`DailyTask`) | id, title, kind, detail, dueAt, done, isLocked | `dueAt` exists but only Canvas fills it. No source tag, no time-of-day, no notes. |
| Photo import | Nothing | Everything. |
| Home (`HomeView.swift`) | Today's list, rebuilt daily from templates + Canvas | Only ever shows today. |

## Decision: Calendar is its own tab (George, 2026-09-09)

Six tabs: Home, Focus, Learn, **Calendar**, Friends, Kin. Calendar sits after
Learn so the two "school" tabs are next to each other.

This breaks the five-tab house rule on purpose. The reasons it is worth it: a
calendar is something students look for by name, and Home's job stays "what do
I do right now" while Calendar's job is "what is coming." The bar's full-colour
icons carry six as long as the Calendar icon is a clear object (a paper
calendar page with a coral ring on today). If the sim walkthrough shows the bar
too crowded at the largest type size, the fallback is the option below, not
cutting Calendar.

Fallback, for the record: Home grows a Today / Week / Month switch and the bar
stays at five. Same screens, one fewer door.

## Data model

One task type for everything, no matter where it came from.

```swift
enum TaskSource: String, Codable { case canvas, mine, photo }

struct DatedTask: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var kind: TaskKind          // canvas / study / life, unchanged
    var source: TaskSource
    var detail: String?         // course name, or "from photo: Bio syllabus"
    var dueAt: Date?            // day, plus time when we know it
    var allDay: Bool            // true for most photo and hand-typed tasks
    var notes: String?
    var done: Bool
    var isLocked: Bool          // Canvas said submitted
    var canvasId: String?       // so a Canvas edit updates the same row
}
```

Rules:

- Canvas rows are rebuilt from the feed every sync, same as now. A changed due
  date moves the row. A deleted assignment disappears. Nothing to merge.
- `mine` and `photo` rows are stored, like templates are today. They live in
  `GameState` next to `templates` as `datedTasks: [DatedTask]`.
- Repeating templates stay as they are. A recurring task shows on every day it
  applies to, computed, never stored per day. This already works.
- Coins: a dated own task pays what a `study` or `life` task pays today. A photo
  task pays the same. Canvas stays the only `canvas` kind. No new coin math.
- Done-state keys off `taskKey(id, on: day)` in the ledger, unchanged.

## Canvas keeps the calendar current

Extension side, `background.js` near line 636, one more paged fetch:

```
/api/v1/calendar_events?type=event&all_events=true&start_date=<today-7d>&end_date=<today+90d>&per_page=100
/api/v1/calendar_events?type=assignment&all_events=true&start_date=...&end_date=...
```

- `type=event` is the part we do not have: exam dates, class meetings, office
  hours a teacher put on the course calendar by hand.
- `type=assignment` overlaps what we already pull per course, but it carries
  section overrides (due Friday for section 2, Monday for section 3). Use its
  `assignment.due_at` when the two disagree. That is the student's real date.
- Push them through the existing `push_todo` bridge RPC as a third list next to
  tasks and courses. The bridge already carries a `tasks` list; add `events`.
- iOS `CanvasSync` decodes `events` into `DatedTask(kind: .canvas, source: .canvas,
  allDay: event.all_day)`. Events do not pay coins and cannot be checked off.
  They are things that happen, not things you finish. Render them as a quiet row
  with a clock, no coin chip.
- Sync cadence is unchanged. Whatever the extension does today for tasks is what
  the calendar gets.

Privacy line holds: the extension still reads only the student's own courses
and calendar through the API the student is already logged in to. It writes
nothing to Canvas.

## Students add their own tasks

Extend the day sheet's "add" row (`DayEditorView`) rather than build a second
one. One field, one date, one kind.

- Title (the only required thing).
- When: three chips, pre-answered. **Today** · Tomorrow · Pick a date.
  Pick a date opens the system date picker. Time is optional, off by default.
- Repeat: Once (default) · Daily · Weekdays · Weekly. Once creates a `DatedTask`.
  Anything else creates a template exactly as today.
- Kind: Study (default) · Life. Two chips, not three. Canvas is not a choice.

Entry points: the "+" on Home, and long-press on an empty day cell in Week or
Month, which pre-fills the date.

Edit and delete: tap the row, same sheet, with Delete at the bottom. Canvas rows
open a read-only version with a "Open in Canvas" link (the extension already
knows the URL).

## Photo to tasks

The pipeline, on the phone:

```
camera / photo library
      │
      ▼
 1. Vision  VNRecognizeTextRequest, .accurate, languages en-US
    on-device, free, handles print well and handwriting OK.
    Output: lines of text with bounding boxes.
      │
      ▼
 2. Structuring  text lines  →  [ {title, date, time?, course?} ]
    This needs a model that can read "Fri 9/12 quiz ch 3-4" and "Essay due
    next Monday" against today's date. Two options below.
      │
      ▼
 3. Review sheet  "Found 6 tasks"  each row: title, date chip, course chip.
    Tap a row to fix it. Swipe to drop it. One coral button: Add 6 tasks.
    Nothing is saved until this button.
      │
      ▼
 4. GameState.datedTasks += rows, source: .photo, detail: "from photo"
```

Step 2 is the real choice:

| Option | Where it runs | Cost | Handwriting | Works on |
|---|---|---|---|---|
| **A. Apple Foundation Models** (`FoundationModels`, `@Generable` struct) | On device | Free | Only what Vision already read | iOS 26 + Apple Intelligence phones (iPhone 15 Pro and newer) |
| **B. Claude API** with the photo itself (`claude-sonnet-5`, image input) | Anthropic servers via a bridge function | ~1¢ per photo | Best. Reads the image, not just OCR lines. Handles arrows, crossed-out items, tables | Every phone |
| **C. Claude API with OCR text only** | Same | ~0.1¢ | Same as A | Every phone |

Decision: **B. Claude reads the photo, with a consent line.** Handwritten
syllabi and whiteboards are the whole point of this feature, and OCR-then-LLM
loses table layout, which is how every syllabus is written. On-device (A) is
free but weak on handwriting and only runs on iPhone 15 Pro and newer with
iOS 26, so it would leave out most high schoolers' phones.

What it costs, per photo, at first-party API prices (skill cache 2026-06-24):

| Model | Photo + prompt in | Rows out | Per photo | 10 photos a semester |
|---|---|---|---|---|
| Haiku 4.5 | ~2,100 tokens at $1/M | ~300 at $5/M | ~0.4¢ | 4¢ |
| **Sonnet 5** | same at $2/M | same at $10/M | ~0.7¢ | 7¢ |
| Opus 5 | same at $5/M | same at $25/M | ~1.8¢ | 18¢ |

A phone photo shrunk to 1568px on the long side is about 1,600 image tokens.
Start on **Sonnet 5**: Haiku saves a third of a cent and reads messy handwriting
worse, Opus costs 2.5x and is only worth it if the 20-photo test set shows
Sonnet missing dates. At 1,000 students scanning 10 photos each, the semester
bill is about $70. The `parse_schedule` function takes the model id as a
setting so swapping is a one-line change.

The consent copy on first use:

> "This sends the photo to Prepkin's server to read it. We keep nothing. Skip
> this and type the tasks instead."

A is not built now. If it ever is, it gates on `#available(iOS 26, *)` plus a
`SystemLanguageModel.default.availability` check and becomes the free path.

### Plus only, 50 photos a month (George, 2026-09-09)

Photo scan is a **Prepkin Plus** feature. Typing tasks stays free for everyone.

- Free user taps the camera: the Plus sheet opens with one line of pitch,
  "Scan a syllabus and Sprout fills your calendar." Same sheet as the shop.
- Plus user: the camera opens. The sheet header shows "41 of 50 left this
  month." At 0 it says "Resets Oct 1" and the shutter is off. No overage.
- The count is per subscriber, not per phone. Key it on the App Store
  `originalTransactionId` so a reinstall or a second device does not reset it.
- Cost ceiling per Plus user: 50 × 0.7¢ = 35¢ a month against the monthly price. Fine.
- **Prices live in `design/PLUS-SPEC.md` section 5 and nowhere else.** Scanning is
  one of eight perks there, not the whole pitch. The `MARKETING-PLAN.md` conflict
  noted here was fixed on 2026-09-10.
- **The 50-a-month cap is copy, not code.** `PlusSheet.swift` says "50 a month" and
  no counter exists in `GameState` or `ScanSheet`. This cost ceiling assumes one.
  Build the counter or take the number off the sheet.

The bridge must know the caller is Plus. Today `Plus.swift` checks StoreKit on
the phone and the bridge knows nothing. Two ways, pick the first:

1. **Send the signed transaction with every scan.** The phone attaches the
   StoreKit 2 `jwsRepresentation` of its current Plus transaction. The edge
   function checks Apple's signature, the product id (`com.prepkin.canvas.plus.*`),
   and that it has not expired. No new table, no Apple server setup, and a
   faked request fails the signature check.
2. App Store Server Notifications writing a `plus` row per subscriber. More
   setup, and a second thing to keep in sync. Later, if the app needs Plus
   status on the server for other reasons (leagues, social).

The edge function `parse_schedule` takes a base64 image, today's date, the
student's time zone, and the transaction JWS. It calls `claude-sonnet-5` with a
fixed prompt and a JSON schema for the task list, and returns rows. No image is
stored. A `scan_count` table keyed by `originalTransactionId` and month holds
the tally, and the function refuses at 50 with a clear error the app shows.

The prompt asks for: title, due date as ISO, optional time, optional course
name, and a confidence 0-1. Rows under 0.5 confidence show with a dashed border
in the review sheet so the student looks at them first.

What is *not* in scope: reading the photo for grades, reading a whole textbook,
or any "AI tutor" wrapper. This is a scanner that outputs dated rows.

## UI

The Calendar tab opens on **Week**, with a Week · Month switch at the top,
pre-answered to Week. Home is untouched except for one thing: its "+" now
opens the same add sheet as Calendar's, so a task typed on Home shows on both.

**Week.** Seven columns, current day highlighted. Each cell lists task titles as
one-line chips coloured by course (Canvas already sends `colorHex`) or by kind.
Tap a chip to open it. Tap an empty cell to add. Swipe left/right for next and
last week.

**Month.** A grid with a dot per task, at most three dots then "+2". Tap a day
to open that day's list in a sheet, which is Today's list for another date.
Canvas events (not assignments) are a hollow dot.

Two floating actions bottom-right on the Calendar tab: **+** (coral, the one
primary) and a camera icon (quiet). Two, not three: the house rule.

Empty states: Week with nothing on it shows Sprout with "Nothing due. Point the
camera at a syllabus and I'll fill this in." One sentence, one camera button.

The extension panel gets the same events in its Today / This week filters. No
Month view on the laptop; Canvas already has one.

## Phases

| Phase | What ships | Depends on | Size |
|---|---|---|---|
| **1. Dated own tasks** | `DatedTask`, storage, add/edit/delete in the day sheet, rows on Home Today | nothing | 1–2 days |
| **2. Calendar tab** | Sixth tab + icon, Week · Month switch, week grid, month grid, day sheet, empty states | 1 | 2–3 days + one Claude Design handoff |
| **3. Canvas events** | Extension fetch, bridge `events` list, iOS decode, event rows | schema.sql re-run (still pending from M2) | 1 day |
| **4. Photo → tasks** | `parse_schedule` edge function on Sonnet 5, JWS check, 50/month tally, Plus gate, review sheet, consent line | 1, bridge project | 3–4 days |
| **5. Polish** | Reminders for own tasks (the day sheet already asks for notification permission), long-press to add, course colour on chips | 2 | 1 day |

Phase 1 and 3 can run in parallel. Phase 4 is the one that needs a real photo
test set: collect 10 syllabi and 10 handwritten planner pages before writing the
prompt, and score the parse against a hand-typed answer key. Under 90% on dates
means the prompt is not done.

## Built 2026-09-09

All four phases are in the tree, uncommitted. What exists:

| Piece | Where |
|---|---|
| `DatedTask`, `CanvasEvent`, `DayKey.date()/adding()` | `ios/Sources/Core/DatedTask.swift` |
| Storage, `tasks(on:)`, `events(on:)`, dated pay-once keys, add/edit/delete | `ios/Sources/Core/GameState.swift` |
| Calendar tab (Week strip + agenda, Month grid + day list, FABs, empty week) | `ios/Sources/CalendarView.swift` |
| Add / edit sheet | `ios/Sources/TaskEditorSheet.swift` |
| Scan sheet: consent → pick → reading → review → add; row fixer; camera | `ios/Sources/ScanSheet.swift` |
| Scan client: resize, JWS from StoreKit, POST, typed errors | `ios/Sources/ScanClient.swift` |
| Plus paywall (first one in the app) | `ios/Sources/PlusSheet.swift` |
| Sixth tab + calendar icon | `RootView.swift`, `PrepkinIcons.swift` |
| Extension: `mapEvents`, `eventQueries` (10 courses per call), `events` in the push | `extension/canvas.js`, `background.js` |
| Edge function | `bridge/functions/parse_schedule/index.ts` |
| Monthly tally table + `bump_scan` | `bridge/schema-scan.sql` |
| Fixture scorer | `bridge/scan-eval.mjs` |
| Tests: 17 iOS (`CalendarTests.swift`), 7 extension | green |

Two calls made while building, both easy to reverse:

- **Daily habits stay off the calendar.** First cut showed "drink water" seven
  times a week and "28 things due". The calendar shows dated things only:
  Canvas work, events, and tasks the student put on a day. Home keeps habits.
- **`-sampleCanvas` is a new launch flag** for the simulator, separate from
  `-unlockAll`, so the pairing tests keep seeing the real client. The scanner
  gate reads `-unlockAll`.

Not done, and needs George:

1. **Deploy the scanner** (below). Until then the camera path ends in "The
   reader is down" on a real Plus phone and "Scanning is a Plus feature" on a
   simulator, which is the right message for both.
2. **Run `bridge/schema-scan.sql`** in the Supabase SQL editor, after the
   `schema.sql` re-run that is still pending from M2.
3. **Collect the 20-photo test set** and run `scan-eval.mjs`. Nothing about the
   prompt is proven until this runs.
4. **Home's "+"**: the day sheet still adds habits only. A dated task is added
   from the Calendar tab. Left alone on purpose (one door per room).

### Deploying the scanner

```bash
# once (the CLI is not on this Mac yet)
brew install supabase/tap/supabase
supabase login
supabase link --project-ref aetvqwwiidrxiavbfgrl
supabase secrets set ANTHROPIC_API_KEY=sk-ant-... 
# optional, for the simulator and scan-eval.mjs: any long random string
supabase secrets set PARSE_SCHEDULE_DEV_TOKEN=...
# optional, while testing through TestFlight (sandbox receipts)
supabase secrets set ALLOW_SANDBOX_RECEIPTS=true

# every change
supabase functions deploy parse_schedule --project-ref aetvqwwiidrxiavbfgrl
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided to the function by
Supabase; nothing to set. The function verifies the App Store JWS chain against
Apple Root CA G3 by SHA-256 fingerprint (`APPLE_ROOT_SHA256` secret overrides
it if Apple ever rotates). On a simulator, run the app with the env var
`PREPKIN_SCAN_DEV_TOKEN` set to the same value as the secret, plus `-unlockAll`.

## Tests

- `GameStateTests`: add/edit/delete a dated task; it shows on its day and not
  the day before; done pays once; deleting a template does not touch dated tasks.
- `BridgeTests`: decode a payload with `events`; an event with `all_day` lands
  as all-day; a missing `events` key decodes fine (old extension).
- Extension `canvas.test.js`: calendar_events pagination and the section-override
  date winning over the course assignment date.
- Photo: a fixture folder of 20 images with a JSON answer key, run against the
  edge function, printed as a score. Not an XCTest; a script in `bridge/`.
- Gate: an expired or forged JWS is refused; the 51st scan in a month is
  refused; the count rolls over on the 1st in the student's time zone; a
  reinstall keeps the same count.
- iOS UI sweep: Home unchanged pixel-for-pixel, six-tab bar at all four type
  sizes (the largest is the one that will break), Week and Month at all four.

## Open questions

1. Decided: sixth tab. Fallback to Home Today/Week/Month only if the six-tab bar fails the sweep.
2. Decided: Claude Sonnet 5 reads the photo, with consent. Plus only, 50 a month. Opus 5 if the test set says so.
3. Should Canvas *events* (class meetings) show at all, or only exams and due
   dates? Start with everything and let the walkthrough decide.
4. Do photo tasks pay coins? Plan says yes, same as typed. Easy to cheat by
   scanning a fake list, but so is typing one. Coins for own tasks are already
   on the honor system.
5. Reminders: local notifications for own tasks the evening before? The
   permission prompt already exists in the day sheet.
