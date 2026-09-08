---
name: figure-art
description: Generate and wire the raster art behind Prepkin's Learn figures. Covers what actually controls a Google or xAI image generation (and what does not), the house prompt rules, the per-card chain format, and the pipeline from a generated PNG to a working figure in the app. Triggers when asked to make, redo, prompt for, or wire up lesson figure art, write image prompts for Gemini or Grok, or fix art that came back wrong. Does NOT trigger for the code-drawn figures themselves (see design/figure-art/RECIPE.md) or for app UI work.
---

# Lesson figure art

## The honest ceiling

You cannot get a prompt-only generation to land exactly where you want it. Say so
plainly when asked; do not promise pixel control you cannot deliver.

The four image models, and which to reach for:

| Model | Use it for |
| --- | --- |
| `gemini-3.1-flash-image` | the workhorse. Up to 4K, multi-turn editing, grounding. Default. |
| `gemini-3.1-flash-lite-image` | cheap and fast. 1K only, and **no multi-turn editing** |
| `gemini-3-pro-image` | top quality on a hard composition, and interleaved text + images |
| `gemini-2.5-flash-image` | legacy. Migrate off it. |

Every lever Gemini actually exposes:

| Lever | What it controls |
| --- | --- |
| `aspect_ratio` | `1:1` `3:2` `2:3` `3:4` `4:3` `4:5` `5:4` `9:16` `16:9` `21:9` |
| `image_size` | `512px` `1K` `2K` `4K` — uppercase K required; Lite is 1K only |
| `thinking_level` | `minimal` or `high`; 3.1 Flash and Lite only |
| `mime_type` | `image/png` or `image/jpeg` |
| `previous_interaction_id` | keeps a multi-turn edit on one thread |
| `tools: google_search` | grounds real-world subjects. **Turn it off for stylised art** — a flat vector illustration has no fact to check, and it only adds noise |
| reference images | 3.1 Flash takes **14 in total**: up to 10 object, 4 character, 3 style |

**No Gemini image model has any of these:** `seed`, negative prompt, system
instruction, or mask editing. Not one. If a job genuinely needs the rest of the frame
untouched, that is Vertex Imagen, not Gemini.

### The wrapper trap

Tooling around Gemini will offer you `negative_prompt` and `system_instruction` anyway
— the `nanobanana` MCP has both fields. Gemini supports neither, so a wrapper can only
be pasting that text into the prompt. That names the thing you want gone, which is the
one reliable way to summon it. **Leave both empty.** A good wrapper tells you it did
nothing: the result JSON comes back `"negative_prompt_applied": false`.

Two consequences worth stating out loud:

- **Gemini has no seed.** The same prompt twice gives two different pictures. Plan on
  keeping the one you like, not on reproducing it.
- **Gemini's editing is semantic, not masked.** Asking it to change one thing changes
  other things too. Over a five-image chain that drift compounds. It is the main reason
  a set stops looking like a set.

If a job genuinely needs the rest of the frame untouched, that is Vertex Imagen, not
Gemini: `EDIT_MODE_INPAINT_INSERTION` with a `REFERENCE_TYPE_RAW` image, a
`REFERENCE_TYPE_MASK` image, and `maskMode: MASK_MODE_USER_PROVIDED`. Tune with
`MASK_DILATION` (start 0.01) and `EDIT_STEPS` (start 35). This suits Prepkin's figures
unusually well, because each reveal step adds one thing inside a rectangle you can read
straight out of the Swift, so the mask is computable rather than hand-painted.

## How to prompt it

From Google's own guidance. Breaking these is what makes output look generic.

1. **Prose, not keywords.** A narrative paragraph beats a comma list. The model's
   strength is language understanding.
2. **Never write "no" or "don't".** There is no negative prompt on Gemini, and naming a
   thing to exclude tends to summon it. Describe the wanted state instead. Not "no
   speech bubbles" but "a sign is a plain painted board, a screen shows only shapes and
   colour, paper is ruled but unwritten".
