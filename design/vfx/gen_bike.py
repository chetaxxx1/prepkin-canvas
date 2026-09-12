"""The biker's motorbike, from a generated picture.

A drawn-from-memory vector bike read as a blob (George: "does not look like a bike"), so
this one follows the project's art rule — generation draws the object, code owns the
geometry. `src/bike-raw.png` was made with the nano-banana generator (a cruiser in exact
side profile on magenta, with the biker still as the style reference); this script keys the
magenta out, measures the wheels and the seat, and writes a Lottie with the picture as an
embedded image layer plus spinning spoke overlays on the wheels and exhaust puffs.

Geometry (raw 2752x1536 image, crop origin 114,102): rear wheel centre (358, 974), front
(2166, 974), tyre radius 356; the seat dip is at (820, 574). The seat is placed at the comp
centre, so an act that puts the effect one radius below his origin sits him on the saddle.

    python3 design/vfx/gen_bike.py
"""
import base64, io, os
import numpy as np
from PIL import Image
from lottie import C, Comp, anim, ellipse, fill, group, path, soft_fill, star, still, stroke, transform

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(HERE, "src", "bike-raw.png")
ASSET_W = 1200          # enough for a 350px-wide bike at 3x

# --- key the magenta out and crop -----------------------------------------------------
im = np.asarray(Image.open(RAW).convert("RGB")).astype(float)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
mag = np.clip((r - g) / 255, 0, 1) * np.clip((b - g) / 255, 0, 1)
alpha = 1 - np.clip((mag - 0.25) / 0.5, 0, 1)
alpha[(r > 200) & (b > 200) & (g < 90)] = 0
sil = alpha > 0.5
ys, xs = np.where(sil)
x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
rgba = np.dstack([im, alpha * 255]).astype(np.uint8)
bike = Image.fromarray(rgba, "RGBA").crop((x0, y0, x1 + 1, y1 + 1))
W, H = bike.size
# Measured on the raw image; expressed in crop pixels.
REAR = (472 - x0, 1076 - y0)
FRONT = (2280 - x0, 1076 - y0)
TYRE_R = 356
SEAT = (934 - x0, 676 - y0)

scale_px = ASSET_W / W
asset = bike.resize((ASSET_W, int(H * scale_px)), Image.LANCZOS)
buf = io.BytesIO()
asset.save(buf, "PNG", optimize=True)
b64 = base64.b64encode(buf.getvalue()).decode()
aw, ah = asset.size

# --- lay it into the comp ------------------------------------------------------------
# Units per crop pixel: the bike is 296 units wide so the seat can sit at the comp centre
# with the front tyre still inside the 400-unit canvas.
UNIT = 296 / W
sx, sy = SEAT
def unit(p):
    return ((p[0] - sx) * UNIT, (p[1] - sy) * UNIT)

frames = 78
IN, OUT_ = 12, 60


def ride(dx=0.0, dy=0.0):
    """Shared motion: in from the left, a bob, off to the right. Offsets are in units from the seat."""
    keys = [(0, [C + dx - 380, C + dy, 0], "out"), (IN, [C + dx, C + dy, 0], "linear")]
    for f in range(IN + 6, OUT_, 6):
        keys.append((f, [C + dx, C + dy + (3 if (f // 6) % 2 else -3), 0], "inout"))
    keys.append((OUT_, [C + dx, C + dy, 0], "in"))
    keys.append((frames - 1, [C + dx + 640, C + dy - 12, 0], "linear"))
    return anim(keys, 3)


c = Comp("motorbike", frames)
spin = anim([(0, [0], "linear"), (IN, [520], "linear"), (OUT_, [700], "linear"), (frames - 1, [2100], "linear")], 1)
wheel_r = TYRE_R * UNIT
for name, centre in (("rear", REAR), ("front", FRONT)):
    ox, oy = unit(centre)
    # Spokes and a hub over the painted rim: turning spokes are what make a wheel read as rolling.
    c.add(f"{name}-spokes", [group([star(8, wheel_r * 0.62, wheel_r * 0.12), fill((0.9, 0.92, 0.95), 55)]),
                             group([ellipse(wheel_r * 0.34), stroke((0.35, 0.37, 0.42), 3, 80)])],
          p=ride(ox, oy), r=spin)
# The picture itself, seat at the comp centre.
img_layer = {
    "ddd": 0, "ind": len(c.layers) + 1, "ty": 2, "nm": "bike", "refId": "bike", "sr": 1,
    "ks": {"o": still(100), "r": still(0), "p": ride(unit((W / 2, H / 2))[0], unit((W / 2, H / 2))[1]),
           "a": still([aw / 2, ah / 2, 0]), "s": still([UNIT / scale_px * 100, UNIT / scale_px * 100, 100])},
    "ao": 0, "ip": 0, "op": frames, "st": 0, "bm": 0,
}
c.layers.append(img_layer)
# Exhaust off the muffler tip on the way out.
mx, my = unit((330 - x0, 1180 - y0))
for n in range(4):
    d0 = OUT_ - 2 + n * 3
    c.add(f"puff{n}", [group([ellipse(46), soft_fill((0.55, 0.58, 0.64), 46, 0.35)])],
          p=anim([(d0, [C + mx, C + my, 0], "out"), (d0 + 12, [C + mx - 110 - n * 20, C + my - 30, 0], "linear")], 3),
          s=anim([(d0, [30, 30, 100], "out"), (d0 + 12, [130, 130, 100], "linear")], 3),
          o=anim([(d0, [80], "linear"), (d0 + 4, [80], "in"), (d0 + 12, [0], "linear")], 1), ip=d0, op=d0 + 13)

# write with the asset attached
import json, shutil
from lottie import FPS, SIZE, SPROUT_PUBLIC
doc = {"v": "5.7.4", "fr": FPS, "ip": 0, "op": frames, "w": SIZE, "h": SIZE, "nm": "motorbike", "ddd": 0,
       "assets": [{"id": "bike", "w": aw, "h": ah, "u": "", "p": f"data:image/png;base64,{b64}", "e": 1}],
       "layers": c.layers}
out = os.path.join(HERE, "motorbike.json")
json.dump(doc, open(out, "w"), separators=(",", ":"))
shutil.copy(out, os.path.join(SPROUT_PUBLIC, "motorbike.json"))
print(f"wrote motorbike.json {os.path.getsize(out) // 1024} KB; bike {W}x{H}, seat at {SEAT}, wheel r {wheel_r:.1f} units")
