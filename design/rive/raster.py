"""Fast local rasteriser so we can score shapes without a browser."""
import numpy as np, math
from PIL import Image, ImageDraw

W, H = 1010, 830
OFFX, OFFY = 87.0, 22.0          # art -> canvas

def flatten(segs, n=14):
    pts = []
    for s in segs:
        for i in range(n):
            t = i / n
            x = (1-t)**3*s[0] + 3*(1-t)**2*t*s[2] + 3*(1-t)*t*t*s[4] + t**3*s[6]
            y = (1-t)**3*s[1] + 3*(1-t)**2*t*s[3] + 3*(1-t)*t*t*s[5] + t**3*s[7]
            pts.append((x + OFFX, y + OFFY))
    return pts

def mask(*shapes):
    im = Image.new("1", (W, H), 0)
    d = ImageDraw.Draw(im)
    for segs in shapes:
        d.polygon(flatten(segs), fill=1)
    return np.asarray(im, dtype=bool)
