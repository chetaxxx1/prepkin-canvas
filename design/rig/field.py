"""The slime as one distance field. Rebuild, with a fixable underarm.

The character has no joints. An arm is a bulge in the body mass, so we never
draw an arm on top of a torso - we add its field to the torso's field, take the
SMOOTH union, and retrace the whole silhouette from the zero contour. A seam is
impossible because there are never two outlines to cross.

Three knobs exist purely to fix the underarm, which is the one place a plain
smooth union looks wrong (it leaves a hard white V under a raised arm):

  bend   the arm leaves the shoulder along the flank and curves up, instead of
         shooting straight out at the wave angle. Real goo does this.
  web    a thin strand of slime spanning the armpit, from the flank to the
         underside of the arm. It only exists when the arm is up.
  kboost the blend radius is a FIELD, not a number - bigger in the armpit only.

All three are zero at rest, so the rest pose stays the approved art.
"""
import math
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw

AW, AH = 886.0, 795.0            # art space
PAD = 210                        # headroom for a raised arm
SS = 2                           # field supersample
W = int((AW + 2*PAD) * SS)
H = int((AH + 2*PAD) * SS)
_YY, _XX = np.mgrid[0:H, 0:W].astype(np.float32)

def _flat(segs, n=20):
    pts = []
    for s in segs:
        for i in range(n):
            t = i / n
            x = (1-t)**3*s[0] + 3*(1-t)**2*t*s[2] + 3*(1-t)*t*t*s[4] + t**3*s[6]
            y = (1-t)**3*s[1] + 3*(1-t)**2*t*s[3] + 3*(1-t)*t*t*s[5] + t**3*s[7]
            pts.append(((x+PAD)*SS, (y+PAD)*SS))
    return pts

def mask_path(segs):
    im = Image.new("1", (W, H), 0)
    ImageDraw.Draw(im).polygon(_flat(segs), fill=1)
    return np.asarray(im, dtype=bool)

def sdf_path(segs):
    """signed distance in art px of a closed bezier path; negative inside"""
    m = mask_path(segs)
    din = ndimage.distance_transform_edt(m)
    dout = ndimage.distance_transform_edt(~m)
    return ((dout - din) / SS).astype(np.float32)

def _to_grid(p):
    return (p[0] + PAD) * SS, (p[1] + PAD) * SS

def sdf_capsule(a, b, ra, rb, out=None):
    """round-capped, linearly tapered capsule, in art px"""
    ax, ay = _to_grid(a); bx, by = _to_grid(b)
    pax = _XX - ax; pay = _YY - ay
    bax = bx - ax; bay = by - ay
    L2 = bax*bax + bay*bay
    if L2 < 1e-6:
        d = np.sqrt(pax*pax + pay*pay) / SS - ra
        return d.astype(np.float32)
    h = np.clip((pax*bax + pay*bay) / L2, 0.0, 1.0)
    dx = pax - bax*h; dy = pay - bay*h
    r = (ra + (rb-ra)*h) * SS
    return ((np.sqrt(dx*dx + dy*dy) - r) / SS).astype(np.float32)

def sdf_tube(pts, radii):
    """min over a chain of tapered capsules -> a smooth curved tube"""
    d = None
    for i in range(len(pts)-1):
        c = sdf_capsule(pts[i], pts[i+1], radii[i], radii[i+1])
        d = c if d is None else np.minimum(d, c, out=d)
    return d

def smin(d1, d2, k):
    """polynomial smooth minimum. k may be a scalar OR a field."""
    hh = np.clip(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0)
    return (d2*(1-hh) + d1*hh - k*hh*(1-hh)).astype(np.float32)

def gauss_bump(center, sigma, amp):
    """a localized field, for making the blend radius bigger in one spot"""
    cx, cy = _to_grid(center)
    r2 = ((_XX-cx)**2 + (_YY-cy)**2) / (SS*SS)
    return (amp * np.exp(-r2 / (2.0*sigma*sigma))).astype(np.float32)

# ---- arm centreline -------------------------------------------------------
def _unit(vx, vy):
    n = math.hypot(vx, vy) or 1.0
    return vx/n, vy/n

def arm_curve(shoulder, hand, rest_hand, bend, n=10):
    """centreline from shoulder to hand.

    bend=0 -> a straight line (the old build). bend=1 -> the arm leaves the
    shoulder along the REST direction (down the flank) and sweeps up to the
    hand, so its underside flows out of the body instead of cutting into it.
    """
    sx, sy = shoulder; hx, hy = hand
    L = math.hypot(hx-sx, hy-sy) or 1.0
    ux, uy = _unit(hx-sx, hy-sy)
    rx, ry = _unit(rest_hand[0]-shoulder[0], rest_hand[1]-shoulder[1])
    tx, ty = _unit(ux + (rx-ux)*bend, uy + (ry-uy)*bend)
    p1 = (sx + tx*L*0.48, sy + ty*L*0.48)
    p2 = (hx - ux*L*0.26, hy - uy*L*0.26)
    out = []
    for i in range(n+1):
        t = i/n
        a, b, c, d = (1-t)**3, 3*(1-t)**2*t, 3*(1-t)*t*t, t**3
        out.append((a*sx + b*p1[0] + c*p2[0] + d*hx,
                    a*sy + b*p1[1] + c*p2[1] + d*hy))
    return out

