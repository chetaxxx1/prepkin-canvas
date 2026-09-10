# Commit message for the Home A+ pass (2026-09-10)

Not committed on the day it was written: `AppState.swift` (354+), `GameState.swift`
(461+) and `RootView.swift` (87+) all carry another session's unfinished work, and
`CalendarView.swift` is that session's untracked file. Staging any of them would commit
their work under this message. Use this when the tree is yours alone.

```
Home: close the seven gaps that kept it at A−

The screen every student opens every day, in the four states it actually has.
Nothing rebuilt; the headline, the coin chip, the Day 1 offers, the tank and the
tab bar are untouched.

The level band loses its bar. "3 stars · fully grown" drew a *full* gold capsule
with nothing left to do, which is a meter with a promise it cannot keep
(PRODUCT.md bans meters). StarPips carry the count and the words carry what is
left — "Fully grown" / "Ready for the next star" / "40 to the next" — so the
words never repeat what the pips already draw. The lightning tile went with the
bar: three stars beside the word "stars" was one fact drawn twice. The band is
36pt shorter, which is why one more task row now fits above the fold.

The empty day is no longer blank space. One quiet line under the goals row, muted
12.5pt, never a card and never an ask: "Last list from your laptop 2h ago." when
the laptop has sent one. With a full list the same line only appears once that
list is over an hour old — "From your laptop 2h ago." — so a student looking at
four rows at 11 PM can tell whether they are tonight's four. That cue used to
live only inside Your day.

Deviation from the brief, deliberate: with no laptop and nothing due, there is no
second line. The goals row already reads "Nothing due today" and a second copy of
that sentence directly under it is worse than the space it would fill.

A Tomorrow line under the list: two titles then "and 2 more", from the same two
sources today's list reads — Canvas work and dated tasks — minus the daily
habits, which are on every tomorrow there will ever be, and minus anything
already finished. Tapping it opens the Calendar tab on tomorrow. Absent when
tomorrow is empty; "nothing tomorrow" is not news and a row that is always there
stops being read.

The preset menu leads with school. "Drink a glass of water / 10 minute walk / In
bed by 11" read like a wellness app for 14-year-olds and they were the first
thing an undergrad saw. They are all still there, below "Read for one class",
"Start the thing due Friday", "Email a professor", "Go to office hours" and
"Laundry". Order is the menu: first run lists presets top down and the day editor
shows three of each kind before "more". Same coin bands — the four new study
ones pay 20, Laundry pays 10. A save written before a preset existed now has it
merged in, switched off, in catalogue order; without that a student who installed
in August would never see a preset added in September.

The grade calculator did NOT move. It is the most undergrad-specific thing in the
app and on a four-task evening it starts at y=964 on an 874pt screen, so a busy
student never sees it. Moving it into the pinned header band is a layout change
to the most delicate part of Home — the seam where the tank's floor colour
becomes the page — so it is a Claude Design brief rather than freehand SwiftUI:
design/CLAUDE-DESIGN-PROMPT-HOME-HEADER-BAND.md, queued as 0d. The Calendar
option was ruled out: it means editing the Calendar tab, which is another
session's screen this week.

The widget install card is not built. ios/project.yml has two targets, the app and
its tests, and no widget extension, so the card would open instructions for
something that cannot be installed. Copy parked as a TODO in HomeView.swift.

Tests: HomeTests (20) covers the star words at every stage, the quiet line in all
four combinations, and the Tomorrow line — one title, two, three, four, finished
items excluded, habits excluded, Canvas work included, absent when empty.
DebugUnlockTests (3) proves both chip rails above the mascot follow the
-unlockAll launch argument and nothing else, and reads both sources to prove the
#if DEBUG / #else return false that keeps them out of a Release build. Asserted
as an equivalence, not a flat false, because the scheme's test action inherits
the Run action's arguments — so the test bundle itself runs with -unlockAll.
CopySweepTests gains a Home-and-Your-day-only ban on "behind", "streak",
"catch up" and "falling"; app-wide would fail on the Kin tab, where "the room
behind your kin" is a plain word about where a thing sits.

test/ios-sweep.sh had five tab coordinates and the app has had six since
2026-09-09, so every tab after Home was being screenshotted off by one. Centres
re-measured with idb: 47/107/167/227/287 at y=805, Kin at 361.

Before and after contact sheets, the four Home states, Day 1, and the three
appearances: design/screenshots/home-a-plus-2026-09-10/.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```
