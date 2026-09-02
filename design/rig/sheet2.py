import sys
import numpy as np
from PIL import Image, ImageDraw
import rig, metrics, diag

def grid(cases, out, cols=6, scale=3):
    ims, labs = [], []
    for dg, rc, P, tag in cases:
        im, n = diag.frame(dg, rc, P)
        t = metrics.topology(rig.silhouette(degL=dg, reachL=rc, degR=-0.10*dg, P=P))
        ims.append(im)
        labs.append("%s d%d r%.2f  pit %d/%d  comp%d h%d  x%d" % (
            tag, dg, rc, n["area"], n["depth"], t["components"], t["holes"],
            round(t["bbox"][0])))
        print(labs[-1], flush=True)
    w, h = ims[0].size
    rows = (len(ims)+cols-1)//cols
    s = Image.new("RGB", (w*cols, (h+20)*rows), (255,255,255))
    d = ImageDraw.Draw(s)
    for i, im in enumerate(ims):
        c, r = i % cols, i//cols
        s.paste(im, (c*w, r*(h+20)+20)); d.text((c*w+6, r*(h+20)+5), labs[i], fill=(0,0,0))
    s = s.resize((s.size[0]//scale, s.size[1]//scale)); s.save(out)
    print("wrote", out, s.size)
