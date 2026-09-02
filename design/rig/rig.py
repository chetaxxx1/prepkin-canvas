"""Pose -> one closed silhouette. Two numbers per arm: swing angle and reach.

The silhouette is always retraced from a distance field, so there is never a
second outline to cross and a seam is impossible by construction.

  torso   the approved body with both mitten lobes bridged out, antenna kept
  arm     a round-capped tapered capsule, shoulder -> hand
  pit     the armpit fill: a cone laid along the bisector of the wedge between
          the arm and the flank. Its radius is driven by the wedge's own half
          angle, so it is exactly zero at rest and grows only as far as the
          wedge opens. This is what turns a hard white V into a soft scoop.
  kboost  on top of that, the blend radius is a FIELD - wider in the armpit
          only - so what is left of the corner is filleted, not creased.
"""
import ast, math
import numpy as np
import field, art, curve
from smooth_torso import TORSO

SHX, SHY, RSH, HX, HY, RPW, KFIT = ast.literal_eval(open("blobfit.txt").read())
SH_L,  SH_R    = (float(SHX), float(SHY)), (886.0-SHX, float(SHY))
REST_L, REST_R = (float(HX), float(HY)), (886.0-HX, float(HY))
R_SH, R_PAW = float(RSH), float(RPW)

D_TORSO = field.sdf_path(TORSO)

# Everything suffixed _up is the value at FULL lift; at rest each one falls
# back to its rest value, so the rest silhouette is untouched by all of them.
P0 = dict(k=float(KFIT), k_up=26.0,
          root_up=74.0, tip_up=44.0, taper=1.3, bow=0.0, hug=0.0,
          fillet=0.0, fil_base=0.0, fil_lo=200.0, fil_hi=760.0, nseg=12)

# Gates for the fillet: never touch the antenna or the top of the head, and let
# each arm soften only its own side.
_GATE_Y = None
_GATE_L = None
_GATE_R = None
def _gates(P):
    global _GATE_Y, _GATE_L, _GATE_R
    if _GATE_Y is None:
        _GATE_Y = field.band(P["fil_lo"], P["fil_hi"], soft=110.0)
        _GATE_L = field.half(470.0, "left", soft=140.0)
        _GATE_R = field.half(416.0, "right", soft=140.0)
    return _GATE_Y, _GATE_L, _GATE_R

def _u(vx, vy):
    n = math.hypot(vx, vy) or 1.0
    return vx/n, vy/n

def swing(sh, rest, deg, reach):
    v = (rest[0]-sh[0], rest[1]-sh[1])
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return (sh[0] + (v[0]*c - v[1]*s)*reach, sh[1] + (v[0]*s + v[1]*c)*reach)

def wedge_angle(sh, rest, deg, reach):
    """How far the arm has swung off the flank it grew out of. 0 at rest."""
    hand = swing(sh, rest, deg, reach)
    ua = _u(hand[0]-sh[0], hand[1]-sh[1])
    uf = _u(rest[0]-sh[0], rest[1]-sh[1])
    c = max(-1.0, min(1.0, ua[0]*uf[0] + ua[1]*uf[1]))
    return math.acos(c)

def arm_radii(lift, P, n):
    """A TEARDROP, the way the drawn mitten and the TFT slime both are.

    Fat where it swells out of the body, tapering along its length, ending in a
    rounded tip. Not a tube with a ball on it - that reads as a limb with a
    joint, which this character does not have. The drawn mitten is 1.9x as wide
    across its base as it sticks out, so a raised arm stays stubby too.
    """
    r0 = R_SH  + (P["root_up"] - R_SH) * lift
    r1 = R_PAW + (P["tip_up"]  - R_PAW) * lift
    p = P["taper"]
    return [r1 + (r0-r1)*(1.0 - i/n)**p for i in range(n+1)]

def arm_centre(sh, hand, lift, P, side, n):
    """Rise along the flank first, then curl out - the reference's comma shape.

    A straight arm has to choose: out to the side (reads as an arm, but opens a
    wide armpit) or straight up (narrow armpit, but the head swallows it). The
    curve does both - the root hugs the body so the slot stays narrow, the tip
    swings clear so the arm reads.
    """
    dx, dy = hand[0]-sh[0], hand[1]-sh[1]
    L = math.hypot(dx, dy) or 1.0
    ux, uy = dx/L, dy/L
    h = P["hug"] * lift
    rx, ry = _u(ux*(1-h) + 0.0*h, uy*(1-h) + (-1.0)*h)     # root leans upright
    px, py = (uy, -ux) if side == "left" else (-uy, ux)     # away from the body
    b = P["bow"] * lift * L
    p1 = (sh[0] + rx*L*0.50, sh[1] + ry*L*0.50)
    p2 = (hand[0] - ux*L*0.30 + px*b, hand[1] - uy*L*0.30 + py*b)
    out = []
    for i in range(n+1):
        t = i/n
        a, b2, c2, d2 = (1-t)**3, 3*(1-t)**2*t, 3*(1-t)*t*t, t**3
        out.append((a*sh[0] + b2*p1[0] + c2*p2[0] + d2*hand[0],
                    a*sh[1] + b2*p1[1] + c2*p2[1] + d2*hand[1]))
    return out

def _add_arm(d, sh, rest, deg, reach, P, side):
    """The blend is tight at rest (so the rest pose IS the art) and loosens as
    the arm lifts. Safe only because the rolling-ball fillet, not the blend,
    is what guarantees a soft armpit."""
    hand = swing(sh, rest, deg, reach)
    lift = math.sin(min(wedge_angle(sh, rest, deg, reach), math.pi/2))
    k = P["k"] + (P["k_up"] - P["k"]) * lift
    n = int(P["nseg"])
    pts = arm_centre(sh, hand, lift, P, side, n)
    return field.smin(d, field.sdf_tube(pts, arm_radii(lift, P, n)), k)

def silhouette(degL=0.0, reachL=1.0, degR=0.0, reachR=1.0, P=None,
               n_pts=96, sigma=22.0):
    P = dict(P0, **(P or {}))
    d = _add_arm(D_TORSO, SH_L, REST_L, degL,  reachL, P, "left")
    d = _add_arm(d,       SH_R, REST_R, -degR, reachR, P, "right")
    if P["fillet"] > 0:
        aL = math.sin(min(wedge_angle(SH_L, REST_L, degL, reachL), math.pi/2))
        aR = math.sin(min(wedge_angle(SH_R, REST_R, -degR, reachR), math.pi/2))
        if max(aL, aR, P["fil_base"]) > 0.01:
            gy, gl, gr = _gates(P)
            # fil_base keeps a minimum roll radius on the WHOLE outline, at
            # every pose - that is what stops the mitten junctions reading as
            # cusps. The lift terms add more where an arm has swung away.
            w = np.clip(P["fil_base"] + gl*aL + gr*aR, 0.0, 1.0) * gy
            dc = field.close_field(d, P["fillet"])
            d = d + (dc - d) * w
    return curve.contour(d, n_pts=n_pts, sigma=sigma)[0]
