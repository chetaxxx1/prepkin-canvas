"""Raster diagnostic straight off the mask - no Chrome, no lottie, no guessing."""
import sys, math
import numpy as np
from PIL import Image, ImageDraw
import field, rig, metrics
from smooth_torso import TORSO

SS, PAD = field.SS, field.PAD
def g(p): return ((p[0]+PAD)*SS, (p[1]+PAD)*SS)

def frame(deg, reach, P, note=""):
    P = dict(rig.P0, **(P or {}))
    sh, rest = rig.SH_L, rig.REST_L
    hand = rig.swing(sh, rest, deg, reach)
    pts = rig.silhouette(degL=deg, reachL=reach, degR=-0.16*deg, P=P)
    im = Image.new("RGB", (field.W, field.H), (255,255,255))
    d = ImageDraw.Draw(im)
    d.polygon([g(p) for p in pts], fill=(81,207,160))
    # torso and arm outlines on top, so we can see where each piece sits
    d.line([g((x,y)) for x,y in _outline(field.mask_path(TORSO))], fill=(0,0,180), width=3)
    d.line([g(sh), g(hand)], fill=(220,0,0), width=5)
    d.ellipse([*g((sh[0]-rig.R_SH, sh[1]-rig.R_SH)), *g((sh[0]+rig.R_SH, sh[1]+rig.R_SH))],
              outline=(220,0,0), width=3)
    ua = rig._u(hand[0]-sh[0], hand[1]-sh[1]); uf = rig._u(rest[0]-sh[0], rest[1]-sh[1])
    ub = rig._u(ua[0]+uf[0], ua[1]+uf[1])
    L = min(math.hypot(hand[0]-sh[0], hand[1]-sh[1]), 250.0)
    d.line([g(sh), g((sh[0]+ub[0]*L, sh[1]+ub[1]*L))], fill=(255,140,0), width=5)
    n = metrics.notch(pts)
    if n["at"]:
        cx, cy = n["at"]
        d.ellipse([*g((cx-14, cy-14)), *g((cx+14, cy+14))], fill=(255,0,0))
    return im.resize((field.W//4, field.H//4)), n

def _outline(m):
    from scipy import ndimage
    b = m ^ ndimage.binary_erosion(m)
    ys, xs = np.nonzero(b)
    o = np.stack([xs/SS-PAD, ys/SS-PAD], 1)
    c = o.mean(0); a = np.arctan2(o[:,1]-c[1], o[:,0]-c[0])
    o = o[np.argsort(a)][::12]
    return [tuple(p) for p in o] + [tuple(o[0])]

if __name__ == "__main__":
    CASES = [(0,1.0,{}), (45,1.25,{}), (70,1.25,{}), (95,1.25,{}), (120,1.25,{})]
    ims = []
    for dg, rc, P in CASES:
        im, n = frame(dg, rc, P)
        ims.append(im)
        print("deg=%3d notch area=%6d depth=%5.1f mouth=%5.1f at=%s" % (
            dg, n["area"], n["depth"], n["mouth"], n["at"]))
    w, h = ims[0].size
    sheet = Image.new("RGB", (w*len(ims), h), (255,255,255))
    for i, im in enumerate(ims): sheet.paste(im, (i*w, 0))
    sheet.save("diag_base.png")
    print("wrote diag_base.png", sheet.size)
