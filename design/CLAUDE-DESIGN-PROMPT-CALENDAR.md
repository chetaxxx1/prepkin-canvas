# Prompt for Claude Design — the Calendar tab (one brief, seven artboards)

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the line.
Attach `design/handoff-calendar/built-week.png`, `built-month.png` and `built-empty.png`
— that is the tab as it runs today, not the older `calendar-2026-09-09/` shots. Turn the
**Mobbin** connector on in claude.ai → Settings → Connectors before you send.

This file replaces both of the old briefs. The sheets brief
(`CLAUDE-DESIGN-PROMPT-CALENDAR-SHEETS.md`) was deleted on 2026-09-10; its screens are
artboards 5 and 6 here.

---

I'm redesigning the **Calendar** tab of Prepkin Canvas. It is built and running. George's
call on 2026-09-10 is a full redesign, and the house rule from the games and social builds
applies: **copy the mechanics of something that ships, exactly. Never inspired-by.**

Every pattern below names the app and the Mobbin screen it comes from. Open each link and
look at the image before you draw. You do not have to search for these; the URLs are here.

## What the tab is for

Home is "what do I do right now." Calendar is "what is coming." It shows only dated things:

- **Canvas work** on its due day (`CanvasItem`: title, course name, course colour
  `colorHex`, `dueAt`, submitted or not). Pays 30 coins when finished.
- **Course events** from the Canvas calendar (`CanvasEvent`: title, `courseName`,
  `colorHex`, `startAt`, `endAt`, `allDay`, `location`). Exams, class meetings, office
  hours. They happen; they are not finished, so no checkbox and no coins.
- **The student's own dated tasks** (`DatedTask`: title, `day`, optional `minute`, kind
  Study 20 or Life 10, `notes`).

Daily habits (drink water, 20 min study) are **not** here. They stay on Home. Read
`design/CALENDAR-PLAN.md` before you draw.

## What is on screen today, and what the review said

The 2026-09-09 review graded the tab **B−**. Some of it has been fixed since; this is the
list as it stands on 2026-09-10.

| Finding | Now |
| --- | --- |
| Three bands of chrome before content | Two. The Week · Month pill and ‹ Today › moved inside the strip card. |
| Seven day headers for three items | Past empty days fold into one strip. **Future empty days still cost a line each.** |
| Three add buttons | One coral `+`, plus a small `+` in every day header. |
| Task rows and exam rows the same weight | Fixed. An event is a ruled entry with a rail as long as the event; a task is a white card. |
| A scanner promise on the empty state | **Still there.** "Point the camera at a syllabus and I'll fill this in." |
| Two dead "Type them instead" buttons | Being wired in code this session. |

What is still wrong, and what this brief fixes:

1. The title says **"Calendar"**. A student on a calendar knows they are on a calendar.
   The title should be the month.
2. The **Week · Month** pill is a mode switch for something that should be one gesture.
3. **Empty days exist on screen.** Four empty future days push three real items below the
   fold.
4. There is **no day view**. A student cannot see "Chem lab 1 to 3, problem set due at 5."
   The tab knows class meetings and due times and never draws them against a clock.
5. The empty state is a card with a mascot and two buttons, and it sells a feature that is
   **not deployed**.

## What to copy, and from where

Open every link. Take the mechanics, not the look — every colour, radius and font still
comes from `Theme.swift`.

### A. The spine: Things 3 "Upcoming"

One vertical list of **only the days that have something on them**. A big day number with
the weekday beside it in the left margin. "Tomorrow" spelled out where the weekday would
be. Calendar events sit in a small tinted block at the top of each day (time + title, no
checkbox); tasks with checkboxes under them. Empty days do not exist on screen. Further
out, a month header ("April") with just the dated items under it.

This one pattern fixes both "seven headers for three items" and "an exam looks like an
essay."

- https://mobbin.com/screens/1f3adaff-5def-4789-a938-456435ecd4df
- https://mobbin.com/screens/590f4dd6-1a6d-45a3-91c3-3508a762b041
- https://mobbin.com/screens/3055273e-f993-4d94-a3cb-13c1bb281726

### B. The header and ticker: Microsoft Outlook agenda

Month name as the title. A seven-day ticker under it with today filled. A small drag
handle under the ticker that pulls it down into a full month grid and pushes it back up.
That replaces the Week · Month pill and one band of chrome.

The agenda below uses "Today" and "Tomorrow" words, the time in the left column with the
duration under it, and an "in 4 min" chip on the next thing.

