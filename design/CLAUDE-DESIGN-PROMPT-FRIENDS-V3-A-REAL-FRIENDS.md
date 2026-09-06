# Prompt for Claude Design — Friends v3, part A: real friends

**How to use.** Paste `design/CLAUDE-DESIGN-PREAMBLE.md`, then everything below the line.
Attach `design/screenshots/22-friends-v2.png` (today), the current handoff
`design/handoff-friends/Friends Tab.dc.html` + `README.md` + `BUILD-NOTES.md`, and
`design/FRIENDS-PLAN.md`. Reference frames: `design/reference/README.md` (Finch Tree
Town, Instagram close friends, Dolphin SAT).

---

The Friends tab you drew is built (`22-friends-v2.png`). It is also **entirely mock**:
four sample people, a Cheer that changes local state and sends nothing, an Add that
sends nothing. The one real thing is the student's **friend code** (`GameState.friendCode`,
eight characters from the alphabet `A–H J–N P–Z 2–9`, generated on first open).

Part A designs the screens that turn a code into a real friend. Part B is Study
Together, part C is the Yard and moments. Each is its own request.

## What exists in code

- `Friend { id, name, speciesID, level, weekCoins, lastActivity }` in
  `Core/GameState.swift`. Persisted, but nothing writes one yet.
- `pendingFriendCodes: [String]` — codes the student has typed and sent.
- The bridge is Supabase, keyed by codes, no accounts. A friend profile will be:
  friend code, display name (the student types it, 14 characters max, same rule as
  naming a kin), active kin species and stars. That is the **whole** profile.
- `1a` zero-friends and the **Add a friend** pushed screen exist and are good. Keep them.
  Note the build note: 1a is unreachable today because the sample list never empties;
  after this handoff a new install starts with zero friends, so 1a becomes the first
  thing every user sees. Recheck it with that in mind.

## Screens I want back (one artboard each, on the existing tab)

### 1. Request received
A code was typed on the other phone. It arrives as a card at the top of the Friends
tab (and as a local notification, one line of copy for that too). Card shows their kin
(dashed KIN box, their coat and stars), their name, and two actions: **Add back** (coral)
and a quiet **Not now**. No "Decline", no "Block" here — the quiet menu on the friend
card has those. Show the card in place on the populated tab.

### 2. Request accepted
The moment both sides are friends. A `KinToast` is enough on the sender's side ("Maya
added you back"). On the receiver's side the card from screen 1 collapses into the kin
row. Draw both. If you think it deserves more than a toast, show the alternate and say
why.

### 3. Friend card (sheet)
Tap a kin anywhere. A sheet: their kin large, name, `StarPips`, "Friends since
{date}", and **what they did today** as at most three lines generated from their ledger
("Focused 45 min", "Finished 3 tasks", "Solved the word in 4"). Nothing about what they
did *not* do. Then a **Send a vibe** row (a picker of six fixed drawn cards — design the
six: nice one, keep going, proud of you, same here, coffee?, high five — as flat vector
in the palette, no words on the card face beyond a short label under it), a **Study
together** button (part B; draw it disabled-looking-nothing-like-disabled with the
caption "Coming with Study Together"), and the quiet **···** menu.

### 4. The quiet menu
Remove friend · Block · Report. A plain list sheet. Remove is instant and silent on
their side. Block removes and stops their code from ever reaching this phone again.
Report sends the friend code and nothing else; the app has no free text so there is
nothing to attach. One line of copy under each explaining exactly that. Confirm step
only on Block and Report, coral text, never red.

### 5. Privacy & safety
A settings sheet reached from the `···` on the Friends title row. Rows, each a toggle,
each with one plain line under it, **all sensitive ones off by default**:
- Show my week's coins to friends (on)
- Show what I did today (on)
- Show which of my classes match a friend's (off; this is the Canvas crossover from
  part C, and it needs a per-course list under it)
- Let friends invite me to study together (on)
Plus a static block: "Friends can never see your assignments, grades, or school." and
"You can only be added by someone who has your code."

### 6. The weekly card, corrected
Today's "This week" board is a ranked coin list with You pinned. My plan says ranking is
**opt-in** and, if shown, ranks **focus minutes**, not coins. Redraw that card as a
**group total by default** ("You and 4 friends: 41 tasks, 6h focus, 3 words") with a
small **Show the board** toggle that reveals the ranked version on focus minutes. Both
states.

## Rules specific to this brief

- No free text anywhere. The display name is the only thing a student ever types, and
  it is typed once in first run, not here.
- Nobody is ever shown as absent, behind, or inactive. A friend who has not opened the
  app today simply has no "today" lines.
- The kin row, the friend list and the Cheer button are already built. Do not restyle
  them. Cheer stays one fixed clap; it is the same mechanism as a vibe and should
  become one of the six cards.
- The friend code is spoken out loud and typed by hand. Keep it big and monospaced.

## What I want back

Six artboards (some with two states), the six vibe cards as flat vector on one sheet,
every string of copy including the one notification line, and the state you need the
app to store. Say which of these can ship before the Yard exists. Tell me what you
changed and why.
