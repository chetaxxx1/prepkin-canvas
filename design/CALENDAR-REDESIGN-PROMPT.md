Redesign the Calendar tab of the Prepkin iPhone app, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas). George's call on 2026-09-10: full redesign, and copy as much as possible from calendar and planner apps that already work. The house rule from the games and social builds applies: mechanics-identical to something that ships, never inspired-by. Every pattern below names the app and the Mobbin screen it comes from. Look at those screens yourself before you draw or build anything; the URLs are in this file so you do not have to search again.

Read first, in this order:
1. ios/Sources/CalendarView.swift, ios/Sources/ScanSheet.swift, ios/Sources/TaskEditorSheet.swift, ios/Sources/Core/DatedTask.swift (DatedTask and CanvasEvent), and `GameState.tasks` in Core/GameState.swift.
2. design/CALENDAR-PLAN.md — the data model, what the tab is for ("Home is what do I do right now, Calendar is what is coming"), and the rule that daily habits never appear here.
3. design/CLAUDE-DESIGN-PROMPT-CALENDAR.md and design/CLAUDE-DESIGN-PROMPT-CALENDAR-SHEETS.md — the current briefs. You will replace both with one brief built from the references below.
4. PRODUCT.md house rules: no red, amber means "still counts", no meters, no countdowns, no exclamation marks, no "sync". The scanner backend is NOT deployed (CALENDAR-PLAN.md "Deploying the scanner"); nothing on the tab may promise it until it is.
5. design/screenshots/calendar-2026-09-09/24-calendar-week.png, 25-calendar-month.png, 26-calendar-add-task.png — the tab today. The 2026-09-09 review graded it B−: three bands of chrome before content, seven day headers for three items, three add buttons, task rows and exam rows the same weight, a scanner promise on the empty state, two dead "Type them instead" buttons.
6. .claude/skills/ios-walkthrough/SKILL.md for the simulator rules. Check `xcrun simctl list devices booted` first.

What to copy, and from where. Open each Mobbin link and look at the image.

A. The spine: Things 3 "Upcoming". A single vertical list of only the days that have something. Big day number with the weekday beside it in the left margin, "Tomorrow" spelled out. Calendar events sit in a small tinted block at the top of each day (time + title, no checkbox), tasks with checkboxes under them. Empty days do not exist on screen. Further out, a month header with just the dated items in it. This one pattern fixes "seven headers for three items" and "an exam looks like an essay".
   https://mobbin.com/screens/1f3adaff-5def-4789-a938-456435ecd4df
   https://mobbin.com/screens/590f4dd6-1a6d-45a3-91c3-3508a762b041
   https://mobbin.com/screens/3055273e-f993-4d94-a3cb-13c1bb281726

B. The header and ticker: Microsoft Outlook agenda. Month name as the title, a seven-day ticker under it with today filled, and a small drag handle under the ticker that pulls it down into a full month grid and pushes it back up. That replaces the Week · Month pill and one band of chrome. The agenda below uses "Today" and "Tomorrow" words, the time in the left column, a duration under it, and an "in 4 min" chip on the next event.
   https://mobbin.com/screens/3a21d1a0-0bec-472b-9c07-8a33dddf45cf (agenda with ticker and handle)
   https://mobbin.com/screens/a6fd424b-68a6-40e5-ad65-e0257449ff2a (the month grid it opens into)

C. Dots under the ticker: Binance's calendar, tiny course-colour marks under each day number with "+3" when there are more, and a Today button top right. Our dots exist; make them read as load the way these do.
   https://mobbin.com/screens/8339ece6-cfa5-4995-a7ab-e52de69fb419

D. Empty days and empty weeks: Google Calendar schedule view. Today with nothing on it shows one inline line, "Nothing planned. Tap to create." Empty weeks fold into one line with the date range. Our version: "Nothing due. Tap to add." on today only, and the folded "Thu – Sun · free" strip that already exists for the rest. No card, no illustration, no scanner line.
   https://mobbin.com/screens/1f51ee68-947e-4ce0-b371-4d307313f77b
   https://mobbin.com/screens/ce0f4482-6d5d-44b6-a59c-6547a5dc0448

E. The day view: Structured's timeline. Tap a day header or the ticker and the day opens on a vertical time axis with a now-line, class meetings and office hours as blocks (they come from CanvasEvent), due times as pins, and the gap between items labelled with the free time and one quiet "Add task" inside the gap. Tiimo does the same gap line ("11h 50m → No plans"). This is where a student sees "I have Chem lab 1 to 3, the problem set is due at 5".
   https://mobbin.com/screens/574482d9-3640-4553-805e-944f11f27428
   https://mobbin.com/screens/26fae4e6-2163-4d93-8c47-5bd9839cb369
   https://mobbin.com/screens/2e5e28b9-c537-46b3-89fe-5d46c59fe6a3 (Tiimo gap line)

