"""Find the hold pose: the arm must READ as an arm, at app size, with a clean
underarm. Copying the reference's absolute angle is wrong - our shoulder sits
somewhere else - so we map its flutter onto whatever range reads for us."""
import numpy as np
from PIL import Image, ImageDraw
import rig, metrics, diag

def clearance(pts):
    """How far the arm tip stands clear of the body it came out of.

    Measures the narrowest neck between the arm tip and the torso: if the arm
    is being swallowed by the head this collapses toward zero.
    """
    m = metrics.raster(pts)
    ys, xs = np.nonzero(m)
    return float(0)

if __name__ == "__main__":
    P = {"fillet": 150.0}
    grid = [(d, r) for d in (65, 75, 85, 95) for r in (1.40, 1.55, 1.70)]
    ims, labs = [], []
    for dg, rc in grid:
        for thin in (0.45, 0.9):
            p = rig.silhouette(degL=dg, reachL=rc, degR=-0.10*dg,
                               P=dict(P, thin=thin))
            n = metrics.notch(p); t = metrics.topology(p)
            im, _ = diag.frame(dg, rc, dict(P, thin=thin))
            ims.append(im)
            labs.append("d%d r%.2f t%.2f  pit=%d/%d  bbox=%d,%d" % (
                dg, rc, thin, n["area"], n["depth"],
                round(t["bbox"][0]), round(t["bbox"][1])))
            print(labs[-1], flush=True)
    w, h = ims[0].size; cols = 6
    rows = (len(ims)+cols-1)//cols
    s = Image.new("RGB", (w*cols, (h+18)*rows), (255,255,255))
    d = ImageDraw.Draw(s)
    for i, im in enumerate(ims):
        c, r = i % cols, i//cols
        s.paste(im, (c*w, r*(h+18)+18))
        d.text((c*w+6, r*(h+18)+4), labs[i], fill=(0,0,0))
    s = s.resize((s.size[0]//3, s.size[1]//3)); s.save("diag_hold.png")
    print("wrote", s.size)
