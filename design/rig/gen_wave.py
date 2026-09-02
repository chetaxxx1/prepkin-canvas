"""Build wave.json and verify EVERY frame before writing it."""
import json, math, time
import numpy as np
import field, art, rig, metrics, wave, curve, smoothness

# The arm is a swept FIN, the way the TFT River Sprite's is: a wide base that
# flares straight out of the body with no neck and no lobe, tapering to a
# point. A narrow neck with a rounded club on the end reads as a limb with a
# joint - this character has neither.
P = dict(k=rig.P0["k"], k_up=26.0, root_up=40.0, tip_up=8.0, taper=1.0,
         bow=-0.12, hug=0.0, fillet=70.0, fil_base=0.35, nseg=12)
NPTS, SIGMA = 72, 22.0
ANC = [443.0, 795.0]
GREEN, MINT, INK = (81,207,160), (177,237,212), (16,24,32)
MARGIN = 34

def posed(pts, b):
    """apply the root null (bob, lean, squash) so we can size the canvas"""
    dx, dy, rot, sx, sy = b
    a = math.radians(rot); c, s = math.cos(a), math.sin(a)
    q = pts - np.array(ANC)
    q = q * np.array([sx/100.0, sy/100.0])
    q = np.stack([q[:,0]*c - q[:,1]*s, q[:,0]*s + q[:,1]*c], 1)
    return q + np.array(ANC) + np.array([dx, dy])

def fill(c): return {"ty":"fl","c":{"a":0,"k":[c[0]/255,c[1]/255,c[2]/255,1]},
                     "o":{"a":0,"k":100},"r":1}
def tr(): return {"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},
                  "s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}
def lay(ind, nm, shapes):
    return {"ddd":0,"ind":ind,"ty":4,"nm":nm,"sr":1,"parent":99,
            "ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[0,0]},
                  "a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]}},
            "ao":0,"shapes":shapes,"ip":0,"op":wave.DUR,"st":0}
EASE = {"o":{"x":[0.38],"y":[0]}, "i":{"x":[0.62],"y":[1]}}
def ease_n(n): return {"o":{"x":[0.38]*n,"y":[0]*n}, "i":{"x":[0.62]*n,"y":[1]*n}}

if __name__ == "__main__":
    t0 = time.time()
    paths, rep, bb = {}, [], None
    for j, f in enumerate(wave.KEYS):
        dg, rc = wave.pose(f)
        fd, fr_ = wave.far(f)
        p = rig.silhouette(degL=dg, reachL=rc, degR=fd, reachR=fr_,
                           P=P, n_pts=NPTS, sigma=SIGMA)
        paths[f] = p
        t = metrics.topology(p); u = metrics.underarm(p)
        row = {"f": f, "deg": round(dg,1), "reach": round(rc,2),
               "comp": t["components"], "holes": t["holes"],
               "gap": u["gap_px"], "bbox": [round(v,1) for v in t["bbox"]]}
        sm = smoothness.score3(curve.to_bezier(p))
        row["inflect"] = sm["inflections_body"]
        row["minR_concave"] = sm["min_r_concave"]
        if j % 8 == 0 or f in (0, wave.DUR-1):
            row["filletR"] = metrics.fillet_radius(p)
            row["slotW"] = metrics.notch(p)["depth"]
        rep.append(row)
        q = posed(p, wave.body(f))
        e = [q[:,0].min(), q[:,1].min(), q[:,0].max(), q[:,1].max()]
        bb = e if bb is None else [min(bb[0],e[0]), min(bb[1],e[1]),
                                   max(bb[2],e[2]), max(bb[3],e[3])]
        print("f%3d deg%6.1f r%.2f comp%d h%d gap%5.1f %s" % (
            f, dg, rc, t["components"], t["holes"], u["gap_px"],
            ("inflect=%d minRccv=%s %s" % (row["inflect"], row["minR_concave"],
             ("filletR=%s" % row.get("filletR")) if "filletR" in row else ""))),
            flush=True)

    W = int(math.ceil(bb[2]-bb[0]) + 2*MARGIN)
    H = int(math.ceil(bb[3]-bb[1]) + 2*MARGIN)
    OFF = [ANC[0] - bb[0] + MARGIN, ANC[1] - bb[1] + MARGIN]
    print("posed bbox", [round(v,1) for v in bb], "-> canvas", W, H, "off", OFF)

    kfs = [{"t": f, "s": [curve.to_bezier(paths[f])], **EASE} for f in wave.KEYS]
    pk, rk, sk = [], [], []
    for f in wave.KEYS:
        dx, dy, rot, sx, sy = wave.body(f)
        pk.append({"t": f, "s": [OFF[0]+dx, OFF[1]+dy, 0], **ease_n(3)})
        rk.append({"t": f, "s": [rot], **EASE})
        sk.append({"t": f, "s": [sx, sy, 100], **ease_n(3)})
    NULL = {"ddd":0,"ind":99,"ty":3,"nm":"root","sr":1,
            "ks":{"o":{"a":0,"k":0},"r":{"a":1,"k":rk},"p":{"a":1,"k":pk},
                  "a":{"a":0,"k":ANC+[0]},"s":{"a":1,"k":sk}},
            "ao":0,"ip":0,"op":wave.DUR,"st":0}
    doc = {"v":"5.7.1","fr":wave.FR,"ip":0,"op":wave.DUR,"w":W,"h":H,
           "nm":"SlimeWave","ddd":0,"assets":[],"layers":[
      lay(1,"face",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(g)}}
                                     for g in art.FACES]+[fill(INK),tr()]}]),
      lay(2,"belly",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(art.BELLY)}},
                                      fill(MINT),tr()]}]),
      lay(3,"slime",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":1,"k":kfs}},fill(GREEN),tr()]}]),
      NULL]}

    # ---- Lottie sanity: a keyframe past op is silently dropped, and then the
    # animation never comes back to rest. Check the ends explicitly.
    bad = [k["t"] for k in kfs if k["t"] >= wave.DUR or k["t"] < 0]
    assert not bad, "keyframes outside the comp: %s" % bad
    assert kfs[0]["t"] == 0 and kfs[-1]["t"] == wave.DUR-1, "ends not pinned"
    assert all(len(k["s"][0]["v"]) == NPTS for k in kfs), "vertex count varies"
    v0 = np.array([k["s"][0]["v"][0] for k in kfs])
    print("start-vertex drift: max %.1f px" % np.abs(np.diff(v0, axis=0)).max())
    rest_delta = float(np.abs(np.array(kfs[0]["s"][0]["v"]) -
                              np.array(kfs[-1]["s"][0]["v"])).max())
    print("first vs last frame: max vertex delta %.1f px" % rest_delta)

    open("wave.json","w").write(json.dumps(doc))
    json.dump(rep, open("wave_report.json","w"), indent=1)
    print("wrote wave.json  %d keyframes  %d bytes  %.0fs"
          % (len(kfs), len(json.dumps(doc)), time.time()-t0))
