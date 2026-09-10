# Prepkin Plus — the spec

Written 2026-09-10. This file is the single source of truth for what Plus is, what it costs,
and what it may never touch. **The price table in section 5 is the only price table in this
repo.** `LAUNCH-PLAN.md`, `MARKETING-PLAN.md`, `CALENDAR-PLAN.md` and
`CLAUDE-DESIGN-PROMPT-PLUS.md` all point here and name no numbers of their own.

Plus is the app's only money. Today it gates one thing — the syllabus reader — and the sheet
is a template with a perk row that says "more later". This spec replaces that.

---

## 1. The rules this is checked against

Copied verbatim from `PRODUCT.md` and `LAUNCH-PLAN.md` so the table in section 2 has something
to fail against.

| # | Rule | Source |
|---|---|---|
| R1 | Everything shipping free today stays free, in any release, for any reason. | LAUNCH-PLAN "What stays free, forever"; MARKETING-PLAN code-review gate |
| R2 | Coins pay for finishing, never for grades. Coins are never sold, and no coin item moves behind money. | PRODUCT.md; LAUNCH-PLAN brand rules |
| R3 | Accessibility is never behind money — contrast, reduced motion, dark. | PRODUCT.md; LAUNCH-PLAN brand rules |
| R4 | Nothing is ever taken away. Every number can only go up. | PRODUCT.md |
| R5 | No padlocks, meters, countdowns, `?` tiles, or the word "unlock". | LAUNCH-PLAN brand rules |
| R6 | No streaks, and nothing that resets. | LAUNCH-PLAN brand rules |
| R7 | Nothing on the Canvas page sells anything. Every Plus benefit lives inside the iOS app, where the entitlement is. | PRODUCT.md; MARKETING-PLAN (Apple 3.1.3(b)) |
| R8 | No exclamation marks in shipped copy. Enforced by `ios/Tests/CopySweepTests.swift`, which also bans "sync", "bridge", "endpoint", "selector", "api", "token", "schema", "payload". | LAUNCH-PLAN audit two |

**R4 cannot survive a subscription in its current wording.** LAUNCH-PLAN says "no trial that
ends" because it was written for a one-time $9.99 purchase. Plus is a subscription that lapses,
and section 7 gives it a gift week that stops. That is signature 1 in section 10, and the whole
spec below assumes George signs the replacement rule in section 8. If he does not sign it, Plus
goes back to being a one-time purchase and most of this file is wrong.

---

## 2. Every candidate perk

Eight ship. Seven of the eight are a direct copy of something Finch or BetterCampus already
charges for. Nothing here was invented to pad the list.

