"""wave_v8.json - follows the reference hand path exactly.

The reference arm is 2.7x longer than our drawn paw, so the paw alone can never
reach where the reference hand goes. Instead:

  paw   = the EXACT mitten from SlimeView.swift, kept rigid. It rotates about
          the shoulder and slides outward to sit on the reference's hand.
  arm   = a slim tapered tendril from a round shoulder cap out to the paw's
          base. It stretches as the paw reaches - which is what a slime does.
  body  = the approved art, static, drawn ON TOP so the shoulder is hidden.

Per frame the paw is placed on the hand position traced from George's clip, so
the gesture is the reference's, not an invention.
"""
import json, math, ast, art, limb
from body_noarm import BODY_NOARM

B = art.BODY
PAW = [B[i] for i in range(30, 34)]                 # untouched drawn art
A_PT, B_PT = (B[30][0], B[30][1]), (B[34][0], B[34][1])
SHOULDER = (165.0, 470.0)
R_SH, R_BASE = 70.0, 46.0
REST_HAND = (B[32][6], B[32][7])                    # the paw's drawn tip
REST_V = (REST_HAND[0]-SHOULDER[0], REST_HAND[1]-SHOULDER[1])
REST_A = math.atan2(REST_V[1], REST_V[0])
REST_L = math.hypot(*REST_V)

W, H, FR, DUR = 1180, 830, 30, 120
GREEN, MINT, INK = (81,207,160), (177,237,212), (16,24,32)
OFF, ANC = [660, 817], [443, 795]

def place(hand):
    """rigid paw + the tendril that reaches it, for a given hand position."""
    v = (hand[0]-SHOULDER[0], hand[1]-SHOULDER[1])
    ang, L = math.atan2(v[1], v[0]), math.hypot(*v)
    dth, ext = ang - REST_A, L - REST_L
    c, s = math.cos(dth), math.sin(dth)
    ux, uy = math.cos(ang), math.sin(ang)
    def T(p):
        dx, dy = p[0]-SHOULDER[0], p[1]-SHOULDER[1]
        return (SHOULDER[0] + dx*c - dy*s + ux*ext,
                SHOULDER[1] + dx*s + dy*c + uy*ext)
    paw = []
    for g in PAW:
        q = []
        for k_ in range(4):
            x, y = T((g[2*k_], g[2*k_+1]))
            q += [x, y]
        paw.append(q)
    a2, b2 = T(A_PT), T(B_PT)
    paw = paw + [limb._line(b2, a2)]                # close the paw's mouth
    mid = ((a2[0]+b2[0])/2, (a2[1]+b2[1])/2)
    base = (mid[0]+ux*18, mid[1]+uy*18)   # sink the joint into the paw
    return [limb.same_winding(limb.arm(SHOULDER, R_SH, base, R_BASE)),
            limb.same_winding(paw)]

# ---- the reference hand path, resampled to 30 fps -------------------------
raw = json.load(open("hand_path.json"))             # [(t, x, y), ...] at 12 fps
def ref_hand(f):
    t = f / FR
    if t <= raw[0][0] or t >= raw[-1][0]: return None
    for a, b in zip(raw, raw[1:]):
        if a[0] <= t <= b[0]:
            u = (t-a[0])/(b[0]-a[0])
            u = u*u*(3-2*u)
            return (a[1]+(b[1]-a[1])*u, a[2]+(b[2]-a[2])*u)
    return None

IN0, IN1 = 3, 10                                    # ease off the rest pose
OUT0, OUT1 = 100, 112
def hand_at(f):
    r = ref_hand(f)
    if r is None: return REST_HAND
    if f < IN1:
        u = max(0.0, (f-IN0)/(IN1-IN0)); u = u*u*(3-2*u)
        return (REST_HAND[0]+(r[0]-REST_HAND[0])*u, REST_HAND[1]+(r[1]-REST_HAND[1])*u)
    if f > OUT0:
        u = min(1.0, (f-OUT0)/(OUT1-OUT0)); u = u*u*(3-2*u)
        return (r[0]+(REST_HAND[0]-r[0])*u, r[1]+(REST_HAND[1]-r[1])*u)
    return r

def fill(c): return {"ty":"fl","c":{"a":0,"k":[c[0]/255,c[1]/255,c[2]/255,1]},
                     "o":{"a":0,"k":100},"r":1}
def tr(): return {"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},
                  "s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}
def lay(ind, nm, shapes):
    return {"ddd":0,"ind":ind,"ty":4,"nm":nm,"sr":1,"parent":99,
            "ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[0,0]},
                  "a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]}},
            "ao":0,"shapes":shapes,"ip":0,"op":DUR,"st":0}

LIN = {"o":{"x":[0.4],"y":[0]}, "i":{"x":[0.6],"y":[1]}}
tend_kfs, paw_kfs = [], []
for f in range(DUR):
    tend, paw = place(hand_at(f))
    tend_kfs.append({"t":f,"s":[art.to_lottie(tend)],**LIN})
    paw_kfs.append({"t":f,"s":[art.to_lottie(paw)],**LIN})

def pk(t,x,y): return {"t":t,"s":[OFF[0]+x,OFF[1]+y,0],
    "o":{"x":[0.42]*3,"y":[0]*3},"i":{"x":[0.58]*3,"y":[1]*3}}
def rk(t,d): return {"t":t,"s":[d],"o":{"x":[0.42],"y":[0]},"i":{"x":[0.58],"y":[1]}}
bob=[pk(0,0,0),pk(14,3,-7),pk(38,1,-3),pk(60,3,-7),pk(82,1,-3),pk(100,2,-5),
     pk(112,0,0),pk(119,0,0)]
lean=[rk(0,0),rk(14,-2.2),rk(48,-1.5),rk(78,-2.2),rk(100,-1.2),rk(112,0),rk(119,0)]
NULL={"ddd":0,"ind":99,"ty":3,"nm":"root","sr":1,
      "ks":{"o":{"a":0,"k":0},"r":{"a":1,"k":lean},"p":{"a":1,"k":bob},
            "a":{"a":0,"k":ANC},"s":{"a":0,"k":[100,100,100]}},
      "ao":0,"ip":0,"op":DUR,"st":0}

layers=[
 lay(1,"face",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(g)}}
                                for g in art.FACES]+[fill(INK),tr()]}]),
 lay(2,"belly",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(art.BELLY)}},
                                 fill(MINT),tr()]}]),
 lay(3,"body",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(BODY_NOARM)}},
                                fill(GREEN),tr()]}]),
 lay(4,"armLeft",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":1,"k":tend_kfs}},
                                   {"ty":"sh","ks":{"a":1,"k":paw_kfs}},
                                   fill(GREEN),tr()]}]),
 NULL,
]
doc={"v":"5.7.1","fr":FR,"ip":0,"op":DUR,"w":W,"h":H,"nm":"SlimeWaveV8",
     "ddd":0,"assets":[],"layers":layers}
open("wave_v8.json","w").write(json.dumps(doc))
print("wrote wave_v8.json", len(json.dumps(doc)), "bytes")
for f in (0,10,20,40,60,90,110,119):
    h=hand_at(f); print("  f%3d hand (%6.0f,%6.0f)"%(f,h[0],h[1]))
