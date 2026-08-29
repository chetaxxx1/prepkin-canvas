#!/usr/bin/env python3
"""Trace the slime mascot renders into bezier paths for SwiftUI.

Outputs normalized (unit-square over the full-character bbox) bezier segments
for: body silhouette (green, one path incl. antenna+arms), belly, and each
ink face element per expression.
"""
import json
import numpy as np
from PIL import Image

HANDOFF = "/Users/georgeshi/Desktop/mascot/slime-handoff"

BODY = (0x51, 0xCF, 0xA0)
BELLY = (0xB1, 0xED, 0xD4)
INK = (0x10, 0x18, 0x20)


def load(path):
    return np.array(Image.open(path).convert("RGBA"), dtype=np.int16)


def color_mask(a, rgb, tol=60):
    d = np.abs(a[..., :3] - np.array(rgb)).sum(axis=2)
    m = d < tol
    if a.shape[2] == 4:
        m &= a[..., 3] > 128
    return m


# ---------- connected components (4-conn) ----------
def components(mask):
    from scipy import ndimage
    lab, n = ndimage.label(mask)
    return lab, n


# ---------- Moore boundary tracing ----------
def trace_boundary(mask):
    """Return outer boundary of the largest component as Nx2 float array (x, y)."""
    from scipy import ndimage
    lab, n = ndimage.label(mask)
    if n == 0:
        return None
    sizes = ndimage.sum(mask, lab, range(1, n + 1))
    biggest = 1 + int(np.argmax(sizes))
    m = lab == biggest
    # pad to avoid edge issues
    mp = np.pad(m, 1)
    ys, xs = np.nonzero(mp)
    start = (ys[0], xs[0])  # topmost-leftmost pixel
    # Moore neighbor tracing, clockwise
    nbrs = [(-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1)]
    boundary = [start]
    prev_dir = 6  # came from the left-ish
    cur = start
    while True:
        found = False
        for i in range(8):
            d = (prev_dir + 1 + i) % 8
            ny, nx = cur[0] + nbrs[d][0], cur[1] + nbrs[d][1]
            if mp[ny, nx]:
                boundary.append((ny, nx))
                prev_dir = (d + 4) % 8
                cur = (ny, nx)
                found = True
                break
        if not found:
            break  # isolated pixel
        if len(boundary) > 2 and cur == start:
            break
        if len(boundary) > 200000:
            raise RuntimeError("boundary runaway")
    b = np.array(boundary[:-1], dtype=float)
    # back to unpadded coords, as (x, y)
    return np.stack([b[:, 1] - 1, b[:, 0] - 1], axis=1)


def smooth_closed(pts, sigma=3.0):
    from scipy import ndimage
    out = np.empty_like(pts)
    for k in range(2):
        out[:, k] = ndimage.gaussian_filter1d(pts[:, k], sigma, mode="wrap")
    return out


def resample_closed(pts, n=400):
    d = np.sqrt(((np.roll(pts, -1, axis=0) - pts) ** 2).sum(axis=1))
    s = np.concatenate([[0], np.cumsum(d)])
    total = s[-1]
    t = np.linspace(0, total, n, endpoint=False)
    xs = np.interp(t, s, np.concatenate([pts[:, 0], [pts[0, 0]]]))
    ys = np.interp(t, s, np.concatenate([pts[:, 1], [pts[0, 1]]]))
    return np.stack([xs, ys], axis=1)


