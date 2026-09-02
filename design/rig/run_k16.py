import numpy as np
from PIL import Image, ImageDraw
import rig, metrics, diag, field
print("fit:", rig.SH_L, rig.REST_L, rig.R_SH, rig.R_PAW, rig.P0["k"])
CASES=[]
for kup in (16.0, 26.0):
    for fil in (80.0, 130.0):
        CASES.append((104,2.4,{"k_up":kup,"fillet":fil,"r_up":44.0,"hug":0.65,"bow":0.10},
                      "kup%.0f fil%.0f"%(kup,fil)))
CASES.append((0,1.0,{"k_up":22.0,"fillet":80.0,"r_up":44.0,"hug":0.65,"bow":0.10},"REST"))
CASES.append((50,1.7,{"k_up":22.0,"fillet":80.0,"r_up":44.0,"hug":0.65,"bow":0.10},"mid"))
ims,labs=[],[]
for dg,rc,P,tag in CASES:
    p=rig.silhouette(degL=dg,reachL=rc,degR=-0.10*dg,P=P)
    t=metrics.topology(p); n=metrics.notch(p)
    lab="%s d%d r%.1f XOR=%.2f%% cvL=%.0f slotW=%d filR=%d c%d h%d"%(
        tag,dg,rc,metrics.art_xor(p),metrics.side_concavity(p),n["depth"],
        metrics.fillet_radius(p),t["components"],t["holes"])
    im,_=diag.frame(dg,rc,P); ims.append(im); labs.append(lab); print(lab,flush=True)
w,h=ims[0].size; cols=3
rows=(len(ims)+cols-1)//cols
s=Image.new("RGB",(w*cols,(h+20)*rows),(255,255,255)); d=ImageDraw.Draw(s)
for i,im in enumerate(ims):
    c,r=i%cols,i//cols; s.paste(im,(c*w,r*(h+20)+20)); d.text((c*w+6,r*(h+20)+5),labs[i],fill=(0,0,0))
s.resize((s.size[0]//3,s.size[1]//3)).save("diag_k16.png"); print("ok")
