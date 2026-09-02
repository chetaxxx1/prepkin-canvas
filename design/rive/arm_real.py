"""The real mitten, drawn whole, with a round root tucked under the body.

Visible outline  = the EXACT mitten from SlimeView.swift (segs 30..33).
Buried root      = a circle centred on the shoulder pivot, deep inside the
                   torso. Rotation about the pivot leaves that circle exactly
                   where it is, so the joint can never open, and because it is
                   inside the body it is never visible either.
This is the standard cut-out rig: whole limb, drawn behind a solid torso.
"""
import math, numpy as np, art, raster
from body_noarm import BODY_NOARM
from limb import _arc, _line

B = art.BODY
A_PT = (B[30][0], B[30][1])       # bottom of the mitten's seam
B_PT = (B[34][0], B[34][1])       # top of the mitten's seam
MITTEN = [B[i] for i in range(30, 34)]      # untouched drawn art

def build(pivot, R):
    """closed path: the drawn mitten, then a dive into the buried root disc."""
    bB = math.atan2(B_PT[1]-pivot[1], B_PT[0]-pivot[0])
    bA = math.atan2(A_PT[1]-pivot[1], A_PT[0]-pivot[0])
    T1 = (pivot[0]+R*math.cos(bB), pivot[1]+R*math.sin(bB))
    T2 = (pivot[0]+R*math.cos(bA), pivot[1]+R*math.sin(bA))
    sweep = bA - bB
    while sweep <= 0: sweep += 2*math.pi          # wrap the long way, through
    if sweep < math.pi: sweep -= 2*math.pi        # the body, so the disc is enclosed
    return list(MITTEN) + [_line(B_PT, T1)] + _arc(pivot, R, bB, bB+sweep) + [_line(T2, A_PT)]

def find_pivot():
    """deepest, largest root circle that still fits inside the torso"""
    body = raster.mask(BODY_NOARM)
    YY, XX = np.mgrid[0:raster.H, 0:raster.W]
    best = None
    for px in range(100, 231, 4):
        for py in range(430, 611, 4):
            cx, cy = px+raster.OFFX, py+raster.OFFY
            d2 = (XX-cx)**2 + (YY-cy)**2
            # largest radius that stays inside
            outside = d2[~body]
            R = int(math.sqrt(outside.min())) - 2 if outside.size else 0
            if R < 30: continue
            # the root must sit behind the seam, not out past it
            reach = max(math.hypot(A_PT[0]-px, A_PT[1]-py),
                        math.hypot(B_PT[0]-px, B_PT[1]-py))
            score = R - 0.35*reach
            if best is None or score > best[0]:
                best = (score, px, py, R)
    return best[1], best[2], best[3]

def build2(pivot, R):
    """Same idea, but the root joins the seam with TRUE tangent lines, so the
    connector reads as a tapered upper arm instead of a strut. Path:
    A -> drawn mitten -> B -> tangent to root disc -> around the disc ->
    tangent back to A."""
    px, py = pivot
    def tangent(pt, side):
        dx, dy = pt[0]-px, pt[1]-py
        d = math.hypot(dx, dy)
        if d <= R + 1e-6:                      # inside the disc: fall back radial
            a = math.atan2(dy, dx)
            return a
        return math.atan2(dy, dx) + side * math.acos(R/d)
    aB = tangent(B_PT, +1)
    aA = tangent(A_PT, -1)
    T1 = (px+R*math.cos(aB), py+R*math.sin(aB))
    T2 = (px+R*math.cos(aA), py+R*math.sin(aA))
    sweep = aA - aB
    while sweep <= 0: sweep += 2*math.pi
    if sweep < math.pi: sweep -= 2*math.pi
    return list(MITTEN) + [_line(B_PT, T1)] + _arc(pivot, R, aB, aB+sweep) + [_line(T2, A_PT)]

def max_radius(pivot, body_mask):
    import numpy as _np
    YY, XX = _np.mgrid[0:raster.H, 0:raster.W]
    cx, cy = pivot[0]+raster.OFFX, pivot[1]+raster.OFFY
    d2 = (XX-cx)**2 + (YY-cy)**2
    out = d2[~body_mask]
    return int(math.sqrt(out.min())) - 3 if out.size else 0
