# Three directions for the client

Read the score column last. The spread is 7.33 to 6.33 with a three-way tie in the middle, so score is noise here. What separated these was **how far apart they are** and **whether the signature move actually works**.

Two of the seven are the same concept twice. Two more are the same axis twice. One is a different justification for the same answer everyone else gave. That left five real candidates for three slots, and the top scorer only survived because it owns a surface nothing else touches.

---

## The three, in presentation order

### 1. Receipt (was: Fair Copy)

**One line.** It quietly takes the junk off your Canvas pages and fixes what Canvas gets wrong, then shows you the list of everything it took so you can put any of it back with one click.

**The axis it owns.** Subtraction with proof. It is the only concept whose product is *absence*, and the only one where every change is inspectable and reversible by the student. No other pick removes anything. No other pick can show its work.

**Why it earned the slot.** It is built on the strongest single finding in the research — students use these extensions subtractively; the most-shared tips are all "remove X" (§7.3 item 3) — and it is the only one of seven that acts on that instead of designing around it. The engineer judge gave it 8 and said it is the only concept he would hand to a junior and expect to survive the next Canvas deploy. It fixes five of the eleven shipped bugs by construction, not by patch. It satisfies constraints 7 and 8 **by deletion**: it never writes `font-family`, so there is no `ENV.use_dyslexic_font` branch to get wrong and no 104/218px layout ladder to break.

The decisive part is Marks. A skin that deletes things from a school-owned page and hands the student a receipt plus a permanent one-click undo turns the category's worst failure — a student can't find a control, blames the extension, a district blocks it for everyone — into the product's proof. Nothing in this market does that.

---

### 2. Measure (was: Margin Notes)

**One line.** Canvas re-set like a really good textbook: one narrow readable column, thin rules instead of boxes, and every due date lined up so you can read straight down.

**The axis it owns.** The reading surface. It is the only concept that touches `.user_content` — assignment prose, Pages, Syllabus, every teacher-written page — where a student actually reads and where Prepkin today ships literally nothing. It is also the only direction competing on typography, an axis no shipped skin in the category occupies.

**Why it earned the slot.** Highest average and two 8s, and both of those judges independently named the same artifact the strongest single thing in the whole batch: the Modules due-date column. It answers complaint #1 by *alignment* rather than by scattering thirty amber pills down a page, needs no JS, and degrades to a plain row. It fixes four shipped bugs by omission — never touches hero opacity, never colours the title span, declares tokens on both root classes, deletes the unguarded hover lift. Its `prefers-reduced-motion` block is empty by construction because it adds no motion at all, which is the cheapest correct answer to constraint 9 anyone gave.

---

### 3. Low Beam

**One line.** A dimmer for Canvas instead of a dark-mode switch — four steps from daylight down to 2am — that also turns down the white pages the skin isn't allowed to repaint.

**The axis it owns.** The page's light output as a continuous, student-controlled variable, **and the seam**. It is the only concept that treats the surfaces a skin cannot repaint — Files v2, third-party LTI, InstUI trays — as a design problem rather than a footnote. That is constraint 16 answered instead of acknowledged.

**Why it earned the slot.** Dark is the one category with a physical retention mechanism: turning it off hurts. Eight years, 354 comments, still Open, most-visited idea every quarter, opened by a student, and a meaningful share of it is disability rather than taste. Low Beam engineers for that instead of styling for it — the text ceiling comes *down* at the deepest step because maximum contrast is not maximum readability for astigmatic and Irlen readers, and chromatic area shrinks while course hue is left exactly as Canvas gave it. Its signature — the brightest object on the page is always the button you are supposed to press — is the exact inverse of the incumbent's documented worst bug and satisfies constraint 15 by construction.

---

## Every graft

**Into Receipt:**

- **Took the tabular right-aligned due column on Modules from Margin Notes**, because Receipt names "I cannot tell what is due" as complaint #1 and then answers it with greyer secondary text — de-emphasis dressed as information. Re-aligning a date already on the page is removal of visual noise, not addition, so it costs the thesis nothing. `.due_date_display { min-width: 8.5rem; text-align: right }` plus inherited `tabular-nums`. One rule, no JS.
- **Took the `brightness()` veil from Low Beam** — Files v2 and third-party LTI only, **never** `iframe#tool_content` on a proctoring launch, floored at ~.88 wherever grey-on-white body text can appear — because Carbon's whole promise is that nothing flashes you at 2am and today it leaves every unreachable white rectangle at full brightness. Apply the Corrections block first: New Quizzes has been same-origin since 2026-08-15 and gets real dark; Canvadocs is reachable with `all_frames`. The veil covers a much smaller set than Low Beam thought.
- **Took the sticky module header from Manila**, because Receipt's only answer to complaint #3 is hiding four course-nav tabs — the riskiest call in the concept presented as the safest. A pinned header buys the same win by adding a rule instead of removing a control a teacher may have just told the class to click. Drop the tab deletions to demotion by ink tone.

