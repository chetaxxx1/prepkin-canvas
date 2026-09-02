import rig, curve, smoothness, still
CFG=[("A base0 R110",{"fillet":110.0,"fil_base":0.0}),
     ("B base1 R60",{"fillet":60.0,"fil_base":1.0}),
     ("C base1 R110",{"fillet":110.0,"fil_base":1.0}),
     ("D base1 R110 k34",{"fillet":110.0,"fil_base":1.0,"k":34.0})]
paths=[]
for tag,ex in CFG:
    P=dict({"k_up":22.0,"r_up":44.0,"bow":0.10,"hug":0.65}, **ex)
    for dg,rc in ((0,1.0),(104,2.4)):
        p=rig.silhouette(degL=dg,reachL=rc,degR=-4.0 if dg else 0.0,P=P,n_pts=72,sigma=22.0)
        paths.append(p)
        print("%-18s %s %s"%(tag,"rest" if dg==0 else "hold",
                             smoothness.score3(curve.to_bezier(p))), flush=True)
still.render(paths,"look",cols=2,scale=0.62)
print("done")