3. **Name the camera.** Shot type, eye level, and where the subject sits in the frame
   are the real composition controls.
4. **Attach, don't describe, the layout.** Hand it a reference image for arrangement and
   for aspect ratio rather than spelling either out in words. Be aware that a reference
   carries more than style: a tram's pantograph transferred from an attached preview
   without ever being asked for. Useful, but check nothing else rode along.
5. **Count out loud, or you get one fewer.** "Five people" comes back as four, from
   Gemini and from Recraft alike. Enumerate instead — "the first person, then a second,
   then a third, then a fourth, then a fifth. Five in total and no more" — and it lands.
6. **Name an object by its marks, not by its name.** "A railway track" gets a coloured
   ribbon. "Two long parallel rails with short wooden sleepers laid across them" gets a
   railway. Same rule as the wordless test in `design/figure-art/RECIPE.md`.
7. **Expect palette drift regardless.** Snap fills to the house palette afterwards
   rather than re-rolling for colour; `design/figure-art/finish-trolley.py` is the
   worked example.

xAI is the alternative: `grok-imagine-image-2.0` edits from up to 5 source images and
returns up to 10 per request with aspect ratio and resolution control. It has no
documented seed or negative prompt, and it rewrites the prompt before generating, which
works against "change only this one thing". Fine for openers, weaker for chains.

## The house constraints

Every prompt carries these, phrased positively:

- **Every surface blank and unlettered.** The app draws all type in SwiftUI, and the
  words change per card. Baked-in text cannot be restyled or corrected later.
- **Quiet top third and clear margins.** The labels land on top of the picture.
- **Nothing pre-emphasised.** No highlight, circle or glow in the art; emphasis is added
  one card at a time in code.
- **4:3**, subject centred. The card is 360 by 300 points.

## Two modes. Pick one before you write a prompt.

| The cards are… | Mode | Where |
| --- | --- | --- |
| steps in one drawing | **chain** — one picture, one small edit per card | below |
| different moments | **style-locked variation** — a different picture per card, one look | `design/figure-art/STYLE-BLOCK.md` |

They use opposite levers and fight each other. A chain leans on
`previous_interaction_id` and "keep everything else exactly the same". Variation forbids
both and leans on a fixed style block plus three fixed style references. Mixing them
gives you drift with none of the payoff.

## One picture per card (chain mode)

A raster cannot reveal itself, so a lesson is a chain, not one hero image: a first
image, then one small edit per figure card, so the drawing builds as the student reads.
Match the chain length to the lesson's figure-card count in
`ios/Resources/Content/lessons.json`.

Each step prompt opens with "Here is the picture so far. Make exactly one change to it:"
and closes with Google's preservation wording: "Keep everything else in the image
exactly the same, preserving the original style, lighting, composition, camera angle,
characters, clothing and colours." A step that cuts to a different setting is a fresh
generation using the previous image as a style and character reference instead.

## The pipeline

```bash
# 1. Layout references: the code figure at each step, to attach with each prompt
scratchpad/render/render <dir> --probe            # every figure, every step, twice
# 2. After the art comes back, pack it into the catalogue at 3x
python3 design/figure-art/pack.py --raster <folder>
# 3. Both checks still have to pass afterwards
python3 design/figure-art/figcheck.py --all       # scale, safe box, type on type
python3 design/figure-art/textcheck.py <dir>      # type on shapes, by pixel
```

Draw the art with `fxArt("scene-<id>", x, y, w, h)`, register the id in
`LessonFigure.drawn` and in `LessonFigure.field(_:)`, and keep every label in code so it
stays crisp, themeable and translatable.

`pack.py --raster` repaints the background to the figure's exact field colour so the art
and the card read as one surface. The field colours are in `Fig`: coinField `#FFF4DC`,
leafField `#EAF4E0`, skyField `#E6F0FB`, lavField `#EDE7FB`, roseField `#FFEDE7`.

## What to tell the owner

Raster art does not restyle later. If the palette moves, every generated image is
redrawn by hand, while the code-drawn figures follow along on their own. Say this before
a large generation run, not after.