**Into Measure:**

- **Took the sticky module header from Manila** (`.ig-header.header { position: sticky; top: 0 }`, no indices, no JS), because all three of its judges said complaint #3 gets literally nothing and the concept says so out loud four separate times.
- **Took "never set `font-family` by default" from Fair Copy**; the serif ships as one opt-in checkbox and the measure, leading, heading rhythm, hairlines and tabular figures ship always on. This kills three problems at once: the dyslexic-font gate is unreadable from an isolated world, a late `font-family` write guarantees a visible relayout on every page load, and "one designer's Georgia on a school page" is the charge the concept levels at everyone else. The legibility win survives a face change intact.
- **Took density as a coin-earned dial from Falloff**, with the rule that a Look sells the paper and never the ink. Measure's Looks catalog is four colour tokens, which its keeper judge called not worth 300 coins, and its student critic said density is the one place the evidence demands a control rather than an opinion.

**Into Low Beam:**

- **Took the tabular due column from Margin Notes**, because Low Beam's own honest weakness is that it spends everything on complaint #2 and leaves #1 as a repaint. All three of its judges said the same thing.
- **Took the rim-light dark drawing from Room Tone** — drop shadows to `transparent`, surfaces separated by `inset 0 1px 0 rgba(255,244,228,.055)` on the top edge — because Low Beam never says how a card reads as an object on a dark ground, and a shadow on near-black is invisible. Manila reached the identical rule independently, which is good evidence it is right.
- **Took "a Look supplies hue only; the dimmer owns every luminance value" from Falloff**, because Low Beam silently orphans five paid Looks (every tint in `looks.js` points at tokens Low Beam drops) and makes the 500-coin Night Shift purchase worthless.
- **Took the press from Same Paper** — `box-shadow: 0 3px 0 var(--ic-brand-button--primary-bgd-darkened-15)`, collapsing on `:active`, always in the school's own computed colour — because Low Beam already stakes its headline on the same control. The submit button becomes both the brightest object and the only object that moves. The derivative is real (§4.2 rule 4), the fill and label colour are never touched so contrast stays byte-for-byte Instructure's, and the travel goes inside the reduced-motion guard.

---

## Duplicate pairs found

| Pair | What makes them the same | Resolution |
|---|---|---|
| **Margin Notes ≈ Manila** | Same paper concept twice: warm ground, hairlines not boxes, tabular numerals, 2–3px radii, zero shadows, zero motion, amber-not-red, Looks-as-paper-stock. Their catalogs **share two entries by name — Manila and Ledger.** | Take Margin Notes; graft the divider in its working form |
| **Low Beam ≈ Room Tone** | Same axis: light output as the one continuous variable. Both add zero elements. Both own #2 and concede #1 and #3. They differ only on who moves the dial — student or clock. | Take Low Beam; graft the rim light |
| **Margin Notes ≈ Falloff** | Not the same premise, but the same artifact and the same register. Both stake their strongest move on identical CSS — the due date pulled out of prose and right-aligned in tabular lining figures. Strip Falloff's ramp and a screenshot cannot tell them apart. | Take Margin Notes; graft the Looks rule |
| **Low Beam ≈ Same Paper** | Same signature control, same justification, same words: the submit button as the exact inverse of the incumbent's hidden-submit-button bug. Brightest object vs. only moving object. | Compatible, not competing — graft the press |
| **Margin Notes ≈ Manila ≈ Fair Copy** *(Looks model)* | Three concepts independently propose "a Look is a paper stock", overlapping on Manila, Ledger and Blueprint. | Treat as a shared product decision, not a per-concept feature |
| **Manila ≈ Room Tone** *(dark drawing)* | Both replace the drop shadow with an inset top-edge highlight in dark, justified identically. | Two premises, one rule — strong evidence it is correct |

---

## The four that did not make it

**Manila** — duplicate of Margin Notes, and where it differs it breaks. A `position:sticky` element is constrained by its nearest block ancestor, and `.ig-header` lives inside `.context_module`, so headers never accumulate. Worse, the `--pk-tab-i` offsets make it fail *hard*: module 5's header parks 130px below the viewport top with an empty band above it. That is the only place in the entire batch where a concept produces a broken page instead of a plain one.
*Keep:* the pinned module header at `top: 0` — grafted into all three picks.

