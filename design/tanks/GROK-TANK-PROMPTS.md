# Fifteen themed tanks — Grok prompt pack (v2)

Written 2026-09-11, rebuilt the same day, five more added that evening. Fifteen new Home-tab tank scenes for Sprout in
the language of the five that ship (Lagoon, Reef, Kelp, Dusk, Deep): two classic
aquarium scenes, then eight the 18–22 crowd would actually pick.

**What changed in v2.** v1 asked for one painting per tank with the props painted
in. The test renders put every prop against the frame edge — image models do that
no matter how the placement is worded — and every surface in the app crops the
plate a different way, so the chest was half gone on Home and the disco speakers
were slivers in the shop. Now each tank is **three images**: an EMPTY tank, and
two props each painted on a flat magenta background. `compose_tank.py` keys the
props out and stands them where every surface keeps them. Code owns geometry; the
painter draws the objects.

Everything below is paste-ready. Section 1 is the brief (paste once, at the top of
the chat). Section 2 is one block per tank with its three prompts. Section 3 is what
happens on this side once the images come back — nothing for Grok.

Works two ways:
- **Grok Imagine by hand** (how the first five were made): paste the brief, then a
  tank's three prompts one at a time. Tank: attach the reference plate named in the
  block, aspect **4:3** if offered, else 3:2. Props: no attachment, aspect **1:1**.
- **The Ink bot**: same, but the brief goes in first with the override lines it
  carries. Ink can run the checker itself if its computer has Python with Pillow,
  numpy and scipy (`design/tanks/check_tank.py`).

---

## 0. Where a tank shows, and what each place cuts

Measured off the Swift on 2026-09-11 (`SURFACES` in `check_tank.py`), as the part
of the 4:3 plate that survives.

| surface | box (pt) | what is cut |
| --- | --- | --- |
| Home band, iPhone 15 / 16 / 17 Pro / Max | 402 × 336 | 5% off each side |
| Home band, iPhone SE | 375 × 257 | 9% off the top |
| Shop hero tile | 362 × 196 | **37% off the top**, 6% off each side |
| Shop grid tile | 175 × 142 | 5% off the top, 6% off each side, pans up to 6% more |
| Collection card | 175 × 74 | **22% off the top and 22% off the bottom** |
| Kin header | 402 × 301 | nothing |
| Focus band | 402 × 222 | 13% off the top and bottom, at half strength under paper |
| Friend card | 362 × 212 | 11% off the top and bottom, at half strength under paper |

The window every one of them keeps is **x 12–88%, y 37–78%** of the plate. The
mascot stands in x 30–70%. So a key item lives in x 12–30% or x 70–88%, standing
on the floor with its feet at about 76% down. That is where `compose_tank.py` puts
it. The Chrome extension and the website never draw a tank; the Sprout web
playground draws the uncut painting.

---

## 1. The brief — paste first

