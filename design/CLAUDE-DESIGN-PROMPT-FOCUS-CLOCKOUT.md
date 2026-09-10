# Prompt for Claude Design — Focus: clock-out sheet, shift report, Ready-screen row

**Rewritten 2026-09-10.** The version before this described a delivery van, lengths of
25 / 45 / 60 with a − + stepper, and pay for the minutes actually worked. All three are
gone. The kin is a fish, the scene is the Reef Route swim, the lengths are 15 / 25 / 45
with three chips and no stepper, and **a shift pays all or nothing**. Everything below
is the app as it runs today.

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the line.
Attach `design/screenshots/sweep-2026-09-09/light-focus.png` (the Ready screen today),
`design/screenshots/focus-a-plus-2026-09-10/before-shift.png` (a running shift) and the
scene mock `design/reef-route/reef-route.html`.

---

I'm finishing the **Focus** tab of Prepkin Canvas. The Ready screen and the running
shift are built (`ios/Sources/FocusView.swift`, `ios/Sources/SwimSceneView.swift`). Two
screens the tab needs have never been drawn, and one row on the Ready screen is a stand-in.
Design those three.

## What Focus is

A **shift**. The kin clocks in and swims the Reef Route — a reef that rolls past under
him — for 15, 25 or 45 minutes. The point of the screen is that the student **puts the
phone down**. Since 2026-09-10 the phone can say when the shift is over on its own: a
local notification fires at the end, and a Live Activity puts the kin and the countdown
on the lock screen while it runs. So the app screen no longer has to be watched, and
should stop asking to be.

## How Focus works today, in code (`ios/Sources/FocusView.swift`)

**Ready screen.** Title, the kin on a still low-contrast band of the student's own tank,
a big minute count, three chips **15 / 25 / 45** with 25 already chosen (no stepper — it
came out 2026-09-06, `design/hicks-law-plan.md`), a `+N coins for finishing` pill, a
**Working on** chip, a small **This week** line, and one coral **Start focus** button. A
Study Together row appears above the button only when a friend is working right now.

**A shift.** The kin swims sideways through the reef inside a 250pt circle
(`SwimSceneView`, ported from `design/reef-route/reef-route.html`). A **length** ticks
every 90 seconds and the kin bounces as the marker passes. There is a `best shift` chip
(lengths, only ever goes up), a big countdown, a progress bar, the length count, and
Pause / Resume plus **Clock out early**.

**Pay is all or nothing.** Finishing a 25 pays 25 coins. Clocking out at minute 24 pays
**zero** — George's rule from Focus Friend, 2026-09-06, commit `3bd80e1`. Lengths swum
and best shift still count either way, because those two numbers only ever go up.

**What the tab does not have and will not get:** app blocking (Screen Time needs a
Family Controls entitlement review, and the fish is the hook, not a wall), a streak, a
meter, a countdown to anything but the end of this shift, sound (there is no audio
anywhere in the app), or red.

## Artboard 1 — the clock-out sheet

A bottom sheet over the shift screen. Same visual family as the Kin buy-confirm sheet
(`design/handoff-kin/README.md`, `1k`): cream paper, 26pt corner, no drag indicator,
about 256pt tall.

It has **one** job: say plainly what leaving costs, and make staying the easy tap. The
copy shipped today says the waiting coins "stay in the reef", which a tired reader hears
as *kept for you*. They are not kept. Say it straight:

- Title: **Clock out early?**
- Line: **"Clock out now and this shift pays nothing. Finish it and it pays 25."**
  (the real length's number). Two sentences, both true, neither a threat.
- Primary, coral, full width: **Keep working**.
- Secondary, quiet text button: **Clock out**.

Rules: never scolded, never coloured as danger, no red, no "Are you sure?", no "you'll
lose". Note that **Keep working is now the coral one** — it was the quiet one, which put
the app's only primary button on the action that pays nothing.

## Artboard 2 — the shift report

Full screen, no tab bar, for one beat after the timer hits zero **or** after a clock-out.
Both cases show the report; the clock-out's pay line reads zero. Contents, in order:

1. The kin, large, coat and stars as owned. `celebrate` at 25 minutes or more, `bounce`
   below, and nothing extra after a clock-out — the emote is the whole reaction.
2. **What the shift paid.** One big coin number with the arithmetic visible: **"25
   minutes. 25 coins."** After a clock-out: **"You worked 12 minutes. This shift pays
   nothing."** — stated once, not repeated, not apologised for. The arithmetic being
   visible is the whole honesty of the feature.
3. The task that rode along, if any (the **Working on** chip). A **Mark it done** row
   that pays that task's own coins (Study 20, Life 10). If it is a Canvas assignment it
   is **not** markable by hand — Canvas has to see the submission — so show it with no
   checkbox, as a plain line naming the course.
4. Lengths this shift, small. Best shift **only if it changed**, said once.
5. One coral **Done** and a quiet **Another shift**.

Never a streak, never "come back tomorrow", never a calendar, never a grade.

## Artboard 3 — the Ready screen's two new rows

Both are built as stand-ins and need a designer's eye, not a decision:

- **Working on** — a chip that defaults to the next undone task and can be tapped to pick
  another from today's list, or "Nothing in particular". It rides into the shift screen
  and into the report. Nothing about it ever travels to a friend
  (`ios/Sources/StudySync.swift` rule 3: the wire carries a kin and an end time, never a
  title). Long Canvas titles are the problem to solve: give me the rule for
  "Quiz - International Graduate Student Com…" — one line truncated, two lines, or a
  course eyebrow over a shorter title.
- **This week** — one small line, "3 shifts · 1h 15m", read off the coin ledger. Only
  ever up. No graph, no calendar, no streak. (A graph is a Plus perk if it is ever
  wanted: `design/PLUS-PROMPT.md`.)

Draw the Ready screen with both, and tell me if the screen is now too busy above the
button.

## What happened to Strict

The old brief asked for a **Strict** switch (leaving the app clocks the shift out) beside
a **Sound** switch. Sound is cut — the app has no audio at all. Strict is **not built**,
and the reason is worth writing down: when it was drawn, a clock-out still paid the
minutes worked, so Strict cost a student a few coins. Under all-or-nothing it costs the
whole shift. A student who checks a text at minute 24 of a 25 walks away with nothing.
That is a punishment, and the tab's rule is that nothing here punishes. Decided: not
built. If you think there is an honest version, draw it — but it has to survive the
minute-24 text message.

## Also solve

- Reduce Motion: the report with no coin motion.
- The report at accessibility-extra-large text, where "25 minutes. 25 coins." has to stay
  on one line or break well.

## What I want back

Three artboards (sheet, report in both its pay states, Ready screen with the two rows)
plus any alternate you make. The README lists every string. Tell me what you changed and why.