def taper(n, r0, r1, belly=0.0):
    """radii along the tube; belly>0 fattens the middle a little"""
    out = []
    for i in range(n+1):
        t = i/n
        out.append(r0 + (r1-r0)*t + belly*math.sin(math.pi*t))
    return out

# ---- contour --------------------------------------------------------------
def contour(field, n_pts=190, smooth=6):
    m = field < 0
    lab, nlab = ndimage.label(m)
    if nlab > 1:
        sizes = ndimage.sum(m, lab, range(1, nlab+1))
        m = lab == (1 + int(np.argmax(sizes)))
    m = ndimage.binary_fill_holes(m)
    pts = _trace(m)
    for _ in range(smooth):
        pts = 0.5*pts + 0.25*np.roll(pts, 1, 0) + 0.25*np.roll(pts, -1, 0)
    pts = _resample(pts, n_pts)
    out = np.stack([pts[:, 0]/SS - PAD, pts[:, 1]/SS - PAD], 1)
    return reindex(out)

def _trace(mask):
    m = np.pad(mask, 1)
    ys, xs = np.nonzero(m)
    sy = ys.min(); sx = xs[ys == sy].min()
    s = (sy, sx); back = (sy-1, sx)
    nbr = [(-1,0),(-1,1),(0,1),(1,1),(1,0),(1,-1),(0,-1),(-1,-1)]
    pts = [s]; c = s; first = None
    for _ in range(int(m.sum())*4):
        d = (back[0]-c[0], back[1]-c[1]); i0 = nbr.index(d); nxt = None
        for k in range(1, 9):
            i = (i0+k) % 8
            cand = (c[0]+nbr[i][0], c[1]+nbr[i][1])
            if m[cand]:
                nxt = cand; back = (c[0]+nbr[i-1][0], c[1]+nbr[i-1][1]); break
        if nxt is None: break
        if c == s and first is not None and nxt == first: break
        if first is None: first = nxt
        c = nxt
        if c == s: continue
        pts.append(c)
    return np.array([(x-1, y-1) for y, x in pts], dtype=float)

def _resample(poly, n):
    d = np.sqrt(((np.roll(poly, -1, 0) - poly)**2).sum(1))
    cum = np.concatenate([[0], np.cumsum(d)])
    tot = cum[-1] or 1.0
    out, j = [], 0
    for t in np.linspace(0, tot, n, endpoint=False):
        while j < len(cum)-2 and cum[j+1] < t: j += 1
        f = (t-cum[j]) / (d[j] or 1.0)
        out.append(poly[j]*(1-f) + poly[(j+1) % len(poly)]*f)
    return np.array(out)

def to_bezier(pts, dp=1):
    n = len(pts); v=[]; o=[]; i_=[]
    for k in range(n):
        p, pv, nx = pts[k], pts[(k-1) % n], pts[(k+1) % n]
        tx, ty = (nx[0]-pv[0])/6.0, (nx[1]-pv[1])/6.0
        v.append([round(float(p[0]), dp), round(float(p[1]), dp)])
        o.append([round(float(tx), dp), round(float(ty), dp)])
        i_.append([round(float(-tx), dp), round(float(-ty), dp)])
    return {"c": True, "v": v, "o": o, "i": i_}

def close_field(d, r):
    """Morphological closing of the shape by a ball of radius r (art px).

    Roll a ball of radius r around the OUTSIDE of the silhouette. Anywhere the
    ball cannot reach - the crease under a raised arm - fills in, and the fill
    meets both walls tangentially, so it is a true fillet, not a patch. Convex
    parts of the outline are mathematically untouched.
    """
    m = d <= r
    din = ndimage.distance_transform_edt(m)
    dout = ndimage.distance_transform_edt(~m)
    return (((dout - din) / SS) + r).astype(np.float32)

def band(y_lo, y_hi, soft=60.0):
    """1 inside the y band, easing to 0 outside - keeps the antenna out of it"""
    y = _YY / SS - PAD
    a = np.clip((y - y_lo) / soft, 0, 1)
    b = np.clip((y_hi - y) / soft, 0, 1)
    w = np.minimum(a*a*(3-2*a), b*b*(3-2*b))
    return w.astype(np.float32)

def half(x_split, side, soft=90.0):
    """1 on one side of the character, easing across the middle"""
    x = _XX / SS - PAD
    t = (x_split - x)/soft if side == "left" else (x - x_split)/soft
    t = np.clip(t, 0, 1)
    return (t*t*(3-2*t)).astype(np.float32)


ANCHOR = (443.0, 793.0)          # bottom centre - the calmest point on the body

def reindex(pts):
    """Always start the path at the same feature.

    The tracer starts wherever the topmost pixel is. If a raised arm ever gets
    higher than the antenna that start point jumps to a different part of the
    outline, and Lottie then tweens vertex 0 of one pose into vertex 0 of a
    completely different one - the animation tears. Anchoring the start to the
    bottom centre, which no pose moves, makes that impossible.
    """
    d = (pts[:, 0]-ANCHOR[0])**2 + (pts[:, 1]-ANCHOR[1])**2
    return np.roll(pts, -int(np.argmin(d)), axis=0)
