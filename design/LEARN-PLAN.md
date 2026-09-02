# Learn v2 — plan (2026-08-31)

What the Learn tab becomes, why, and what has to exist before code starts.
Reference: `design/reference/imprint/` — 17 frames pulled from George's Imprint
screen recording (`~/Downloads/Imprint.MP4`, 85s, iPhone).

---

## 1. What Imprint actually does

Watched frame by frame. The mechanics worth copying, in order of value:

1. **One figure that accretes.** A lesson has *one* drawing, not one per card. The
   iceberg appears bare, then gains the word UNCONSCIOUS, then a CONSCIOUS pill and
   arrow, then a pink PRECONSCIOUS band, then a SUPER-EGO wedge inside it. Eight cards,
   one picture. This is the whole trick. It gives continuity that a slideshow of
   unrelated art cannot, and it costs one artwork per lesson instead of eight.
   (`04-` through `08-figure-build-*.png`)
2. **Tap zones, not swipe.** Left half = back, right half = forward. A one-time coach
   overlay teaches it (`03-tap-zones-tutorial.png`). Swipe is a fallback, not the
   primary gesture. Faster than swiping, and it keeps one thumb on the screen.
3. **Card is 55% picture / 25% text / 20% chrome.** Body copy is 2–4 short lines,
   left-aligned, never centred, never a paragraph.
4. **Named card types.** Figure card, "Key Idea" card (label + one all-caps sentence,
   no figure), example card ("For example, imagine you're bored in a meeting"),
   text-only card. The variety is what keeps a 20-card deck from feeling like one long
   scroll.
5. **A preview sheet before Start.** Cover art, category pill, title, "What you'll
   learn" in three lines, "You may also like", one big Start button. You know the
   size of the commitment before you commit.
6. **Course map after the lesson.** Vertical path, green checks behind you, the next
   node calls out with a Start button, locked nodes are grey.
7. **Progress that isn't only a streak.** Level ("Level 2: Thinker"), total XP, weekly
   XP line chart, achievements with progress bars, and per-topic Learning Levels.

What Imprint does that we should **not** copy:

- **Streak pressure.** "Reach 3 day streak · 1 day to complete" and a Daily Challenge
  that resets to 0/3. Our whole position is that nothing punishes you for a quiet day.
- **XP as a second currency.** We already have coins. Two scoreboards is one too many.
- **No character.** Imprint is clean and completely impersonal. That gap is our opening.

---

## 2. What we build

Four screens. Learn goes from one flat list to a real place.

### A. Learn (tab root) — replaces the current flat list

Top to bottom:

