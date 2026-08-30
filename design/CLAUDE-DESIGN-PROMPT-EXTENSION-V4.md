# Claude Design briefs — Prepkin extension v4

Paste-ready prompts for the next round of extension screens. Each prompt stands
alone. Always paste the **shared constraints block** (bottom of this file) after
the prompt, and attach the reference links listed with it.

## Why these screens (research, 2026-08-30)

Better Canvas rebranded to **BetterCampus** and moved its best features behind a
**$19/month** subscription. Its own feedback board and Reddit are full of angry
students. One school district **banned it** after it broke Canvas quizzes. What
students loved when it was free, in order of how often it comes up in reviews:

1. **Personal themes** — "my cute custom themes made me feel so much more
   motivated", "hello kitty themed has saved me academically". Emotional, not
   cosmetic.
2. **Dark mode** — the single most-installed reason. Canvas has no native web
   dark mode and students have asked since 2018.
3. **Seeing every due date in one place** without clicking into each course.
4. **Grade visibility** — one reviewer caught a grading error and got an A.

Biggest complaints: the paywall, forced AI features, themes that got taken away,
and breakage that gets it banned by school IT. Prepkin's angle: free, doesn't
rewrite Canvas's code (API only), rewards are verified, and it has a phone app.

---

## Prompt 1 — Dark mode (highest demand)

```
Design the dark theme for Prepkin, a Chrome extension that reskins Canvas LMS
and shows a slime mascot buddy panel. The light theme exists (see attached
screens): warm cream surfaces, mint accent, ink #101820, rounded 16px cards
with 1px inset borders, pressable mint buttons with a darker bottom edge.

Make the dark version feel like the same warm brand at night — NOT a generic
gray dark mode. Think warm charcoal with a slight brown-green cast, cream text,
the same mint #51CFA0 accent, and the slime staying exactly its daytime colors
(the mascot never recolors).

SCREENS
1. Buddy panel, happy state, dark (360px wide) — same layout as the light one.
2. Restyled Canvas dashboard in dark: page background, course cards with color
   strips, sidebar.
3. The extension popup in dark, including the theme toggle row states.

RULES
- Body text must pass WCAG AA on every surface.
- The dark coin chip from the light theme needs a new treatment (it can't be
  ink-on-ink) — try mint-on-ink or cream-on-ink.
- No pure black (#000) and no pure white anywhere.
```

## Prompt 2 — Theme shop: slime looks + Canvas palettes (the emotional hook)

```
Design the "Looks" screen for Prepkin. Students loved BetterCampus for cute
custom themes ("hello kitty themed saved me academically") — ours are earned
with coins instead of bought with a subscription, and they restyle BOTH the
Canvas page and the slime's accessories at once.

A look = a named palette (page tint, card tint, accent) + one slime accessory
(a beanie, round glasses, a tiny scarf, a sprout on the head). The slime's body
color and face NEVER change — accessories sit on top of the fixed mascot art.

SCREENS
1. "Looks" tab in the extension popup (340px): a 2-column grid of look cards,
   each showing a mini slime wearing the accessory on a swatch of the palette,
   a name, and either a coin price (e.g. 300) or "Owned". Current look has a
   mint ring. Locked looks show the coin icon, never a padlock-and-shame vibe.
2. One Canvas dashboard screenshot restyled by a non-default look, so we can
   see how far a palette is allowed to push (answer: tints and accents move,
   layout and type never do).
3. The confirm sheet: "Wear Woodland? 300 coins" with the slime previewing it.

TIE-IN: coins come from the phone app's ledger (verified Canvas submissions,
30 coins each). Show balances small and calm — this is a treat, not a casino.
```

## Prompt 3 — Focus timer in the buddy panel (ties to the app's Focus mode)

```
Design a focus timer state for Prepkin's 360px buddy panel on Canvas. The
phone app already has a Focus mode; this is its desktop twin. A student picks
a task ("Problem Set 4 · MATH 221"), presses Start, and the panel collapses to
a small floating card while they work in Canvas.

STATES
1. Setup: the Next-up card grows a "Focus" option next to Start — choose 15 /
   25 / 45 minutes as pills.
2. Running (compact, ~280px card): big minutes remaining, the task title, the
   slime sitting beside the countdown, a quiet "Give up for now" text link (no
   shame copy — "Stopping is fine. It'll be here.").
3. Done: slime delighted, "+10 coins on your phone" chip, and the task's Start
   link ("Open the assignment") as the primary action.

RULES: the timer never overlays Canvas content in a blocking way, never plays
sound, and the countdown type is the biggest thing on the card.
```

## Prompt 4 — Week planner view (the "everything in one place" ask)

