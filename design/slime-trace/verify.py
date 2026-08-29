#!/usr/bin/env python3
"""Rasterize fitted beziers and diff against the source masks."""
import json
import numpy as np
from PIL import Image, ImageDraw
from trace import load, color_mask, bbox_of, BODY, BELLY, INK
from scipy import ndimage

SCRATCH = "/private/tmp/claude-501/-Users-georgeshi-Desktop-app-prepkin-canvas/8e386b9b-4386-4450-acc7-6b9b7ff1db2a/scratchpad"

res = json.load(open(f"{SCRATCH}/trace_result.json"))


def bez_points(seg, n=30):
    p0, c1, c2, p3 = [np.array(p) for p in seg]
    t = np.linspace(0, 1, n)[:, None]
    return ((1 - t) ** 3) * p0 + 3 * ((1 - t) ** 2) * t * c1 + 3 * (1 - t) * t ** 2 * c2 + t ** 3 * p3


def rasterize(segs, box, shape):
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    pts = np.concatenate([bez_points(s)[:-1] for s in segs])
    pts = pts * [w, h] + [x0, y0]
    img = Image.new("L", (shape[1], shape[0]), 0)
    d = ImageDraw.Draw(img)
    d.polygon([tuple(p) for p in pts], fill=255)
    return np.array(img) > 128


def report(name, fitted, truth):
    inter = (fitted & truth).sum()
    union = (fitted | truth).sum()
    sym = (fitted ^ truth)
    # max boundary deviation: distance transform of truth edges
    dt_in = ndimage.distance_transform_edt(truth)
    dt_out = ndimage.distance_transform_edt(~truth)
    dev = np.where(truth, dt_in, dt_out)[sym]
    maxdev = dev.max() if sym.any() else 0
    print(f"{name}: IoU={inter/union:.5f}  sym-diff px={sym.sum()}  max deviation={maxdev:.1f}px")


a = load("/Users/georgeshi/Desktop/mascot/slime-handoff/mascot-idle.png")
green = color_mask(a, BODY)
belly = color_mask(a, BELLY)
ink = color_mask(a, INK, tol=90)
sil = ndimage.binary_fill_holes(green | belly | ink)
box = bbox_of(sil)
shape = a.shape[:2]

report("body", rasterize(res["body"], box, shape), sil)
report("belly", rasterize(res["belly"], box, shape), belly)

# idle face comps
lab, n = ndimage.label(ink)
for i, comp in enumerate(res["idle_face"]):
    fit = rasterize(comp["segs"], box, shape)
    # find matching truth comp: nearest label at comp center
    x0, y0, x1, y1 = box
    cx = comp["cx"] * (x1 - x0) + x0
    cy = comp["cy"] * (y1 - y0) + y0
    li = lab[int(cy), int(cx)]
    truth = lab == li
    report(f"idle ink {i}", fit, truth)
