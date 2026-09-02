"""A real limb for the slime: a rubber-hose capsule between two circles.

The root circle is centred exactly on the shoulder pivot and sits INSIDE the
body. Rotating the arm about that pivot leaves the root circle unchanged, so
the joint can never open a gap - at any angle, any length. The body layer is
drawn on top and hides everything inside it, so only the part of the arm that
reaches past the flank is ever visible.
"""
import math

K = 0.5522847498307936          # circle -> cubic bezier constant

def _rot(v, a):
    c, s = math.cos(a), math.sin(a)
    return (v[0]*c - v[1]*s, v[0]*s + v[1]*c)

def _arc(c, r, a0, a1):
    """circle arc c,r from angle a0 to a1 (radians, signed) -> cubic segments"""
    segs = []
    sweep = a1 - a0
    n = max(1, int(math.ceil(abs(sweep) / (math.pi/2) - 1e-9)))
    step = sweep / n
    k = K * (4.0/3.0) * math.tan(step/4.0) * 3.0/4.0 * (4.0/3.0)
    k = (4.0/3.0) * math.tan(step/4.0)
    for i in range(n):
        b0 = a0 + i*step
        b1 = b0 + step
        p0 = (c[0]+r*math.cos(b0), c[1]+r*math.sin(b0))
        p3 = (c[0]+r*math.cos(b1), c[1]+r*math.sin(b1))
        t0 = (-math.sin(b0)*r*k, math.cos(b0)*r*k)
        t1 = ( math.sin(b1)*r*k, -math.cos(b1)*r*k)
        segs.append([p0[0], p0[1], p0[0]+t0[0], p0[1]+t0[1],
                     p3[0]+t1[0], p3[1]+t1[1], p3[0], p3[1]])
    return segs

def _line(a, b):
    return [a[0], a[1], a[0]+(b[0]-a[0])/3, a[1]+(b[1]-a[1])/3,
            a[0]+2*(b[0]-a[0])/3, a[1]+2*(b[1]-a[1])/3, b[0], b[1]]

def arm(pivot, R, hand, r):
    """closed outline of the limb: root circle at `pivot` r=R, hand circle at
    `hand` r=r, joined by their external tangents."""
    dx, dy = hand[0]-pivot[0], hand[1]-pivot[1]
    d = math.hypot(dx, dy)
    if d <= abs(R - r) + 1e-6:
        return _arc(pivot, R, 0, 2*math.pi)          # degenerate: just the root
    base = math.atan2(dy, dx)
    alpha = math.asin((R - r) / d)                    # tangent tilt
    a1 = base + (math.pi/2 + alpha)                   # one side
    a2 = base - (math.pi/2 + alpha)                   # the other
    P1 = (pivot[0]+R*math.cos(a1), pivot[1]+R*math.sin(a1))
    H1 = (hand[0] + r*math.cos(a1), hand[1] + r*math.sin(a1))
    P2 = (pivot[0]+R*math.cos(a2), pivot[1]+R*math.sin(a2))
    H2 = (hand[0] + r*math.cos(a2), hand[1] + r*math.sin(a2))
    segs = [_line(P1, H1)]
    segs += _arc(hand, r, a1, a2 - 2*math.pi)         # around the hand tip
    segs += [_line(H2, P2)]
    segs += _arc(pivot, R, a2, a1 - 2*math.pi)        # the long way round the root
    return segs

def pose(pivot, R, rest_hand, r, deg, reach=1.0, fat=1.0):
    """arm rotated `deg` about the pivot, hand pushed out by `reach`."""
    v = (rest_hand[0]-pivot[0], rest_hand[1]-pivot[1])
    v = _rot(v, math.radians(deg))
    hand = (pivot[0]+v[0]*reach, pivot[1]+v[1]*reach)
    return arm(pivot, R, hand, r*fat)

def capsule(c0, r0, c1, r1):
    """closed outline hugging two circles (a 'hose' segment)."""
    return arm(c0, r0, c1, r1)

def hose(pivot, R, rest_dir, length, deg, bend, rE, rH):
    """Two-link rubber hose: root -> elbow -> hand. Returns a LIST of closed
    sub-paths; drawn together with one fill they union seamlessly. The root
    circle stays centred on the pivot, so the joint never opens."""
    d = _rot(rest_dir, math.radians(deg))
    n = (-d[1], d[0])
    E = (pivot[0] + d[0]*length*0.55 + n[0]*bend,
         pivot[1] + d[1]*length*0.55 + n[1]*bend)
    Hd = (pivot[0] + d[0]*length + n[0]*bend*1.7,
          pivot[1] + d[1]*length + n[1]*bend*1.7)
    return [capsule(pivot, R, E, rE), capsule(E, rE, Hd, rH)]

def _signed_area(segs, n=10):
    pts = []
    for s in segs:
        for i in range(n):
            t = i/n
            x = (1-t)**3*s[0]+3*(1-t)**2*t*s[2]+3*(1-t)*t*t*s[4]+t**3*s[6]
            y = (1-t)**3*s[1]+3*(1-t)**2*t*s[3]+3*(1-t)*t*t*s[5]+t**3*s[7]
            pts.append((x, y))
    a = 0.0
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]+pts[:1]):
        a += x0*y1 - x1*y0
    return a/2.0

def reverse(segs):
    return [[s[6], s[7], s[4], s[5], s[2], s[3], s[0], s[1]] for s in reversed(segs)]

def same_winding(segs, positive=True):
    """Sub-paths that overlap must wind the same way or non-zero fill punches
    a hole where they cross."""
    a = _signed_area(segs)
    if (a > 0) != positive:
        return reverse(segs)
    return segs
