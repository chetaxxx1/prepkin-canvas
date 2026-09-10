Take Prepkin Plus from a C+ to an A, in this repo (/Users/georgeshi/Desktop/app/prepkin-canvas). Plus is the app's only money. Today it gates one thing, the syllabus scanner, and the sheet is a template. The job is a Plus a college student can justify at $9.99 a month, built the way Finch Plus is built, without breaking the house rules unless George signs the line that breaks them.

Read first, in this order:
1. PRODUCT.md and design/LAUNCH-PLAN.md ("Brand rules, one by one" and "What stays free, forever"). These are the constraints. Everything that ships free today stays free. Coins are never sold. No coin item moves behind money. Accessibility is never behind money. Nothing is ever taken away. No padlocks, no "?" tiles, no countdowns, no "unlock".
2. ios/Sources/Core/Plus.swift, ios/Sources/PlusSheet.swift, ios/PrepkinCanvas.storekit, and the one gate at ios/Sources/CalendarView.swift (grep isPlus). That is all of Plus today. $9.99 a month, $79.99 a year, chosen 2026-09-09.
3. design/CLAUDE-DESIGN-PROMPT-PLUS.md — the sheet brief as it stands. You will rewrite it.
4. design/MARKETING-PLAN.md, the pricing and free-trial sections (search "Free trial" and "BetterCampus Pro is $119"). Note that it still says $19.99 a year and LAUNCH-PLAN.md still sells a $9.99 one-time Lamp. Three documents, three prices. You will leave one.
5. design/FRIENDS-BUILD-PLAN.md and design/FRIENDS-PHASE-1-PROMPT.md, so Plus perks that touch friends (vibe cards, name plate) match what is being built.

Research facts, already checked on 2026-09-10, use them:
- Finch Plus is $9.99 a month or $69.99 a year. It has NO member-only items. It sells speed and slots: an extra reward every day, the micropet on day 20 instead of 25, a daily discounted shop item, more rare-item slots, nine travel options instead of three, all timer durations, all soundscapes, all good-vibe cards, unlimited saved outfit combos, extra reflection prompts. Core self-care stays free and says so on the first line of the benefits page. Nothing is taken away on lapse. People who cannot afford it can enter a monthly Guardians raffle and get a month sponsored, then a hardship price. Source: help.finchcare.com "Benefits of Finch Plus", finch.fandom.com/wiki/Finch_Plus.
- BetterCampus Pro is $19 a month or $119 a year. It gates AI lecture notes and transcription, flashcards and study sets, task planning with Google and Microsoft calendar sync, advanced grade tracking, and unlimited themes; free keeps community themes and a basic to-do list. It hit $1M ARR on 2026-09-03 with 1.5M installs. Source: bettercampus.com/pricing, help.bettercampus.com/changelog.
- How students justify $19: it replaces two or three other subscriptions (Quizlet Plus, an AI notes app, a planner) and it touches grades. Cosmetic themes alone never sold; the money came after the pivot to AI tools and the planner.
- How students refuse it: the most-upvoted post on feedback.bettercampus.com is "im sorry but were literally college students", 30 upvotes: "sometimes I ONLY have 20 dollars to survive off of for the month", "some of these things were FREE", "make it OPTIONAL or a ONE TIME PAYMENT". Every gated-what-was-free change produced a wave of one-star reviews. Lesson: never gate what was free, price under the meal, and give a way out.
- Finch's own reviewers call Plus "largely cosmetic" and say that is fine because it is honest: you pay to customise and to support the developer, not to unlock wellbeing.

Then do these, in order:

A. Use Mobbin (search_screens, platform ios) and look at the images: "Finch Plus benefits sheet with the bird", "Finch Plus paywall yearly monthly", "Duolingo Super paywall mascot", "Quizlet Plus plan sheet", "Headspace subscription warm illustration". Cite mobbin_url for anything borrowed. Take structure and honesty, never the look.

