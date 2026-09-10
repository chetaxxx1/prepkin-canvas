# What to steal from BetterCampus, and what to refuse

Decision brief, 2026-09-10. Evidence: `research-bettercampus-likes.md` (Chrome store +
their feedback board, 09-09) and `~/Downloads/BetterCampus_Reddit_Evidence.xlsx`
(361 coded Reddit rows, 91 threads, 09-10). Current Prepkin state read from
`extension/README.md`, `content.js`, `themes.js`, `receipt.js`.

**The verdict in one line: steal almost none of their features and all of their scar
tissue.** Prepkin already ships the things students name as favorites. What BetterCampus
has that we don't is mostly the stuff their own users are trying to escape. The real
prize is the list of mistakes they made in public.

---

## Already ours — do not rebuild

Before the take list, the things a parity read would wrongly flag as gaps. We have these:

| Student favorite | Where it is in Prepkin |
|---|---|
| Dark mode | 4 dark papers, warm charcoal, measured contrast, Auto follows the OS, free forever |
| To-do / assignment visibility | Today / This week / Overdue / **Missing**, plus Next due on every dashboard card |
| Grades on the dashboard | Sparkline, class average, aiming-for, what-if, See every assignment |
| GPA calculator | `content.js:352` — unweighted plus a weighted line with Honors / AP chips |
| Themes | 26, each a measured paper + accent + card wash + texture |
| Focus timer | 15/25/45, survives navigation in the service worker |
| Sidebar / page cleanup | The receipt, with per-row Put back |
| A mobile app | The whole iOS app. Their own board asks for one (14 upvotes) |

---

# TAKE

## 1. Their positioning. Say "to-do, dark mode, grades" first. — free, copy only
Three separate top-voted Reddit comments say the same sentence:

> Most users don't care about Pro, AI or a new interface; they only want the to-do
> list, dark mode and grades. — 18 upvotes
> Old version gave them assignments on the home page, a to-do list, grades and dark
> mode — all most people needed. — 19 upvotes
> Just wants a lite tool for dark mode, hiding past courses and custom fonts. — 23 upvotes

Our own store description currently opens with syncing to a phone and a study buddy.
That is our differentiator, not the reason anyone installs. **Lead with the trio, free,
no account. Put the buddy and the phone second.** This is the highest-value change in the
brief and it costs an afternoon of copy.

## 2. A student's own picture on a course card and the dashboard. — M
Themes are the #1 liked thing (22 distinct people). The specific thing they praise is
**images**: card images matched to specific classes, a Canvas themed around a favorite
show, background photos. Our 26 themes ship *our* art. A student cannot bring theirs.

- Local file picker → stored as a data URI in `chrome.storage.local`, never uploaded.
- No hotlinking, no marketplace, no fetch to Pinterest or Giphy. That ban stays.
- It rides the receipt like everything else: one row, one Put back.

This is the single feature gap where their users are loudest and we are genuinely behind.

## 3. Hide past and concluded courses. — S
Named in the same 23-upvote comment as a core want. `canvas.js:189` already knows which
enrolments are concluded, and `content.js:1227` already reasons about non-student courses.
This is a toggle and a filter, not a feature.

## 4. A term recap. Steal the shape of "Canvas Wraps". — M
The only feature in the entire corpus that produced plain delight:

> Weirdly motivating seeing everything broken down like this. — their board

Periodic, reflective, shareable, zero daily nagging. It fits Prepkin's rules better than
it fits theirs: we already hold submission times, points and per-course history on the
laptop. **Build it end-of-term only.** The moment it becomes a daily counter it turns
into the thing they got mocked for.

## 5. "What's due" in the Chrome side panel. — M
An upvoted request on their board that they never built:

> Right now the popup just takes you to Canvas, which is redundant — most students
> already have a Canvas bookmark.

Same complaint applies to us. A side panel means the list is there without a Canvas tab.

## 6. Firefox and Edge. — M/L, and it is a wedge
Nine distinct people complain. BetterCampus promised both "in about a month" in Dec 2025
and still has not shipped a current Firefox build in Sept 2026. Their Firefox reviews are
people asking to be rescued. Our extension is MV3 with no Chrome-only APIs beyond
`optional_host_permissions`; this is mostly a packaging job.

## 7. Their pricing scar, as a promise we write down. — free
They lost their base at the exact moment a thing a student already had stopped working.
The rule that falls out, for Prepkin Plus: **Plus may add. Plus may never take away
something that was free, and never something a student already made.** Put it in the
store listing and in the popup, in those words.

---

# DO NOT TAKE

## 1. AI anywhere near the Canvas page
Their **second-biggest complaint** — 19 distinct people, 169 upvotes — and the anger is
not about price. It is that it is *there*.

> AI features were switched on without consent.
> Went from a polished student project to bloat with AI features nobody asked for.

**Applies directly to us.** The Sonnet photo scanner shipped with the Calendar tab stays
in the app, opt-in, off by default, never on the extension, and never the first thing a
student meets. If a student never taps it, they should never learn it exists.

