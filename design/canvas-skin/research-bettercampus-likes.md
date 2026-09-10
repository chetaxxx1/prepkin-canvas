# What students actually LIKE about BetterCampus

Fresh sentiment sweep, 2026-09-09. Updates `BETTERCAMPUS-PARITY.md`, whose feature list
was a Nov-2024 source read with no live web check. This pass is live.

## Corrections after the Reddit pass (2026-09-10) — this section wins

A Reddit sweep ran in George's logged-in Chrome the next day: 22 searches, **91 threads
read as full comment trees**, **361 coded evidence rows**, deduped by author. Workbook:
`~/Downloads/BetterCampus_Reddit_Evidence.xlsx`. Three claims below were wrong.

1. **"Themes are motivation, not decoration" — mostly wrong.** Reddit students describe
   themes as *looks*: a less sterile dashboard, a cute Canvas, dreading plain Canvas,
   classmates noticing it in lecture. Motivation and focus appear, but in a handful of
   low-vote comments, and even there the looks are the cause. Themes are still **the #1
   liked thing (22 distinct people, 97 upvotes)** — just don't sell them as a study aid.
2. **"Streaks read as childish to college students" — not supported.** Streaks barely
   come up. **One** person dismissed gamification. Four valued streaks, one lost a
   450-day streak, and the loudest streak row (16 upvotes) is about the migration
   *losing* streak data. The 14-upvote "am I a 12 year old on snapchat" line came from
   their feedback board, not Reddit, and Reddit does not echo it.
3. **"Dark mode is unfinished on quizzes" — no evidence either way on Reddit.** Reddit's
   dark-mode complaints are styling leaking into other tabs and failing to load. Quiz
   trouble on Reddit is *functional*, and much worse than cosmetic — see the exam PSA
   below. The store/board evidence for the white-quiz complaint still stands on its own.

## Sources actually read

| Source | What I got |
|---|---|
| Chrome Web Store reviews page (live) | 10 verbatim reviews, all dated Sep 9 2026. **2,000,000 users**, 4.7 / 4.3K ratings. Browser pane kept dropping, so this is the recent-first slice only, not a full pull. |
| Firefox add-on reviews | 25 reviews, ~2 years deep, with stars |
| `feedback.bettercampus.com` (public Featurebase board) | ~40 posts with real upvote counts and status labels. **This is the best signal on the page** — students upvote what they want, and the counts are public. |
| ExtSpot review-derived analysis | Aggregate positive/negative themes across a larger review sample |
| Store listing, pricing page, changelogs 8.0-9.4 | What the company itself says students love, and what moved behind the paywall |
| **Reddit** | **NOT REACHED.** Reddit 403s the search JSON, blocks reader proxies, is delisted from Exa, and is blocked by policy in the in-app browser. Nothing below is from Reddit. |

Version facts: extension is on **9.8.1, updated Aug 11 2026**. Pro is **$119/yr**
(a student post quotes "$20 a month", so a monthly tier exists or existed at that price).

---

## The seven things students say they love

Ranked by how often it shows up and how strongly it's worded.

### 1. Dark mode — the entry drug
Named in almost every positive review and in the store listing's own first bullet.
It is *why people install*, not why they stay.

> "Makes it much easier on the eyes (I hate canvas OG color scheme)." — Chrome, Sep 9 2026
> "Almost no CPU overhead, no artifacts... huge set of custom themes." — Firefox, 5★

**But it is their #1 unfinished job.** Quizzes stay white:
> "It doesn't affect it at all and whenever I go to take a quiz I feel like I just got
> flash banged." — feedback board, 5 upvotes, still "Under Review"

Also flagged on Firefox 2 years ago: *"parts that dark mode doesn't affect properly...
text color won't change."* Prepkin's parity doc already lists same-origin iframe dark
mode (DocViewer/Canvadocs) as gap #4 — this confirms it is a live, unfixed wound.

### 2. Themes — the emotional core, far more than decoration
This is the strongest feeling in the whole corpus, and it is not about looks. It is
about *ownership* and *motivation*.

> "All of my cute custom themes that I spent hours on are all gone :( I feel heartbroken.
> My cute designs made me feel so much more motivated to work." — **23 upvotes**
> "Been using it for years... So so so many cool themes." — Firefox, 5★
> "ITS SO CUTE YALL ARE DOING THE LORD'S WORK" — Chrome, Sep 9 2026
> "Love that I actually want to look into my classes LOL!" — Chrome, Sep 9 2026

