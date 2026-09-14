# BetterCampus: every feature vs. what students actually said

Grid of all 100 shipped features (per the 9.8.11 teardown) against coded evidence from three
sources: 361 Reddit rows (91 threads, deduped by author), a pre-Reddit pass of Chrome/Firefox
reviews and the feedback board, and today's public research (changelog, Featurebase, Campy).
No web search was run for this file; nothing here is invented — a blank cell means no source
read named that feature.

## Summary

1. **Most loved** (distinct people / upvotes, Reddit): theme marketplace & customization (22/97),
   the to-do list (16/131), dark mode (5/83), the GPA calculator (4/62), streak tracking (4/1 —
   small, but real, and it rebuts the "streaks read as childish" claim from the earlier pass).
2. **Most hated**: Files AI / AI tools generally (19 people/169up), the rebuilt theme editor —
   lost custom CSS, can't save (18/90), Pro subscription billing/paywall (16/89), the contrast
   checker that blocks saving your own colors (13/77), account login (13/31, mostly failures).
3. **Nobody asked for this** — shipped, zero positive mentions anywhere in 361 rows, the
   feedback board, or store reviews: **Campy** (the pet/habitat mascot layer), the **Chrome
   Dino easter-egg game**, and the **Quote/Music/Breathe widget trio**.
4. The single biggest complaint in the whole corpus isn't a named feature at all — it's
   **"bloat," the 2026 redesign in general: 34 distinct people, 326 upvotes.**
5. **73 of the 100 shipped features have no student signal at all**, for or against, in any
   source read (70 zero-signal + 3 with only a qualitative store/board mention, no Reddit count).
6. Old BetterCanvas-era features draw far more love per mention (27 people/278 upvotes) than
   new-suite features (30 people/109 upvotes) — see "Old simple vs. new suite" below.
7. New-suite features draw three times the opposition of old ones: 502 upvotes across 95
   people, vs. 165 upvotes across 41 people for old features.
8. Reddit quotes below are **paraphrased**, per the workbook's own rule (authors can't
   reproduce others' Reddit comments verbatim); genuine verbatim quotes come from the earlier
   Chrome/Firefox/feedback-board pass and are marked "pre-Reddit pass."
9. The contrast checker and the lost-custom-CSS complaints are self-inflicted: an accessibility
   rule now blocks students from saving their own theme colors.
10. Full 100-row grid, the old-vs-new math, and the bloat quotes in students' own words are below.

## Old simple vs. new suite

"OLD" = present in BetterCanvas before the ~March 2026 rebuild (8.1.0, which rebuilt themes
from scratch and introduced AI study tools): dark mode, presets, card images/colors, the to-do
sidebar, card assignments/grades, GPA, what-if, sidebar cleanup, custom font, condensed cards,
universal search, and other basic utility toggles. "NEW" = added since: the theme
marketplace/editor, stickers, cursors, AI (notes/Files AI/transcription/flashcards/Study),
Planner, calendar sync, the Quote/Music/Breathe/Notes/Doge widgets, streaks + restores,
celebrations, Campy/pet/habitat, Wrapped, the notifications hub, referrals, and account/Pro.
Some features not named in the coordinator's examples were classified by changelog date or by
description; that judgment call is flagged in the Method section.

| | Distinct people FOR | Upvotes FOR | Distinct people AGAINST | Upvotes AGAINST |
|---|---:|---:|---:|---:|
| **OLD features** (40 of the 100) | 27 | 278 | 41 | 165 |
| **NEW features** (60 of the 100) | 30 | 109 | 95 | 502 |

Old features get fewer people but far more love-per-person (278 upvotes across 27 people =
~10 upvotes/person). New features get slightly more people saying something positive, but a
fifth as much love-per-person (109/30 = ~3.6/person) and 5x the upvotes in opposition. The
same 40 old features draw less than a third of the negative weight the 60 new features draw.

**The three most-upvoted rows that explicitly say they'd keep the old, simple version over
the new AI/suite** (verbatim, feedback board — the pre-Reddit source, not Reddit paraphrase):

1. *"Just change it back"* — 34 upvotes, feedback board.
2. *"im sorry but were litearly college students...."* — 30 upvotes, feedback board, on the
   $20/month price.
3. *"Keeping it simple"* — 21 upvotes, feedback board.

---

## The full grid

