"""Sweep the three underarm knobs and MEASURE. No eyeballing at this stage."""
import json, sys, time
import numpy as np
import rig, metrics, art, field

POSES = [45, 70, 95, 120]
REACH = 1.25

def evaluate(name, P):
    rest = rig.silhouette(P=P)
    row = {"name": name, "P": P,
           "rest_xor": round(metrics.art_xor(rest), 2),
           "rest_concav": round(metrics.side_concavity(rest), 1),
           "bad": 0, "depth": 0.0, "area": 0, "gap": 0.0, "per": []}
    for dg in POSES:
        p = rig.silhouette(degL=dg, reachL=REACH, degR=-0.16*dg, P=P)
        t = metrics.topology(p); n = metrics.notch(p); u = metrics.underarm(p)
        if t["components"] != 1 or t["holes"] != 0:
            row["bad"] += 1
        row["depth"] = max(row["depth"], n["depth"])
        row["area"] += n["area"]
        row["gap"] = max(row["gap"], u["gap_px"])
        row["per"].append({"deg": dg, "depth": n["depth"], "area": n["area"],
                           "gap": u["gap_px"], "comp": t["components"],
                           "holes": t["holes"], "bbox": [round(v) for v in t["bbox"]]})
    return row

CONFIGS = [("base", {})]
for b in (0.2, 0.35, 0.5, 0.7, 0.9):
    CONFIGS.append(("bend%.2f" % b, {"bend": b}))
for kb, ks in ((60,80),(120,80),(180,80),(120,120),(180,120),(240,120)):
    CONFIGS.append(("kb%d_s%d" % (kb, ks), {"kboost": float(kb), "ksig": float(ks)}))
for rw, kw in ((20,80),(32,80),(45,80),(32,110),(45,110),(60,110)):
    CONFIGS.append(("web%d_k%d" % (rw, kw),
                    {"web": 1.0, "r_web": float(rw), "k_web": float(kw)}))

if __name__ == "__main__":
    t0 = time.time(); out = []
    print("%-12s restXOR restCcv  maxDepth  sumArea  maxGap  bad" % "config")
    for nm, P in CONFIGS:
        r = evaluate(nm, P); out.append(r)
        print("%-12s %6.2f%% %6.1f  %8.1f %8d %7.1f %4d" % (
            nm, r["rest_xor"], r["rest_concav"], r["depth"], r["area"],
            r["gap"], r["bad"]), flush=True)
    json.dump(out, open("sweep1.json", "w"), indent=1)
    print("%.0fs" % (time.time()-t0))
