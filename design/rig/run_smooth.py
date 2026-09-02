import numpy as np, rig, curve, metrics, smoothness
print("%-18s %-9s %-8s %-8s %-8s"%("cfg","inflect","minR","ripple","restXOR"))
for sig in (10.0, 22.0, 34.0, 48.0):
    for n in (72, 96):
        p = rig.silhouette(P={"fillet":110.0,"k_up":22.0,"r_up":44.0,
                              "bow":0.10,"hug":0.65}, n_pts=n, sigma=sig)
        bz = curve.to_bezier(p)
        sc = smoothness.score(bz)
        print("%-18s %-9d %-8.1f %-8.1f %.2f%%"%(
            "rest s%.0f n%d"%(sig,n), sc["inflections"], sc["min_radius"],
            sc["ripple"], metrics.art_xor(p)), flush=True)