```text
Read these rules before you paint anything. They override your profile for this
job: this art is a soft matte CLAY RENDER, not flat shapes, and it may use a full
smooth gradient on the back wall. Everything else in your profile still holds —
you never draw Sprout, you never put text in the art.

## What you are painting
- Six images per tank for the Home tab of an iPhone app: one EMPTY tank, and
  five PIECES each painted alone on a flat magenta background — two STANDS
  (stand on the floor), two CORNERS (hang from the top edge in the top corners)
  and one LIGHT (a lamp on a cord from the top centre). I cut the pieces out and
  place them with code, so any piece fits any tank. You never paint a piece into
  a tank, and the tank's top corners stay empty wall.
- A vector fish (Sprout) is drawn on top of the tank by the app, in the middle.
  Chips of UI sit over the top corners. The bottom of the tank fades into one
  colour that becomes the whole page under it.
- Five tanks already ship. Match them exactly in material, light and layout.
  They are attached (reef.png for light tanks, deep.png for dark ones). Copy the
  style, replace the theme.
- Audience: US college students, 18 to 22, both sexes. Pinterest-aesthetic,
  never toy-like. Props have no faces. Muted pastel, never candy-bright.

## The material — identical for every image
- Soft matte modelling clay, rendered in gentle studio light. Fine matte grain,
  soft rounded forms, soft shadows, a subtle glow inside the lit edges. Zero
  gloss, zero reflections, zero photographic texture.
- One light: a soft shaft from the top centre, unless the block says the light
  comes from a prop (lanterns, lava).

## The EMPTY TANK — rules
- Straight-on, eye level, wide shot, filling the frame edge to edge. No tank
  glass, no rim, no border, no vignette.
- Back wall: ONE smooth vertical gradient, pale glowing top down to the horizon,
  62% to 68% of the way down. Themed relief may sit on the wall in the upper
  corners and down the sides (carved stone, rope, stars, neon tubes) — never
  across the middle third.
- Depth at the horizon: TWO ridges of rounded clay mounds, a far pale one and a
  nearer, deeper-toned one, with the theme's shapes worked into them (coral,
  battlements, ice, rooftops, basalt columns).
- Floor: a bare, flat plane in ONE colour, very slightly deeper in tone toward
  the camera, from the horizon to the bottom edge. NOTHING stands on it. This is
  the rule that makes slots work: the two props I add stand on the floor just
  inside each side, and a chest standing on a coral cluster is what happens when
  the floor is dressed. The horizon sits at two thirds down on EVERY tank, level
  across the frame, so a prop's feet land on the ground in every tank.
- Where the theme goes instead: ON the horizon line (mounds, coral, book stacks,
  bleachers, basalt columns — bases on the line, never in front of it), on the
  upper wall corners (relief, posters, neon, windows), hanging from the top
  corners, and tucked against the far left and right frame edges, half out of
  frame (kelp, a fence, a bamboo screen, a ladder). Small ground things (coins,
  cassettes, leaves) only against those far edges.
- Two or three flat round stepping discs tucked against the far left and right
  frame edges, half out of frame, each under 10% of the frame width. Every tank
  restyles them (dance tiles, craters, stepping stones, ice floes). They are the
  family resemblance, and they never sit where a prop stands.
- Two hanging details, one in each top corner, reaching no lower than a third of
  the way down.
- The middle third of the frame is empty wall and empty floor, top to bottom.
  The bottom fifth is empty floor from edge to edge — it fades into the page.
- Top 18%: pale and quiet in light tanks. A clock and a battery icon in dark
  text sit there.
- Aspect 4:3 if you have it, otherwise 3:2. Largest export. PNG, named <id>.png.

## A CORNER or a LIGHT — rules
- Hangs from the TOP EDGE of the frame: the cord, chain or stem touches the top
  edge, and the whole object is inside the frame on every other side. Corners are
  nets, vines, strings of lights, signs, cobwebs; the light is a lamp, glowing.
- Otherwise exactly like a prop: alone, centred, flat magenta, no floor, no
  shadow, no text. Aspect 3:4 (tall). PNG, named <id>-tl.png / <id>-tr.png /
  <id>-light.png.

## A STAND (prop) — rules
- One object, alone, centred, seen straight on at eye level, lit softly from
  above like the tank. The WHOLE object inside the frame with empty background
  all around it. Nothing cropped.
- The background is one flat, solid, bright magenta, #FF00FF, corner to corner.
  No floor, no ground shadow, no gradient, no second object, no text. When the
  block says GREEN, use #00FF00 instead (the prop itself is pink or purple).
- Same clay, same light, same softness as the tank it goes in. Roughly a
  quarter of the frame is empty margin on every side.
- Aspect 1:1. Largest export. PNG, named <id>-left.png / <id>-right.png.

## Colour
- Each block gives four hexes: wall top, horizon, floor, accent. Use them, not
  something near them. One accent colour per tank, on at most two things.

## Delivery
- Six images per tank, four options for each. Under each: the hexes used.
- If you can run Python: build the tank with
  `python3 compose_tank.py --id <id> --tank <tank> --left <l> --right <r> --tl <tl> --tr <tr> --light <lamp> --light-color '<hex>'`
  then `python3 check_tank.py out/<id>.png --id <id>` and deliver only a set
  that prints PASS.

## CRITICAL INSTRUCTIONS
- NEVER draw a fish, an animal, a person, a face, or a character of any kind.
  A toy figurine named in a block is a prop, not a character.
- NEVER put text, letters, numbers, logos or UI in any image.
- NEVER paint bubbles, sparkles, bokeh dots or floating particles. The app
  animates its own bubbles.
- NEVER paint a piece into a tank. Tanks are empty, corners included; pieces
  are alone on magenta.
- EVERY image is soft matte clay. No gloss, no chrome, no photo texture.
```

---

## 2. The fifteen tanks — paste one block's prompts one at a time

The style sentence is repeated in every prompt on purpose. Grok Imagine forgets
the brief between images; the Ink bot does not, but the repeat costs nothing.

Reference to attach to the TANK prompt: **reef.png** for light tanks, **deep.png**
for dark ones, both in `~/Downloads/Sprout-handoff/public/tanks/`. Props take no
attachment. If Grok only recolours the reference instead of building the theme,
run the tank prompt again with no attachment.

| # | id | name | light/dark | left prop | right prop |
| --- | --- | --- | --- | --- | --- |
| 1 | `treasure` | Treasure | light | open treasure chest | toy diver |
| 2 | `castle` | Castle | light | castle tower | broken column with ivy |
| 3 | `zen` | Zen | light | stone lantern | stacked stones + tiny pine |
| 4 | `frost` | Frost | light | ice cave with igloo | frosted pine + ice crystals |
| 5 | `vapor` | Vapor | light | marble bust on a pedestal | palm fronds + pink pyramid (GREEN) |
| 6 | `disco` | Disco | DARK | speaker stack | mirror ball on a stand |
| 7 | `orbit` | Orbit | DARK | ringed planet on a mound | toy rocket |
| 8 | `arcade` | Arcade | DARK | arcade cabinet | pinball ornament + tokens |
| 9 | `lantern` | Lantern | DARK | lantern post | bench with two lanterns |
| 10 | `magma` | Magma | DARK | volcano cone | basalt boulders with glowing cracks |
| 11 | `library` | Library | DARK | book stack with a green banker's lamp | globe on a stand + brass telescope |
| 12 | `cottage` | Cottage | light | thatched stone cottage | wheelbarrow of wildflowers + watering can |
| 13 | `lofi` | Lofi | DARK | desk lamp with headphones | potted monstera + cassettes |
| 14 | `court` | Court | light | basketball hoop on a stand | basketball on a stand + bottle |
| 15 | `haunt` | Haunt | DARK · October | carved pumpkin, lit | cauldron with a green glow |

