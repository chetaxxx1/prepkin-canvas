# Claude Design prompts — Prepkin Canvas

How to use: paste the **base prompt** first, then any **page prompt**. Do one page
per request. The base prompt sets the app context and style once. Edit the STYLE
block to taste — everything else is the plan we locked.

---

## Base prompt (paste this first, once per session)

```
You are designing screens for Prepkin Canvas, an iOS companion app for high school
students. A cute slime chibi lives in the app (like Finch's bird). The student's
real school assignments flow in from Canvas LMS. Completing daily tasks — school
work, study, and life care — earns coins. Coins upgrade the chibi (3 levels per
chibi) and buy new chibi species in a shop.

APP RULES (never break these):
- Coins pay for FINISHING things, never for grades or correct answers.
- The chibi is a companion, not a meter. It is never sad, starved, or punished.
  It naps, waves, bounces, and celebrates. Giving up a focus session just means
  no coins — no guilt screen.
- 6 tabs: Home, Focus, Games, Learn, Friends, Shop.
- iPhone screens, 390x844 points. Do not draw a fake iOS status bar or keyboard.
- Chibi has 5 preset animations to design poses for: idle, bounce, celebrate,
  wave, sleep. Levels are visual evolutions: Lv1 small and plain, Lv2 bigger with
  blush, Lv3 biggest with a crown.

THE MASCOT (this is a real, finished character — reproduce, don't reinvent):
I'm attaching mascot-idle.png. That IS the character. A chibi slime: soft
dome/bell body, a droplet antenna on top leaning slightly right, two stubby
mitten arms hanging off the sides, a pale oval belly patch low on the front.
No neck, no legs, no outline stroke, no shading, no texture — flat vector
shapes only. Exact palette, never approximate: body #51CFA0, belly #B1EDD4,
eyes/mouth ink #101820. He has 4 approved expressions: idle (round dot eyes +
small crescent smile), deadpan, judging (half-lidded), delight (closed happy
arc eyes + open laughing mouth). His judgment is aimed at the test, never at
the user. Do not restyle him, recolor him, or invent new expressions.

STYLE (edit this block to taste):
- Warm cream background, white cards with soft shadows, large rounded corners.
- Accent colors derived from the mascot: his green #51CFA0 for success and
  positive states, one coral accent for actions and rewards, warm yellow for
  coins. Ink #101820 text, warm gray secondary text.
- Rounded, friendly type. Big numbers for stats and timers.
- Cozy and calm, not gamified-noisy. Think Finch meets a clean planner.
```

---

## 1. Home

```
Design the Home tab. Top to bottom:
1. Header: small date line, big greeting ("Hey, George"), coin count pill on the
   right (coin icon + number).
2. Chibi stage card: the slime chibi front and center on a soft ground shadow,
   its name and level under it ("Slime · Lv 1"), and one upgrade button
   ("Upgrade to Lv 2 · 100"). The button looks disabled when coins are short.
3. "This week" card: four small stats in a row — tasks done, focus minutes,
   words solved, coins earned.
4. A slim row card linking to the Grade calculator ("What do I need on the final?").
5. "Today" card: task list. Each row = check circle, title, a caption line
   (source: Canvas course name + due time, or "Study" / "Life"), and a coin
   reward on the right ("+30"). Done rows are struck through and muted.
6. Tab bar: Home active.
Show one Canvas task, one study task, two life tasks, one of them done.
```

## 2. Focus — set up

```
Design the Focus tab (set-up state). The chibi sits center screen. Under it, a
huge duration number ("25 min") with minus/plus steppers (5–120 min, steps of 5).
A quiet caption: "Finish and earn 25 coins." One big primary button: "Start
focus." Tab bar with Focus active. Calm and airy — this screen should feel like
an exhale.
```

## 3. Focus — running

```
Design the Focus running state. No tab bar. The chibi is asleep (eyes closed,
little z z z). A huge countdown ("18:42"). Caption: "Slime is napping. Stay off
your phone." One quiet ghost button at the bottom: "Give up" — styled gently,
not as a scary red action. Optional: a thin progress ring or bar around the
chibi.
```

## 4. Weekly summary

```
Design the Weekly summary page (opened from Home, back chevron in the header:
"Your week"). A recap card listing the week's numbers with labels: tasks done,
focus minutes, words solved, lessons finished, coins earned. A small "chibi
moment" card: the chibi celebrating with one warm sentence about the week. A
primary button: "Share my week" (renders a shareable card). Honest tone — a slow
week reads as "lighter week", never as failure.
```

## 5. Grade calculator

```
Design the Grade calculator page (back header). RogerHub-style. Card one: three
labeled sliders — "Current grade" (0–100%), "Grade I want" (0–100%), "Final is
worth" (5–100% of grade) — each with its value shown big at the right. Card two,
the result: "You need" caption, a huge percentage ("94.2%"), and a one-line
plain-English verdict under it ("Tough but possible."). Verdict color: mint if
easy or already secured, ink for normal, coral only above 100%.
```