One row per shipped feature, grouped by area, sorted by feature number. Free/Pro is copied
from the teardown's own gating determination. Era is OLD/NEW per the rule above. A dash means
no source read named that feature. Verdict is exactly one of LOVED / USED / NO SIGNAL / BLOAT /
HATED, per the strict rule: BLOAT only when a row names that specific feature as unwanted
(AI, notes, flashcards, planner, widgets, streaks, account, paywall, theme editor, calendar
sync); general "bloat" or "revert the update" complaints that don't name a feature are **not**
attributed to any single row here — they're covered in "Old simple vs. new suite" and the
quotes section below instead.

| Feature | Free/Pro | Era | Distinct people for | Upvotes for | Distinct people against | Upvotes against | Best quote | Verdict |
|---|---|---|---:|---:|---:|---:|---|---|
| **Dashboard & to-do** | | | | | | | | |
| #15 Better to-do list (Canvas planner feed) | Free | OLD | 16 | 131 | 7 | 14 | "Easier to view when everything is due, rather than navigate every page." — Firefox add-on review, 5★ (pre-Reddit pass) | **LOVED** |
| #16 To-do Day/Week/Month/Custom views | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #17 Overdue-item visibility window | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #18 Progress ring/bar (8 styles) | Free | OLD | — | — | — | — | "i like how i can see what percentage i need to finish" — Chrome Web Store review, Sep 9 2026 | **LOVED** |
| #19 Hide completed tasks | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #20 Relative due dates | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #21 Todo reminders | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #22 New Assignment / custom task (with recurrence) | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #23 Custom task types (global + per-course) | Free, <=10/course | OLD | — | — | — | — | — | **NO SIGNAL** |
| #41 Widget: "Doge" meme clicker | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #70 Custom-task overrides sync | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #94 Assignment-row details button + status classification | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #96 Custom section injected into assignment groups | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| **Cards** | | | | | | | | |
| #24 Card tasks (assignments under course cards) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #25 Card grades | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #26 Grade-pill click destination | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #27 Hover-only grade reveal (privacy) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #28 Condensed cards | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #29 Card images/colors/gradients/roundness/size | Free | OLD | — | — | 6 | 11 | Course card photos keep turning into solid colors. (paraphrase) — Reddit r/bettercampus, 2up | **HATED** |
| #30 Card create-course button, bookmark icons | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #31 Dashboard card limit (25) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #93 Course-home "Customize/Edit" CTA | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| **Grades** | | | | | | | | |
| #36 Widget: Grades / GPA / GPA Trend | Free (remote flag) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #44 GPA calculator (current + cumulative) | Free | OLD | 4 | 62 | 2 | 4 | Only used the to-do list and grades; the update made them feel they had to relearn Canvas. (paraphrase) — Reddit r/bettercampus, 5up | **LOVED** |
| #45 Weighted GPA (school-level Honors/AP flag) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #46 Import a past-semester GPA (manual entry) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #47 Import a past transcript (AI-parsed) | Requires account | NEW | — | — | — | — | — | **NO SIGNAL** |
| #48 What-If grades simulator | Free | OLD | — | — | — | — | — | **USED** |
| #49 Grade Trends chart (per-semester GPA history) | Free (remote flag) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #50 Goals (per-class + per-semester target grade) | Free (data model only) | NEW | — | — | 1 | — | "So much stuff is now behind a paywall, like the GPA goals." — BetterCampus feedback board (pre-Reddit pass) | **BLOAT** |
| #51 "Reset All Goals?" confirmation | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #52 Assignment-group weighting (real Canvas weights) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #53 Grade history CSV/JSON export | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #69 Syllabus import/parsing (auto-detect grade cutoffs) | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #97 Grades-page sidebar-width layout fix | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| **Themes & looks** | | | | | | | | |
| #1 Dark mode (manual toggle) | Free | OLD | 5 | 83 | 4 | 7 | "Makes it much easier on the eyes (I hate canvas OG color scheme)." — Chrome Web Store review, Sep 9 2026 | **LOVED** |
| #2 Dark mode presets (Lighter/Darker) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #3 Community theme marketplace (browse/like/comment) | Free to browse | NEW | 22 | 97 | — | — | "ITS SO CUTE YALL ARE DOING THE LORD'S WORK" — Chrome Web Store review, Sep 9 2026 | **LOVED** |
| #4 Apply a community theme, logged out (5 free swaps) | Free (5 swaps) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #5 Apply a community theme, logged in on Free (swap cap) | Pro-gated | NEW | — | — | 2 | 7 | Each theme tweak spends one of six free swaps, and pop-ups hide the preview so they must save just to see changes. (paraphrase) — Reddit r/bettercampus, 5up | **BLOAT** |
| #6 Save a custom theme (Pro-gated past a cap) | Pro-gated | NEW | — | — | 18 | 90 | "All of my cute custom themes that I spent hours on are all gone :( I feel heartbroken." — BetterCampus feedback board, 23up (pre-Reddit pass) | **HATED** |
| #7 Theme History (recent applied themes) | 2 free, then Pro | NEW | — | — | — | — | — | **NO SIGNAL** |
| #8 Scheduled dark mode (time window / match-device) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #9 Custom fonts (Google Fonts, 36 curated + free-text) | Free | OLD | 2 | 2 | — | — | Picks bold fonts and specific color pairings to help reading comprehension, matching how they take notes. (paraphrase) — Reddit r/bettercampus 'ADHD themes' thread | **USED** |
| #10 Custom cursors | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #11 Theme stickers (3 free, then Pro) | Free up to 3 | NEW | — | — | — | — | — | **NO SIGNAL** |
| #12 Contrast/readability checker (blocks saves) | Free | NEW | — | — | 13 | 77 | "It's their Canvas; customization should be up to them." — BetterCampus feedback board, 8up (pre-Reddit pass) | **HATED** |
| #13 Theme auto-rotate on a schedule | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #14 Apply the active theme to bettercampus.com | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #37 Widget: Theme showcase | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #63 PDF/document viewer dark mode (canvadocs) | Free | OLD | — | — | 1 | 5 | "It doesn't affect it at all and whenever I go to take a quiz I feel like I just got flash banged." — BetterCampus feedback board, 5up, still Under Review (pre-Reddit pass) | **HATED** |
| #92 RCE (Rich Content Editor) dark mode | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| **Sidebar & navigation** | | | | | | | | |
| #32 Universal search (Cmd/Ctrl+K) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #54 Sidebar (courses/pages/widgets rail) | Free | OLD | — | — | 9 | 48 | "I can no longer take notes, view my grades, open my planner… without having to open the chrome extension, which takes much longer." — BetterCampus feedback board, re: v9.3.0 (pre-Reddit pass) | **HATED** |
| #55 Sidebar collapse/expand, width/density/icon-scale | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #56 Hide School Logo | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #57 Hide BetterCampus Logo (confirmation flow) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| #98 Nav-badge sync (Calendar/Conversations/Groups) | Free | OLD | — | — | — | — | — | **NO SIGNAL** |
| **Planner/Notes/Study/AI** | | | | | | | | |
| #33 Widget: Planner | Free | NEW | — | — | 1 | 2 | Too much UI on screen; doesn't want planner, notes, grades or study in the sidebar. (paraphrase) — Reddit r/bettercampus, 2up | **BLOAT** |
| #34 Widget: Notes | Free up to a cap | NEW | — | — | — | — | — | **NO SIGNAL** |
| #35 Widget: Study overview | Free (remote flag) | NEW | — | — | 1 | 2 | Too much UI on screen; doesn't want planner, notes, grades or study in the sidebar. (paraphrase) — Reddit r/bettercampus, 2up | **BLOAT** |
| #38 Widget: Quote carousel | Pro-gated (account) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #39 Widget: Music player (Spotify/YouTube/Apple Music) | Pro-gated (account) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #40 Widget: Breathe (guided breathing) | Pro-gated (account) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #43 Lecture-recording widget | Free (undocumented) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #58 Notes (rich text course notes, folders) | Free up to a cap | NEW | — | — | — | — | "Keeping notes for each class is a very good idea, since Canvas is not good at saving your work." — Chrome/Firefox review (pre-Reddit pass) | **USED** |
| #59 Smart Notes (AI note enhancement) | Entitlement-capped | NEW | — | — | — | — | — | **NO SIGNAL** |
| #60 Files AI (AI document chat, GPT-4o-mini) | Free trial then Pro | NEW | — | — | 19 | 169 | Says it went from a polished student project to bloat with AI features nobody asked for. (paraphrase) — Reddit r/bettercampus, 13up | **BLOAT** |
| #61 Lecture transcription (AI, Groq) | Free trial then Pro | NEW | — | — | 1 | 1 | Doesn't think it's right that AI features can't be disabled; can make flashcards and transcripts without AI. (paraphrase) — Reddit r/chrome_extensions, 1up | **BLOAT** |
| #62 Study Sets (flashcards), Study Sessions | Entitlement-capped | NEW | — | — | 2 | 3 | Doesn't think it's right that AI features can't be disabled; can make flashcards and transcripts without AI. (paraphrase) — Reddit r/chrome_extensions, 1up | **BLOAT** |
| #64 PDF annotations (6 tools, requires account) | Requires account | NEW | — | — | — | — | — | **NO SIGNAL** |
| #65 AI "Explain selected text" | Tied to Files AI gating | NEW | — | — | — | — | — | **NO SIGNAL** |
| **Gamification** | | | | | | | | |
| #42 Widget: Pet / virtual-pet habitat ("Campy") | Gating not confirmed | NEW | — | — | — | — | — | **NO SIGNAL** |
| #73 Streak tracking (server-validated) | Free | NEW | 4 | 1 | 1 | 1 | Four valued streaks, one lost a 450-day streak (see #74); one dismissed gamification outright. (paraphrase, aggregated) — Reddit corpus, Summary tab section 3a | **USED** |
| #74 Streak restore after a break (Pro-gated, 48hr) | Pro-gated | NEW | — | — | 2 | 17 | Lost a 450-day streak even though the switch pop-up said it would sync. (paraphrase) — Reddit r/bettercampus, 1up (thread up to 16up) | **HATED** |
| #75 Streak rarity/percentile stat | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #76 Celebration animations (confetti/fireworks/etc.) | Free | NEW | — | — | 1 | 1 | Has no interest in gamification or dopamine-style features and turns off streaks and celebrations on every machine. (paraphrase) — Reddit r/bettercampus, 1up | **BLOAT** |
| #77 Celebration sound effects (built but inert) | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #78 "Wrapped" yearly recap | Backend live, frontend unclear | NEW | 1 | 5 | 1 | 6 | "I absolutely love this feature—it's weirdly motivating seeing everything broken down like this." — BetterCampus feedback board, 5up (pre-Reddit pass) | **LOVED** |
| #79 Referral program (invite a friend) | N/A — 14-day trial both sides | NEW | — | — | — | — | — | **NO SIGNAL** |
| #80 Friends (social) | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #99 Chrome Dino game easter egg | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| **Calendar sync** | | | | | | | | |
| #66 Calendar sync — Google | Free | NEW | — | — | 1 | 2 | Can't remove the Google Calendar sync button they never use. (paraphrase) — Reddit r/bettercampus, 2up | **BLOAT** |
| #67 Calendar sync — Outlook/Microsoft | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #68 Google Calendar "Tasks" auto-enable | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #95 Assignment-page calendar "Sync" button | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| **Settings/other** | | | | | | | | |
| #71 Quiz Safe Mode (suppresses theme, opt-in) | Free | OLD | — | — | 12 | 76 | Installed it to make Canvas look better; during a final exam quiz it lagged the timer and blocked submission, forcing a paper redo. (paraphrase) — Reddit r/UTMississauga, 26up | **HATED** |
| #72 Marketing-popup suppression during quizzes | N/A | NEW | — | — | — | — | — | **NO SIGNAL** |
| #81 "Wall of love" testimonials asset | Free (read-only) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #82 Account login (passwordless email OTP) | N/A | NEW | — | — | 13 | 31 | Every time they open Canvas it plays an animation and asks them to sign in; will uninstall if an account becomes mandatory. (paraphrase) — Reddit r/bettercampus, 3up | **HATED** |
| #83 Free trial (7 days standard) | N/A | NEW | — | — | 2 | 4 | Tried to cancel the free trial and ended up on paid Pro; asks how to get a refund. (paraphrase) — Reddit r/bettercampus, 3up | **HATED** |
| #84 Subscription billing (Stripe Checkout) | N/A | NEW | — | — | 16 | 89 | "im sorry but were litearly college students...." — BetterCampus feedback board, 30up, re: $20/mo (pre-Reddit pass) | **HATED** |
| #85 Billing portal, invoice history, pause/cancel/resume | N/A | NEW | — | — | — | — | — | **NO SIGNAL** |
| #86 Push/email notification preferences (12 categories) | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #87 Onboarding tours (per-feature) | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #88 Age verification | N/A (compliance) | NEW | — | — | — | — | — | **NO SIGNAL** |
| #89 QR cross-device login handshake | Free | NEW | — | — | — | — | — | **NO SIGNAL** |
| #90 Anonymous usage analytics (PostHog, opt-in default) | Opt-in by default | OLD | — | — | — | — | — | **NO SIGNAL** |
| #91 Uninstall feedback survey | N/A | OLD | — | — | — | — | — | **NO SIGNAL** |
| #100 Multi-LMS support (Blackboard/Moodle/Brightspace/etc.) | Free | NEW | 3 | 6 | — | — | Says it was a lifesaver as a freshman; their college moved to Brightspace and they're begging for support there. (paraphrase) — Reddit r/bettercampus, 3up | **USED** |

