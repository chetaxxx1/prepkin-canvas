# How a lesson figure is built

The house rules, and the two mistakes that produced most of the rework.

## The wordless test

**Switch every word off. A stranger must still be able to name the object.**

This is the acceptance test. Everything below serves it.

The renderer draws each figure twice, once whole and once with `Fig.drawText` off:

```bash
scratchpad/render/render <outdir> --probe            # every figure, every step, both ways
python3 design/figure-art/textcheck.py <outdir>      # what sits under each word
```

`textcheck.py` diffs the pair. The pixels that differ are the glyphs; it then samples the
wordless image underneath them. One flat colour means the word is inside a shape or on
open field, which is fine. Two or more means the word lies across an edge.

## The mistake that caused the rework

An early version of these rules said "ONE big flat mass". Taken literally that produces a
featureless rounded rectangle with a word on it, and then the word is carrying the whole
idea. Twenty of the fifty-four figures failed the wordless test for exactly that reason: a
track that was a flat band read as a road, an email that was four coloured bars read as a
bar chart, a ticket with no perforation read as a progress bar.

**The mass has to be a recognisable object.** Give it the two or three marks that define
it, and nothing more:

| object | the marks that make it read |
| --- | --- |
| railway track | two rails and the ties across them |
| ticket | a dashed perforation and a notch bitten out of both edges |
| email | a header rule, a To line, a Send button |
| jar | a lid band and a rim |
| map | a coastline, one road, one pin |
| pay stub | a torn top edge, ruled lines, a heavier total rule |
| offer letter | a logo block, ruled lines of *different* lengths, a signature squiggle |
| phone feed | rows, each an avatar circle and two short lines |

These marks are the object, not texture. Texture is decoration that carries no meaning:
hatching, wood grain, rows of dots. A tie on a track carries the whole meaning.

## The rest of the house style

- flat fills, black outlines; no gradients, perspective or drop shadows
- one mass that is the subject, big, ideally bleeding off one edge on purpose
- one big word, caps, 20 to 34pt, inside the mass
- every other label one or two words at `Fig.caption` (12) or `Fig.label` (13)
- at most ten words on the densest step; no sentences on the art, they live in the card
- the whole silhouette at step 1; each later step adds exactly one thing, and nothing
  moves, recolours or disappears
- nothing outside x 16..344 or y 14..286, except the mass bleeding off an edge
- no word within 3pt of a drawn shape's edge, unless a strike-through crosses it on purpose
- every number on the art is computed, never eyeballed: see `charts.py`

## The two checks

```bash
python3 design/figure-art/figcheck.py --all     # scale, fit, safe box, type on type, dead steps
python3 design/figure-art/textcheck.py <probe>  # type on shapes, by pixel
```

`figcheck` reads the source. `textcheck` reads the pixels. The second exists because the
first only ever compared words against other words, and a word was shipped sitting on a
drawn person's head.
