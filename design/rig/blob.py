"""The slime as a blob, not as a body with limbs bolted on.

A slime has no joints. An arm is a bulge that flows out of the body mass, and
the silhouette is ONE smooth curve at all times. So we build the character as
a distance field:

    body  = the approved torso, fully smooth, no limbs
    arms  = round-capped capsules
    shape = SMOOTH union of those fields

The smooth union puts a real fillet where an arm meets the body - the same soft
flare the drawn mitten has - and it is continuous by construction, so there is
no "join" to see. Then we trace the zero contour once and emit it as a single
closed path.
"""
import math, numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw

SS = 2                      # supersample factor for the field
AW, AH = 886, 795           # art space
PAD = 260                   # room for a raised arm
W, H = (AW + 2*PAD) * SS // 1, (AH + 2*PAD) * SS // 1

def _flat(segs, n=18):
    pts = []
    for s in segs:
        for i in range(n):
            t = i/n
            x = (1-t)**3*s[0]+3*(1-t)**2*t*s[2]+3*(1-t)*t*t*s[4]+t**3*s[6]
            y = (1-t)**3*s[1]+3*(1-t)**2*t*s[3]+3*(1-t)*t*t*s[5]+t**3*s[7]
            pts.append(((x+PAD)*SS, (y+PAD)*SS))
    return pts

def sdf_path(segs):
    """signed distance (art px) of a closed bezier path; negative inside"""
    im = Image.new("1", (W, H), 0)
    ImageDraw.Draw(im).polygon(_flat(segs), fill=1)
    m = np.asarray(im, dtype=bool)
    din = ndimage.distance_transform_edt(m)
    dout = ndimage.distance_transform_edt(~m)
    return (dout - din) / SS

_YY, _XX = np.mgrid[0:H, 0:W]
def sdf_capsule(a, b, ra, rb):
    """signed distance of a round-capped, linearly-tapered capsule"""
    ax, ay = (a[0]+PAD)*SS, (a[1]+PAD)*SS
    bx, by = (b[0]+PAD)*SS, (b[1]+PAD)*SS
    pax, pay = _XX-ax, _YY-ay
    bax, bay = bx-ax, by-ay
    L2 = bax*bax + bay*bay
    if L2 < 1e-6:
        return (np.sqrt(pax*pax+pay*pay)/SS) - ra
    h = np.clip((pax*bax + pay*bay)/L2, 0.0, 1.0)
    dx, dy = pax - bax*h, pay - bay*h
    r = (ra + (rb-ra)*h) * SS
    return (np.sqrt(dx*dx+dy*dy) - r) / SS

def smin(d1, d2, k):
    """polynomial smooth minimum - this is what makes the join disappear"""
    hh = np.clip(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0)
    return d2*(1-hh) + d1*hh - k*hh*(1-hh)

def contour(field, n_pts=200, smooth=6):
    """zero level set -> smoothed, resampled closed polyline in art coords"""
    m = field < 0
    lab, nlab = ndimage.label(m)
    if nlab > 1:
        sizes = ndimage.sum(m, lab, range(1, nlab+1))
        m = lab == (1 + int(np.argmax(sizes)))
    m = ndimage.binary_fill_holes(m)
    pts = _trace(m)
    for _ in range(smooth):                    # kill the pixel stair-steps
        pts = 0.5*pts + 0.25*np.roll(pts,1,0) + 0.25*np.roll(pts,-1,0)
    pts = _resample(pts, n_pts)
    return np.stack([pts[:,0]/SS - PAD, pts[:,1]/SS - PAD], 1)

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
    d = np.sqrt(((np.roll(poly,-1,0)-poly)**2).sum(1))
    cum = np.concatenate([[0], np.cumsum(d)])
    tot = cum[-1] or 1.0
    out, j = [], 0
    for t in np.linspace(0, tot, n, endpoint=False):
        while j < len(cum)-2 and cum[j+1] < t: j += 1
        f = (t-cum[j])/(d[j] or 1.0)
        out.append(poly[j]*(1-f) + poly[(j+1) % len(poly)]*f)
    return np.array(out)

def to_bezier(pts):
    n = len(pts); v=[]; o=[]; i_=[]
    for k in range(n):
        p, pv, nx = pts[k], pts[(k-1) % n], pts[(k+1) % n]
        tx, ty = (nx[0]-pv[0])/6.0, (nx[1]-pv[1])/6.0
        v.append([round(float(p[0]),1), round(float(p[1]),1)])
        o.append([round(float(tx),1), round(float(ty),1)])
        i_.append([round(float(-tx),1), round(float(-ty),1)])
    return {"c": True, "v": v, "o": o, "i": i_}
