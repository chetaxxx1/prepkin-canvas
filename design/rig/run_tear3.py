import numpy as np
from PIL import Image, ImageDraw
import rig, curve, metrics, smoothness, still, field
CASES=[]
for ku in (12.0,20.0):
    for ru,tu in ((46.0,58.0),(56.0,66.0),(40.0,52.0)):
        for dg,rc in ((110,2.1),):
            CASES.append((dg,rc,{"k_up":ku,"fillet":70.0,"fil_base":0.35,"hug":0.0,
                                 "bow":-0.08,"taper":0.9,"root_up":ru,"tip_up":tu},
                          "kup%.0f root%.0f tip%.0f"%(ku,ru,tu)))
paths,labs,thumbs=[],[],[]
for dg,rc,P,tag in CASES:
    p=rig.silhouette(degL=dg,reachL=rc,degR=-4.0,P=P,n_pts=72,sigma=22.0)
    sc=smoothness.score3(curve.to_bezier(p)); t=metrics.topology(p)
    paths.append(p); labs.append("%s inf%d ccv%s"%(tag,sc["inflections_body"],sc["min_r_concave"]))
    th=Image.new("RGB",(field.W,field.H),(255,255,255))
    ImageDraw.Draw(th).polygon([((q[0]+field.PAD)*field.SS,(q[1]+field.PAD)*field.SS) for q in p],fill=(81,207,160))
    thumbs.append(th.resize((int(field.W*104/field.H),104)))
    print(labs[-1],flush=True)
still.render(paths,"tear3",cols=3,scale=0.5)
tw,th_=thumbs[0].size
strip=Image.new("RGB",(tw*3,(th_+14)*2),(255,255,255)); dd=ImageDraw.Draw(strip)
for i,t2 in enumerate(thumbs):
    c,r=i%3,i//3; strip.paste(t2,(c*tw,r*(th_+14)+14)); dd.text((c*tw+3,r*(th_+14)+2),labs[i][:24],fill=(0,0,0))
strip.save("tear3_small.png")
