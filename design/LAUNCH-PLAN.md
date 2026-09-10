# Prepkin Canvas launch plan

Written 2026-09-06. The goal on the desk was 1,000 paying customers by 2026-12-31. This plan does not reach it and does not pretend to. It delivers 23 by 2026-12-31 and asks to move the 1,000 to the 2027 spring term. That swap is the first section, and it needs a written yes before 2026-09-08.

## The bet

We sell one thing: **Prepkin Plus**, a subscription in the iPhone app. **Its price and its eight perks live in `design/PLUS-SPEC.md` and nowhere else.** Perk 1 there is what this document used to call The Lamp: a look, three tank scenes and a small name plate that coins can never buy. We sell it to US college students who use Canvas on their own laptop, and we reach them with short video that points at the App Store, not at the Chrome Web Store, because the phone the student is holding is the phone that can buy. Everything that exists today stays free forever, including all 20 Canvas looks, the Receipt, put-back, the buddy panel, the timer, coins, Learn, Games, leagues and every accessibility setting. The free Chrome extension is the reason people stay, and the phone app is the front door and the till. Honest reach by 2026-12-31: about 23 paying customers, range 10 to 60, with a real but small chance of 150 to 250 if one video breaks out.

## The goal we are changing

**The goal was 1,000 paying customers by 2026-12-31. This plan delivers 23. The swap being asked for is a swap of objective, from count of customers to value per buyer.**

That swap has to be said out loud, because the price decision below is already optimised for it. $9.99 was chosen over $2.99 because it returns more per buyer. If the objective is still a count, $9.99 is the wrong price and the whole plan is aimed at the wrong target.

**The only 2026 variant that maximises count, and what it costs.** Take the cheapest credible item, a $1.99 one-time purchase, at the low-price buy rate of 1.4%.

| Route | Buy rate | Phone installs needed by 2026-11-26 | Net revenue at 1,000 payers |
|---|---|---|---|
| $1.99 item, naive 1,000 divided by 1.4% | 1.4% | about 71,000 | about $1,692 |
| $1.99 item, with the same day-35 lag and 5% refund haircut used everywhere else in this plan | 1.4% | about 87,000 | about $1,692 |
| $9.99 item, the plan | 1.2% | about 82,000 | about $8,492 |

The plan reaches 1,930 phone installs by 2026-11-26. The count-maximising route needs 87,000, which is 45 times more, from a standing start with no audience, in eleven weeks, on a budget under $2,000. It is not a stretch. It is arithmetically dead, at any price. Cutting the price does not rescue the count. It only lowers the ceiling if the count ever arrives.

**So the goal moves, and it is a real change, not a rounding.** The 1,000 is re-aimed at **2027-01-04 through the spring term**, starting with the 2027-01-04 to 2027-01-25 restart, which is the next install window the size of September 2026. The fall of 2026 is bought as a proof cohort: a live listing on both stores, measured pairing and buy rates, and a rating count that is not zero.

**George signs this or the plan is wrong.** Write "yes, count moves to 2027, fall is a proof cohort" in this file, with the date, before **2026-09-08**. If the answer is no, and 1,000 in 2026 is still the goal, then stop and rewrite the plan from the top, because nothing below is aimed at a count.

Signed: _______________ Date: _______________

## About the 1,000

**23 paying customers by 2026-12-31 is the plan. The range is 10 to 60.**

Three rates decide it, and all three sit below what the four draft plans assumed:

- Buy rate: 1.2% of phone installs by day 35. The rows that match a cosmetic, no-gate, one-time item are 1.0% (game cosmetic shops), 1.4% (low-priced apps) and 0.8% (real indie Chrome extensions), not the 2.1% freemium median.
- Pairing rate: 20% of extension installs pair a phone, base case, range 15 to 25%. It takes a second store, a second install and eight characters typed by hand, and about 15% of US students are on Android and cannot pair at all (own estimate, no source).
- Install rate: a brand-new Chrome listing with no ratings and no badge does 3 to 8 installs a day (own estimate, read off the indie posts in Sources, no direct figure). Every Canvas extension that is not BetterCampus sits between 360 and 3,000 users total.

At 1.2%, with the day-35 lag and the refund haircut, 1,000 payers needs about 82,000 phone installs by 2026-11-26. If the extension were the front door instead, at 20% pairing that is about 410,000 extension installs. BetterCampus has 1,000,000 users after about six years.

1,000 happens in 2026 only if one video does 5 to 15 million views and lands on a live listing. That is a lottery ticket, not a plan, so we buy the ticket daily and budget for the base case.

## What we sell

**Prepkin Plus, a subscription in the iPhone app, through Apple. `design/PLUS-SPEC.md` section 5 holds the only price table in this repo, and this document names no numbers of its own.**

> **Superseded on 2026-09-10, and read this before trusting any arithmetic below.** This section
> and everything downstream of it was written for **one non-consumable at $9.99, bought once**.
> Plus is a subscription. Three things are now stale and none of them is fixed here, because
> quietly rewriting a revenue model is worse than flagging it:
>
> - **"A paying customer" no longer means one unit.** It means an active subscriber, and the
>   same person can lapse and come back. The definition below, the case table, the weekly grid
>   and the 2026-11-26 column all count units. **They need rebuilding against monthly recurring
>   revenue before anyone quotes them again.**
> - **"Revenue is The Lamp alone at $9.99"** in the weekly grid is a first-month figure now,
>   not a lifetime one. Under a subscription the same 23 payers are worth more over a year and
>   less on day one.
> - **Two brand rules below do not survive a subscription** — "no trial that ends" and "nothing
>   is ever taken away". Their replacement is `PLUS-SPEC.md` section 7, and it is signature 1 in
>   that file's section 10. Do not ship Plus until George has signed it.
>
> What does survive, unchanged, and is used by `PLUS-SPEC.md`: the price-band argument in the
> next paragraph, the free-forever list, and every brand rule except the two named above.

**Price decision.** The argument for a high price band over a low one still stands and is the
reason Plus is $9.99 a month rather than the $3.99 `MARKETING-PLAN.md` used to argue for: low-priced
apps convert worse in the same dataset (1.4% against 2.0%) and return about a fifth of the year-one
value per buyer ($10.69 against $62.19). Note what that pair does **not** decide — it separates a low
band from a high one, and says nothing about $69.99 against $79.99 within the high band. That choice
is made on the pricing-page sentence, in `PLUS-SPEC.md` section 5.

