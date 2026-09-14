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
