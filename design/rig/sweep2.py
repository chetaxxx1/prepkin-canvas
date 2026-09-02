import json, time
import rig, metrics
POSES = [45, 70, 95, 120]; REACH = 1.25

def evaluate(name, P):
    rest = rig.silhouette(P=P)
    r = {"name": name, "P": P, "rest_xor": round(metrics.art_xor(rest), 2),
         "rest_concav": round(metrics.side_concavity(rest), 1),
         "bad": 0, "depth": 0.0, "area": 0, "gap": 0.0, "per": []}
    for dg in POSES:
        p = rig.silhouette(degL=dg, reachL=REACH, degR=-0.16*dg, P=P)
        t = metrics.topology(p); n = metrics.notch(p); u = metrics.underarm(p)
        if t["components"] != 1 or t["holes"] != 0: r["bad"] += 1
        r["depth"] = max(r["depth"], n["depth"]); r["area"] += n["area"]
        r["gap"] = max(r["gap"], u["gap_px"])
        r["per"].append({"deg": dg, "depth": n["depth"], "area": n["area"],
                         "gap": u["gap_px"], "comp": t["components"],
                         "holes": t["holes"], "bbox": [round(v) for v in t["bbox"]]})
    return r

CONFIGS = [("base", {})]
for p in (0.35, 0.55, 0.75, 0.95):
    CONFIGS.append(("pit%.2f" % p, {"pit": p}))
for pr in (0.65, 1.10):
    CONFIGS.append(("pit0.75_r%.2f" % pr, {"pit": 0.75, "pit_r": pr}))
for kp in (70.0, 150.0):
    CONFIGS.append(("pit0.75_kp%d" % kp, {"pit": 0.75, "k_pit": kp}))
CONFIGS += [("pit0.75+kb180", {"pit": 0.75, "kboost": 180.0}),
            ("pit0.95+kb180", {"pit": 0.95, "kboost": 180.0}),
            ("pit0.95+kb240", {"pit": 0.95, "kboost": 240.0})]

if __name__ == "__main__":
    t0 = time.time(); out = []
    print("%-16s restXOR restCcv  maxDepth  sumArea  maxGap  bad" % "config")
    for nm, P in CONFIGS:
        r = evaluate(nm, P); out.append(r)
        print("%-16s %6.2f%% %6.1f  %8.1f %8d %7.1f %4d" % (
            nm, r["rest_xor"], r["rest_concav"], r["depth"], r["area"],
            r["gap"], r["bad"]), flush=True)
    json.dump(out, open("sweep2.json", "w"), indent=1)
    print("%.0fs" % (time.time()-t0))
