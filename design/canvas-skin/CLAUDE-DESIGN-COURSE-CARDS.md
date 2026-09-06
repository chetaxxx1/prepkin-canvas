# Claude Design brief: the course card on Canvas

Paste everything below the line into Claude Design. One screen per handoff.

---

Read `design/CLAUDE-DESIGN-PREAMBLE.md`, `DESIGN.md`, and `extension/skin.css` in
github.com/chetaxxx1/prepkin-canvas before drawing. This handoff is for the Chrome
extension, not the iPhone app, so the phone rules about screen size do not apply.

## What you are designing

The **course card** on a student's Canvas dashboard, as restyled by the Prepkin
extension. Today it is Canvas's stock card with four things added, and it looks like
a stock card with things stuck on. Make it one designed object.

Current state to beat: `design/signoff/themes/final-graffiti-dark-pill.png` (image
theme) and `design/signoff/themes/rail-classic-light.png` (flat theme). The flat one
is the ugly one: a 60px colour block, a white title box with rounded corners that
overlaps it, a "Nothing due" line, then a row of grey icons floating in space.

## What the card has to carry (these are the features, make them read)

1. **Course name and code.** Canvas's own text, we only style it. Name is often long
   and truncates.
2. **The course colour.** The student picked it in Canvas. It must stay visible on
   the card as colour, because students learn "red is Physics". Today it is a 60px
   block (flat themes) or a 6px strip under the banner (image themes).
3. **Grade pill.** "88.5%" from the extension's own read of Canvas. Opt-in. Top-left
   today. Should feel like a stat, not a sticker.
4. **Next due line.** "Due 7:54 PM · Problem Set 7", or "Nothing due", or amber
   "Was due 8:03 AM today · still counts" when it slipped. This is the most useful
   thing on the card. Make it the second-loudest element after the name.
5. **Banner art** on image themes: a 3:1 illustration across the top of the card
   (see `extension/art/graffiti/card-1.webp`). Flat themes have no art.
6. **Canvas's action icons** (announcements, assignments, discussions, files) with
   their unread badges. Canvas draws these. We may space and tint them, never hide
   them.
7. **Canvas's three-dot menu button**, 36px, top-right of the header. It stays and
   it is a Canvas button, so we cannot restyle it. Leave it a clear 12px inset.

## Hard rules

- Never change `font-family`. Canvas's Lato stays.
- Never hide or move a Canvas control. Icons and the three-dot menu keep their place.
- Never red. Overdue is amber (see DESIGN.md).
- Text contrast 4.5:1 or better on every paper, light and dark.
- Card width is 262px, or 220px in Compact mode. Height is whatever the content needs.
- We can only add two elements of our own: the grade pill and the due line. Everything
  else is Canvas's markup, restyled with CSS. So the design must be achievable by
  styling these Canvas parts: card, header, hero (the colour block), header content
  (name + code), action row, plus our two additions.
- Twelve papers exist (see `extension/receipt.js` PAPERS). Show the card on
  Newsprint (light) and Carbon (dark) at minimum.

## Deliver

One artboard, 1280 wide, showing a dashboard row of four cards in each of four
states, stacked:

1. Flat theme, light paper (Classic Cream), grade pill on.
2. Flat theme, dark paper, one card overdue (amber), one with nothing due.
3. Image theme (Graffiti), dark paper, banners on, the course colour still readable.
4. Compact mode, light, 220px cards.

Then a spec sheet: paddings, radii, type sizes and weights, colour tokens by name
from DESIGN.md, and where the course colour lives on the card. Export as HTML/CSS
using the real Canvas class names (`.ic-DashboardCard`, `.ic-DashboardCard__header`,
`.ic-DashboardCard__header_hero`, `.ic-DashboardCard__header_content`,
`.ic-DashboardCard__header-title`, `.ic-DashboardCard__header-subtitle`,
`.ic-DashboardCard__action-container`, plus ours: `.pk-card-grade`, `.pk-card-due`)
so it ports straight into `skin.css`.

Do not draw the mascot. Do not invent data; use course names like
"AP Physics C: Mechanics" / "PHYS-C-1" and real-looking due lines.