- https://mobbin.com/screens/3a21d1a0-0bec-472b-9c07-8a33dddf45cf — agenda, ticker, handle
- https://mobbin.com/screens/a6fd424b-68a6-40e5-ad65-e0257449ff2a — the month grid it opens into

### C. Load under the ticker: Binance's calendar

Tiny course-colour marks under each day number, with "+3" when there are more than fit,
and a Today button top right. Ours are 20×3 bars today (`DayLoadStack`); make them read as
load the way these do at arm's length. Tell me which you chose and why.

- https://mobbin.com/screens/8339ece6-cfa5-4995-a7ab-e52de69fb419

### D. Empty days and empty weeks: Google Calendar schedule view

Today with nothing on it is one inline line — "Nothing planned. Tap to create." — on the
same row as the date, not a card. Empty weeks fold into one line with the date range.

Ours: **"Nothing due. Tap to add."** on today only, and the folded **"Thu – Sun · free"**
strip that already exists for the rest. No card, no illustration, no scanner line.

- https://mobbin.com/screens/1f51ee68-947e-4ce0-b371-4d307313f77b
- https://mobbin.com/screens/ce0f4482-6d5d-44b6-a59c-6547a5dc0448

### E. The day view: Structured's timeline

Tap a day header or a ticker day and the day opens on a vertical time axis. A now-line.
Class meetings and office hours as blocks (they are `CanvasEvent`s). Due times as pins.
The gap between two items is labelled with the free time and carries one quiet "Add task"
inside it. Tiimo does the same gap line: "11h 50m → No plans" in grey, with a `+` at the
right of the gap row.

This is where a student sees "I have Chem lab 1 to 3, the problem set is due at 5."

- https://mobbin.com/screens/574482d9-3640-4553-805e-944f11f27428
- https://mobbin.com/screens/26fae4e6-2163-4d93-8c47-5bd9839cb369
- https://mobbin.com/screens/2e5e28b9-c537-46b3-89fe-5d46c59fe6a3 — the Tiimo gap line

### F. Class blocks: Saturn Calendar

The calendar built for exactly our age. "Now" shows today's class blocks with the current
one lit and a time line through it, and tomorrow's block under it. Copy the block shape and
the now-line.

Our classes come from Canvas events, so there is no manual setup. When a student is not
paired, show Saturn's "Got your class schedule?" card as the **one** setup prompt, pointing
at the laptop pairing, not at a form.

- https://mobbin.com/screens/f4d20fce-ae76-45c2-8d1f-6132b25fa29c
- https://mobbin.com/screens/d59d5b9e-5ce1-444f-9e99-88210bee983e
- https://mobbin.com/screens/01c14d42-74ef-4046-af3c-c38f8e9fa88c

### G. Adding: Todoist quick add

One coral `+` opens one text field above the keyboard. The date is typed in words and lit
up as it is recognised: **"Bio quiz fri 4pm"** highlights `fri 4pm` in a tinted pill inside
the field, and the chip under the field reads **"Friday 4:00 PM"**. Chips: Date, Time,
Study/Life. That is the whole add flow for most tasks. The full editor (notes, repeat) is
one more tap, never the default.

- https://mobbin.com/screens/b2e34aae-de00-4c7b-8194-cf07c9755c01 — the parsed date, lit
- https://mobbin.com/screens/d73506db-d527-4084-a876-3cf7f1e037f7 — the empty quick add
- https://mobbin.com/screens/5a23ab49-44fa-4db6-8f59-0f365a4f8569 — the full editor behind it

### H. The date picker: Things 3 "When"

One sheet: Today, This Evening, a compact month grid, and a reminder time. Tap a day,
done. Copy it exactly for the Date chip.

- https://mobbin.com/screens/44ec9290-bd1c-4b82-acec-b0b3c32c847b
- https://mobbin.com/screens/6675a19f-4911-443c-b127-62965cd36d9a

### I. Overdue: Todoist and ClickUp

Both put overdue in its own group at the top, with a plain-text action on the right of the
header. Ours is one group labelled **"Still counts"** in amber, never red. Rows do not
fade — they are not done. Copy the placement, not the colour.

- https://mobbin.com/screens/ecb1790e-e9b8-494c-8022-224b41476d34

### Deliberately not copied

Google Calendar's month artwork banners (decoration). Structured's energy meter (a meter).
Saturn's chat-to-create and friend directory. Todoist priorities and flags. Anything with a
streak. Any red.

## Draw these, on the 402 × 874 canvas

