"""The wave: reference TIMING on our proportions.

The clip's arm is 2.7x longer than our drawn paw, so its poses cannot be copied
directly - we take its rhythm and its envelope and drive our own two numbers
with them. Its flutter is only about 14 degrees, too small to read at app size,
so it is amplified; its stretch is mapped onto our reach.
"""
import json, math
import numpy as np

FR, DUR = 30, 120
F_IN, F_OUT = 10, 100          # the reference's own action occupies 0.33..3.33 s
HOLD_DEG = 110.0               # where a raised arm reads best on OUR body
HOLD_RCH = 2.60                # the fin stretches out as it sweeps up
AMP = 2.0                      # widen the clip's ~14 deg flutter so it reads
RAMP_IN, RAMP_OUT = 9, 11      # frames to leave / return to the rest pose

_d = json.load(open("arm_drive.json"))
_t = np.array([r[0] for r in _d]); _g = np.array([r[1] for r in _d])
_r = np.array([r[2] for r in _d])

def _smooth(a, w):
    k = np.ones(w)/w
    return np.convolve(np.pad(a, (w, w), mode="edge"), k, "same")[w:-w]

_F = np.arange(F_IN, F_OUT+1)
_gi = np.interp(_F/FR, _t, _g)
_ri = np.interp(_F/FR, _t, _r)
_ge = _smooth(_gi, 13)                    # envelope: raise, hold, lower
_re = _smooth(_ri, 13)
_LO, _HI = float(_gi.min()), float(np.percentile(_ge, 85))
_env = np.clip((_ge - _LO) / (_HI - _LO), 0.0, 1.0)
_flut = _gi - _ge                          # the flutter, envelope removed
_rflut = _ri - _re

def _ss(x):
    x = min(1.0, max(0.0, x)); return x*x*(3-2*x)

def pose(f):
    """(deg, reach) for frame f. Exactly rest outside the action."""
    if f <= F_IN or f >= F_OUT:
        return 0.0, 1.0
    i = int(f) - F_IN
    e = _env[i]
    e *= _ss((f - F_IN)/RAMP_IN) * _ss((F_OUT - f)/RAMP_OUT)
    deg = e*HOLD_DEG + _flut[i]*AMP*e
    # The arm only stretches once it is UP. Tying reach to e squared keeps it a
    # stub while it is still low, instead of a long thin spike swinging past
    # the horizontal on the way back down.
    st = e*e
    rch = 1.0 + st*(HOLD_RCH-1.0) + _rflut[i]*(HOLD_RCH-1.0)*1.6*st
    return float(deg), float(max(1.0, rch))

# Keyframes: dense through the fast raise and the drop, 15 fps across the hold.
KEYS = sorted(set([0] + list(range(F_IN-2, F_IN+11)) +
                  list(range(F_IN+11, F_OUT-8, 2)) +
                  list(range(F_OUT-8, F_OUT+4)) + [F_OUT+8, DUR-1]))

# Body: the whole blob lifts and leans into the wave, and settles back.
FAR_SWAY = 4.0          # the resting arm just breathes; it must stay a mitten

def far(f):
    """(deg, reach) of the arm that is NOT waving"""
    d, _ = pose(f)
    return -FAR_SWAY * (d/HOLD_DEG), 1.0

def body(f):
    """(dx, dy, rot_deg, sx, sy) of the root null - bob, lean and squash"""
    e = 0.0
    if F_IN < f < F_OUT:
        i = int(f) - F_IN
        e = _env[i] * _ss((f-F_IN)/RAMP_IN) * _ss((F_OUT-f)/RAMP_OUT)
    br = math.sin((f - F_IN) * 2*math.pi / 26.0)      # slow settle bob
    return (2.2*e, -8.0*e - 2.6*e*br, -2.3*e, 100.0 - 1.1*e*br, 100.0 + 1.3*e*br)

if __name__ == "__main__":
    for f in range(0, DUR, 6):
        d, r = pose(f)
        print("f%3d deg %6.1f reach %.2f" % (f, d, r))
    print("keys:", len(KEYS), KEYS[:6], "...", KEYS[-4:])
