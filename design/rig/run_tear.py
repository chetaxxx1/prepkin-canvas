import numpy as np
from PIL import Image, ImageDraw
import rig, curve, metrics, smoothness, still, field
BASE={"k_up":22.0,"fillet":70.0,"fil_base":0.55,"hug":0.35,"bow":-0.10,
      "tip_up":44.0,"taper":1.3}
CASES=[]
for dg in (70,85,100):
    for rc in (1.55,1.80):
        for ru in (66.0,80.0):
            CASES.append((dg,rc,dict(BASE,root_up=ru),"d%d r%.2f root%.0f"%(dg,rc,ru)))
paths,labs,thumbs=[],[],[]
for dg,rc,P,tag in CASES:
    p=rig.silhouette(degL=dg,reachL=rc,degR=-4.0,P=P,n_pts=72,sigma=22.0)
    sc=smoothness.score3(curve.to_bezier(p)); t=metrics.topology(p)
    paths.append(p); labs.append("%s inf%d ccv%s c%d h%d"%(tag,sc["inflections_body"],
                                 sc["min_r_concave"],t["components"],t["holes"]))
    th=Image.new("RGB",(field.W,field.H),(255,255,255))
    ImageDraw.Draw(th).polygon([((q[0]+field.PAD)*field.SS,(q[1]+field.PAD)*field.SS) for q in p],fill=(81,207,160))
    thumbs.append(th.resize((int(field.W*104/field.H),104)))
    print(labs[-1],flush=True)
still.render(paths,"tear",cols=4,scale=0.42)
tw,th_=thumbs[0].size
strip=Image.new("RGB",(tw*4,(th_+14)*3),(255,255,255)); dd=ImageDraw.Draw(strip)
for i,t2 in enumerate(thumbs):
    c,r=i%4,i//4; strip.paste(t2,(c*tw,r*(th_+14)+14)); dd.text((c*tw+3,r*(th_+14)+2),labs[i][:24],fill=(0,0,0))
strip.save("tear_small.png")