Content starts at y = 99. Keep 90 pt clear above the tab bar. Use the sample data in
`MockCanvasClient` (`ios/Sources/CanvasSync.swift`) so the artboards match what the
simulator shows:

| Thing | Course | Colour | When |
| --- | --- | --- | --- |
| Ch. 5 Problem Set | Physics 13 | `#FF6F61` | today, all day |
| Essay outline | Writing 5 | mint | tomorrow, 9:00 AM |
| Office hours · Moore 202 | Intro Psych | `#9BC8F2` | tomorrow, 2:00–3:00 PM |
| Week 3 quiz | Intro Psych | `#9BC8F2` | Saturday, 4:00 PM |
| Midterm 1 | Physics 13 | `#FF6F61` | Sunday, 9:00–11:00 AM |
| Bio quiz, ch. 3–4 | *typed, no course* | warm grey | Saturday, 4:00 PM |

---

### Artboard 1 — Upcoming, three days of content

The default screen. **A (spine) + B (header and ticker) + C (load marks).**

- Title: **September** — the month the ticker is showing, `Theme.font(34, .black)`,
  `Theme.ink`. `CoinBadge` stays top right.
- Under it, the seven-day ticker: narrow weekday letter over the day number, today on a
  `Theme.coral` disc in white, load marks under each number, past days at 40%.
- Under the ticker, the drag handle: a 38 × 4.5 pt `Theme.hex(0xE2D8C6)` pill, centred.
  Say the grab target you want around it (44 pt minimum).
- A **Today** pill top right of the ticker row, the way Binance does it. It only appears
  when the ticker is not on today's week.
- Then the list. **Only days with something on them.** Each day: a big day number in the
  left margin with the weekday beside it, `Today` / `Tomorrow` spelled out for the first
  two. Events in a small tinted block at the top of the day, then tasks.
- One coral `+` floating bottom right, 60 pt, `Theme.coral`, 78 pt above the bottom. That
  is the **only** add button on the screen — the per-day `+` in the current build goes.
- The kin peeks over the bottom of the scroll, as it does today. Dashed box, 78 pt, coat
  mint, one star.

Give me the day-header anatomy in pt: number size, weekday size, the gap, the rule.

### Artboard 2 — the ticker pulled into the month grid

**B.** The same screen with the handle dragged down. The month grid takes the ticker's
place; the list below is the selected day's items. Six rows of seven so the grid never
jumps height between months. Load marks in the cells, other-month days dimmed, today on a
coral disc, the selected day tinted `Theme.coralSoft`.

Tell me the drag: what the handle follows, what happens at the halfway point, what the
rubber-band at each end feels like, the durations and curves, and what Reduce Motion does
instead.

### Artboard 3 — the empty today

**D.** Today has nothing on it. One inline line at the top of the list:

> **Today** Sep 10 · Nothing due. Tap to add.

Then the folded strip for the rest of the week: **"Thu – Sun · free"**.

No card. No mascot in the middle of the screen. No scanner line — **the scanner backend is
not deployed** (`design/CALENDAR-PLAN.md`, "Deploying the scanner") and nothing on this tab
may promise it until it is. The kin peek at the end of the scroll is the only warmth, and
it stays.

Show me the same artboard a second time in the **not paired** state: Saturn's "Got your
class schedule?" card (F), one card, pointing at the laptop pairing. Its exact copy:

> **Got your class schedule?**
> Open Prepkin on your laptop and your classes land here.
> **Show me how**

### Artboard 4 — the day timeline, two class blocks and a due pin

**E + F.** Tapping a day header or a ticker day pushes this screen. Tomorrow, with:

- 9:00 AM — **Essay outline** due, as a **pin** (a small marker on the axis, not a block)
- 2:00–3:00 PM — **Office hours**, Intro Psych, Moore 202, as a **block**
- 3:30–5:00 PM — **Chem lab**, as a second **block** (invent nothing else; this is the
  shape I need to see twice)
- the **now-line** across the axis at the current time, with the time on the axis in bold
- between the pin and the first block, one **gap line**: `4h 50m · free`, with a quiet
  `+ Add task` at the right of that row

Copy Tiimo's gap row exactly: grey text, a dotted rail down the left, the `+` at the right.
Copy Saturn's block for the block: the current one lit, the rest quiet.

Give me: the pt-per-hour of the axis, what happens to a 15-minute block, what an all-day
event does, and where the day's header and back control sit.

### Artboard 5 — quick add, mid-typing, with a parsed date

**G.** The `+` opens this. A sheet above the keyboard, never full screen.

