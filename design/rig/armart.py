"""The arm, authored the way a designer would draw it.

ARM SPACE: origin at the shoulder joint, +x down the arm to the paw.
The silhouette is a round shoulder cap and a round paw joined by two long
edges - the outer edge bowed out, the inner edge slightly hollow - which is
exactly the line the drawn mitten uses. The root cap is centred on the joint
so it stays tucked under the torso at any angle.
"""
import math
from limb import _arc

R_SH   = 56.0     # shoulder cap radius (centred on the joint)
R_PAW  = 52.0     # paw radius
LEN    = 188.0    # joint -> paw centre
BOW_O  = 14.0     # outer edge bulge
BOW_I  = -9.0     # inner edge hollow

def _bowed(p0, p1, bow):
    dx, dy = p1[0]-p0[0], p1[1]-p0[1]
    n = math.hypot(dx, dy) or 1.0
    nx, ny = -dy/n, dx/n
    return [p0[0], p0[1],
            p0[0]+dx/3 + nx*bow, p0[1]+dy/3 + ny*bow,
            p0[0]+2*dx/3 + nx*bow, p0[1]+2*dy/3 + ny*bow,
            p1[0], p1[1]]

def outline(r_sh=R_SH, r_paw=R_PAW, length=LEN, bow_o=BOW_O, bow_i=BOW_I):
    P = (length, 0.0)
    d = length
    alpha = math.asin((r_sh - r_paw) / d)
    aO = math.pi/2 + alpha          # outer side
    aI = -math.pi/2 - alpha         # inner side
    S_O = (r_sh*math.cos(aO),  r_sh*math.sin(aO))
    P_O = (P[0]+r_paw*math.cos(aO), P[1]+r_paw*math.sin(aO))
    S_I = (r_sh*math.cos(aI),  r_sh*math.sin(aI))
    P_I = (P[0]+r_paw*math.cos(aI), P[1]+r_paw*math.sin(aI))
    segs  = [_bowed(S_O, P_O, bow_o)]                 # outer edge, bulged
    segs += _arc(P, r_paw, aO, aI - 2*math.pi)        # round the paw
    segs += [_bowed(P_I, S_I, bow_i)]                 # inner edge, hollowed
    segs += _arc((0.0, 0.0), r_sh, aI, aO - 2*math.pi)  # round the shoulder
    return segs

ARM_LOCAL = outline()

def place(pivot, deg, stretch=1.0, segs=None):
    segs = segs if segs is not None else (
        ARM_LOCAL if stretch == 1.0 else outline(length=LEN*stretch))
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    out = []
    for g in segs:
        q = []
        for k in range(4):
            x, y = g[2*k], g[2*k+1]
            q += [pivot[0] + x*c - y*s, pivot[1] + x*s + y*c]
        out.append(q)
    return out