# ---------- Schneider bezier fitting ----------
def fit_cubic(points, max_error):
    """Fit closed polyline with cubic beziers. points: Nx2, first point is start.
    Returns list of [p0, c1, c2, p3]."""

    def q(ctrl, t):
        mt = 1 - t
        return (mt ** 3)[:, None] * ctrl[0] + 3 * (mt ** 2 * t)[:, None] * ctrl[1] \
            + 3 * (mt * t ** 2)[:, None] * ctrl[2] + (t ** 3)[:, None] * ctrl[3]

    def chord_params(pts):
        d = np.sqrt(((pts[1:] - pts[:-1]) ** 2).sum(axis=1))
        u = np.concatenate([[0], np.cumsum(d)])
        return u / u[-1]

    def generate(pts, u, tan1, tan2):
        n = len(pts)
        A = np.zeros((n, 2, 2))
        A[:, 0] = tan1 * (3 * (1 - u) ** 2 * u)[:, None]
        A[:, 1] = tan2 * (3 * (1 - u) * u ** 2)[:, None]
        C = np.zeros((2, 2))
        X = np.zeros(2)
        mt = 1 - u
        b0 = mt ** 3
        b1 = 3 * mt ** 2 * u
        b2 = 3 * mt * u ** 2
        b3 = u ** 3
        tmp = pts - (b0 + b1)[:, None] * pts[0] - (b2 + b3)[:, None] * pts[-1]
        C[0, 0] = (A[:, 0] * A[:, 0]).sum()
        C[0, 1] = C[1, 0] = (A[:, 0] * A[:, 1]).sum()
        C[1, 1] = (A[:, 1] * A[:, 1]).sum()
        X[0] = (A[:, 0] * tmp).sum()
        X[1] = (A[:, 1] * tmp).sum()
        det = C[0, 0] * C[1, 1] - C[0, 1] * C[1, 0]
        if abs(det) > 1e-12:
            a1 = (X[0] * C[1, 1] - X[1] * C[0, 1]) / det
            a2 = (C[0, 0] * X[1] - C[1, 0] * X[0]) / det
        else:
            a1 = a2 = 0
        seglen = np.linalg.norm(pts[-1] - pts[0])
        eps = 1e-6 * seglen
        if a1 < eps or a2 < eps:
            a1 = a2 = seglen / 3
        return np.array([pts[0], pts[0] + tan1 * a1, pts[-1] + tan2 * a2, pts[-1]])

    def max_err(pts, ctrl, u):
        pt = q(ctrl, u)
        d2 = ((pt - pts) ** 2).sum(axis=1)
        i = int(np.argmax(d2))
        return np.sqrt(d2[i]), i

    def reparam(pts, ctrl, u):
        # one Newton-Raphson step
        def qprime(t):
            mt = 1 - t
            return 3 * (mt ** 2)[:, None] * (ctrl[1] - ctrl[0]) + \
                6 * (mt * t)[:, None] * (ctrl[2] - ctrl[1]) + 3 * (t ** 2)[:, None] * (ctrl[3] - ctrl[2])

        def qpp(t):
            mt = 1 - t
            return 6 * mt[:, None] * (ctrl[2] - 2 * ctrl[1] + ctrl[0]) + \
                6 * t[:, None] * (ctrl[3] - 2 * ctrl[2] + ctrl[1])

        d = q(ctrl, u) - pts
        d1 = qprime(u)
        d2 = qpp(u)
        num = (d * d1).sum(axis=1)
        den = (d1 * d1).sum(axis=1) + (d * d2).sum(axis=1)
        un = np.where(np.abs(den) > 1e-12, u - num / den, u)
        return np.clip(un, 0, 1)

    def rec(pts, tan1, tan2, depth=0):
        if len(pts) == 2:
            seglen = np.linalg.norm(pts[1] - pts[0]) / 3
            return [np.array([pts[0], pts[0] + tan1 * seglen, pts[1] + tan2 * seglen, pts[1]])]
        u = chord_params(pts)
        ctrl = generate(pts, u, tan1, tan2)
        err, split = max_err(pts, ctrl, u)
        if err < max_error:
            return [ctrl]
        if err < max_error * 4:
            for _ in range(4):
                u = reparam(pts, ctrl, u)
                ctrl = generate(pts, u, tan1, tan2)
                err, split = max_err(pts, ctrl, u)
                if err < max_error:
                    return [ctrl]
        split = max(1, min(len(pts) - 2, split))
        center_tan = pts[split - 1] - pts[split + 1]
        n = np.linalg.norm(center_tan)
        center_tan = center_tan / n if n > 1e-12 else np.array([1.0, 0])
        left = rec(pts[: split + 1], tan1, center_tan, depth + 1)
        right = rec(pts[split:], -center_tan, tan2, depth + 1)
        return left + right

    pts = points
    t1 = pts[1] - pts[0]
    t1 = t1 / np.linalg.norm(t1)
    t2 = pts[-2] - pts[-1]
    t2 = t2 / np.linalg.norm(t2)
    return rec(pts, t1, t2)


def fit_closed(pts_closed, max_error, corner_idx=None):
    """Fit a closed contour. Optionally split at given index (sharpest corner)
    so start tangents don't smooth over a real corner. Start at top point."""
    # rotate so start is at the point of max curvature or top-most
    if corner_idx is None:
        corner_idx = int(np.argmin(pts_closed[:, 1]))
    pts = np.roll(pts_closed, -corner_idx, axis=0)
    pts = np.concatenate([pts, pts[:1]], axis=0)
    return fit_cubic(pts, max_error)


def bbox_of(mask):
    ys, xs = np.nonzero(mask)
    return xs.min(), ys.min(), xs.max() + 1, ys.max() + 1  # x0,y0,x1,y1


def norm_segs(segs, box):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    out = []
    for s in segs:
        out.append([[(p[0] - x0) / w, (p[1] - y0) / h] for p in s])
    return out


def trace_shape(mask, box, max_error=1.2, sigma=3.0, n=400):
    b = trace_boundary(mask)
    b = smooth_closed(b, sigma)
    b = resample_closed(b, n)
    segs = fit_closed(b, max_error)
    return norm_segs(segs, box)


