import rig, curve, metrics, smoothness
print("%-20s %-8s %-9s %-9s %-8s %-8s"%("cfg","inflect","minR_cvx","minR_ccv","ripple","restXOR"))
for R in (60.0, 110.0):
    for b in (0.0, 0.5, 1.0):
        P={"fillet":R,"fil_base":b,"k_up":22.0,"r_up":44.0,"bow":0.10,"hug":0.65}
        p=rig.silhouette(P=P, n_pts=72, sigma=22.0)
        sc=smoothness.score2(curve.to_bezier(p))
        print("%-20s %-8d %-9s %-9s %-8.0f %.2f%%"%(
            "rest R%.0f base%.1f"%(R,b), sc["inflections"], sc["min_r_convex"],
            sc["min_r_concave"], sc["ripple"], metrics.art_xor(p)), flush=True)
