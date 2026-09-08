# Style-locked variation: different pictures, one look

The other mode. `.claude/skills/figure-art/SKILL.md` describes a **chain** — one picture
that grows by one small edit per card, so the drawing builds as the student reads. Use a
chain when the cards are steps in one drawing.

This file is for the opposite job: **each card gets a completely different picture, and
only the style is shared.** Different subject, different camera, different composition.
Use it when the cards are different moments rather than steps.

## The two levers, and one you must not touch

1. **A style block that never changes.** The same paragraph, word for word, on every
   generation. It describes only look — never content.
2. **The same style reference images, every time.** Gemini 3.1 Flash takes three.
3. **Never `previous_interaction_id`.** That is the chain lever. It drags the last
   composition along, which is exactly what you are trying to escape here.

### Pick style refs whose subjects differ

Attach three pictures that look alike and depict nothing alike. A reference carries more
than style: generating a tram with `trolley.png` attached transferred its pantograph
without being asked. If all three refs share a subject, that subject leaks into
everything.

The working set: `preview/scene-cave.png`, `preview/jar.png`, `preview/ticket.png` — a
cave, a jar and a ticket. Nothing in common but the drawing.

## The style block

Paste this unchanged above every scene. Swap only the background hex to the lesson's
field colour (`Fig` fields: coin `#FFF4DC`, leaf `#EAF4E0`, sky `#E6F0FB`, lav
`#EDE7FB`, rose `#FFEDE7`).

```
The attached pictures are the house style. Match them exactly and ignore their subjects.

STYLE. A flat vector illustration for a learning app. Every shape is filled with one
single flat colour, uniform edge to edge, with a hard clean boundary. Every shape is
traced with the same thick even dark brown #2E2622 outline, the same weight all the way
round every object. Colours are drawn only from coral red #FF6F61, warm yellow #FFC24B,
sky blue #9BC8F2, leaf green #A5CE6B, lavender #C3B2F0, white and warm grey #D9CFC0. The
background is one plain solid pale sky blue #E6F0FB filling the whole frame. Every
surface is blank and unlettered: signs are plain painted boards, screens show only shape
and colour, paper is ruled but unwritten. Camera at eye level, straight on, a flat side
view with everything at true size and no perspective. Shapes are large and simple and
fill the frame. The top third of the frame is open and empty.
```

Drop the camera sentence when the scene names its own camera — an overhead view has to
overrule it, and leaving both in makes the model split the difference.

## Writing a scene block

One paragraph, content only. Four rules, all earned the hard way:

- **Name the camera first** if it differs from the style block. "A bird's-eye view
  looking straight down, like a map." Camera is the single biggest lever on how
  different two pictures feel.
- **Name objects by their marks, not their names.** "A railway track" gets a coloured
  ribbon. "Two parallel rails with short wooden sleepers laid across them" gets a
  railway.
- **Enumerate any count.** "Five people" returns four. "The first, then a second, then a
  third, then a fourth, then a fifth. Five in total and no more" returns five.
- **Ruled lines all the same length are notebook paper.** The first offer letter drew
  every rule full width, edge to edge, and read as a legal pad. Say the lines are "of
  different lengths, each ending at a different point well short of the right edge, the
  way paragraphs of text do", and add the marks that name the document — a logo block, a
  signature squiggle. Same wordless test as any other object.
- **Describe the wanted state, never the unwanted one.** Not "no text" but "every
  surface is blank and unlettered". There is no negative prompt on any Gemini image
  model, so naming a thing to exclude only summons it.

## Settings

`gemini-3.1-flash-image` · `aspect_ratio` `4:3` · `image_size` `2K` · `thinking_level`
`high` · grounding **off** · `negative_prompt` and `system_instruction` **empty**
(Gemini has neither; a wrapper offering them is pasting them into your prompt).

`candidateCount` above 1 is a bare **400** on the image models. To get variants, send
the request more than once — which is what `gemini.py -n` does.

## Four tested scene blocks

All four ran with the block above and the same three refs. Nothing is shared between
them but the look.

**A · wide side view — the runaway**

```
SCENE. A red tram runs alone down a straight railway track, moving fast to the right.
The track is two long parallel rails with short wooden sleepers laid across them in an
even row, running from the left edge to the right edge across the lower third. The tram
sits on the track with its two round black wheels resting on the rails. Three short
straight speed lines trail behind it in the open air. The track ahead of the tram is
empty and clear all the way to the right edge.
```

**B · extreme close-up — the choice**

```
SCENE. A close view of one hand gripping a tall upright switch lever beside a railway
track, seen from the side. The lever is a straight post rising from a heavy base plate,
with a long straight handle angled out from its top and a round knob at the handle's
end. The hand and forearm come in from the left edge and close around the handle. Behind
the lever, low and small, a railway track runs left to right, drawn as two parallel rails
with short sleepers across them, and it splits into two branches that separate as they go
right. The lever fills the left half of the frame and is much larger than the track
behind it.
```

**C · top-down map — the arithmetic** (drop the camera sentence from the style block)

```
SCENE. A bird's-eye view looking straight down from directly above at a railway
junction, like a map. The track enters at the bottom of the frame as two parallel rails
with short sleepers laid across them, and splits into two branches that spread apart as
they run toward the top of the frame. On the left branch stand five small people seen
from directly overhead, each a plain round head with shoulders, in a row and evenly
spaced. On the right branch stands one small person of the same overhead shape, alone. A
small square switch plate sits beside the split where the two branches part.
```

**D · unrelated subject — the weighing**

```
SCENE. A large two-pan balance scale standing on the ground, seen from the side, filling
most of the frame. A tall upright column rises from a wide base and carries a straight
horizontal beam across its top. From each end of the beam hangs a shallow round pan on
three straight cords. The left pan holds a stack of five plain round discs and hangs low.
The right pan holds one single disc of the same size and rides high. The beam tilts down
to the left.
```

D exists to prove the block carries to any subject. It shares nothing with a railway and
still came back in the same hand.

## What still drifts

- **The background.** The top-down scene laid its own tan ground over the field colour.
  Repaint it — `pack.py --raster` already snaps the background to the figure's field.
- **The palette**, always, a little. Snap fills afterwards;
  `design/figure-art/finish-trolley.py` is the worked example.
- **Outline weight** across a set is close but not identical. It is the first thing the
  eye catches, so compare a contact sheet of the whole set before wiring any of it.
