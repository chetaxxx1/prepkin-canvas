# Prepkin marketing playbook

Written 2026-09-07. Covers Monday 2026-09-07 through Thursday 2026-12-31.

This is the one plan. It replaces the three drafts and the twelve skeptic passes. Where the drafts
disagreed, the disagreement is settled here and the loser is named in the same paragraph.

---

## Who this is for

**US college undergraduates, 18 to 22, on Canvas, doing coursework on their own laptop in Chrome,
with an iPhone they pay for themselves.** About 8.1M undergrads are on Canvas. Roughly 90% own a
laptop personally and Chrome is 65.5% of US desktop, so about 4.8M can physically install this.
Narrow to traditional college age and about 2.9M are also reachable through studytok, campus
subreddits and student papers. They pay with their own Apple Account. No parent approval, no Ask to
Buy, no card typed into a web form. 85% carry a debit card and 77% of 18 to 29 year olds already pay
for at least one app subscription. Their ceiling is about $10 to $12 a month across every app they
pay for. The price that follows from it is in `design/PLUS-SPEC.md` section 5.

What blocks them: the extension is Chrome only, the paywall sits one hop downstream of the install
behind a pairing step nobody has measured, and a broken Canvas page during midterms ends everything.

**Her Tuesday, 14 October.** Week eight. Psych midterm Thursday, lab report due at 11:59 tonight. She
got back to her room around 8. Laptop open on the Canvas dashboard, the same six grey-blue cards it
has been since August, a To-Do list she scrolls past because two of the four items are things she has
not opened. Her phone is face up next to the trackpad. She has checked TikTok maybe forty times today
and searched something in it twice, because that is where she looks things up now. Last week she saw
someone's Canvas that was pink with a Ghibli background and thought "wait, you can do that" and did
not write it down. She refreshes the grades page, sees the same number, closes the tab, opens it
again eleven minutes later. She submits the lab report at 11:41. Canvas shows a green tick. That is
the whole reward for four hours.

**Runner-up: US high schoolers on Canvas, 4 to 6 million.** They are bigger and louder. They are the
ones who post the Canvas customization videos and sign the petitions. They are not first because they
fail both gates. Their daily machine is a district-managed Chromebook where extensions need admin
approval, and three named districts have already blocked the leading Canvas extension. And only 9.4%
of US teens have ever used a debit card. They stay in the plan as the free tier and the people who
make the videos.

**Say the Chromebook problem out loud, because an earlier draft did not.** A student who cannot
install the extension cannot make the videos and cannot earn coins, because coins pay only for
Canvas-verified finishing. "Everything they touch is free forever" is an empty sentence if she can
touch nothing. Three things fix as much of that as money can fix:

1. **Publish prepkin.app/schools by Wednesday 2026-09-09,** written for a student, not only for a
   newspaper. It carries the extension ID, the exact Canvas pages Prepkin touches, the sentence about
   quiz, submission and editor pages, the Chrome Enterprise allowlist policy name, and copy-paste
   Incident IQ wording she can paste into her own district's ticket form.
2. **Say "install it on your own laptop, not the school Chromebook"** in the Chrome Web Store
   description, on /schools, and in every video aimed at high schoolers. It is the honest instruction
   and it stops a one-star review that says "doesn't work on my school computer."
3. **Hand-entered tasks in the day editor do not pay coins, and that is now written down.** Coins are
   for Canvas-verified finishing only, per PRODUCT.md, and typed-in homework cannot be verified. So a
   Chromebook-locked student gets the phone app, Learn, Focus and the tank she already has, and **no
   coin loop at all.** That is a real hole in the runner-up audience. It is the price of the rule that
   makes coins mean something, and the plan does not pretend otherwise.

**Age, and the two words nobody had written down.** Prepkin is for students **13 and older**, and that
sentence goes in the Chrome Web Store description, the App Store description and first run. Under 13
is out, which keeps COPPA out of the product: Prepkin collects no email, no name, no account and no
age beyond a single self-reported 18-or-over tap. On FERPA, one sentence goes in the privacy policy,
on /schools and in the newspaper pitch: **no student record leaves the browser except the assignment
list and course grades, and they go only to the student's own paired phone.** Prepkin is installed by
the student, not by the school, so it is not a school official under FERPA, and saying so plainly is
cheaper than being asked.

A 16-year-old who does reach the paywall is very likely under Ask to Buy, which means her tap opens a
parent approval on a different phone and usually ends there. That is why the revenue model below
applies the conversion rate only to the self-reported 18-and-over half of app users, not to everyone.

---

## What we learned from the ones that won

| App | First users | The loop that spread it | What we copy | What we cannot copy |
|---|---|---|---|---|
| **Finch** (self-care pet) | 8 versions over 10 months, nobody understood it, launched anyway. Day-2 return was the only good signal. | Monthly seasonal events (43 of them) plus 195,000 people in r/finch posting pictures of their own bird and swapping friend codes. Finch runs none of it. | Nothing is ever taken away on lapse. Plus buys speed and slots, never items. Paywall late, after the pet is named. A gifted preview with no card. "How did you hear about us" in first run. | 610 active Meta ad creatives, a VP of Marketing, a $1M-a-month ad budget, and 2M daily users before the first brand film. |
| **BetterCampus** (was BetterCanvas) | Chrome Web Store search, alone in the category. 1,000 users at 11 months, 10,000 at 25. No viral event, no launch post, no press. | A public gallery of student-made themes with the maker's handle and a live install counter. Then TikTok in 2024 took it from thousands to millions. | The gallery shape, eventually. The complaint list is a free product spec: caps, deleted themes, a forced account, a gated timer. Freeze the skin during school weeks. | Four years of head start and 1M+ installs before the gallery mattered. Their gallery is a retention mechanic sitting on an install base we do not have. |
| **Turbo AI** | Two dropouts posted 40+ TikToks on a $300 budget. One hit millions. | Founder short video at volume, then 100M views before a dollar of paid spend. | Post volume, judge at day 10, one hook shot five ways. | They sold a phone app to a person holding a phone. We sell a laptop extension to the same person. Their install was two taps. Ours is a device switch. |
| **Cal AI** | 500 cold DMs to nano creators on Instagram, about 1 reply in 100. | 150+ creators on monthly retainer at a $2 to $3 CPM, product on screen in the first 15 seconds, app name never spoken, pinned comment does the naming. | Creator sourcing (train a burner feed, log handles), the brief rules, reposting every creator video, timestamps laid over the install curve. | 150 retainers and an eight-figure run rate. We can afford six videos. |
| **Momentum** (Chrome extension) | One honest comment in an r/productivity thread. 0 to 100,000 users in four months. Founder says they were never featured in the store. | A blog in India, one in Norway, then CNET. | Disclosed comments in standing "what study apps are you using" threads, never a launch post. | 2015-era Reddit. Today 39% of the relevant subreddits ban self-promotion outright. Treat it as a lottery ticket, not a channel. |
| **Focus Friend** | Hank and John Green posted it to a 17-year audience. #1 in the US within days. | None identified. The audience was the distribution. | The price ladder ($3.99 monthly, $19.99 annual), the second earned currency shape, no login at all, and "we do not sell your data" as the reason to pay. | The audience. This is not a playbook, it is a story about already having millions of followers. |
| **tbh and Gas** | One private Instagram per school, follow students who list it in their bio, flip public at 4pm. 5M and 10M users on $0. | Anonymous compliments only work if your classmates are on it. The school WAS the product. | Nothing. See "What we are not doing". | A network effect. A Canvas skin works perfectly with zero classmates, so the tease has nothing behind it. Also, an account named for a university you have no relationship with is impersonation. |
| **Fizz** | Free doughnuts, dorm pamphlets, .edu gating, about 15 paid moderators per campus. 95% of Stanford undergrads. | Campus density. | One campus at a time, with a written trigger before spreading. | About $500 a month per campus in moderators. One ambassador for a semester is a quarter of our entire budget. |

**The single most transferable move is Finch's lapse promise.** Every other winner had something we do
not have: an audience, a head start, a network effect, or a budget. Finch's decision that nothing is
ever member-only and nothing is removed when you stop paying costs nothing to copy, is already
George's written brand rule, and it is the direct answer to the loudest complaint against the
incumbent, whose own users write "I had over a years worth of my own themes, all gone." Put that
sentence on the paywall screen, not in the terms.

---

## Prepkin Plus

**Name:** Prepkin Plus.

**Price: see `design/PLUS-SPEC.md` section 5. That is the only price table in this repo, and this
document names no numbers of its own.**

The $3.99 / $19.99 ladder argued for here until 2026-09-10 is dead. It was read off Focus Friend,
which is the closest living comparable by audience and shape. It loses to the RevenueCat price-band
figures written up in `LAUNCH-PLAN.md`: low-priced apps convert *worse* (1.4% against 2.0%) and
return about a fifth of the year-one value per payer ($10.69 against $62.19). Monthly is now $9.99.
The yearly number and the argument for it are in `PLUS-SPEC.md` section 5, together with the
Finch / BetterCampus / Quizlet comparison. The lifetime tier stays dropped, for the reason it was
always dropped: at any price under about $100 it is worth more than the subscription it replaces,
which contradicts the whole reason we chose a subscription.

**The perk list in this section is also superseded.** `PLUS-SPEC.md` section 2 is the live list:
eight perks, seven of them a direct copy of something Finch or BetterCampus already charges for.
The free-forever list below and the lapse promise below both survive unchanged and are quoted into
that spec.

**Free trial.** No paywall on day one. When a student has finished her third Canvas assignment, Plus
switches on for seven days as a gift. No card, no charge, nothing to cancel, one quiet line when it
starts. When those seven days end, the paywall appears once, four screens: seven days free, then we
will remind you two days before it ends, then the price, then the offer details with a plain timeline
showing today, reminder day and charge day.

**Seven days is chosen for time in the product, not from a conversion benchmark.** An earlier draft
justified it with the published 37.4% seven-day trial rate. That number is wrong for this product:
it measures card-on-file trials that auto-charge unless the student cancels. Prepkin's preview is a
gift with no card attached, so nothing can auto-charge and that benchmark does not apply at all.
Seven days is chosen because it spans one full assignment week, which is the smallest window in which
a student sees the faster coin rate do anything. The real funnel here is three steps, and it is
**preview ends, the paywall is shown, she taps to buy with a card she has to enter on purpose.**
There is no published rate for that shape. It is marked invented in the rates table below, alongside
the other two.

This is the one place we changed Finch's shape on purpose. Finch shows a paywall on day zero and
gifts a preview on day three, which teaches the student that saying no is rewarded. We sequence them:
gift first, ask second, and the ask lands on a person who has just spent a week inside Plus.

**Free forever, and this list never shrinks:**

- All 26 looks and every image theme, and every look a student makes once the editor ships.
- The Receipt page and the one-click put-back.
- Every Focus timer length, including 45 minutes.
- Grades, the GPA calculator, due-next, the buddy panel, the whole Canvas extension.
- Coins earned from Canvas-verified finishes, and every costume, coat, colour and scene those coins
  buy. Every one of them. There is no shelf coins cannot reach.
- All 54 Learn lessons, Friends, leagues, pairing with no account, no email and no password.
- Dark mode, contrast and reduce-motion.
- The entire experience for high schoolers, said in those words on the pricing page.

