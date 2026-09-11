#!/usr/bin/env python3
"""Turns before.png and after.png (from shoot.js) into the two images the site
build looks for: the hero before/after at 1120x520 and the card at 520x260,
both at 2x. Run from anywhere:  python3 design/site-shots/compose.py
"""
import json
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SITE = ROOT / "site" / "img"
SCALE = 2
# The mascot still the site shows. Another session may replace it with a new
# rig at a new size, so the crop below reads the fish's bounds off the file
# instead of trusting numbers from an older one.
SPROUT = ROOT / "ios/Resources/Assets.xcassets/sprout-mint-2.imageset/sprout-mint-2@3x.png"

# Which frames the site shows. shoot.js writes one per image theme, light and
# dark (theme-<id>.png, theme-<id>-dark.png, kept here as .webp), plus before / after / after-dark
# for the plain skin. The label under the hero comes from here too, through
# site/img/shots.json, so the words and the picture cannot drift apart.
HERO_AFTER = ("theme-deepsea", "After · Prepkin, Deep Sea theme")
CARD = ("theme-deepsea-dark", "Deep Sea theme, dark")

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


def sprout() -> None:
    """The fish, trimmed to its own alpha bounds with a little air at the sides
    and top. The still is drawn to bleed off the bottom, so no air there."""
    im = Image.open(SPROUT).convert("RGBA")
    left, top, right, bottom = im.split()[-1].getbbox()
    air = 6 * SCALE
    out = im.crop((max(0, left - air), max(0, top - air), min(im.width, right + air), bottom))
    out.save(SITE / "sprout.png", optimize=True)
    print(f"sprout.png: {out.size}, from {SPROUT.relative_to(ROOT)}")


def ingest() -> None:
    """shoot.js writes PNG (Playwright cannot write WebP). Keep the frames as
    WebP instead: a 2560 x 1720 PNG of a wallpaper theme is 2 to 3 MB each."""
    for png in sorted(HERE.glob("*.png")):
        if png.name == "themes-sheet.png":
            continue
        Image.open(png).convert("RGB").save(png.with_suffix(".webp"), quality=92, method=6)
        png.unlink()
        print(f"{png.name} -> .webp")


def main() -> None:
    ingest()
    sprout()
    before = Image.open(HERE / "before.webp").convert("RGB")
    after = Image.open(HERE / f"{HERO_AFTER[0]}.webp").convert("RGB")
    card_src = Image.open(HERE / f"{CARD[0]}.webp").convert("RGB")
    SITE.mkdir(parents=True, exist_ok=True)
    # WebP: the wallpaper art makes a PNG of these over a megabyte.
    hero(before, after).save(SITE / "canvas-before-after.webp", quality=84, method=6)
    card(card_src).save(SITE / "canvas-card.webp", quality=84, method=6)
    (SITE / "shots.json").write_text(json.dumps({"hero": HERO_AFTER[1], "card": CARD[1]}, indent=1) + "\n")
    for name in ["canvas-before-after.webp", "canvas-card.webp"]:
        p = SITE / name
        print(f"{name}: {Image.open(p).size}, {p.stat().st_size // 1024} KB")
    print(f"labels: {HERO_AFTER[1]} / {CARD[1]}")


if __name__ == "__main__":
    main()
