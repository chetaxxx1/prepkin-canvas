# Grok handoff — the tank shop, everything so far, and what to build next

Written 2026-09-12. Three paste blocks. Paste them in order into one Grok chat
(Grok Imagine by hand, or the Ink bot). Attach these five files to the first message:

| attach | what it is |
| --- | --- |
| `design/tanks/GROK-TANK-PROMPTS.md` | the full pack: every theme's six prompts, loose pieces, earned pieces, prices |
| `~/Downloads/Sprout-handoff/public/tanks/reef.png` | style reference for LIGHT tanks |
| `~/Downloads/Sprout-handoff/public/tanks/deep.png` | style reference for DARK tanks |
| `design/tanks/trial/set/treasure-set.png` | a finished six-piece tank, so it sees the target |
| `design/tanks/trial/set/orbit-set.png` | the same on a dark tank |

Block 1 is the brief. Block 2 is the job queue. Block 3 is the boundary, sent as its
own message after the first two, the way the bot roster says to. Make Grok read the
rules back before it paints anything; if the read-back is wrong, the rules are wrong.

---

## Block 1 — the brief (paste first, with the five attachments)

```text
You are painting the shop for Prepkin, an iPhone study app for US college students
aged 18 to 24. The mascot, Sprout, is a small vector fish who lives in a tank on
the Home tab. Students earn coins by finishing Canvas assignments and spend them
on the tank and on pieces that go in it. You paint the tank and the pieces. You
NEVER paint Sprout. Read all of this, then read the rules back to me in your own
words before you paint anything. If your read-back is wrong I will correct it
first.

## What exists already
- Five tanks ship today (Lagoon, Reef, Deep, Kelp, Dusk). The attached reef.png
  and deep.png are two of them and are the STYLE LOCK: soft matte modelling clay,
  gentle pastel studio light, fine matte grain, soft shadows, zero gloss.
- Fifteen new themes are designed and prompted in the attached
  GROK-TANK-PROMPTS.md: Treasure, Castle, Zen, Frost, Vapor (light); Disco,
  Orbit, Arcade, Lantern, Magma (dark); Library, Cottage, Lofi, Court, Haunt
  (the five that fill gaps for 18–24s: dark academia, Ghibli-cottage, lo-fi
  night desk, a sport, an October drop).
- A tank is SIX images, not one. The attached treasure-set.png and orbit-set.png
  show what six images become once my code assembles them.

## The six pieces of a tank
1. TANK — the painting. Wall, a ridge of mounds on the horizon, a light shaft,
   two or three flat discs tucked against the far edges, side dressing hugging
   the far edges, a BARE floor, and EMPTY top corners.
2. STAND L and 3. STAND R — the two key objects. Each painted ALONE on flat
   magenta. My code stands them on the floor just inside each side.
4. CORNER L and 5. CORNER R — things that hang from the top edge in the top
   corners (a net, a vine, string lights, a neon sign, a cobweb). Alone on
   magenta, touching the top edge.
6. LIGHT — a lamp on a cord from the top edge. Alone on magenta, glowing. Its
   colour becomes the colour of the tank's light rays in the app.
Any piece fits any tank, because my code keys, sizes, tints and places them.
That is the whole shop: fifteen tanks times every piece a student owns.

## The rules that make it work — these are measured by code, not by eye
- FLOOR RULE: the floor is a bare, flat plane from the horizon to the bottom
  edge. NOTHING stands on it. Everything painted stands ON the horizon line as
  part of the ridge, hangs from the top, or is tucked against the far left or
  right frame edge, half out of frame. A chest my code places must land on
  sand, not on a coral cluster. This rule failed once and the whole tank was
  thrown away.
- HORIZON: where the wall meets the floor sits EXACTLY two thirds of the way
  down, level across the frame, on every tank. Same height everywhere, so a
  prop's feet touch the ground in every tank.
- EMPTY MIDDLE: the middle third of the frame, from a seventh of the way down
  to the bottom, is empty wall and empty floor. Sprout lives there.
- EMPTY CORNERS: the top corners are plain wall. The corner pieces and the lamp
  are separate images.
- NO SIDE WALLS: the back wall runs edge to edge. No room corners, no box.
- BOTTOM FIFTH: plain floor from edge to edge. It fades into the page colour.
- LIGHT TANKS keep the top fifth pale; a dark clock sits on it.
- STYLE: the attached reef.png and deep.png, exactly. Two ridges of mounds for
  depth (a far pale one, a nearer deeper one) with the theme's shapes worked
  in. Themed relief on the upper wall corners only. Muted pastel, never candy.
  Pinterest-aesthetic, never toy-like. Props have no faces (the Haunt pumpkin
  is the one exception the pack names).

## The image specs
- TANK: 4:3 landscape if you have it, else 3:2. Largest export. PNG.
  Name it <theme>-tank.png.
- STANDS: 1:1, one object centred with about a quarter of the frame empty on
  every side, on flat magenta #FF00FF corner to corner, no floor, no shadow.
  <theme>-left.png and <theme>-right.png. A pink or purple object goes on green
  #00FF00 instead; say so in the delivery.
- CORNERS and LIGHT: 3:4 tall. The cord, chain or stem touches the TOP edge;
  everything else inside the frame; flat magenta. <theme>-tl.png,
  <theme>-tr.png, <theme>-light.png. The lamp's colour is given per theme in
  the pack as --light-color; match it.
- Same clay, same light, same softness on every piece as on the tank it is for.
- Four options per image. State the hexes you used under each delivery.

## How to work
- Take the prompts from the attached pack verbatim; they already carry the
  STYLE, EMPTY, PROP, CORNER and LIGHT sentences. Do not improve the wording.
- Before you deliver a tank, check it against the rules above like a checklist
  and say which line you checked. My code will check it again.
- If a rule and a theme fight (a night market wants lanterns on the floor), the
  rule wins: put them on the ridge or against the far edge.
- Ask one question at a time, only when a rule genuinely blocks you.
```

