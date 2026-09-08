#!/usr/bin/env python3
"""Find type that has been laid over a drawn shape, by looking at the pixels.

    python3 textcheck.py <probe dir> [figure ...]

The renderer draws every figure twice: whole, and with every word switched off. The
pixels that differ are exactly the glyphs. Sampling the wordless image underneath each
word says what that word is sitting on:

  one flat colour   the word is inside a shape, or on the open field. Fine.
  two or more       the word straddles an edge — a person's outline, the seam between
                    two shapes. That is the "ONE over the person's head" bug, and no
                    amount of comparing text boxes against other text boxes catches it.

Also reports words that leave the safe box, and words that clear a shape by less than
a couple of points, which read as a collision even when the pixels do not touch.
"""
import sys, os, glob, collections
import numpy as np
from scipy import ndimage
from PIL import Image

SAFE = (16, 344, 14, 286)      # figure points
SCALE = 2                      # the renderer writes at 2x
NEAR = 3.0                     # points of clearance below which a word looks stuck on


def surfaces(px, floor=0.06, tol=12):
    """The distinct flat fills in a block of pixels, biggest first.

    Colours are clustered by distance rather than dropped into fixed buckets: a flat
    fill comes back from the renderer with a point or two of dither, and a bucket edge
    would split one surface into two and report a collision that is not there.
    """
    px = px.reshape(-1, 3)
    vals, counts = np.unique(px, axis=0, return_counts=True)
    order = np.argsort(-counts)
    centres, weight = [], []
    for i in order:
        c, n = vals[i].astype(np.int32), int(counts[i])
        for k, m in enumerate(centres):
            if np.abs(m - c).sum() <= tol:
                weight[k] += n
                break
        else:
            centres.append(c)
            weight.append(n)
    total = sum(weight)
    return sorted((w / total for w in weight if w / total >= floor), reverse=True)


def words_in(mask, gap=7):
    """Glyphs glued into words: dilate along x, label, then take each blob's box."""
    grown = ndimage.binary_dilation(mask, np.ones((3, gap * 2 + 1), bool))
    lab, n = ndimage.label(grown)
    out = []
    for sl in ndimage.find_objects(lab):
        sub = mask[sl]
        # A real word is at least six points tall. Anything flatter is either a
        # hairline of antialiasing that moved by a subpixel between the two renders,
        # or the sliver of a word left above and below a strike-through — and a word
        # crossed by a strike on purpose is not the bug this is looking for.
        if sub.sum() < 30 or (sl[0].stop - sl[0].start) < 12:
            continue
        ys, xs = np.nonzero(sub)
        out.append((sl[1].start + xs.min(), sl[0].start + ys.min(),
                    sl[1].start + xs.max(), sl[0].start + ys.max(), sl, sub))
    return out


def check(full_path, bare_path):
    full = np.asarray(Image.open(full_path).convert('RGB')).astype(np.int16)
    bare = np.asarray(Image.open(bare_path).convert('RGB')).astype(np.int16)
    if full.shape != bare.shape:
        return []
    glyphs = np.abs(full - bare).sum(2) > 60
    if not glyphs.any():
        return []
    found = []
    for x0, y0, x1, y1, sl, sub in words_in(glyphs):
        pts = (x0 / SCALE, y0 / SCALE, x1 / SCALE, y1 / SCALE)
        shares = surfaces(bare[sl][sub])
        if len(shares) > 1:
            pct = ', '.join(f'{v * 100:.0f}%' for v in shares)
            found.append(('OVERLAP', pts, f'{len(shares)} surfaces under the word ({pct})'))
        elif NEAR > 0:
            # nothing under it, but is it nearly touching something?
            pad = int(NEAR * SCALE)
            ys0, ys1 = max(0, y0 - pad), min(bare.shape[0], y1 + pad + 1)
            xs0, xs1 = max(0, x0 - pad), min(bare.shape[1], x1 + pad + 1)
            if len(surfaces(bare[ys0:ys1, xs0:xs1].reshape(-1, 3), floor=0.02)) > 1:
                found.append(('NEAR', pts, f'clears the nearest shape by under {NEAR:.0f}pt'))
        if (pts[0] < SAFE[0] - 0.5 or pts[2] > SAFE[1] + 0.5
                or pts[1] < SAFE[2] - 0.5 or pts[3] > SAFE[3] + 0.5):
            found.append(('OUTSIDE', pts, 'word leaves the safe box'))
    return found


if __name__ == '__main__':
    d = sys.argv[1]
    only = set(sys.argv[2:])
    per = collections.defaultdict(list)
    for full in sorted(glob.glob(os.path.join(d, '*.png'))):
        if full.endswith('-notext.png'):
            continue
        bare = full[:-4] + '-notext.png'
        if not os.path.exists(bare):
            continue
        fig, step = os.path.basename(full)[:-4].rsplit('-', 1)
        if only and fig not in only:
            continue
        for kind, box, why in check(full, bare):
            per[fig].append((int(step), kind, box, why))
    total = 0
    for fig in sorted(per):
        seen, rows = set(), []
        for step, kind, box, why in sorted(per[fig]):
            key = (kind, round(box[0] / 4), round(box[1] / 4))
            if key in seen:
                continue
            seen.add(key)
            rows.append((step, kind, box, why))
        if rows:
            print(fig)
            for step, kind, box, why in rows:
                print(f'  {kind:8} step {step}  x {box[0]:.0f}..{box[2]:.0f} '
                      f'y {box[1]:.0f}..{box[3]:.0f}  {why}')
                total += 1
    print(f'\n{total} findings')
