import numpy as np
from PIL import Image, ImageDraw
import rig, curve, metrics, smoothness, still, field
CASES=[]
for rc in (2.4,2.9):
    for ru in (40.0,52.0):
        for ku in (26.0,42.0):
            CASES.append((110,rc,{"k_up":ku,"root_up":ru,"tip_up":8.0,"taper":1.0,
                                  "bow":-0.12,"hug":0.0,"fillet":70.0,"fil_base":0.35},
                          "r%.1f root%.0f k%.0f"%(rc,ru,ku)))
paths,labs,thumbs=[],[],[]
for dg,rc,P,tag in CASES:
    p=rig.silhouette(degL=dg,reachL=rc,degR=-4.0,P=P,n_pts=72,sigma=22.0)
    sc=smoothness.score3(curve.to_bezier(p)); t=metrics.topology(p)
    paths.append(p); labs.append("%s inf%d ccv%s"%(tag,sc["inflections_body"],sc["min_r_concave"]))
    th=Image.new("RGB",(field.W,field.H),(255,255,255))
    ImageDraw.Draw(th).polygon([((q[0]+field.PAD)*field.SS,(q[1]+field.PAD)*field.SS) for q in p],fill=(81,207,160))
    thumbs.append(th.resize((int(field.W*104/field.H),104)))
    print(labs[-1],flush=True)
still.render(paths,"fin2",cols=4,scale=0.46)
tw,th_=thumbs[0].size
strip=Image.new("RGB",(tw*4,(th_+14)*2),(255,255,255)); dd=ImageDraw.Draw(strip)
for i,t2 in enumerate(thumbs):
    c,r=i%4,i//4; strip.paste(t2,(c*tw,r*(th_+14)+14)); dd.text((c*tw+3,r*(th_+14)+2),labs[i][:22],fill=(0,0,0))
strip.save("fin2_small.png")
