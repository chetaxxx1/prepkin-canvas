import numpy as np
from PIL import Image, ImageDraw
import rig, metrics, field

BASE = dict(r_up=44.0, hug=0.65, bow=0.10, k_up=26.0)
def shot(fil):
    P = dict(BASE, fillet=fil)
    p = rig.silhouette(degL=105, reachL=2.4, degR=-10.5, P=P)
    im = Image.new("RGB", (field.W, field.H), (255,255,255))
    ImageDraw.Draw(im).polygon(
        [((q[0]+field.PAD)*field.SS, (q[1]+field.PAD)*field.SS) for q in p], fill=(81,207,160))
    return p, im

out, labs = [], []
for fil in (0.0, 80.0, 130.0, 180.0):
    p, im = shot(fil)
    fr = metrics.fillet_radius(p); n = metrics.notch(p); t = metrics.topology(p)
    labs.append("fillet=%.0f -> achieved r=%.0f px   pocket=%d  c%d h%d"
                % (fil, fr, n["area"], t["components"], t["holes"]))
    print(labs[-1], flush=True)
    # crop the armpit: art x -60..360, y 320..760
    box = [int((-60+field.PAD)*field.SS), int((320+field.PAD)*field.SS),
           int((360+field.PAD)*field.SS), int((760+field.PAD)*field.SS)]
    out.append(im.crop(box).resize((420, 440)))
s = Image.new("RGB", (420*4, 460), (255,255,255)); d = ImageDraw.Draw(s)
for i, im in enumerate(out):
    s.paste(im, (i*420, 20)); d.text((i*420+6, 5), labs[i], fill=(0,0,0))
s.save("zoom_armpit.png"); print("wrote zoom_armpit.png")