**Where $10.69 against $62.19 comes from, and the one thing to check.** Both figures are read off the price-band table in the RevenueCat State of Subscription Apps report (https://www.revenuecat.com/state-of-subscription-apps), year-one revenue per payer by price band, low band against high band. This single pair is the whole argument for $9.99 over $2.99, so it is the one number in the plan worth re-reading at the source before 2026-09-08. If it cannot be found on that page, mark it "own estimate, no source" and redo the price decision from scratch. Note also that the report measures subscriptions, and The Lamp is a one-time purchase, so the ratio travels better than the absolute dollars do.

**Price points**

| Item | Price | When |
|---|---|---|
| Prepkin Plus, monthly and yearly | **`design/PLUS-SPEC.md` section 5** | Launch |
| Night Reef (one tank scene, standalone) | Dropped. It became a Plus scene — `PLUS-SPEC.md` perk 1. | — |
| Gift codes for testers, creators, and the hardship path | $0 App Store Connect promo codes | Any time, counted as zero payers |

The price is fixed through at least 2027-08-31. That boundary is a promise to ourselves and it stays in this plan. It does **not** go on the sheet, because a price guaranteed until a named date is a soft deadline, and this plan already rejects any "get it before it goes up" line. No launch discount, no season, no countdown.

**What used to be The Lamp is now perk 1 of Plus.** The list below is unchanged in content; what changed is that it arrives with a subscription instead of a single purchase, and that it stays yours after that subscription lapses (`PLUS-SPEC.md` section 7). In the code a "coat" of this kind is a **look** — the same `skinID` axis as `ninja` — not a new field.

- The Lamp look, a colourway Sprout wears on any kin at any stage, money-only forever.
- Three tank scenes: Observatory, Lantern Street, Snow Cabin.
- A small Lamp plate under the fish's name on Home, in the Shop and in Looks.
- Two scenes added later for everyone who already owns it: Desk Lamp and Long Night. They arrive silently in an update. No note, no date named in the app.

**Night is not the paid version of the app.** Every paid scene named above is a night scene, and app dark mode is not in 2026, so a fair reader could say the dark version costs money. That reading has to be made false in the product, not argued away in a document. So **Night Tank, one free night scene for the phone, ships in iOS 1.0, coin-priced like every other scene, before The Lamp ever goes on sale.** It is in the free list below and in the build list. The paid three stay a place set, not a dark set: Observatory, Lantern Street and Snow Cabin are named for where they are, and the free Night Tank is the one that is simply dark.

**What stays free, forever**

Everything shipping in 0.6.0 today. All 12 palette looks and all 8 image looks (graffiti, neon city, vaporwave, deep sea, forest, spring, cafe, nebula), earned with coins exactly as they are now. The Receipt, put-back and put-all-back. The buddy panel. The focus timer and the Reef Route. Pairing and the task list. The tank, every coin-priced kin, coat, costume, scene and look, Shop picks, Games, Learn (39 units), Friends, leagues. The Night Tank scene, coin-priced, shipping in iOS 1.0. Every accessibility setting, including the laptop's dark paper, which is already free and always will be.

**Where the purchase happens**

- On the phone: the Shop has a Lamp card on its own screen, reached by a plain link under the coin racks. Never a money row sitting inside a coin grid.
- On the extension: nothing. The extension never asks for money, never mentions a price on the Canvas page, and makes no payment request of any kind. The popup carries one plain line and no price.

**How the entitlement crosses the pairing code**

At launch it does not cross, and that is deliberate. Nothing paid lives on the laptop, so there is nothing to unlock there. On the phone, StoreKit 2 returns a verified transaction, and the app reads `Transaction.currentEntitlements` on every launch, so a refund removes the coat at the next open with no server involved. The 2026-11-02 update adds a Supabase Edge Function that checks the signed transaction and writes an entitlement row, plus App Store Server Notifications for refunds, so the count cannot drift. If the laptop ever gains a paid look in 2027, the flag rides inside the state the app already pushes, is cached on the laptop, and is removed only on an explicit "no pass" from a live row, never on a missing row or a failed fetch.

**Brand rules, one by one**

- ~~Nothing is ever taken away: one-time, non-consumable, no trial that ends, no season.~~ **Superseded 2026-09-10, and this is the one rule Plus actually costs.** Plus is a subscription, so it lapses, and it opens with a gift week that stops. The replacement rule is `PLUS-SPEC.md` section 7 — you keep your fish, your coins, every coin item, every Plus look and scene you wore, and every combination you saved; only new Plus *actions* stop. It is signature 1 in that file and Plus does not ship until it is signed.
- Every number can only go up: the pass grows with two extra scenes for everyone who owns it, and the plate is a mark, not a meter.
- Coins pay for finishing, never for grades: no coin item ever moves behind money, and coins are never sold.
- Accessibility is never behind money: contrast, reduced motion and the laptop's dark paper stay free, and a dark scene is already coin-reachable today — `deep` is `isDark: true` at 280 coins in `Theme.swift:205` — so the rule is visible in the product and not only stated here.
- No padlocks, meters, countdowns or question-mark tiles: the Lamp card sits in full colour with a price on its own screen, and the coat previews on an example fish, never on the student's own fish.
- No scolding: nothing in the app names midterms or finals at a student, and nothing dated appears in the app.
- The page belongs to the school: nothing on the Canvas page sells anything.
- The popup is the funnel and the screenshot: the free image looks are what appears in every clip.
- No exclamation marks anywhere in shipped copy or in a listing.
- No streaks. This one is currently false in shipped code. See the two audits below.

**Audit one: a streak is shipped today, in two places.** The rule says no streaks. The code says otherwise, and neither the popup nor the app has ever been checked against the rule.

- `extension/content.js:1400` renders "3 days in a row" in the rail footer on the Canvas page, and "Start a streak today" when the count is zero. The counter itself is built in `extension/day.js` around lines 125 to 130 and lives on the `streak` field of `weekStats`, which `extension/content.test.js:118` to `:137` also asserts on.
- `ios/Sources/WordleView.swift:468` to `:469` shows "N days in a row" after a win. The counter behind it is `wordleStreak` in `ios/Sources/Core/GameState.swift` (declared line 99, coded lines 152 and 207, written lines 463 to 465, read line 473), and line 465 resets it to 1 after a gap, so it is also a number that goes down. `ios/Sources/AppState.swift:439` exposes it to the view.

This is on the Canvas page, which means it is in the Chrome store screenshots, and clip 9 in the content list sells "no streaks" out loud. It is removed in the week of 2026-09-07, before the Chrome submit. The replacement is a count that can only rise, "N things finished this week". One more string has to move with it: `ios/Sources/DayEditorView.swift:738` reads "Nothing here counts a streak or warns you about losing anything", which is on our side of the argument but still puts the word on screen, so it becomes "Nothing here is a countdown, and nothing warns you about losing something". After that the word appears in no user-visible string at all, and a unit test enforces it with an allowlist of zero entries.

**Audit two: exclamation marks in shipped copy.** Two real hits, both in lesson art:

- `ios/Sources/LessonFigures.swift:867` draws "a like!" and `:2114` draws "ALL GOOD!". Both render into a figure a student sees.
- Two more hits, `ios/Sources/AppState.swift:170` and `ios/Sources/SlimeView.swift:588`, are code comments describing a "whoa!" animation, not shipped copy. They do not break the rule, and the sweep should not waste time on them, but a naive grep will surface them, so they are named here.

The sweep in the week of 2026-09-07 covers both, plus the banned engineering words, and ends in a test.

**Exact shop copy — superseded.** The card copy written here was for a one-time purchase and says
"$9.99, once" and "Yours for good", neither of which is true of a subscription. The live copy is
`design/PLUS-SPEC.md` section 3 (the two paragraphs) and section 7 (the lapse promise), and the
sheet brief is `design/CLAUDE-DESIGN-PROMPT-PLUS.md`.

One line from the old copy survives and should be kept word for word, because it is the honest
first line of the whole pitch: **"The one part of Prepkin that costs money. Everything else stays
free, and coins are never for sale."**

The first-coins note also survives, with one word changed: "First coins. That is the whole thing:
finish something real, Sprout gets paid. There is one paid plan if you ever want it. Nothing in it
is needed."

## The math

**A paying customer** is one non-refunded App Store unit of The Lamp or Night Reef. **(Stale — see the banner in "What we sell". Under a subscription this must be an active subscriber, and this whole section needs rebuilding.)** Counted from App Store Connect Sales and Trends units minus refunds. From 2026-11-02, when entitlement rows start existing, that count is reconciled monthly against our own rows. **When the two disagree, Apple wins.** Our rows are a check on our code, not on Apple's ledger. A $0 promo code is zero. A family-shared copy is zero, and Family Sharing is off anyway, because it cannot be turned off later.

**Which table is the source of truth.** Installs are decided in one place, the channel table, further down. The weekly grid below spreads those channel totals across the weeks each channel is live. The case table is a summary read off the weekly grid. So the order is: channel table, then weekly grid, then case table. **If any two disagree, the channel table wins, and the other two are wrong and get rebuilt.**

**The funnel, as one chain.** There are three rates and two install sources, and everything else in this plan is arithmetic on them.

    extension installs x pair rate = paired phone installs
    paired phone installs + direct App Store installs = total phone installs
    total phone installs x buy rate x (1 - refund rate) = paying customers

| Link in the chain | Low | Base | High |
|---|---|---|---|
| Extension installs by 2026-12-31 | 700 | 1,100 | 1,800 |
| Pair rate, extension install to a paired phone | 15% | 20% | 25% |
| Paired phone installs | 105 | 220 | 450 |
| Direct App Store installs | 1,500 | 2,150 | 3,600 |
| **Total phone installs by 2026-12-31** | **1,605** | **2,370** | **4,050** |
| Buy rate by day 35 | 0.8% | 1.2% | 1.8% |
| Refund haircut | 5% | 5% | 5% |
| **Paying customers by 2026-12-31** | **10** | **23** | **60** |

**The denominator is phone installs**, not extension installs, because the till is on the phone. Note what the chain shows: paired installs are 220 of 2,370, about 9% of the phone side. Pairing is a small lever on revenue and a large one on strategy. That matters for the 2026-10-04 tripwire, and it is spelled out below.

| Case | Extension installs | Pair rate | Paired phone | Direct phone | Total phone by 2026-12-31 | Phone by 2026-11-26 | Buy rate | Payers | Net revenue after Apple's 15% |
|---|---|---|---|---|---|---|---|---|---|
| Low | 700 | 15% | 105 | 1,500 | 1,605 | 1,300 | 0.8% | 10 | $85 |
| Base | 1,100 | 20% | 220 | 2,150 | 2,370 | 1,930 | 1.2% | 23 | $195 |
| High | 1,800 | 25% | 450 | 3,600 | 4,050 | 3,300 | 1.8% | 60 | $509 |
| What 1,000 needs | 20,000 | 20% | 4,000 | 97,000 | 101,000 | 82,000 | 1.2% | 1,000 | $8,492 |

The 2026-11-26 column is read off the weekly grid at the week of 2026-11-23, which is the week that date falls in. Revenue is The Lamp alone at $9.99. Night Reef units are upside and are not counted here.

**The low case is what this plan looks like if the video does not hit.** It is not a disaster scenario. It is the ordinary outcome of a new account that never breaks out. See the view-to-install arithmetic under Channels.

**Weekly cumulative targets, built cohort by cohort.** Payers are not a flat percentage of installs to date, because Education buyers pay late. Only 28.5% of the eventual buyers in any cohort buy in the first days. The rest arrive after day 35, which is five weeks. So the formula, applied to every row:

    payers = 1.2% x (0.285 x all phone installs to date
                     + 0.715 x phone installs from five or more weeks ago)
                  x 0.95 for refunds

Both stores go public in the week of 2026-09-28 in the base case, so the first three weeks are zero on purpose. The extension column starts at week four for the same reason.

| Week starting | Ext added | Ext total | Direct phone added | Paired phone added | Phone total | Payers |
|---|---|---|---|---|---|---|
| 2026-09-07 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2026-09-14 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2026-09-21 | 0 | 0 | 30 | 0 | 30 | 0 |
| 2026-09-28 | 130 | 130 | 150 | 26 | 206 | 1 |
| 2026-10-05 | 130 | 260 | 245 | 26 | 477 | 2 |
| 2026-10-12 | 110 | 370 | 210 | 22 | 709 | 2 |
| 2026-10-19 | 95 | 465 | 195 | 19 | 923 | 3 |
| 2026-10-26 | 85 | 550 | 175 | 17 | 1,115 | 4 |
| 2026-11-02 | 110 | 660 | 245 | 22 | 1,382 | 6 |
| 2026-11-09 | 90 | 750 | 200 | 18 | 1,600 | 9 |
| 2026-11-16 | 85 | 835 | 216 | 17 | 1,833 | 12 |
| 2026-11-23 | 35 | 870 | 90 | 7 | 1,930 | 14 |
| 2026-11-30 | 60 | 930 | 140 | 12 | 2,082 | 16 |
| 2026-12-07 | 50 | 980 | 110 | 10 | 2,202 | 18 |
| 2026-12-14 | 45 | 1,025 | 90 | 9 | 2,301 | 21 |
| 2026-12-21 | 30 | 1,055 | 30 | 6 | 2,337 | 23 |
| 2026-12-28 | 45 | 1,100 | 24 | 9 | 2,370 | 23 |

The Ext added column sums to 1,100 and the Ext total ends at 1,100, which is the channel table's extension total. Direct phone added sums to 2,150 and paired phone added sums to 220, so the phone total ends at 2,370, which is the channel table's direct total plus 20% of its extension total. Those three equalities are the check that the two tables agree. Re-run them after any edit to either.

**What changed, and by how much.** An earlier draft of this grid ran payers at a flat 1.2% of installs to date, which ignored the day-35 lag it had already assumed. That draft showed 15 payers at the week of 2026-11-02. Honest cohort arithmetic gives 6. Mid-fall was overstated by roughly two and a half times. The endpoint barely moved, 25 to 23, because by December most cohorts are mature. The middle of the fall is where the error lived, and the middle of the fall is where the tripwires read, so the tripwire thresholds below have been rebuilt too.

**The three assumptions that matter most**

1. Buy rate 1.2% of phone installs by day 35. Source: RevenueCat State of Subscription Apps 2026 (freemium 2.1%, Education 2.2%, low-priced 1.4%) pulled down toward the cosmetic-shop row (free-to-play games see 2 to 5% of active players pay, on a much smaller denominator, which is own estimate, no source) and the real indie Chrome extension figure of 0.8% on installs (dev.to, May 2026). Prepkin shows no lock, no grey-out and asks once, which removes the mechanism that produces the higher rows.
2. Pair rate 20% of extension installs, range 15 to 25%. Source: no benchmark exists, so this is the number to measure first. The bounds come from Chrome utility retention (30 to 50% uninstall immediately, about 8% weekly actives, Indie Hackers and aboutchromebooks) and from the estimate that roughly 15% of US 16 to 22 year olds are on Android and cannot pair (own estimate, no source). This rate now sits inside the chain, so changing it changes the phone install column and the payer column, and the 2026-10-04 read moves real numbers.
3. Education buyers pay late. Only 28.5% of Education conversions happen on day 0 and 23.5% of Education trial starts happen at day 31 or later (RevenueCat Education 2026, Adapty 2026). So an install after 2026-11-26 mostly cannot pay by 2026-12-31, and the real selling window closes then, not on 2026-12-18. This is the assumption the weekly grid is now built on.

**Tripwires**

Every tripwire below names the instrument that reads it. If there is no instrument, there is no tripwire. The instruments themselves are build items in the week of 2026-09-21.

- If the pair rate is under 15% on **2026-10-04**, then stop treating the extension as the funnel. Move the popup's phone card to the top, make every video point at the App Store only, and ship an unpaired first-run card in the app that hands people to the laptop. Read it as: rows in `pairings` with a bound `writer_hash` created in the last seven days, divided by the Chrome Web Store weekly-user count. Both sides of that fraction are rough. The Chrome dashboard reports weekly users on a delay, not installs, so the denominator is approximate and the number is a direction, not a measurement. What the tripwire is worth: at 15% instead of 20% the base case loses 55 phone installs and about one payer, so this is not a revenue tripwire. It is the test of whether the extension is a funnel at all. A low read means the extension is a retention product and a trust story, and every video and every dollar goes to the App Store.
- If the paid creator round has not produced installs under $4 each by **2026-10-11**, then do not run round two and hold the remaining money for the 2027-01-04 restart. Read it as: App Store Connect campaign-link installs on the eight creator links, against $960. If the campaign links are not live before the first creator post, this tripwire cannot be read at all and the round is judged on total lift instead. See Channels, attribution.
- If the day-35 buy rate for the first cohort is under 0.8% when read on **2026-11-08**, then do not cut the price. Fix the path to the Shop instead: the Lamp card is reached in one tap from Home, and the first-coins note is confirmed firing on a real device. Read it as: units in Sales and Trends against the week-of-2026-09-28 install cohort.
- If The Lamp is not on sale by **2026-10-15** because of an Apple delay, then 2026 ends near zero payers, the fall becomes the proof cohort, and every hour moves to the 2027-01-04 relaunch. The Apple contingency has its own decision date of 2026-09-25 and its own prepared fallback, in the Launch sequence.
- If total payers are under 4 on **2026-11-08**, or under 8 on **2026-11-22**, then stop all spending, keep posting, and write the 2027-01 plan. The base case is 6 and 12 on those two dates, and the low case is about 3 and 5, so this fires when the plan is running low and not when it is running to target. The old threshold of 8 on 2026-11-08 fired on the base case itself, which made it useless.
- If a Canvas deploy breaks a quiz, submit or login page at any point, then ship the put-back fix the same day and freeze everything else for seven days.

## Launch sequence

**Chrome first in the queue, App Store first in the market.** The Chrome Web Store is the slower and less predictable line, so it is submitted first and left to sit with deferred publishing, which gives 30 days to press Publish after approval. The App Store is where the money is, so the iPhone app is released the day it clears, even if Chrome has not. Public launch, not soft launch: a private or unlisted Chrome item goes through the same review, so there is no review-free path and nothing to gain from hiding.

**Earliest realistic dates, base case in bold.**

- Apple Developer enrollment: filed 2026-09-06 tonight. Approval **2026-09-08 to 2026-09-09**, tail risk two to nine weeks. Monday 2026-09-07 is Labor Day, so no support that day.
- Chrome Web Store developer account: registered 2026-09-07, verification takes one to three business days, so the first upload is possible **2026-09-09 or 2026-09-10**.
- Privacy policy and support mailbox live at a real URL: **2026-09-07**. Both stores block on both.
- schema.sql re-run on the live bridge plus the live suite: **2026-09-07**. Nothing pairs until this is done, and a reviewer who cannot pair is a rejection.
- First real-phone install with free provisioning: **2026-09-07 evening through 2026-09-09**. The app has never run on hardware, so budget two to four days of fixes, not two hours. Three days is the planning figure, and it is the first thing cut when the week runs out.
- Both store listings written in full: **2026-09-09**. Nothing can be submitted to either store without them.
- App Store screenshots from the simulator at 6.9 inch: **2026-09-09**, half a day. App Store Connect will not accept a submission without them, so they cannot wait for the polished preview video.
- Extension repackaged as 0.6.1 and all three suites re-run: **2026-09-10**, before the submit. The zip on disk today is 0.6.0 and predates every week-one change.
- Extension 0.6.1 submitted to Chrome under its new name: **2026-09-10**, Public with deferred publishing. Approval **2026-09-25** base case, range 2026-09-16 to 2026-10-07.
- Paid Apps Agreement, W-9 and banking: filed the hour enrollment lands, active about 24 hours later. No in-app purchase can be reviewed before it is active.
- iOS 1.0, free, no in-app purchase, with the free Night Tank scene: submitted **2026-09-11** if the account is live. Released manually **2026-09-16 to 2026-09-22**, allowing one rejection round.
- iOS 1.0.1 with The Lamp: submitted **2026-09-22**, live **2026-09-25 to 2026-10-01**. A sandbox purchase pass on a real device happens on **2026-09-21**, the day before, and blocks the submission.
- Public go-live day, both stores, one morning: **2026-09-30**. If Chrome is still in review, the app goes live alone and Chrome is published the morning it clears.
- Polished 30-second App Store preview video: **week of 2026-10-19**, shipped as a metadata-only update. It is not needed to submit.

Why the app ships free first: an in-app purchase cannot be submitted until the Paid Apps Agreement is active, and a first submission that also carries a $9.99 item whose main value a reviewer cannot see is a slower, riskier review. Shipping free first gets the listing, the search ranking and the seven-day new-app boost started while the paperwork clears.

**Free provisioning expires in seven days.** The first device build on 2026-09-07 uses a Personal Team, and Personal Team builds stop launching after seven days and have to be re-signed from Xcode. So the never-run-on-hardware blocker is closed on 2026-09-07 but does not stay closed on its own. Until enrollment lands, re-signing is a Monday chore. If enrollment has not cleared by **2026-09-18**, put a re-sign step on every Monday in the calendar through the end of the year, so the device pass does not quietly stop working and take the only real-hardware check with it.

**If Apple enrollment stalls: the contingency, decided 2026-09-25.**

Every dollar in this plan depends on one approval, and the risk table already calls that approval Medium likelihood of a two-to-nine-week stall. There is one prepared fallback, and a date to choose it.

- **Decision date: 2026-09-25.** If enrollment has not cleared by then, the fallback is built. If it has, the fallback is thrown away and nothing was lost but half a day of writing.
- **The fallback, option A: a US external-purchase link-out from the app.** Apple has permitted US-storefront apps to link out to an external purchase page since the 2025 injunction, under the US external purchase link entitlement. This still needs a live Apple account, so it only helps if the account exists but the paid agreements do not.
- **The fallback, option B, the one that survives no Apple account at all: web checkout through a merchant of record.** Lemon Squeezy or Paddle sells a code, the app redeems the code, and the app itself stays free. Paddle needs custom pricing under $10, so at $9.99 Lemon Squeezy is the likely pick. This route has a real cost: Apple's guideline 3.1.1 bans a license key used as an unlock inside an app that is otherwise sold through the App Store, so the redeem flow has to be designed carefully or held until the account clears.
- **What to do in the week of 2026-09-07, and only that: write the half-page spec and paste the two policy citations into it.** Do not build it. The point is that on 2026-09-25 the decision is a build, not the start of a research project.

## Week by week

**These week sections are the source of truth for tasks.** Every dated task appears in exactly one week block, and that block's range contains the date. The section called "This week, in order" further down is a date-ordered view of the week of 2026-09-07 and holds no tasks of its own. If the two ever disagree, this section wins.

**The weekly hour budget is 55 hours.** That is seven days at about eight hours, with no day off, which is already an unkind number and is the honest one for a solo founder trying to ship in ten days. Every week below carries an hours estimate. The channel table alone books 18.5 hours a week of marketing from the week of 2026-09-28 onward, so build work has about 36 hours in a normal week. "George runs out of hours" is rated High in the risk table, and these estimates are the test of it. When a week is over budget, the section says so and names what gets cut first.

### Week of 2026-09-07 (Mon) to 2026-09-13 (Sun) - Accounts, plumbing, first phone, both submissions
Labor Day is Monday 2026-09-07. No Apple support that day.

**Hours: about 94 against a budget of 55. This week does not fit and everyone should know it before it starts.** The list below is roughly 11.8 days of work in seven days. It is written out in full because cutting it silently is how a store submission slips without anyone deciding to slip it.

1. Commit and push the working tree as one checkpoint before touching anything else. (0.2 days)
2. Create `support@` on the new domain, forward it to the address George actually reads, and send a test message to it from a second account. Both stores require a working contact, and the Chrome account needs an email read daily. Nothing else this week can be submitted until this exists. (0.1)
3. Re-run bridge/schema.sql on the live Supabase project and run the live suite. Confirm a fresh code pairs from the app. (0.2)
4. Buy the domain. Host bridge/PRIVACY.md at a real URL, fill in the support email at bridge/PRIVACY.md line 190, which still reads "PUT A SUPPORT EMAIL HERE BEFORE PUBLISHING", add the Chrome Limited Use sentence, add the payments paragraph, add "Prepkin is independent and not affiliated with Instructure". Set homepage_url in the manifest. Host it on Cloudflare Pages, not GitHub Pages, because the per-channel redirect links in the Channels section need a host that reports click counts. (0.5)
5. Register the Chrome Web Store developer account for $5 with 2-Step Verification on and the support address as the contact. (0.2)
6. Rename the extension before it is ever published. `extension/manifest.json` line 3 is "Prepkin Canvas Sync" and the action `default_title` on line 22 is the same. Both become "Prepkin for Canvas, quiet themes and your work". The plan already removes "sync" from the popup, and leaving it in the store title and the browser tooltip leaves it in the two most student-facing strings there are. The rename costs nothing before publication, and renaming afterwards keeps the same item id but wastes a listing. (0.2)
7. Fix the two truth problems in the extension: remove the five-tap unlock in the popup, and replace "sync" and "Syncing" in the popup with "Check again" and "Getting your work". (0.3)
8. Remove the streak, everywhere. Delete the footer at `extension/content.js:1400`, delete the `streak` field from `weekStats` in `extension/day.js` and the three assertions in `extension/content.test.js`, delete the line at `ios/Sources/WordleView.swift:468` to `:469`, and delete `wordleStreak` from `ios/Sources/Core/GameState.swift` and `ios/Sources/AppState.swift:439`. Replace both surfaces with a count that only rises, "N things finished this week". Reword `ios/Sources/DayEditorView.swift:738`. Add a unit test that fails if the word "streak" appears in any user-visible string, with an allowlist of zero entries. This lands before the Chrome submit, because the rail is on the Canvas page and therefore in the store screenshots, and because clip 9 markets "no streaks". (0.5)
9. Copy sweep. Grep every user-visible string in `ios/Sources` and `extension` for "!" and for the banned engineering words: sync, bridge, endpoint, selector, API, token, schema, payload. Fix the hits. The known "!" hits are `ios/Sources/LessonFigures.swift:867` and `:2114`. Add a test that fails the build on a new one. (0.5)
10. Add the missing kill switches: no skin on assignment submission pages and no skin on any page with the Rich Content Editor open, both default-on, both with a unit test. (1)
11. Install the app on George's own iPhone with free provisioning and fix what a real device breaks. Free provisioning expires in seven days, so this is a recurring chore until enrollment lands. (2 to 4, budget 3)
12. Make the 1024 app icon, which does not exist yet. (0.5)
13. Rewrite the "sends nothing" line everywhere it appears, on Wednesday 2026-09-09: the popup, both store listings, the clip 3 script, and `PRODUCT.md` line 35, which still carries the false version. PRODUCT.md is where the brand rules come from, so the corrected sentence has to live there or it has no home of record. The corrected sentence is: "Reads only the Canvas you connect. Sends your coursework list and course grades to your own phone, and makes no other request." (0.3)
14. Write both store listings in full, due 2026-09-09. Chrome needs: name, 132-character summary, description, category, language, five 1280x800 screenshots, the 440x280 tile, the 1400x560 marquee, a privacy policy URL, a single-purpose statement and one justification per permission. The App Store needs: name, 30-character subtitle, 100-character keyword string, description, promotional text, support URL, marketing URL, privacy policy URL, age answers, the export-compliance answer and the category. The support URL is required alongside the privacy URL and is easy to forget. (0.5)
15. Shoot five App Store screenshots at 6.9 inch from the simulator, which runs the app today. Half a day, not a week. The polished 30-second preview video is a separate, later, metadata-only update in the week of 2026-10-19. (0.5)
16. Shoot the five Chrome screenshots, the tile and the marquee, and write one line of justification per permission. That includes both broad patterns, not only the first. (1.5)
17. Repackage the extension as 0.6.1 and re-run the unit, e2e and live suites, then load the zip unpacked and click through the popup once. The zip on disk is `dist/prepkin-canvas-0.6.0.zip`, built 2026-09-06, and every change in this week postdates it. Submitting a stale zip is a rejection and a lost queue slot, and a new publisher gets two slots. Due 2026-09-10, immediately before the submit. (0.3)
18. Submit extension 0.6.1 to Chrome on Thursday 2026-09-10, Public with deferred publishing, sandbox Canvas login in the test notes, GCP sandbox VM left running for the whole review. Never change a permission after approval. (0.2)
19. The hour Apple approves: accept the agreements, file the W-9 and banking, apply to the Small Business Program, create the app record, answer the age questionnaire as 13+, uncheck the EU, upload build 1 to internal TestFlight. (0.5)
20. Add PrivacyInfo.xcprivacy with the UserDefaults reason CA92.1, set ITSAppUsesNonExemptEncryption to NO, put the privacy link in the app. (0.3)
21. Build the reviewer demo path: a pre-seeded pairing code with sample tasks on the live bridge, or a local sample-task mode. (0.5)
22. Submit iOS 1.0 free on Friday 2026-09-11, with the reviewer pairing code and the 60-second video in the App Review notes. (0.2)
23. Write the half-page Apple-stall fallback spec and paste in the two policy citations. Do not build it. (0.5)
24. Confirm on Monday 2026-09-07 whether George can be physically at Dartmouth. If the answer is no, delete the Dartmouth row from the channel table that same day, move its $100 to the reserve, and restate the install totals, because 280 of the plan's installs depend on it: 200 extension and 80 direct phone, which is 120 phone installs once pairing is counted, and about one of the 23 payers. This has to be settled before any money or printing is committed. (0.1)

**If the hours run out, cut in this order.** First, the device-fix budget drops from three days to two and the rest is caught in the week of 2026-09-14. Second, the Chrome submit slips from Thursday 2026-09-10 to Tuesday 2026-09-15. That is the real lever, and it is cheap: a 09-15 submit moves base approval to about 2026-09-30 and Publish to the week of 2026-10-05, which shifts the extension column one week right and costs about 130 extension installs, 26 paired phone installs and well under one payer. **Do not cut the streak removal, the copy sweep, the rename or the repackage.** Those are the four that are wrong today and are visible in a store screenshot.

Targets: 0 phone installs, 0 extension installs, 0 payers.

### Week of 2026-09-14 (Mon) to 2026-09-20 (Sun) - Build The Lamp while both reviews sit
Nothing dated before 2026-09-14 lives here. The Chrome submit and the Apple paperwork are in the week above, where their dates are.

**Hours: about 44 against a budget of 55. This week has slack on purpose, because week one will spill into it.**

1. Open @prepkin on TikTok, Instagram and YouTube with the same fish avatar on 2026-09-14. (0.5 days)
2. Build The Lamp against a local StoreKit configuration file, which needs no Apple account: the non-consumable, the Lamp screen, Restore Purchases, `currentEntitlements` read on every launch. (3 of the 4 to 6 days, finishing in the week of 2026-09-21)
3. Build the free Night Tank scene for the phone, coin-priced, so a free night option ships in 1.0 before any paid night scene goes on sale. (1)
4. Answer any Chrome or Apple review question the same day it arrives. Never cancel and resubmit a Chrome item, because that resets the queue. (slack)
5. Catch whatever spilled out of week one, including the Chrome submit if it slipped to 2026-09-15.
Targets: 0 phone installs, 0 extension installs, 0 payers.

### Week of 2026-09-21 (Mon) to 2026-09-27 (Sun) - App live, quiet start
Stanford starts 2026-09-22. UC quarter campuses start about 2026-09-24 to 2026-09-28 (own estimate, no source, and worth ten minutes on the UC registrar pages before the campus clips are cut).

**Hours: about 68 against a budget of 55. Over by roughly a day and a half.** If it does not fit, the Lamp art narrows to the coat plus two scenes and Snow Cabin ships in 1.1. Do not cut the sandbox purchase pass.

1. Release iOS 1.0 manually the morning it is approved. Do not announce it widely yet. (0.2 days)
2. Finish the Lamp art: one coat plus three tank scenes in the Sprout source, with sign-off. (4 to 6)
3. Sandbox purchase pass on a real device, Monday 2026-09-21, before the 1.0.1 submit. Half a day, named as its own item because it has never been done: buy in the sandbox, force-quit and relaunch, Restore Purchases, take a refund through App Store Connect and watch what happens, then a full buy-and-restore on a device that has never paired. Write the revoke rule into the spec and build it: on revoke the app falls back silently to the last coin-owned coat, the Lamp card stays visible at its price, and there is no alert and no message of any kind. (0.5)
4. Submit iOS 1.0.1 with The Lamp on 2026-09-22 once the Paid Apps Agreement is active. Attach the product to the version with its review screenshot and name Restore Purchases in the notes. (0.2)
5. Set up App Store Connect campaign links, one per channel, before the first clip goes out. Set up the per-channel redirect pages for the extension on the Cloudflare Pages site. Without these the 2026-10-11 creator tripwire cannot be read at all. (0.3)
6. Build the tripwire instruments: the SQL query that counts `pairings` rows with a bound `writer_hash` created in the last seven days, and the Sunday cohort log itself. (0.5)
7. Bank 15 clips with HyperFrames so a bad week never breaks the posting rhythm. (2)
8. DM 80 nano and micro creators with the offer and a "post within seven days of my go signal" clause. Pay nothing until the listing is public. (1)
9. Post the first three clips on the Prepkin TikTok, pointing at the App Store campaign link. (0.5)
Targets: 30 phone installs, 0 extension installs, 0 payers.

### Week of 2026-09-28 (Mon) to 2026-10-04 (Sun) - Go live, the last clean week
University of Washington starts 2026-09-30. This is the last week before midterm pressure.
1. Press Publish on Chrome the morning it clears, target 2026-09-30, and nominate for the Featured badge through One Stop Support the same day with the 1400x560 marquee.
2. Give the creators the go signal for posts between 2026-10-01 and 2026-10-09.
3. Post one clip a day. Start the Reddit comment routine, two evenings a week, disclosed as the builder.
4. Dartmouth: subreddit post, Fizz and Sidechat, one QR table if George is on campus.
5. Read the pairing tripwire on 2026-10-04 using the pairings query. Under 15% means the popup changes in the next build and every video points at the App Store only.
6. Freeze the Canvas skin from 2026-10-04 through 2026-10-30. Put-back fixes only. Popup copy and phone builds are not covered by the freeze.
Hours: about 55. At budget.
Targets: 206 phone, 130 extension, 1 payer.

### Week of 2026-10-05 (Mon) to 2026-10-11 (Sun) - Midterms rising
1. Clips switch to the timer, the Receipt and the network tab. No look reveals this week.
2. Read the creator cost tripwire on 2026-10-11 from the App Store Connect campaign links. Over $4 an install means no round two.
3. Answer every store review and every message within a day.
4. Run the live smoke check after any Canvas release.
5. Start the November build in the background: Edge Function receipt check, refund notifications, the share card. The share card has to be finished by 2026-10-19 or it is cut from 2026.
Hours: about 50.
Targets: 477 phone, 260 extension, 2 payers.

### Week of 2026-10-12 (Mon) to 2026-10-18 (Sun) - Midterm peak
1. Daily clip, no code on the Canvas page.
2. Reddit comments in the school subreddits of the ten largest Canvas colleges.
3. Send $0 promo codes to every creator who posted, as thanks. They count as zero payers. (The cap is 100 codes per app per version, and content codes for a non-consumable draw on a separate pool with its own limit. We need 8, so it is fine now, and the constraint is written here in case the creator round ever grows.)
4. Publish the "For your school's IT" page and link it from the popup footer.
5. Ship the "Rate it" links: one in Settings, one in the Shop receipt after a purchase. Both are plain links, both one-time and dismissible, and neither is a rating prompt. See the ratings target under Channels.
Hours: about 45.
Targets: 709 phone, 370 extension, 2 payers.

### Week of 2026-10-19 (Mon) to 2026-10-25 (Sun) - Midterm tail
1. Cut the best three clips into a 45-second video for the Chrome listing, and ship the 30-second App Store preview as a metadata-only update.
2. Nominate the app for App Store featuring for finals week. Apple wants two weeks minimum.
3. Submit extension 0.7 by 2026-10-19 with deferred publishing, so it can be published in the week of 2026-11-02. Chrome review running three weeks or more is rated High in the risk table, so a same-week submit-and-ship in November is not a plan. If the share card is not finished by 2026-10-19, cut it from 2026 and move the share-card clips to the 2027-01 plan.
4. Keep the daily clip. Ask happy users in person for an honest rating.
Hours: about 55. At budget.
Targets: 923 phone, 465 extension, 3 payers.

### Week of 2026-10-26 (Mon) to 2026-11-01 (Sun) - Unfreeze
1. The skin freeze ends 2026-10-30. Ship the put-back fixes collected during midterms.
2. Submit iOS 1.1 by 2026-11-02. Extension 0.7 already went out on 2026-10-19.
3. Halloween clip on 2026-10-31 showing a coin-priced costume, free and earned.
Hours: about 50.
Targets: 1,115 phone, 550 extension, 4 payers.

### Week of 2026-11-02 (Mon) to 2026-11-08 (Sun) - The second window
This is the best acquisition week after September, and it holds the two real decisions.
1. Ship iOS 1.1: verified entitlements and refund handling. ~~Night Reef at $2.99 as the low step~~ — dropped 2026-09-10; that scene became a Plus scene in `design/PLUS-SPEC.md` perk 1, and a second paid tier alongside a subscription is a second price to explain.
2. Publish extension 0.7, already approved: the share card in the popup, drawn locally, no new permission.
3. Read the day-35 buy rate on 2026-11-08. Under 0.8% means fix the path to the Shop, not the price.
4. Read the total-payers tripwire on 2026-11-08. The base case here is 6, so the threshold is under 4.
5. Second campus push across the ten largest Canvas colleges.
Hours: about 60. Over by half a day, and Night Reef is the cut.
Targets: 1,382 phone, 660 extension, 6 payers.

### Week of 2026-11-09 (Mon) to 2026-11-15 (Sun) - Quiet, keep posting
1. Daily clip, now led by the share card.
2. Reddit: Canvas privacy and dark mode threads, disclosed.
3. Update the IT page with the shipped package hash, the rating count and the incident count.
Hours: about 40.
Targets: 1,600 phone, 750 extension, 9 payers.

### Week of 2026-11-16 (Mon) to 2026-11-22 (Sun) - Last full work week
An install after 2026-11-26 mostly cannot pay by 2026-12-31, so this is the last push that counts.
1. Two clips a day this week.
2. Submit anything that must ship in November by 2026-11-20 so review clears before the break.
3. Freeze the Canvas skin from 2026-11-20 through 2026-12-18.
4. Read the total-payers tripwire again on 2026-11-22. The base case here is 12, so the threshold is under 8. Under 8 means stop all spending, keep posting, and write the 2027-01 plan.
Hours: about 55. At budget.
Targets: 1,833 phone, 835 extension, 12 payers.

### Week of 2026-11-23 (Mon) to 2026-11-29 (Sun) - Dead week, build only
Thanksgiving is 2026-11-26. Campuses are closed most of the week. Post nothing that needs a reply.
1. Build the Friends backend on the bridge.
2. Reconcile entitlement rows against App Store Connect units minus refunds. Apple wins any disagreement.
3. Write the 2027-01 relaunch plan and batch-record clips for 2027-01.
Hours: about 35.
Targets: 1,930 phone, 870 extension, 14 payers.

### Week of 2026-11-30 (Mon) to 2026-12-06 (Sun) - Finals start
1. Retention content only: the timer, the tank at night, the Receipt. New installs now mostly cannot pay this year.
2. Push the two extra scenes silently to everyone who owns The Lamp. No note to anyone.
3. Fix the 2027-01 pairing cliff. Pairing rows expire 30 days after the last touch and are then deleted (`bridge/schema.sql` lines 47, 166 and 246 to 252). Any student whose laptop went quiet before about 2026-12-05 comes back on 2027-01-04 to a purged row, and the only way back is finding the eight-character code again. The whole 1,000 goal now leans on that 2027-01-04 restart, so this is not a small bug. Either raise `expires_at` to 120 days for rows that have ever had a bound writer, or add a silent re-pair path so the app hands the laptop a fresh code without the student typing anything. Test it by fast-forwarding a row's `expires_at` in the live suite.
4. Reply to reviews. No releases on the Canvas page.
Hours: about 45.
Targets: 2,082 phone, 930 extension, 16 payers.

### Week of 2026-12-07 (Mon) to 2026-12-13 (Sun) - Finals peak one
1. Support only. No releases.
2. Live smoke check after any Canvas deploy.
3. Read the October cohorts at day 35 and write the numbers down.
Hours: about 25.
Targets: 2,202 phone, 980 extension, 18 payers.

### Week of 2026-12-14 (Mon) to 2026-12-20 (Sun) - Finals peak two
High school semesters end around 2026-12-18 (own estimate, no source, and it varies by district). Apple review normally slows over the winter holidays, with the exact dates posted in Apple's developer news each year, so watch for the 2026 announcement rather than assuming 2026-12-20.
1. Last selling days. Nothing is submitted to Apple after 2026-12-18.
2. Full cohort review on Sunday 2026-12-20 for the 2027-01 plan.
Hours: about 25.
Targets: 2,301 phone, 1,025 extension, 21 payers.

### Week of 2026-12-21 (Mon) to 2026-12-27 (Sun) - Dead week
Winter break. Campuses closed. Post nothing.
1. Rest.
2. Finish the 2027-01 builds. Do not submit before 2026-12-28.
Hours: about 15.
Targets: 2,337 phone, 1,055 extension, 23 payers.

### Week of 2026-12-28 (Mon) to 2026-12-31 (Thu) - Close the books
1. Count paying customers on 2026-12-31 from App Store Connect units minus refunds.
2. Submit the 2027-01 builds on 2026-12-28 so they clear before the 2027-01-04 spring restart.
3. Write the spring plan around 2027-01-04 to 2027-01-25.
Hours: about 25.
Targets: 2,370 phone, 1,100 extension, 23 payers.

## Channels

**This table is the only source of install numbers in the plan.** The weekly grid spreads these totals across the weeks each channel is live, and the case table summarises the grid. The two install columns are separate: extension installs feed the pairing chain, direct phone installs go straight to the App Store. Total phone installs are 2,150 direct plus 20% of 1,100 extension, which is 2,370, and that is the number the weekly grid must end at.

| Channel | Tactic | Extension installs | Direct phone installs | Cost | Hours/week | Evidence |
|---|---|---|---|---|---|---|
| Prepkin short video, own account | One clip a day, App Store campaign link in bio | 0 | 900 | $0 | 7 | BetterCanvas grew from thousands to millions on user theme clips in 2024 (lionsroarnews). New accounts sit at a few hundred views for weeks (own estimate, no source). |
| App Store search | "study pet", "focus fish", "canvas" | 0 | 500 | $0 | 1 | New apps get about a seven-day boost then a cliff (own estimate, no source). The niche is crowded by Finch, Forest and Focus Friend. |
| Chrome Web Store search plus Featured | Keyword-loaded listing, nomination on day one | 500 | 0 | $5 | 1 | One documented Featured badge roughly doubled daily installs (habr). A zero-rating listing does 3 to 8 a day (own estimate, no source). |
| Paid nano and micro creators | 80 DMs, 8 signed at $120, posts 2026-10-01 to 2026-10-09 | 0 | 500 | $960 | 3 | Nano rates are $50 to $200 a video (influencermarketinghub). Cold creator outreach closes at 10 to 20% (own estimate, no source. The Cal AI piece describes 150 DMs but publishes no close rate). |
| Reddit, disclosed comments | Two evenings a week in the right threads | 300 | 60 | $0 | 2 | An indie extension got 1,300 installs in five weeks, mostly from niche threads (indiehackers). r/college bans self-promotion posts. |
| Dartmouth, one campus | Subreddit, Fizz, one QR table | 200 | 80 | $100 | 3 | Fizz saturated one campus first with paid ambassadors and venture funding (techcrunch, theithacan). The specific $41M figure is own recall, no source. Unpaid and solo, assume 2 to 5% of 4,500 undergrads. |
| Discord study servers | One post where rules allow, then answer | 0 | 80 | $0 | 1 | Study Together is the largest study server, with a member count in the low millions (own estimate, no source, and worth checking the server listing before relying on it). No published rate, no case study. A $0 experiment. |
| In-product sharing | Share card in the popup, Friends code swap | 100 | 30 | $0 | 0.5 | Duolingo's referral lifted new users only 3% (lennysnewsletter). This is a retention feature that leaks a few installs. |
| Owned audience, marketing site only | A "tell me when Android or dark mode ships" email box | 0 | 0 | $0 | 0 | No installs claimed in 2026. This exists so the fall has something that carries into 2027-01-04, which nothing else here does. |
| **Total** | | **1,100** | **2,150** | **$1,065** | **18.5** | Extension 1,100 and direct phone 2,150 are the two numbers the weekly grid must reproduce. Total phone installs are 2,150 + (1,100 x 20%) = **2,370**, which is the final row of the weekly grid. |

**The owned-audience row, and why it is not in the app.** The plan has no waitlist, no email list and no way to reach a single user again, and it leans the whole 1,000 on the 2027-01-04 restart. So one email box goes on the marketing site: "tell me when Android or dark mode ships". It never appears in the app or the extension, so the no-accounts promise inside the product stays exactly true. On the separate Prepkin SAT app as a cross-promotion channel: it cannot carry a link, because it has not launched. Revisit that when it does.

**Attribution, because none of the above can be measured without it.** The extension makes no requests and cannot report a referrer, which is the whole trust story and is not changing. So attribution has to sit outside the product.

- **App Store side:** App Store Connect campaign links, one per channel, created before the first clip on 2026-09-21. They are Apple-side, they break no analytics rule, and they cost nothing. Without them the 2026-10-11 creator tripwire cannot be read.
- **Extension side:** a per-channel redirect page on the marketing site, which has to exist anyway for the privacy policy. GitHub Pages reports no click counts, so the site goes on Cloudflare Pages instead, whose free Web Analytics reports them. Cost $0.
- **If either is not in place before the first creator post:** say so, and rewrite the creator tripwire to judge the round on total lift across the whole week rather than cost per install. Do not leave a tripwire on the page that nothing can read.

**Ratings, which nothing in the plan currently produces.** The Chrome install assumption of 3 to 8 a day is explicitly the zero-rating floor, and the only rating tactic anywhere is asking people in person at one campus. Target: **10 Chrome ratings and 10 App Store ratings by 2026-10-31.** The path is three things, all shipped in the week of 2026-10-12: a plain "Rate it" link in the app's Settings, a plain "Rate it" link in the Shop receipt after a purchase, both one-time and dismissible, and a line in the creator brief asking creators to rate honestly. These are static links a student chooses to tap, not a rating prompt that interrupts, so the no-nagging rule holds. If George decides even a link is too much, then say so here and lower the Chrome target from 500 to about 300, because the listing stays at the zero-rating floor all fall.

**Prepkin short video.** First three moves: open @prepkin on TikTok, Instagram and YouTube with the same fish avatar on 2026-09-14. Bank fifteen clips with HyperFrames during the week of 2026-09-21. Start posting the day the App Store listing is live, one clip a day, with the App Store campaign link in bio and never a Chrome link in a mobile video.

**What 900 installs from own video actually requires, said plainly.** This is the least defensible number in the plan and it is the largest. At an organic view-to-install rate of 0.2 to 0.3%, which is the defensible band, 900 installs needs 300,000 to 450,000 views. Spread over the 13 posting weeks from 2026-09-28, that is 69 installs a week, or roughly **3,300 to 5,000 views a day, every day, from an account opened on 2026-09-14 with no followers**. The same table's own evidence column says new accounts sit at a few hundred views for weeks. Both cannot be true without a breakout. So: the video target requires a hit. It is not a base-case number dressed up as one. If no clip breaks out, own video does perhaps 250 to 350 installs instead of 900, total phone installs land near 1,750, and payers land near the low case of 10. That is what the low case is for, and it is the more likely of the two.

**App Store search.** First three moves: write the listing around "study pet" and "focus fish", not around "Canvas", which is owned by Canvas Student. Shoot five 6.9-inch screenshots from the simulator on 2026-09-09, led by the tank and the Focus swim, because the 2026-09-11 submission cannot happen without them. Cut the polished 30-second preview from the best three clips in the week of 2026-10-19 and ship it as a metadata-only update.

**Chrome Web Store.** First three moves: register the account on 2026-09-07 with 2-Step Verification. Write the listing under the new name, "Prepkin for Canvas, quiet themes and your work", with "themes", "dark", "to-do" and "quiet" in the summary and "Prepkin is independent and not affiliated with Instructure" as the last line of the description, five 1280x800 screenshots led by graffiti, a 440x280 tile and a 1400x560 marquee. Nominate for Featured through One Stop Support the day it goes public.

**Paid creators.** First three moves: list 80 accounts from the "better canvas themes" and "canvas customize" discover pages during the week of 2026-09-21. DM all 80 with a flat $120, a free promo code, Spark rights, and a post-within-seven-days-of-my-signal clause. Pay nothing until the listing is public, and judge the round on App Store installs from that creator's own campaign link, against $120 each, read on 2026-10-11.

**Reddit.** First three moves: use one real account and say "I built this" every time. Answer three thread types: my Canvas is ugly, dark mode hid my submit button, is BetterCampus safe after the breach. Post properly only in r/SideProject and r/iOSApps, and give r/CanvasLMS the IT page as a question to admins, never as a pitch.

**Dartmouth.** First three moves: confirm on Monday 2026-09-07 that George can be on campus, before any money or printing is committed, and delete this row that same day if the answer is no. Post in r/dartmouth and Fizz the day the listing is live. Run one QR table with snacks, and treat the campus as the place where pairing and buy rates get measured, not as an install engine.

**Discord.** First three moves: read the rules of Study Together and two university servers. Post once in the resources channel. Answer questions and never post twice.

**In-product sharing.** First three moves: build the share card as a local PNG in extension 0.7, finished by 2026-10-19 so 0.7 can be submitted that day and published on 2026-11-02, or cut from 2026. Close every clip with "show me yours". Reward a Friends code swap with a cosmetic, capped at three friends, never with coins.

## Content to make

1. "My Canvas at 11:58pm and at 11:59pm." Twenty-second before and after screen recording, graffiti look, ends on the put-back tap. George films. TikTok, Reels, Shorts.
2. "The extension that shows you its receipt." Scroll the Receipt list, tap put all back, the page returns. George films. All three platforms and the Reddit comments.
3. "After the May Canvas breach I read what my extensions send." DevTools network tab open on a Canvas page, one call and nothing else. Spoken line: "Reads only the Canvas you connect. Sends your coursework list and course grades to your own phone, and makes no other request." George films. TikTok and r/CanvasLMS.
4. "I turned in my lab report and my fish got paid." Laptop and phone in one shot, submit, coins land in the tank. George films. This is the clip that only Prepkin can make.
5. "On a quiz it does nothing at all. That is the point." Quiz page with the extension on, nothing changes. George films. Also the clip to send a district IT person.
6. "Every Canvas look, in order of how late it is." All 20 looks cycling at 1.2 seconds each with name labels. HyperFrames renders. Saves and shares well.
7. "Ranking Canvas looks so you can argue with me." Live tier list, S to C. George films.
8. "Your major but it is a Canvas look." Bio is forest, CS is midnight, English is dark paper, art is graffiti. George films.
9. "Twenty-five minutes, one fish, no streaks." The Reef Route running over a real reading block. George films.
10. "The fish grows when you finish things. It never shrinks." Sprout stage one to two to three. HyperFrames renders from the stills.
11. "Stanford starts Tuesday. Set your Canvas up before week two." Campus template, re-cut for UW on 2026-09-30 and for the 2026-11-02 push. George films.
12. "My study app has a ninja fish and I am fine with it." The Shop picks row and the ninja costume, all coin-priced and free. George films.
13. "The one thing in Prepkin that costs money." The Lamp card, the coat on an example fish, the three scenes. Posted once, in the week of 2026-10-05, then never again. George films.
14. "Sunday night Canvas but make it a window seat." The Today block in the cafe look at 8pm. George films.
15. "Show me yours." The share card export, one tap, themed dashboard with a small corner tag. Product feature plus a clip, week of 2026-11-02.
16. "Finals week. The fish is also up late." The tank at night beside the laptop. George films, week of 2026-11-30.
17. Creator brief: a 30-second Canvas glow-up on their own dashboard, three hook options, their own words, name on screen, their own campaign link, and a line asking them to leave an honest rating on either store.
18. Chrome listing assets: five 1280x800 screenshots (popup over a graffiti dashboard, the Receipt with put-back, the buddy panel and timer, the phone tank beside the laptop, the network tab with one call), the 440x280 tile and the 1400x560 marquee.
19. App Store assets: five 6.9-inch screenshots (tank Home, Focus swim, Shop picks, Learn, the Night Tank scene), captured from the simulator on 2026-09-09 because the 2026-09-11 submission blocks on them. The 30-second preview cut from clips 1, 4 and 6 comes later, in the week of 2026-10-19, as a metadata-only update. The Lamp card replaces one screenshot in the 1.0.1 listing update.
20. The 60-second demo video for both store reviewers and for any school that asks: pair with the code, the Receipt, put-back, the timer, the coins landing.
21. "For your school's IT", a one-page PDF and a web page: permissions with one-line reasons, the single endpoint, the package hash, the pages never touched, the FERPA paragraph, "not affiliated with Instructure", and a support email.

## Trust and schools

**The story, said accurately.** The old line was wrong, so it changes. It changes in five places on Wednesday 2026-09-09: the popup, the Chrome listing, the App Store listing, the clip 3 script, and **`PRODUCT.md` line 35**, which still reads "Reads nothing it does not need, sends nothing but the task list to the student's own phone". PRODUCT.md is the document the brand rules come from, so if it keeps the false line the corrected sentence has no home of record. The sentence PRODUCT.md carries afterwards is: "Reads only the Canvas you connect. Sends your coursework list and course grades to your own phone, and makes no other request."

The extension reads only the Canvas the student connects, and it sends the student's coursework list and their course grades to the student's own phone through one address, and it makes no other request. No fonts, no CDN, no analytics, no accounts, no email, no password. It never touches a login page, a quiz being taken, a submission page, or a page with the Rich Content Editor open. Everything it changes on a Canvas page is listed on a Receipt, and one click puts all of it back. The Chrome privacy tab declares Website content and does not declare User activity, which is a visible difference from BetterCampus.

**How to get allow-listed.** Most districts run Chrome in block-all mode with an allowlist and take student requests through their own help desk. So the request comes from a student, with our IT page attached, and George emails the ed-tech lead the next business day offering a call and the package hash. Aim the first three requests at districts that blocked BetterCampus, because being allowed where it was blocked is the proof point that travels. Do not expect approvals before **2027-01**. Committees meet monthly.

**Where the independence line goes.** The extension's own name leads with "Canvas", which is Instructure's trademark, so the disclaimer cannot live only on the privacy page and the IT page. "Prepkin is independent and not affiliated with Instructure" is the **last line of the Chrome store description and the last line of the App Store description**, as well as on the privacy page and the IT page. The rename in the week of 2026-09-07 keeps "for Canvas" rather than leading with it as a brand.

**What goes on the privacy page,** hosted at a real URL before either submission: what is read, what is sent, the one address it is sent to, that the purchase happens through Apple and Prepkin stores only that the purchase exists, the Chrome Limited Use sentence, retention and deletion, the support email, and "Prepkin is independent and not affiliated with Instructure". Any later change to what is sent has to be disclosed to existing users before it ships, because the Chrome rule that took effect 2026-08-01 requires it.

**The second broad pattern in the manifest, and what to say about it.** The Chrome submission carries a justification for the broad `optional_host_permissions` of `https://*/*`. There is a second broad pattern in the same file that reviewers flag separately: `web_accessible_resources[0].matches` is also `https://*/*` (`extension/manifest.json` lines 37 to 39). It cannot simply be narrowed to a fixed list, because the extension declares no static content scripts and injects on whatever origin the student has granted, so the resource pattern has to cover the same open set the grant does. The fix is two lines of work, not a rewrite: write its justification in the same document as the host-permission one ("panel.css and the art files are injected only into origins the student has already granted, and the pattern must match that same open set because school Canvas domains are not knowable in advance"), and set `"use_dynamic_url": true` on the resource entry so the URLs are not a stable fingerprint any site can probe. Then verify the panel and the art still load on the sandbox Canvas before the 2026-09-10 submit.

**Three sentences for a district IT person.** "Prepkin runs in the student's own browser on the student's own Canvas login, so the school discloses nothing to us and no FERPA exception is needed. It reads a small set of read-only endpoints, sends the student's coursework list and course grades to that student's own phone through one address, and makes no other network request at all, which you can confirm in the network tab in about a minute. It does nothing on login, quiz, submission or editor pages, and every change it makes is listed with a one-click undo, so a student can turn it off on any page you ask them to."

## Build list

| Item | Days | Must land |
|---|---|---|
| Commit and push the working tree | 0.2 | Week of 2026-09-07 |
| support@ on the new domain, forwarded and test-mailed from a second account | 0.1 | 2026-09-07 |
| schema.sql re-run on the live bridge plus live suite | 0.2 | Week of 2026-09-07 |
| Privacy page hosted on Cloudflare Pages, support email filled in at bridge/PRIVACY.md line 190, Limited Use sentence, payments paragraph, homepage_url | 0.5 | Week of 2026-09-07 |
| Rename the extension: manifest name and action default_title to "Prepkin for Canvas, quiet themes and your work" | 0.2 | Week of 2026-09-07 |
| Remove the five-tap unlock in the popup and the two "sync" strings | 0.3 | Week of 2026-09-07 |
| Remove the streak from content.js, day.js, content.test.js, WordleView, GameState and AppState, reword DayEditorView:738, replace with "N things finished this week", add a test that fails on the word in any user-visible string | 0.5 | Week of 2026-09-07, before the Chrome submit |
| Copy sweep: grep ios/Sources and extension for "!" and for sync, bridge, endpoint, selector, API, token, schema, payload, fix the hits, add a test that fails the build on a new one | 0.5 | Week of 2026-09-07 |
| Kill switches for submission pages and the Rich Content Editor, with tests | 1 | Week of 2026-09-07 |
| Rewrite the "sends nothing" line in the popup, both listings, the clip 3 script and PRODUCT.md line 35 | 0.3 | 2026-09-09 |
| App icon at 1024, made and signed off | 0.5 | Week of 2026-09-07 |
| First real-device run and the fixes it finds. Free provisioning expires in 7 days, so re-signing is a weekly chore until enrollment lands | 2 to 4 | Week of 2026-09-07, then weekly |
| Write both store listings, full text. Chrome: name, summary, description, category, privacy URL, single-purpose statement, per-permission justifications. App Store: name, subtitle, 100-character keywords, description, promotional text, support URL, marketing URL, privacy URL, age answers, export answer | 0.5 | 2026-09-09 |
| App Store screenshots, five at 6.9 inch, captured from the simulator | 0.5 | 2026-09-09 |
| Chrome listing assets, plus a justification for both broad patterns, plus use_dynamic_url on web_accessible_resources, verified on the sandbox Canvas | 1.5 | Week of 2026-09-07 |
| Repackage 0.6.1, re-run unit, e2e and live suites, reinstall the zip unpacked and click through the popup once | 0.3 | 2026-09-10, immediately before the submit |
| PrivacyInfo.xcprivacy, encryption key, privacy link in app | 0.3 | Week of 2026-09-07 |
| Reviewer demo path: pre-seeded pairing code with sample tasks, or a local sample-task mode | 0.5 | Week of 2026-09-07 |
| Apple-stall fallback: half-page spec plus the two policy citations, written not built | 0.5 | Week of 2026-09-07, decided 2026-09-25 |
| The Lamp: StoreKit 2 non-consumable, local .storekit config, Lamp screen, Restore, currentEntitlements on launch | 4 to 6 | Week of 2026-09-14 to 2026-09-21 |
| Night Tank, one free coin-priced night scene for the phone, shipping in iOS 1.0 before any paid night scene | 1 | Week of 2026-09-14 |
| The Lamp art: one coat plus three tank scenes in the Sprout source, with sign-off | 4 to 6 | Week of 2026-09-21 |
| Sandbox purchase pass on a real device: buy, force-quit and relaunch, Restore, an App Store Connect refund, then a full buy-and-restore on a device that has never paired. Revoke rule built and written into the spec: silent fall back to the last coin-owned coat, Lamp card stays visible at its price, no alert and no message | 0.5 | 2026-09-21, blocks the 2026-09-22 submit |
| App Store Connect campaign links per channel, plus per-channel redirect pages on Cloudflare Pages | 0.3 | Week of 2026-09-21, before the first clip |
| Tripwire instrument: SQL over pairings counting rows with a bound writer_hash created in the last seven days | 0.3 | Week of 2026-09-21 |
| Cohort log, written by hand each Sunday: installs, pairings, purchases, plus "rows touched in the last seven days" from bridge updated_at as the only available proxy for actives. "First tasks" is deleted from the log, because nothing in the product produces it and no analytics are being added | 0.3 | Week of 2026-09-21 |
| Counting, part one: App Store Connect Sales and Trends units minus refunds, full stop. There are no entitlement rows to reconcile against yet | 0.2 | Week of 2026-09-28 to 2026-11-01 |
| Unpaired first-run card in the app that hands the student to the laptop | 0.5 | Week of 2026-09-28 |
| IT page and PDF | 0.5 | Week of 2026-10-12 |
| "Rate it" links in Settings and in the Shop receipt, one-time and dismissible, no rating prompt | 0.3 | Week of 2026-10-12 |
| 30-second App Store preview, shipped as a metadata-only update | 0.5 | Week of 2026-10-19 |
| Share card in the popup, drawn locally, finished in time for the 2026-10-19 submit of 0.7 or cut from 2026 | 1 | By 2026-10-19 |
| Edge Function receipt check plus App Store Server Notifications for refunds | 2 | Week of 2026-11-02 |
| Counting, part two: add the entitlement-row reconcile on top of Sales and Trends. Apple wins any disagreement | 0.3 | Week of 2026-11-02 |
| ~~Night Reef at $2.99~~ — dropped 2026-09-10, folded into Plus perk 1. The scene art is still needed and still unbudgeted. | 2 to 2.5 | Week of 2026-11-02 |
| Submit the Night Reef IAP with the 1.1 version, with its own review screenshot | 0.2 | Week of 2026-11-02 |
| Friends code swap with a cosmetic reward, capped at three | 2 | Week of 2026-11-23 |
| Pairing expiry fix before the 2027-01-04 restart: raise expires_at to 120 days for rows that have ever had a bound writer, or add a silent re-pair path. Test by fast-forwarding a row's expires_at in the live suite | 1 | Week of 2026-11-30 |
| Two extra Lamp scenes for existing owners | 2 | Week of 2026-11-30 |
| App dark mode | not in 2026 | 2027-01 |
| Android app | not in 2026 | 2027 at the earliest |

App dark mode is off the 2026 list. The laptop already has a free dark paper, the free Night Tank scene ships in 1.0, and the app's paper, plates and kin art are tuned for cream, so a real dark mode is an art job, not a token swap.

Android is off the 2026 list too, and it is worth saying why, because the pairing assumption puts about 15% of the audience on Android where they cannot pair at all. The tank is a web build and would port. Nothing else would: the whole app is SwiftUI, there is no second store account, and there are no hours. So the answer to the 15% is that we lose them in 2026 and revisit in 2027.

## Budget

**Committed $1,184, plus an $81 conditional reserve, so the ceiling is $1,265.** The reserve is not committed spend and should not be counted as though it were.

| Line | Cost | Committed? |
|---|---|---|
| Apple Developer Program, one year | $99 | Committed |
| Chrome Web Store developer registration, one time | $5 | Committed |
| Domain for the privacy page and the IT page | $20 | Committed |
| Paid creators, 8 at $120 | $960 | Committed |
| Dartmouth table: printing, QR cards, snacks | $100 | Committed, and deleted on 2026-09-07 if George cannot be on campus |
| **Committed total** | **$1,184** | |
| Reserve, released only if a creator clip beats $4 an install | $81 | Conditional |
| **Ceiling** | **$1,265** | |
| Paid ads | $0 | Never |

**The revenue, which the plan never stated.**

| Case | Payers | Net revenue after Apple's 15% |
|---|---|---|
| Low | 10 | $85 |
| Base | 23 | $195 |
| High | 60 | $509 |

**The fall costs about $989 net in the base case.** That is $1,184 committed against $195 of revenue. It is bought as a proof cohort for the 2027-01-04 restart: a live listing on both stores, real pairing and buy rates instead of guesses, and a rating count that is not zero. The only reversible line in it is the $960 of creator spend, which is why the 2026-10-11 tripwire sits on that line and nothing else.

Every payer figure in this plan already carries a 5% refund haircut, because the definition of a paying customer is a non-refunded unit.

No Spark Ads, no Meta, no Apple Search Ads. At $3 to $9 an install the whole budget buys under 400 installs, which is worse per dollar than any free channel here. The unspent $735 from the original $2,000 stays for the 2027-01-04 restart, when there will be measured rates to spend against. **$119 of that carry-over is already spoken for by the 2027 renewals**, the $99 Apple Developer Program around 2026-09-08 and the $20 domain, so the free money is really about $616.

## Risks

| Risk | Likelihood | Impact | Cheapest fix | Tripwire date |
|---|---|---|---|---|
| Apple enrollment stalls for weeks, so nothing can be sold | Medium | Fatal to the count | Enrolled 2026-09-06 with legal name and own card, support case with the Enrollment ID if silent by 2026-09-08. On 2026-09-25, if it has still not cleared, build the prepared fallback: a US external-purchase link-out, or a merchant-of-record web checkout selling a code the app redeems. The half-page spec is written in the week of 2026-09-07 so that decision is a build, not research | 2026-09-25 |
| Chrome review runs three weeks or more | High | Delays the laptop half | Submitted 2026-09-10 with deferred publishing, sandbox login in the notes, escalate at three weeks, never cancel and resubmit | 2026-10-07 |
| Chrome rejects outright on the broad host permission | Medium | Blocks the laptop half entirely | Reply inside the same item, never open a new one, because a new item resets the queue and a new publisher gets two item slots. Keep a prepared branch, scoped but unbuilt: an explicit allowlist of *.instructure.com plus the top 200 university Canvas hosts, with activeTab for everything else. It is a worse product and it is not the plan, but it exists so the reply can be a fix rather than an argument | On rejection |
| Apple rejects under Guideline 2.1 because the reviewer cannot pair | Medium | Costs three to five days | Pre-seeded pairing code with sample tasks, a local sample-task mode, the 60-second video, every tab usable unpaired | 2026-09-18 |
| Pairing lands under 15% | High | Small on revenue, about one payer, but it means the extension is not a funnel | Point every video at the App Store, put the phone card first in the popup, ship the unpaired first-run card. Read it with the pairings query, and treat the number as a direction rather than a measurement | 2026-10-04 |
| Buy rate lands at 0.8% instead of 1.2% | Medium | Payers fall from 23 to about 15 | Do not cut the price. Shorten the path from Home to the Lamp card and confirm the first-coins note fires on device | 2026-11-08 |
| No clip breaks out | High | The count falls to the low case, about 10, because 900 of 2,150 direct installs assume a hit | Post daily anyway, copy proven formats, and read the outcome honestly rather than spending into it | 2026-11-22 |
| A store listing sits at zero ratings all fall | High | The Chrome install rate stays at the 3 to 8 a day floor | Ship the two plain "Rate it" links in the week of 2026-10-12, ask creators to rate honestly, ask in person at Dartmouth. Target 10 and 10 by 2026-10-31 | 2026-10-31 |
| The 2027-01-04 restart lands on purged pairing rows | Medium | Returning students hit a dead code in the week the plan depends on most | Raise expires_at to 120 days for rows that ever had a bound writer, or ship a silent re-pair path, in the week of 2026-11-30 | 2026-11-30 |
| A Canvas deploy breaks a quiz or submit page and a school blocks us | Medium | Loses a campus and the trust story | Kill switches default-on, freezes 2026-10-04 to 2026-10-30 and 2026-11-20 to 2026-12-18, live smoke check after every Canvas release, one-click put-back | Any deploy |
| The old "sends nothing" line is quoted back at us as false | High if unfixed | Store rejection and a trust hit | Change the line on 2026-09-09 in the popup, both listings, the clip 3 script and PRODUCT.md line 35, to name the coursework list and the course grades | 2026-09-10 |
| A shipped streak is quoted back at us against the "no streaks" rule | Certain if unfixed | Contradicts clip 9 and the brand rules, in a store screenshot | Delete it from both surfaces in the week of 2026-09-07, before the Chrome submit, and add the test | 2026-09-10 |
| George runs out of hours in week one | Certain | A store submission slips without anyone deciding to slip it | Week one is 94 hours against a 55-hour budget and says so. The cut order is written into the week section: device fixes drop to two days, then the Chrome submit slips to 2026-09-15, which costs under one payer | 2026-09-13 |
| Refund or entitlement drift on the phone | Low | Support noise | currentEntitlements on every launch at launch, verified rows and refund notifications on 2026-11-02, monthly reconcile | 2026-12-20 |
| BetterCampus ships Campies during the window | Medium | Takes the pet story | Ship first, sell the phone, the coins for verified finishing, the Receipt and no account. Spend zero days on GPA, notes or planners | 2026-10-31 |
| George runs out of hours | High | The daily clip dies first | Three clips a week batched in one Saturday block is the floor. Everything else is optional | Any week |
| Texas SB 2420 adds a parent tap for some 16 and 17 year olds | Certain | Small | Nothing to build for a 13+ no-account app. Watch Apple's developer news | None |

## This week, in order

**This is a date-ordered view of the week of 2026-09-07 section above. It adds no tasks.** If a task is here and not there, one of the two is wrong, and the week section is the one that is right.

1. Tonight, 2026-09-06, enroll in the Apple Developer Program in the Apple Developer app with the exact legal name, your own card and a licence scan.
2. Tonight, commit and push the working tree as one checkpoint.
3. Monday 2026-09-07, create support@ on the new domain, forward it to the address you read, and send it a test message from a second account. Nothing else this week can be submitted until this exists.
4. Monday 2026-09-07, answer the Dartmouth question. If you cannot be on campus, delete the Dartmouth row from the channel table today, move the $100 to the reserve, and restate the install totals.
5. Monday 2026-09-07, register the Chrome Web Store developer account for $5 with 2-Step Verification on and the support address as the contact.
6. Monday 2026-09-07, buy the domain and host bridge/PRIVACY.md on Cloudflare Pages with the support email filled in at line 190, the Chrome Limited Use sentence, the payments paragraph and the "not affiliated with Instructure" line.
7. Monday 2026-09-07, re-run bridge/schema.sql on the live Supabase project, run the live suite, and pair a fresh code from the app.
8. Monday 2026-09-07 evening, install the app on your own iPhone with free provisioning and start the first real-device pass. Note the seven-day expiry and put a re-sign reminder on next Monday.
9. Tuesday 2026-09-08, get George's written yes on the goal swap in "The goal we are changing", or stop and rewrite the plan.
10. Tuesday 2026-09-08, spend the day on whatever the phone found, and make the 1024 app icon.
11. Tuesday 2026-09-08, rename the extension in the manifest, delete the five-tap unlock in the popup, and replace the two "sync" strings.
12. Tuesday 2026-09-08, remove the streak from both surfaces and add the test that fails on the word.
13. Wednesday 2026-09-09, run the copy sweep for "!" and the banned engineering words, and add the test.
14. Wednesday 2026-09-09, add the kill switches for submission pages and the Rich Content Editor, with a unit test each.
15. Wednesday 2026-09-09, rewrite the "sends nothing" line in the popup, both listings, the clip 3 script and PRODUCT.md line 35.
16. Wednesday 2026-09-09, write both store listings in full, including the App Store support URL.
17. Wednesday 2026-09-09, shoot the five App Store screenshots at 6.9 inch from the simulator. Half a day.
18. Wednesday 2026-09-09, shoot the five Chrome screenshots, the tile and the marquee, and write a one-line justification for both broad patterns, plus use_dynamic_url on web_accessible_resources.
19. Thursday 2026-09-10, repackage 0.6.1, re-run the unit, e2e and live suites, and click through the popup once from the unpacked zip.
20. Thursday 2026-09-10, submit extension 0.6.1 to Chrome, Public with deferred publishing, with the sandbox Canvas login in the test notes, and leave the sandbox VM running.
21. Thursday 2026-09-10, the hour Apple approves, accept the agreements, file the W-9 and banking, apply to the Small Business Program, create the app record, and upload build 1 to internal TestFlight.
22. Friday 2026-09-11, add PrivacyInfo.xcprivacy with reason CA92.1, set ITSAppUsesNonExemptEncryption to NO, answer the age questionnaire as 13+, uncheck the EU, and submit iOS 1.0 free with the reviewer notes and the demo video.
23. Saturday 2026-09-12 and Sunday 2026-09-13, write the half-page Apple-stall fallback spec with its two policy citations, and catch up on whatever slipped. Do not start The Lamp until the week of 2026-09-14.

**This week is 94 hours of work in a 55-hour budget.** Read the cut order at the end of the week of 2026-09-07 section before Wednesday, not after.

## What the skeptics killed

- Paid Canvas looks or any paid unlock inside the extension. It forces a second Chrome review, breaks the Featured rule that core features are free, and risks a rejection for saying free while gating.
- Reading a purchase flag off the pairing row at launch. Pairing rows expire in 30 days and get purged, so a paid item would vanish for a student who left the laptop shut. The expiry itself is raised in the week of 2026-11-30 for the 2027-01-04 restart, and this decision stands either way, because an entitlement should not depend on a row that can be deleted.
- The founder mark beside a nickname in leagues. It makes money visible as rank on a board that is supposed to be about finishing, and it changes what other people can see about you without disclosure.
- Dated seasonal drops and any "get it before it goes up" price. The Shop already promises no seasons and no last chance.
- The word "Founder" as the product name. It only means something if it ends, and nothing here ends.
- Previewing a paid coat on the student's own fish and then removing it. That is taking something away at the worst possible moment.
- Dated in-app notes that name midterms or finals and point at a paid shelf. That is scolding plus a countdown.
- Narrowing optional_host_permissions to instructure.com. Chrome cannot request an origin that is not already declared, so it would break every school with its own Canvas domain, including Dartmouth. The narrowed allowlist survives only as an unbuilt fallback branch for an outright rejection, in the risk table, and it is not the plan.
- Narrowing web_accessible_resources.matches to a fixed list. Same reason: the extension declares no static content scripts and injects on whatever origin the student granted, so the resource pattern has to match the same open set. It gets a written justification and use_dynamic_url instead.
- Putting the price boundary on the product card. "The price stays $9.99 through August 2027" is a named date, and a named date is a soft deadline. The boundary stays in this plan. The card says "One price. It does not go up."
- Reaching 1,000 in 2026 at any price. A $1.99 item at the low-price buy rate needs about 87,000 phone installs by 2026-11-26 against a plan that reaches 1,930. Cutting the price does not rescue a count that is 45 times away.
- The claim "sends nothing but your task list". Course names, course codes and current grades also go to the bridge, and the privacy policy already says so.
- Cutting the price to $1.99 or $2.99 as a rescue. Low-priced apps convert worse and earn a fifth as much per buyer.
- Spark Ads, Meta and Apple Search Ads. At $3 to $9 an install the whole budget buys under 400 installs.
- Campus ambassadors at Fizz rates. About $1,000 per campus per semester for one campus.
- Product Hunt and Hacker News as student channels. Show HN posts for student extensions scored two or three points.
- App dark mode as a 2026-12 feature. The laptop's dark paper is already free, the free Night Tank scene ships in iOS 1.0, and the app's art is tuned for cream, so it is an art job for 2027-01.
- Any funnel that reaches 1,000 on paper. Four plans tried and twelve skeptics refuted all four.

## Sources

https://developer.apple.com/help/account/membership/program-enrollment/ - Apple Developer Program is $99 a year, individuals must use their own card, a wrong name delays approval
https://developer.apple.com/support/enrollment/ - sole proprietors enroll as individuals, confirmation expected within 24 hours of purchase
https://developer.apple.com/forums/thread/822540 - 2026 reports of individual enrollments stalled two to nine weeks
https://developer.apple.com/help/account/membership/enrolling-in-the-app/ - enrollment through the Apple Developer app needs two-factor, an ID scan and a card
https://developer.apple.com/distribute/app-review/ - Apple reviews 90% of submissions in under 24 hours, Guideline 2.1 App Completeness is over 40% of unresolved issues
https://www.apple.com/legal/app-store/transparency/2025/ - 9,100,620 submissions reviewed and 2,093,244 rejected in 2025, about 23%
https://developer.apple.com/app-store/review/guidelines/ - 3.1.1 bans license keys as an unlock, 3.1.3(b) multiplatform rule, 2.1(a) demo account rule, 2.5.2 remote code, 4.2 repackaged website
https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/ - internal TestFlight needs no review, external needs beta review
https://developer.apple.com/news/upcoming-requirements/ - uploads must use Xcode 26 and the iOS 26 SDK since 2026-04-28
https://www.avanderlee.com/xcode/missing-api-declaration-required-reason-itms-91053/ - ITMS-91053 for a missing privacy manifest, UserDefaults needs reason CA92.1
https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest/ - which APIs need a reason entry
https://developer.apple.com/news/?id=ks775ehf - new 13+, 16+ and 18+ age tiers, frequent contests trigger 13+
https://developer.apple.com/help/app-store-connect/reference/age-ratings-values-and-definitions - leagues count as frequent contests, loot boxes are 13+
https://developer.apple.com/app-store/small-business-program/ - 15% commission, rate starts 15 days after the end of the approval month
https://developer.apple.com/help/app-store-connect/manage-tax-information/provide-tax-information/ - W-9 and banking required before paid apps can pay out
https://developer.apple.com/documentation/storekit/transaction/currententitlements - currentEntitlements returns the latest verified transaction and drops refunded items
https://developer.apple.com/documentation/appstoreservernotifications/notificationtype - ONE_TIME_CHARGE, REFUND, REVOKE notifications
https://developer.apple.com/documentation/storekit/supporting-family-sharing-in-your-app - Family Sharing cannot be turned off once enabled for a product
https://developer.apple.com/app-store/getting-featured/ - App Store featuring needs at least two weeks notice
https://developer.chrome.com/docs/webstore/register - one-time developer registration fee
https://developer.chrome.com/docs/webstore/program-policies/two-step-verification - 2-Step Verification required before publishing
https://developer.chrome.com/docs/webstore/review-process - most reviews take a few days, broad host permissions and new developers take longer
https://groups.google.com/a/chromium.org/g/chromium-extensions/c/VJ6DcpEn51Y/m/yuxvHWdwCAAJ - 2026 backlog, three weeks is the escalation threshold, no expedite, resubmitting resets the queue
https://developer.chrome.com/blog/cws-review-updates-2026 - extended review times and a default limit of two extension slots per new publisher
https://developer.chrome.com/docs/webstore/cws-dashboard-privacy - single purpose, per-permission justification, remote code declaration, data checkboxes, policy URL
https://developer.chrome.com/blog/cws-policy-updates-2026 - Limited Use tightened 2026-08-01, data must be strictly necessary and changes must be disclosed
https://developer.chrome.com/docs/webstore/program-policies/limited-use - the affirmative statement required in the privacy policy
https://developer.chrome.com/docs/webstore/troubleshooting/ - rejection families including missing policy link, unseen features, and free-but-gated listings
https://developer.chrome.com/docs/webstore/cws-dashboard-distribution - Public, Unlisted and Private all get the same review, deferred publishing gives 30 days
https://developer.chrome.com/docs/webstore/discovery - Featured badge is self-nominated through One Stop Support, cannot be paid for, core features must be free
https://habr.com/en/articles/976398/ - one developer reports the Featured badge roughly doubled daily installs
https://groups.google.com/a/chromium.org/g/chromium-extensions/c/XLeZ6iKiuVI - Chrome Web Store payments are dead, third-party checkout only
https://www.revenuecat.com/state-of-subscription-apps - freemium converts a median 2.1% by day 35, low-priced 1.4%, mid 2.0%, high 2.8%
https://www.revenuecat.com/state-of-subscription-apps-2026-education - Education converts 2.2%, only 28.5% of conversions happen on day 0
https://adapty.io/blog/education-app-subscription-benchmarks/ - 23.5% of Education trial starts happen at day 31 or later
https://adapty.io/state-of-in-app-subscriptions/ - first-session paywall sells to about 1.78% of installs
https://dev.to/ktg0215/real-numbers-freemium-chrome-extension-monetization-after-6-months-5hga - 0.8% free-to-paid across five real Chrome extensions
https://www.indiehackers.com/post/what-does-your-install-uninstall-ratio-look-like-f44076717a - 30 to 50% of extension installs uninstall right away
https://www.aboutchromebooks.com/unused-chrome-extension-statistics-2026/ - the average Chrome user installs 8 to 12 extensions and uses 2 to 3
https://www.indiehackers.com/post/we-hit-1-3k-chrome-extension-installs-in-5-weeks-heres-what-actually-moved-the-needle-and-what-was-a-complete-waste-of-time-cebd3e4a5a - 1,300 installs in five weeks, niche threads beat launch posts
https://influencermarketinghub.com/tiktok-influencer-rates/ - nano creators $50 to $200 a video, micro $200 to $800
https://adliftr.com/blog/tiktok-ads-cost-benchmarks-2026 - app-install CPM $12.40 median, utility CPI $4.40
https://ideaequity.ai/blog/cost-per-install-benchmarks-2026 - EdTech iOS CPI $3 to $9 in tier-one markets
https://www.pewresearch.org/internet/2025/12/09/teens-social-media-and-ai-chatbots-2025/ - 21% of US teens use TikTok almost constantly
https://www.tiktok.com/discover/better-canvas-themes - standing discover pages for Canvas theme customization
https://lionsroarnews.com/37673/a-guide-to-a-cuter-better-canvas/showcase/ - BetterCanvas went from thousands to millions of downloads on user-made theme TikToks
https://chromewebstore.google.com/detail/bettercampus-prev-betterc/cndibmoanboadcifjkjbdpjgfedanolh - BetterCampus at 1,000,000+ users, 4.7 stars, offers in-app purchases
https://chromewebstore.google.com/detail/tasks-for-canvas/kabafodfnabokkkddjbnkgbcbmipdlmb - Tasks for Canvas at 400,000 users with a Featured badge, now owned by BetterCampus
https://chromewebstore.google.com/detail/canvas-dark-mode/jbfgmfpakhabhhpefblmehnadjjkadna - Canvas Dark Mode at 50,000 users, no data collected, last updated 2022
https://bettercampus.com/pricing - BetterCampus Pro at $119 a year or $19 a month
https://www.linkedin.com/posts/jaketsilver_a-year-ago-today-bettercampus-made-its-first-activity-7501337328364302336-g7Yv - BetterCampus crossed $1M ARR about a year after starting to charge
https://machronicle.com/bettercampus-temporarily-blocked-students-frustrated/ - Sequoia Union blocked BetterCampus after a September update broke quizzes and logins
https://scotscoop.com/suhsd-blocks-bettercampus-amid-district-wide-security-concerns/ - the block stayed in place on security grounds after phishing incidents
https://support.google.com/chrome/a/answer/6177431 - Google Admin block-all with an allowlist for managed student accounts
https://support.google.com/chrome/a/answer/9031935 - runtime blocked hosts can stop any extension altering a domain
https://community.instructure.com/en/kb/articles/662718-what-are-the-browser-and-computer-requirements-for-instructure-products - Instructure's only line is that extensions may conflict and should be disabled
https://www.instructure.com/policies/canvas-api-policy - no rule on session cookies, multi-user apps must use OAuth for tokens, be independent and do not impersonate
https://www.instructure.com/policies/acceptable-use - access only through publicly supported interfaces
https://en.wikipedia.org/wiki/2026_Canvas_data_breach - the 2026 Canvas breach, roughly 275 million users and 8,809 institutions, confirmed in May 2026
https://fsapartners.ed.gov/knowledge-center/library/electronic-announcements/2026-05-12/technology-security-alert-ongoing-cybersecurity-incident-involving-canvas-learning-management-system-updated-may-29-2026 - the Department of Education told institutions to audit integrations
https://studentprivacy.ed.gov/frequently-asked-questions - FERPA binds schools, not the student reading their own records
https://www.federalregister.gov/documents/2025/04/22/2025-05904/childrens-online-privacy-protection-rule - the amended COPPA rule and its 2026-04-22 compliance date
https://www.scotusblog.com/2026/07/supreme-court-allows-texas-to-enforce-law-requiring-age-verification-and-parental-consent-on-app/ - Texas SB 2420 is enforceable since 2026-07-06
https://oneup.today/tools/reddit-self-promotion-checker - 34% of founder-pitched subreddits ban self-promotion outright
https://redplus.ai/en/r/college/ - r/college bans surveys and personal-gain posts
https://registrar.illinois.edu/fall-2026-academic-calendar/ - Illinois midterm dates, Thanksgiving break 2026-11-21 to 2026-11-29, finals 2026-12-11 to 2026-12-17
https://registrar.utexas.edu/calendars/26-27 - UT Austin fall 2026 calendar, Thanksgiving 2026-11-23 to 2026-11-28, finals in December
https://studentservices.stanford.edu/calendar-events/academic-calendars/stanford-academic-calendar-2026-2027 - Stanford autumn instruction begins 2026-09-22, finals 2026-12-07 to 2026-12-11
https://www.washington.edu/students/reg/begendcal.html - UW autumn begins 2026-09-30, finals 2026-12-12 to 2026-12-18
https://satsuite.collegeboard.org/sat/dates-deadlines - SAT dates 2026-09-12, 2026-10-03, 2026-11-07, 2026-12-05
https://www.instructure.com/press-release/new-instructure-data-shows-k-12-districts-are-demanding-evidence-not-just-access - more than 11 million US K-12 students on Canvas
https://edutechnica.com/2026/06/17/lms-data-spring-2026-updates/ - Canvas holds about half of US and Canada higher-ed enrollments
https://apps.apple.com/us/app/finch-self-care-pet/id1528595748 - Finch keeps core self-care free and sells cosmetics
https://blog.sparrowapps.io/p/finch-how-a-self-care-app-hit-30m-arr-without-vc-money - Finch at roughly $30M ARR on cosmetics, growth led by paid creative
https://apps.apple.com/us/app/focus-friend-by-hank-green/id6742278016 - Focus Friend pricing, bean skins at $2.99 to $5.99
https://www.lennysnewsletter.com/p/how-duolingo-reignited-user-growth - Duolingo's referral program lifted new users by only 3%
https://www.sec.gov/Archives/edgar/data/0001562088/000162828026053299/q2fy26duolingo6-30x26share.htm - Duolingo at 12.7M paid on 140.6M monthly users, about 9%
https://www.inc.com/ben-sherry/he-built-an-ai-app-in-high-school-made-40m-and-sold-to-myfitnesspal-now-hes-aiming-even-bigger/91307748 - Cal AI reached scale by DMing about 150 creators
https://theithacan.org/49642/news/fizz-hires-ic-students-to-market-app-on-campus/ - Fizz paid ambassadors $75 a week and $90 for a three-hour table
https://techcrunch.com/2022/10/04/fizz-app-college-stanford-social/ - Fizz saturated one campus first, with funding behind it
https://extensionpay.com/ - ExtensionPay takes 5% plus Stripe fees and requires the buyer's email
https://docs.stripe.com/api/checkout/sessions/create - Stripe Checkout always collects an email
https://www.paddle.com/pricing - Paddle is 5% plus $0.50 and needs custom pricing under $10
https://www.lemonsqueezy.com/pricing - Lemon Squeezy as merchant of record, the fallback checkout if Apple enrollment stalls past 2026-09-25
https://developer.apple.com/support/storekit-external-entitlement-us/ - Apple's US external purchase link entitlement, the link-out route allowed on the US storefront since the 2025 injunction. Confirm this URL still resolves before relying on it on 2026-09-25
https://developer.apple.com/help/app-store-connect/manage-app-store-promotional-codes/overview-of-promo-codes/ - 100 promotional codes per app per version, with content codes drawn from a separate pool
https://developer.chrome.com/docs/extensions/reference/manifest/web-accessible-resources - matches must cover the origins resources are injected into, and use_dynamic_url stops the resource URL being a stable fingerprint
https://developers.cloudflare.com/web-analytics/ - free click and pageview counts on Cloudflare Pages, which is why the marketing site does not go on GitHub Pages
https://developer.apple.com/help/app-store-connect/view-sales-and-trends/campaign-links/ - App Store Connect campaign links, the only per-channel attribution in the plan

**Claims in this plan with no source.** Each is marked "own estimate, no source" where it appears, and each is listed here so none of them quietly becomes a fact: about 15% of US 16 to 22 year olds are on Android, a zero-rating Chrome listing does 3 to 8 installs a day, free-to-play games see 2 to 5% of active players pay, cold creator outreach closes at 10 to 20%, Fizz raised $41M specifically, Study Together's exact member count, new apps get about a seven-day App Store boost then a cliff, high school semesters end 2026-12-18, Apple review slows from 2026-12-20, and UC quarter campuses start 2026-09-24 to 2026-09-28. The one that matters most is not on this list: the $10.69 against $62.19 pair, which carries the entire price decision, is attributed to the RevenueCat report above and should be re-read at the source before 2026-09-08.