**What Plus adds.** Speed, slots and convenience. Nothing else. Six things were on this list in an
earlier draft and **five of them had no build item on any dated week.** Selling a thing that does not
exist is the fastest route to a one-star review and a 3.1.2 rejection, so every line below now names
the week it is built, and one line was cut outright.

**Shipping with the paywall on 2026-10-19:**

- **The shop refreshes three times a day instead of once, with one discounted costume every day.**
  Built week 2026-10-05. Small: the shop roll already exists, this changes a timer and adds a price
  multiplier.
- **Coins arrive faster from the same finished work.** Built week 2026-10-05. Small: one multiplier
  on the existing award.
- **Unlimited saved combinations of coat, colour, costume and scene.** Built week 2026-10-12. Medium,
  because **there is no saved-combination feature in the app today** and the free version has to ship
  first. Free cap is **three saved combinations**, stated as a number on the paywall.

**Added to the paywall copy on 2026-11-30, after two events have actually run:**

- **One extra reward during the monthly event, and the event pet at 20 finished assignments instead
  of 25.** The mechanic is built week 2026-10-26 with the first event. It is not sold until 11-30,
  because a student cannot judge "one extra event reward" for a thing she has never seen.
- **The new Learn figure themes and the new Focus timer sounds that ship with each monthly event.**
  Built weeks 2026-10-26 and 2026-11-30 with the events. Read that wording exactly: it is **new** art
  and **new** sounds, shipped from the event forward. **Every Learn figure style and every timer sound
  that shipped before the paywall stays free forever,** including everything in LessonFigures.swift
  today. An earlier draft said "every Learn figure theme and every Focus timer sound", which would
  have moved free things behind Plus and broken the promise printed one paragraph above it.

**Cut, and not coming back this year:**

- **A custom emoji on any Canvas task.** It lived in the Chrome extension, and the extension has no
  way to know she is a Plus member. The entitlement rides the Apple ID with no server, and the
  extension has no Apple ID. Carrying a `plus:true` flag across the pairing record is real work
  nobody scheduled, and it hands Apple a 3.1.3(b) argument about what a purchase unlocks outside the
  app that we do not need to have on a first submission. Dropped, so **every Plus benefit lives
  inside the iOS app, where the entitlement already is.**

**The event pet never expires, and that goes in the paywall copy.** Event progress carries forever.
If a free student is at 22 of 25 on 30 November, she is at 22 of 25 on 1 December and in March. The
pet is claimable the moment she reaches the count, this month or next year. Plus buys 20 instead of
25, which is speed, not a deadline. This sentence exists because "monthly event" implies a month
boundary and the plan had no written answer.

**What happens when it lapses.** This goes on the paywall screen itself, in the App Store
description, and in PRODUCT.md:

- You keep your fish.
- You keep every coat, colour, costume and scene you earned.
- You keep every coin.
- You keep every saved combination. Every combination you already saved stays applicable forever,
  including the ones above the free cap of three. Only saving a **new** fourth one stops.
- You keep every look you made and every look you applied.
- You keep every figure style, every timer sound and every event pet you ever had.
- The shop goes back to refreshing once a day, and coins go back to the normal rate.
- That is the whole difference. There are no member-only items in Prepkin.

**The rule behind all of it goes into PRODUCT.md as a code-review gate, this week:** *nothing that has
ever shipped free may move behind Plus, in any release, for any reason.* A reviewer who sees a diff
that gates an existing free thing rejects it without discussion. Two other sentences were already
queued for PRODUCT.md on Friday. This is the third and it is the one that matters most, because it is
the only promise here that a future release can quietly break.

**Where this maps to Finch, and where it does not.** Copied: the lapse promise, near word for word
from Finch's own wiki. Plus as speed and slots. The daily discounted shop item. Extra saved combos.
Custom emoji. The extra event reward and the earlier event pet. The gifted preview with no card. The
paywall placed late, after the fish exists and is named. The four-screen paywall order. The "how did
you hear about Prepkin" screen. A free three-months code for anyone who says they cannot afford it.
Finch's custom emoji is **not** copied, because ours would have had to live in the extension.

Deliberately different, and each one is a fix a skeptic forced:

- **Price matches Finch's, and is a third of BetterCampus's.** See `PLUS-SPEC.md` section 5. An
  earlier draft here priced at 29% of Finch's annual on the argument that Finch sells to employed
  women aged 25 to 35 while we sell to broke sophomores. That argument lost to the price-band
  data; the answer to broke sophomores is the hardship path, not a price nobody can build against.
- **No second currency.** An earlier draft added "pearls" that bought a shelf coins could never
  reach. That is a member-only shelf, which contradicts the sentence printed one paragraph above it.
  Dropped.
- **No loyalty discount ladder.** Finch drops the price at 25, 50, 75 and 100 days. Ours would have
  needed a signing server we said we would not build, would have shown a progress meter the brand
  rules ban, and would have taught the best users to wait. Replaced with free Apple offer codes.
- **No streaks and no dimming tank.** Finch points streaks at the bird's energy bar. Ours would still
  be a meter that falls. Instead the tank only accretes: each verified finish adds a permanent plant,
  rock or coral. An idle week adds nothing and removes nothing.
- **The monthly event counts finished work, not days.** Chest four opens at your fourth finished
  assignment this month, whenever that lands, and it waits. No daily calendar, nothing expires.
- **No gift subscriptions in 2026.** Finch sells a year on a Stripe page redeemed by friend code. The
  rule here is contested and a first-time developer account is the wrong place to test it. Revisit in
  spring as a non-consumable in-app purchase.
- **Family Sharing stays off.** Turning it on is the irreversible direction, one yearly plan would cover six
  people, and the target user lives with five roommates. Switch it on later if we ever want it.

**Apple rules that apply, and they are not optional:**

- Guideline 3.1.2. Four things must be on the paywall screen inside the app: the subscription title,
  its length, the price and the price per period, and tappable links to the privacy policy and the
  Terms of Use. Missing one is the most common first-submission rejection and costs a full review
  cycle we cannot spare in October.
- Guideline 3.1.3(b). A purchase made in the iOS app may unlock things in the Chrome extension. The
  reverse is not allowed. Nothing bought outside the app may unlock anything inside it.
- Guideline 3.1.1. Purchased currency may not expire, and there must be a restore path.
- Guideline 1.2. If any user-published content or a public handle ships, the app needs a content
  filter, an in-app report button, a way to block a user, and published contact details, before
  submission. This is one of the reasons the public gallery is deferred.
- Small Business Program: apply the day the developer account activates. The 15% rate starts 15 days
  after the end of the month the enrolment is approved, so a late-September approval means the rate
  is live from about mid-October.
- Billing grace period: set 16 days in App Store Connect and treat `inGracePeriod` exactly like
  `subscribed` in code. A card that bounces in October must not cost a student anything.
- Entitlement: plain StoreKit 2. Check `Transaction.currentEntitlements` at launch, hold a
  `Transaction.updates` listener, call `finish()` every time. No accounts, no server. The entitlement
  rides the Apple ID, which is how "works on all your devices" is satisfied with zero login.

---

## The loop

**The loop is a picture the product makes of her fish, plus a six-character code that hands someone
her exact look.**

The earlier drafts made the loop a public gallery of student-made Canvas themes, copying
BetterCampus. That is refuted for 2026 for three reasons, and this is the biggest change in the plan.
First, there is no theme editor in the extension. The looks catalogue is fixed and ships inside the
build, so there is nothing for a student to author and nothing that is "hers" to show off. Second,
uploading a student's authored content and handle means the Chrome data declaration and the privacy
story change, and the privacy story is the strongest thing we have. Third, BetterCampus's gallery
became growth only after they had hundreds of thousands of installs. On a base of two thousand it is
a page showing "11 installs", which is a demotivator. Runner-up: the full public gallery, which moves
to January with a real editor, real moderation and a truthful declaration.

**What ships instead, and when:**

1. **A look code, by Saturday 2026-09-12. Palette only, not the accessory.** Six characters that
   select one of the 26 shipped theme palettes. She pastes it in a comment. Someone types it in the
   popup and has her exact colours in one tap. No upload, no server, no account, and the extension
   stays local. The code deliberately does **not** carry the accessory, because looks.js says in its
   own header that the four accessories are provisional art awaiting George's sign-off, and they are
   drawn in the slime's coordinate space, so they have to be redrawn after the Sprout port anyway.
   Shipping a share mechanic on top of unapproved art breaks the standing rule that new mascot art
   gets a sign-off first. The accessory joins the code after the Sprout port and its own sign-off
   round.
2. **The Look Card, from the extension popup, in this week (by Saturday 2026-09-12).** One tap renders
   a 1080x1350 image of her real themed dashboard, big and clean, with the six-character look code as
   a small caption. Course names are blanked by default, because her dashboard is her course list and
   no student posts that. **This is the only share unit that works at zero scale,** because it is an
   image posted into a feed and needs no other users. An earlier draft had nothing for a student to
   post for the first five weeks of a daily video cadence. This closes that hole.
3. **The Tank Card, in the phone app, by Monday 2026-10-12.** The fish version of the same thing: her
   fish, the costume she chose, the scene she chose, her count of finished assignments, and the look
   code at the bottom. The prompt to share it appears only after she has put a first costume on the
   fish, so the card always shows something she picked. It ships on 10-12 because that is after the
   Sprout port, and there is no point rendering a card of a mascot the extension does not draw.
4. **The first costume free at the first finish**, so a week-one student has something to wear and
   something to post.
5. **The pairing code doubles as a friend code**, with one weekly swap thread from the day the app is
   live. r/finch grew 45% in a year on threads whose first rule is "post your code first," and Finch
   neither runs nor pays for it.

Two promises go in PRODUCT.md and the store listing on day one: **a look you make is yours and never
leaves your extension**, and there is **no cap, ever, on applying, swapping or saving looks.**

---

## Channels, ranked

Every install number in this table is now **derived**, not asserted. The previous version stated a
0.15% view-to-install rate and then never used it once, and nine numbers were written down that no
arithmetic produced. The total fell from 1,800 to 760 when the arithmetic was actually done.

| # | Channel | Assumed views or impressions | Rate applied | Installs by 2026-12-31 | Cost | Hours a week | Precedent |
|---|---|---|---|---|---|---|---|
| 1 | Chrome Web Store listing and search | not view-based. Store rank, which compounds with review count | n/a | 120 | $5 | 1 | BetterCanvas: ~400 a month, but on years of rank and thousands of reviews |
| 2 | Prepkin short video (TikTok, then Shorts) | 100,000 across ~80 posts, a 1,250 median post from a zero-follower account | 0.15% | 150 | $0 | 8 | Turbo AI: 40 posts on $300, no audience |
| 3 | Paid nano creators, 6 videos | 18,000, at 3,000 a video from creators under 20,000 followers | 0.15% | 27 | $720 | 3 | Cal AI: creators at a $2 to $3 CPM |
| 4 | One campus, footage first | 100 stickers handed out at two shoots | 1.5% scan to install | 20 | $490 | 2 | Fizz at Stanford, discounted hard |
| 5 | Student newspapers, 40 emails | 3 to 5 pieces run, about 30,000 student readers | 0.15% | 40 | $0 | 1 | Five papers covered BetterCanvas, but that was a district-block news story |
| 6 | Reddit, disclosed comments only | about 60,000 thread impressions over the quarter | 0.2%, because the reader is already on a laptop | 120 | $0 | 1 | Momentum: one r/productivity comment |
| 7 | Pinterest and Lemon8 | about 65,000 impressions on 26 pins plus one walkthrough | 0.15% | 100 | $0 | 1 | Every Canvas tutorial sends students to Pinterest |
| 8 | Look Cards, Tank Cards and look codes | no view base. It scales with the installed base, not with posting | **invented** | 80 | $0 | 1 | BetterCampus's gallery, at 1/1000 of the scale |
| 9 | Spark Ads, held back | about 130,000 paid views on $400 | 0.08%, because paid views convert worse than earned | 100 | $400 | 1 | Only spent if one organic post clears 50,000 views |
| | **Base case total** | | | **760** | **$1,615** | **19** | |

