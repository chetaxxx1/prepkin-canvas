import rig, curve, metrics, smoothness, still
OPTS=[("1 keep mittens (matches art)", {"fillet":110.0,"fil_base":0.0}),
      ("2 softened",                    {"fillet":70.0,"fil_base":0.55}),
      ("3 smooth blob",                 {"fillet":110.0,"fil_base":1.0})]
paths=[]
for tag,ex in OPTS:
    P=dict({"k_up":22.0,"r_up":44.0,"bow":0.10,"hug":0.65}, **ex)
    for dg,rc,fd in ((0,1.0,0.0),(104,2.4,-4.0)):
        p=rig.silhouette(degL=dg,reachL=rc,degR=fd,P=P,n_pts=72,sigma=22.0)
        paths.append(p)
        sc=smoothness.score3(curve.to_bezier(p))
        print("%-30s %-5s inflect=%d  minR concave=%s convex=%s  XOR=%.2f%%"%(
            tag,"rest" if dg==0 else "hold",sc["inflections_body"],
            sc["min_r_concave"],sc["min_r_convex"],
            metrics.art_xor(p) if dg==0 else 0), flush=True)
still.render(paths,"opts",cols=2,scale=0.66)
