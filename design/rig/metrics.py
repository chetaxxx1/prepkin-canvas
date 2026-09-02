"""Measure the silhouette. Every past failure was caught here, not by looking."""
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
import field, art

AW, AH = field.AW, field.AH
MS = 1                                  # metric raster = 1 px per art px
MPAD = 260
MW, MH = int(AW + 2*MPAD), int(AH + 2*MPAD)

def raster(pts):
    """closed polyline in art coords -> bool mask in the metric raster"""
    im = Image.new("1", (MW, MH), 0)
    ImageDraw.Draw(im).polygon([(p[0]+MPAD, p[1]+MPAD) for p in pts], fill=1)
    return np.asarray(im, dtype=bool)

ART_MASK = field.mask_path(art.BODY)     # approved art, in the field raster

def art_xor(pts):
    """% of the approved character that differs from this silhouette"""
    im = Image.new("1", (field.W, field.H), 0)
    ImageDraw.Draw(im).polygon(
        [((p[0]+field.PAD)*field.SS, (p[1]+field.PAD)*field.SS) for p in pts], fill=1)
    m = np.asarray(im, dtype=bool)
    return 100.0 * (m ^ ART_MASK).sum() / ART_MASK.sum()

def topology(pts):
    m = raster(pts)
    _, ncomp = ndimage.label(m)
    holes = int(ndimage.binary_fill_holes(m).sum() - m.sum())
    ys, xs = np.nonzero(m)
    bbox = (float(xs.min()-MPAD), float(ys.min()-MPAD),
            float(xs.max()-MPAD), float(ys.max()-MPAD))
    return {"components": int(ncomp), "holes": holes, "bbox": bbox}

def side_concavity(pts, y_lo=210.0, y_hi=690.0, side="left"):
    """max inward dip of the side profile, px. Lower = smoother flank."""
    p = np.asarray(pts, float)
    cx = p[:, 0].mean()
    sel = (p[:, 1] > y_lo) & (p[:, 1] < y_hi)
    sel &= (p[:, 0] < cx) if side == "left" else (p[:, 0] > cx)
    idx = np.nonzero(sel)[0]
    if len(idx) < 8:
        return 0.0
    idx = idx[np.argsort(p[idx, 1])]
    q = p[idx]
    a, b, c = q[:-2], q[1:-1], q[2:]
    cross = (b[:,0]-a[:,0])*(c[:,1]-a[:,1]) - (b[:,1]-a[:,1])*(c[:,0]-a[:,0])
    dev = cross / (np.linalg.norm(c-a, axis=1) + 1e-6)
    dip = np.clip(dev, None, 0.0) if side == "left" else -np.clip(dev, 0.0, None)
    return float(-dip.min())

def _runs(row):
    d = np.diff(np.concatenate([[0], row.astype(np.int8), [0]]))
    return list(zip(np.nonzero(d == 1)[0], np.nonzero(d == -1)[0]))

def underarm(pts, y_lo=180.0, y_hi=700.0, x_hi=443.0):
    """The white wedge under a raised arm.

    Per row, the arm and the body are two separate inside-runs with white
    between them. Returns the worst gap width, the wedge area, and where.
    """
    m = raster(pts)
    worst, area, at = 0.0, 0, None
    for y in range(int(y_lo)+MPAD, int(y_hi)+MPAD):
        row = m[y, :int(x_hi)+MPAD]
        rr = _runs(row)
        if len(rr) < 2:
            continue
        for (a0, a1), (b0, b1) in zip(rr, rr[1:]):
            g = b0 - a1
            area += g
            if g > worst:
                worst, at = float(g), (float(a1-MPAD), float(y-MPAD))
    return {"gap_px": worst, "wedge_area": int(area), "at": at}

def report(pts, label=""):
    t = topology(pts)
    u = underarm(pts)
    r = {"label": label, **t,
         "concav_L": round(side_concavity(pts, side="left"), 1),
         "concav_R": round(side_concavity(pts, side="right"), 1),
         "gap_px": round(u["gap_px"], 1), "wedge_area": u["wedge_area"]}
    return r

def line(r):
    b = r["bbox"]
    return ("%-16s comp=%d holes=%d gap=%5.1f wedge=%6d concavL=%5.1f "
            "bbox=[%6.0f %6.0f %6.0f %6.0f]" % (
        r["label"], r["components"], r["holes"], r["gap_px"], r["wedge_area"],
        r["concav_L"], b[0], b[1], b[2], b[3]))