Note the mechanism students report: a page they made theirs is a page they open. That is
a retention argument, not an aesthetic one.

Requests on the board are all *more* theming: auto-rotate favourited themes seasonally,
themes that auto-apply to newly added courses, per-course background colour behind the
grade pill, text highlighters in any RGB colour.

### 3. Everything due, in one place, without clicking each course
The single most-cited *functional* win.

> "Easier to view when everything is due, rather than navigate every page." — Firefox, 5★
> "Presents my tasks and assignments in a way that makes it easy to keep up with!"
> "Easy layout and very useful features and widgets, like the to-do list and grades at a glance."

Top request in this family: put it in the **Chrome side panel** so it doesn't need a
Canvas tab open at all ("most students already have a bookmark for canvas").

### 4. Visible completion — the progress ring
Students describe a feeling, not a feature.

> "I love that it tells me what tasks I have completed and how much I've done; it makes
> me feel like I'm really getting things accomplished. 100000/10." — Chrome, Sep 9 2026
> "i like how i can see what percentage i need to finish" — Chrome, Sep 9 2026

The two loudest bugs on the board are both *this breaking*: submitted work not crossing
off the course card (9 upvotes), and the to-do list silently filtering assignments out
(3 upvotes). When the progress signal lies, the whole thing loses its point.

### 5. Grades at a glance, GPA, and what-if
Grades on the dashboard card, a GPA calculator, and per-assignment what-if. Consistently
praised, and the board's asks are all *precision* asks, not new features:

- Let letter grades have **+ and −**, not just flat A/B (7 upvotes)
- Support **non-US scales** — ECTS goes A B C D E (Fx) F, there is no E option
- Support a **100-point GPA** system
- What-if should handle a **0-point assignment**

### 6. Canvas Wraps — the one feature that produced actual delight
A Spotify-Wrapped-style end-of-term recap.

> "I absolutely love this feature—it's weirdly motivating seeing everything broken down
> like this... It would also be really cool to see comparisons." — 5 upvotes

The only unambiguously happy feature post on the board. Worth stealing the *shape*:
periodic, reflective, shareable, zero daily nagging.

### 7. Small tools that quietly stuck
- **The timer.** *"The timer is actually so helpful, and I want to keep using it"* — from
  a post otherwise asking them to move it out of the way.
- **Per-class notes.** *"Keeping notes for each class is a very good idea, since Canvas is
  not good at saving your work."*
- **Editing an assignment's due time or point value locally** — called out as a feature
  the reviewer hadn't even thought to want.

---

## What they hate — the opening

BetterCampus rebuilt itself into a paid productivity suite in early 2026. The board is a
revolt. This is the part that matters most for Prepkin's positioning.

| Complaint | Evidence |
|---|---|
| **Bloat.** Canvas is now *harder* than without it | *"Just change it back"* — **34 upvotes**. *"The whole reason for the extension was to make life easier, not harder."* |
| **Wanting the old simple version** | *"Keeping it simple"* — **21 upvotes**. *"Less is more... it almost feels like opening FL Studio for the first time."* *"The new layout is really bad — it's SO bloody hard to navigate."* |
| **Paywall on what used to be free** | *"im sorry but were litearly college students...."* — **30 upvotes**, on $20/mo. *"So much stuff is now behind a paywall, like the GPA goals."* *"The timer is cool but u need pro to change it?! to me thats really silly… (i mean its a timer…)"* |
| **Losing saved work on update** | The 23-upvote heartbreak post above |
| **Gamification read as childish** | *"I'm scared, what is this update?"* — **14 upvotes**: *"streaks (really? am I a 12 year old on snapchat…no, no im not.)"* |
| **Hiding features behind the extension popup** | 9.3.0: *"I can no longer take notes, view my grades, open my planner… without having to open the chrome extension, which takes much longer."* |
| **Account required** | Changelog 8.5 itself: *"Locked features now clearly show what requires an account."* |
| **US-only assumptions** | ECTS grades, 100-point GPA |
| **Forced AI** | ExtSpot's negative themes list: *"Unwanted forced AI features"* |

Also notable: **14 upvotes for "Create a BetterCampus mobile app"** — *"see tasks coming
up on their phone + take class notes."* Their users are asking for the thing Prepkin
already is.

---

---

# The Reddit layer

