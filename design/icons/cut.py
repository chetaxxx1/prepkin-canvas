#!/usr/bin/env python3
"""Cut the generated sheets in src/ into one transparent PNG per icon.

Three things happen here, and all three matter:

1. **Background removal is a flood from the border, not a colour key.** A colour
   key eats the white highlight inside a glass or a flashcard. Flooding inward
   from the edge only removes white the object is not sitting on.
2. **Sizing is by ink area, not by bounding box.** A pencil is a thin diagonal;
   fitting it to a box makes it tower over the apple next to it. Matching the
   number of painted pixels is what makes a row of tiles look even.
3. Everything lands on a square 512 canvas so the app never has to think about
   an icon's aspect.

Run:  python3 design/icons/cut.py
"""
import os, sys, math
from collections import deque
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import icons as M

SRC = os.path.join(HERE, "src")
OUT = os.path.join(HERE, "png")
CANVAS = 512

COVER = 0.30       # share of the canvas an icon's ink should fill
BARE_COVER = 0.44  # an icon with no tile behind it fills more of its box
BOX = 0.94         # ...but never wider or taller than this


def dewhite(im, tol=26):
    im = im.convert("RGBA")
    a = np.array(im)
    h, w, _ = a.shape
    near = np.abs(a[:, :, :3].astype(int) - 255).max(axis=2) <= tol
    seen = np.zeros((h, w), bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if near[y, x] and not seen[y, x]:
                seen[y, x] = True; q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if near[y, x] and not seen[y, x]:
                seen[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and near[ny, nx] and not seen[ny, nx]:
                seen[ny, nx] = True; q.append((ny, nx))
    a[:, :, 3] = np.where(seen, 0, a[:, :, 3])
    out = Image.fromarray(a, "RGBA")
    out.putalpha(out.split()[3].filter(ImageFilter.GaussianBlur(0.7)))
    b = out.getbbox()
    return out.crop(b) if b else out


def cell(sheet, cols, rows, i):
    W, H = sheet.size
    cw, ch = W // cols, H // rows
    r, c = divmod(i, cols)
    part = sheet.crop((c * cw, r * ch, (c + 1) * cw, (r + 1) * ch))
    part.thumbnail((560, 560), Image.LANCZOS)
    return dewhite(part)


def place(im, cover=COVER):
    a = np.array(im.convert("RGBA"))[:, :, 3]
    ink = int((a > 40).sum())
    if not ink:
        return im
    s = math.sqrt(cover * CANVAS * CANVAS / ink)
    w, h = max(1, int(im.width * s)), max(1, int(im.height * s))
    cap = int(CANVAS * BOX)
    if max(w, h) > cap:
        k = cap / max(w, h)
        w, h = max(1, int(w * k)), max(1, int(h * k))
    r = im.resize((w, h), Image.LANCZOS)
    out = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    out.alpha_composite(r, ((CANVAS - w) // 2, (CANVAS - h) // 2))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    sheets = {k: Image.open(os.path.join(SRC, k + ".png")).convert("RGBA")
              for k in M.GRIDS}
    for name, _, group, _, src, idx in M.SET:
        cols, rows = M.GRIDS[src]
        cover = BARE_COVER if name in M.NO_TILE else COVER
        place(cell(sheets[src], cols, rows, idx), cover).save(
            os.path.join(OUT, name + ".png"))
    print(f"{len(M.SET)} icons -> {OUT}")


if __name__ == "__main__":
    main()