Eleven to fifteen were added the same day for the gaps in the first ten, read against
what 18–24s actually pick: the top BetterCampus community theme is Ghibli (40k
likes), the Canvas skin list students asked for is Dark Academia / Lo-fi / Cottage /
Midnight / Matcha, the top Stylus Canvas theme is Tokyo Night, and the mascot
research says soft pastel companions skew ~75% women while competition and loot keep
men. So: a study-app study scene in two moods (Library, Lofi), the pastoral hit
(Cottage), one sport (Court), and one seasonal drop for the October launch cohort
(Haunt). Bench, if a sixth is wanted: Cafe (matcha counter), Alley (rainy neon
street, the Tokyo Night look), Terrarium (moss + monstera under glass).

Shared sentences, so the blocks below stay short:

- **STYLE** = `Miniature aquarium diorama sculpted from soft matte modelling clay, straight-on eye-level wide shot in gentle pastel studio light, filling the frame edge to edge with no tank glass, rim or border. Smooth back wall running edge to edge, with no side walls and no room corners, in one vertical gradient from a pale glowing top down to a low ridge of rounded clay mounds at the horizon, exactly two thirds of the way down. Plain matte floor in one colour, slightly deeper toward the camera. Fine matte grain, soft shadows, no gloss.`
- **EMPTY** = `The floor is a bare, flat plane from the horizon to the bottom edge, and NOTHING stands on it anywhere: no props, no objects, no plants, no discs, no scattered things. Everything in the painting either stands on the horizon line as part of the ridge, hangs from the top, or is tucked against the far left or right frame edge, half out of frame. The middle of the frame is empty wall and empty floor. No text, no bubbles, no fish, no creatures.`
- **CORNER** = `A single small clay object hanging from the TOP EDGE of the frame, sculpted from soft matte modelling clay in a gentle pastel style, seen straight on, lit softly from above, on a completely flat, solid, bright magenta background (#FF00FF). It touches the top edge where it hangs and is fully inside the frame on every other side, with empty magenta around it. No floor, no shadow, no other objects, no text. The object:`
- **LIGHT** = `A single small lamp hanging on a cord from the TOP EDGE of the frame, sculpted from soft matte modelling clay in a gentle pastel style, seen straight on, glowing softly, on a completely flat, solid, bright magenta background (#FF00FF). The cord touches the top edge, the lamp hangs in the lower half of the frame, everything fully inside the frame with empty magenta around it. No floor, no shadow, no other objects, no text. The lamp:`
- **PROP** = `A single small figurine sculpted from soft matte modelling clay in a gentle pastel style, seen straight on at eye level, lit softly from above, centred on a completely flat, solid, bright magenta background (#FF00FF). The whole object is fully inside the frame with empty magenta all around it. No ground shadow, no floor, no other objects, no text. The object:`

Paste the full sentence in place of the word each time.

### 1. Treasure — `treasure` — light — tank attaches reef.png

```text
TANK: STYLE The top corners are empty wall (they are slots). Theme: the classic
fish tank, rich but calm. Far ridge of pale sand mounds, nearer ridge of cream
and coral-pink clay coral clusters with a wooden plank half sunk in the right-
hand mound. Bare sand floor; a few gold coins and pearls half buried against the
far left and right frame edges only. A tall kelp frond hugs the far right edge.
Two flat pale sand-dollar discs tucked against each far edge. Warm gold light
shafts from the top centre. Colours: wall top #E3F4F1, horizon #9FD3CF, floor
#EBD6AF, accent coin gold #FFC24B. EMPTY

LEFT: PROP an old wooden treasure chest with its lid half open, spilling smooth
clay gold coins and three pearls.

RIGHT: PROP a toy deep-sea diver ornament with a round brass helmet with three
porthole windows and a boxy grey suit, standing still, arms at its sides.

CORNER L: CORNER a drape of knotted rope fishing net with three cream glass floats.

CORNER R: CORNER a sprig of pale seaweed with a small pearl caught in it.

LIGHT (--light-color '#FFD98A'): LIGHT a brass diving lantern with a warm amber glass.
```

### 2. Castle — `castle` — light — tank attaches reef.png

```text
TANK: STYLE The top corners are empty wall (they are slots). Theme: a sunken
kingdom, calm and quiet. Far ridge of pale stone walls with soft rounded
battlements low on the horizon, nearer ridge of mossy mounds with a broken
column stump at each far edge and a short flight of stone steps at the far
right. Bare pale stone floor; a few tumbled stone blocks and moss patches
against the far left and right frame edges only. Two flat flagstone discs tucked
against each far edge. Cool white light shafts. Colours: wall top #E9EFF9,
horizon #AFC3E6, floor #E2DAC8, accent moss #A5CE6B. EMPTY

LEFT: PROP a rounded clay castle tower in soft grey-cream stone, one small arched
doorway, a cone roof, a little moss at its base, no flag, no windows with faces.

RIGHT: PROP a broken stone column, snapped off at the top, with a strand of ivy
climbing it and a small fallen stone block beside it.

CORNER L: CORNER a strand of ivy with rounded leaves.

CORNER R: CORNER a small weathered stone corbel with moss, hanging from a chain.

LIGHT (--light-color '#FFE6B0'): LIGHT a wrought-iron chandelier with three pale candle flames.
```

### 3. Zen — `zen` — light — tank attaches reef.png

