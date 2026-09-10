# Prompt for Claude Design — the Prepkin Plus sheet

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the line.
Attach `design/screenshots/calendar-2026-09-09/30-plus-paywall.png`. Mobbin connector on.

**Read `design/PLUS-SPEC.md` first.** It is the source of truth for the perk list, the prices
and the rules. Nothing on this sheet may promise a perk that is not in its section 2 table.

---

The first paid screen in the app is built and running (`ios/Sources/PlusSheet.swift`,
`30-plus-paywall.png`). It is a competent generic paywall: a plum "PREPKIN PLUS" tag, a
headline, a two-row perks card where one of the rows says "more later", two price cards, a
coral button. It could be any app's. Make it Prepkin's, and make it honest.

Since that sheet was drawn, Plus went from one perk to eight. That is the change this brief is
about.

## Facts

- **$9.99 a month or $69.99 a year.** Yearly is the default pick and saves 42%, which is the
  only reason it is the default — say that, and do not put a "most popular" badge on it.
  Prices come from the App Store at runtime (`PlusStore.products`), so draw them as text the
  app fills in; the amounts above are the fallbacks.
- **The sheet opens for a reason, and the top third changes with it.** Seven reasons, one per
  entry point: `scan`, `calendarExport`, `shop`, `focus`, `look`, `grades`, `vibe`, plus
  `general` for the once-only appearance when the gift week ends. The bottom two thirds never
  move. Design the swap, not eight sheets.
- **What Plus gives, all eight, from `PLUS-SPEC.md` section 2.** A look and three scenes coins
  cannot buy. Seven shop picks instead of five, three holds instead of one, 30% off instead of
  20%, six rerolls instead of three. Sixty and ninety minute shifts, any length you type, and a
  week of your own hours. The photo reader. Every dated task sent out to Apple Calendar, or an
  `.ics` file. Your GPA for the term and a target per course. All six cards to send a friend.
  Unlimited saved looks.
- **What stays free, and this is the first thing on the sheet, not the last.** Canvas, the
  Receipt, the buddy panel, the timer, coins, every kin, coat, costume, colour and scene coins
  buy, all 57 lessons, Friends, leagues, Games, and every accessibility setting. Finch puts
  this on line one of its benefits page and it is the reason its own reviewers forgive it for
  being "largely cosmetic". Copy that placement.
- **Nothing is taken away when it lapses.** `PLUS-SPEC.md` section 7, in full. At minimum, one
  line of it is on this sheet: you keep your fish, your coins, every look you wore and every
  combination you saved.
- **Actions:** **Get Plus** (coral, exactly one coral thing on the sheet), **Restore a
  purchase** (text), and **"Can't swing it? Ask."** (text, opens mail — George sends a promo
  code for a month). Plus the legal line "Cancel any time in Settings. Renews unless you turn
  it off." A failed purchase says "That didn't go through. Nothing was charged." under the
  button, never in a dialog.
- **Apple guideline 3.1.2 needs four things on this screen:** the subscription title, its
  length, the price, the price per period, and tappable links to the privacy policy and the
  Terms of Use. Missing one is the most common first-submission rejection. Draw all of them.
- When the purchase lands the sheet closes itself and the thing the student was doing
  continues — the camera opens, the 90-minute chip is now selected, the look goes on.

## What is wrong with the sheet today

1. It is a template. Plum was invented for it; nothing else in the app is plum.
2. The kin is absent from the one screen that asks for money.
3. The perks card has two rows and one of them is "more later". There are eight now.
4. The price cards are the visual centre. The reason the student came is a line of text above
   them.
5. Nothing on it says what stays free, which is the one sentence that makes the ask honest.

## Use Mobbin (required)

Search with `search_screens`, platform `ios`, look at the images, and cite the `mobbin_url` of
anything you borrow. These five have already been looked at and are written up in
`PLUS-SPEC.md` "References" — start there, then go further:

- `Finch Plus benefits sheet with the bird and a list of member perks`
- `Duolingo Super paywall with the owl mascot and yearly monthly plan choice`
- `Quizlet Plus choose your plan sheet with annual best value option`
- `Headspace subscription screen with a warm illustration and one price`
- `subscription sheet that lists what stays free above what you pay for`

Take the structure and the honesty, not the look. Everything comes from `Theme.swift`. If you
want an accent beyond coral and mint, argue for it in the README; do not invent one silently.

## Design

- **Artboard 1 — reason `scan`.** The kin (dashed box, coat and stars as owned) with a
  syllabus or a calendar page. The free line. The perks. The two prices. The button. Show the
  sheet at the height it actually opens.
- **Artboard 2 — reason `shop`.** Same bottom, different top. This is the proof the swap
  works: if artboards 1 and 2 differ anywhere below the fold, the design is wrong.
- **Artboard 3 — reason `general`**, the once-only appearance the day the gift week ends. It
  may not say "your trial is ending", may not show a countdown, and may not name how many days
  anything was. It is the same sheet, arriving quietly.
- **Artboard 4 — already Plus.** A student who has paid and lands here by mistake must never
  see a price. Tell me what this screen says instead. It is the shortest artboard and the one
  most apps get wrong.
- **Artboard 5 — purchasing** (button reads "One moment" with a spinner) **and failed** (the
  line under the button).

### The perks, and this is the hard part

Eight perks will not fit as eight rows of an icon in a circle next to two lines of text. That
is what the sheet does today with two rows and it already looks like a settings screen.

**Draw them as things.** The scene as a scene. The shop row as a shop row with seven slots in
it. The 90-minute chip as the chip. The calendar as a calendar with the dates in it. Show me
what the student gets, at the size they will see it. Group them if grouping helps — the fish
things, the work things — but do not turn them into a comparison table with ticks and crosses,
because a cross is a padlock wearing a different hat.

## Rules

- No countdown, no "limited time", no crossed-out price, no "most popular" badge that is not
  true, no percentage saved on anything except the yearly plan where it is arithmetic.
- **Not once the word "unlock".** Not in a heading, not in a button, not in body copy.
- No padlocks, no `?` tiles, no greyed-out anything. A Plus thing is drawn in full colour with
  the word "Plus" beside it, exactly like a coin item is drawn with its price.
- No exclamation marks. `ios/Tests/CopySweepTests.swift` fails the build on one, and it also
  bans "sync", "bridge", "endpoint", "selector", "api", "token", "schema" and "payload" — so
  the calendar perk says "sent to your calendar", never the other word.
- The kin is never sad, locked, pleading, or holding a sign. It is not a mascot for a paywall.
  It is the same kin as on Home, doing what it does.
- Plain copy. A 19-year-old reads this at midnight with a lab report due. One idea per
  sentence.

Return the `.dc.html` prototype and README as the preamble describes, with a "References"
section listing the Mobbin screens you leaned on.
