# The trolley problem: what is drawn, and by what

Lesson `phil-6`. This file is the whole reference for its art. It replaces the old
Grok brief, which asked one generator for the entire scene and was wrong to.

## The rule this lesson taught us

**Code draws anything that has to line up. Generation draws objects that sit in it.**

Fifteen Recraft rolls and four prompt generations never once put the tram on the rails
or drew the fork correctly. `fxTrack` gets it right every time, because it is
arithmetic: a centre line, two rails offset ±7 from it, a tie every 30 along it. Five
people is `ForEach(0..<5)`, not a wish.

So the split is:

| Part | Drawn by | Where |
| --- | --- | --- |
| track, fork, sleepers | code | `fxTrack` in `TrolleyFigure` |
| the five, the one, the lever, every word | code | `fxPerson`, `fxText` in `TrolleyFigure` |
| the tram | generated object | `fig-trolley`, placed with `fxArt` |
| the footbridge scene | generated scene | card 4, which has no art today |

## Sitting a generated object on a code-drawn rail

Two numbers, no eyeballing:

1. **Give the box the art's own aspect.** `fig-trolley` is 1.135 (the pantograph makes
   it near-square). `fxArt` uses `scaledToFit`, so a box of any other shape leaves slack
   and the object floats inside it.
2. **Make the box bottom the rail top.** A horizontal `fxTrack(_, 118, _, 118)` puts its
   rails at 118 ± 7, so the rail top is 111. The wheels are the lowest ink in the art,
   so bottom-aligned means wheels on rail.

That gives the call in `TrolleyFigure`: `fxArt("trolley", 14, 29.9, 92, 81.1)`.

## The gap worth generating

The figure has five reveal steps and none of them is the footbridge. Card 4 is an
`example` card with no art at all — and the footbridge is the whole point of the
lesson: the lever and the push are the same arithmetic and not the same act. Chips
cannot say that. A picture can.

## The Gemini prompt for the footbridge

Tested. Attach two reference images with it — `preview/scene-cave.png` and
`preview/trolley.png` — and read `../../.claude/skills/figure-art/SKILL.md` first for
what the parameters actually do.

Settings: `gemini-3.1-flash-image`, `aspect_ratio` `4:3`, `image_size` `2K`,
`thinking_level` `high`, grounding **off** (it is for real-world subjects and only adds
noise here), `negative_prompt` and `system_instruction` **left empty** — Gemini has
neither, and a wrapper that offers them just pastes your exclusions into the prompt.

```
The attached pictures are the house drawing style. Draw a new picture that matches them
exactly in line weight, flat colour and feel.

A flat side view of a railway scene, camera at eye level, straight on, the whole scene
filling the frame. A railway track runs left to right across the lower third: two long
parallel rails with short wooden sleepers laid across them in an even row, like a ladder
lying down. A small red tram with two round black wheels sits on the track at the far
left, its wheels resting on the rails, facing right.

Standing on the track at the far right is a row of people. Count them as you draw: the
first person, then a second beside them, then a third, then a fourth, then a fifth. Five
people in total and no more, all identical, evenly spaced, all the same height and the
same simple shape.

Spanning the track between the tram and those five stands a footbridge: one straight
flat deck resting on two straight vertical legs, one leg on each side of the track,
raised high enough that the tram would pass underneath. Standing on the middle of the
deck are two people, seen from the side. One is a small person of the same simple shape
as the five. Beside them stands one noticeably larger and heavier person, close to the
deck's edge. The small person has one arm reaching out toward the larger person's back.

Every shape is filled with one single flat colour with a hard clean edge, drawn from
coral red #FF6F61, lavender #C3B2F0 and sky blue #9BC8F2, and every shape is traced with
the same thick even dark brown #2E2622 outline of equal weight all the way round. Every
surface is blank and unlettered: the tram's windows are clear empty white panes, the
bridge deck is a plain painted board. The whole background is one plain solid pale sky
blue #E6F0FB. The top third of the frame is open empty sky, and the people stand clear
of the bottom edge.
```

### Why it is written that way

- **The counting paragraph earns its length.** "Five people" returns four, every time,
  from both Recraft and Gemini. Enumerating them — first, second, third, fourth, fifth,
  then "five in total and no more" — returned five on both rolls.
- **The track is described by its marks**, not its name. "Two long parallel rails with
  short wooden sleepers laid across them" gets a railway. "A railway track" gets a
  coloured ribbon.
- **Nothing is excluded, only described.** Not "no text" but "every surface is blank and
  unlettered". Not "no shading" but "one single flat colour with a hard clean edge".
- **The camera is named.** Flat side view, eye level, straight on.
- **The empty top is asked for**, because the code draws the labels there.

## What still comes back wrong

- **Palette drift.** The sleepers came back brown both times. Snap fills to the house
  palette afterwards — `finish-trolley.py` is the worked example.
- **The five stand beside the track**, not on it, about half the time. Reroll.
- Reference images carry more than style: the pantograph on the tram transferred from
  `preview/trolley.png` without being asked for. Useful, but check nothing else rode
  along.

## Then

```bash
python3 design/figure-art/pack.py --raster bridge      # from design/art-src/figures/
python3 design/figure-art/figcheck.py --all
```

Register the id in `LessonFigure.drawn` and `LessonFigure.field(_:)`, and keep every
word in code so it stays crisp, themeable and translatable.