Three things about this table. The rate is low on purpose: every video channel asks a person watching
on a phone to walk to a laptop, open Chrome and search a brand name she heard once. The comparables
all sold phone apps to people holding phones. The hours are real: 19 a week of marketing on top of
building the app. And when a week goes wrong, cut in this order: Pinterest, campus, Reddit, Spark
Ads. Never cut the Sunday shoot, the store listing, or the code freezes.

**Channel 2 is a lottery ticket bought with 8 hours a week.** The base case of 150 assumes a 1,250
median post, which is what a new zero-follower account actually gets. The 400 in the old plan needed
267,000 views, or a 3,333 median post, which a new account does not have. The breakout case, worth
1,200 installs, needs about 800,000 views and happens to roughly 3% of videos in this genre. Buy the
ticket, because it costs money nobody has to spend. Do not budget the prize.

### 1. Chrome Web Store listing and search

**120 installs, not 400, and loaded into November and December.** The 400 came from BetterCanvas,
which was alone in its category with years of accumulated rank and thousands of reviews. A listing
published in September with zero reviews does not rank for "canvas theme" for its first several
weeks. **The store channel compounds with review count,** which is why the push to 25 reviews in the
week of 2026-11-16 is an acquisition task, not a reputation task, and should be read that way in the
week plan.

1. Host the privacy policy at prepkin.app/privacy today, then fill the Chrome data declaration.
   Here is the answer, so nobody has to stop and decide it on Tuesday. **Tick: Website content**
   (Canvas assignment titles, due dates and course grades) **and User activity** (which assignments
   she marked finished). **Do not tick** personally identifiable information, financial and payment
   information, authentication information, personal communications, location, health, or web
   history. Certify **all three** limited-use statements: the data is used only for the single
   purpose the listing describes, it is not sold, and it is not used for creditworthiness or lending.
   Link prepkin.app/privacy in the privacy-policy field. "No data collected" is not true here and a
   false declaration is a removal offence, not a warning.
2. Then say the stronger true thing in the description: **one list, to one place, that only your phone
   can open. No email, no password, no account.**
3. Name it **Prepkin: Themes and Dark Mode for Canvas**. Keyword-first, but do not lead with the
   trademark. BetterCanvas renamed itself BetterCampus, and the likeliest reason is trademark
   pressure. No Instructure logo, no Canvas colours, no "Canvas" as the first word.
4. **Narrow the host permissions before Tuesday's submit, not after.** The shipped manifest asks for
   `optional_host_permissions` of `https://*/*`. A broad all-sites request from a first-time
   publisher is the single biggest driver of a long Chrome review and of the "why does it want all my
   sites" one-star, and it flatly undercuts "reads nothing it doesn't need", which is the strongest
   thing we have. Default to `*://*.instructure.com/*`, and request the student's self-hosted Canvas
   host through `chrome.permissions.request` at the moment she adds that school. Do it **before**
   the 2026-09-08 submit: a permission change after publication triggers a fresh review.
5. First screenshot is a themed dashboard. Second is the Receipt page. Third is the put-back. Put
   three sentences in the description: **"does nothing on quiz, submission or editor pages"**,
   **"for students 13 and older"**, and **"install it on your own laptop, not a school-managed
   Chromebook"**. Submit Tuesday 2026-09-08, and assume five to ten business days for a first-time
   publisher, not three.

### 2. Prepkin short video

1. Open **@prepkin as a TikTok Business account** today, not a personal one. A business account gets a
   clickable bio link at zero followers instead of at 1,000. The cost is being limited to the
   Commercial Music Library, which does not matter for a screen recording, and off-niche audio wrecks
   follow conversion anyway. Claim the same handle on YouTube.
2. Point the bio link at **prepkin.app/get**, which holds two things: a QR code and the words to type.
   The QR is the whole point. It is the only way the phone viewer's install survives the walk to the
   laptop, because scanning it on her phone puts the store listing in the Chrome account that syncs to
   her Mac.
3. **Create the nine short links today, on Dub.co's free tier.** Attribution has no budget line and
   no named tool anywhere in the old plan, which means two of the three tripwires could not have been
   read. All nine redirect to prepkin.app/get. The slugs are fixed, and every channel task below names
   its own: **/s-store, /s-video, /s-creator, /s-campus, /s-paper, /s-reddit, /s-pin, /s-card,
   /s-ads**. Cost is $0. A Cloudflare Worker on prepkin.app does the same job for $0 if Dub's free
   tier changes.
4. Screen-record five raw takes on real Canvas data on Friday 2026-09-11: a theme reveal, the Receipt
   scroll, the put-back, a coin landing after a submission, a 25-minute Focus timer. Those five takes
   cut into the first twelve videos.

### 3. Paid nano creators, 6 videos

1. Build a burner TikTok account on 2026-09-08 and do nothing but watch and like studytok and
   aesthetic-Canvas videos for two days, until the For You page is a creator list. Log every handle
   under 20,000 followers with its typical view count in a sheet.
2. Send the DMs **from Instagram, not TikTok**, from an account with two weeks of posts on it, capped
   at 25 a day. Cal AI's bulk DMs were on Instagram; a fresh TikTok account cannot send at volume and
   gets action-blocked trying. **25 a day for six weeks is about 900 sends, and that is what it takes
   to sign four to six.** The old plan budgeted 500 sends over three weeks: at the published reply
   rate of one in a hundred that is five replies, and a reply is not a signed creator. 900 sends is
   the number that actually sources the six videos the $720 already pays for.
3. **The reason to pay creators is footage rights and Spark Ads whitelisting, not organic reach.**
   Six videos at 3,000 views each is 18,000 views and about 27 installs. Nobody should buy 27 installs
   for $720. What $720 buys is six whitelisted assets that the $400 ad budget can run from a real
   creator handle, plus six pieces of usable footage, and that is a defensible purchase. Judge this
   channel on assets, not installs.
4. Offer $120 a video and ask for Spark Ads whitelisting rights in the first message, at about +30%.
   Fix exactly two things in the brief: the themed Canvas is on screen in the first two seconds, and
   the call to action is "scan this, it's a Chrome thing." Voice, sound and edit are theirs. `#ad`
   goes inside the video in the first second and at the top of the caption, never after the hashtags.
   Every creator's pinned comment carries **/s-creator**.

### 4. One campus, footage first

**The school is UCF. It is picked, in the plan, so nobody has to stop and choose on Thursday.** The
old draft offered Arizona State, UCF or Texas A&M and never decided, which meant the Thursday task
could not start. UCF wins on this plan's own criteria: about 69,000 undergraduates, Canvas, a live
daily student paper in Nikki, and an active r/ucf. Dartmouth was in an even earlier draft because
George already has its Canvas test data, which is a reason about convenience, not about market.

**And this channel is now a footage line, not an acquisition line.** The old plan credited 200
installs to 500 stickers and 200 flyers. That is a 28% conversion on printed matter. Real sticker and
flyer QR scan-to-install rates run 1 to 2%, which is about 10 installs, and $650 for 10 to 20 installs
is $32 to $65 each, by far the worst line in the plan. What the plan genuinely needs from a campus rep
is the thing it cannot make remotely: **the two-second face shots, the hands, and the campus b-roll**
that every hook convention below depends on. So the rep stays and the print run mostly goes.

1. Hire one UCF student rep at $75 a week for six weeks, $450, through the UCF job board or a class
   GroupMe. **Post the listing at UCF on Thursday 2026-09-10.**
2. The rep's job is footage. Two 40-minute batched sessions give a full quarter of video openers:
   face, hands, walking, laptop-on-a-desk, library, the walk between classes. Everything posts from
   **@prepkin**.
3. Order **100 die-cut QR stickers, about $40**, not 500 stickers and 200 flyers. The rep hands them
   out at the two shoots. Expect **15 to 25 installs** from them and do not plan around it. The QR
   points at **/s-campus**.
4. Do not make a school-named Instagram account. Make a school-colour look pack, name it after the
   town not the college, and let the rep drop the look code in class GroupMes.

### 5. Student newspapers

**30 to 50 installs, not 150, and a different ask.** The five papers that covered BetterCanvas
unprompted were covering a district blocking an extension that thousands of their own students had
already installed. That is a news event about an installed base. "New extension launches, made by one
guy" is not a story, and a student editor will not run it.

1. Build a list of 40 papers, starting with the five that have already covered this beat: The Lion's
   Roar, M-A Chronicle, Woodside Paw Print, Scot Scoop, BVSW News. Add 35 college papers at big Canvas
   schools, Nikki at UCF first.
2. **Pitch the service piece, not the launch.** The publishable angle is the IT note: what a Canvas
   extension is actually allowed to touch, what your district can see, and exactly how a student files
   an allowlist request. That is a piece an editor runs because it helps her readers. Prepkin is the
   example inside it, not the headline. Never name a competitor, never mention broken quizzes.
3. Attach the one-page "For your school's IT" note and link **prepkin.app/schools**: the extension ID,
   the exact Canvas pages Prepkin touches, the sentence about quiz and editor pages, the FERPA
   sentence, and the copy-paste Incident IQ wording. Two images: the Receipt page and a themed
   dashboard. Link **/s-paper**. Send all 40 on 2026-09-10 and follow up once on 2026-09-24.

### 6. Reddit

1. On 2026-09-08, read the written self-promotion rules of r/college, r/GetStudying, r/SideProject and
   ten campus subs and write down which allow a disclosed comment. 39% of the subs founders pitch ban
   it outright, including r/productivity.
2. Answer the standing "what focus or study apps are you using" threads with **"I built this"** as the
   first three words, not the last. One account, real name, no second account ever.
3. Search "canvas dark mode" and "my canvas is ugly" weekly and answer with real help, mentioning
   Prepkin only when it is the answer. Links are **/s-reddit**. This is quietly the best-converting channel in the plan,
   because the reader is already on a laptop. Never post a launch thread.

### 7. Pinterest and Lemon8

1. Open a Pinterest business account on 2026-09-09, claim prepkin.app, and publish **26 pins, one per
   look**, each with the palette hex codes printed on the image and **/s-pin** on the pin. There are
   26 looks in themes.js, not 20. Every count in the old plan was wrong by six.
2. Title them the way students already search: "aesthetic canvas dashboard", "canvas dark mode",
   "pastel canvas theme hex codes", "deep sea canvas dashboard".