Counts are **distinct people** (each account once), then mentions, then summed upvotes.
Small numbers — treat the ranking as signal, the magnitude as weak. r/bettercampus is the
main source and skews toward people with a problem.

## Liked, by distinct people

| # | Theme | People | Mentions | Upvotes | Top |
|---|---|---:|---:|---:|---:|
| 1 | Themes & customization | 22 | 24 | 97 | 23 |
| 2 | Assignment visibility & to-do list | 16 | 19 | 131 | 19 |
| 3 | **CanvasRefined (the free fork)** | 15 | 15 | 26 | 3 |
| 4 | The lightweight old version | 6 | 7 | 59 | 16 |
| 5 | Dark mode | 5 | 6 | 83 | 23 |
| 6 | Likes the new BetterCampus | 5 | 5 | 15 | 9 |
| 7 | Tasks for Canvas (rival, now merged in) | 5 | 5 | 32 | 17 |
| 8 | Grades & GPA on the dashboard | 4 | 6 | 62 | 19 |
| 9 | Streaks | 4 | 4 | 1 | 1 |
| 10 | Brightspace / other-LMS support | 3 | 3 | 6 | 3 |

The three top-voted "likes" are all the *same sentence* said by different people:

> Old version gave them assignments on the home page, a to-do list, grades and dark mode
> — all most people needed. — 19 upvotes
> Most users don't care about Pro, AI or a new interface; they only want the to-do list,
> dark mode and grades. Ship a lite one and a pro one. — 18 upvotes
> Just wants a lite tool for dark mode, hiding past courses and custom fonts. Doesn't
> need a planner or AI. — 23 upvotes

**That trio — to-do, dark mode, grades — is the whole product to these students.**

## Disliked, by distinct people

| # | Theme | People | Mentions | Upvotes | Top |
|---|---|---:|---:|---:|---:|
| 1 | Bloat / wants the old version back | **34** | 43 | **326** | 26 |
| 2 | **AI features** | 19 | 24 | 169 | 23 |
| 3 | Theme editor and card images | 18 | 19 | 90 | 25 |
| 4 | Paywall, upsell and price | 16 | 22 | 89 | 18 |
| 5 | Forced update: lost settings and themes | 14 | 15 | 134 | 26 |
| 6 | Account and login | 13 | 13 | 31 | 6 |
| 7 | **Contrast checker blocks theme saves** | 13 | 16 | 77 | 25 |
| 8 | **Breaks Canvas, exams, school blocks** | 12 | 14 | 76 | 26 |
| 9 | Pop-ups and UI takeover | 9 | 10 | 48 | 16 |
| 10 | Firefox / Edge support | 9 | 9 | 20 | 5 |
| 11 | Lag and slowness | 8 | 9 | **110** | 26 |
| 12 | To-do list regressions | 7 | 7 | 14 | 4 |
| 13 | Dark mode problems | 4 | 4 | 7 | 3 |

## Four things the store and the feedback board did not show

**1. AI is the second-biggest complaint (19 people, 169 upvotes).** Not the price — the
AI itself. *"AI features were switched on without consent."* *"Went from a polished
student project to bloat with AI features nobody asked for."* One student who likes the
customization asks only how to hide the AI.

**2. It broke a final exam, and schools are blocking it.** The single most-upvoted
negative row is a PSA:

> Installed it to make Canvas look better; during a final exam quiz it lagged the timer
> and blocked submission, forcing a paper redo. A nicer look isn't worth that.
> — r/UTMississauga, 26 upvotes

Plus a district blocking it outright, UC Davis blocking it, a Canvas admin warning
students off in three separate r/canvas threads, and questions about Honorlock conflicts.
**This is a whole risk axis neither earlier source showed.**

**3. Their contrast checker is a self-inflicted wound (13 people).** They added an
accessibility check that refuses to save a student's own theme.

> After the update all their saved themes vanished, and the contrast rule won't let them
> save the current one. — 8 upvotes
> It's their Canvas; customization should be up to them. — 8 upvotes
> The contrast rule forced them to replace a light-blue theme they'd loved for two years.

An accessibility feature that overrides the user reads as policing. Advise, don't block.

