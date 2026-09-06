`, `button`, `[type="submit"]`, `input[type="submit"]` or `[role="button"]`, anywhere, in any theme, in any state.**

That is a stronger guarantee than a contrast check, because it removes the class of bug rather than testing for it. BetterCanvas's documented worst failure — a submit button its dark mode painted the same colour as its background, which a user reported as "it doesn't let me submit assignments" — cannot occur in a stylesheet that never writes those properties on a button.

Enforced two ways:

1. **Stylesheet lint, CI-blocking.** Parse the compiled Receipt CSS. For every rule, if any selector in the selector list matches the button pattern above, assert the declaration block contains none of the eight banned properties. Zero exceptions, no allowlist.
2. **Headless contrast assertion**, run against Canvas's default brand config plus three real school configs (a light-blue, a dark-navy, and a maroon primary), on both papers, in four states.

Because Receipt writes nothing, the measured numbers are Canvas's own and are recorded as a regression baseline:

| Check | Canvas default | Requirement | Result |
|---|---|---|---|
| Primary button text `#FFFFFF` on `--ic-brand-button--primary-bgd` `#0374B5` | **5.0:1** | 4.5:1 | pass |
| Same, `:hover` (`-darkened-5`) | 5.4:1 | 4.5:1 | pass |
| Same, `:active` (`-darkened-15`) | 6.4:1 | 4.5:1 | pass |
| Same, `[disabled]` (Canvas drops opacity, not colour) | 3.1:1 | — | Canvas's own; unchanged by Receipt |
| Button block edge against `--pk-paper`, light | 4.4:1 | 3:1 | pass |
| Button block edge against `--pk-paper`, dark (Carbon) | **3.5:1** | 3:1 | pass |

The last row is the one that matters in dark: the button stays Canvas's saturated blue on a `#17191D` page, so it reads as a raised control at 3.5:1 rather than vanishing.

### 9.6 Everything else Receipt must not fight

| Preference | Receipt's behaviour |
|---|---|
| `ENV.PREFERENCES.hide_dashcard_color_overlays` | Never fought. `opacity` is never written on `.ic-DashboardCard__header_hero` and `color` is never written on `.ic-DashboardCard__header-title span`. Shipped bugs 1 and 2. |
| `ENV.SETTINGS.collapse_global_nav` | Read never, written never. No width rules. |
| `ENV.disable_celebrations` | Irrelevant — Receipt ships no celebration. |
| `ENV.disable_keyboard_shortcuts` | Receipt binds no page-level key. Its one shortcut is a `chrome.commands` browser command. |
| `body.Underline-All-Links__enabled` | Never overridden. Receipt writes no `text-decoration` anywhere. |
| Screen-reader outline | No heading, label, link or landmark is ever removed. The four things Receipt removes are: a chevron with nothing before it, a duplicate logo, a colour band, and an expander whose targets are already expanded. |

### 9.7 The toggle matrix (constraint 21)

Every combination a student can reach, asserted in CI. Tokens live on `html.pk-on` alone, so no combination can leave a custom property unresolved — this is shipped bug 3 fixed by construction, not by patch.

| `pk-on` | `pk-dark` | Look | Veil | Result |
|---|---|---|---|---|
| off | any | any | any | Stock Canvas. All classes and all inline properties removed; nothing left behind. |
| on | off | any of 6 | off | Light paper from the Look's light stock. |
| on | on | any of 6 | on / off | Dark paper from the Look's dark stock; veil independent. |
| on | on | any | any | Under high contrast, New Quizzes, or Widget Dashboard: kill switch fires first, result is row 1. |

---

## 10. Looks

The existing `looks.js` model survives intact — a palette plus one accessory, earned with coins, never bought with money. What changes is that the palette **splits by surface**.

**A Look now owns two things:** one **paper stock pair** (what the Canvas page becomes) and one **accessory on Sprout** (what the popup and panel show). Same catalog, same prices, two surfaces, and the school page always gets the quiet half. That is constraint 18 expressed as a data model rather than as a rule someone has to remember.

**On a Canvas page a Look moves exactly seven tokens** — `--pk-paper`, `--pk-paper-2`, `--pk-paper-sunk`, `--pk-ink`, `--pk-ink-2`, `--pk-rule`, `--pk-mark`. Nothing else. No radius, no type, no spacing, no accessory, no course colour, ever.

### 10.1 The six paper stocks — a closed catalog

