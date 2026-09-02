import numpy as np
from PIL import Image, ImageDraw
import rig, metrics, diag, field
CASES=[]
for dg in (95,110):
    for rc in (2.0,2.4,2.8):
        for r_up in (40.0,48.0):
            CASES.append((dg,rc,{"fillet":80.0,"r_up":r_up,"bow":0.24},"r_up%.0f"%r_up))
ims,thumbs,labs=[],[],[]
for dg,rc,P,tag in CASES:
    p=rig.silhouette(degL=dg,reachL=rc,degR=-0.10*dg,P=P)
    n=metrics.notch(p); t=metrics.topology(p)
    im,_=diag.frame(dg,rc,P); ims.append(im)
    th=Image.new("RGB",(field.W,field.H),(255,255,255))
    ImageDraw.Draw(th).polygon([((q[0]+field.PAD)*field.SS,(q[1]+field.PAD)*field.SS) for q in p],
                               fill=(81,207,160))
    thumbs.append(th.resize((int(field.W*110/field.H),110)))
    labs.append("d%d r%.1f %s slotW=%d area=%d c%d h%d bbox=%d,%d"%(
        dg,rc,tag,n["depth"],n["area"],t["components"],t["holes"],
        round(t["bbox"][0]),round(t["bbox"][1])))
    print(labs[-1],flush=True)
w,h=ims[0].size; cols=6; rows=2
sh=Image.new("RGB",(w*cols,(h+22)*rows),(255,255,255)); d=ImageDraw.Draw(sh)
for i,im in enumerate(ims):
    c,r=i%cols,i//cols; sh.paste(im,(c*w,r*(h+22)+22)); d.text((c*w+8,r*(h+22)+6),labs[i],fill=(0,0,0))
sh=sh.resize((sh.size[0]//3,sh.size[1]//3)); sh.save("diag_long.png")
tw,th_=thumbs[0].size
strip=Image.new("RGB",(tw*6,(th_+14)*2),(255,255,255)); dd=ImageDraw.Draw(strip)
for i,t2 in enumerate(thumbs):
    c,r=i%6,i//6; strip.paste(t2,(c*tw,r*(th_+14)+14)); dd.text((c*tw+3,r*(th_+14)+2),labs[i][:26],fill=(0,0,0))
strip.save("diag_long_small.png"); print("wrote",sh.size,strip.size)