- One field. Typed text: **`Bio quiz fri 4pm`**, with `fri 4pm` lit in a tinted pill
  inside the field.
- Under the field, the chip row: **`Friday 4:00 PM`** (lit, coral-soft, with a small
  calendar glyph), **`Study`**, **`Life`**, and **`More`** which opens the full editor.
- Bottom left: the day it will land on, in words. Bottom right: a 44 pt coral circle with
  an up arrow. Disabled until there is a title.
- Draw the empty state of the same sheet: placeholder **`Bio quiz, ch. 3–4`**, chip row
  `Date` · `Study` · `Life` · `More`. There is no separate Time chip — the When sheet
  behind Date carries the time, so one chip answers both and the row stays short.

There is **no camera chip** in either state. When the scanner is deployed and the student
is Plus, one more chip appears in the row reading **`Photo`** — draw it once, greyed into
the corner of the artboard, labelled "not until the reader is live."

Give me: what happens to the pill when the student edits the phrase, what the chip reads
when nothing parses, and where the field goes when the title runs to two lines.

### Artboard 6 — the When sheet

**H.** The Date chip opens this. Things 3's "When", exactly:

- Header: **When?** with **Cancel** on the right
- **Today** row, with a glyph
- **This evening** row, with a glyph (this sets 6:00 PM, nothing else)
- A compact month grid, Sun–Sat, past days dimmed, month rollover shown in the cell the
  way Things does ("Oct 1")
- **At a time** at the bottom, with the time control beside it

There is no "Someday" — every task in this app has a day. There is no reminder line; local
reminders for typed tasks are not built, and this sheet may not imply they are.

### Artboard 7 — the Still counts group

**I.** The list with three overdue things above it.

- Header: **Still counts**, `Theme.coinDark`, with a hairline rule running out to the
  right margin — amber, never red, never a count in a badge. There is deliberately **no
  "Move to today"** action: half the rows in this group are Canvas due dates, and a
  Canvas date is not ours to move. Tapping a typed row opens the editor, which is where
  a date changes. If you can see a way to offer it that does not lie about the Canvas
  rows, draw it and say so.
- Three rows under it, each with `Physics 13 · was due Tue` as the caption.
- Then the normal list, starting at Today.

Rows in this group are **not** faded. Show the same group with one row swiped, and say what
the swipe offers.

## Rules for this screen

- Check-off pays coins the way Home does; the coin chip on a row shows what it pays.
- Events cannot be checked. Canvas rows cannot be edited — a submitted one carries a small
  lock and cannot be un-ticked. Typed rows open the editor on tap.
- Reuse by name and do not restyle: `CoinBadge`, `CoinDisc`, `IconTile`, `PlusTag`,
  `CalendarTaskRow`, `EventRow`, `FoldedDaysStrip`, `DayLoadStack`, `MonthLoadBars`,
  `SproutImage`.
- No streaks, no countdowns, no "you missed", no meters, no red, no exclamation marks, no
  engineering words. Overdue is amber and reads "still counts".
- Every string under 40 characters on one line. Every control 44 pt. Every image and button
  labelled.
- Nothing on this tab promises a feature that is not live.

## What comes back

The `.dc.html` prototype and a `README.md` in the shape of `design/handoff-kin/README.md`:
overview · fidelity · layout per artboard with pt values · tokens by `Theme` name · reused
components by name · state · every string of copy · interactions and motion with durations
and curves · a Reduce Motion note · deviations and why. Plus a **References** section
listing every Mobbin screen you leaned on as a link to its `mobbin_url`, one line on what
you took. If a link above returns nothing useful, say so in the README rather than
inventing a source.

**Already built in code, so draw it as it is, not as you would have it:** quick add and its
parser, the When sheet, the Still counts group, the empty-today line, and the one add
button. Artboards 1, 2 and 4 — the ticker with its drag handle, the month grid it opens
into, and the day timeline with its class blocks — are the parts nobody should freehand.
Those are what this handoff is for.

---

## Screens actually opened while writing this brief (2026-09-10)

Every link above was searched for on Mobbin and looked at. Four came back as the exact
screen named; the rest came back as a different screen of the same pattern in the same
app, and those are listed here so nobody looks twice.