3. Write the Lemon8 walkthrough with the same structure as the May 2026 posts that already rank in
   web search, and delete step three. Every one of those tutorials says "open Pinterest and find
   aesthetic photos." Prepkin ships the images, so our tutorial is a step shorter than theirs.

### 8. Look Cards, Tank Cards and look codes

1. Ship the six-character look code **and the 1080x1350 Look Card in the extension popup** by
   2026-09-12, and the Tank Card in the app by 2026-10-12. Link **/s-card**.
2. Start a weekly friend-code and look-code swap thread the week the app is live.
3. Repost the best student Tank Card every week with credit, and reply to it with a video.

### 9. Spark Ads

1. Spend nothing until one organic post, ours or a creator's, clears **50,000 views**.
2. When one does, Spark-Ad that exact post from the creator's own handle, US only, ages 18 to 24, $400
   over 10 to 14 days. Link **/s-ads**.
3. If nothing clears 50,000 by 2026-11-08, keep the money and put it into two more creator videos.
   Creator retainers buy five to eight times more views per dollar than boosting unproven creative.

---

## The content engine

**Cadence.** One post a day, six days a week, from 2026-09-14 to 2026-12-19. Dark 2026-11-25 to
2026-11-28 and after 2026-12-20. That is about 80 posts. An earlier draft called for two a day and
150 posts, which is where the plan silently dies in week three. Eighty made well beats 150 made
badly, and the thing that must never die is the daily reply video.

**Publish 6pm to 9pm Eastern, 8pm is the target. Judge every video at day 10, never day 1.** 96% of a
post's reach and 98% of its interactions land inside ten days.

**Two platforms, two jobs. TikTok is reach and comments.** 16.47% of TikTok accounts still moved up a
follower tier last year, the best of any platform, and the For You feed is 72.7% of views. **YouTube
Shorts is the archive.** 74% of Shorts views come from non-subscribers, the penalty for not showing a
face is smallest there, and a Short stays searchable on Google forever while a TikTok is spent in ten
days. Same file, both places, same day. **Instagram Reels is dropped for 2026:** reach fell 35% and
only 21% of accounts under 10,000 followers grew.

**How a week gets made in one sitting.** Sunday afternoon, three hours.

- George screen-records on the real Canvas sandbox: whichever of the five raw takes changed this
  week, plus the four things comments asked for. That is about 60 minutes.
- HyperFrames does the rest: cuts each take to 21 to 34 seconds, burns the captions in, renders the
  plain-text meme cards and the checklist graphics from one script, and exports the same vertical file
  for both platforms. That is where the volume comes from cheaply.
- The campus rep supplies the two-second face and hands shots, batched once a month, and the campus
  b-roll.
- Monday morning, queue the week. Monday to Saturday, ten minutes a day goes to one reply video.

**Hook conventions, and these are not up for debate.**

- The finished themed Canvas is on screen inside 1.5 seconds. "Product or outcome showcase" is the
  top hook type across 34,635 clips and the algorithm makes its first call at about 1.5 seconds.
- Two seconds of a face or a pair of hands, then cut to the screen. Face on camera earns 2.4 times
  the median views on TikTok, and the teacher-style hook has the smallest gap, so two seconds buys
  most of the premium without turning George into a talking-head creator.
- Never open with a greeting.
- 21 to 34 seconds by default. 11 to 18 when the point is one reveal.
- One message, five formats. The sentence is: **"If your Canvas dashboard makes you close the tab, we
  made a free thing for that."** Shoot it as a screen recording, a plain-text card, a five-item
  checklist graphic, a phone-in-hand photo, and a talking head. Finch's longest-running ad has been
  live unbroken for 180 days as one sentence in four formats. The format competes, the message does
  not change.
- Never name a specific thing the student has failed to do. Finch names shame-adjacent behaviour
  because it is a mental-health brand talking to adults about self-compassion. Prepkin telling a
  19-year-old she has four unopened assignments is scolding said kindly, and the brand rules ban it.
  Point the specifics at the page, not at her.

**Captions.** Three to seven word chunks, white with a black outline, upper-centre, clear of the
button zone. About 60% of TikTok is watched with the sound off, so the on-screen text is the video.
Every caption ends with a question, because posts with a question take 26.19% more comments, and the
comments are next week's videos.

**Sounds.** The Business account limits us to the Commercial Music Library. Use quiet lofi under
tutorials and nothing at all under reveals. Off-niche trending audio produces high views and terrible
follow conversion, so it is not worth the trade even if we could use it.

**How the app is credited.** Three places, every time. The word Prepkin in the on-screen text. A
pinned comment with the exact words to search and the **/s-video** QR link. And the spoken line is
never the brand name alone, it is **"search themes for Canvas in the Chrome store, the one with the
Receipt."** An invented word with no meaning does not survive the walk to the laptop; the category
phrase does, and it matches the store listing name.

**"It's the fish one" is cut until the Sprout port lands.** The shipped extension does not draw
Sprout. `extension/content.js` draws the slime, from `slimeSVG()` at line 202, called at lines 885,
890, 897, 957, 993, 1033 and 1046, and `popup.html` still has `id="slime"`. A viewer who searched for
"the fish one", installed it, and found a slime is a person who was lied to in the first five seconds.
**The Receipt and the put-back are the hero until the port ships.** They are also the better hook:
they are the thing no competitor has and the thing the privacy story is built on.

**The workhorse.** Reply to comments with videos. Four of the five highest-engagement Canvas videos in
this whole genre open with "Replying to @___". TikTok stamps the comment on screen as a sticker, so
the question is the hook and the audience picked the topic. The comment section is the content
calendar, which is why the account does not run out of ideas in week three.

**The kill rule for this channel is a number, not a feeling.** In week three, on **2026-10-04**,
divide installs on /s-video by total views across every post and read it per 10,000 views. **If it is
under 0.1%: under 10 installs per 10,000 views. Stop making original hooks and run only reply
videos.** Reply videos cost ten minutes and the audience picks the topic, so they are the cheapest
thing left. The old plan judged each video at day 10 and checked a total install count, and never set
an installs-per-view floor, so the channel could have burned 8 hours a week for a quarter without ever
failing a written test.

**Attribution.** There is no analytics budget and the extension makes no external requests it does not
need. Two sources only. **The nine Dub.co short links created in the 2026-09-07 week.** /s-store,
/s-video, /s-creator, /s-campus, /s-paper, /s-reddit, /s-pin, /s-card, /s-ads: all redirecting to
prepkin.app/get, which redirects to the store listing. And the "how did you hear about Prepkin" screen
in first run, which Finch puts at step 38 for exactly this reason. Without those nine links the
2026-10-04 install split and the 2026-11-08 campus trigger cannot be read at all. Keep a spreadsheet
of every post timestamp and lay it over the Chrome install curve, but do not trust it below about 100
installs a day, because the daily noise is bigger than any single video.

### The videos

**Four videos are held, not written off.** Videos about the fish inside the extension cannot be shot
until Sprout replaces the slime in `content.js` and `popup.html`. They are listed at the bottom and
come back the week the port lands.

1. **Before and after.** "My Canvas looked like this. Now it looks like this." Screen recording, cut
   on the reveal at 1.5 seconds, 14 seconds, no talking.
2. **The Receipt.** "Every single thing this extension changed on my Canvas, listed." Slow scroll of
   the Receipt page, 22 seconds. **This is the hero video now.**
3. **The put-back.** "One click and my school's Canvas goes back to normal." One button press, 8
   seconds. **Second hero.**
4. **No dark mode.** "Canvas still has no dark mode in 2026. I fixed it." Toggle on a night-time
   dashboard, 12 seconds.
5. **Ranking.** "Rating all 26 Canvas looks, worst to best." One second each, fast cuts, best one
   last, 25 seconds.
6. **Comment bait.** "Pick a Canvas look and I'll guess your major." Four looks on screen, question in
   the caption.
7. **No account.** "No email, no password, no account. Eight characters." Phone and laptop in one
   frame, 12 seconds.
8. **What it sends.** "Here is literally everything this extension sends anywhere." Screen record
   devtools, expand the one request, show it is assignment titles and due dates with no email on it.
   24 seconds.
9. **Quiz pages.** "Watch what my Canvas extension does on a quiz page. Nothing." Open a quiz, skin
   is off, 10 seconds. Never name who broke theirs.
10. **Look codes.** "Six characters and you have my exact Canvas." Type a code, look applies, 9
    seconds.
11. **Reply tutorial.** "Replying to @___ here's the deep sea one, step by step." Repeat once per
    look, forever. This is the workhorse.
12. **Freshman advice.** "Thing I wish I knew freshman year: your Canvas can look like anything."
    Talking head into screen recording, 28 seconds.
13. **App roundup.** "Five things that got me through midterms, and the first one isn't an app."
    Prepkin at number one as a browser extension, 32 seconds.
14. **Day in the life.** "Day in my life, except every assignment I finish feeds a fish." Timestamps,
    campus b-roll, three Canvas cutaways, 34 seconds. Shoot the fish half on the phone, not in the
    extension.
15. **Study with me.** "25 minutes. One fish. Phone face down." Long on YouTube, cut a 20-second
    Short from the reveal at the end. Phone app only.
16. **The grade page.** "I refresh this number eleven times a night. Now the page is at least
    readable." Screen recording, 15 seconds.
17. **Setup in 60.** "Setting up my Canvas for the semester in one minute." Install to themed in one
    take, 30 seconds.
18. **Sound off.** "Turn the sound off. Watch the top of the screen." Pure caption video, plain text
    card format, 12 seconds.
19. **The list.** "Five things Prepkin does not do." No account, no ads, no data selling, nothing on
    quiz pages, no cap on anything. Checklist graphic, 18 seconds.
20. **Two tabs.** "Same Canvas, two browsers, one of them is mine." Split screen, 11 seconds.
21. **The costume shop.** "Everything in this shop is bought with finished homework." Scroll the shop,
    show the coin count, 20 seconds. Phone app only.
22. **Roommate.** "My roommate typed six characters and now our Canvas matches." Two laptops in
    frame, 13 seconds.
23. **The price line.** "The other one is $119 a year. Mine's $70, and the Canvas part is free."
    Plain text card, 10 seconds. Read the number off `PLUS-SPEC.md` section 5 on the day you film.
24. **Sponsor a stranger.** "If you can't afford it, there's a link that just gives it to you." 12
    seconds, said plainly, no music.
25. **Semester Wrapped.** "Semester Wrapped, but it's your Canvas." Ship 2026-12-07 and cut ten
    variants from one recording.
26. **Winter.** "Setting up next semester's Canvas over break." Post it 2026-12-29, 15 seconds.

**Held until Sprout is in the extension:**

- **The fish.** "There's a fish that lives in my Canvas tab now." Buddy panel open over the dashboard,
  11 seconds. Today that panel draws a slime.
- **The loop.** "I turned in one assignment and my fish got a hat." Coin lands, costume goes on, 15
  seconds.
- **Focus.** "45 minutes of work and my fish swam a whole reef." Timer running, scene moving, 20
  seconds.
- **The phone half.** "My Canvas to-do list is on my phone, with a fish sitting on it." 16 seconds.


---

## Week by week