- **Continue** — the deck you're partway through, with a thin progress bar. Absent if
  you have none. (Imprint's "Jump back in".)
- **Because of your week** — 1–2 lessons chosen from your *real* Canvas assignments.
  "Bio quiz Friday → How to study for a science quiz." Nobody else can do this; it is
  the single strongest reason this tab exists inside this app instead of Imprint.
  If Canvas is not connected the section simply isn't there. Never an empty state.
- **Today's card** — one lesson picked for today, +20 coins, rolls over at midnight.
  Sits next to Daily Word as the second small daily ritual.
- **Tracks** — grid of track cards, each with a drawn icon and a progress ring
  (3 of 8). Replaces today's emoji rows (💸 🧾 🏛️), which are the weakest thing on the
  current screen.
- **Saved cards** — entry to the review deck.

### B. Track map — pushed, tab bar hidden

Vertical path of 6–10 lesson nodes alternating left and right. Done nodes are mint with
a check. The current node is coral, larger, and the slime is sitting next to it. Locked
nodes are cream circles with a dot — **no padlocks**; a padlock reads as a wall. Path
ends in a track badge you keep. No "Unit 1 / Unit 2" headers; a track is one run.

### C. Lesson deck — the core, replaces `LessonView`

Full bleed, tab bar hidden (`hidesTabBar()` already supports this).

```
X          ▬▬▬▬▬▬▬───────────        <- thin segmented progress, no title
┌───────────────────────────┐
│                           │
│        the figure         │        ~50% of the height
│                           │
└───────────────────────────┘

  Two to four short lines of body            <- 19–20pt, left aligned
  text. Never a paragraph.

  ( ♡  ⤴  ⚐ )              ( Ask Kin )       <- pill row + slime AI button
```

- Tap right half → next. Tap left half → back. Swipe works too. Coach overlay once.
- Card kinds: `figure`, `key`, `example`, `check`, `finish`.
- `key` — no figure. "Key Idea" label, one all-caps sentence in a tinted card, slime
  peeking in from the edge. This is the card people screenshot.
- `check` — one recall question at the end. Wrong costs nothing, explains, moves on.
  Retrieval practice is the highest-value 20 seconds in the whole deck.
- `finish` — "Finish · +20 coins", slime celebrates, coins fly to the chip.

### D. Saved cards — the review deck

Hearting a card during a lesson saves it. Saved cards resurface as a Home task
("Review 5 saved cards, +10") a few days later. This closes a loop the app already
preaches: `study-1 Spaced practice beats cramming` currently teaches spacing and then
does nothing with it.

---

## 3. Six things we add that Imprint doesn't have

| # | Addition | Why |
|---|---|---|
| 1 | **The slime teaches.** Appears on the Key Idea card, the check card, and at Finish — not on every card, where it would fight the figure. | Imprint is impersonal. The character is the product. |
| 2 | **Canvas-aware picks.** Lessons chosen off your real due dates. | Unavailable to any competitor. |
| 3 | **Coins, not XP.** One currency, already spends on chibis and scenes. | Two scoreboards is one too many. Rule holds: pay for finishing, never for correct. |
| 4 | **A check card.** One recall question per deck. | Testing beats rereading. Imprint never asks you anything. |
| 5 | **Saved cards become a review task.** | Turns a bookmark into a habit. |
| 6 | **No streak.** "8 lessons this month" — a number that can only go up. | Imprint's "1 day to complete" is exactly the pressure we refuse. |

---

## 4. Data model — what the content pipeline has to produce

`lessons.json` grows from `pages: [String]` to typed cards. Existing lessons still
load: a bare string becomes `{"kind":"figure","body":...}` with no figure.

```json
{
  "id": "study-forgetting",
  "track": "study-skills",
  "title": "Why cramming fails",
  "kicker": "The forgetting curve",
  "minutes": 2,
  "reward": 20,
  "blurb": "Why the same hour of study is worth double when you split it.",
  "figure": "forgetting-curve",
  "cards": [
    { "kind": "figure",  "show": ["axes"],                    "body": "..." },
    { "kind": "figure",  "show": ["axes","curve"],            "body": "..." },
    { "kind": "figure",  "show": ["axes","curve","review-1"], "body": "..." },
    { "kind": "key",     "body": "REVIEWING BEATS REREADING" },
    { "kind": "example", "body": "..." },
    { "kind": "check",   "q": "...", "choices": ["...","...","..."],
                         "answer": 1, "why": "..." }
  ]
}
```

**`figure` + `show` is the accretion mechanism.** One drawing per lesson, cut into named
layers. Each card lists which layers are visible. The renderer cross-fades layers in and
out with an 8pt rise. One artwork serves the whole deck.

**Shipping the layers.** SwiftUI has no SVG renderer. Cheapest path with no new
dependency: export every layer as its own vector PDF into
`Assets.xcassets/fig-forgetting-curve/axes.pdf`, `curve.pdf`, … and stack them in a
`ZStack` with per-layer opacity. The repo already converts SVG to paths for the mascot
(`design/canvas/mascot-paths.json`, `design/rive/gen_layers.py`), so that route stays
open if a figure needs to animate rather than just appear.

**Figure palette.** The app's cream/coral/mint system is deliberately low-chroma, and
diagrams need more. Figures get the one licensed exception, same as the room scenes:
flat vector on white, 2pt ink outline `#2E2822`, at most **three** fills per figure from
slime `#51CFA0` · sky `#9BC8F2` · lavender `#C3B2F0` · coin `#FFC24B` · coral `#FF6F61`
· leaf `#A5CE6B`, on paper `#FAF5EC`. No gradients, no shadows, no 3D.

---

## 5. Defaults I picked — flip any of these

1. **No units on the track map.** 6–10 lessons is one run; Imprint's Unit 1 / Unit 2 is
   for 40-lesson courses we don't have.
2. **The check card pays nothing extra.** Getting it right earns no coins, because the
   economy rule says finishing pays and correctness doesn't. Finishing the deck pays.
3. **Slime appears on 3 cards, not all of them.** On every card it would compete with
   the figure it's meant to be explaining.
4. **Ask Kin is drawn but stubbed for v1.** Imprint's ASK button is an AI tutor. Ours
   should exist in the design so the layout is right, and open a "coming soon" sheet
   until there's a model behind it.

---

## 6. Order of work

1. Claude Design returns artboards (prompt: `CLAUDE-DESIGN-PROMPT-LEARN-V5.md`).
2. Extend `Content.swift` for typed cards, keeping string-page decoding working.
3. Build `LessonDeckView` with tap zones + layered figure, one hand-built figure to
   prove it.
4. Rebuild `LearnView` root + `TrackMapView`.
5. Saved cards + the Home review task.
6. Author 8 lessons with figures. **This is the long pole** — every lesson needs a
   drawn, layered figure. Budget accordingly; the code is a week, the content is not.