**4. A free fork is taking their users, in the open.** **CanvasRefined**, mentioned
positively by 15 distinct people (excluding its own developer's plugs). Its developer's
r/opensource post about the company pushing back has **588 upvotes**. *"Installed the
fork and deleted BetterCampus."* *"A godsend."* Also **Tasks for Canvas**, a rival to-do
extension people loved, which merged into BetterCampus in Aug 2026 and broke for its old
users. Prepkin is not the only thing aimed at this gap.

## The timeline, from Reddit

| When | What |
|---|---|
| Sep 2025 | Listing already reads "prev. BetterCanvas". Plans: Basic $0 (themes, GPA, to-do) vs Learn $8.25/mo |
| Nov 29 2025 | Team opens r/bettercampus, claims 2M+ students |
| Dec 2025 – Feb 2026 | Firefox and Edge versions promised "in about a month", repeatedly. Still not current Sep 2026 |
| **Apr 15–28 2026** | Long-time users force-updated **right before finals**. Six "give me the old version" threads in two weeks |
| May 13 2026 | Team: no revert, no toggle; paid features because **donations raised $64** |
| May 25–31 2026 | Team confirms **$19/mo or $119/yr**; says theme swaps will become free |
| Aug 5 2026 | CanvasRefined fork developer's r/opensource post — 588 upvotes |
| Aug–Sep 2026 | Back-to-school wave: contrast checker, Tasks for Canvas merged in, Brightspace launch, two students charged while cancelling the Pro trial |

Their official account replies to nearly every complaint and gets downvoted for it
(−11 in r/Professors, −6 in r/UTAustin).

---

## What this means for Prepkin

Rewritten after the Reddit pass.

1. **Ship the trio, loudly: to-do, dark mode, grades.** Three separate top-voted comments
   say that is the entire product. Everything else is optional. Prepkin has all three.
2. **"Simple and free" is the pitch, and bloat is the wound** — 34 people, 326 upvotes,
   the biggest single theme in the corpus. Say *simple* as loudly as *private*.
3. **Be careful how you ship the AI.** AI is their **second-biggest complaint**, and
   the anger is about it being *there and on by default*, not about the price. Prepkin's
   Sonnet photo scanner should stay opt-in, off by default, out of the way, and never
   the thing a student meets first.
4. **Never let an accessibility rule block a student's own theme.** Warn, show the
   contrast number, let them save anyway. Their contrast checker cost them 13 upset
   people and pushed users to a fork.
5. **Never take a saved theme away**, and never force an update during finals week.
   Both earlier sources and Reddit agree; Reddit adds the timing.
6. **Performance and exam safety are a real risk axis, not a nice-to-have.** Their
   worst-voted post is an extension that lagged an exam timer and blocked a submission.
   Prepkin's skin must be provably inert on quiz pages, and that belongs in the test
   suite and in the pitch. It also strengthens "reads nothing, sends nothing."
7. **No mandatory account.** 13 people hit login walls and server errors; one says they
   will uninstall if an account becomes required. Prepkin's no-account model is a feature.
8. **Streaks were not the problem — losing streak data was.** Do not use Reddit as
   evidence for pulling streaks. If they come back, they must survive migrations.
9. **Sell themes as looks, not as a study aid.** Students want a Canvas that isn't ugly
   and that classmates notice. That is enough.
10. **Watch CanvasRefined.** A free fork with 15 distinct advocates and a 588-upvote post
    is going after the same opening Prepkin is.
11. **Firefox and Edge are an unserved gap** — 9 people, and BetterCampus has broken that
    promise for nine months.
12. **A mobile app is what their own users ask for.** 14 upvotes on their board; Prepkin
    already is one.

## Gaps in this pass

- ~~No Reddit.~~ Done 2026-09-10 in George's logged-in Chrome, via Claude in Chrome.
  Reddit is unreachable from the Claude Code harness itself (403s the search JSON, blocks
  reader proxies, delisted from Exa, blocked by policy in the in-app browser).
- Reddit comments in the workbook are **paraphrased, not quoted**, with a permalink per
  row. Quotes above are paraphrases unless marked otherwise.
- Reddit sample is small and skewed: most threads under 30 upvotes, r/bettercampus is
  self-selected for people with a problem, and some posters are clearly high schoolers.
  r/college, r/CollegeRant, r/highschool, r/APStudents, r/csMajors and r/Instructure
  returned **nothing**.
- Chrome Web Store reviews are a **single recent page** (10 reviews, all one day). They
  skew positive because the extension prompts for reviews. The negative signal here comes
  from the feedback board and ExtSpot's aggregate, not from a full store pull.
- Feedback-board upvote counts are small in absolute terms (max 34). Treat the *ranking*
  as signal and the magnitude as weak.
