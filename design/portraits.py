#!/usr/bin/env python3
"""Where each three-star still's face is, for the round kin portraits.

The stills are not centred on the face: a ninja headband tail widens one side,
a costume shifts the body. So `SproutFace` cannot draw every still at the same
offset — the tab-bar kin drifted left or right by rig. This finds the eyes (the
dark pixels in the top 45% of the art) and writes their centre, as a fraction of
the image, to ios/Resources/Content/portraits.json. The view scales the still
2.15× the circle and puts that point a little above the centre.

Run after `design/capture_sprout.py` recaptures the stills:

    python3 design/portraits.py
"""
import glob, json, os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, 'ios', 'Resources', 'Assets.xcassets')
OUT = os.path.join(ROOT, 'ios', 'Resources', 'Content', 'portraits.json')
# The eyes sit at the circle's centre minus this much of the drawn width, which
# keeps the tuft in and the collar just showing — the framing picked 2026-09-10.
EYE_LIFT = 0.05
# How many circle-widths wide the still is drawn. One value now that every kin
# is a Sprout coat; a rig with gills or a helmet would want about 1.6.
SCALE = {}
DEFAULT_SCALE = 2.15
# Eyes the finder cannot see, set by eye on the still. Empty since the axolotl left.
OVERRIDES = {}

def blobs(mask, W, H):
    """Connected dark blobs on the quarter-scale mask: (area, cx, cy, bw, bh)."""
    seen = [[False] * W for _ in range(H)]
    out = []
    for y0 in range(H):
        for x0 in range(W):
            if not mask[y0][x0] or seen[y0][x0]:
                continue
            stack = [(x0, y0)]; seen[y0][x0] = True
            pts = []
            while stack:
                x, y = stack.pop(); pts.append((x, y))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if 0 <= xx < W and 0 <= yy < H and mask[yy][xx] and not seen[yy][xx]:
                        seen[yy][xx] = True; stack.append((xx, yy))
            xs = [q[0] for q in pts]; ys = [q[1] for q in pts]
            out.append((len(pts), sum(xs) / len(pts), sum(ys) / len(pts),
                        max(xs) - min(xs) + 1, max(ys) - min(ys) + 1))
    return out

def eyes(im):
    """Centre of the eyes: the lowest pair of compact dark blobs side by side.
    The rig's outlines are dark too, so a plain centroid or a row scan lands on
    them; a pair of small round blobs at the same height is only ever the eyes
    (or the glasses around them, which is the same point)."""
    Wf, Hf = im.size
    small = im.resize((Wf // 4, Hf // 4), Image.BILINEAR)
    W, H = small.size; px = small.load()
    bb = small.split()[3].getbbox(); top = bb[1]; stop = min(H, int(top + 0.62 * (bb[3] - top)))
    mask = [[(y < stop and px[x, y][3] > 200 and px[x, y][0] < 70 and px[x, y][1] < 70 and px[x, y][2] < 80)
             for x in range(W)] for y in range(H)]
    cands = [b for b in blobs(mask, W, H)
             if 0.0003 * W * H <= b[0] <= 0.02 * W * H and 0.4 <= b[3] / b[4] <= 2.5 and b[0] >= 0.35 * b[3] * b[4]]
    pairs = []
    for i, p in enumerate(cands):
        for q in cands[i + 1:]:
            dx = abs(p[1] - q[1]); dy = abs(p[2] - q[2])
            if 0.08 * W <= dx <= 0.45 * W and dy <= 0.04 * H and max(p[0], q[0]) <= 3 * min(p[0], q[0]):
                pairs.append((p, q))
    if not pairs:
        return (0.5, 0.65)
    p, q = max(pairs, key=lambda pq: pq[0][2] + pq[1][2])
    return ((p[1] + q[1]) / 2 / W, (p[2] + q[2]) / 2 / H)

table = {}
for p in sorted(glob.glob(os.path.join(ASSETS, '*-3.imageset', '*@3x.png'))):
    name = os.path.basename(os.path.dirname(p)).replace('.imageset', '')
    cx, cy = OVERRIDES.get(name) or eyes(Image.open(p).convert('RGBA'))
    scale = SCALE.get(name.split('-')[0], DEFAULT_SCALE)
    # A looser crop lifts less, so the head stays in the upper part of the circle.
    lift = EYE_LIFT - (DEFAULT_SCALE - scale) * 0.04
    table[name] = [round(cx, 3), round(cy - lift, 3), scale]
    print(f"  {name:24s} {table[name]}")
with open(OUT, 'w') as f:
    json.dump(table, f, indent=1, sort_keys=True)
print(f"  portraits.json: {len(table)} stills")
