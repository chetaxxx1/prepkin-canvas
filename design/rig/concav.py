"""Measure how concave the SIDES of the silhouette are.

A "base" where an arm attaches shows up as a concave dip on the side profile.
For a wholly smooth side there must be no inward curvature between the head and
the bottom flare. This scores exactly that, so tuning is measured, not guessed.
"""
import numpy as np

def side_concavity(pts, y_lo=210.0, y_hi=690.0, side="left"):
    """pts: Nx2 closed contour, art coords. Returns (max_dip_px, mean_dip)."""
    p = np.asarray(pts, float)
    # keep the points on the requested side within the y band
    cx = p[:, 0].mean()
    sel = (p[:, 1] > y_lo) & (p[:, 1] < y_hi)
    sel &= (p[:, 0] < cx) if side == "left" else (p[:, 0] > cx)
    idx = np.nonzero(sel)[0]
    if len(idx) < 8:
        return 0.0, 0.0
    # walk the contiguous run
    idx = idx[np.argsort(p[idx, 1])]
    q = p[idx]
    # signed area of each triple: negative => concave for a left-side profile
    a, b, c = q[:-2], q[1:-1], q[2:]
    cross = (b[:,0]-a[:,0])*(c[:,1]-a[:,1]) - (b[:,1]-a[:,1])*(c[:,0]-a[:,0])
    seglen = np.linalg.norm(c-a, axis=1) + 1e-6
    dev = cross / seglen                     # perpendicular deviation, px
    if side == "left":
        dip = np.clip(dev, None, 0.0)        # inward = negative
    else:
        dip = -np.clip(dev, 0.0, None)
    return float(-dip.min()), float(-dip.mean())
