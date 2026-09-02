import numpy as np
from PIL import Image, ImageDraw
import rig, metrics, diag, field
CASES=[]
for dg,rc in ((95,2.4),(105,2.4)):
    for hug in (0.0,0.35,0.65):
        for bow in (0.10,0.25):
            CASES.append((dg,rc,{"fillet":80.0,"r_up":44.0,"hug":hug,"bow":bow},
                          "hug%.2f bow%.2f"%(hug,bow)))
ims,thumbs,labs=[],[],[]
for dg,rc,P,tag in CASES:
    p=rig.silhouette(degL=dg,reachL=rc,degR=-0.10*dg,P=P)
    n=metrics.notch(p); t=metrics.topology(p)
    im,_=diag.frame(dg,rc,P); ims.append(im)
    th=Image.new("RGB",(field.W,field.H),(255,255,255))
    ImageDraw.Draw(th).polygon([((q[0]+field.PAD)*field.SS,(q[1]+field.PAD)*field.SS) for q in p],
                               fill=(81,207,160))
    thumbs.append(th.resize((int(field.W*110/field.H),110)))
    labs.append("d%d r%.1f %s slotW=%d area=%d c%d h%d"%(dg,rc,tag,n["depth"],n["area"],
                                                          t["components"],t["holes"]))
    print(labs[-1],flush=True)
w,h=ims[0].size; cols=6
sh=Image.new("RGB",(w*cols,(h+22)*2),(255,255,255)); d=ImageDraw.Draw(sh)
for i,im in enumerate(ims):
    c,r=i%cols,i//cols; sh.paste(im,(c*w,r*(h+22)+22)); d.text((c*w+8,r*(h+22)+6),labs[i],fill=(0,0,0))
sh.resize((sh.size[0]//3,sh.size[1]//3)).save("diag_hug.png")
tw,th_=thumbs[0].size
strip=Image.new("RGB",(tw*6,(th_+14)*2),(255,255,255)); dd=ImageDraw.Draw(strip)
for i,t2 in enumerate(thumbs):
    c,r=i%6,i//6; strip.paste(t2,(c*tw,r*(th_+14)+14)); dd.text((c*tw+3,r*(th_+14)+2),labs[i][:26],fill=(0,0,0))
strip.save("diag_hug_small.png"); print("done")
