"""wave_blob.json - the wave on the blob rig.

The rig is two numbers per arm: swing angle and reach. The silhouette is the
smooth union of the torso field and the arm capsules, retraced every frame, so
there is no seam to break at any pose - it is a single closed curve by
construction. Motion is driven by the hand path traced from George's reference.
"""
import json, math, ast, numpy as np
import blob, art, render
from smooth_torso import TORSO

SHX, SHY, RSH, HX, HY, _RP, _K = ast.literal_eval(open("blobfit.txt").read())
K, RP = 58.0, 62.0                       # approved: smooth sides, arm still reads
SH_L, SH_R = (SHX, SHY), (886.0-SHX, SHY)
REST_L, REST_R = (HX, HY), (886.0-HX, HY)
D_TORSO = blob.sdf_path(TORSO)

FR, DUR, NPTS = 30, 120, 168
AMP   = 1.9      # widen the reference's small flutter so it reads at app size
REACH = 0.62     # damp the reference's stretch so the arm stays a slime, not a noodle

drive = json.load(open("arm_drive.json"))          # [(t, deg, reach), ...]
mid = sum(d[1] for d in drive[2:-2]) / max(1, len(drive)-4)

def _sample(f):
    """(deg, reach) for frame f, easing out of and back into rest"""
    t = f / FR
    t0, t1 = drive[0][0], drive[-1][0]
    if t <= t0 or t >= t1:
        return 0.0, 1.0
    for a, b in zip(drive, drive[1:]):
        if a[0] <= t <= b[0]:
            u = (t-a[0])/(b[0]-a[0]); u = u*u*(3-2*u)
            deg = a[1] + (b[1]-a[1])*u
            rch = a[2] + (b[2]-a[2])*u
            break
    else:
        return 0.0, 1.0
    deg = mid + (deg - mid)*AMP                     # amplify the flutter
    rch = 1.0 + (rch - 1.0)*REACH                   # damp the stretch
    # ease in/out of the rest pose at the ends
    IN0, IN1, OUT0, OUT1 = t0, t0+0.30, t1-0.34, t1
    if t < IN1:
        u = np.clip((t-IN0)/(IN1-IN0), 0, 1); u = u*u*(3-2*u)
        deg, rch = deg*u, 1.0 + (rch-1.0)*u
    elif t > OUT0:
        u = np.clip((t-OUT0)/(OUT1-OUT0), 0, 1); u = u*u*(3-2*u)
        deg, rch = deg*(1-u), 1.0 + (rch-1.0)*(1-u)
    return float(deg), float(rch)

def _swing(sh, rest, deg, reach):
    v = (rest[0]-sh[0], rest[1]-sh[1])
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return (sh[0] + (v[0]*c - v[1]*s)*reach, sh[1] + (v[0]*s + v[1]*c)*reach)

def silhouette(degL, reachL, degR=0.0, reachR=1.0):
    hL = _swing(SH_L, REST_L, degL, reachL)
    hR = _swing(SH_R, REST_R, -degR, reachR)
    d = blob.smin(D_TORSO, blob.sdf_capsule(SH_L, hL, RSH, RP), K)
    d = blob.smin(d,       blob.sdf_capsule(SH_R, hR, RSH, RP), K)
    return blob.contour(d, n_pts=NPTS)

# keyframe at the reference's own 12 fps and let Lottie interpolate
KEYS = sorted({0, DUR-1} | {int(round(d[0]*FR)) for d in drive if d[0]*FR < DUR})
GREEN, MINT, INK = (81,207,160), (177,237,212), (16,24,32)
W, H = 1180, 830
OFF, ANC = [660, 817], [443, 795]

def fill(c): return {"ty":"fl","c":{"a":0,"k":[c[0]/255,c[1]/255,c[2]/255,1]},
                     "o":{"a":0,"k":100},"r":1}
def tr(): return {"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},
                  "s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}
def lay(ind, nm, shapes):
    return {"ddd":0,"ind":ind,"ty":4,"nm":nm,"sr":1,"parent":99,
            "ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[0,0]},
                  "a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]}},
            "ao":0,"shapes":shapes,"ip":0,"op":DUR,"st":0}

if __name__ == "__main__":
    LIN = {"o":{"x":[0.4],"y":[0]}, "i":{"x":[0.6],"y":[1]}}
    kfs, poses = [], {}
    for f in KEYS:
        dg, rc = _sample(f)
        # the far arm gives a small counter-sway so he isn't rigid on one side
        poses[f] = (dg, rc)
        kfs.append({"t": f, "s": [blob.to_bezier(
            silhouette(dg, rc, degR=-0.16*dg, reachR=1.0))], **LIN})
    def pk(t,x,y): return {"t":t,"s":[OFF[0]+x,OFF[1]+y,0],
        "o":{"x":[0.42]*3,"y":[0]*3},"i":{"x":[0.58]*3,"y":[1]*3}}
    def rk(t,d): return {"t":t,"s":[d],"o":{"x":[0.42],"y":[0]},"i":{"x":[0.58],"y":[1]}}
    bob=[pk(0,0,0),pk(14,3,-7),pk(38,1,-3),pk(60,3,-7),pk(84,1,-3),pk(100,2,-5),
         pk(112,0,0),pk(119,0,0)]
    lean=[rk(0,0),rk(14,-2.0),rk(46,-1.4),rk(76,-2.0),rk(100,-1.1),rk(112,0),rk(119,0)]
    NULL={"ddd":0,"ind":99,"ty":3,"nm":"root","sr":1,
          "ks":{"o":{"a":0,"k":0},"r":{"a":1,"k":lean},"p":{"a":1,"k":bob},
                "a":{"a":0,"k":ANC},"s":{"a":0,"k":[100,100,100]}},
          "ao":0,"ip":0,"op":DUR,"st":0}
    doc={"v":"5.7.1","fr":FR,"ip":0,"op":DUR,"w":W,"h":H,"nm":"SlimeWaveBlob",
         "ddd":0,"assets":[],"layers":[
      lay(1,"face",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(g)}}
                                     for g in art.FACES]+[fill(INK),tr()]}]),
      lay(2,"belly",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(art.BELLY)}},
                                      fill(MINT),tr()]}]),
      lay(3,"slime",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":1,"k":kfs}},fill(GREEN),tr()]}]),
      NULL]}
    open("wave_blob.json","w").write(json.dumps(doc))
    print("wrote wave_blob.json  %d keyframes  %d bytes"%(len(kfs), len(json.dumps(doc))))
    print("deg/reach at f0/f14/f30/f60/f90/f110:",
          " ".join("%.0f/%.2f"%_sample(f) for f in (0,14,30,60,90,110)))
