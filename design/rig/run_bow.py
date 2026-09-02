import numpy as np
from PIL import Image, ImageDraw
import rig, metrics, diag, field
CASES=[]
for dg in (105,115,125):
    for bow in (0.14,0.24,0.34):
        CASES.append((dg,1.65,{"fillet":80.0,"r_up":34.0,"bow":bow},"bow%.2f"%bow))
ims,thumbs,labs=[],[],[]
for dg,rc,P,tag in CASES:
    p=rig.silhouette(degL=dg,reachL=rc,degR=-0.10*dg,P=P)
    n=metrics.notch(p); t=metrics.topology(p)
    im,_=diag.frame(dg,rc,P)
    ims.append(im)
    # app size: 96 px tall, plain fill, no guides - the read test
    th=Image.new("RGB",(field.W,field.H),(255,255,255))
    ImageDraw.Draw(th).polygon([((q[0]+field.PAD)*field.SS,(q[1]+field.PAD)*field.SS) for q in p],
                               fill=(81,207,160))
    thumbs.append(th.resize((int(field.W*96/field.H),96)))
    labs.append("%s d%d slotW=%d area=%d c%d h%d"%(tag,dg,n["depth"],n["area"],
                                                   t["components"],t["holes"]))
    print(labs[-1],flush=True)
w,h=ims[0].size; cols=3; rows=3
sh=Image.new("RGB",(w*cols,(h+22)*rows),(255,255,255)); d=ImageDraw.Draw(sh)
for i,im in enumerate(ims):
    c,r=i%cols,i//cols; sh.paste(im,(c*w,r*(h+22)+22)); d.text((c*w+8,r*(h+22)+6),labs[i],fill=(0,0,0))
sh=sh.resize((sh.size[0]*4//9,sh.size[1]*4//9)); sh.save("diag_bow.png")
tw,th_=thumbs[0].size
strip=Image.new("RGB",(tw*len(thumbs),th_+14),(255,255,255)); dd=ImageDraw.Draw(strip)
for i,t2 in enumerate(thumbs):
    strip.paste(t2,(i*tw,14)); dd.text((i*tw+4,2),labs[i][:22],fill=(0,0,0))
strip.save("diag_bow_small.png")
print("wrote",sh.size,strip.size)