from scipy.spatial import ConvexHull

def notch(pts, x_hi=443.0, y_lo=150.0, y_hi=720.0):
    """The armpit pocket, measured as a dent in the convex hull.

    Works whether or not the wedge is a full through-gap, so a webbed underarm
    and an open one are scored on the same scale.
      area  px^2 of the pocket
      depth px from the pocket's mouth to its deepest point  <- the V-ness
      mouth px of the widest opening
    """
    m = raster(pts)
    ys, xs = np.nonzero(m)
    hull = ConvexHull(np.stack([xs, ys], 1))
    poly = [(float(xs[i]), float(ys[i])) for i in hull.vertices]
    im = Image.new("1", (MW, MH), 0)
    ImageDraw.Draw(im).polygon(poly, fill=1)
    hm = np.asarray(im, dtype=bool)
    dfc = hm & ~m
    lab, n = ndimage.label(dfc)
    best = {"area": 0, "depth": 0.0, "mouth": 0.0, "at": None}
    if n == 0:
        return best
    edt = ndimage.distance_transform_edt(dfc)
    for i in range(1, n+1):
        sel = lab == i
        cy, cx = ndimage.center_of_mass(sel)
        if cx - MPAD > x_hi or not (y_lo < cy - MPAD < y_hi):
            continue
        a = int(sel.sum())
        if a < 60:
            continue
        if a > best["area"]:
            rows = np.nonzero(sel.any(1))[0]
            mouth = max(int(sel[y].sum()) for y in rows)
            best = {"area": a, "depth": round(float(edt[sel].max())*2, 1),
                    "mouth": float(mouth), "at": (round(cx-MPAD,1), round(cy-MPAD,1))}
    return best

def slot(pts, y_lo=120.0, y_hi=720.0, x_hi=443.0):
    """The gap between a raised arm and the body, row by row.

    The reference clip keeps a NARROW, even slot there. A wedge that opens out
    to 80px reads as a hard V; a 25-45px slot of near constant width reads as
    an arm held away from the body. So we score evenness, not just size.
    """
    m = raster(pts)
    ws = []
    for y in range(int(y_lo)+MPAD, int(y_hi)+MPAD):
        rr = _runs(m[y, :int(x_hi)+MPAD])
        if len(rr) < 2:
            continue
        ws.append(max(b0-a1 for (a0, a1), (b0, b1) in zip(rr, rr[1:])))
    if not ws:
        return {"rows": 0, "max": 0.0, "med": 0.0, "spread": 0.0}
    a = np.array(ws, float)
    return {"rows": len(ws), "max": float(a.max()),
            "med": float(np.median(a)), "spread": float(a.max()-np.median(a))}

def fillet_radius(pts, x_hi=443.0, y_lo=150.0, y_hi=740.0, hi=200.0):
    """The largest ball that can roll INTO every crease on the arm side.

    This is the direct answer to "is the underarm a hard V or a soft scoop".
    A sharp corner admits only a small ball; a gooey fillet admits a big one.
    Returned in art px (the character is 886 wide).
    """
    m = raster(pts)
    reg = np.zeros_like(m)
    reg[int(y_lo)+MPAD:int(y_hi)+MPAD, :int(x_hi)+MPAD] = True
    lo = 0.0
    r = hi
    for _ in range(7):
        mid = (lo+r)/2
        dout = ndimage.distance_transform_edt(~m)
        dil = dout <= mid
        sd = ndimage.distance_transform_edt(~dil) - ndimage.distance_transform_edt(dil)
        added = (sd + mid <= 0) & ~m & reg
        if added.sum() > 150:
            r = mid
        else:
            lo = mid
    return round(lo, 1)

def neck(pts, hi=90.0):
    """Narrowest bridge in the shape, in art px.

    Where the arm joins the body there is a neck. If it gets too thin the
    silhouette is one pinch away from splitting - and Lottie tweening between
    two frames that both look fine can still cross the outline through a thin
    neck and punch the shape into pieces. So this is a hard floor, not taste.
    """
    m = raster(pts)
    lo, r = 0.0, hi
    for _ in range(8):
        mid = (lo+r)/2
        er = ndimage.binary_erosion(m, ndimage.generate_binary_structure(2, 1),
                                    iterations=max(1, int(round(mid))))
        _, n = ndimage.label(er)
        if n != 1:
            r = mid
        else:
            lo = mid
    return round(lo*2, 1)
