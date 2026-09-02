"""Shared: exact SlimeArt geometry, plus the body/arm split.

Nothing here approximates our mascot. The body is the original path with the
left mitten lifted out along a shared chord, so body UNION arm is exactly the
original silhouette at rest.
"""
import re, math, numpy as np

SWIFT = "/Users/georgeshi/Desktop/app/prepkin-canvas/ios/Sources/SlimeView.swift"
SRC = open(SWIFT).read()
SW, SH = 886.0, 795.0

def parse_paths(name):
    m = re.search(rf"static let {name}: \[\[\[Double\]\]\] = \[(.*?)\n    \]\n", SRC, re.S)
    out = []
    for sub in re.findall(r"\[\n((?:\s*\[[^\]]+\],\n)+)\s*\]", m.group(1)):
        segs = [[float(x) for x in re.findall(r"-?\d+\.\d+|-?\d+", r)]
                for r in re.findall(r"\[([^\]]+)\]", sub)]
        out.append([s for s in segs if len(s) == 8])
    return out

def px(segs):
    """normalized 8-tuples -> absolute-pixel 8-tuples"""
    return [[s[0]*SW, s[1]*SH, s[2]*SW, s[3]*SH, s[4]*SW, s[5]*SH, s[6]*SW, s[7]*SH]
            for s in segs]

BODY  = px(parse_paths("body")[0])
BELLY = px(parse_paths("belly")[0])
FACES = [px(g) for g in parse_paths("faceIdle")]

# ---- bezier helpers -------------------------------------------------------
def split3(seg):
    """one cubic -> three cubics (de Casteljau at 1/3 and 1/2 of remainder)"""
    def de_cast(s, t):
        p0=np.array(s[0:2]); p1=np.array(s[2:4]); p2=np.array(s[4:6]); p3=np.array(s[6:8])
        a=p0+(p1-p0)*t; b=p1+(p2-p1)*t; c=p2+(p3-p2)*t
        d=a+(b-a)*t; e=b+(c-b)*t; f=d+(e-d)*t
        return ([*p0,*a,*d,*f], [*f,*e,*c,*p3])
    left, rest = de_cast(seg, 1/3)
    mid, right = de_cast(rest, 1/2)
    return [left, mid, right]

def cubic_through(a, ta, b, tb, k=0.36):
    """cubic from a to b leaving along unit ta, arriving along unit tb"""
    d = math.hypot(b[0]-a[0], b[1]-a[1]) * k
    return [a[0], a[1], a[0]+ta[0]*d, a[1]+ta[1]*d,
            b[0]-tb[0]*d, b[1]-tb[1]*d, b[0], b[1]]

def unit(dx, dy):
    n = math.hypot(dx, dy) or 1.0
    return (dx/n, dy/n)

def to_lottie(segs, closed=True):
    """abs-pixel cubic list -> lottie bezier dict"""
    n = len(segs); v=[]; o=[]; i_=[]
    for k in range(n):
        s = segs[k]; prev = segs[(k-1) % n]
        v.append([round(s[0],2), round(s[1],2)])
        o.append([round(s[2]-s[0],2), round(s[3]-s[1],2)])
        i_.append([round(prev[4]-s[0],2), round(prev[5]-s[1],2)])
    return {"c": closed, "v": v, "o": o, "i": i_}

# ---- the split ------------------------------------------------------------
# Left mitten = segs 30..33. It attaches along the chord from seg34's start
# back to seg30's start; body and arm share that chord, so their union is the
# untouched original outline.
A = (BODY[30][0], BODY[30][1])       # (90.1, 592.2)  chord end, low
B = (BODY[34][0], BODY[34][1])       # (60.2, 457.0)  chord end, high
CHORD = [A[0], A[1],
         A[0]+(B[0]-A[0])/3, A[1]+(B[1]-A[1])/3,
         A[0]+2*(B[0]-A[0])/3, A[1]+2*(B[1]-A[1])/3,
         B[0], B[1]]

# BODY_REST: EVERY original segment except the mitten (30..33), with the chord
# closing the gap. Antenna, right mitten, dome, bottom - all untouched, same
# control points as the art file. Order: 0..29, chord, 34..40 (40 closes to 0).
BODY_REST = [BODY[i] for i in range(0, 30)] + [CHORD] + [BODY[i] for i in range(34, 41)]

# BODY_OPEN: identical vertex count; segs 28, 29 and the chord are replaced by
# a single smooth flank curve split into three, so the notch the arm used to
# sit in dissolves when the arm lifts. Nothing else changes at all.
FA = (BODY[28][0], BODY[28][1])                      # (99.3, 642.3)
FB = B                                               # (60.2, 457.0)
tA = unit(BODY[28][2]-BODY[28][0], BODY[28][3]-BODY[28][1])
tB = unit(BODY[34][2]-BODY[34][0], BODY[34][3]-BODY[34][1])
FLANK = cubic_through(FA, tA, FB, (-tB[0], -tB[1]), 0.42)
IDX28 = 28                                           # seg28 sits at index 28
BODY_OPEN = list(BODY_REST)
BODY_OPEN[IDX28:IDX28+3] = split3(FLANK)
assert len(BODY_OPEN) == len(BODY_REST)

# ARM: the mitten segments plus a root buried inside the body so the joint can
# never open a gap, whatever the angle.
PIVOT = (96.0, 528.0)
def _bury(p, depth):
    return (p[0] + depth, p[1])
ARM = [BODY[i] for i in range(30, 34)]
_root_hi = _bury(B, 78.0)
_root_lo = _bury(A, 78.0)
ARM = ARM + [
    [B[0], B[1], B[0]+26, B[1], _root_hi[0]-26, _root_hi[1], _root_hi[0], _root_hi[1]],
    [_root_hi[0], _root_hi[1], _root_hi[0]+10, _root_hi[1]+45,
     _root_lo[0]+10, _root_lo[1]-45, _root_lo[0], _root_lo[1]],
    [_root_lo[0], _root_lo[1], _root_lo[0]-26, _root_lo[1], A[0]+26, A[1], A[0], A[1]],
]