Four light, two dark. Every body-text ratio measured. **The floor is AAA (7:1), not AA** — a student picking a paper is picking a reading surface, so none of them is allowed to be a worse place to read.

| Stock | `--pk-paper` | `--pk-paper-2` | `--pk-paper-sunk` | `--pk-ink` | `--pk-ink-2` | `--pk-rule` | `--pk-mark` | Body | Cast |
|---|---|---|---|---|---|---|---|---|---|
| **Newsprint** | `#F7F6F3` | `#FFFFFF` | `#EFEDE8` | `#1B1F24` | `#454B54` | `#E3E0D9` | `#2F6BAA` | **15.3:1** | neutral |
| **Manila** | `#F2EAD9` | `#FBF6EC` | `#E9DFC9` | `#33291F` | `#5E5142` | `#E5D7C2` | `#A9563A` | **11.9:1** | warm |
| **Bond** | `#F4F6F8` | `#FFFFFF` | `#E9EDF1` | `#12171C` | `#3E464F` | `#DDE3E9` | `#1F5FA8` | **16.6:1** | cool |
| **Vellum** | `#EFE7D8` | `#F6F1E6` | `#E5DBC8` | `#3C3730` | `#635C51` | `#DED3BE` | `#6E6A5F` | **9.6:1** | cream, softest |
| **Carbon** | `#17191D` | `#1E2126` | `#121417` | `#E6E8EA` | `#B4BAC1` | `#2C3037` | `#6FA8DC` | **14.3:1** | neutral dark |
| **Blueprint** | `#161B22` | `#1C232C` | `#11151B` | `#DDE4EC` | `#A9B4C2` | `#29323D` | `#7FB2E0` | **13.5:1** | blue-grey dark |

Each shop card prints its own measurement and its cast — *"Manila · 11.9:1 · warm"* — so a student picks a paper the way they pick a desk lamp, not the way they pick a hat. Unowned papers show their price and are **fully previewable on the live page**. No padlocks, no `?` tiles.

### 10.2 The six Looks — nothing taken away

| Look | Price | Accessory (popup/panel) | Light stock | Dark stock |
|---|---|---|---|---|
| Classic Cream | free | none | Newsprint | Carbon |
| Woodland | 300 | sprout | Manila | Carbon |
| Cozy Beanie | 300 | beanie | Vellum | Carbon |
| Tidepool | 450 | glasses | Bond | Blueprint |
| Butterscotch | 300 | scarf | Manila | Carbon |
| **Night Shift** | 500 | beanie | Bond | **Blueprint** |

**Two light Looks share Manila and four share Carbon, and that is fine.** A paper is a reading surface, not a badge. The Look's identity lives on the accessory, in the popup, which is the surface the student opened.

### 10.3 The Night Shift ledger problem, settled

Night Shift costs 500 coins today and its entire payload is `dark: true` — wearing it turns dark mode on. Receipt ships dark as a free base mode. That is a collision and the concept as briefed did not notice it.

**The settlement, and it must ship with the change, not after:**

- **Dark is free and always will be.** It is an accommodation — migraine, photosensitivity, astigmatism, Irlen — and Prepkin does not sell an accommodation. Carbon is free to everyone.
- **Night Shift keeps its name, its 500-coin price, its beanie, and a dark page.** Its dark stock becomes **Blueprint**, the blue-grey one, which is otherwise only reachable by buying Tidepool or Night Shift.
- **Nobody who paid loses anything.** They keep the item, keep the accessory, and end up on the more distinctive of the two dark papers at no extra cost.
- **`dark: true` is deleted from the Look object.** That also fixes shipped bug 8, where Night Shift forced dark on while the popup checkbox still read "off" — the toggle and the state visibly disagreed.

### 10.4 Two shipped bugs the split fixes for free

- **Bug 10 — Look tints never reach `#prepkin-buddy`.** Today tints are set inline on `<html>` while the panel re-declares all 27 tokens in its own matched rule, and a declared value beats an inherited one, so wearing Woodland turns Canvas green while the panel stays mint. Fixed structurally: the seven paper tokens are declared **once**, on `html.pk-on`, and the panel inherits them. The panel declares only what is its own — the mint, the coin, the accessory colours — and never redeclares a paper token.
- **Bug 9 — all six Looks render identically in dark.** Caused by `if (!s.cards || dark) return;` in `applySkin`. Fixed by giving every Look a **dark stock as well as a light one**, and deleting the early return. Four Looks land on Carbon and two on Blueprint, so the page differs across the catalog in dark, and the accessory differs in all six.

