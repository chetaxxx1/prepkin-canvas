# Ink brief 01 — the launch marketing art

Paste the block below into Ink's chat. It is the only bot with nothing to do, and
one of these three assets blocks the Chrome submission outright.

## Why the brief is shaped this way

Ink's profile says **never redraw Sprout** and **never put text inside the art**.
Both promo images need Sprout and the wordmark in them. So Ink does not make the
finished image — it paints the **background plate** at the exact final size with an
empty reserved zone, and Claude Code composites the real Sprout PNG and the
wordmark on top.

That is the house rule anyway: code draws what has to line up, generation draws
objects. Sprout is a finished vector character with real stills at
`design/sprout-stills/`. Nothing should ever approximate him.

---

```text
Read /workspace/prepkin/FACTS.md first. Three jobs. Deliver them in this order,
because job 1 blocks a store submission and the other two do not.

HOW THESE GET USED, so you build them right:
You are painting BACKGROUND PLATES, not finished images. You never draw Sprout and
you never put a word of text in the art. I composite the real Sprout artwork and
the wordmark on top of your plate afterwards. So each plate needs a deliberately
quiet, empty zone where those go, and you tell me exactly where it is in pixels.

THE PALETTE. These are the app's real values. Use them, not something near them.
  paper      #F8F8F8   the off-white ground
  paperSunk  #F3ECE0   warm cream, the usual background
  tile       #FDF9F4   the lightest cream
  ink        #2E2622   near-black brown, all dark marks
  coral      #FF6F61   the action colour. One coral thing per image, maximum.
  mint       #57C79B   green
  mintSoft   #DFF3E9   pale green
  leaf       #A5CE6B   yellow-green
  coin       #FFC24B   the coin yellow
  hairline   #F0E9DC   for thin lines on cream

STYLE, same for all three:
Flat shapes. No photographic texture. No gradient deeper than two stops. No drop
shadows. Nothing glossy, nothing 3D, nothing airbrushed. It should look like it was
drawn by the same hand that drew a children's picture book, but for a 20-year-old.
Never cute-for-kids. Never corporate-illustration.

---

JOB 1 — Chrome Web Store small promo tile plate. 440 x 280 pixels, exact.
This is a required field in the listing. Nothing submits without it.

It appears at real size in a store grid next to other extensions, about the size of
a business card on screen. So: almost nothing in it. One idea.

The subject is water. Prepkin's mascot is a fish, the five tanks are called Lagoon,
Reef, Kelp, Dusk and Deep, and the product reskins a page. A plate that reads as
"calm water with room in it" is right. A plate with a laptop, a browser window, a
graduation cap or a book in it is wrong — every other study extension does that.

Reserve a quiet zone of roughly 150 x 150 pixels on the LEFT side for Sprout, and
keep the right two thirds calm enough that dark text sits on it legibly. Tell me the
exact rectangle you reserved.

Give me THREE options. Render each one at its true 440 x 280 and show me that, not a
big version. An image that only works at 1200px wide is not finished.

---

JOB 2 — Chrome Web Store marquee plate. 1400 x 560 pixels, exact.
Same subject, same palette, wider. This one is seen large, so it can carry more:
depth in the water, a suggestion of a tank floor, plants. Still no text and still no
fish from you.

Reserve a zone of roughly 420 x 420 pixels for Sprout, placed so the composition
still reads if he is not there. Tell me the rectangle.

One option first. I will pick a direction from job 1 and you carry it across.

---

JOB 3 — the site hero drawing. Single-colour line art, transparent PNG, 1600 wide.
This goes at the top of prepkin.com. Reference: Notion's Web Clipper page uses one
loose line drawing and nothing else, which is why it works with no screenshot.

Draw in ink #2E2622 only. Line weight even, hand-drawn feeling, not vector-perfect.
Subject: a hand holding a phone, and the phone's screen is a small tank of water.
No face, no person's body beyond the hand and wrist, no logo, no text.

Give me three options at 1600 wide, and also show each one shrunk to 600 wide,
because that is closer to how it will actually appear.

---

FOR EVERY DELIVERY, put these three lines under the image:
  1. Exact pixel dimensions.
  2. Every hex you used.
  3. The reserved rectangle, as x, y, width, height.

DO NOT:
- Draw Sprout, a fish, or any character. Not even a placeholder silhouette.
- Put any text, letter, number or logo in the art.
- Use a real brand, a real logo, or a real person.
- Deliver only a large version. Always show it at ship size too.
```

---

## After Ink delivers

The composite is mine, not Ink's:

- Sprout stills to use: `design/sprout-stills/sprout-scholar-mint-3@3x.png` or
  `sprout-grad-mint-3@3x.png`. Mint is the free coat, so it is the honest one to
  show a person who has not installed anything.
- The wordmark is set in the site's typeface once Claude Design names it. Until
  then the composite is a draft, not a submission.
- Chrome sizes to confirm at submission time rather than trusting this file:
  small tile 440x280, marquee 1400x560, screenshots 1280x800 or 640x400, up to five.

## What Ink is NOT doing

- **The five store screenshots.** Those are real captures of the running app and the
  skinned Canvas, framed. Not generated art.
- **Theme art.** All eight image themes already have a complete set in
  `design/art-src/` and ship as WebP through `bridge/art-pack.sh`. That work is done.
- **App icons or Learn figures.** Those have their own pipelines
  (`design/icons`, `chartkit`).