```text
TANK: STYLE The top corners are empty wall (they are slots). Theme: a quiet
stone garden. Far ridge of pale mounds, nearer ridge of moss mounds with round
river stones set into them, a small arched wooden footbridge silhouette at the
far left edge and three bamboo stalks at the far right edge. The floor is pale
raked sand; the fine rake lines curve around the edges and fade out well before
the bottom. A few pink petals rest on the sand against the far edges only. Two
flat dark grey stepping stones tucked against each far edge. Warm pink-white
light shafts. Colours: wall top #FBF1F2, horizon #E5C4CE, floor #ECDFCB, accent
blossom #F4B8C8. EMPTY

LEFT: PROP a pale grey stone garden lantern with a small pagoda roof, standing on
a rounded moss mound, no lettering.

RIGHT: PROP three smooth stacked balance stones in soft grey clay with a small
rounded clay pine growing beside them.

CORNER L: CORNER a cherry blossom branch with a few pink blossoms.

CORNER R: CORNER a small wind chime of pale bamboo tubes.

LIGHT (--light-color '#FFE3E8'): LIGHT a round paper lantern glowing soft pink-white.
```

### 4. Frost — `frost` — light — tank attaches reef.png

```text
TANK: STYLE The top corners are empty wall (they are slots). Theme: an ice cave
under a faint aurora. Two soft ribbons of aurora, mint and pale pink, drift
across the upper wall in the corners only. Far ridge of pale ice ridges, nearer
ridge of rounded matte ice blocks with a frosted pine at each far edge. Bare
snow floor; a few small pale blue ice crystals against the far left and right
frame edges only. Two flat pale ice-floe discs tucked against each far edge.
Cool white light shafts. Colours: wall top #ECF5FB, horizon #B9D6EA, floor
#E3EDF3, accent glacier #8FBFE0. EMPTY

LEFT: PROP rounded blocks of matte blue-white ice clay stacked into a small cave
mouth with a little clay igloo in front of it.

RIGHT: PROP a frosted rounded clay pine tree with a cluster of pale blue ice
crystals at its foot.

CORNER L: CORNER a row of short icicles.

CORNER R: CORNER a cluster of pale blue ice crystals on a thread.

LIGHT (--light-color '#E8F6FF'): LIGHT a frosted glass lantern glowing cool white.
```

### 5. Vapor — `vapor` — light — tank attaches reef.png

```text
TANK: STYLE The top corners are empty wall (they are slots). Theme: a soft
vaporwave sunset. The back wall runs pale pink at the top through peach to lilac
at the horizon, with one large flat pale-peach sun disc behind the mounds,
crossed by three thin horizontal bands of the wall colour. Far ridge of lilac
mounds, nearer ridge of deeper lilac mounds with a clay palm silhouette at each
far edge. Pale lilac floor with a faint perspective grid that fades out well
before the bottom, and a few small pastel clay spheres resting against the far
left and right frame edges only. Two flat discs, pastel pink and cyan, tucked
against each far edge. Soft peach glow from the horizon. Colours: wall top
#FFDCEB, horizon #C9A9F0, floor #D8C6EE, accent cyan #7FE3F0. EMPTY

LEFT: PROP a classical marble bust ornament in pastel white clay on a short
pedestal, a generic sculpted head with no real likeness, turned slightly away.

RIGHT (GREEN background, #00FF00, because the prop is pink): PROP two clay palm
fronds rising from a rounded lilac mound with a small pastel pink pyramid beside
it.

CORNER L: CORNER a string of pastel clay beads.

CORNER R: CORNER a small pastel pink Greek column capital on a chain.

LIGHT (--light-color '#9FF0FA'): LIGHT a neon ring lamp glowing cyan.
```

### 6. Disco — `disco` — DARK — tank attaches deep.png

```text
TANK: STYLE with a softly glowing violet top instead of a pale one. The top
corners are empty wall (they are slots). Theme: a quiet disco after the crowd
left. Soft pastel light spots in pink, cyan and mint scattered over the upper
wall corners only, none in the middle. Far ridge of plum mounds, nearer ridge of
deeper plum mounds with a low stage step at each far edge. Bare plum floor; a
few flat pastel clay confetti pieces against the far left and right frame edges
only. Two or three flat dance-floor tiles glowing softly pink, cyan and butter
yellow tucked against each far edge. Pink-violet light shaft. Colours: wall top
#4A3676, horizon #7A57A8, floor #4B3A70, accent hot pink #FF7AB6. EMPTY

LEFT: PROP a stack of two rounded clay speaker boxes, dark grey with cream cones,
the top one slightly smaller.

RIGHT: PROP a faceted mirror ball in matte silver clay, each facet a soft pastel
tint, mounted on a short black stand.

CORNER L: CORNER a string of small pastel bulbs on a black cord.

CORNER R: CORNER a folded silver party streamer.

LIGHT (--light-color '#FFC6E6'): LIGHT a faceted mirror ball on a short cord, glinting pastel pink.
```

### 7. Orbit — `orbit` — DARK — tank attaches deep.png

```text
TANK: STYLE with a softly glowing navy top instead of a pale one. The top
corners are empty wall (they are slots). Theme: a toy solar system. Tiny pale
four-point stars and two faint wisps of pastel nebula on the upper wall corners
only. A small pale distant planet low on the wall at the far left. Far ridge of
grey moon hills, nearer ridge of rounded grey mounds. Bare grey-indigo floor;
two or three shallow round craters against each far edge instead of discs. Cool
cyan-white light shaft. Colours: wall top #202A55, horizon #4A5A94, floor
#6E6C95, accent peach #F2B48C. EMPTY

LEFT: PROP a ringed planet, peach clay with a cream clay ring, resting on a small
rounded grey clay mound, with a small crescent moon leaning against the mound.

RIGHT: PROP a rounded toy rocket standing upright on three fins, cream clay body,
coral nose cone, one round porthole.

CORNER L: CORNER a small pale crescent moon on a thread.

CORNER R: CORNER a small clay satellite on a thread.

LIGHT (--light-color '#FFD2B0'): LIGHT a ringed-planet lamp glowing peach.
```

