import numpy as np
from PIL import Image, ImageDraw
import rig, metrics, diag
CASES=[]
for dg in (110,128,145):
    for r_up,bow in ((34.0,0.0),(34.0,0.14),(44.0,0.0),(44.0,0.14)):
        CASES.append((dg,1.65,{"fillet":80.0,"r_up":r_up,"bow":bow},
                      "r%.0f b%.2f"%(r_up,bow)))
ims,labs=[],[]
for dg,rc,P,tag in CASES:
    p=rig.silhouette(degL=dg,reachL=rc,degR=-0.10*dg,P=P)
    s=metrics.slot(p); t=metrics.topology(p); n=metrics.notch(p)
    im,_=diag.frame(dg,rc,P); ims.append(im)
    labs.append("%s d%d slot med%.0f max%.0f rows%d  pit%d/%d c%d h%d"%(
        tag,dg,s["med"],s["max"],s["rows"],n["area"],n["depth"],t["components"],t["holes"]))
    print(labs[-1],flush=True)
w,h=ims[0].size; cols=4; rows=(len(ims)+cols-1)//cols
sh=Image.new("RGB",(w*cols,(h+20)*rows),(255,255,255)); d=ImageDraw.Draw(sh)
for i,im in enumerate(ims):
    c,r=i%cols,i//cols; sh.paste(im,(c*w,r*(h+20)+20)); d.text((c*w+6,r*(h+20)+5),labs[i],fill=(0,0,0))
sh=sh.resize((sh.size[0]//3,sh.size[1]//3)); sh.save("diag_cres.png"); print("wrote",sh.size)
