# Prompt for Claude Design — Friends v3, part C: the Yard, moments, Daily Word strip, same class

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the line.
Attach `design/screenshots/22-friends-v2.png`, `20-kin-root.png` (the scene system),
`04-games.png` / `09-dailyword.png` (Daily Word), and `design/FRIENDS-PLAN.md`.
Reference frames: Finch Tree Town, Instagram story tray and viewer, from
`design/reference/`.

---

Parts A and B made friends real and gave them one thing to do together. Part C is what
the tab looks like on an ordinary day when nobody is on shift: **a place you visit**, not
a list.

## What exists in code

- Five owned scenes (`Scene0`: Lagoon, Reef, Kelp, Dusk, Deep) as full-bleed
  art, with a light/dark flag and `GlassPill(onDark:)` for pills over dark art.
- The kin row, "This week" card and friend list from the current tab.
- Daily Word (`WordleView.swift`): five letters, six tries, 30 coins once a day, a
  30-word bank. The Games tab has a **Versus** card that says "Needs a friend".
- The Chrome extension knows the student's real Canvas course names. Sharing them is
  **off by default** and per course (part A's privacy sheet).
- The ledger: every task, focus minute, lesson and word the student finished, with a
  day key. Moments are generated from it — there is no camera and no upload.

## Screens I want back

### 1. The Yard
The top of the populated tab, replacing the plain kin row. Friends' kin standing in
**your** equipped scene, dashed KIN boxes with coat and stars, your own kin among them.
A friend on shift right now is drawn focused (caption the emote). A friend who has not
opened the app today is simply not in the yard — never greyed, never asleep-as-a-
punishment, never "last seen". Show it at one friend, four friends, and on the dark scene.
Tapping a kin opens the friend card from part A.

### 2. Today (the moments row)
Under the Yard: a horizontal row of small cards, one per friend who did something today,
with an unseen ring in `Theme.coral`, Instagram-shaped. Each card is that friend's kin
plus **one** thing they did, generated: "Focused 45 min", "Finished Compound interest",
"Solved the word in 3", "Grew to 2 stars", "Adopted Wisp". Never a count of things not
done. Show unseen and seen.

### 3. Moment viewer
Full bleed, their scene, their kin large, the one line, a tap-through to the next
friend (left half back, right half forward, same as the lesson reader). Across the
bottom, the **fixed reaction row**: the six vibe cards from part A, one tap, no text.
Show it with one reaction already sent.

### 4. Daily Word friends strip
On the Games tab's Daily Word card, and on the word screen after solving: a strip of
friends' kin with how many tries each took today. **Letters and guesses stay hidden until
you have solved it too**; before that the strip only shows who has played. Two states:
before you solve, after. This is also where **Versus** becomes real: same word, same day,
the fewer tries wins nothing but a line in the moment ("Beat Josh by a guess"). No coins
change hands for winning. Redraw the Versus card on Games so it reads as this, not as a
locked game.

### 5. Same class
A card on Friends, only when at least one friend has opted in to the same course:
"You and Maya both have BIOL 12 — Quiz 3 Friday." Tap → the Focus invite from part B
with that task riding along. When no course matches, the card is absent. Also draw the
per-course opt-in list in the privacy sheet (course names come from Canvas; a toggle per
course, all off).

### 6. This week, together
The group card from part A, now with the Yard above it: confirm it still reads as the
calm bottom of the tab rather than a dashboard. If the tab has become too long, tell me
what to cut. Prefer cutting the friend list (the Yard replaces it) over cutting anything
else.

## Rules specific to this brief

- Every moment is auto-generated from the ledger. No photos, no camera, no captions, no
  stickers, no custom status.
- Reactions are the six fixed vibe cards. No comment field, ever.
- Nobody is ever shown as absent, behind, quiet, or inactive.
- Course names are personal data. They appear only when both sides opted in, and never
  in a moment or a notification.
- Winning Daily Word against a friend pays nothing. Finishing it pays 30, as today.

## What I want back

Six artboards (the Yard at three sizes, the strip in two states), every string, the
generated-moment copy rules as a table (event → line), and the state you need per
friend per day. Tell me what you changed and why.