F. Class blocks: Saturn Calendar, the calendar built for exactly our age. "Now" shows today's class blocks with the current one lit and a time line through it; tomorrow's block under it; friends can see your schedule only if you allow it. Copy the block shape and the now-line. Our classes come from Canvas events, so there is no manual setup; when a student is not paired, show Saturn's "Got your class schedule?" card as the one setup prompt, pointing at the laptop pairing, not at a form.
   https://mobbin.com/screens/f4d20fce-ae76-45c2-8d1f-6132b25fa29c
   https://mobbin.com/screens/d59d5b9e-5ce1-444f-9e99-88210bee983e
   https://mobbin.com/screens/01c14d42-74ef-4046-af3c-c38f8e9fa88c

G. Adding: Todoist quick add. One coral + opens one text field above the keyboard. The date is typed in words and lit up as it is recognised: "Bio quiz fri 4pm" highlights "fri 4pm" and the chip under the field reads "Friday 4:00 PM". Chips: Date, Time, Study/Life. That is the whole add flow for most tasks. The full editor (notes, repeat) is one more tap, never the default.
   https://mobbin.com/screens/b2e34aae-de00-4c7b-8194-cf07c9755c01 (parsed date lit in the field)
   https://mobbin.com/screens/d73506db-d527-4084-a876-3cf7f1e037f7 (the empty quick add)
   https://mobbin.com/screens/5a23ab49-44fa-4db6-8f59-0f365a4f8569 (the full editor behind it)

H. The date picker: Things 3 "When". One sheet: Today, This Evening, a compact month grid, and a reminder time. Tap a day, done. Copy it exactly for the Date chip.
   https://mobbin.com/screens/44ec9290-bd1c-4b82-acec-b0b3c32c847b
   https://mobbin.com/screens/6675a19f-4911-443c-b127-62965cd36d9a

I. Overdue: Todoist and ClickUp both put overdue in its own group at the top. Ours is one group labelled "Still counts" in amber, never red, rows fade like done rows do not. Copy the placement, not the colour.
   https://mobbin.com/screens/ecb1790e-e9b8-494c-8022-224b41476d34

What is deliberately NOT copied: Google Calendar's month artwork banners (decoration), Structured's energy meter (a meter), Saturn's chat-to-create and friend directory, Todoist priorities and flags, anything with a streak, any red.

The scanner: keep the reader and its sheet as built, but move its entry to a row inside the quick-add field's chip bar ("Photo") that appears only when the scan backend is deployed and the student is Plus. Until then the tab has no camera button at all and no line about syllabuses. Fix the two dead "Type them instead" buttons so they open quick add.

Do it in this order:
1. Rewrite design/CLAUDE-DESIGN-PROMPT-CALENDAR.md as one brief with the references above, seven artboards: the Upcoming list with the ticker (three days of content), the ticker pulled into the month grid, the empty today, the day timeline with two class blocks and a due pin, quick add with a parsed date, the When sheet, and the Still counts group. Every string. Same paper, type and coral as Home; nothing invented. Preamble rules apply (design/CLAUDE-DESIGN-PREAMBLE.md). Delete the sheets brief; it is inside this one now.
2. Build what needs no handoff, now, in code: skip empty days in the list; one add button; Todoist-style quick add with a date parser for "today, tomorrow, mon…sun, fri 4pm, 9/14, sep 14, next week" and a unit test per phrase; the Things When sheet on the Date chip; the Still counts group; "Nothing due. Tap to add." on an empty today; remove the camera button and the scanner line until the deploy; wire the dead buttons.
3. When the handoff comes back, port the ticker with the drag handle, the day timeline and the class blocks. Do not freehand those; they are layout.
4. Class blocks need recurring Canvas events. Check what CanvasSync already delivers (CALENDAR-PLAN.md "Canvas keeps the calendar current"); if events are not flowing yet, draw the timeline from due pins alone and leave a TODO with the block spec.

Prove it:
- Unit tests for the date parser, the day-grouping (no empty days, Today and Tomorrow words, month headers past two weeks), the Still counts rule, the folded strip.
- On one simulator, screenshot: the list with three days of Canvas and typed tasks; empty today; the month grid open; quick add mid-typing with "fri 4pm" lit; the When sheet; day timeline. Before and after contact sheets from test/ios-sweep.sh in design/screenshots/calendar-redesign-<date>/, light, dark, accessibility-XL.
- Every control 44pt, every image and button labelled, every string under 40 characters on a single line, no banned words.

What an A looks like: a student opens Calendar and the first thing on screen is content, not chrome. Only days with something on them exist. An exam looks different from an essay. Adding a task is typing one line. Tomorrow's classes are blocks on a timeline with the problem set pinned at 5 PM. Nothing on the tab promises a feature that is not live, and nothing is red.

Do not touch Home, Focus, Learn, Friends, Kin or the Shop in this session. `git diff` before editing GameState.swift and AppState.swift; other sessions are active in this tree.

Finish with: the rewritten brief, the screenshots, the contact sheets, the test count and result, and a list of what waits on the handoff.
