# Grok prompts: full scenes for the 23 Learn figures

## How Grok reads a prompt (this changes how to write one)

- **Grok rewrites your prompt before drawing.** The API returns a `revised_prompt`; the app does the same silently. Short natural sentences survive the rewrite; long keyword lists and rule lists get paraphrased. Keep it to one paragraph with the must-haves first.
- **There is no negative prompt.** So the prompts below say what to draw, not what to avoid. The one "no" that matters is *wordless*, said once and early. If letters still show up, rerun; don't argue with it.
- **Style words work when woven into the sentence**, not stacked at the end. Each prompt below reads as one description.
- **Consistency comes from edit mode, not from repeating words.** Grok's edit mode takes a source image and keeps its look. That's the lever.

## Two ways to run these

**A. Edit mode from the cave scene (recommended).** In Grok Imagine, upload `design/figure-art/preview/scene-cave.png`, then paste:

```
Keep this exact drawing style, line weight, colours and flat background. Replace the whole scene with: <paste the scene paragraph below>
```

Do this for every one of the 23, always from the cave image (not from the previous result, or the style drifts).

**B. Plain text-to-image.** Paste the paragraph as is. Expect more drift between images; keep the 4:3 ratio and rerun any that stray.

**Settings:** aspect ratio 4:3 (the app offers it; API value `"4:3"`), resolution 1k is enough, PNG. Save each as `design/art-src/figures/<id>.png` using the bold id.

**Reject and rerun if:** any letters or numbers appear, the background isn't the named colour, shapes have shading or soft edges, or the empty area is filled. I can't fix those after; a raster can't be re-inked.


## **slots** · Your brain holds about four things

```
A cardboard drink carrier with four cup slots seen slightly from above, four paper cups sitting in the slots, a fifth cup tipping off the right edge. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from warm yellow #FFC24B, white, coral red #FF6F61, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid soft cream (#FFF4DC). Empty space across the top third. Landscape 4:3.
```


## **refresh** · Why you can't stop scrolling

```
 Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from white, sky blue #9BC8F2, warm yellow #FFC24B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale sky blue (#E6F0FB). A hand holding a smartphone upright, thumb on the screen pulling down, the screen plain light blue and empty. Empty space on the right third. Landscape 4:3.
```


## **sunk** · The sunk cost trap

```
A large cinema ticket with a perforated tear line one third from the left, lying on a cinema seat armrest, a small popcorn bucket beside it. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from warm yellow #FFC24B, coral red #FF6F61, white, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid soft cream (#FFF4DC). Empty space across the bottom quarter. Landscape 4:3.
```


## **filter** · Confirmation bias

```
A large funnel standing upright, marbles pouring toward its mouth from the left, some bouncing off its rim, a glass jar under the spout. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from sky blue #9BC8F2, leaf green #A5CE6B, warm grey #D9CFC0, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale mint green (#EAF4E0). Empty space on the right third. Landscape 4:3.
```


## **spotlight** · Nobody is watching you that closely

```
A stage spotlight lamp at the top shining a wide cone of light down onto one small person on a round stage, four smaller people standing in the dark on either side each under a faint small cone. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from warm yellow #FFC24B, lavender #C3B2F0, coral red #FF6F61, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale lavender (#EDE7FB). Empty space at the top corners. Landscape 4:3.
```


## **loop** · The habit loop

```
A round race track seen from above forming a ring, three small flags planted at three points on the ring, one small runner on the track. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from sky blue #9BC8F2, warm yellow #FFC24B, coral red #FF6F61, leaf green #A5CE6B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale sky blue (#E6F0FB). The centre of the ring empty. Landscape 4:3.
```


## **arousal** · Say 'I'm excited', not 'calm down'

```
 Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from coral red #FF6F61, white, sky blue #9BC8F2, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale sky blue (#E6F0FB). A person standing facing forward with a large heart shape over the chest and a pulse line across the heart, two empty thought bubbles above, one at the left and one at the right. Landscape 4:3.
```


## **email** · Ask for an extension the right way

```
 Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from white, sky blue #9BC8F2, coral red #FF6F61, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale peach (#FFEDE7). An open laptop on a desk showing an empty email window with a blank white body, a paper envelope leaning against the laptop. The email body empty. Landscape 4:3.
```


## **no** · How to say no

```
A person standing in front of a closed door in a wall, one hand raised palm out in a stop gesture, calm face. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from coral red #FF6F61, white, warm yellow #FFC24B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale peach (#FFEDE7). Empty wall space above the door. Landscape 4:3.
```


## **echo** · Listen so people feel heard

```
 Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from lavender #C3B2F0, white, leaf green #A5CE6B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale peach (#FFEDE7). Two people sitting on a bench facing each other, one with a sad expression, two large empty speech bubbles above them, one over each person. Landscape 4:3.
```