### 8. Arcade — `arcade` — DARK — tank attaches deep.png

```text
TANK: STYLE with a softly glowing indigo top instead of a pale one. The top
corners are empty wall (they are slots). Theme: a retro arcade at closing time.
Soft neon tubes on the upper wall corners: a pink zigzag and a small cyan star
on the left, a cyan ring and a pink arrow on the right, glowing gently. Far
ridge of indigo mounds, nearer ridge of deeper mounds with a stack of blank clay
game cartridges at each far edge. Bare slate floor with a faint glowing cyan
grid that fades out well before the bottom; a few pastel clay tokens against the
far left and right frame edges only. Two or three flat pads glowing cyan and
pink tucked against each far edge. Cyan light shaft. Colours: wall top #2B2556,
horizon #4E4390, floor #3A3466, accent pink #FF6FB5. EMPTY

LEFT: PROP a rounded clay arcade cabinet, its screen a plain soft cyan glow with
no picture and no letters, a coral joystick and two round buttons on the deck.

RIGHT: PROP a rounded clay pinball-machine ornament with a blank glowing top and
a small stack of pastel clay tokens leaning against it.

CORNER L: CORNER a small neon tube in a zigzag, glowing pink.

CORNER R: CORNER a coiled cable with a plug, glowing soft cyan.

LIGHT (--light-color '#C8E8FF'): LIGHT a neon ring lamp glowing cyan-pink.
```

### 9. Lantern — `lantern` — DARK — tank attaches deep.png

```text
TANK: STYLE with a softly glowing teal top instead of a pale one. The top
corners are empty wall (they are slots). Theme: a night market after hours. Far
ridge of low dark-teal rooftop silhouettes at the horizon, nearer ridge of teal
mounds with a bamboo screen at the far left edge and a leaning paper umbrella at
the far right. Bare warm umber floor; a few small round paper lanterns resting
against the far left and right frame edges only. Two flat stone discs warmed by
lantern light tucked against each far edge. Light: warm amber from the lanterns;
the top of the wall keeps a soft teal glow. Colours: wall top #24404F, horizon
#47707E, floor #6F5148, accent amber #FFB25C. EMPTY

LEFT: PROP a wooden lantern post with three round paper lanterns hanging from its
short crossbar, amber, cream and coral, softly glowing, no writing on them.

RIGHT: PROP a low wooden clay bench with two round paper lanterns resting on it,
softly glowing.

CORNER L: CORNER a string of three round paper lanterns, amber, cream and coral.

CORNER R: CORNER a string of two round paper lanterns, cream and coral.

LIGHT (--light-color '#FFC98A'): LIGHT a large round amber paper lantern glowing warm.
```

### 10. Magma — `magma` — DARK — tank attaches deep.png

```text
TANK: STYLE with a softly glowing charcoal top instead of a pale one, and a warm
orange glow low on the wall. The top corners are empty wall (they are slots).
Theme: a sleeping volcano. Far ridge of dark hexagonal basalt columns at the
horizon, nearer ridge of rounded black boulders. Bare dark basalt floor; thin
glowing orange lava veins against the far left and right frame edges only, gone
by the bottom fifth. Two flat cooled-lava discs, dark with warm edges, tucked
against each far edge. Light: an ember glow rising from the horizon and a faint
pale glow at the very top. Colours: wall top #2E2828, horizon #4E3C3A, floor
#3B3234, accent ember #FF7A45. EMPTY

LEFT: PROP a rounded clay volcano cone in dark grey with a softly glowing orange
rim and two slow lava trickles down one side, no smoke, no eruption.

RIGHT: PROP a cluster of three rounded black basalt boulders with faint glowing
orange cracks.

CORNER L: CORNER a dark hanging root with a faint orange glow at its tip.

CORNER R: CORNER two dark hanging roots.

LIGHT (--light-color '#FF9A5C'): LIGHT a lamp of glowing orange lava in a dark iron cage.
```

### 11. Library — `library` — DARK — tank attaches deep.png

```text
TANK: STYLE with a softly glowing deep-oak top instead of a pale one. The top
corners are empty wall (they are slots). Theme: dark academia, a sunken reading
room. Rows of blank clay book spines in muted greens, oxblood and cream sit as
relief on the upper wall corners only. Far ridge of low stacked-book shapes at
the horizon, nearer ridge of rounded moss mounds with a ladder leaning at the
far left edge and a tall stack of books at the far right. Bare warm worn-rug
floor; a few small clay ink bottles and a quill resting against the far left and
right frame edges only. Two flat round brass medallion discs tucked against each
far edge. Light: a warm amber shaft, soft. Colours: wall top #3A2A22, horizon
#5C4534, floor #5A3F35, accent banker's green #7FB69A. EMPTY

LEFT: PROP a stack of five clay books in muted green, oxblood and cream with a
brass banker's lamp standing on top, its green glass shade glowing softly, no
lettering on the spines.

RIGHT: PROP a clay globe on a short wooden stand with a small brass telescope
leaning against it, no map lettering.

CORNER L: CORNER a strand of ivy with rounded leaves.

CORNER R: CORNER a brass reading lamp on a chain, unlit.

LIGHT (--light-color '#CFEFD8'): LIGHT a green glass banker's pendant lamp glowing soft green.
```

### 12. Cottage — `cottage` — light — tank attaches reef.png