**Mon 2026-09-07 to Sun 2026-09-13: Get listed, and port the fish.** Domain bought and four pages
live, **Sprout ported into the extension**, host permissions narrowed, privacy policy hosted, data
declaration filled truthfully, store listing and manifest renamed, extension submitted, accounts
opened, nine short links created, look code and Look Card shipped, first twelve videos cut, 40
newspaper emails out. *Measuring: nothing yet. The only question is whether the listing is in review
by Wednesday.*

**Mon 2026-09-14 to Sun 2026-09-20: Launch.** Listing goes live if review clears. One video a day
starts. 26 Pinterest pins. First disclosed Reddit comments. Rep hired at UCF, 100 stickers ordered.
*Measuring: daily installs, first store reviews.*

**Mon 2026-09-21 to Sun 2026-09-27: The quarter-school wave.** Quarter campuses are in week one
right now: Stanford started 22 September, UW 30 September, the UCs late September. Aim four videos at
"setting up my Canvas for the new quarter." First sticker drop on campus. Start the burner TikTok
creator list. Daily reply-video habit begins. *Measuring: installs by day, view counts at day 10 on the
first seven videos.*

**Mon 2026-09-28 to Sun 2026-10-04: Last install week, submit the app, and clear the paid-account
blockers.** Creator DMs start from Instagram, 25 a day, and run for six weeks. Second footage session
at UCF. Lemon8 walkthrough published. **Submit the iPhone app this week, before the freeze**, with all
four Apple disclosures already in the binary.

**These five are hard blockers, not admin. Without all of them a subscription product cannot even be
created in App Store Connect, let alone submitted:**

- Accept the **Paid Applications Agreement**. George, Monday.
- Submit **banking details** and the **US tax forms** (W-9 and the tax residency questionnaire).
  George, Monday. Apple will not create a paid product until all three are in the Accepted state.
- Create the two subscription products in one subscription group with annual as the higher level.
  **The ids are `com.prepkin.canvas.plus.monthly` and `com.prepkin.canvas.plus.yearly`** — they are
  already live in `ios/Sources/Core/Plus.swift` and `ios/PrepkinCanvas.storekit`, so anything else
  will not resolve. Prices from `design/PLUS-SPEC.md` section 5. George, Tuesday.
- Set the **billing grace period to 16 days** on the group, and write the App Review notes explaining
  that the preview is a gift with no card and the paywall appears only after it ends. George, Tuesday.
- Apply to the **Small Business Program** the day the developer account activates.

**Write the App Store listing this week too.** 150 of the projected app users are credited to App
Store search, and the old plan had no task anywhere that wrote the listing. Title, subtitle with
**Canvas in it**, the 100-character keyword field, the description including "for students 13 and
older", and six screenshots. Without these that 150 is a wish, not an estimate.

*Measuring: total installs against a 250 target, DM reply rate, and whether the three Apple agreements
are Accepted.*

**Mon 2026-10-05 to Sun 2026-10-11: Freeze the skin, and write the StoreKit code.** No change
touching a Canvas page until 31 October. Ship the guards first if they are not already in: nothing
runs on quiz pages, submission pages, or the rich text editor, with tests that fail the build. Ship
the tank-accretes loop.

**There is zero StoreKit code in `ios/Sources` today.** Nothing matches StoreKit, `currentEntitlements`
or `Product.products` anywhere in the app. This week writes it:

- The entitlement check on `Transaction.currentEntitlements` at launch, treating `inGracePeriod`
  exactly like `subscribed`. George, 2 days.
- The `Transaction.updates` listener, held for the app's lifetime, calling `finish()` every time.
  George, 1 day.
- The four-screen paywall, with all four 3.1.2 disclosures on screen: title, length, price, price per
  period, and tappable privacy and terms links. George, 2 days.
- **Plus benefit: the shop refreshes three times a day with one discounted costume.** George, half a
  day.
- **Plus benefit: the faster coin rate.** George, half a day.

*Measuring: zero Canvas incidents, and the entitlement check working against a sandbox account. Those
are the whole metrics.*

**Mon 2026-10-12 to Sun 2026-10-18: The Tank Card and the pairing QR.** Ship the Tank Card render in
the app. Ship the gifted preview that fires at the third finished assignment, and **count preview
starts and preview ends from the first day**, because paywall reach is the number the whole revenue
model turns on and nothing measures it today. Add the "how did you hear about Prepkin" screen and the
self-reported 18-or-over tap on it. Sign the first two creators.

- **Ship the pairing QR in the extension popup.** The popup has a text code field, `id="code"`, and no
  QR element. The risk table's own fix for a low pairing rate is a QR at launch instead of as a
  fallback, and no week had ever scheduled it. It is a canvas render of the same eight characters,
  under a day of work, and it must be live the day the app is. George, 1 day.
- **Plus benefit: saved combinations, free cap of three.** The feature does not exist yet, so the free
  version ships here and the unlimited version is what Plus unlocks. George, 2 days.

*Measuring: pairing rate from the day the app is live. This is the number that decides everything.*

**Mon 2026-10-19 to Sun 2026-10-25: App live, paywall on.** Paywall lands after the preview ends,
never in first run. Grace period on at 16 days. Repost every creator video the day it goes up. Push
the "rate it" link in the popup after a student's third finished task.

**A skeptic pass said plainly: do not launch Plus until there is a content treadmill it can
accelerate, and ship two events before the paywall goes live.** The old plan ignored that and never
answered it. Here is the answer, and it is a split, not a dismissal. **The paywall ships on 10-19
selling only the three things that exist and can be judged on the day: the shop refresh, the coin
rate and unlimited saved combinations.** The two event benefits are **cut from the paywall copy until
2026-11-30**, after the second event has actually run, because a student cannot evaluate "one extra
event reward" for a thing she has never seen. Waiting until 11-30 to charge anything at all was the
alternative and it loses six weeks of the only paying window this year for a benefit worth two lines
of copy.

*Measuring: app users, preview starts, Tank Cards rendered, store reviews.*

**Mon 2026-10-26 to Sun 2026-11-01: First event, freeze lifts.** Run the first monthly event, metered
on finished assignments, no calendar, **and progress that never expires**. Build the two event Plus
benefits with it: the extra event reward, and the pet at 20 finishes instead of 25. Ship the first
event's new Learn figure theme and new Focus timer sound, both **new**, neither taken from the free
set. Unfreeze 31 October and ship everything held back in one release. Lay the creator post timestamps
over the install curve. *Measuring: has one post cleared 50,000 views.*

**Mon 2026-11-02 to Sun 2026-11-08: Spend or hold.** If one post cleared 50,000 organic views, put
$400 of Spark Ads behind it from the creator's handle. If not, keep the money and buy two more creator
videos. Check the campus trigger: 150 attributable installs, 15 store reviews, one Tank Card that
someone who is not George posted publicly. *Measuring: the three trigger numbers.*

**Mon 2026-11-09 to Sun 2026-11-15: Renew or move.** If the campus trigger hit, renew the rep for six
more weeks. If it missed, stop the campus spend and put the hours into reply videos and Reddit. Three
videos aimed at spring registration, which opens on most campuses this month. *Measuring: trial starts.*

**Mon 2026-11-16 to Sun 2026-11-22: Reviews and store pages. This is an acquisition week, not a
reputation week,** because Chrome store rank compounds with review count and rank is channel 1. Push
toward 25 Chrome reviews. Reply
to and fix every one-star inside 24 hours. Set up App Store custom product pages, one per look and one
per creator; keyword-matched pages produce 23% more downloads on identical spend. *Measuring: review
count and average, first day-35 cohort forming.*

**Mon 2026-11-23 to Sun 2026-11-29: Dead week. Thanksgiving is Thursday 26 November.** Post nothing
new from Tuesday to Saturday; three pre-made evergreen tutorials carry it. Ship nothing that touches
Canvas. Read every comment and review and write December's video list from them. *Measuring: nothing.
This week is for reading.*

**Mon 2026-11-30 to Sun 2026-12-06: Second event, Plus copy completes, build Wrapped.** Run the
second monthly event with its own new figure theme and new timer sound. **Two events have now run, so
the two event benefits go into the paywall copy today**, six weeks after the paywall itself. Semester
Wrapped: assignments finished, coins earned, focus hours, the look she used most, her fish in his
costume, one shareable card. Pre-record all ten Wrapped videos so the week it ships needs no new
footage. *Measuring: day-35 conversion on the October cohort. First honest read.*

**Mon 2026-12-07 to Sun 2026-12-13: Wrapped ships, freeze again.** Ship Wrapped Monday 7 December.
Second code freeze on anything touching Canvas until 19 December. Push Wrapped on every surface for
four days. This is the last real attention window of the year; finals kill it after 18 December.
*Measuring: Wrapped shares, installs off Wrapped.*

**Mon 2026-12-14 to Sun 2026-12-20: Finals. Do no harm.** One video a day, all quiet, nothing that
asks for a decision. Run the "can't afford Plus" codes for the first time, 25 of them, no proof
required. Answer every comment. Unfreeze Friday 19 December. *Measuring: nothing new. Just do not break
anything.*

**Mon 2026-12-21 to Sun 2026-12-27: Dead week.** One post every other day, all pre-scheduled. Fix the
backlog of small bugs. Nobody is on Canvas. *Measuring: nothing.*

**Mon 2026-12-28 to Thu 2026-12-31: Count.** Write down installs by channel from the nine short
links, the measured pairing rate, app users, the 18-and-over share, preview starts, preview ends,
paywalls shown, payers, gross, net, store reviews, and the full "how did you hear" tally. Kill whichever channel came last and give its hours to whichever came first. Book the
January plan against 5 to 20 January, when spring semesters start, which is the bigger window because
the base compounds instead of resetting. *Measuring: everything, once.*

---

## The numbers

**Read this first: the totals fell hard, and they fell because the arithmetic was finally done.** The
old version asserted nine channel numbers that no rate produced, put paywall reach at 69% of app users
with no source, and double-counted the payer figure. Fixing each of those separately would have been
survivable. They compound. Base-case installs went from 1,800 to 760, and 2026 revenue went from about
$44 to about $20. Nothing here is a new pessimism. It is the same plan with the multiplication carried
out.

**Base case, by 2026-12-31.**

- **Extension installs: 760.** Store search 120, own video 150, Reddit 120, Pinterest 100, Spark Ads
  100, Look Cards and codes 80, papers 40, creators 27, campus 20. Every one is derived in the channel
  table.
- App live about 2026-10-19. Installs landing after that date: about **480**.
- Paired and opened at 15%: **72 app users.** Plus about **150** from App Store search directly, since
  roughly 60% of App Store downloads come from search and "Canvas" faces almost no competition in the
  subtitle. That 150 now depends on the App Store listing task added to the week of 2026-09-28. With
  no title, subtitle, keywords or screenshots it is zero. **Total app users: about 220.**
- **Self-reported 18 or over: about 145.** *Estimate, no source.* The runner-up audience is high
  schoolers, most of whom cannot buy: only 9.4% of US teens have ever used a debit card, and a
  16-year-old who taps buy is usually under Ask to Buy, which sends the decision to a parent's phone
  and ends there. Applying a conversion rate to the whole pool overstates payers, so from here the
  rate is applied **only to the 18-and-over half.** The split is measured at the "how did you hear
  about Prepkin" screen, which now carries a single 18-or-over tap.