## 2. A required account
13 distinct people hit login walls and server errors; one says they will uninstall the
day an account becomes mandatory. Prepkin's pairing-token model needs no account. Keep it,
and say so on the listing.

## 3. Paywalling anything free, and upsell pop-ups
16 people. $19/mo or $119/yr. *"A paywall every other click."* *"The whole thing feels
like an ad."* Two students were charged while cancelling the trial. Note the cause with
sympathy: **donations raised them $64.** A free extension has no business model. Ours does
— the extension is the app's front door, so it never has to sell anything.

## 4. The suite: planner, notes, flashcards, AI quizzes, calendar sync, transcription
Bloat is the biggest theme in the whole corpus — **34 people, 326 upvotes**, larger than
every positive theme combined.

> So overloaded they can't do the simple things they installed it for.
> It almost feels like opening FL Studio for the first time.
> Canvas is actually HARDER to use than without the extension.

Prepkin's own Hick's-law pass exists for this reason. The extension must stay a skin, a
list, a timer and a buddy. New surfaces go in the app, not on the Canvas page.

## 5. A contrast checker that blocks a save
13 people, and it is the most instructive mistake they made. They shipped an accessibility
rule that refuses to save a student's own theme.

> It's their Canvas; customization should be up to them. — 8 upvotes
> The contrast rule forced them to replace a light-blue theme they'd loved for two years.

We measure ink contrast on every paper, which is right. **Never let that measurement stop
a student.** Show the number, warn once, save anyway.

## 6. A community theme marketplace
It is what students love about them and it is also the thing that breaks: hotlinked images
from Pinterest and Giphy on every dashboard load, capped theme swaps, server errors,
themes vanishing on update. Take the *feeling* — make it yours, show it off in lecture —
with local images. Not the marketplace.

## 7. Any update that drops what a student made
14 people, 134 upvotes, and the loudest emotion in either source: *"I feel heartbroken."*
Worse, they shipped it **in the two weeks before finals**, April 15–28 2026. Six
"give me the old version" threads in fourteen days.

**House rules:** saved themes, papers and put-backs migrate or the update does not ship.
No schema-breaking release between April 15 and May 15, or December 1 and 20.

## 8. Streaks as a hook
Correcting my own earlier read: Reddit does **not** call streaks childish. One person
dismissed gamification; four valued them; one lost a 450-day streak. The real complaint is
streak data destroyed in migration. So the case for removing them app-wide was never
Reddit's — decide it on Prepkin's own grounds. If they ever return, they survive
migrations or they do not ship.

## 9. Anything that touches a quiz page
The most-upvoted negative row in 361:

> Installed it to make Canvas look better; during a final exam quiz it lagged the timer
> and blocked submission, forcing a paper redo. A nicer look isn't worth that.
> — r/UTMississauga, 26 upvotes

Plus a district block, a UC Davis block, a Canvas admin warning students off in three
r/canvas threads, and Honorlock conflict questions. We already switch off on New Quizzes.
**Make it provable:** an e2e case that asserts zero injected nodes, zero observers and
zero style rules on a quiz page, and a line in the listing that says so. This is the same
argument as "reads nothing, sends nothing," and it is the one an IT department reads.

## 10. Their branding on the page
*"Its now been attacked by 'better campus' branding… logo on the sidebar."* Our receipt
already removes a duplicate Canvas logo. We must not add ours in its place.

---

## The three rules that fall out

1. **The extension stays small.** Trio first, everything else in the app.
2. **Nothing a student made ever disappears** — not on update, not behind Plus, not
   because a rule of ours disapproved of it.
3. **Never be the reason an exam went wrong**, and be able to prove it in a test.

---

## Built 2026-09-10

Four of the seven takes are in the extension. Details and test names in
`EXTENSION-FEATURES.md` §F.

| Take | Status |
|---|---|
| 1. Trio-first copy | **Done.** Store listing, manifest, popup subline, first-run, README |
| 2. Your own picture on a course card | **Done.** Local file, shrunk in the page, never uploaded. `scrimFor()` dims a bright picture exactly enough for Canvas's white controls and never refuses one |
| 3. Hide past courses | **Done.** Opt-in receipt row, CSS only, heading folds with its table |
| 5. What's due in the Chrome side panel | **Done.** Reads what was already collected, makes no request, never writes |
| 4. Term recap | Not built |
| 6. Firefox and Edge | Not built |
| 7. The Plus promise, written down | Not built — it is a copy decision, not code |

Plus the refusal that mattered most: **R18, the quiz-page proof.** The test now
reads every selector in `skin.css` off disk and asserts none of them matches
anything on a quiz being taken, and that no element carries an id, class or
attribute of ours. It caught a real one on its first run — an empty
`#pk-theme-vars` element was being created on pages the skin is off for.

## Open for George

- **Firefox** is the biggest unserved gap and their longest-broken promise.
  Worth a session?
- **A term recap** is the only feature in the corpus that made anyone happy.
  Build it now, or at the end of the first real term?
- The Plus promise — *"Plus may add. Plus may never take away something that was
  free, and never something a student already made"* — belongs in the listing and
  the popup. Want it written in?
