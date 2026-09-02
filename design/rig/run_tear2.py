import numpy as np
from PIL import Image, ImageDraw
import rig, curve, metrics, smoothness, still, field
for fb in (0.0,0.35,0.55):
    p=rig.silhouette(P={"fillet":70.0,"fil_base":fb},n_pts=72,sigma=22.0)
    print("rest fil_base=%.2f  XOR=%.2f%%  %s"%(fb,metrics.art_xor(p),
          smoothness.score3(curve.to_bezier(p))), flush=True)
BASE={"k_up":26.0,"fillet":70.0,"fil_base":0.35,"hug":0.0,"bow":-0.08,"taper":0.9}
CASES=[]
for dg in (75,95,115):
    for rc in (1.9,2.3):
        for ru,tu in ((66.0,50.0),(84.0,58.0)):
            CASES.append((dg,rc,dict(BASE,root_up=ru,tip_up=tu),
                          "d%d r%.1f root%.0f tip%.0f"%(dg,rc,ru,tu)))
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
still.render(paths,"tear2",cols=4,scale=0.42)
tw,th_=thumbs[0].size
strip=Image.new("RGB",(tw*4,(th_+14)*3),(255,255,255)); dd=ImageDraw.Draw(strip)
for i,t2 in enumerate(thumbs):
    c,r=i%4,i//4; strip.paste(t2,(c*tw,r*(th_+14)+14)); dd.text((c*tw+3,r*(th_+14)+2),labs[i][:24],fill=(0,0,0))
strip.save("tear2_small.png")
