import math, art
B = art.BODY
def _s(i): return (B[i][0], B[i][1])
def _c(a, b, bow):
    dx, dy = b[0]-a[0], b[1]-a[1]
    n = math.hypot(dx, dy) or 1
    nx, ny = -dy/n, dx/n
    return [a[0],a[1], a[0]+dx/3+nx*bow, a[1]+dy/3+ny*bow,
            a[0]+2*dx/3+nx*bow, a[1]+2*dy/3+ny*bow, b[0],b[1]]
# the body with BOTH limb lobes removed - a clean smooth slime, antenna kept
TORSO, i = [], 0
while i < 41:
    if i == 10: TORSO.append(_c(_s(10), _s(17), -5.0)); i = 17; continue
    if i == 28: TORSO.append(_c(_s(28), _s(34), -7.0)); i = 34; continue
    TORSO.append(B[i]); i += 1