```text
TANK: STYLE The top corners are empty wall (they are slots). Theme: a summer
meadow, soft and pastoral. Far ridge of rolling pale green hills, nearer ridge
of grass mounds dotted with tiny wildflowers in white, lavender and poppy red, a
short wooden fence at the far left edge and a round stone well at the far right.
Bare meadow floor, green-gold; a few fallen petals and clover against the far
left and right frame edges only. Two flat round mossy stepping stones tucked
against each far edge. Warm golden light shafts. Colours: wall top #EAF3F8,
horizon #BFD9A6, floor #CFD9A0, accent poppy #E8735A. EMPTY

LEFT: PROP a small stone cottage with a thatched clay roof, a round wooden door,
one round window with no one in it, and a short chimney.

RIGHT: PROP a wooden wheelbarrow heaped with clay wildflowers, a small watering
can leaning against its wheel.

CORNER L: CORNER a wisteria strand in lavender.

CORNER R: CORNER a hanging flower basket with wildflowers.

LIGHT (--light-color '#FFE4A8'): LIGHT a small wooden lantern glowing warm gold.
```

### 13. Lofi — `lofi` — DARK — tank attaches deep.png

```text
TANK: STYLE with a softly glowing muted-violet top instead of a pale one. The
top corners are empty wall (they are slots). Theme: a late-night study room. A
rounded window frame sits on the upper wall at the far left, showing a navy
night with a small crescent moon; blank posters as soft rounded rectangles on
the upper wall at the far right. Far ridge of rounded cushions at the horizon,
nearer ridge of book stacks and a folded blanket mound. Bare muted violet-grey
floor; a mug, two cassette tapes and a closed notebook resting against the far
left and right frame edges only. Two flat round vinyl-record discs tucked
against each far edge. Light: soft amber from the left, a faint cool glow at the
top. Colours: wall top #2B2836, horizon #4A4358, floor #3E3849, accent amber
#FFB870. EMPTY

LEFT: PROP a small desk lamp with a warm amber shade, glowing softly, with a pair
of headphones hung over its neck.

RIGHT: PROP a potted monstera in a terracotta pot with a stack of two cassette
tapes at its foot, no lettering on the tapes.

CORNER L: CORNER a string of small warm lights on a cord.

CORNER R: CORNER a pair of headphones on a hook.

LIGHT (--light-color '#FFC98A'): LIGHT a small desk lamp on a cord glowing warm amber.
```

### 14. Court — `court` — light — tank attaches reef.png

```text
TANK: STYLE The top corners are empty wall (they are slots). Theme: an outdoor
basketball court on a bright day. Far ridge of pale bleacher steps low on the
horizon, nearer ridge of rounded mounds in court orange with a chain-link fence
panel at the far left edge and a tall floodlight pole at the far right. Bare
court-tan floor with faint white court lines against the far left and right
frame edges only; a whistle, a sports bottle and two small orange cones resting
against those far edges. Two flat round rubber floor pads tucked against each
far edge. Cool white light shafts. Colours: wall top #E3EEF8, horizon #A9C4DC,
floor #D9A876, accent ball orange #F08A3C. EMPTY

LEFT: PROP a basketball hoop on a short stand: a rounded backboard, an orange
rim, a cream net, no lettering.

RIGHT: PROP a clay basketball resting on a small ring stand with a sports bottle
beside it.

CORNER L: CORNER a string of blank pennants in orange and cream.

CORNER R: CORNER a whistle on a lanyard.

LIGHT (--light-color '#EEF6FF'): LIGHT a stadium floodlight on a short pole, glowing cool white.
```

### 15. Haunt — `haunt` — DARK, seasonal for October — tank attaches deep.png

```text
TANK: STYLE with a softly glowing plum top instead of a pale one. The top
corners are empty wall (they are slots). Theme: a soft Halloween night, playful
not scary. One large flat pale moon disc sits behind the mounds. Far ridge of
dark rounded hills with a bare clay tree at each far edge, nearer ridge of plum
mounds with tiny clay mushrooms. Bare dark plum-grey floor; fallen leaves in
orange and brown and two small candles resting against the far left and right
frame edges only. A cobweb in the top-left corner, a small iron lantern on a
chain in the top-right. Two flat round stone slabs tucked against each far edge.
Light: cool moonlight from the top, a warm glow low on the wall. Colours: wall
top #2A2438, horizon #4B3F5E, floor #3C3346, accent pumpkin #F09A3C. EMPTY

LEFT: PROP a classic carved pumpkin, lit from inside with a soft amber glow — the
one prop that is allowed a face, a simple friendly one.

RIGHT: PROP a round iron cauldron on three short legs with a soft green glow
rising from inside it, no smoke.

CORNER L: CORNER a cobweb with a single dew drop.

CORNER R: CORNER a small iron lantern on a chain, glowing faint amber.

LIGHT (--light-color '#E9E4FF'): LIGHT a paper moon lamp glowing pale.
```

---

## 3. When the images come back — this side, not Grok

Tested 2026-09-11 with Gemini standing in for Grok: Treasure (light) and Orbit
(dark) built this way pass every check, and `design/tanks/trial/` holds the
pieces, the composites and the surface sheets.

1. Save the three winners, e.g. `~/Downloads/<id>-tank.png`, `<id>-left.png`,
   `<id>-right.png`.
2. Check the empty tank's stages first: `python3 design/tanks/check_tank.py <tank> --empty`.
   The two stages (the floor just inside each side, from the horizon down) must be as
   bare as the centre floor, or the prop stands on whatever was painted there — the
   first intricate Treasure put a coral cluster under the chest. `compose_tank.py`
   refuses a tank that fails this unless you pass `--force`. The five shipping tanks
   FAIL it (discs and plants on the stages); they need a repaint under the rule
   before they can take slots.