- **Reach the paywall: about 29.** That is **20% of the 18-and-over app users**, and it is *an
  estimate, not a measurement.* Reaching the paywall means finishing three Canvas assignments **and**
  still being in the app seven days later. Typical D7 retention for a new consumer app is 10 to 25%,
  so 20% is the middle of that band and probably generous. The old plan said 220 of 320, which is 69%,
  with no source at all. **Measure it from day one: count preview starts and preview ends in the app,
  starting the week of 2026-10-12.**
- **Convert at 1.5%: about 0 to 1 mature payer,** and call the mature-payer base case **1**.

**Mature payers and payers charged in 2026 are two different numbers, and the old plan added them
together.** It said "convert at 1.5%: 3 mature payers", then "only about half of eventual payers are
charged inside the calendar year", then printed 3 as the 12-31 figure. Both numbers are stated
separately from now on:

- **Mature payers at full maturity: 1** (range 0 to 3). Education buyers convert late. 23.5% of
  Education trial starts happen on day 31 or later.
- **Payers actually charged by 2026-12-31: 0 to 1.** Installs are back-loaded and the paywall opens on
  2026-10-19, so roughly half of eventual payers are charged after New Year.
- **Trials running on 2026-12-31: about 5.**
- **Gross revenue in 2026: about $70.** Realistically that is one annual plan, or nothing at all. Net after
  Apple's 15%: about **$17**. The old plan's $44 came from adding 2 annual and 1 monthly, which was
  the mature number wearing the in-year label.

**Low case.** 300 installs, 60 app users, 0 payers, $0. This happens if the Chrome listing takes three
weeks to clear review, or the developer account is still unverified in October, or no video passes
5,000 views.

**High case.** One video breaks out, which happens to roughly 3% of videos in this genre and the top
Canvas video in it already has 123,700 likes. 8,000 installs, about 900 app users, 585 of them 18 or
over, about 117 reaching the paywall, **2 to 5 payers, $40 to $100 gross.** Read that carefully:
**even a genuine breakout does not produce meaningful 2026 revenue.** What it produces is the install
base and the store rank that January monetises. That is what the high case is for.

**Churn, which the old plan never modelled at all.** It cited two renewal rates in one sentence,
"Education annual renews at about 24%" and "yearly plans overall renew at 83.4%", and then concluded
from the flattering one that the 2026 payers are still there next September. They are not.

- **Annual: use 24%,** the Education figure, because Prepkin is an Education app. **Of every 4
  annual payers, about 1 renews in September 2027.** At a base case of 1 payer, the honest sentence is
  that there is a one-in-four chance the 2026 cohort still exists a year later.
- **Monthly: assume 50% gone by month three.** *Estimate, no source.* A $9.99 line item on a
  student's card is the first thing cut in January. So a monthly payer is worth about $10, not $48.
- The mixed-plan revenue therefore **decays**, it does not sit flat. Any January projection that draws
  a straight line from December is wrong.

**The four rates that decide everything, and where they come from.**

| Rate | Used | Source |
|---|---|---|
| Video view to install | 0.15% | **Invented.** No published rate exists for a phone video driving a desktop extension install. Every comparable sold a phone app. Replace it with George's own measurement by 2026-10-04. |
| Pairing rate (extension install to app open) | 15% | **No precedent anywhere.** Finch has never published a conversion rate and BetterCampus has no phone app. This is the single load-bearing guess and it must stop being a guess by 2026-11-01. |
| App user to paywall reached (3 finishes, then 7 more days) | 20% of the 18+ half | **Estimate.** Anchored on the 10 to 25% D7 retention band for new consumer apps. Nothing product-specific supports it. Measured from 2026-10-12. |
| Paywall shown to tap-to-buy | 1.5% | RevenueCat 2026: 2.0% for a soft paywall that never takes anything away, 2.1% for Education at day 35, against 10.7% for a hard paywall. Discounted below the median because Prepkin gates less than the median product does. **But the last step of this funnel is invented:** the published rates measure trials with a card on file that auto-charge. Prepkin's preview is a gift with no card, so she has to type a card in on purpose. Nobody has published a rate for that. |

**Tripwire dates.**

- **2026-09-14.** Apple Developer enrollment. Check the status today and again this Friday. **If the
  account is not active by 2026-09-14, open a Developer Support case,** because individual identity
  verification can take weeks and nothing chases it on its own.
- **2026-09-17.** Store listing live. If not, shift the launch push to 2026-09-28 and use the delay to
  build the Look Card and the Tank Card.
- **2026-09-28.** Apple Developer account active, and the Paid Applications Agreement, banking and tax
  forms all Accepted. **If the account is not active by 2026-09-28, the app submission moves to
  2026-10-12 and the paywall moves to January.** Written here so it is a decision in September, not a
  discovery in November.
- **2026-10-04.** 250 installs. If under 120, the video channel is not working and the hours move to
  Reddit and student papers.
- **2026-10-04.** Installs per 10,000 views on /s-video. **If under 0.1%, stop making original hooks
  and run only reply videos.**
- **2026-11-01.** One post above 50,000 views. If none, do not spend the $400 on ads.
- **2026-11-01.** Pairing rate measured. If under 10%, the revenue plan is wrong and the fix is
  product, not marketing: move the pairing prompt earlier and give the phone app a reason to open on
  its own.
- **2026-11-08.** Campus trigger: 150 attributable installs on /s-campus, 15 reviews, one public Look
  Card or Tank Card from a stranger. Miss any and stop the campus spend. Note that 150 attributable
  installs is far above the 20 this channel is now budgeted to produce, so on the base case this
  trigger fails and the rep ends at six weeks. That is the expected outcome, not a surprise.
- **2026-12-01.** October cohort day-35 conversion. This is the first honest read and it sets January.

**Say the bottom line out loud.** The budget spends about $1,759 to book about $20 in 2026. That is a
loss of roughly $1,740 and about 380 hours of George's time. It is a deliberate trade: the money buys
installs, store reviews, video that stays searchable, and a working paywall, all of which January
monetises. A one-time purchase resets to zero every semester. A subscription does not, though at a 24%
Education renewal rate it decays fast enough that the January cohort matters far more than the
December one.

**And the honest verdict, unchanged and now worse.** 1,000 paying customers by 2026-12-31 is not
reachable. At the conversion every benchmark shows, 1,000 payers needs roughly 50,000 to 100,000 app
users, which needs several hundred thousand extension installs. BetterCanvas took four years to pass a
million. Judge this quarter on the pairing rate, the number of cards posted by people who are not
George, and the store review count. Not on a payer number.

---

## Budget

| Item | Cost |
|---|---|
| Chrome Web Store developer fee | $5 |
| Apple Developer Program, one year | $99 |
| prepkin.app domain (Namecheap, 1 year) and Cloudflare Pages hosting for /privacy, /terms, /get, /schools | $45 |
| Nano creators, 6 videos at $120 | $720 |
| UCF campus rep, $75 a week for 6 weeks: **this is a footage line, not an install line** | $450 |
| Stickers, 100 die-cut with a QR on the back, handed out at the two shoots | $40 |
| Spark Ads, held until one post clears 50,000 views | $400 |
| Short links (Dub.co free tier) and QR codes | $0 |
| **Total** | **$1,759** |
| Reserve inside the $2,000 ceiling | $241 |

The print run dropped from $200 to $40 because 500 stickers and 200 flyers were credited with 200
installs, a 28% conversion on printed matter. Real QR scan-to-install rates on print run 1 to 2%. The
rep stays because the two-second face shots, the hands and the campus b-roll are the one thing the
hook conventions need and George cannot shoot alone.

If the campus trigger misses on 2026-11-08, the unspent rep weeks fund two more creator videos. If no
post clears 50,000 views by then, the $400 funds three more.

---

## Risks

| Risk | Likelihood | Impact | Cheapest fix |
|---|---|---|---|
| The skin breaks a Canvas page during midterms and a district blocks Prepkin | Medium | Fatal to the school channel, permanently | Guards on quiz, submission and editor pages with build-failing tests, shipped before 2026-09-14. Freezes 5 to 31 October and 7 to 19 December. A remote off-switch read from the bridge so the skin can be turned off in an hour instead of waiting for a store review. |
| The Chrome data declaration does not match what the code sends | Medium | Listing removal, and the privacy story dies | Fill it truthfully on 2026-09-08 before submitting. The honest version is a better line anyway: one list, one place, no email. |
| Chrome review takes three weeks and the acquisition window closes | Medium | Launch slips past 4 October | Submit 2026-09-08, six days before the first video. If not live by 17 September, shift to the 28 September quarter-school week and build the Tank Card in the gap. |
| The iPhone app is rejected or the developer account is late | High | 2026 revenue goes to roughly zero | Nothing in acquisition depends on Apple. **Check enrollment status today and again 2026-09-14, and open a Developer Support case the moment it is past 09-14 without activating**. Individual identity verification can take weeks and nothing chases it on its own. Accept the Paid Applications Agreement and file banking and tax forms the week of 09-28. Without all three Accepted, a subscription product cannot be created at all. Put all four 3.1.2 disclosures in the binary before the first submit. **If the account is not active by 2026-09-28, the app submission moves to 10-12 and the paywall moves to January.** Budget two review cycles. |
| A student cannot install the extension because her Chromebook is district-managed | High, for the 4 to 6M high-school audience | The runner-up audience has no coin loop at all | Publish prepkin.app/schools by 2026-09-09 with the extension ID, the pages touched, the Chrome Enterprise allowlist policy name and copy-paste Incident IQ wording, written for a student. Say "install it on your own laptop, not the school Chromebook" in the store listing and every high-school-facing video. And accept the hole: hand-entered tasks pay no coins, because coins are for Canvas-verified finishing, so the phone app gives a Chromebook-locked student Learn, Focus and a tank, and nothing to earn with. |
| The all-sites host permission scares installers and slows Chrome review | Medium | Longer first review, and the privacy story is undercut by the permission dialog | Narrow to `*://*.instructure.com/*` and request self-hosted Canvas hosts through `chrome.permissions.request` at the moment she adds a school. **Do it before the 2026-09-08 submit.** a permission change after publication triggers a fresh review. |
| The pairing rate is far below 15% | High | Every revenue number is wrong | Instrument the funnel from the day the app is live and read it weekly. **Ship the pairing QR in the popup, built in the week of 2026-10-12 alongside the Tank Card, so it is live the day the app is.** The popup has a text code field, `id="code"`, and no QR element today; this is a canvas render of the same eight characters and is under a day of work. If under 10% by 1 November, the answer is product work. |
| The TikTok account gets no distribution | High | The largest channel produces almost nothing | Judge at day 10. If twenty videos in a row come in under 1,000 views, stop making original hooks and make only reply videos and videos against Creator Search Insights content gaps. The 700-install low case already assumes this. |
| A bad launch fortnight becomes the permanent store rating | Medium | Store search stops working | The store now weights recent reviews most heavily. Ask for a review only after a third finished task. Reply to and fix every one-star inside 24 hours. Keep the put-back visible so an unhappy student un-skins Canvas instead of leaving a one-star. |
| BetterCampus ships Campies, its announced pet | Medium | The differentiator narrows | It has not shipped through v9.8.1 and was announced 26 August 2026, so the window is months. Lean on the half they cannot copy quickly: coins for Canvas-verified finishing, which their own users are asking for on their own feedback board and getting no reply. |
| Trial-to-paid anger | Low, if we ship the timeline | Reputation, and it breaks a no-scolding brand | Gift first, ask second. Four screens with a real today, reminder, charge timeline. Reminder sent two days early, for real. One-tap cancel from inside the app. |
| Founder burnout | High | The Sunday shoot stops and the whole plan stops | One post a day, not two. One three-hour Sunday block. Ten minutes a day on reply videos. Two dead weeks written into the calendar. A written cut order: Pinterest, campus, Reddit, Spark Ads. Never the Sunday shoot, the listing, or the freezes. |
| Trademark pressure on the extension name | Low | A forced rename mid-quarter | Do not lead the name with Canvas, use no Instructure logo or colours, never name a competitor in the listing, and keep the comparison page on prepkin.app only. |