```
Design the expanded "This week" view for Prepkin's buddy panel (360px). The
collapsed panel shows a flat list; this view groups by day so a student plans
the week without opening any course — the #1 practical thing students praise
Canvas extensions for.

LAYOUT
- Day sections: TODAY, TOMORROW, then weekday names, then "NO DUE DATE" last.
- Each day header: label + tiny total ("2 due"). Days with nothing are omitted,
  except today, which always shows (empty today = "Nothing due. Enjoy it.").
- Rows: 3px course-color bar, title, course code, due time, points. Submitted
  rows stay visible with a check and strikethrough for the satisfaction.
- A slim week progress strip at top: 7 dots, one per day, filled when that
  day's work is all submitted. NO streak language anywhere — this is a map,
  not a scoreboard.
```

## Prompt 5 — First-run onboarding (nobody designs this and everybody needs it)

```
Design Prepkin's first-run flow in the extension popup (340px). Today a new
student sees an empty popup and has to guess. Three steps, one screen each,
with the slime guiding:

1. "Hi, I'm your buddy" — slime waves (static pose), one sentence on what
   Prepkin does, "Let's set up" button. Small print: free, no account.
2. "Connect your school" — detects the current tab ("You're on
   canvas.stateu.edu") with one Connect button; or instructs "open your
   school's Canvas page first" if not on one.
3. "Link your phone (optional)" — pairing code input, a tiny phone mockup
   showing where the code lives in the app, and a clear "Skip for now".

Progress: three dots at the bottom. Every step skippable. Tone: calm, zero
setup anxiety, no permissions jargon — say "so Prepkin can read your
assignments" not "grant host permissions".
```

## Prompt 6 — Grade trends + what-if entry (steal Canvas Grades Pro's demand)

```
Extend Prepkin's grades card (in the 360px buddy panel). Today: course rows
with a colored mini progress bar and a GPA estimate. Add:

1. A tap-to-expand course row: expands to show a small grade-trend sparkline
   (last 8 graded assignments), the three most recent grades as rows
   ("Quiz 5 · 13/15"), and a "What do I need on the final?" button.
2. The what-if screen exists (attached) — restyle only if needed for
   consistency with the expanded row.
3. A tiny "updated 2 min ago" freshness note under the GPA row.

RULES: trends are neutral — a falling sparkline is drawn in the course color,
never red. No warnings, no "at risk" labels. The data is the student's own
business; we display, we don't judge.
```

---

## Shared constraints block (paste after every prompt)

```
BRAND CONSTRAINTS (do not deviate)
- Mascot: Prepkin's slime. Use the attached renders exactly — body #51CFA0,
  belly #B1EDD4, face/ink #101820. The face is always drawn by code from an
  approved expression set; never invent new faces, never recolor the slime,
  never replace it with another character. Accessories may be layered on top.
- Palette: cream page #F0EEE9, card cream #F4F1EA, white cards with 1px inset
  border #EAE5DA, ink text #33291F, secondary #8A7A66, mint #51CFA0, deep
  green #2E7D57, amber #DE9A22. Course colors come from Canvas, not from us.
- Type: Nunito (weights 400–900). 11px uppercase 800 labels, 12px meta, 14px
  body, 16px headings. Never below 11px.
- Shape: 16px card radius, 12px button radius, 999px pills. Primary buttons
  are mint with a 3px darker bottom edge (pressable, Duolingo-style).
- Sizing: buddy panel 360px wide; popup 340px; floating tab 64px circle.
- Tone: calm and non-shaming. No streaks, no red urgency walls, no guilt copy.
  Overdue = amber and "still counts", never alarms.
- One dark ink accent per surface (the coin chip). Everything else stays warm.
```

## References to attach alongside the prompts

- **Our v3 canvas** (current shipped design):
  https://claude.ai/code/artifact/bf0bdd5b-d0a6-4489-a2be-805192040522
  Export the buddy-panel and popup artboards as PNGs and attach them.
- **Slime renders**: screenshot the panel from the live extension (both faces)
  so the mascot is copied, not redrawn.
- Finch home (mascot + daily goals + progress):
  https://mobbin.com/screens/f4a915f9-425c-45c9-9d34-7da294122379 and
  https://mobbin.com/screens/e7f40efd-01a8-4f03-828e-31db0c35dbc2
- Duolingo (pressable buttons, game warmth): https://duolingo.com
- Family.co (cream canvas, inset borders, mascot-overlap): https://family.co
- What to study, not copy — BetterCampus product page (their widget/planner
  scope): https://bettercampus.com/product ; Tasks for Canvas (progress rings,
  completion delight):
  https://chromewebstore.google.com/detail/tasks-for-canvas/kabafodfnabokkkddjbnkgbcbmipdlmb

## Build notes (for us, not for Claude design)

- Focus timer pays 10 coins in the app's terms (`TaskKind.study` is 20,
  Wordle is 30) — confirm the amount against the iOS ledger before shipping,
  and route it through the bridge so the phone pays it, not the extension.
- Theme shop needs the app to push owned-looks + balance to the extension —
  today the bridge is one-way (extension → app). New RPC needed.
- Grade trends need per-assignment submission history — we already fetch
  assignments with submissions, so it's a mapping change, not a new API call.
- Week view and onboarding are pure extension work, no bridge changes.