3. Compose:
   ```bash
   python3 design/tanks/compose_tank.py --id <id> --tank ~/Downloads/<id>-tank.png --left ~/Downloads/<id>-left.png --right ~/Downloads/<id>-right.png --out ~/Downloads/Sprout-handoff/public/tanks/<id>.png
   ```
   It keys the props, stands them in the slots, tints them toward the tank's light,
   shadows them, and prints where each landed. `--left-size 0.8` shrinks one,
   `--right-nudge 0.02 0` moves one, `--key green` for a green-screen prop.
4. Check:
   ```bash
   python3 design/tanks/check_tank.py ~/Downloads/Sprout-handoff/public/tanks/<id>.png --id <id>
   ```
   Must print PASS. Look at `design/tanks/out/<id>-surfaces.png`: both props whole
   on all eleven crops, seam-free under the band. It also prints the `FLOOR_LINE`
   row and the `Scene0` line.
5. Add `"<id>": <row>` to `FLOOR_LINE` in
   `~/Downloads/Sprout-handoff/scripts/cut_ios_tanks.py` and run it. It writes the
   plate to `public/tanks/ios`, `dist/tanks/ios`, `ios/SproutWeb/tanks/ios` and
   `ios/Resources/Assets.xcassets/scene-<id>.imageset`, and prints floor / floorDeep.
6. Web build: add the id to `TankId` and a `TANKS` entry in `src/tanks.ts`
   (`iosSrc: '/tanks/ios/<id>.png?v=1'`, `floor` from step 4), a swatch button in
   `index.html`, then `npm run build` and copy `dist/assets/*.js` and `*.css` over
   `ios/SproutWeb/assets/`. An unknown `?tank=` id silently falls back to Lagoon.
7. Swift: add the `Scene0` line to `Scene0.all` in `ios/Sources/Theme.swift` with a
   price. `isDark: true` flips the chips to the light-on-dark glass.
8. Build on a sim (a worktree — see the sim-unlock-all memory), screenshot Home,
   Kin, Shop and Collection, and check by eye.

### Animation — the live Home tank moves

Built 2026-09-11 in the Sprout build (`~/Downloads/Sprout-handoff/src/tankfx.ts`,
wired through `tanks.ts` → `renderer.ts` → `main.ts`; uncommitted, George commits).
Every effect is a few canvas gradients a frame and sits BEHIND Sprout, so nothing
ever crosses his face; only the drifting particles go in front. Reduce Motion draws
the resting frame of everything — nothing vanishes, it just stops.

| effect | what it does | who gets it |
| --- | --- | --- |
| `rays` | three soft light shafts from the top centre, breathing and leaning | every tank |
| `caustics` | two big soft light patches wandering the upper wall, like light through water | every tank |
| `glow` | fixed points that pulse | Disco tiles, Arcade pads + screen, Lantern lanterns, Magma cracks + rim |
| `twinkle` | stars that flare on their own clocks | Orbit |
| `aurora` | two ribbons drifting across the upper wall | Frost |
| `drift` | petals falling (Zen), snow (Frost), embers rising (Magma), coin glints (Treasure) | those four |
| prop `bob` / `sway` | the cut-out prop floats or leans, pivot at its feet | rocket bobs, diver sways, mirror ball sways, lantern post sways |

Eleven to fifteen: Library — lamp `glow` (green) + cream dust `drift` (the snow
particle, slower, warm); Cottage — warm `rays` + white petal `drift`; Lofi — lamp
and string-light `glow`, `twinkle` on the lights; Court — floodlight `glow`;
Haunt — pumpkin `glow` (amber) and cauldron `glow` (green) + pale-green wisp
`drift` (the ember particle recoloured).

Positions for `glow` and `twinkle` are fractions of the plate and are typed into
`tanks.ts` by hand once the real art lands (where Grok actually put the tiles).
`compose_tank.py --layers` writes the empty plate and the prop cut-outs the live
tank draws, and prints the `props:` entry; the flat plate is still what the stills
use, so the shop and the collection never change.

Sign-off: `design/tanks/capture_fx.py treasure orbit` records the Home band as a
GIF (`design/tanks/trial/<id>-fx.gif`), `--still` records it with Reduce Motion on.
Animations ship only after George has seen the GIF.

Shipping it to the phone: `npm run build` in the Sprout build, copy
`dist/assets/*.js` and `*.css` over `ios/SproutWeb/assets/`, plus the new files
under `dist/tanks/ios/`. The WKWebView no longer caches the bundle (no-store), so
the change shows on the next launch.

### The five that already ship — council verdict, 2026-09-11

They fail the stage check, and `clear_stages.py` (a Gemini edit that erases the
floor) made them pass — but a three-model council found the edit unfit to ship: the
first run asked for 4:3 from 3:2 sources and the model SQUASHED the scene 11% narrower
(fixed in the script since: it now matches the source aspect), the files came back
about half as sharp (Lagoon a 1.6× upscale), four of five lost mounds or plants, Deep
gained a branch, and all five lost the discs. The stage check cannot see content loss.