---

## This week, in order

Monday 2026-09-07 is Labor Day. Items 0 to 4 still happen today, because nothing ships without them.

**0. Port Sprout into the extension. This is the first thing, before the listing.** `content.js` draws
the slime from `slimeSVG()` at line 202, called at lines 885, 890, 897, 957, 993, 1033 and 1046.
`popup.html` has `id="slime"`. `looks.js` still says "Looks: a palette plus something the slime
wears." The whole voice call-to-action, the store story and four of the videos all say fish, and the
product shows a slime. Replace `slimeSVG` with the Sprout render in both files, keep the same call
signature so the seven call sites do not change, and update the looks.js header. **Also open
`extension/icons/icon128.png` and confirm it is Sprout, not the slime, before a single video ships.**
Until this lands: the four fish videos are held, "it's the fish one" is cut from the spoken line, and
**the Receipt and the put-back are the hero.**

**1a. Buy prepkin.app at Namecheap.** About $12 for the first year. It is a purchase, not a decision.

**1b. Point it at Cloudflare Pages,** free tier, a static repo. Named here so nobody has to choose a
host on a holiday Monday.

**1c. Publish four pages today.** `/privacy`, `/terms`, `/get` (the QR target, which redirects to the
Chrome listing and is where all nine short links land), and `/schools` (the allowlist kit: extension
ID, pages touched, the quiz-page sentence, the FERPA sentence, and copy-paste Incident IQ wording).
Items 1 and 4 below cannot start until these exist, which is why the old plan could not have been
followed as written.

1. Write and host the privacy policy and the terms at prepkin.app/privacy and prepkin.app/terms,
   including the two new sentences: **Prepkin is for students 13 and older**, and **no student record
   leaves the browser except the assignment list and course grades, and they go only to the student's
   own paired phone.**
2. Fill the Chrome Web Store data declaration. Tick **Website content** and **User activity**. Do not
   tick personally identifiable information, financial, authentication, personal communications,
   location, health or web history. Certify all three limited-use statements. Link
   prepkin.app/privacy. Then write the honest one-line version for the description.
3. Rename the listing to "Prepkin: Themes and Dark Mode for Canvas" and write the description for one
   person, a college undergrad on her own laptop. **And fix the name inside the product, not only on
   the store page:** change `manifest.json` `name` and `default_title` from "Prepkin Canvas Sync" to
   **"Prepkin"**, change the popup button from **"Sync now"** to **"Check for new work"**, and grep
   `extension/` and `ios/Sources/` for `sync`, `bridge`, `selector`, `token` and `schema` in any
   string a student can see. Those five words are on the banned list in PRODUCT.md and one of them is
   currently on a button she presses.
4. **Narrow the host permissions in `manifest.json`** to `*://*.instructure.com/*` and move the
   self-hosted case to `chrome.permissions.request` at the moment she adds a school. This has to be in
   the build submitted tomorrow, because a permission change after publication triggers a fresh review.
5. Open @prepkin as a TikTok Business account, plus YouTube and Pinterest, and point the TikTok bio
   link at prepkin.app/get.
6. **Create the nine short links on Dub.co's free tier**, all redirecting to prepkin.app/get:
   /s-store, /s-video, /s-creator, /s-campus, /s-paper, /s-reddit, /s-pin, /s-card, /s-ads. Cost $0.
   Two of the three tripwires cannot be read without them.
7. **Check the Apple Developer enrollment status.** If it has not activated by Friday 2026-09-11, open
   a Developer Support case on 2026-09-14. It is rated High likelihood and fatal to 2026 revenue, and
   nothing else in the plan chases it.
8. Tuesday 2026-09-08: pay the $5 fee and submit the extension, with the narrowed permissions and the
   renamed manifest in the build.
9. Tuesday: build the burner TikTok account and spend two days training its feed on studytok and
   aesthetic-Canvas videos only.
10. Tuesday: read the written self-promotion rules of r/college, r/GetStudying, r/SideProject and ten
    campus subs, and write down which allow a disclosed comment.
11. Wednesday 2026-09-09: ship the guards so nothing runs on quiz, submission or rich-text-editor
    pages, with tests that fail the build if they regress.
12. Wednesday: publish prepkin.app/schools with the extension ID, the pages touched, the Chrome
    Enterprise allowlist policy name, the FERPA sentence and the Incident IQ request wording, written
    for a student to send, not only for a newspaper to quote.
13. Wednesday: publish **26 Pinterest pins, one per look**, hex codes printed on each image, linking
    /s-pin. There are 26 looks in themes.js, not 20.
14. Thursday 2026-09-10: email 40 student newspapers, pitching **the IT service piece**, not a launch,
    with the Receipt screenshot, a themed dashboard and the /schools link. Link /s-paper.
15. Thursday: **post the campus rep listing on the UCF job board** and order 100 QR stickers.
16. Friday 2026-09-11: screen-record the five raw takes on real Canvas data.
17. Friday: write three sentences into PRODUCT.md and the store listing: "a look you make is yours and
    never leaves your extension", "no cap on applying, swapping or saving looks, ever", and the
    code-review gate: **nothing that has ever shipped free may move behind Plus, in any release, for
    any reason.** The third one is the one a future release can quietly break, and the old plan wrote
    the first two and not it.
18. Saturday 2026-09-12: ship the six-character look code in the popup, **selecting the theme palette
    only, not the accessory.** The four look accessories are marked provisional in looks.js and need
    George's sign-off, and they are drawn in the slime's coordinate space, so they get redrawn with
    the Sprout port and go through their own sign-off round.
19. Saturday: ship the **1080x1350 Look Card** from the extension popup: her real themed dashboard,
    big, course names blanked, look code as a small caption. This is the only thing a student can post
    before the Tank Card arrives on 2026-10-12, and without it the first five weeks of daily video
    have no share unit behind them.
20. Saturday: cut the first twelve videos with HyperFrames and queue the week.
21. Sunday 2026-09-13: hire the UCF campus rep, and set the recurring Sunday three-hour shoot block.

---

## What we are not doing

- **A public gallery of student-made looks in 2026.** There is no theme editor to publish from, it
  changes the privacy declaration, and it needs moderation, reporting and blocking before Apple will
  take an app carrying it. January, with a real editor.
- **Fake campus Instagram accounts named for a university.** Impersonation, a trademark complaint
  waiting to happen, and it worked for tbh only because the school was the product.
- **Seeding looks under invented student handles.** Fabricated makers on a page whose only value is
  that real students made it. Seed under @prepkin, labelled as ours.
- **A second currency ("pearls").** A shelf coins can never reach is a member-only shelf, which
  contradicts the sentence printed on the paywall.
- **A loyalty discount ladder.** Needs a signing server we said we would not build, shows a progress
  meter the brand rules ban, and teaches the best users to wait.
- **A lifetime tier.** At any price under about $100 it is worth more than the subscription, which is
  the one thing a subscription was chosen to fix.
- **Family Sharing.** Turning it on is the irreversible direction and one yearly plan would cover six
  roommates.
- **Stripe gift subscriptions.** The rule about a web purchase unlocking an iOS feature is contested
  and a first submission is the wrong place to test it. Revisit in spring as an in-app purchase.
- **Selling coins, or any cosmetic pack for cash.** Coins pay for finishing. Cash skipping the
  finishing is the thing the whole product is against.
- **A daily-chest event calendar with a day-25 payoff.** That is a countdown and a streak. Meter the
  event on finished assignments instead.
- **A tank that dims when work is not finished.** A meter that falls, with the mascot delivering the
  guilt. The tank only accretes.
- **Putting the fish on the Canvas page itself.** The page belongs to the school. The buddy panel and
  the popup are the only places the mascot appears, and she opened both on purpose. It films
  identically. **Note what is true today: those two places draw the slime, not Sprout.** The port is
  item 0 of this week. Until it lands, no video says fish about anything inside the extension.
- **A custom emoji on a Canvas task as a Plus benefit.** It lived in the extension, and the extension
  has no way to know she is a Plus member. The entitlement rides the Apple ID with no server. Carrying
  a `plus:true` flag across the pairing record is unscheduled work, and it starts a 3.1.3(b)
  conversation about what a purchase unlocks outside the app that a first submission does not need.
  Every Plus benefit lives inside the iOS app.
- **Selling any Plus benefit that has no dated build item.** Five of the six original Plus lines had
  none. Six-of-six is now dated or cut.
- **Naming or attacking BetterCampus in any video or in the store listing.** Recent reviews now carry
  the whole rating, and a brigade from a million-user Discord in launch fortnight is permanent.
- **Instagram Reels.** Reach fell 35% and only 21% of accounts under 10,000 followers grew.
- **The Study Together Discord, or any launch thread on Reddit.** Both ban it in writing.
- **The Chrome Featured badge.** Google closed self-nominations on 2026-08-20 and is sunsetting the
  programme.
- **A brand campaign.** Finch waited five years and 2 million daily users before its first one.
- **Any claim that Prepkin improves grades.** Ever. The line is: Prepkin makes finishing the work you
  already have feel less bad.

---

## Sources

https://help.finchcare.com/hc/en-us/articles/38755205001869-Finch-Plus-Pricing: Finch Plus is $9.99 monthly and $69.99 yearly
https://help.finchcare.com/hc/en-us/articles/37780200600589-Benefits-of-Finch-Plus: Finch Plus is speed, slots and convenience only, core features always free
https://finch.fandom.com/wiki/Finch_Plus: "Finch has no member-exclusive items", and the loyalty discount ladder at 25/50/75/100 days
https://help.finchcare.com/hc/en-us/articles/37780209444365-Canceling-Finch-Plus: cancelling keeps access to the end of the cycle, nothing removed
https://recurdash.com/subscription-pricing/finch: "Your birb and all progress stay" on cancellation
https://help.finchcare.com/hc/en-us/articles/38087066022285-Finch-Plus-Preview-Explained: the day-3 gifted preview, no card, nothing to cancel
https://help.finchcare.com/hc/en-us/articles/41672084300557-FAQs: two trial types, no family plan, no published conversion rate
https://help.finchcare.com/hc/en-us/articles/38108014451725-Entering-the-Guardians-Raffle: free Plus for people who cannot afford it
https://help.finchcare.com/hc/en-us/articles/37780423805069-Invite-Rewards: Finch's referral is capped at three friends and pays a micropet
https://finch.fandom.com/wiki/Seasonal_Events: 43 monthly events, the retention loop and the main thing Plus is for
https://revyl.com/atlas/finch/flows/complete-onboarding/: paywall at screen 34 of 45, attribution and buddies come after it
https://medium.com/@skuni/a-look-back-on-finchs-first-year-599ba68d06f2: 8 versions, nobody understood it, day-2 return was the signal
https://www.systemaic.com/teardowns/finch-self-care: 686+ active ads, the longest-running hook live 180 days, no published conversion rate
https://blog.sparrowapps.io/p/finch-how-a-self-care-app-hit-30m-arr-without-vc-money: 610 active Meta creatives, growth is paid not organic
https://www.chiefmarketer.com/finchs-first-brand-campaign-celebrates-the-weirder-side-of-self-care/: 2M daily users, first brand campaign only in May 2026
https://apps.apple.com/us/app/finch-self-care-pet/id1528595748: Finch's App Store title, subtitle and price points
https://gummysearch.com/r/finch/: r/finch has 195,000 members and grew 45% in a year on friend-code threads
https://foxdata.com/en/blogs/finch-as-app-store-editors-choice-a-self-care-companion/: Finch's audience is 75.79% female, mostly 25 to 35
https://habitbox.app/blog/finch-app-review: trial-to-paid billing is the most repeated complaint about Finch