### 10.5 Why this is not a treadmill

**A closed catalog of six things a student stares at every day cannot be drip-fed.** There is no version of Receipt where the answer to "what's new this month" is a seventh theme. If the catalog needs to grow, the honest growth is a seventh **reading surface** with a real reason to exist — a genuinely higher-contrast stock, a genuinely warmer one — priced the same, measured the same, and printed with its ratio on the card.

**And the thing that actually accumulates is not bought.** Every **Put back** a student clicks is remembered. What grows over months is their own edit list: the Outcomes tab they un-dimmed, the sidebar row they kept, the teacher's colour-coded table they exempted from the Word repair. Fifteen keys, so it cannot sprawl, but it is theirs, it costs nothing to ship, and it is the only thing in the product that could not be handed to another student.

---

## 11. Build order

Honest days, honest line counts. The restraint in Receipt is in what lands on the page, not in the code behind it — and the brief that said *"the only JS is one debounced querySelectorAll"* understated the real build by roughly an order of magnitude. Judge 2 was right to call that out, and a spec that misstates its own cost is the one thing that would make an engineer distrust the rest of it.

| # | What | Why here | CSS | JS | Days |
|---|---|---|---|---|---|
| **1** | **Navigation plumbing.** `canvasReadyStateChange`, patched `pushState`/`replaceState`, `popstate`, `hashchange`, one debounced (~300ms) `MutationObserver` on `document.documentElement`. Manifest gains `webNavigation`. | **Prerequisite for everything with JS in it, and none of it exists in the repo today.** The extension registers once at `document_end` and the only re-render trigger is `chrome.storage.onChanged`, which fires on *data* change, never on *page* change. Ship it before anything else and say so. | — | ~120 | **3** |
| **2** | **Kill switches and the token layer.** Three-way high-contrast detection and teardown, New Quizzes off, Widget Dashboard off, the 14 tokens on `html.pk-on`, the three scoped link variables, the reduced-motion block. | The safety floor. Nothing ships on top of an unguarded skin. Retires shipped bugs 3, 5 and 7 on day one. | ~70 | ~80 | **1.5** |
| **3** | **Static CSS, all pages.** Papers, per-page rules, every hide/dim/fix and its Show-me twin, the button lint. | Pure CSS, injected before DOM construction, no flash, no observer, no perf cost. This is the whole visible product for a student who never opens the popup. Retires shipped bugs 1, 2, 4 and 11. | ~360 | — | **4** |
| **4** | **The receipt popup.** "This page" list, Put back with 15 category keys, Show me, the toolbar badge, the count pass. | The removals in step 3 are only defensible once this exists. Do not ship a deletion without its undo. | ~90 (popup) | ~250 | **3** |
| **5** | **Sidebar dedupe and un-truncate.** | Highest student value per line in the product, and the closest thing to an answer to complaint #1 on the page itself. Needs a real dashboard with both To Do variants to test. | ~15 | ~70 | **1.5** |
| **6** | **Selector file plus smoke check.** All Canvas selectors in one annotated file with page and hook tier; a headless fixture asserting each load-bearing hook still matches; runs against every Canvas release. | Markup churn here is the default state, not the exception. Ship this before step 7 so the veil and the Looks are built on something that alarms when it breaks. | — | ~150 | **2** |
| **7** | **Papers and the Looks split.** Six stocks, six Looks, the panel inheritance fix, the Night Shift settlement. | Retires shipped bugs 8, 9 and 10. Cannot ship before the settlement is agreed. | ~60 | ~90 | **1.5** |
| **8** | **The seam.** Veil, borders, the Canvadocs optional permission with its popup copy. | Lowest student value per unit of risk, and the one step that touches the manifest's permission surface. Last on purpose. | ~15 | ~50 | **1** |
| **9** | **Popup "Due next."** Cross-course triage from `/api/v1/users/self/todo` and `upcoming_events`, which `canvas.js` already fetches. Amber on "due today, still counts." A **Missed** section replacing the cut Load-prior-dates un-hide. | Not a skin feature, which is why it is not in steps 1–8. But it is the real answer to complaint #1 and the only screenshottable thing in the product. | ~70 | ~120 | **1.5** |

