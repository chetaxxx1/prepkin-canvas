# Art for the image themes: what to generate in Grok

Each theme needs **one wallpaper** (the page background) and **four card banners**
(the strip at the top of each course card). Everything ships inside the
extension, nothing is fetched. Drop the originals here, with these names:

```
design/art-src/<theme>/wallpaper.png     2560 x 1440  (16:9)
design/art-src/<theme>/card-1.png        1200 x 400   (3:1)
design/art-src/<theme>/card-2.png
design/art-src/<theme>/card-3.png
design/art-src/<theme>/card-4.png
```

Then run `bash bridge/art-pack.sh`. It shrinks them to WebP under
`extension/art/<theme>/` (about 650 KB a theme instead of 9 MB) and lists the
theme in `extension/art/manifest.js`, which is what turns the real art on. A
theme with no folder yet shows placeholder art, so nothing breaks while you
are still generating. Done so far: graffiti (Grok, 2026-09-05); neoncity, vaporwave, deepsea, forest, spring, cafe, nebula (generated in-session with the Gemini image model, 2026-09-06). Originals in design/art-src/<theme>/.

## The master prompt (paste this, then one theme line)

```
Create a matching set of 5 images for a browser theme, in one consistent style
and palette: 1 wallpaper at 2560x1440 and 4 banners at 1200x400.

Style rules, all of them:
- Illustrated, rich and ornate, but with LOW-to-MEDIUM contrast and no pure
  white or pure black: text will be laid on top, so leave calm areas and avoid
  busy detail in the centre of the wallpaper.
- No text, no letters, no logos, no watermarks, no faces, no people.
- The 4 banners are 4 different crops or scenes from the same world, each with
  a clear focal point in the middle third, so they read as a set on a grid of
  course cards.
- Colours: one dominant hue family plus one accent, both stated below. Keep the
  palette tight so the set looks like one theme.
- Edges of the wallpaper should be darker or quieter than the middle.

Theme:
```

## The theme lines (one per run)

```
GRAFFITI: a painted brick wall at night, layered spray-paint shapes, drips and
stencil marks, wildstyle abstract forms (no legible letters), hot pink and
electric cyan on charcoal brick, wet-street sheen.

ANIME NIGHT CITY: rainy Tokyo side street at night, neon signs as abstract
glowing shapes (no legible text), reflections on wet asphalt, lavender-blue
dusk with warm orange window light.

Y2K CHROME: liquid chrome blobs and glossy bubbles on a soft pink-to-silver
gradient, lens flares, early-2000s desktop wallpaper feel, baby blue accent.

DARK ACADEMIA: an old library reading room, oak shelves, green banker's lamp,
candlelight, parchment and oxblood tones, soft dust in the light.

COTTAGECORE: a wildflower meadow at golden hour, a cottage window box,
mushrooms and bees, cream and sage with terracotta accent, painterly.

VAPORWAVE: a sunset over a glowing grid horizon, palm silhouettes, a marble
bust as an abstract shape, magenta to teal gradient, retro-futurist.

DEEP SEA: sunlight rays through deep blue water, kelp, jellyfish glow, coral
in the foreground, navy with seafoam accent, calm and slow.

NEBULA: a soft space nebula with sparse stars, indigo and plum with a single
warm gold accent, minimal, no planets with rings.

COZY CAFE: a rainy-day café window seat, latte art, warm wood, string lights
as soft bokeh, caramel and cream with a muted red accent.

RETRO ARCADE: pixel-art arcade cabinet lights and CRT glow, deep purple and
black with neon green and orange accents, chunky pixel shapes, no legible text.

CHERRY BLOSSOM: sakura branches against a pale dawn sky, petals in the air,
blush pink with a deep plum accent, Japanese woodblock feel.

LOFI ROOM: a bedroom desk at night, window with rain, a lamp, plants, a cat
asleep, muted purple-grey with warm amber lamp light, lo-fi illustration.
```

## When you have them

Drop the folders into `extension/art/` and tell me. I wire each theme's paper,
accent and buddy accessory to the art, dim the wallpaper under a paper wash so
every card and line stays readable, keep the course colour as a strip under
each banner, and test the lot on the real Canvas. Four banners per theme is
what makes a grid of cards look like a set; one banner repeated looks flat.
