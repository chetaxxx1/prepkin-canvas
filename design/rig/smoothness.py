"""How smooth is the outline, as a number.

A slime silhouette is a few long, evenly-curving arcs. A lumpy one has many
curvature sign flips and spikes. Both are measured on the curve Lottie will
actually draw - the emitted beziers, sampled densely - not on the field.
"""
import numpy as np

def sample_bezier(bz, per_seg=24):
    v = np.array(bz["v"], float); o = np.array(bz["o"], float); i = np.array(bz["i"], float)
    n = len(v); out = []
    for k in range(n):
        p0 = v[k]; p3 = v[(k+1) % n]
        p1 = p0 + o[k]; p2 = p3 + i[(k+1) % n]
        t = np.linspace(0, 1, per_seg, endpoint=False)[:, None]
        out.append((1-t)**3*p0 + 3*(1-t)**2*t*p1 + 3*(1-t)*t*t*p2 + t**3*p3)
    return np.concatenate(out)

def curvature(p, win=9):
    q = p
    a = np.roll(q, win, 0); b = q; c = np.roll(q, -win, 0)
    v1 = b-a; v2 = c-b
    cr = v1[:, 0]*v2[:, 1] - v1[:, 1]*v2[:, 0]
    l1 = np.linalg.norm(v1, axis=1); l2 = np.linalg.norm(v2, axis=1)
    lc = np.linalg.norm(c-a, axis=1)
    den = (l1*l2*lc)
    return np.where(den > 1e-9, 2*cr/np.maximum(den, 1e-9), 0.0)

def score(bz):
    p = sample_bezier(bz)
    k = curvature(p)
    ks = np.convolve(np.r_[k[-6:], k, k[:6]], np.ones(13)/13, "same")[6:-6]
    flips = int((np.diff(np.sign(ks)) != 0).sum())
    rmin = 1.0/max(abs(ks).max(), 1e-9)
    step = np.linalg.norm(np.diff(p, axis=0, append=p[:1]), axis=1)
    per = step.sum()
    ripple = float(np.abs(np.diff(ks, append=ks[:1])).sum() * per / (2*np.pi))
    return {"inflections": flips, "min_radius": round(float(rmin), 1),
            "ripple": round(ripple, 1), "perimeter": round(float(per))}

def score2(bz):
    """same, but split by sign: a slime needs no tight CONCAVE corners"""
    p = sample_bezier(bz); k = curvature(p)
    ks = np.convolve(np.r_[k[-6:], k, k[:6]], np.ones(13)/13, "same")[6:-6]
    cvx = ks[ks > 0]; ccv = ks[ks < 0]
    r = score(bz)
    r["min_r_convex"] = round(float(1.0/max(cvx.max(), 1e-9)), 1) if len(cvx) else None
    r["min_r_concave"] = round(float(1.0/max(-ccv.min(), 1e-9)), 1) if len(ccv) else None
    return r

def score3(bz, y_min=200.0):
    """Ignore the antenna. Its base is a sharp concave junction in the approved
    art and must stay sharp, so it would otherwise mask the body's own numbers."""
    p = sample_bezier(bz); k = curvature(p)
    ks = np.convolve(np.r_[k[-6:], k, k[:6]], np.ones(13)/13, "same")[6:-6]
    sel = p[:, 1] > y_min
    kb = ks[sel]
    cvx = kb[kb > 0]; ccv = kb[kb < 0]
    flips = int((np.diff(np.sign(kb)) != 0).sum())
    return {"inflections_body": flips,
            "min_r_convex": round(float(1/max(cvx.max(), 1e-9)), 1) if len(cvx) else None,
            "min_r_concave": round(float(1/max(-ccv.min(), 1e-9)), 1) if len(ccv) else None,
            "ripple_body": round(float(np.abs(np.diff(kb)).sum()*len(kb)), 1)}