## **ladder** · Small talk without the panic

```
A wooden step ladder with three rungs standing on the floor, a person climbing on the lowest rung. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from warm yellow #FFC24B, white, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale peach (#FFEDE7). Empty space on the right half. Landscape 4:3.
```


## **apology** · A real apology has three parts

```
Two grassy banks with a gap between them, a plank bridge of three planks laid across the gap, one small person standing on each bank. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from leaf green #A5CE6B, warm yellow #FFC24B, white, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale peach (#FFEDE7). Empty space across the top third. Landscape 4:3.
```


## **paycheck** · Where your paycheck goes

```
A pay slip sheet of paper lying on a desk beside a coffee mug and a pen, the pay slip large with only a coloured header band and blank space below. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from white, warm yellow #FFC24B, leaf green #A5CE6B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid soft cream (#FFF4DC).  Landscape 4:3.
```


## **brackets** · Tax brackets aren't what you think

```
Three buckets stacked in a tower, the bottom bucket full of gold coins, the middle bucket half full, the top bucket with only a few coins. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from warm yellow #FFC24B, leaf green #A5CE6B, sky blue #9BC8F2, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid soft cream (#FFF4DC). Empty space on the left third. Landscape 4:3.
```


## **jar** · A Roth IRA at 18

```
A glass jar with a yellow lid standing on a wooden shelf, a few gold coins at the bottom and a small green sprout growing from them. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from white, warm yellow #FFC24B, leaf green #A5CE6B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid soft cream (#FFF4DC). Empty space on the right third. Landscape 4:3.
```


## **burrito** · Why a dollar shrinks

```
A burrito wrapped in foil on a plate, one end cut open showing green lettuce, red salsa and rice, a small blank price tag on a string. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from warm yellow #FFC24B, leaf green #A5CE6B, coral red #FF6F61, warm grey #D9CFC0, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid soft cream (#FFF4DC). Empty space across the top quarter. Landscape 4:3.
```


## **trolley** · The trolley problem

**Do not use a whole-scene prompt for this one. See [TROLLEY-ART.md](TROLLEY-ART.md).**

Fifteen rolls of the prompt that used to sit here never put the tram on the rails and
never drew the fork correctly. The track, the fork and the counts are drawn in code by
`TrolleyFigure`; only the tram and the footbridge are generated. That file has the
tested Gemini prompt and the two numbers that sit the tram on the rail.


## **ship** · The ship of Theseus

```
A wooden sailing ship with a white sail moored at a dock, a stack of old grey planks on the dock and a carpenter holding a hammer. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from warm grey #D9CFC0, white, warm yellow #FFC24B, leaf green #A5CE6B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale lavender (#EDE7FB). Empty space across the top quarter. Landscape 4:3.
```


## **cave** · Plato's cave

```
The inside of a cave, three people sitting in a row facing the cave wall where dark shadows fall, a campfire burning behind them, a bright opening to the outside on the right. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from lavender #C3B2F0, coral red #FF6F61, warm yellow #FFC24B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale lavender (#EDE7FB). Empty space on the wall above the shadows. Landscape 4:3.
```


## **cornell** · Notes you'll actually reread

```
A notebook page divided by lines into a narrow left column, a wide right area and a strip along the bottom, a pencil lying beside it, all areas blank. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from white, warm yellow #FFC24B, sky blue #9BC8F2, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale mint green (#EAF4E0).  Landscape 4:3.
```


## **feynman** · Explain it to a twelve-year-old

```
 Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from leaf green #A5CE6B, warm yellow #FFC24B, white, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale mint green (#EAF4E0). A person standing at a large blank chalkboard explaining to a child sitting on a stool, the chalkboard filling most of the picture and empty. Landscape 4:3.
```


## **sleep** · Sleep is part of studying

```
 Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from lavender #C3B2F0, sky blue #9BC8F2, warm yellow #FFC24B, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale sky blue (#E6F0FB). A person asleep in a bed under a window showing a crescent moon, a long horizontal empty bar below the bed like a timeline. Empty space at the bottom. Landscape 4:3.
```


## **exam** · The first minute of a test

```
An exam paper on a desk with five blank numbered lines, a pencil and a small clock beside it. Drawn as a flat, wordless vector illustration for a learning app: big simple shapes, each filled with one flat colour from white, leaf green #A5CE6B, coral red #FF6F61, and every shape traced with the same thick, even dark brown (#2E2622) outline. No shading, no gradients, no texture, no writing of any kind. The whole background is one plain solid pale mint green (#EAF4E0). Empty space at the bottom of the paper. Landscape 4:3.
```