Decision: **ship the five untouched; no slots on them at launch; the floor rule is
mandatory for every NEW tank.** When slots are built, give the old five their own
slot boxes instead of new art: every shipping plate has a bare strip wide enough for
a prop inside the always-visible window — nudge the left stand right by 0.10 (Lagoon,
Reef), 0.06 (Kelp), 0.03 (Dusk), the right stand left by 0.07 (Reef, Dusk); where a
disc sits under the feet the prop stands on it like a stepping stone
(`compose_tank.py --force --left-nudge …`, and `TankProp.box` in `tanks.ts` is already
per tank). Caveat: on Lagoon and Reef the left prop then centres at x≈0.31, touching
the mascot's lane — check on a phone. `clear_stages.py` stays as the last resort for a
tank with no bare strip at all, run with `--hires` and an eye diff, never on Lagoon.

### The shop — six pieces per theme (2026-09-11 evening)

Fifteen themes × (tank + stand L + stand R + corner L + corner R + light) = 90
images, all prompted above. Proven with Gemini stand-ins for Treasure and Orbit
(`trial/set/`): the sets compose, the corners swing, the lamp recolours the rays,
and pieces cross themes (`mix-treasure-orbit-zenlight.png`,
`mix-orbit-treasure-vaporlight.png`). Light: the sixth piece, top centre, a lamp on a
cord; on the phone the Dynamic Island hides the top of the cord and the fixture hangs
out from under it. `compose_tank.py` takes all five (`--tl --tr --light`), and
`tankfx.ts` swings hanging pieces and takes the lamp's colour for the rays.

| piece | coins | visible |
| --- | --- | --- |
| tank | 200–400, as today | everywhere |
| stand | 120–180 | everywhere |
| corner | 80–120 | Home + Kin (shop hero crops them, chips overlap) |
| light | 100–160 | Home + Kin; recolours every tank you own |
| weather | 60 | code only, no art |
| whole set | −20%, the shop's usual discount | |

Drops: a theme set a week after launch; Haunt only in October, Frost in December.
Lagoon ships with its two stands and lamp owned, so the first shop tap is a swap.
Plus never sells pieces (PLUS-SPEC.md). Two things learned painting the demo set:
say "no side walls, no room corners" (Orbit came back as a boxed room twice), and
"exactly two thirds down" for the horizon (Treasure drifted to 0.75 once). Both are
in the STYLE sentence now.

### Loose pieces — theme-free, for any tank

Twelve pieces no theme owns, the ones a student actually has on a desk. Same PROP /
CORNER / LIGHT sentences, no tank. These are the shop's filler between theme drops
and the first things a new student can afford.

```text
STAND  coffee  : PROP a stack of two takeaway coffee cups with cardboard sleeves, no lettering.
STAND  books   : PROP a stack of three clay textbooks in muted blue, cream and rust with a pencil cup on top, no lettering.
STAND  laptop  : PROP a small open laptop, pastel lid, blank pale screen, no logo.
STAND  plant   : PROP a potted monstera in a terracotta pot.
STAND  trophy  : PROP a small gold trophy cup on a wooden base, no plaque text.
STAND  radio   : PROP a small retro radio in cream and mint with a round dial.
CORNER pennants: CORNER a string of blank triangular pennants in cream, mint and coral.
CORNER planes  : CORNER three paper planes on threads, cream, one coral.
CORNER lights  : CORNER a string of small warm bulbs on a black cord.
CORNER calendar: CORNER a small blank wall calendar on a string, cream pages, one coral square.
LIGHT  desk    : LIGHT a small desk lamp on a cord, cream shade, glowing warm amber.   --light-color '#FFC98A'
LIGHT  moon    : LIGHT a round pale moon lamp on a cord, glowing soft white.            --light-color '#EEF2FF'
```

### Earned pieces — not for sale

The mascot research says a collecting economy is the adult counterweight to cute,
and Reddit says students hate paywalls. So some pieces are earned, shown greyed in
the collection with the rule under them, and never sold. Each is one PROP/CORNER/
LIGHT image like the rest.

| piece | rule | slot |
| --- | --- | --- |
| First Assignment (a tiny gold star on a stand) | first Canvas task done | stand |
| Clean Week (a small calendar page, all ticked) | a week with nothing overdue | corner |
| Deep Work (an hourglass, sand run through) | one Focus shift of 45 minutes | stand |
| Reader (a stack of five books, one open) | a Learn unit finished | stand |
| Semester (a diploma tube with a coral ribbon) | 100 assignments | stand |
| League (a small brass bell) | first week at the top of a pod | corner |
| Night Owl (a moon lamp) | a Focus shift after midnight | light |

### Prices (a suggestion; PLUS-SPEC.md stays the only price table once decided)

Shipped: Lagoon 0, Reef 200, Kelp 220, Dusk 250, Deep 280.

| set | tanks | price |
| --- | --- | --- |
| classic | Treasure, Castle | 300 |
| mood | Zen, Frost, Vapor | 320 / 320 / 340 |
| night | Lantern, Disco, Orbit, Arcade, Magma | 360 / 380 / 380 / 400 / 400 |
| study + more | Library, Cottage, Lofi, Court | 340 / 320 / 360 / 340 |
| seasonal | Haunt | 300, sold only in October, then it stays if you own it |

### Two things to know before the dark five are wired in

- The app never flips the status bar. Deep already ships with the clock in dark
  text on navy (`check_tank.py` fails it on the "pale top" rule: clock corner
  luma 93). Five more dark tanks make that a real bug. A small Swift change —
  the status bar style following `Scene0.isDark` — should land with them.
- A dark floor becomes the colour of the whole Home page under the tank, with
  white cards on it. Deep shows what that looks like. It reads as a dark mode,
  which the BetterCampus research says this audience wants.
