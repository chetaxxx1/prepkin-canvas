"""wave_v7.json - standard cut-out rig, the way it is actually done.

body / face / belly : the approved art. Static. Not one control point moves.
armLeft             : the WHOLE limb drawn as one shape - the exact mitten from
                      SlimeView.swift, a tapered upper arm, and a round root
                      centred on the shoulder pivot. Layered BEHIND the body,
                      so the torso hides the root and the joint is never seen.
                      The arm animates with a single rotation value.
"""
import json, math, ast, arm_real, art
from body_noarm import BODY_NOARM

PX, PY, R = ast.literal_eval(open("pivot.txt").read())
ARM = arm_real.build2((PX, PY), R)

W, H, FR, DUR = 1180, 830, 30, 120
GREEN, MINT, INK = (81,207,160), (177,237,212), (16,24,32)
OFF, ANC = [660, 817], [443, 795]

def rot(segs, deg):
    a = math.radians(deg); c, s = math.cos(a), math.sin(a); out = []
    for g in segs:
        q = []
        for k in range(4):
            dx, dy = g[2*k]-PX, g[2*k+1]-PY
            q += [PX + dx*c - dy*s, PY + dx*s + dy*c]
        out.append(q)
    return out

EO = ({"x":[0.20],"y":[0]}, {"x":[0.30],"y":[1]})
IO = ({"x":[0.42],"y":[0]}, {"x":[0.58],"y":[1]})
def k(t, v, e=IO):
    o, i = e; return {"t": t, "s": [v], "o": o, "i": i}

UP = 64.0
ANG = [k(0,0.0), k(5,-12.0,EO), k(17,UP+12,EO), k(22,UP)]
t = 22
for n in range(4):                       # four waves, easing off
    f = 1.0 - n*0.09
    t += 8; ANG.append(k(t, UP - 15*f))
    t += 8; ANG.append(k(t, UP + 13*f))
ANG += [k(t+8, UP-6), k(t+22, -7.0, EO), k(t+32, 0.0)]
ANG = [a for a in ANG if a["t"] <= DUR]

def samp(keys, f):
    if f <= keys[0]["t"]: return keys[0]["s"][0]
    if f >= keys[-1]["t"]: return keys[-1]["s"][0]
    for a, b in zip(keys, keys[1:]):
        if a["t"] <= f <= b["t"]:
            u = (f-a["t"])/(b["t"]-a["t"])
            x1,y1 = a["o"]["x"][0], a["o"]["y"][0]
            x2,y2 = b["i"]["x"][0], b["i"]["y"][0]
            lo, hi = 0.0, 1.0
            for _ in range(22):
                m=(lo+hi)/2; x=3*(1-m)**2*m*x1+3*(1-m)*m*m*x2+m**3
                lo,hi=(m,hi) if x<u else (lo,m)
            m=(lo+hi)/2
            return a["s"][0]+(b["s"][0]-a["s"][0])*(3*(1-m)**2*m*y1+3*(1-m)*m*m*y2+m**3)
    return keys[-1]["s"][0]

def fill(c): return {"ty":"fl","c":{"a":0,"k":[c[0]/255,c[1]/255,c[2]/255,1]},
                     "o":{"a":0,"k":100},"r":1}
def tr(): return {"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},
                  "s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}
def lay(ind, nm, shapes, ks=None):
    return {"ddd":0,"ind":ind,"ty":4,"nm":nm,"sr":1,"parent":99,
            "ks": ks or {"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[0,0]},
                         "a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]}},
            "ao":0,"shapes":shapes,"ip":0,"op":DUR,"st":0}

# the arm is ONE static shape rotated by the layer transform - the cleanest
# possible rig, and exactly what a Spine/Rive bone does.
arm_r = [{"t": a["t"], "s": [a["s"][0]], "o": a["o"], "i": a["i"]} for a in ANG]
arm_ks = {"o":{"a":0,"k":100}, "r":{"a":1,"k":arm_r},
          "p":{"a":0,"k":[PX,PY]}, "a":{"a":0,"k":[PX,PY]},
          "s":{"a":0,"k":[100,100]}}

def pk(t,x,y): return {"t":t,"s":[OFF[0]+x,OFF[1]+y,0],
    "o":{"x":[0.42]*3,"y":[0]*3},"i":{"x":[0.58]*3,"y":[1]*3}}
def rk(t,d): return {"t":t,"s":[d],"o":{"x":[0.42],"y":[0]},"i":{"x":[0.58],"y":[1]}}
bob  = [pk(0,0,0),pk(18,3,-7),pk(40,1,-3),pk(62,3,-7),pk(84,1,-3),pk(100,2,-5),
        pk(113,0,0),pk(119,0,0)]
lean = [rk(0,0),rk(18,-2.2),rk(50,-1.5),rk(80,-2.2),rk(100,-1.2),rk(113,0),rk(119,0)]
NULL = {"ddd":0,"ind":99,"ty":3,"nm":"root","sr":1,
        "ks":{"o":{"a":0,"k":0},"r":{"a":1,"k":lean},"p":{"a":1,"k":bob},
              "a":{"a":0,"k":ANC},"s":{"a":0,"k":[100,100,100]}},
        "ao":0,"ip":0,"op":DUR,"st":0}

layers = [
 lay(1,"face",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(g)}}
                                for g in art.FACES]+[fill(INK),tr()]}]),
 lay(2,"belly",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(art.BELLY)}},
                                 fill(MINT),tr()]}]),
 lay(3,"body",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(BODY_NOARM)}},
                                fill(GREEN),tr()]}]),
 lay(4,"armLeft",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(ARM)}},
                                   fill(GREEN),tr()]}], ks=arm_ks),
 NULL,
]
doc = {"v":"5.7.1","fr":FR,"ip":0,"op":DUR,"w":W,"h":H,"nm":"SlimeWaveV7",
       "ddd":0,"assets":[],"layers":layers}
open("wave_v7.json","w").write(json.dumps(doc))
print("wrote wave_v7.json", len(json.dumps(doc)), "bytes  (arm = 1 shape + 1 rotation curve)")
print("angle f0/f17/f30/f60/f90/f110/f119:", " ".join("%.0f"%samp(ANG,f)
      for f in (0,17,30,60,90,110,119)))