def ink_components(a, box, min_area=30):
    """Return list of dicts for each ink component: bbox-normalized info."""
    from scipy import ndimage
    m = color_mask(a, INK, tol=90)
    lab, n = ndimage.label(m)
    out = []
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    for i in range(1, n + 1):
        comp = lab == i
        area = comp.sum()
        if area < min_area:
            continue
        ys, xs = np.nonzero(comp)
        cx, cy = xs.mean(), ys.mean()
        bw = xs.max() - xs.min() + 1
        bh = ys.max() - ys.min() + 1
        fill = area / (bw * bh)
        out.append(dict(mask=comp, area=int(area),
                        cx=(cx - x0) / w, cy=(cy - y0) / h,
                        bw=bw / w, bh=bh / h, fill=round(float(fill), 3),
                        px_bbox=(xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)))
    out.sort(key=lambda d: d["cx"])
    return out


def main():
    a = load(f"{HANDOFF}/mascot-idle.png")
    green = color_mask(a, BODY)
    belly = color_mask(a, BELLY)
    sil = green | belly  # ink sits on top of body -> include ink too
    ink = color_mask(a, INK, tol=90)
    sil = sil | ink
    box = bbox_of(sil)
    x0, y0, x1, y1 = box
    W, H = x1 - x0, y1 - y0
    print(f"image {a.shape[1]}x{a.shape[0]}  char bbox: x{x0}-{x1} y{y0}-{y1}  W={W} H={H} aspect W/H={W/H:.4f}")

    # body silhouette (whole green incl arms/antenna + interior)
    from scipy import ndimage
    filled = ndimage.binary_fill_holes(sil)
    body_segs = trace_shape(filled, box, max_error=1.0, sigma=2.5, n=700)
    print(f"body: {len(body_segs)} bezier segs")

    belly_segs = trace_shape(belly, box, max_error=0.8, sigma=2.5, n=200)
    bb = bbox_of(belly)
    print(f"belly: {len(belly_segs)} segs, bbox norm x {(bb[0]-x0)/W:.4f}-{(bb[2]-x0)/W:.4f} y {(bb[1]-y0)/H:.4f}-{(bb[3]-y0)/H:.4f}")

    comps = ink_components(a, box)
    face = {}
    for c in comps:
        print(f"ink comp: c=({c['cx']:.4f},{c['cy']:.4f}) bw={c['bw']:.4f} bh={c['bh']:.4f} fill={c['fill']}")
    face["idle"] = [dict(cx=c["cx"], cy=c["cy"], bw=c["bw"], bh=c["bh"], fill=c["fill"],
                         segs=trace_shape(c["mask"], box, max_error=0.6, sigma=1.5, n=150))
                    for c in comps]

    result = dict(aspect=W / H, body=body_segs, belly=belly_segs, idle_face=face["idle"])

    # ---- expressions sheet ----
    e = load(f"{HANDOFF}/approved-expressions.png")
    eg = color_mask(e, BODY)
    lab, n = components(eg)
    sizes = ndimage.sum(eg, lab, range(1, n + 1))
    order = np.argsort(-sizes)[:4] + 1
    panels = []
    for i in order:
        m = lab == i
        panels.append(m)
    # sort panels left->right
    panels.sort(key=lambda m: np.nonzero(m)[1].mean())
    names = ["idle", "deadpan", "judging", "delight"]
    expr = {}
    for name, pm in zip(names, panels):
        pb = bbox_of(pm)
        px0, py0, px1, py1 = pb
        pw, ph = px1 - px0, py1 - py0
        # ink face components live inside the body bbox
        sub = e[py0:py1, px0:px1]
        comps = ink_components(sub, (0, 0, pw, ph))
        items = []
        for c in comps:
            segs = trace_shape(c["mask"], (0, 0, pw, ph), max_error=0.5, sigma=1.2, n=150)
            items.append(dict(cx=c["cx"], cy=c["cy"], bw=c["bw"], bh=c["bh"],
                              fill=c["fill"], area=c["area"], segs=segs))
        expr[name] = items
        print(f"{name}: body bbox {pw}x{ph} aspect {pw/ph:.4f}, {len(items)} ink comps")
        for it in items:
            print(f"   c=({it['cx']:.4f},{it['cy']:.4f}) bw={it['bw']:.4f} bh={it['bh']:.4f} fill={it['fill']}")
    result["expressions_meta"] = expr

    with open("/private/tmp/claude-501/-Users-georgeshi-Desktop-app-prepkin-canvas/8e386b9b-4386-4450-acc7-6b9b7ff1db2a/scratchpad/trace_result.json", "w") as f:
        json.dump(result, f, indent=1)
    print("wrote trace_result.json")


if __name__ == "__main__":
    main()
