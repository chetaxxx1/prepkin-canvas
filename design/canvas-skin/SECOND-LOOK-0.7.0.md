# Second look, 0.7.0 — 2026-09-14

Six pages on the real sandbox at 1280, skin on, both papers, from the floor's own
shots (`design/signoff/canvas-pages/*-1280.jpg`, 13:07–13:17). Graded against the
references in `VERDICT-2026-09-14.md` §4. No fixes were made. The page with the
twelve shots side by side: the "Second Look 0.7.0" artifact.

| Page | Newsprint | Carbon | Reference | Why it is still B |
|---|---|---|---|---|
| Dashboard | A− | A− | Finch rows, BetterCampus card | The card's Next row cuts the title mid-word ("Unit 4 conce…"); the rail's Start-with title wraps while the Then rows truncate, two rules in one list. Canvas's Recent Feedback under the rail still lists the deleted "Live:" rows (Canvas caches it). |
| Course home | B+ | B | Finch rows, Imprint headings | Canvas's empty 90px band above the modules holding one Collapse All; the module row's due line in Canvas's 11px grey; Recent Feedback repeats the top card. Dark: Collapse All and the three View buttons are white blocks (the button rule's cost). |
| Modules | B+ | B | Things rows, Imprint headings | The same empty band; "Prerequisites: Unit 4" in small grey; the dimmed Files tab reads as disabled. Dark: the white Collapse All. |
| Grades | B | B+ | Things dark, Finch rows | Canvas's table: the last columns clip at the right edge at 1280 ("198.00" cut); "missing" is a grey outlined pill, not an amber "still counts"; three-line titles make uneven rows. Dark reads well, same clipped edge. |
| Files | B+ | B+ | Contra tiles, Imprint headings | The two header buttons are Canvas's grey blocks with no hierarchy; the Files heading is 36px where Imprint sets 17/600. Dark: header buttons and Search are white blocks. |
| Calendar | B+ | B | Todoist Upcoming | Canvas's event chips keep their light fills, course-colour text and strike-through, seven in a row; the Month toggle is a grey slab; "September 2026" is an underlined link. Dark: the chips are the loudest thing on the page. |

Two things that would move most pages a step: cut titles at a word everywhere, and
keep the module band's empty 90px out of the page. The white blocks in dark are the
"never a property on a button" rule's price, not misses.

## After the A pass (same afternoon)

Six moves, one commit. Grades after, Newsprint · Carbon:

| Page | Was | Now | What moved | Still short of A |
|---|---|---|---|---|
| Dashboard | A− · A− | A · A | `cutAtWord()` in `day.js`: the card line, the rail's Then rows and Next in this class cut a title at a word. | Canvas's cached Recent Feedback lists deleted rows (Canvas). |
| Course home | B+ · B | A− · B+ | `module-band`: the 90px bar folded to its one button; the due line 13px in the quiet ink. | Recent Feedback repeats the card; white buttons in dark. |
| Modules | B+ · B | A− · B+ | Same. | "Prerequisites" small grey; white Collapse All in dark. |
| Grades | B · B+ | A− · A− | `grades-fit`: fixed columns that fit 620px, the name widest, hidden tooltip links gone from Details, due dates may wrap; missing and late are amber pills. | The totals' "198.00 / 280.00" wraps to three lines. |
| Files | B+ · B+ | A− · B+ | The h1 (`[class*="-view-heading"]`) at the one title size. | Two header buttons with no hierarchy; white in dark. |
| Calendar | B+ · B | A− · A− | `cal-rows`: each chip one ink line, the course colour on its 3px edge and the icon. | The Month toggle (a jQuery-UI button) is a grey slab; the month is an underlined link. |

The receipt gained three rows with Put backs (module-band, grades-fit, cal-rows; cap
raised 19 → 22 in `receipt.test.js`). What holds every dark page under A is the
"never a property on a button" rule: the carve-out allows colour only, which cannot
take a white ground away. That change is George's call.

## After the buttons pass (2026-09-15, a3e79b81)

George opened the button rule: Canvas's plain buttons take the paper (never a submit,
primary, danger, success or icon-only button; never an InstUI button inside a form).
The title bar is the paper, not a white block, and the count badge is gone from the
buddy. Every page is now A− or A in both papers: Dashboard A · A, the other five A− · A−.
Left, all Canvas's own: the cached Recent Feedback list, the underlined month link on the
calendar, the grey icon-only download button on Files, the totals row wrapping on Grades.

## The last pass (2026-09-15), and an honest grade

Four more moves: the module header's "Prerequisites" line in the quiet ink at 13px;
the grades totals on one line; the calendar's month name in the ink with no underline,
and the selected view a shade sunk; the Files page's icon-only buttons on the paper
(it has no colour band for them to sit on). Floor 87/87, unit 143, receipt 38, e2e 39,
stress 10.

Honest grades against the §4 references, Newsprint · Carbon:

| Page | Grade | What keeps it from a clean A |
|---|---|---|
| Dashboard | A · A | Nothing of ours. Canvas's Recent Feedback list under the rail is Canvas's, cached. |
| Course home | A− · A− | Recent Feedback repeats the card above it (Canvas's block; hiding it would be a new "taken" row George has not asked for). |
| Modules | A · A | — |
| Grades | A− · A− | The totals' "198.00 / 280.00" runs 24px past the table edge into the gutter; the ⓘ icon on an ungraded row is Canvas's grey. |
| Files | A · A | — |
| Calendar | A− · A− | The selected view (Month) is a shade sunk, which reads faintly on Newsprint; Todoist marks the selected view harder. Seven chips a row is still Canvas's density. |

So: three A, three A−. The A− lines are each one Canvas block or one faint tone, not a
miss. Getting the last three to A means hiding Canvas's Recent Feedback on course
homes, a bolder selected-view treatment (a filled tab, which is a button change past
the paper's three tokens), and a fourth column plan for the grades totals.