| Perk | What the student gets | Copies | Rule check | Days | Hooks in code |
|---|---|---|---|---|---|
| **1. Plus looks and Plus scenes** | A look coins cannot buy, wearable on any kin at any star, and three scenes — Observatory, Lantern Street, Snow Cabin. | Nobody, honestly. Finch has **no** member-only items. This is the one place we differ, and LAUNCH-PLAN:65 already sanctioned it as the Lamp coat. | **Allowed on R1/R2** (new art, no coin item moved). **Needs signature 4 on R4**: it stays yours after you cancel, so one paid month buys the cosmetics forever. Dark is already coin-reachable — the `deep` scene is `isDark: true` at 280 coins today — so R3 is visibly satisfied in the product, not just claimed here. | 5–7, art-bound | `Theme.swift:197` scene table; `SproutView.Look.skin` (looks are the `skinID` axis, same as `ninja`); `KinView` Looks rail; 6 coats × 3 evos of stills via `scratchpad/capture_sprout.py` |
| **2. Shop: 7 pick slots, 3 holds, 30% off, 6 rerolls** | Two more picks a day, three slots you can hold instead of one, every pick 30% off instead of 20%, six free rerolls instead of three. | Finch, exactly: "50% off deals and more item slots at every shop" ([mobbin](https://mobbin.com/screens/0525a643-772d-4665-b5fc-b0d7d10a3a3a)). | **Allowed**, and it is the closest any perk comes to R2. It sells no coins and moves nothing behind money — every item stays reachable at full coin price forever. It does make coin items cheaper for money, and that reading deserves **signature 3** on the record rather than a quiet pass. | 2 | `KinState.swift:112` `rerollsPerDay`; `pickSlots`; `lockedPick` becomes `lockedPicks: Set<String>`; the 20% multiplier in `ShopPick.price`; **`rerollCanChange` at KinState.swift:120 compares against the static `pickSlots` and must become entitlement-aware** |
| **3. Focus: 60, 90 and a custom length, plus a week of history** | Two more shift lengths, any length you type, and a bar per day for the last seven days. | Finch, "all timer durations". | **Allowed.** 15, 25 and 45 stay free and untouched. The graph is a bar chart of minutes done, not a target — no meter that falls, so R6 holds. | 2 | `FocusView.swift:102` the chip row; `GameState.recordFocus` at `:662` already writes every session to the ledger with `reason: .focus`, so the history needs no new storage |
| **4. Calendar: the reader, and a way out to a real calendar** | The photo reader you have today, plus every dated task sent to Apple Calendar, and an `.ics` file for anything else. | BetterCampus, "task planning with Google and Microsoft calendar sync" — the single most-cited reason students pay them. | **Allowed.** The reader is already Plus-only, so nothing changes there. Calendar write is new. **Google Calendar is not in scope** — it needs a Google account and an OAuth server, which is the first account Prepkin has ever asked anyone for. That is **signature 5**; the `.ics` import path gets a student into Google Calendar without one. | 3 | `CalendarView.swift:779`; new `EventKit` write, `NSCalendarsWriteOnlyAccessUsageDescription` in `project.yml`; `DatedTask` → `EKEvent` |
| **5. Grades: semester GPA and a goal per course** | Your GPA for the term projected from the grades already on your phone, and a target grade you set per course. | BetterCampus, "advanced grade tracking". | **Allowed.** The per-course what-if (`GradeCalcView`) stays free. A projection is a tool; it is not paying for a grade, so R2 is untouched. **Must be built in the app, not the extension** — the extension is where the GPA code lives today (`extension/content.js`) and it has no Apple ID, so R7 forbids it. | 3 | `GradeCalcView.swift`, reached from `HomeView.swift:769`; course grades already arrive on the phone via `CanvasSync` |
| **6. Friends: six vibe cards instead of three, and a Plus mark** | All six cards to send a friend, and a small mark under your name on your friend card. | Finch, "all good-vibe cards" plus Guardian sparkles. | **Allowed, on one condition.** Vibes are phase 2 of `FRIENDS-BUILD-PLAN.md` and do not exist yet, so a 3/6 split takes nothing away. **It must ship as 3-free/6-Plus on day one.** If six ship free first, the split can never happen without breaking R1, and the chance is gone permanently. The mark is a mark and not a rank, per LAUNCH-PLAN:88. **Signature 10**: a paid badge is visible to other people. | 1, inside phase 2 | `FRIENDS-BUILD-PLAN.md` section 5 row 9; six card indices 0–5; `FriendsView.swift:777` friend card |
| **7. Unlimited saved looks** | Save any number of coat-plus-costume-plus-scene combinations; free saves three. | Finch, "unlimited saved outfit combos". | **Allowed, on one condition.** No saved-look feature exists in the app today, so the free three is not a reduction. **The free version ships first or in the same build.** Every combination already saved stays applicable forever, including any above three — that promise is already written into MARKETING-PLAN and stays. | 3 | new; `GameState` + `KinView` Looks rail |
| **8. "Can't swing it? Ask."** | A plain row that opens mail. George replies with an App Store promo code for a month, then a hardship price. | Finch's Guardians raffle ([mobbin](https://mobbin.com/screens/5476a849-e09a-437e-b4c8-c39260617658)), done by hand at our scale. | **Allowed.** No rule touched. It sits on the sheet as a plain text row, never a `?` tile and never a padlock. | 0.5 | `PlusSheet.swift`, a `mailto:` row under Restore |

### Cut from the brief's list, with the reason

| Was proposed | Verdict | Why |
|---|---|---|
| **Star thresholds 25% lower** | **Cut.** | Stars are not a time threshold. They are a coin price — 100 coins to reach two stars, 250 to reach three (`Models.swift:90`). "25% lower" is a second coin discount, and stacking it on perk 2 is how a discount stops being a discount and starts being a coin sale. One discount, in the Shop, is enough. |
| **An extra daily coin reward** | **Rejected, and I recommend against signing it.** | This is selling coins with extra steps. R2 is the one rule the whole coin loop rests on: coins mean a real thing got finished. A coin that arrives because a card was charged means nothing, and every coin in the app is worth less the day it ships. If George wants it anyway it is signature 9 and it needs its own line in `PRODUCT.md`. |
| **Learn: free capped at one new lesson a day** | **Rejected. My recommendation is not to sign it, and the reasoning is below.** | See section 2a. |
| **Whiteboard and planner photos through the reader** | **Not a perk. Already built.** | `ScanSheet.swift:164` already says "A syllabus, a whiteboard, a planner page" and `:507` already offers camera or library. Listing it as new would be selling something the student already has. |
| **Ambient sound on Focus** | **Dropped. The assets do not exist.** | There is not one `.mp3`, `.m4a`, `.wav` or `.caf` anywhere under `ios/`. Selling a sound we have never recorded is the fastest route to a one-star review. Revisit when audio exists. |
| **Gating the home screen widget** | **Rejected.** | No widget target exists yet, so this is moot today. It stays rejected when one ships: the widget is the daily face of the app on a screen the student looks at forty times a day, and it is free advertising. Gating it costs more in retention and word of mouth than it could ever earn. |
| **Gating dark paper** | **Rejected.** R3. | Not negotiable, and it is already visible in the product: the `deep` scene is dark and costs 280 coins. |
| **Gating any Canvas look already earned with coins** | **Rejected.** R1 and R2. | All 12 palette looks and all 8 image looks stay coin-priced forever. |
| **Selling coins** | **Rejected.** R2. | |
| **Any streak, season, or bonus that resets** | **Rejected.** R6. | The streak that was shipped is being removed this week per LAUNCH-PLAN audit one. Plus does not get to bring one back. |

### 2a. Why the Learn cap is a bad trade, said plainly

The brief asked for a plain answer on whether a one-lesson-a-day cap is worth the review risk.
It is not. Four reasons, in the order they will hurt:

1. **It is the exact complaint that is already the loudest post on a competitor's feedback
   board.** "Some of these things were FREE", 30 upvotes, on a board where every gated-what-was-
   free change produced a wave of one-star reviews. We know the outcome in advance because
   someone already ran the experiment on the same audience.
2. **The grandfather rule makes it earn almost nothing.** Every install before the change keeps
   all 57 lessons forever. So the cap only ever applies to people who have not installed yet —
   and it poisons the review page those exact people will read before installing. It buys
   revenue from strangers by spending the goodwill of everyone who already showed up.
3. **It is the first diff that breaks the rule written to stop it.** MARKETING-PLAN already puts
   "nothing that has ever shipped free may move behind Plus, in any release, for any reason"
   into `PRODUCT.md` as a code-review gate. Shipping this means either deleting that sentence or
   ignoring it, and both are worse than not shipping it.
4. **Learn is the weakest thing to charge for.** The 57 lessons are life-skills content for
   undergrads, not the reason anyone installed. Charging for the thing people came for is a
   business. Charging for the thing they did not is a tax.

**What to do instead, which needs no signature:** the 57 lessons stay free forever, and **new
Learn units shipped after this change go to Plus.** That is the same rule MARKETING-PLAN already
set for event art and timer sounds — new from here forward, everything before it free. It costs
nothing today and takes nothing from anyone.

The consequence is that **Learn has no honest Plus perk at launch**, because zero new units
exist. So Learn gets no entry point until the first one does. See section 6.

---

## 3. What Plus is, and what it is not

These are the two paragraphs a student reads. They go on the sheet, in the App Store
description, and on the pricing page, in these words.

> **Prepkin Plus is more of the fish, a longer shift, and a way out to your real calendar.**
> A look and three scenes coins cannot buy. Two more picks in the Shop every day, three slots
> you can hold, and 30% off instead of 20%. Sixty and ninety minute shifts, or any length you
> type, and a week of your own hours. Photos of a syllabus, a whiteboard or a planner page,
> read into your calendar, and every dated task sent out to the calendar you already use. Your
> GPA for the term, and a target you set per course. All six cards to send a friend. As many
> saved looks as you want.

> **What Plus is not.** Nothing you have today goes away, ever. Coins are never for sale, and
> there is no shelf coins cannot reach. Finishing your work is free — the Receipt, the buddy
> panel, the timer, coins, every kin, every costume, all 57 lessons, Friends, leagues and Games
> stay free, and that list only gets longer. If you stop paying you keep your fish, your coins,
> every look you wore and every combination you saved. Dark, contrast and reduced motion are
> free and always will be. If you cannot afford it, ask, and we will send you a month.

---

## 4. Entry points

One per surface where it is natural. Never a second coral button — coral is the primary action
on every screen and Plus is never the primary action. Each entry point opens the sheet with its
own `reason`, and only the top third of the sheet changes.

| Surface | What it is | Reason | Where |
|---|---|---|---|
| **Shop** | A plain row under the coin racks, above the Collection link. "Seven picks, three holds, 30% off. In Plus." No coral. | `.shop` | `KinShopView.swift`, above `:212` |
| **Focus** | The 60 and 90 chips drawn in **full colour** next to 15, 25 and 45, with a small "Plus" beside them. Tapping one opens the sheet. Never greyed, never a padlock. | `.focus` | `FocusView.swift:102` |
| **Calendar** | The scan row, as it is today, with the existing `PlusTag`. Plus the new "Send to my calendar" row on the same tag. | `.scan` | `CalendarView.swift:1276`, `:652` |
| **Kin** | Plus looks and scenes sit in the Looks rail **in full colour with their price**, exactly like a coin item, previewed on an example fish and never on the student's own. | `.look` | `KinView` Looks rail |
| **Friends** | The vibe picker shows all six cards. Three plain, three with "Plus". Ships with Friends phase 2, not before. | `.vibe` | `FriendsView.swift` friend card sheet |
| **Grades** | One row at the bottom of the what-if screen: "Your GPA for the term. In Plus." Not on Home — Home stays clean. | `.grades` | `GradeCalcView.swift` |
| **Learn** | **None, held.** No honest perk exists until the first Plus-only unit ships. Add the row that day, not before. | — | — |
| **Home** | **None, ever.** Home is the daily face. | — | — |
| **The Chrome extension** | **None, ever.** R7. The page belongs to the school. | — | — |

---

## 5. The price

### The only price table in this repo

| Plan | Monthly | Yearly | Yearly per month | What free keeps |
|---|---|---|---|---|
| Finch Plus | $9.99 | $69.99 | $5.83 | All core self-care, said on line one of their benefits page. No member-only items at all. |
| BetterCampus Pro | $19.00 | $119.00 | $9.92 | Community themes and a basic to-do list. |
| Quizlet Plus | $14.98 | $49.98 | $4.17 | Flashcards and basic study modes. |
| **Prepkin Plus** | **$9.99** | **$69.99** | **$5.83** | Canvas, the Receipt, coins, every coin item, the timer, 57 lessons, Friends, leagues, Games, every accessibility setting. |

Sources: Finch and BetterCampus figures checked 2026-09-10 and recorded in `design/PLUS-PROMPT.md`.
The Quizlet row is read off a [Mobbin capture of their plan sheet](https://mobbin.com/screens/858c67d1-85ef-40e6-951e-42edbd774d0e);
**the storefront currency is not marked on that screen, so treat the Quizlet row as directional
and re-check it before it goes on a public page.** The Finch capture nearby shows S$ pricing,
so the two may not be the same storefront.

### Recommendation: move the yearly price from $79.99 to $69.99

**$9.99 a month stays.** It is right, and RevenueCat's price-band figures back it: year-one
revenue per payer is about $10.69 in the low band against $62.19 in the high band, and low-priced
apps convert *worse* (1.4% against 2.0%), not better. That pair is the argument that kills the
old $3.99 / $19.99 ladder, and it is already written up in `LAUNCH-PLAN.md`.

**$79.99 a year does not survive the comparison.** Finch is $69.99 with a longer perk list, six
years of brand, and a fanbase. We would be asking 14% more with eight perks and no brand at all.
MARKETING-PLAN already made this exact argument once, against a $29.99 yearly: *"asking 50% more
with zero brand equity is not defensible."* The same sentence applies here.

Be honest about what the RevenueCat number does and does not say: it distinguishes a **low band
from a high band**. $69.99 and $79.99 are both in the high band. **It does not choose between
them.** So the choice comes down to the sentence on the pricing page, and $69.99 gives the better
one:

> The other one is $119 a year. Mine is $70, and finishing your work is free.

Two more things $69.99 buys: yearly saves 42% instead of 33%, which is a stronger and true
default; and at the base case of about 23 payers, the whole difference is roughly $230 a year, so
this is not a revenue decision at all — it is a decision about whether the pricing page reads
honestly.

**The alternative George could take instead:** keep $79.99 and grow the list past Finch's.
I recommend against it. The list already has eight items, six of them not yet built, inside an
hours budget LAUNCH-PLAN already shows running over by a day and a half. Growing it further means
shipping less of it on time, and a promised perk that misses the date is a 3.1.2 rejection.

**Decision needed:** signature 7.

---

## 6. The gift week, drawn

No paywall on day one. The gift arrives after real work. The ask arrives after the gift.

```
  install ─────────────── 3rd finished Canvas task ─── + 7 days ────────────►
     │                              │                       │
     │                              │                       │
  nothing                      Plus turns on            Plus turns off
  is sold.                     for a week.              The sheet appears,
  No sheet.                    One quiet line:          once. Then never
  No mention.                  "Plus is on for a        again unless she
                               week. Nothing to         opens it herself.
                               cancel."
                                                        Everything she wore,
                               No card. No charge.      made or saved during
                               Nothing to cancel        the week stays.
                               because nothing
                               was started.
```

Rules for this timeline, each one a thing not to build:

- **No reminder at day five.** No push, no banner, no dot.
- **Never the words "your trial is ending"**, and never a countdown of days left. There is no
  number on screen that goes down.
- **The gift is not announced before it arrives.** No "finish two more and get a week free" —
  that turns finishing work into a coupon.
- **The sheet appears once.** After that, Plus is only ever reached from one of the entry points
  in section 4, which the student taps on purpose.
- **The App Store introductory offer comes off.** `PrepkinCanvas.storekit` currently attaches a
  7-day free intro offer to both products. Left in, a student gets the gift week and then a
  second free week that does auto-charge, which is fourteen free days, two different kinds of
  free, and a timeline nobody can draw. The gift is the trial. That is **signature 6**.

Shape borrowed from [Headspace's "How your trial works"](https://mobbin.com/screens/a9bf58c3-250a-4565-9808-c4722933ea54)
and [Quizlet's "How monthly subscriptions work"](https://mobbin.com/screens/858c67d1-85ef-40e6-951e-42edbd774d0e) —
both draw the dates as a plain vertical list with one line each. Take that. Take neither look.

---

## 7. What happens when it lapses

This is the replacement for LAUNCH-PLAN's "no trial that ends", and it is the load-bearing
promise of the whole plan. It goes on the sheet, in the App Store description, and in
`PRODUCT.md`.

- You keep your fish, every star, and every coin.
- You keep every kin, coat, costume, colour and scene you bought with coins.
- **You keep every Plus look and Plus scene you wore.** They stay on, and you can put them back
  on any time.
- You keep every saved combination, including the ones above the free three.
- You keep every task the reader ever put in your calendar, and everything it sent out.
- The Shop goes back to five picks, one hold, 20% off and three rerolls.
- Focus goes back to 15, 25 and 45.
- The reader stops reading new photos.
- That is the whole difference. **There are no member-only items in Prepkin.**

The cost of that promise, stated plainly: **one paid month buys the Plus looks and scenes
forever.** That is a real leak and it is the price of the rule. Closing it means taking a coat
off a student's fish because a card expired, which is the single most brand-damaging thing this
app could do. Keep the leak. That is signature 4.

---

## 8. Code plan

### 8.1 One enum, every gate

`ios/Sources/Core/PlusGate.swift` — every gate in the app named once, in one place, so a code
reviewer can see the whole surface of what money touches by reading forty lines. Nothing else in
the app reads `PlusEntitlement` directly.

```swift
enum PlusGate: String, CaseIterable {
    case scanPhoto, calendarExport, shopSlots, shopHolds, shopDiscount,
         shopRerolls, focusLengths, focusHistory, gpaProjection,
         courseGoal, vibeCardsAll, savedLooksUnlimited, plusLooks, plusScenes
}
```

Each case carries its free value and its Plus value, so the free path is a value in the same
table rather than an `if` somewhere else. `PlusGate.isOn(_:for:)` is the only entitlement read
in the app.

**Grandfather flag.** `GameState.installedAt: Date?`, set on first save, migrated in
`Store.swift` from v5 to v6 by reading the oldest ledger entry (the same trick the v4 migration
already uses for `adoptedAt`). `PlusGate.isGrandfathered(_:installedAt:)` returns true for any
gate added after a given install date. Nothing uses it on day one, because nothing in this spec
takes anything away. It exists so that the day George does sign one of the section-10 items, the
promise is enforceable in code and not only in a document.

**Tests.** One per gate, all asserting the same thing: **with the entitlement off, the free path
still works and returns the free value.** A gate that fails this test is a gate that took
something away. `ios/Tests/PlusGateTests.swift`.

### 8.2 The rest

- **StoreKit config.** Yearly `displayPrice` to `69.99`; both introductory offers removed
  (signature 6); both localization `description` fields filled in, since they are empty today and
  App Store Connect will reject a blank one.
- **The 50-a-month scan cap is copy, not code.** `PlusSheet.swift` says "50 a month" and there is
  no counter anywhere in `GameState` or `ScanSheet`. `CALENDAR-PLAN.md:194` costs the ceiling
  against that number. Either build the counter or take the number off the sheet — a promised
  limit that is not enforced is a cost surprise, not a student problem.
- **Server-side receipt check stays where it is:** the 2026-11-02 item in `LAUNCH-PLAN.md`. A
  Supabase Edge Function checks the signed transaction and writes an entitlement row, with App
  Store Server Notifications for refunds. Not in this scope, not moved earlier.
- **Billing grace period:** 16 days in App Store Connect, and `inGracePeriod` is treated exactly
  like `subscribed` in `PlusEntitlement.resolve`. A card that bounces must not cost a student
  anything. `Plus.swift` does not handle this today.

---

## 9. The sheet

Rewritten brief: `design/CLAUDE-DESIGN-PROMPT-PLUS.md`. The short version, so this file stands
alone:

- The kin is on it, doing what it does on Home. Never sad, never pleading, never locked.
- The perks are **things**, drawn, not a bulleted list with SF Symbols in circles.
- The first line says what stays free, the way Finch's benefits page does.
- The top third swaps per reason. The bottom two thirds never move.
- One coral button. Restore is a text link. The hardship row is a text link.
- A student who is already Plus never sees a price.
- No countdown, no crossed-out price, no "limited time", no "most popular" badge that is not
  true, and not once the word "unlock".

---

## 10. Signatures George owes

Eleven lines. Each one either breaks a written rule or spends something that cannot be
un-spent. Nothing in this spec ships until the ones it depends on are signed.

| # | The sentence to sign | Rule it costs | My recommendation |
|---|---|---|---|
| 1 | "Plus is a subscription. It lapses. LAUNCH-PLAN's 'nothing is ever taken away — no trial that ends' is replaced by the lapse promise in section 7." | R4, as written | **Sign.** Nothing else in this spec is valid without it. |
| 2 | "The gift week ends. That is the one number in the app that goes down." | R4, R6 | **Sign**, with the section 6 rules: no reminder, no countdown, never the words "your trial is ending". |
| 3 | "A 30% shop discount bought with money is not selling coins." | R2, arguably | **Sign.** It is Finch's exact perk, it moves nothing behind money, and every item stays reachable at full coin price forever. |
| 4 | "Plus looks and scenes stay yours after you cancel, so one paid month buys them forever." | revenue, not a rule | **Sign.** The leak is real. The alternative — taking a coat off a fish because a card expired — is worse than the leak by a wide margin. |
| 5 | "Google Calendar sync needs a Google account and an OAuth server — the first account Prepkin ever asks anyone for." | "No accounts", PRODUCT.md | **Do not sign.** Ship Apple Calendar plus an `.ics` file, which gets a student into Google Calendar with no account at all. |
| 6 | "Remove the 7-day App Store introductory offer. The gift week is the trial." | conversion | **Sign.** Two kinds of free is a timeline nobody can draw. |
| 7 | "Yearly moves from $79.99 to $69.99. Monthly stays $9.99." | ~$230/year at the base case | **Sign.** Asking more than Finch with a shorter list and no brand is the argument MARKETING-PLAN already lost once. |
| 8 | "Vibe cards ship 3-free / 6-Plus on day one of Friends phase 2." | build order | **Sign now**, because it expires. Six free cards shipped first can never be split. |
| 9 | "Plus gets an extra coin reward every day." | R2, directly | **Do not sign.** This is selling coins. Every coin in the app is worth less the day it ships. |
| 10 | "A paid mark appears under your name on your friend card, where other people see it." | social | **Sign.** Finch's Guardian sparkles, small, a mark and not a rank. |
| 11 | "Free Learn is capped at one new lesson a day, with every existing install grandfathered." | R1, R4 | **Do not sign.** Section 2a. Ship new units to Plus instead and keep all 57 free forever. |

---

## References

Mobbin screens looked at on 2026-09-10. Structure and honesty borrowed; none of the look.

- [Finch Plus benefits sheet, bird and perk list](https://mobbin.com/screens/0525a643-772d-4665-b5fc-b0d7d10a3a3a) — the shape of the whole thing: mascot first, four perks with one line of plain detail each, the yearly price with its per-month figure in brackets underneath, one button, "See all plans" as a text link. The "Daily shop deals: 50% off deals and more item slots at every shop" row is the source for perk 2.
- [Finch Plus, scrolled to the perk list](https://mobbin.com/screens/11ec5a8d-7a51-4e18-b70c-9d2da2a0e59a) — "Support our mission" as the last perk. Worth copying the idea, not the wording: paying is partly for the developer, and saying so out loud is why reviewers forgive Finch for being "largely cosmetic".
- [Finch "Become a Guardian" sponsor sheet](https://mobbin.com/screens/5476a849-e09a-437e-b4c8-c39260617658) — the source for perk 8, the hardship path. Ours is one mail row, not three sponsor tiers.
- [Quizlet "Choose your plan"](https://mobbin.com/screens/858c67d1-85ef-40e6-951e-42edbd774d0e) — two plain plan cards and, below them, "How monthly subscriptions work" as a dated vertical list. That list is the shape of our section 6 timeline.
- [Headspace "How your trial works"](https://mobbin.com/screens/a9bf58c3-250a-4565-9808-c4722933ea54) — same idea, three dated rows, "Today / In 12 days / In 14 days". The cleanest version of a timeline that does not read as a countdown.
- [Headspace 50%-off cancellation save](https://mobbin.com/screens/c995f167-095b-40b4-b8e1-13e2a3c54cc1) — an **anti-reference**. A crossed-out price on the way out of the door. We do not build this.
- [Duolingo Super family plan](https://mobbin.com/screens/0bedb164-b0a5-4d16-857d-6668670b0995) — mascots on a paywall, checked to confirm what to avoid: gradient, glow, a crowd of characters selling at you. Our kin does what it does on Home and nothing else.