**Total: ~680 lines CSS, ~930 lines JS, 19 engineer-days.** That is more than judge 2's 8–12 day estimate, and more than the brief claimed by a wide margin. Cutting the dashcard badge fix and the four `:has()` nav deletions saved about two days; the receipt popup, the smoke check and the navigation plumbing cost more than either.

**A day, honestly:** steps 2, 5, 7 and 8 are each roughly a day of real work plus half a day on a live Canvas. **A week, honestly:** step 3 is four days and will find things this document is wrong about, and step 4 is three days because Put back has to survive a page reload, a Canvas deploy and a student who clicks it twice.

---

## 12. What Receipt refuses to do

### 12.1 Cut on the judges' evidence, not on taste

| Cut | Why |
|---|---|
| **The dashboard assignments-badge fix (CNVS-21227).** | It is the only rule in the concept that produces a **wrong answer** instead of a plain page when it goes sideways. `.ic-DashboardCard__action-badge` means *unsubmitted assignments in this course*; planner items are a different set — calendar events, announcements, ungraded surveys, planner notes, over a rolling window. It is React-controlled, so it repaints on every card re-render and must be rewritten on every observer pass forever, and it will flicker. Canvas's own render controls whether the badge displays at all, so "stays hidden at 0" means fighting React over `display`. Cutting it makes every remaining claim in this spec true. If the count is worth having it goes in the popup, labelled honestly. |
| **Hiding four course-nav tabs.** | Presented in the brief as the safest call; it was the riskiest. Conferences is where some courses run the live meeting, Collaborations is where some run all group work, Outcomes is where a mastery-graded student sees their standing. The student only sees tabs the teacher already published, so this was deleting from an already-curated list, silently, with a recovery path most students would never find. Demotion by ink tone buys the same shortened scan for one rule instead of four `:has()` selectors, and hovering brings the tab back to full ink. |
| **The "Load prior dates" un-hide.** | A `ShowOnFocusButton` is a deliberate keyboard-first affordance in the same family as a skip link. Forcing it visible fights an accessibility pattern rather than repairing one, and the implementation was a `width < 4px` heuristic walking `button` elements — a guess, by the brief's own admission, and the only rule in the file that touched a node rather than a colour. The need it served moves to the popup's Missed section. |
| **The permanent 22px strip on every page.** | A product whose pitch is "nobody knows it is installed" should not append its own brand name and a running tally to the bottom of every school page a student opens for four years. It also put a Prepkin string on screen during a screen share, which is the one thing the concept otherwise gets exactly right. The mechanism survives whole; only the permanence and the metaphor are gone. |
| **The proofreader vocabulary.** | No 16-year-old knows what `stet` means, or `fair copy`, or a blue pencil. The mechanism was good and the words made it invisible to the person who needed it. "Put back." "Show me." "Receipt." |
| **`#right-side a.more_link { display: none }`.** | It hit Recent Feedback's expander too, while leaving its extra rows at inline `display:none` — permanently losing older feedback on a widget the concept swore it did not touch. Scoped to `.events_list.coming_up`. |
| **`animation-iteration-count: 1` in the reduced-motion block.** | It freezes Canvas's infinite spinners after one cycle, which reads as a hung page — a worse outcome, for the exact student who turned reduced motion on, than the motion was. |
| **`[style*="color"]` as a broad match.** | It matches `background-color`, `border-color` and `outline-color`, so an element carrying only `style="background-color:#ffff00"` got its text repainted. Replaced with an enumerated list of the values Word actually emits. |
| **The `.ic-DashboardCard__box__container` grid rule.** | The research offers it as a one-rule fix for the ragged right edge, but the container carries `margin: -36px 0 0 -36px` negative gutters that a grid would break, and it hardcodes 262px. It is addition-shaped and it fails hard, not soft. |
| **Deleting the Files action link on a dashcard.** | Its stated reason was that the destination is a stock white page inside a dark skin. Graft 2 handles that seam directly, so the reason evaporated. Four icons in a row are not clutter. |

### 12.2 Refused on principle, permanently