| Pattern | Opened | What it gave |
| --- | --- | --- |
| A · Things 3 Upcoming | [1f3adaff](https://mobbin.com/screens/1f3adaff-5def-4789-a938-456435ecd4df) (exact), [70d652ee](https://mobbin.com/screens/70d652ee-3a68-47b6-a66e-2c8e9194255c), [07423d34](https://mobbin.com/screens/07423d34-0f48-449c-9046-4755b4cd1d85) | Big day number, "Tomorrow" beside it, events as tinted lines above checkboxed tasks, month headers further out |
| B · Outlook agenda | [3a21d1a0](https://mobbin.com/screens/3a21d1a0-0bec-472b-9c07-8a33dddf45cf) (exact), [5df44b2c](https://mobbin.com/screens/5df44b2c-c249-49a6-989e-25f34a8267c9), [3c78041a](https://mobbin.com/screens/3c78041a-6e2d-4908-b5b9-2c7abaac0d6e) | Month as the title, ticker, the grey handle pill, "Today / Tomorrow" section bands, time + duration in the left column, the "in 4 min" chip |
| C · Binance calendar | [8339ece6](https://mobbin.com/screens/8339ece6-cfa5-4995-a7ab-e52de69fb419) (exact) | Colour marks and "+2" under each ticker day, Today pill top right, "No more events today" as one grey line |
| D · Google Calendar schedule | [2e666eec](https://mobbin.com/screens/2e666eec-22dd-491f-8225-63752091ad1b), [3cc69b4b](https://mobbin.com/screens/3cc69b4b-9a3b-4633-8239-4812e0ffc588) | "Nothing planned. Tap to create." inline on the date row; empty weeks folded to "MAY 30 – JUNE 5" |
| E · Structured timeline | [f87538a4](https://mobbin.com/screens/f87538a4-bf7c-46ac-80ed-061e9ee855a5) | Time axis, dotted rail through gaps, blocks as capsules with a checkbox on the right, the current time bold on the axis |
| E · Tiimo gap line | [2e5e28b9](https://mobbin.com/screens/2e5e28b9-c537-46b3-89fe-5d46c59fe6a3) (exact) | "11h 50m → No plans" grey on the rail with a `+` at the right of the gap row |
| F · Saturn Calendar | [b710b067](https://mobbin.com/screens/b710b067-25bf-4ff1-8aff-bbd93549816a), [e81e74a6](https://mobbin.com/screens/e81e74a6-7629-431d-9f2c-d49b674f772e) | Class blocks as flat rows with an object, title and time; ticker with today on a white card; "Wednesday, Jul 9" day header |
| G · Todoist quick add | [825df521](https://mobbin.com/screens/825df521-3a37-4a98-bf38-e6b121815108), [9f832ef6](https://mobbin.com/screens/9f832ef6-02ce-4c3c-bb4d-c95fc779a67c), [3e31606d](https://mobbin.com/screens/3e31606d-730d-4c6e-827e-81af7a276c7c) | "by fri 4 pm" lit inside the field, "Friday 4:00 PM" as the first chip, the round submit, the full editor behind it |
| H · Things 3 When | [79b21b78](https://mobbin.com/screens/79b21b78-f56c-4d87-8b89-466ee2ef180c) | "When?" + Cancel, Today, This Evening, the compact grid with "Apr 1" inside the rollover cell |
| I · Todoist overdue | [e3664e12](https://mobbin.com/screens/e3664e12-9fd4-4240-aca2-522f44003b9e), [7ff218cf](https://mobbin.com/screens/7ff218cf-1ddd-47ee-9123-72535e5f9283) | "Overdue" as its own group above today, with a plain-text action on the right |

Not found on Mobbin, so nothing was copied from them: the specific Saturn "Got your class
schedule?" card, and Structured's own day-header chrome. Draw those from the pattern, and
say in the README that you did.

## Already built, 2026-09-10 — draw it as it is

In `ios/Sources/`: `QuickAddSheet.swift`, `WhenSheet.swift`, `Core/DatePhrase.swift`,
`Core/Upcoming.swift`, and the changes in `CalendarView.swift`. Screenshots in
`design/screenshots/calendar-redesign-2026-09-10/`.

- Only days with something on them get a header; a run of empty days is one folded line;
  in the week that holds today, days already gone are dropped.
- "Nothing due. Tap to add." inline on an empty today.
- The **Still counts** group at the top.
- One coral `+`, no per-day `+`, no camera anywhere.
- Quick add with the date typed in words, and the When sheet behind its Date chip.

**What this handoff is for**, because nobody should freehand layout: **artboard 1** (the
ticker and the month-name title), **artboard 2** (the drag handle and the grid it opens
into), and **artboard 4** (the day timeline with class blocks, the now-line and the gap
row). Artboard 3's not-paired card and artboard 7's swipe are also open questions.