---

## What "bloat" means in their own words

The most-upvoted bloat/useless/annoying rows, verbatim where the source is genuinely verbatim
(feedback board / store review, pre-Reddit pass) and clearly marked paraphrase where the source
is the Reddit workbook (whose own method note says every comment is paraphrased, never quoted,
because authors can't reproduce someone else's Reddit writing word-for-word).

1. *"Just change it back"* — **34 upvotes**, feedback board. Names: the redesign in general.
2. *"The whole reason for the extension was to make life easier, not harder."* — same post,
   feedback board. Names: the redesign in general.
3. *"im sorry but were litearly college students...."* — **30 upvotes**, feedback board, on
   $20/month. Names: **subscription billing / Pro price (#84)**.
4. *"So much stuff is now behind a paywall, like the GPA goals."* — feedback board. Names:
   **Goals (#50)** and the Pro paywall generally.
5. *"Keeping it simple"* — **21 upvotes**, feedback board. Names: the redesign in general.
6. *"Less is more... it almost feels like opening FL Studio for the first time."* — feedback
   board, same complaint thread. Names: the redesign's UI density in general.
7. *"The new layout is really bad — it's SO bloody hard to navigate."* — feedback board.
   Names: **the sidebar/navigation rebuild (#54)**.
8. *"I can no longer take notes, view my grades, open my planner… without having to open the
   chrome extension, which takes much longer."* — feedback board, re: v9.3.0. Names: **the
   sidebar (#54)** burying features behind extra clicks.
9. *"I'm scared, what is this update?"* — **14 upvotes**, feedback board: *"streaks (really?
   am I a 12 year old on snapchat…no, no im not.)"* Names: **streaks/celebrations (#73/#76)**
   — flagged as the one claim Reddit does **not** corroborate (see caveat below).
10. Says it went from a polished student project to bloat with AI features nobody asked for
    (paraphrase, Reddit r/bettercampus, 13 upvotes, one of 19 distinct people making this
    complaint). Names: **AI tools (#60 and siblings)**.

**Caveat on #9**: the earlier Chrome/Firefox/board pass concluded streaks read as childish to
college students, based on this one 14-upvote board post. The Reddit pass does not support
that: across 361 coded rows, exactly **1** person dismissed gamification, while **4** distinct
people said they valued their streak or were upset to lose one, and the loudest streak-related
row (16 upvotes) is a complaint about the migration *losing* streak data, not about streaks
being embarrassing. Streaks were not the problem; losing streak data was.

## What students would keep if they could only keep three

Three separate Reddit posts converge on the same list — to-do, dark mode, grades — as the
whole product. These are **paraphrases**, per the workbook's own rule (Reddit comments are
paraphrased throughout, never quoted).

1. Old version gave them assignments on the home page, a to-do list, grades and dark mode —
   they say that was all most people needed. (paraphrase, r/bettercampus, **19 upvotes**)
2. Most users don't care about Pro, AI or a new interface; they only want the to-do list, dark
   mode and grades. Proposes a separate lite extension and a pro one. (paraphrase,
   r/bettercampus, **18 upvotes**)
3. Just wants a lite tool for dark mode, hiding past courses and custom fonts — doesn't need a
   planner or AI. (paraphrase, r/bettercampus, **23 upvotes**)

Read together with the "Old simple vs. new suite" math above, this is the same message twice:
old, simple, three-feature BetterCanvas is what most vocal students actually wanted, and the
2026 rebuild added weight (AI, planner, widgets, gamification, an account) without asking.
**Caveat**: one especially prolific Reddit voice (labeled V001 in the workbook — 6 entries,
68 cumulative upvotes) wrote both the #19-upvote "old version had it all" post and the
18-upvote "just ship a lite version" comment above, so this trio leans on one person more than
the raw quote count suggests. The Summary tab of the workbook flags this explicitly.

## Method

- **Corpus**: 361 coded evidence rows from `BetterCampus_Reddit_Evidence.xlsx` (91 Reddit
  threads read as full comment trees, pulled Sep 10, 2026), plus the pre-existing
  Chrome/Firefox/feedback-board pass in `research-bettercampus-likes.md` and today's public
  research pass (`BETTERCAMPUS-PUBLIC-2026-09.md`) for company-stated facts (Campy, changelog
  dates, theme-marketplace counts).
- **Dedup**: distinct-people counts use the workbook's own `Voice` column (one anonymized
  label per Reddit account) and only rows marked `Tally = Y` — the workbook itself excludes
  BetterCampus team-account posts, the CanvasRefined developer's repeated plugs, a Canvas
  admin's cross-posted warnings, and posts whose upvotes are actually about something else
  (e.g., an r/opensource licensing fight). Upvotes are summed on tallied mentions, not deduped
  per person (the workbook's own convention: "a comment naming three things appears once under
  each of those three themes"). A few feature rows in this grid intentionally share the same
  underlying evidence row where one Reddit post names two sibling features in one sentence
  (e.g., "doesn't want planner, notes, grades or study" feeds both the Planner and Study widget
  rows) — this mirrors the workbook's own per-theme counting, not an error.
- **Columns in the workbook's Evidence tab**: #, Section, Theme (30 coded themes), Stance
  (Positive/Negative/Mixed/Context/Lost data), Rebrand topic, paraphrase text, Upvotes, Voice,
  Tally (Y/N), Type (Post/Comment), Subreddit, Thread title, Date, Permalink status, Item ID,
  Thread ID, Primary row, and a same-person flag.
- **Mapping 30 corpus themes onto 100 product features**: themes that map cleanly onto one
  feature (Contrast checker, Streaks, Account and login, Dark mode, To-do list regressions,
  Firefox/Edge, Brightspace) use that theme's validated distinct-people/upvote totals directly.
  Broader themes (Bloat, AI features, Theme editor and card images, Paywall) were read
  row-by-row; evidence was attributed to a specific feature only when the row's own text named
  it, per the task's strict rule — otherwise it stayed general and is reported in the "bloat in
  their own words" section instead of inflating a feature row.
- **Verbatim vs. paraphrase**: the Reddit workbook's own Method tab states every entry is a
  paraphrase, because the source material can't legally/practically be reproduced word-for-word
  beyond a line or two — confirmed by a scan of all 361 rows for embedded quotation marks
  (zero found). Genuinely verbatim, quoted lines in this file all come from the earlier
  Chrome Web Store / Firefox / feedback-board pass, marked "pre-Reddit pass" throughout.
- **Era classification**: the coordinator supplied explicit OLD and NEW examples (see the "Old
  simple vs. new suite" section). Features not on either list were classified using the
  changelog in `BETTERCAMPUS-PUBLIC-2026-09.md` (dated entries from 8.1.0, Mar 4 2026, through
  the Jun 30 2026 referral launch) where a feature was named there, and by best-effort judgment
  otherwise (e.g., basic utility toggles like nav-badge sync or the uninstall survey were
  treated as OLD absent evidence they were added later). This is a defensible best-effort
  classification, not a verified one for every row.
- **Not measurable**: which of the 100 features individually drove any of the 34-person,
  326-upvote general "bloat" complaint (most of those rows name no specific feature); precise
  screenshot-based UI captions; the Featurebase board's true "Top" sort (only a partial pull
  was retrievable); Edge/Firefox user reactions specifically (evidence exists for the
  Firefox/Edge *gap*, not for feature-level sentiment on those platforms); and sentiment on any
  feature outside the 100-item teardown list (e.g., a Chrome Web Store "Timer" widget mentioned
  in company marketing copy but not itemized in the teardown was excluded rather than force-fit
  into a row).
