"""Turn a distance field into a SMOOTH closed curve.

The old path was: threshold the field to a bitmap, walk the pixel boundary,
box-blur it a few times, drop 190 points on it and join them with Catmull-Rom
tangents. Every one of those steps injects ripple, and the result reads as a
faceted, lumpy outline rather than slime.

This does it properly:
  1  walk the bitmap boundary only to get the topology and a starting guess
  2  push every point onto the TRUE zero level along the field gradient, so the
     curve is sub-pixel instead of stair-stepped
  3  resample to uniform arc length at high density
  4  Gaussian-smooth in arc length (a real kernel, circular, not a box pass)
  5  drop the final control points and take tangents from the smooth curve
"""
import numpy as np
from scipy import ndimage
import field

def _resample(poly, n, start=0.0):
    d = np.sqrt(((np.roll(poly, -1, 0) - poly)**2).sum(1))
    cum = np.concatenate([[0.0], np.cumsum(d)])
    tot = cum[-1]
    t = (np.linspace(0.0, tot, n, endpoint=False) + start) % tot
    j = np.clip(np.searchsorted(cum, t, "right") - 1, 0, len(poly)-1)
    f = ((t - cum[j]) / np.where(d[j] == 0, 1.0, d[j]))[:, None]
    return poly[j]*(1-f) + poly[(j+1) % len(poly)]*f, tot

def _gauss_closed(poly, sigma_px, step):
    """circular Gaussian blur along arc length; sigma in the same units as step"""
    s = max(sigma_px/step, 1e-6)
    r = int(np.ceil(3*s))
    if r < 1:
        return poly
    k = np.exp(-0.5*(np.arange(-r, r+1)/s)**2); k /= k.sum()
    out = np.empty_like(poly)
    for a in (0, 1):
        out[:, a] = np.convolve(np.r_[poly[-r:, a], poly[:, a], poly[:r, a]],
                                k, "same")[r:-r]
    return out

def _bilinear(a, xy):
    x = np.clip(xy[:, 0], 0, a.shape[1]-1.001)
    y = np.clip(xy[:, 1], 0, a.shape[0]-1.001)
    x0 = x.astype(int); y0 = y.astype(int)
    fx = (x-x0)[:, None].ravel(); fy = (y-y0)[:, None].ravel()
    return (a[y0, x0]*(1-fx)*(1-fy) + a[y0, x0+1]*fx*(1-fy) +
            a[y0+1, x0]*(1-fx)*fy + a[y0+1, x0+1]*fx*fy)

def snap(d, pts_art, iters=3):
    """push points onto the field's zero level - this is what kills the stairs"""
    gy, gx = np.gradient(d)
    gx = gx*field.SS; gy = gy*field.SS          # per art px
    p = pts_art.copy()
    for _ in range(iters):
        g = np.stack([(p[:, 0]+field.PAD)*field.SS, (p[:, 1]+field.PAD)*field.SS], 1)
        v = _bilinear(d, g)
        ax = _bilinear(gx, g); ay = _bilinear(gy, g)
        n2 = ax*ax + ay*ay
        n2 = np.where(n2 < 1e-8, 1.0, n2)
        p[:, 0] -= v*ax/n2
        p[:, 1] -= v*ay/n2
    return p

def contour(d, n_pts=96, sigma=22.0, dense=1400):
    """field -> smooth closed curve in art coords, n_pts control points"""
    m = d < 0
    lab, nlab = ndimage.label(m)
    if nlab > 1:
        sizes = ndimage.sum(m, lab, range(1, nlab+1))
        m = lab == (1 + int(np.argmax(sizes)))
    m = ndimage.binary_fill_holes(m)
    raw = field._trace(m)                                    # (x, y) grid px
    poly = np.stack([raw[:, 0]/field.SS - field.PAD,
                     raw[:, 1]/field.SS - field.PAD], 1)
    poly, _ = _resample(poly, dense)
    poly = snap(d, poly)
    poly, per = _resample(poly, dense)
    poly = _gauss_closed(poly, sigma, per/dense)
    poly = snap(d, poly, iters=1)                            # re-seat, keep shape
    poly = _gauss_closed(poly, sigma*0.5, per/dense)
    # Start the control points at the SAME arc position every frame, to
    # sub-vertex precision. Rolling to the nearest existing vertex would let
    # the parameterisation crawl by up to one spacing between frames, which
    # shows up as a shimmer along the outline once Lottie tweens it.
    d2 = ((poly[:, 0]-field.ANCHOR[0])**2 + (poly[:, 1]-field.ANCHOR[1])**2)
    i0 = int(np.argmin(d2))
    seg = np.sqrt(((np.roll(poly, -1, 0) - poly)**2).sum(1))
    s0 = float(np.concatenate([[0.0], np.cumsum(seg)])[i0])
    out, _ = _resample(poly, n_pts, start=s0)
    return out, poly

def to_bezier(pts, dense=None, dp=2):
    """control points + tangents taken from the SMOOTH dense curve"""
    n = len(pts)
    v, o, i_ = [], [], []
    for k in range(n):
        p = pts[k]; pv = pts[(k-1) % n]; nx = pts[(k+1) % n]
        tx, ty = (nx[0]-pv[0])/6.0, (nx[1]-pv[1])/6.0
        v.append([round(float(p[0]), dp), round(float(p[1]), dp)])
        o.append([round(float(tx), dp), round(float(ty), dp)])
        i_.append([round(float(-tx), dp), round(float(-ty), dp)])
    return {"c": True, "v": v, "o": o, "i": i_}