## 6. Connect Canvas (onboarding / pairing)

```
Design the Connect Canvas setup page. Title "Connect Canvas", one line of copy:
"Your assignments show up as tasks automatically." A card with three numbered
steps: 1 Install the Prepkin Chrome extension, 2 Log into Canvas at school,
3 Enter this code in the extension. Below, a large dashed code card showing a
6-character pairing code ("A7X 99Q") spaced for readability. Bottom ghost
button: "I'll do this later." Skipping must feel completely fine — the app works
without Canvas.
```

## 7. Games hub

```
Design the Games tab. Two game cards: "Daily Word" (one word a day · +30 coins,
chevron) and "Versus" (word battles with friends) shown locked with a small lock
pill — locked because friend sync isn't live yet. Below, "Today's leaderboard"
card: ranked rows of friends — rank number, small chibi avatar, name, and their
guess count ("3/6"). Tab bar with Games active.
```

## 8. Daily Word

```
Design the Daily Word play screen (back header). Wordle-style: a 5-column,
6-row letter grid — show two solved rows using our palette (mint = right spot,
warm yellow = wrong spot, warm gray = not in word) and four empty rows. A slim
result banner area between grid and keyboard ("Solved in 3! +30 coins"). Custom
on-screen keyboard: three rows of keys plus GO and backspace, keys tinted by
their known state. Reward is once per day.
```

## 9. Learn

```
Design the Learn tab. Microlessons grouped by track with small section labels:
"Personal finance", "Philosophy", "Study skills". Each lesson row: a small icon
tile, title ("Why compound interest wins"), caption ("4 cards · 2 min"), and on
the right either "+20" (not done, coral) or a mint checkmark (done). Tab bar
with Learn active.
```

## 10. Lesson player

```
Design the Lesson player (back header with the lesson title). One big centered
card holding a short paragraph of the lesson — one idea per card, big friendly
type, an icon up top. Page dots under the card (e.g. 4 pages). On the last page
a primary button appears: "Finish · +20 coins." Swipe-through feel, zero
clutter.
```

## 11. Friends

```
Design the Friends tab. Top: title + "add friend" affordance. Then a horizontal
stories row — circular chibi avatars with names, "You" first with a neutral
ring, unseen friend stories with a coral ring. Card: "This week's coins"
leaderboard — rank, avatar, name, coin count, with "You" bolded in place. Card:
friends list — chibi avatar, name, and a one-line status ("Focused 45 min
today", "Solved the word in 3"). Tab bar with Friends active.
```

## 12. Story viewer

```
Design the Story viewer (full screen, opened from a friend's story circle).
Instagram-story anatomy without the clutter: segmented progress bars at top,
poster's avatar + name + time, and the story content filling the screen — a
friend's chibi celebrating with one big stat ("Maya focused 45 min"). Bottom: a
single rounded input, "Send a cheer…". Stories are auto-generated daily wins,
not photos.
```

## 13. Shop

```
Design the Shop tab. Header with title and coin pill. A 2-column grid of chibi
species cards: the chibi rendered large, its name, and one action — "Use" pill
if owned, price button ("300" with coin icon) if not, "Active" state for the
current one. Owned cards show their level. Include 4 species with distinct
colors (mint slime, coral ember, sky droplet, sunny sprout). A small "Coming
later" card at the bottom (accessories, rooms). Tab bar with Shop active.
```

---

## Extra prompts you may want

**Chibi model sheet** (attach mascot-idle.png and approved-expressions.png)
```
Using this exact mascot (attached — identical body, palette #51CFA0/#B1EDD4/
#101820, same droplet antenna, belly patch, mitten arms), lay out a model
sheet: the 3 levels side by side (Lv1 small plain, Lv2 bigger with blush,
Lv3 biggest with a small crown), and the 5 animation poses as frames: idle
(soft squish), bounce, celebrate (delight face + sparkles), wave (one mitten
raised), sleep (closed eyes, z z z). The 4 attached expressions are approved
and fixed — reuse them; sleep and wave need new poses but keep the approved
face language. Flat vector, no outline, no shading.
```

Note for the shop's other species: the mascot brief covers ONE character. Other
species (Ember, Droplet, Sprout) are recolors/variants that don't exist yet —
treat them as placeholder silhouettes until you approve designs for them.

**Tab bar + component sheet**
```
Design a small component sheet: the 6-item tab bar (active/inactive), the coin
pill, a task row in all 3 states (todo, done, Canvas-sourced with due date), the
primary button, ghost button, stat block, and the upgrade button
(enabled/disabled). Same style as the screens.
```
