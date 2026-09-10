# Plus, on the simulator — 2026-09-10

iPhone 17 Pro, iOS 26.5, light. The app is light-only
(`INFOPLIST_KEY_UIUserInterfaceStyle: Light`), so there is no dark pass to take.

| Shot | What it shows |
|---|---|
| `01-focus-chips-free` | Free Focus. 15/25/45 in ink, **60 and 90 in full colour with "Plus" under them**, and "Any length you type · Plus" as a text link. No padlock, nothing greyed. |
| `02-sheet-focus` | The sheet opened from the 60 chip. The top third is the chip row and the reason's own headline; everything below it is the same on every reason. |
| `03-sheet-perks` | What stays free, **first**, then five perks drawn as the things they are — a coat on two example fish, seven slots, the two chips, a syllabus page, a month. |
| `04-sheet-prices` | $69.99 with "$5.83 a month, billed once a year" and "saves 42%"; $9.99 monthly; one coral button; Restore; "Can't swing it? Ask."; the mission line; and the 3.1.2 legal line with Privacy and Terms. |
| `05-sheet-bottom` | The same, scrolled to the end. |
| `06-compare-table` / `07-compare-table-2` | Free and Plus side by side, behind "See everything, side by side". Numbers where a number exists, and "Nothing in the left column ever moves to the right one." |

## Not captured

Already-Plus, the gift-week timeline, the Season card, the Shop at seven slots, the
calendar export menu, and the accessibility-XL pass.

Not because they do not work — the seven-slot Shop was driven and two layout bugs were
found and fixed through it — but because **every simulator on the machine was deleted
twice by another session while the sweep was running**, and the last two runs landed on
Home instead of the screen they were aimed at. Rather than ship six files whose names
promise screens they do not show, they are gone.

`test/plus-shots.sh` is the script. It needs one simulator that stays alive, and
`-plusOn` to reach the paid surfaces without `-unlockAll` emptying the shop.
