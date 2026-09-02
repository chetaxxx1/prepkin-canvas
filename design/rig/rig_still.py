"""Rig-ready model sheet: torso with clean flanks + two drawn arms behind it."""
import math, json, armart, art, render, limb

B = art.BODY
def _s(i): return (B[i][0], B[i][1])
def _e(i): return (B[i][6], B[i][7])
def _curve8(a, b, bow):
    dx, dy = b[0]-a[0], b[1]-a[1]
    n = math.hypot(dx, dy) or 1
    nx, ny = -dy/n, dx/n
    return [a[0],a[1], a[0]+dx/3+nx*bow, a[1]+dy/3+ny*bow,
            a[0]+2*dx/3+nx*bow, a[1]+2*dy/3+ny*bow, b[0],b[1]]

# torso: the approved path with BOTH mitten lobes replaced by a clean flank,
# because the arms are now their own pieces sitting behind it
TORSO, i = [], 0
while i < 41:
    if i == 10: TORSO.append(_curve8(_s(10), _s(17), -5.0)); i = 17; continue
    if i == 28: TORSO.append(_curve8(_s(28), _s(34), -7.0)); i = 34; continue
    TORSO.append(B[i]); i += 1

PIV_L = (165.0, 470.0)          # left shoulder, inside the torso
PIV_R = (721.0, 470.0)          # mirrored
REST_L, REST_R = 147.0, 33.0    # rest: arms hang along the sides.
# raising the LEFT arm means turning past 180 (straight out) toward 215 (up-left)

armart.LEN = 155.0
armart.ARM_LOCAL = armart.outline(length=155.0)

def mirror(segs):
    # mirror about the art centre AND reverse direction, so winding is kept
    return [[886.0-g[6], g[7], 886.0-g[4], g[5], 886.0-g[2], g[3], 886.0-g[0], g[1]]
            for g in reversed(segs)]

def left(deg, stretch=1.0):
    return armart.place(PIV_L, deg, segs=armart.outline(length=155.0*stretch))
def right(deg, stretch=1.0):
    return mirror(armart.place(PIV_L, 180.0-deg, segs=armart.outline(length=155.0*stretch)))

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

def scene(poses):
    """poses: list of (leftDeg, rightDeg, stretchL)"""
    n = len(poses)
    def kf(fn):
        return [{"t":i,"s":[art.to_lottie(fn(*p))],"h":1} for i,p in enumerate(poses)]
    NULL={"ddd":0,"ind":99,"ty":3,"nm":"root","sr":1,
          "ks":{"o":{"a":0,"k":0},"r":{"a":0,"k":0},"p":{"a":0,"k":[660,817]},
                "a":{"a":0,"k":[443,795]},"s":{"a":0,"k":[100,100,100]}},
          "ao":0,"ip":0,"op":n,"st":0}
    return {"v":"5.7.1","fr":30,"ip":0,"op":n,"w":W,"h":H,"nm":"rig","ddd":0,"assets":[],
      "layers":[
        lay(1,"face",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(g)}}
                                       for g in art.FACES]+[fill(INK),tr()]}],n),
        lay(2,"belly",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(art.BELLY)}},
                                        fill(MINT),tr()]}],n),
        lay(3,"torso",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(TORSO)}},
                                        fill(GREEN),tr()]}],n),
        lay(4,"armR",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":1,"k":kf(lambda l,r,st: right(r))}},
                                       fill(GREEN),tr()]}],n),
        lay(5,"armL",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":1,"k":kf(lambda l,r,st: left(l,st))}},
                                       fill(GREEN),tr()]}],n),
        NULL]}

if __name__ == "__main__":
    poses = [(REST_L, REST_R, 1.0),      # rest
             (190.0, REST_R, 1.22),      # arm out
             (218.0, REST_R, 1.34),      # wave, high
             (200.0, REST_R, 1.30)]      # wave, low
    render.render(scene(poses), "rigstill", list(range(len(poses))), cols=3, tile=(590,415))
    render.tiles("rigstill", list(range(len(poses))), cols=3, tile=(590,415))
    print("rendered", len(poses), "poses")
