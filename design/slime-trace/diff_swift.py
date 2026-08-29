#!/usr/bin/env python3
"""Diff the SwiftUI harness renders against the reference PNGs."""
import numpy as np
from PIL import Image
from scipy import ndimage

SCRATCH = "/private/tmp/claude-501/-Users-georgeshi-Desktop-app-prepkin-canvas/8e386b9b-4386-4450-acc7-6b9b7ff1db2a/scratchpad"
HANDOFF = "/Users/georgeshi/Desktop/mascot/slime-handoff"

# reference cropped to char bbox
ref = np.array(Image.open(f"{HANDOFF}/mascot-idle.png").convert("RGBA"), dtype=np.int16)
ref = ref[101:896, 69:955]
sw = np.array(Image.open(f"{SCRATCH}/swift-idle.png").convert("RGBA"), dtype=np.int16)
print("shapes:", ref.shape, sw.shape)


def masks(a):
    alpha = a[..., 3] > 128
    out = {}
    for name, rgb in [("body", (0x51, 0xCF, 0xA0)), ("belly", (0xB1, 0xED, 0xD4)), ("ink", (0x10, 0x18, 0x20))]:
        d = np.abs(a[..., :3] - np.array(rgb)).sum(axis=2)
        out[name] = (d < 90) & alpha
    out["sil"] = alpha
    return out


mr, ms = masks(ref), masks(sw)
for k in ["sil", "body", "belly", "ink"]:
    inter = (mr[k] & ms[k]).sum()
    union = (mr[k] | ms[k]).sum()
    sym = mr[k] ^ ms[k]
    dt_in = ndimage.distance_transform_edt(mr[k])
    dt_out = ndimage.distance_transform_edt(~mr[k])
    dev = np.where(mr[k], dt_in, dt_out)[sym]
    print(f"{k}: IoU={inter/union:.5f} symdiff={sym.sum()} maxdev={dev.max() if sym.any() else 0:.1f}px")

# exact color check in swift render
center_colors = set()
body_px = sw[ms["body"]][:, :3]
print("swift body color range:", body_px.min(axis=0), body_px.max(axis=0))

# side-by-side and overlay at app-ish scale
ref_img = Image.open(f"{HANDOFF}/mascot-idle.png").convert("RGBA").crop((69, 101, 955, 896))
sw_img = Image.open(f"{SCRATCH}/swift-idle.png").convert("RGBA")
W, H = ref_img.size
bg = Image.new("RGBA", (W * 2 + 60, H + 40), (249, 244, 234, 255))
bg.paste(ref_img, (20, 20), ref_img)
bg.paste(sw_img, (W + 40, 20), sw_img)
bg.convert("RGB").save(f"{SCRATCH}/sbs-idle-full.png")

# red/blue overlay of silhouettes
ov = np.zeros((H, W, 3), dtype=np.uint8)
ov[...] = 255
ov[mr["sil"] & ~ms["sil"]] = [220, 40, 40]   # ref only = red
ov[ms["sil"] & ~mr["sil"]] = [40, 80, 220]   # swift only = blue
ov[mr["sil"] & ms["sil"]] = [200, 230, 210]  # agree
Image.fromarray(ov).save(f"{SCRATCH}/overlay-idle.png")
print("wrote sbs-idle-full.png, overlay-idle.png")