---

## Block 2 — the job queue (paste second)

```text
Build in this order. Finish a job before starting the next. Deliver each theme as
its six files plus one contact sheet.

JOB 1 — the launch five, light tanks first because the app's status bar needs
them: Treasure, Castle, Zen, Frost, Vapor. Six images each, from the pack.

JOB 2 — the dark five: Orbit, Disco, Arcade, Lantern, Magma. Orbit came back as
a boxed room twice in testing; "no side walls" is not optional.

JOB 3 — the gap five: Library, Cottage, Lofi, Court, Haunt. Haunt must be done
before October 1, 2026; it sells only that month.

JOB 4 — the twelve loose pieces in the pack ("Loose pieces — theme-free"):
coffee, books, laptop, plant, trophy, radio, pennants, planes, lights,
calendar, desk lamp, moon lamp. Same PROP / CORNER / LIGHT sentences, no tank.

JOB 5 — the seven earned pieces in the pack ("Earned pieces — not for sale").

JOB 6 — only after jobs 1 to 5 are delivered: PITCH, do not paint, five more
themes and ten more loose pieces. A pitch is one line per item: name, light or
dark, the two stands, the two corners, the lamp and its hex, and one sentence
on which 18–24 taste it serves and why nothing in the fifteen covers it. Use
the same evidence the fifteen came from: the top BetterCampus community theme
is Ghibli, students asked the Canvas skin for Dark Academia, Lo-fi, Cottage,
Midnight and Matcha, the top Stylus Canvas theme is Tokyo Night, soft pastel
companions skew ~75% women so competition and loot keep men, and seasonal
drops keep a launch cohort coming back. I approve the pitch; then you paint.

Delivery format, every job:
- The image first. Then one line: file name, size, the hexes used, which rules
  you checked.
- A contact sheet per theme: the tank and its five pieces in one image.
- Never a paragraph about the creative direction.
```

---

## Block 3 — the boundary (paste as its own message, after the other two)

```text
Absolute boundary, now and every future run. NEVER draw Sprout, any fish, any
animal, any person, or a face on a piece. NEVER put text, letters, numbers or
logos in an image. NEVER paint a piece into a tank; tanks are empty, corners
included, and pieces are alone on magenta. NEVER put anything on the floor
plane or in the middle third. NEVER paint bubbles, sparkles or floating dots;
the app animates its own. NEVER invent a theme or a piece outside the pack
without pitching it first and hearing yes. Read these back before you start.
```

---

## What comes back, and what happens to it here

Save a theme's six files as `~/Downloads/<theme>-{tank,left,right,tl,tr,light}.png`, then:

```bash
python3 design/tanks/check_tank.py ~/Downloads/<theme>-tank.png --empty
python3 design/tanks/compose_tank.py --id <theme> --tank ~/Downloads/<theme>-tank.png \
  --left ~/Downloads/<theme>-left.png --right ~/Downloads/<theme>-right.png \
  --tl ~/Downloads/<theme>-tl.png --tr ~/Downloads/<theme>-tr.png \
  --light ~/Downloads/<theme>-light.png --light-color '<hex from the pack>' \
  --out ~/Downloads/Sprout-handoff/public/tanks/<theme>.png \
  --layers ~/Downloads/Sprout-handoff/public/tanks/ios
python3 design/tanks/check_tank.py ~/Downloads/Sprout-handoff/public/tanks/<theme>.png --id <theme>
```

The first line refuses a dressed floor. The second refuses a stage that is not
bare and reports any piece hidden under Home's chips or the Dynamic Island. The
third must print PASS and writes the surfaces sheet. Then the cutter, `tanks.ts`
and `Theme.swift`, as section 3 of the pack says. A stand-in for anything Grok is
slow on: the same prompts run through Gemini, once the AI Studio credits are
topped up (they ran out on 2026-09-11).
