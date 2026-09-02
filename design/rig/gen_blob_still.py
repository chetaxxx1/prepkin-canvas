"""Model sheet for the blob build: one smooth silhouette, arms as bulges."""
import ast, math, json, numpy as np
import blob, art, render
from smooth_torso import TORSO

SHX, SHY, RSH, HX, HY, RP, K = ast.literal_eval(open("blobfit.txt").read())
SH_L, SH_R = (SHX, SHY), (886.0-SHX, SHY)
REST_L, REST_R = (HX, HY), (886.0-HX, HY)
D_TORSO = blob.sdf_path(TORSO)

def _swing(sh, rest_hand, deg, reach):
    v = (rest_hand[0]-sh[0], rest_hand[1]-sh[1])
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    return (sh[0] + (v[0]*c - v[1]*s)*reach, sh[1] + (v[0]*s + v[1]*c)*reach)

def silhouette(degL=0.0, reachL=1.0, degR=0.0, reachR=1.0, n_pts=210):
    hL = _swing(SH_L, REST_L, degL, reachL)
    hR = _swing(SH_R, REST_R, -degR, reachR)
    d = blob.smin(D_TORSO, blob.sdf_capsule(SH_L, hL, RSH, RP), K)
    d = blob.smin(d,       blob.sdf_capsule(SH_R, hR, RSH, RP), K)
    return blob.contour(d, n_pts=n_pts)

GREEN, MINT, INK = (81,207,160), (177,237,212), (16,24,32)
W, H = 1180, 830
def fill(c): return {"ty":"fl","c":{"a":0,"k":[c[0]/255,c[1]/255,c[2]/255,1]},
                     "o":{"a":0,"k":100},"r":1}
def tr(): return {"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},
                  "s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}
def lay(ind, nm, shapes, op):
    return {"ddd":0,"ind":ind,"ty":4,"nm":nm,"sr":1,"parent":99,
            "ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[0,0]},
                  "a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]}},
            "ao":0,"shapes":shapes,"ip":0,"op":op,"st":0}

def scene(paths):
    n = len(paths)
    kf = [{"t":i,"s":[blob.to_bezier(p)],"h":1} for i,p in enumerate(paths)]
    NULL={"ddd":0,"ind":99,"ty":3,"nm":"root","sr":1,
          "ks":{"o":{"a":0,"k":0},"r":{"a":0,"k":0},"p":{"a":0,"k":[660,817]},
                "a":{"a":0,"k":[443,795]},"s":{"a":0,"k":[100,100,100]}},
          "ao":0,"ip":0,"op":n,"st":0}
    return {"v":"5.7.1","fr":30,"ip":0,"op":n,"w":W,"h":H,"nm":"blob","ddd":0,
            "assets":[],"layers":[
      lay(1,"face",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(g)}}
                                     for g in art.FACES]+[fill(INK),tr()]}],n),
      lay(2,"belly",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(art.BELLY)}},
                                      fill(MINT),tr()]}],n),
      lay(3,"slime",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":1,"k":kf}},fill(GREEN),tr()]}],n),
      NULL]}

if __name__ == "__main__":
    import sys
    POSES = [(0,1.0), (52,1.18), (86,1.34), (66,1.30)]
    paths = [silhouette(degL=d, reachL=r) for d, r in POSES]
    render.render(scene(paths), "blobstill", list(range(len(POSES))), cols=4, tile=(590,415))
    render.tiles("blobstill", list(range(len(POSES))), cols=4, tile=(590,415))
    print("poses:", POSES)
