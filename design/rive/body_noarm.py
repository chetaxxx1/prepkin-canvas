import math, art
B = art.BODY
def _s(i): return (B[i][0], B[i][1])
def _e(i): return (B[i][6], B[i][7])
def _curve8(a, b, bow):
    dx, dy = b[0]-a[0], b[1]-a[1]
    n = math.hypot(dx, dy) or 1
    nx, ny = -dy/n, dx/n
    return [a[0],a[1], a[0]+dx/3+nx*bow, a[1]+dy/3+ny*bow,
            a[0]+2*dx/3+nx*bow, a[1]+2*dy/3+ny*bow, b[0],b[1]]
# original path with segs 28..33 (left notch + mitten) replaced by a smooth flank
BODY_NOARM = ([B[i] for i in range(0, 28)] + [_curve8(_s(28), _s(34), -7.0)]
              + [B[i] for i in range(34, 41)])