- **No mascot, no coin, no Prepkin green, no Prepkin wordmark, no Prepkin string on any Canvas page, ever.** The skin is imposed; the popup is opt-in. Personality belongs on the surface the student chose to open. Judge 3's suggestion to put the kin at 16px on the receipt strip is declined for the same reason the strip is.
- **Never sets `font-family` on a Canvas page.** Lato is fine. Changing it is taste, not correction — and never setting it is the only implementation of the OpenDyslexic rule that cannot be got wrong.
- **Never changes a radius Canvas did not already use, never adds a shadow, never adds a hover lift.** The shipped 16px cards and `translateY(-3px)` both go.
- **Never reorders the course nav.** CSS `order` on a flex `#section-tabs` would let Receipt float Grades to the top. Students learn that menu by position; it would help on day 1 and hurt every day after.
- **Never removes the school's logomark, the Help link, a heading, a label, or a link.** The sidebar logo is deleted only when it is provably the same mark twice on one page. Remove duplication, never remove identity.
- **Never removes information.** Only duplication, dead controls, and emphasis. Recent Feedback stays. The class distribution on Grades stays. The completion requirement on Modules stays.
- **Never gates a correction behind coins.** Every fix ships free and on by default. Dark mode is free forever. A student who does no work does not get a worse Canvas.
- **No due-date colour and no urgency pill on any Canvas page.** That would mean parsing a localised date string in 40 languages to decide how scared a student should be. Amber lives only in the popup and reads "still counts."
- **Never recolours `.ic-flash-error`.** That red is Canvas telling a student something failed. Softening it to stay on-brand would be the skin lying on the school's behalf.
- **No what-if calculator, no grade colour, no projection, no trend, no "at risk" label.**
- **No time-based auto-dark.** Follow the OS or follow the switch. Nothing else.
- **No `<all_urls>`, no external network request of any kind, no web font, no CDN image, no analytics — not even a private count of what was removed.**

### 12.3 What the last refusal actually costs, and what this concept costs Prepkin

**Refusing telemetry means the removals can never be checked.** "Students almost never open Files" and "a high-school student rarely opens Outcomes" are assertions from a research document, not measurements from real students. Demotion instead of deletion is the mitigation — a dimmed tab is still a tab, and it brightens when you reach for it — but somewhere there is a course whose whole grading scheme runs through Outcomes, and that student's menu now reads as if it does not matter. Put back fixes it for the student who notices. Most will not notice. That is the cost and there is no version of this that does not have it.

**And the larger one, stated plainly because the selection made it a condition:**

**Receipt is a good utility and a bad funnel, on purpose, and "on purpose" is not a defence.** It puts zero Prepkin identity on any Canvas page — no mascot, no coins, no colour, no wordmark — which means it does no work whatsoever to make a student install, open or keep the iOS app. A student could run it happily for a year and never learn there is a Sprout. Moving the receipt off the page and into the popup, which constraint 18 requires, makes that worse rather than better: a tool you cannot see is a tool you forget you installed, and a tool you forget is a tool you do not reinstall on a new laptop.

Four things are the whole answer, and they are smaller than the problem:

1. **The toolbar badge.** It is browser chrome, not the school page, and it is the only always-visible proof that something is working for you. It costs zero Canvas pixels. It is also easy to ignore.
2. **The popup is the funnel, and it has to earn that on its own.** Not as a settings sheet — as the one screen in the product worth opening: *today, across all your classes*, built purely from the two API calls `canvas.js` already makes. Sprout lives there, at rest, at 40px, in the surface the student clicked. The pairing card sits under the list. That is the entire acquisition surface.
3. **The one shareable thing is the popup, not the page.** Nobody sends a friend a screenshot of Canvas with four dimmed menu items. Someone might send a screenshot of one clean list holding six classes' work. Quiet on Canvas, shareable off it.
4. **The papers give coins something real to buy** — six reading surfaces a student stares at every day, each printed with its measured contrast — but a closed catalog of six is deliberately not a business.

**And the honest strategic read: the only part of Receipt a student can actually see is dark mode, and dark mode is the weakest possible moat.** Dark Reader does it across the entire web, free, with zero maintenance. Instructure is shipping native dark for the dashboard behind `widget_dashboard_dark_mode` right now. Take dark away and what is left is four dimmed nav tabs, a deduplicated sidebar, an un-truncated Coming Up, an 8px hero, a right-aligned due column, a pinned module header and a Word-paste repair. That is genuinely useful and it is genuinely hard to make anyone install an extension for.

The trade Receipt makes is that its worst case is Canvas, unchanged — which is the only concept in the set that can say that, and the reason it survives a district security review that the incumbent did not. If the skin's actual job is acquisition rather than retention, this concept fails at its job by design, and that failure should be priced before it ships, not after.