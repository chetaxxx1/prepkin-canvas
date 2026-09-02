"""Same measurement, both builds, on the RENDERED frames.

Everything is scaled to the character's own height so the two canvases are
comparable. The headline number is the fillet radius: the biggest ball that can
roll into the underarm crease. A hard V admits a tiny ball; gooey slime admits
a big one.
"""
import glob, numpy as np
from PIL import Image
from scipy import ndimage

def mask_of(fp):
    a = np.asarray(Image.open(fp).convert("RGB")).astype(int)
    return a.sum(2) < 720

def char_h(m):
    ys = np.nonzero(m.any(1))[0]
    return ys.max()-ys.min()+1

def row_gap(m, scale):
    """widest white gap between the arm run and the body run, in art px"""
    h, w = m.shape
    worst = 0
    for y in range(int(h*0.15), int(h*0.92)):
        row = m[y, :w//2]
        d = np.diff(np.concatenate([[0], row.astype(np.int8), [0]]))
        st, en = np.nonzero(d == 1)[0], np.nonzero(d == -1)[0]
        for a, b in zip(en[:-1], st[1:]):
            worst = max(worst, b-a)
    return worst*scale

def fillet_r(m, scale, hi=90.0):
    """largest ball that rolls into any crease on the waving side, in art px"""
    reg = np.zeros_like(m); h, w = m.shape
    reg[int(h*0.15):int(h*0.94), :w//2] = True
    lo, r = 0.0, hi
    for _ in range(8):
        mid = (lo+r)/2
        dout = ndimage.distance_transform_edt(~m)
        dil = dout <= mid
        sd = ndimage.distance_transform_edt(~dil) - ndimage.distance_transform_edt(dil)
        if (((sd+mid) <= 0) & ~m & reg).sum() > 40: r = mid
        else: lo = mid
    return lo*scale

def run(tag, pat, ref_h=795.0):
    files = sorted(glob.glob(pat))
    gaps, fils = [], []
    for fp in files:
        m = mask_of(fp)
        sc = ref_h/char_h(m)
        gaps.append(row_gap(m, sc)); fils.append(fillet_r(m, sc))
    g, f = np.array(gaps), np.array(fils)
    act = f[(g > 5) | (np.arange(len(f)) > 15)]
    print("%-10s underarm gap: max %5.1f  mean %5.1f  |  fillet radius: min %5.1f "
          "median %5.1f  (art px, character 795 tall)"
          % (tag, g.max(), g.mean(), f.min(), np.median(f)))
    return g, f

if __name__ == "__main__":
    run("OLD", "old_f/*.png")
    run("NEW", "wave_f/*.png")