**Falloff** — its signature artifact is Margin Notes' artifact, and its one variable is wrong by its own admission. A 5-point discussion due tonight renders at 17px/700 in amber; the 40%-of-grade project due in sixteen days renders at 13px/400 in near-silence. The ramp also flattens when six things are due at once, which is exactly when the student opened Canvas for help.
*Keep:* "a Look sells the paper, never the ink" — a purchase may move ground and density, never a colour that carries meaning or a value that carries a contrast ratio.

**Same Paper** — its axis is a comparison that needs both screens present, and the author says so. What lands on the page is a 3px shadow and a border radius. That is not a different answer to "does Prepkin appear on a school surface" — it is a different *justification for the same no*, and the concept concedes the course-colour argument is "doing double duty as a principle and as an alibi."
*Keep:* the governance rule underneath the press — **shape is ours, colour is theirs.** Grafted into Low Beam.

**Room Tone** — same axis as Low Beam, and the mechanism is imperceptible at its own hexes: midday `#f5f5f4` to dusk `#f3ede8` is about two points of lightness on a 96%-lightness ground with a self-imposed floor of L 91.8%. All three judges cut the warmth ratchet: unspecified data source, a hidden done-over-total in the day-clear latch, and a value that resets every dawn — a number going backwards.
*Keep:* in a dark room you see edges catch light, not shadows cast. Grafted into Low Beam.

---

## Surviving risk on each pick

**Receipt** — it is a good utility and a bad funnel, on purpose. Zero Prepkin identity on any Canvas page means it does nothing to make a student install, open or keep the phone app; someone could run it for a year and never learn there is a Sprout. Paper stocks give coins something to buy, but acquisition is unanswered, and the only visible part is dark mode, which Dark Reader does free across the whole web. Moving the receipt into the popup makes this worse: a tool you cannot see is a tool you forget you installed.

**Measure** — the signature may land on a page nobody reads. The deep reading students do is usually a PDF inside a Canvadocs frame or a Google Doc — Tier 4, unreachable by any page-level CSS. If so, the entire prose investment buys a rounding error and the only durable value is the due column, which a much cheaper skin ships without the serif or the argument. Making the serif optional (correct on every other ground) thins the identity further.

**Low Beam** — nobody asked for four darks. Not one line of student voice asks for granularity; they ask for dark, and the incumbent ships a binary switch to two million people. If most students park on one step forever, the ladder and the moving weight scale are cost with no return, and what remains is a warm dark mode — the incumbent. Separately, **the flash is a ship blocker, not a polish item**: the extension registers at `document_end` today, so a dark-first skin paints a white page on every navigation until the sheet moves to a declarative `content_scripts.css` entry at `document_start`.

---

## Recommendation

**Build Receipt.**

It ships fastest, because most of it is deletion, and speed matters: `context_modules_v2`, `files_v2` and `widget_dashboard` are all in master behind flags, and every month costs surface area. It is the only pick whose worst case is *Canvas, unchanged*. And it is the only one built on the strongest finding in the research rather than around it — the other two add a designed page to a surface students are actively decluttering, and both have to argue their way past that.

The decisive reason is the block. A district already pulled the incumbent from every student at once, and the mechanism was students losing controls they could not find. Receipt makes that structurally impossible: every removal listed, every removal one click from coming back, and the list is what you show the IT manager. That is the difference between surviving a security review and losing a whole school in an afternoon — which the research names as the worst outcome in this category, worse than any bad review.

**Two conditions, not optional.**

1. **Take the coin axis or admit this does nothing for the app.** Six earned paper stocks, each card printing its measured body-text contrast ratio and its cast ("Manila · 11.2:1 · warm"); Newsprint and Carbon free forever, because nobody pays for legibility. And settle Night Shift before a line ships — it costs 500 coins today and its entire payload is turning dark on, which Receipt gives away. Refund it or give it a new job. *Nothing is ever taken away* applies to the ledger, not just to pixels.

2. **The receipt moves into the popup; the page keeps zero permanent Prepkin pixels.** Constraint 18 decides it: the page is imposed, the popup is opt-in. The on-page dashed reveal triggers from the popup. "stet" becomes "Put back". "Canvas bug CNVS-21227" becomes "Canvas shows 0 here even when work is due". The kin sits at 16px on the popup's receipt, at rest — the one place in this product a character belongs.

If you want the more distinctive product rather than the safer one, build **Measure** instead: highest scorer, an axis no shipped skin touches, and the only direction that improves the surface where students read. It takes longer and it may be improving a waypoint.

**Low Beam is third and only third.** The space is crowded by Dark Reader and by Instructure's own native dark mode, and the document-start flash has to be fixed before any of the design lands.