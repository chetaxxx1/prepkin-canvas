# Prepkin facts — updated 2026-09-10

## What it is
Prepkin is two things that pair with each other:
1. A Chrome extension that reskins Canvas (the LMS most US colleges run) and can
   send coursework to the phone app.
2. An iPhone app where a pet fish called Sprout lives in a tank the student
   decorates.

## The reward loop — read this twice, it is the most-misdescribed part
Sprout does NOT eat. There is no food, no hunger, no feeding, no meter. Verified in
the code on 2026-09-10: no feed function, no hunger state, no food asset exists.

What actually happens:
- Finish a Canvas task and you earn 30 coins. A study task earns 20.
- The coins fly up over the tank on the Home screen. That is the whole moment.
- Coins buy things: the five tank scenes (Lagoon is free, then Reef 200, Kelp 220,
  Dusk 250, Deep 280), costumes, and looks.

So the sentence is "finish an assignment, get coins, buy Sprout a nicer tank."
NEVER write "feed Sprout", "Sprout eats", "Sprout is hungry", or "fish fed".

The Learn section holds 57 life-skills lessons for undergrads — finance, study,
psychology, philosophy, people, work. Titles like "Why compound interest wins",
"Credit scores, plainly", "Your employer's match is free money".

## What it is NOT
Prepkin is NOT an SAT app and NOT a test-prep app. It was one once. It is not now.
NEVER describe it as SAT prep, test prep, or exam prep.

## Who it is for
US college undergrads, 18 to 22, whose school runs Canvas, who own the laptop they
use, browse in Chrome, and own their own iPhone. About 2.9 million people.

High schoolers are the bigger group but cannot be sold to: their laptop is a
district-managed Chromebook that blocks unapproved extensions, and only 9.4% of
teens have ever used a debit card, so Ask to Buy routes any purchase to a parent.
High schoolers stay free forever. They are the ones who make the videos.

## Money
Prepkin Plus: $9.99 per month or $69.99 per year. Annual is the default option.
There is no lifetime tier. (Raised from $3.99/$19.99 on 2026-09-09; yearly moved
from $79.99 to $69.99 on 2026-09-10. Source of truth: design/PLUS-SPEC.md section 5.)

Plus buys speed, slots and convenience only. Plus NEVER sells items, pets, or
anything cosmetic. If a subscription lapses the student keeps everything she has,
and the shop simply goes back to refreshing once a day instead of more often.

The trial is a gift, not a gate: seven free days fire when she finishes her third
assignment. The paywall then appears exactly once.

## Positioning
The headline for the Canvas skin is "reads nothing, sends nothing." The skin makes
zero external network requests — no CDN fonts, no CDN images, no analytics. It is
pure CSS over Canvas's own markup.

Context: in April 2026 Canvas was breached. 8,809 institutions, roughly 275 million
users, 3.65 TB taken. Instructure traced it to Free-for-Teacher accounts and
permanently discontinued that tier. A school security review in late 2026 will not
carefully separate "extension that reads Canvas data" from "the thing that leaked
275 million records". The zero-data claim is the lead, not a footnote.

The Canvas-to-phone sync is a SEPARATE half of the product from the skin, and the
two stay separable so a school can allow one without the other.

## The competitor
BetterCampus. It went the opposite way — `<all_urls>` permissions and 1,863
hotlinked Pinterest images — and was blocked district-wide at Sequoia Union HSD.

## The honest numbers (2026-09-07 forecast, not a target)
By 2026-12-31: about 760 extension installs, 220 app users, 0 to 1 paying
subscribers, about $20 in revenue. A breakout video adds only 2 to 5 payers.

Fall 2026 is a proof cohort, not a revenue quarter. Its job is a live listing, a
non-zero review count, and a MEASURED pairing rate. January is what monetises.

Three rates carry the whole forecast and all three are currently guesses:
- view to install: 0.15%
- install to paired with the phone app: 15%
- paywall seen to paid: 1.5%
Measuring these is worth more than any single campaign.

## Known blockers, as of 2026-09-10
- The slime blocker is CLEARED. It was fixed in commit edf422c, "Extension draws
  Sprout, not the slime", and the word "slime" now appears nowhere in the extension
  code. The extension UI is fine to show on camera. Any instruction to crop the
  slime out or to avoid the extension is out of date — ignore it.
- The Chrome data declaration must NOT say "no data collected". Coursework and
  course grades are sent by the sync half. A false declaration is a removal offence.
- The Chrome Featured badge does not exist any more. Google closed self-nominations
  on 2026-08-20 and is sunsetting the programme. It cannot be part of any plan.
- There is no theme editor, so students have nothing of their own to publish. The
  share unit is a Look Card image plus a six-character palette code. No upload, no
  server.

## The five tank scenes, by their real names and prices
Lagoon (free), Reef (200 coins), Kelp (220), Dusk (250), Deep (280). Deep is the
only dark one. They are called SCENES, not backgrounds or rooms. Four of the five
cost coins, so nobody switches them casually — do not write copy implying a student
flips between them for free.

Careful: Reef, Lagoon, Kelp, Dusk and Deep are ALSO the league tier names. A tank
scene and a league tier are different things that share a word.