https://chromewebstore.google.com/detail/bettercampus-prev-betterc/cndibmoanboadcifjkjbdpjgfedanolh: BetterCampus current listing, over a million installs
https://chrome-stats.com/d/cndibmoanboadcifjkjbdpjgfedanolh: listing created 2020-10-18, publisher and permission change history
https://raw.githubusercontent.com/UseBetterCanvas/bettercanvas/main/README.md: the original feature list, and theme submission was an email or a pull request
https://bettercampus.com/themes: the public theme gallery, maker handles and install counters, and the twelve-theme LeBron category
https://bettercampus.com/pricing: BetterCampus Pro is $119 a year or $19 a month
https://help.bettercampus.com/changelog: free theme swaps enforced, Canvas Wrapped shipped 2026-05-01, no Campies through v9.8.1
https://feedback.bettercampus.com/: students asking for coins for finishing work, and complaints about caps and deleted themes
https://feedback.bettercampus.com/p/im-sorry-but-were-litearly-college-students: $119 a year is unaffordable for college students
https://extpose.com/ext/cndibmoanboadcifjkjbdpjgfedanolh: reviews naming deleted themes, forced accounts and the gated timer
https://lionsroarnews.com/37673/a-guide-to-a-cuter-better-canvas/showcase/: TikTok in 2024 took downloads from thousands to millions
https://machronicle.com/bettercampus-temporarily-blocked-students-frustrated/: Sequoia Union blocked it after Canvas Quizzes stopped loading; the district allowlist and Incident IQ
https://woodsidepawprint.com/student-life/2025/09/10/students-push-back-after-bettercanvas-ban/: student pushback after the district block
https://scotscoop.com/suhsd-blocks-bettercampus-amid-district-wide-security-concerns/: still blocked two months later
https://addons.mozilla.org/en-US/firefox/addon/better-canvas/reviews/: a dark-mode theme hid the submit button
https://www.linkedin.com/in/jaketsilver/: first dollar 2025-09-03, $1M ARR 2026-09-03, Campies announced 2026-08-26
https://www.coursicle.com/blog/better-canvas/: a competitor publishing an anti-BetterCanvas page to intercept the search traffic

https://www.starterstory.com/turbolearn-ai-breakdown: 40+ TikToks on a $300 budget, no paid spend before 1M users
https://www.techcrunch.com/2025/10/23/20-year-old-dropouts-built-ai-notetaker-turbo-ai-to-5-million-users: 5M users, ten-person team
https://onghost.com/reports/calai: 300 creators on retainer at a $2 to $3 CPM, product on screen in 15 seconds, pinned comment required
https://growthcurve.co/three-engines-and-an-exit-the-cal-ai-growth-playbook: about 1 reply per 100 DMs, sent in bulk on Instagram
https://heyrostr.com/blog/how-cal-ai-built-1m-month-tiktok-creators: burner account trained on the niche to source creators
https://zapier.com/blog/momentum-levi-bucsis-interview/: 0 to 100,000 users in four months off one r/productivity comment, never featured in the store
https://businessmodelcanvastemplate.com/blogs/brief-history/honey-brief-history: one Reddit post produced thousands of downloads in a day
https://apps.apple.com/us/app/focus-friend-by-hank-green/id6742278016: $3.99 monthly, $19.99 yearly, $39.99 lifetime, no login
https://focusfriend.me/focus-friend-scarves: Pro adds a second earned currency from the same finished session
https://www.tubefilter.com/2025/08/20/hank-green-tops-app-store-charts-focus-friend/: #1 in the US after the Green brothers posted it
https://www.synergylabs.co/blog/how-nikita-bier-built-two-viral-apps-without-spending-a-dollar-on-marketing: the tbh school-by-school Instagram play
https://techcrunch.com/2022/10/04/fizz-app-college-stanford-social/: Fizz reached about 95% of Stanford undergrads with paid moderators and doughnuts
https://www.thedrum.com/news/duolingo-s-tiktok-mastermind-its-unhinged-social-strategy-and-killing-its-mascot: one 23-year-old, mascot as the account, 50,000 to 16 million followers

https://www.revenuecat.com/state-of-subscription-apps: median yearly price, soft paywall converts 2.0% versus 10.7% hard, trial length conversion by days
https://www.revenuecat.com/state-of-subscription-apps-2026-education: Education day-35 download-to-paid 2.1%, year-one LTV $22.82
https://www.revenuecat.com/blog/growth/average-subscription-renewal-rates-by-app-category: Education annual renews at 24%, yearly renews 83.4% at first renewal
https://www.revenuecat.com/state-of-subscription-apps-2026-business/: median app makes about $72 a month a year after launch
https://www.revenuecat.com/blog/growth/how-top-apps-approach-paywalls: contextual screens before the paywall, Blinkist's honest paywall lifted conversion 23% and cut complaints 55%
https://adapty.io/blog/education-app-subscription-benchmarks/: 23.5% of Education trial starts happen on day 31 or later
https://developer.apple.com/app-store/review/guidelines/: 3.1.1 currency may not expire, 3.1.2 required disclosures, 3.1.3(b) direction of unlocking, 1.2 user-generated content
https://developer.apple.com/app-store/small-business-program/: 15% rate, effective 15 days after the end of the approval month
https://www.developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases: once Family Sharing is on it cannot be turned off
https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-subscription-offer-codes/: up to 10 active offers, batches to 25,000, a million redemptions a quarter
https://developer.apple.com/documentation/storekit/transaction/currententitlements: the no-server entitlement check
https://support.apple.com/en-us/105055: Ask to Buy is on by default under 13 and can be non-removable under 18
https://adapty.io/blog/custom-product-pages-app-store/: keyword-matched custom product pages produced 23% more downloads on identical spend

https://developer.chrome.com/blog/cws-review-updates-2026: Featured badge sunset 2026-08-20, ratings now weight recent reviews
https://dev.to/_350df62777eb55e1/chrome-web-store-seo-how-i-optimized-17-extensions-for-search-2maj: keyword-first rename took one extension from 15 to 65 installs a week
https://support.google.com/chrome/a/answer/6177431: Chrome Enterprise extension allowlists
https://workspaceupdates.googleblog.com/2023/08/third-party-app-access-enhancements-for-google-workspace-edu.html: under-18 school accounts blocked from unconfigured third-party apps since 2023-10-23

https://metricool.com/press-release-tiktok-study-2026/: TikTok views down 31.30%, 16.47% of accounts tiered up, hashtags and questions data
https://metricool.com/press-release-instagram-study-2026/: Reels reach fell 35%, only 21% of sub-10K accounts grew
https://www.opus.pro/blog/tiktok-hooks-that-go-viral-2026: product or outcome showcase is the top hook across 34,635 clips
https://thecontentlabs.app/blog/faceless-vs-face-on-camera-data-study: face on camera earns 2.4x on TikTok, 1.3x penalty on Shorts, teacher hook has the smallest gap
https://www.opus.pro/blog/tiktok-caption-subtitle-best-practices: caption style, and about 60% of TikTok watched muted
https://stackinfluence.com/blog/best-tiktok-video-lengths-for-creators-in-2026: 21 to 34 seconds has the highest completion
https://www.loopexdigital.com/blog/youtube-shorts-statistics: 74% of Shorts views from non-subscribers
https://stan.store/blog/tiktok-link-bio-requirements-2026-guide/: a Business account gets a bio link at zero followers
https://www.tiktok.com/@nicoledorius2/video/7321505387860004138: the aesthetic-Canvas genre, 123.7K likes and 610 comments
https://www.tiktok.com/discover/better-canvas-themes: standing TikTok discover pages for the competitor's themes
https://www.lemon8-app.com/experience/how-to-make-canvas-aesthetic?region=us: the Lemon8 tutorial structure, with Pinterest as step three
https://blog.hootsuite.com/pinterest-statistics/: 42% of Pinterest users are Gen Z, 47% of Gen Z search there, CPC $0.83
https://influee.co/blog/tiktok-influencer-rates: nano creators at 1K to 10K followers charge $25 to $200 a video
https://influencerfee.com/blog/influencer-whitelisting-pricing/: Spark Ads whitelisting adds about 30% to the fee
https://www.ftc.gov/business-guidance/resources/ftcs-endorsement-guides-what-people-are-asking: disclosure must be at the start and inside the video
https://oneup.today/blogs/reddit-selfpromo-rules-study-2026: 39% of founder-pitched subreddits ban self-promotion outright
https://www.studytogether.com/rules: the largest study Discord bans direct and indirect self-promotion

https://www.studentclearinghouse.org/nscblog/postsecondary-enrollment-rises-as-academic-trends-shift/: 19.4M US postsecondary students, 16.2M undergraduates, fall 2025
https://onedtech.philhillaa.com/p/state-of-higher-ed-lms-market-for-us-and-canada-year-end-2024-edition: Canvas holds about 50% of US and Canada higher-ed enrollment
https://www.prnewswire.com/news-releases/new-instructure-data-shows-k-12-districts-are-demanding-evidence-not-just-access-to-edtech-tools-302812840.html: more than 11 million US K-12 Canvas students
https://gs.statcounter.com/browser-market-share/desktop/united-states-of-america: Chrome is 65.55% of US desktop
https://www.educause.edu/ecar/research-publications/ecar-study-of-community-college-students-and-information-technology/2019/device-access-ownership-and-importance: 91% laptop access, 97% of those own it
https://www.salliemae.com/content/dam/slm/Media/images/Research/Majoring-In-Money-Report-2019.pdf: 85% of college students carry a debit card
https://www.emarketer.com/content/most-americans-pay-mobile-apps: 77% of US adults 18 to 29 pay for at least one app subscription
https://research.missionsq.org/content/media/document/2025/6/113053_How%20Teens%20Handle%20Money_S.pdf: only 9.4% of US teens 13 to 18 have used a debit card
https://www.pewresearch.org/internet/2025/11/20/americans-social-media-use-2025/: Reddit reaches 48% of 18 to 29 year olds versus 17% of teens
https://www.pewresearch.org/internet/2026/04/15/teens-experiences-on-tiktok-instagram-and-snapchat/: teen platform use and product research on TikTok
https://screenfast.app/blog/indie-ios-app-marketing-strategy-2026: about 60% of App Store downloads come from search
