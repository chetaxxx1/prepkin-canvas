#!/usr/bin/env python3
"""Turns before.png and after.png (from shoot.js) into the two images the site
build looks for: the hero before/after at 1120x520 and the card at 520x260,
both at 2x. Run from anywhere:  python3 design/site-shots/compose.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
SITE = HERE.parent.parent / "site" / "img"
SCALE = 2

# The site's hairline token, for the one-pixel rule round each frame.
HAIRLINE = (232, 224, 210)


def rounded(img: Image.Image, radius: int, border: tuple) -> Image.Image:
    """Clip to a rounded rectangle with a one-pixel hairline, like the site's frames."""
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius, fill=255)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(img.convert("RGBA"), (0, 0), mask)
    ImageDraw.Draw(out).rounded_rectangle((0, 0, w - 1, h - 1), radius, outline=border + (255,), width=SCALE)
    return out


# Where the dashboard's To Do column starts, in CSS px at the 1280 viewport
# shoot.js uses. The crops stop short of it: the rail, the header and the four
# course cards are what the skin changes, and a column cut mid-word is not.
CARDS_W = 990 * SCALE


def crop_top(img: Image.Image, aspect: float) -> Image.Image:
    """The largest top-left region at the frame's aspect ratio, no wider than
    the cards area."""
    w, h = img.size
    w = min(w, CARDS_W)
    if w / h > aspect:
        w = int(h * aspect)
    else:
        h = int(w / aspect)
    return img.crop((0, 0, w, h))


def hero(before: Image.Image, after: Image.Image) -> Image.Image:
    """Two frames on a transparent ground. The labels are HTML, so they follow
    the page's theme; the ground is the page's own paper."""
    W, H = 1120 * SCALE, 480 * SCALE
    gutter = 20 * SCALE
    fw = (W - gutter) // 2
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for i, img in enumerate([before, after]):
        x = i * (fw + gutter)
        frame = rounded(crop_top(img, fw / H).resize((fw, H), Image.LANCZOS), 14 * SCALE, HAIRLINE)
        canvas.paste(frame, (x, 0), frame)
    return canvas


def card(after: Image.Image) -> Image.Image:
    W, H = 520 * SCALE, 260 * SCALE
    return crop_top(after, W / H).resize((W, H), Image.LANCZOS)


def main() -> None:
    before = Image.open(HERE / "before.png").convert("RGB")
    # The dark paper is the frame that reads at hero size; the light skin is
    # deliberately quiet and looks like "nothing changed" at 550 px wide.
    after = Image.open(HERE / "after-dark.png").convert("RGB")
    SITE.mkdir(parents=True, exist_ok=True)
    hero(before, after).save(SITE / "canvas-before-after.png", optimize=True)
    card(after).save(SITE / "canvas-card.png", optimize=True)
    for name in ["canvas-before-after.png", "canvas-card.png"]:
        p = SITE / name
        print(f"{name}: {Image.open(p).size}, {p.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