B. Write design/PLUS-SPEC.md. One table, every candidate perk, these columns: perk · what the student gets in one sentence · which app it copies · rule check (free-forever / coins-never-sold / nothing-taken-away / accessibility) with "allowed" or "needs George's signature and why" · size in days · where it hooks in code. Start from this list and cut what fails, do not pad:
   1. Plus coats: a coat line coins cannot buy, on any kin at any stage (the Lamp coat already in LAUNCH-PLAN). Plus scenes: Observatory, Lantern Street, Snow Cabin. The free Night Tank ships first so dark is never paid.
   2. Shop: two more daily pick slots, two hold slots, Plus picks at 30% off instead of 20%, extra rerolls. Finch's slots and discount.
   3. Faster growth, not more coins: star thresholds 25% lower on Plus. This is Finch's day-20 micropet. Present the alternative, an extra daily coin reward, as needing a signature because coins are never sold, and recommend against it.
   4. Learn: Plus reads the whole shelf; free keeps Today's card, Continue, "Because of your week", and one new lesson a day. This takes something away from anyone who has the app today, so it needs a signature AND a grandfather rule: every install before the change keeps every lesson forever, said in one line on the sheet. Say plainly whether you think a one-a-day cap is worth the review risk given the BetterCampus history above.
   5. Focus: 60 and 90 minute shifts and a custom length, focus history with a week graph, ambient sound if audio assets exist (check; if not, say so and drop it).
   6. Calendar: the scanner (exists), whiteboard and planner photos through the same reader, and export to Apple Calendar and Google Calendar via EventKit write. Calendar sync is the single most-cited reason students pay BetterCampus.
   7. Grades: per-course what-if stays free; Plus adds semester GPA projection and a grade goal per course. A tool, not a payment for grades.
   8. Friends: all six vibe cards on Plus, three on free (Finch's split). A small Plus mark on the name plate and friend card, like Finch's Guardian sparkles.
   9. Unlimited saved looks (coat + costume + scene combos), Finch's saved outfits.
   10. A hardship path: "Can't swing it? Ask." opens mail; George sends an App Store promo code for a month. Finch's Guardians raffle, one person at a time.
   Tested and probably rejected, write the reason: gating the home screen widget (it is the daily face, gating it hurts retention), gating dark paper (accessibility), gating any Canvas look already earned with coins, selling coins, any streak or bonus that resets.

C. The argument for $9.99. Write it as the two paragraphs a student reads: what Plus is (more of the fish, more of the shelf, the reader, the calendar export) and what it is not (nothing you have today goes away, coins are never for sale, finishing your work is free). Then a price table with one row each for Finch, BetterCampus, Quizlet Plus, and Prepkin, monthly and yearly. Recommend the yearly price with RevenueCat's price-band figures from LAUNCH-PLAN.md; $79.99 sits above Finch's $69.99 with a smaller perk list, so either the list grows or the price moves, and say which. Then fix the three documents so exactly one price table exists.

D. Entry points, one per tab where it is natural and never a second coral button: Shop, a plain row under the coin racks; Learn, a quiet line under the shelf; Focus, the 60 and 90 chips drawn in full colour with "Plus" beside them; Calendar, the scan row as today; Kin, the Plus coats in the Looks rail at full colour with a price, never a lock. The sheet opens with a reason for each, and the top third swaps per reason.

E. The trial, from MARKETING-PLAN.md: no paywall on day one. After the third finished Canvas task Plus switches on for seven days as a gift, no card, one quiet line. When it ends, the sheet appears once. Draw the timeline the student sees. Never "your trial is ending".

F. Rewrite design/CLAUDE-DESIGN-PROMPT-PLUS.md for the new perk list: the kin on the sheet, the perks as things not bullets, the already-Plus state (never a price to someone who paid), the failed and purchasing states, restore, the legal line, the hardship line. Plain copy, no exclamation marks, no "unlock".

G. Code plan: a single PlusGate enum listing every gate by name, read from PlusEntitlement, with a unit test per gate that asserts the free path still works with the entitlement off. Grandfather flag in GameState with a migration. StoreKit config updated. Server-side receipt check stays the 2026-11-02 item from LAUNCH-PLAN.

What an A looks like when you are done: at least six real perks live, each one a copy of something that already sells for Finch or BetterCampus; not one line of the house rules broken without a signed sentence in PLUS-SPEC.md; a sheet a student can read in five seconds that names what they get and what stays free; one entry point per tab; a gift before an ask; a hardship path; and every price in the repo the same number.

Do not build the perks in this session. Deliver PLUS-SPEC.md, the rewritten design prompt, the price fix across the three documents, the PlusGate skeleton with its tests, and a list of the signatures George owes, one line each.
