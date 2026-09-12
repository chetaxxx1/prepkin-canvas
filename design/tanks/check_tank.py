"""Check a Grok tank painting against every place the app draws it, and show it there.

    python3 design/tanks/check_tank.py ~/Downloads/disco.png --id disco
    python3 design/tanks/check_tank.py --zones            # draw the composition map

Run it on every candidate before it goes anywhere near the cutter. It does the same
cover-scale and bottom fade as `~/Downloads/Sprout-handoff/scripts/cut_ios_tanks.py`
(imported from there when present, so the maths cannot drift), then:

  1. finds the floor line (where the back wall meets the ground) and reports the
     source row to paste into `FLOOR_LINE` in the cutter;
  2. finds the props — the boxes compose_tank.py recorded in <painting>.props.json,
     or else the blobs that stand out from the wall and floor — and checks each one
     lies inside the window that EVERY surface keeps (see SURFACES):
     the Home band on all iPhones, the shop hero and grid tiles, the collection
     card, the Kin header, the Focus band and the friend card. A prop that any of
     them would cut is a FAIL, and the report says which surface cuts it;
  3. measures the rules that made the first five plates blend into Home: pale top
     corners under the clock, a quiet centre column, a plain bottom fifth;
  4. writes `<id>-plate.png` (the 1440x1080 plate as it would ship), `<id>-props.png`
     (the plate with the always-visible window and every prop boxed, green inside /
     red cut) and `<id>-surfaces.png` (the plate on all nine surfaces at once).

Needs Pillow, numpy and scipy. The mascot in the previews is the bare stage II
Sprout still from design/sprout-stills/out/ — never a costume.
"""
from PIL import Image, ImageDraw
import numpy as np
from scipy import ndimage
import argparse, importlib.util, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
CUTTER = os.path.expanduser("~/Downloads/Sprout-handoff/scripts/cut_ios_tanks.py")
STILL = os.path.join(REPO, "design", "sprout-stills", "out", "sprout-mint-2@3x.png")

W, H = 1440, 1080            # the plate
FLOOR_AT = 0.64              # cutter: horizon lands here on a portrait source
FADE = 0.17                  # cutter: the last 17% smoothsteps to one colour
SCALE = 3                    # points to pixels in the previews

# Every place the app draws a scene, measured off the Swift on 2026-09-11, as the
# window of the 4:3 plate that survives: (x0, x1, y0, y1) in fractions, and how
# the mascot sits on it. Cover-scaling a 4:3 plate into a wider box cuts the top
# (bottom-anchored) or top and bottom (centred); into a taller box it cuts the sides.
#   home:      band = (w, min(w*0.836, h*0.385)), cover, bottom-anchored (HomeView)
#   shop:      TankTile — width stretched 14% past cover, bottom-anchored, grid
#              tiles pan up to the whole slack (KinShopView)
#   collect:   SceneCard — scaledToFill into 175x74, centred (CollectionView)
#   kin:       scaledToFit at full width, nothing cut (KinView)
#   focus:     scaledToFill into 402x222, centred, 50% under paper (FocusView)
#   friend:    scaledToFill into 362x212, centred, 55% under paper (FriendCardSheet)
def _cover(box_w, box_h, anchor_bottom, pan=0.0, stretch=1.0):
    if stretch != 1.0:                       # TankTile: 14% past cover, then 4:3
        dw = max(box_w * stretch, box_h * 4 / 3)
        dh = dw * 3 / 4
    else:
        scale = max(box_w / W, box_h / H)
        dw, dh = W * scale, H * scale
    slack = (dw - box_w) / 2
    x0 = (slack - pan * slack) / dw
    y0 = (dh - box_h) / dh if anchor_bottom else (dh - box_h) / 2 / dh
    return (x0, x0 + box_w / dw, y0, y0 + box_h / dh)


SURFACES = {
    "home 17 Pro":      dict(pt=(402, 336), win=_cover(402, 336, True), mascot=0.36),
    "home SE":          dict(pt=(375, 257), win=_cover(375, 257, True), mascot=0.36),
    "home Max":         dict(pt=(430, 359), win=_cover(430, 359, True), mascot=0.36),
    "shop hero":        dict(pt=(362, 196), win=_cover(362, 196, True, 0, 1.14), mascot=0.56),
    "shop grid":        dict(pt=(175, 142), win=_cover(175, 142, True, 0, 1.14), mascot=0.54),
    "shop grid pan -":  dict(pt=(175, 142), win=_cover(175, 142, True, -1, 1.14), mascot=0.60),
    "shop grid pan +":  dict(pt=(175, 142), win=_cover(175, 142, True, 1, 1.14), mascot=0.60),
    "collection card":  dict(pt=(175, 74),  win=_cover(175, 74, False), mascot=0),
    "kin header":       dict(pt=(402, 301), win=(0, 1, 0, 1), mascot=0.36),
    "focus band":       dict(pt=(402, 222), win=_cover(402, 222, False), mascot=0.43),
    "friend card":      dict(pt=(362, 212), win=_cover(362, 212, False), mascot=0.42),
}

# The window every surface keeps, and the column the mascot stands in at rest.
ALWAYS = (max(s["win"][0] for s in SURFACES.values()), min(s["win"][1] for s in SURFACES.values()),
          max(s["win"][2] for s in SURFACES.values()), min(s["win"][3] for s in SURFACES.values()))
MASCOT_X = (0.30, 0.70)
# Where a stand prop's feet land, and the floor under and around them that has to be
# bare for a slot to work: the horizon (~0.65) down to where the fade begins.
# The y range is set per plate from the detected horizon: the ridge's bases sit on
# the horizon, so the stage starts just below it and runs to where the fade begins.
STAGES = {"left": (0.12, 0.30), "right": (0.70, 0.88)}
STAGE_REF_X = (0.40, 0.60)             # the centre floor, bare by the older rule
STAGE_BELOW_HORIZON, STAGE_BOTTOM = 0.035, 0.83


# --- the cutter's maths, imported so a check and a cut never disagree ------------
def _load_cutter():
    if not os.path.exists(CUTTER):
        return None
    spec = importlib.util.spec_from_file_location("cut_ios_tanks", CUTTER)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


cutter = _load_cutter()


def _finish_local(plate):
    """Copy of cut_ios_tanks.finish/ramp for when the handoff folder is missing."""
    a = np.asarray(plate).astype(float)
    mid = a[:, W // 4: 3 * W // 4, :]
    hi = mid[int(H * 0.86): int(H * 0.90)].mean(axis=(0, 1))
    lo = mid[int(H * 0.96): int(H * 0.995)].mean(axis=(0, 1))
    per_px = (lo - hi) / ((0.975 - 0.88) * H)
    handoff = np.clip(lo + per_px * (H * 0.025), 0, 255)
    start = int(H * (1 - FADE))
    for i, y in enumerate(range(start, H)):
        t = i / (H - start - 1)
        s = t * t * (3 - 2 * t)
        a[y] = a[y] * (1 - s) + handoff * s
    return Image.fromarray(a.astype(np.uint8)), handoff, per_px


def finish(plate):
    return cutter.finish(plate) if cutter else _finish_local(plate)


def page_deep(handoff, per_px):
    if cutter:
        return cutter.page_deep(handoff, per_px)
    return tuple(int(round(v)) for v in handoff)


# --- measuring ------------------------------------------------------------------
def luma(a):
    return 0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]


def floor_line(im):
    """Row where the back wall meets the ground: the strongest brightness step down
    the centre column between 45% and 85% of the height, after a light blur."""
    a = np.asarray(im.convert("RGB")).astype(float)
    h, w = a.shape[:2]
    col = luma(a)[:, int(w * 0.40): int(w * 0.60)].mean(axis=1)
    k = max(3, h // 100)
    col = np.convolve(col, np.ones(k) / k, mode="same")
    lo, hi = int(h * 0.45), int(h * 0.85)
    g = np.abs(np.diff(col))[lo:hi]
    return int(np.argmax(g)) + lo


def cut(im, floor_row):
    """Cover-scale to the plate; keep the whole height of a landscape source, and
    place a portrait source so its floor line lands at FLOOR_AT (the cutter's rule)."""
    scale = max(W / im.width, H / im.height)
    big = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    x = (big.width - W) // 2
    y = 0 if big.height <= H else max(0, min(big.height - H, int(floor_row * scale - FLOOR_AT * H)))
    return big.crop((x, y, x + W, y + H)), scale


def edges(L):
    return np.abs(np.diff(L, axis=1))[:-1, :] + np.abs(np.diff(L, axis=0))[:, :-1]


def props(plate):
    """The things standing in the tank, as boxes in plate fractions.

    Wall and floor are smooth gradients and the mounds are tone-on-tone, so a wide
    median filter rebuilds the background under anything smaller than a fifth of the
    frame; what differs from that by more than 45 (summed over RGB) is a prop.
    Blobs under 0.4% of the plate are texture; blobs wider than 60% are the ridge.
    Done at an eighth of the size: a box does not need more, and the median filter
    is quadratic in its window."""
    small = plate.resize((W // 8, H // 8), Image.LANCZOS)
    a = np.asarray(small).astype(float)
    h, w = a.shape[:2]
    bg = np.stack([ndimage.median_filter(a[..., c], size=(h // 5, w // 5), mode="nearest")
                   for c in range(3)], axis=-1)
    diff = np.abs(a - bg).sum(axis=-1)
    mask = diff > 55
    mask = ndimage.binary_opening(mask, iterations=1)
    mask = ndimage.binary_closing(mask, iterations=1)
    labels, n = ndimage.label(mask)
    out = []
    for i, sl in enumerate(ndimage.find_objects(labels), start=1):
        area = (labels[sl] == i).sum() / (h * w)
        y0, y1 = sl[0].start / h, sl[0].stop / h
        x0, x1 = sl[1].start / w, sl[1].stop / w
        if area < 0.004 or (x1 - x0) > 0.6:
            continue
        # a thing hanging from the top edge is decoration by the brief, never a key item
        out.append(dict(box=(x0, x1, y0, y1), area=area, key=area >= 0.015 and y0 > 0.03))
    return out


def known_props(image_path):
    """compose_tank.py writes <painting>.props.json with the exact boxes it placed;
    when that sidecar exists the checker trusts it over the blob finder."""
    side = image_path + ".props.json"
    if not os.path.exists(side):
        return None
    import json
    return [dict(box=tuple(b), area=0.05, key=True) for b in json.load(open(side)).values()]


def stage_boxes(floor_frac):
    y0 = min(max(floor_frac + STAGE_BELOW_HORIZON, 0.60), STAGE_BOTTOM - 0.06)
    return {side: (x0, x1, y0, STAGE_BOTTOM) for side, (x0, x1) in STAGES.items()}


def stage_report(plate, floor_frac):
    """Is the floor bare where a prop will stand? Compares each stage to the centre
    floor: edge density (texture, objects) and colour spread. A chest standing on a
    coral cluster is what this catches — the tank looked fine until the prop landed
    on top of something. Returns {side: (ok, note)}."""
    a = np.asarray(plate).astype(float)
    L = luma(a)
    E = edges(L)
    def crop(arr, box):
        x0, x1, y0, y1 = box
        return arr[int(y0 * H): int(y1 * H), int(x0 * W): int(x1 * W)]
    boxes = stage_boxes(floor_frac)
    ref = (STAGE_REF_X[0], STAGE_REF_X[1], boxes["left"][2], boxes["left"][3])
    ref_e = crop(E, ref).mean()
    ref_s = crop(a, ref).reshape(-1, 3).std(axis=0).mean()
    out = {}
    for side, box in boxes.items():
        e = crop(E, box).mean()
        sd = crop(a, box).reshape(-1, 3).std(axis=0).mean()
        ok = e <= ref_e * 1.6 + 0.6 and sd <= ref_s * 1.8 + 4
        out[side] = (ok, f"{side} stage: texture {e:.2f} vs centre {ref_e:.2f}, colour spread {sd:.1f} vs {ref_s:.1f}"
                     + ("" if ok else " — something is painted where the prop stands"))
    return out


def cut_by(box):
    """Names of the surfaces whose window does not contain the box."""
    x0, x1, y0, y1 = box
    return [name for name, s in SURFACES.items()
            if x0 < s["win"][0] or x1 > s["win"][1] or y0 < s["win"][2] or y1 > s["win"][3]]


def measure(plate, floor_frac):
    a = np.asarray(plate).astype(float)
    L = luma(a)
    E = edges(L)
    box = E[int(H * 0.50): int(H * 0.93), int(W * 0.27): int(W * 0.73)].mean()
    sides = np.concatenate([E[int(H * 0.35): int(H * 0.93), : int(W * 0.27)],
                            E[int(H * 0.35): int(H * 0.93), int(W * 0.73):]], axis=1).mean()
    bottom = L[int(H * 0.80): int(H * 0.98)]
    row = a[H - 2]
    return {
        "top17": L[: int(H * 0.17)].mean(),
        "clock": L[: int(H * 0.12), : int(W * 0.30)].mean(),
        "battery": L[: int(H * 0.12), int(W * 0.70):].mean(),
        "centre": box / max(sides, 1e-6),
        "bottom_std": bottom.std(),
        "bottom_row_spread": int((row.max(axis=0) - row.min(axis=0)).max()),
        "floor": floor_frac,
    }


def verdicts(m, items):
    """(label, ok, note). Thresholds come from the five shipped plates: lagoon /
    reef / deep / kelp / dusk measure top17 243/215/150/180/185, centre 0.71/0.72/
    0.63/0.62/0.76, bottom std 12/24/31/27/26, floor 0.64-0.73."""
    dark = m["top17"] < 165
    out = []
    keys = [p for p in items if p["key"]]
    cut_keys = [(p, cut_by(p["box"])) for p in keys]
    cut_keys = [(p, c) for p, c in cut_keys if c]
    if not keys:
        out.append(("every key item fully visible on every surface", False,
                    "no key item found at all — the theme's props are missing, too small, or tone-on-tone"))
    else:
        note = f"{len(keys)} key item(s)"
        if cut_keys:
            worst = max(cut_keys, key=lambda pc: len(pc[1]))
            note += (f"; {len(cut_keys)} cut — the one at x {worst[0]['box'][0]:.2f}-{worst[0]['box'][1]:.2f},"
                     f" y {worst[0]['box'][2]:.2f}-{worst[0]['box'][3]:.2f} is cut by {', '.join(worst[1])}")
        else:
            note += ", all inside the always-visible window"
        out.append(("every key item fully visible on every surface", not cut_keys, note))
    in_centre = [p for p in keys if p["box"][1] > MASCOT_X[0] and p["box"][0] < MASCOT_X[1]]
    out.append(("no key item under the mascot", not in_centre,
                f"{len(in_centre)} key item(s) reach into x {MASCOT_X[0]:.2f}-{MASCOT_X[1]:.2f}"
                if in_centre else "centre column clear"))
    if dark:
        # A dark tank is a choice, not a defect; the status bar is Swift's job.
        out.append(("pale top (clock + battery corners)", True,
                    f"DARK scene, clock {m['clock']:.0f}, battery {m['battery']:.0f} — the app must flip the"
                    " status bar to light text for Scene0.isDark before this ships"))
    else:
        out.append(("pale top (clock + battery corners)",
                    m["clock"] >= 165 and m["battery"] >= 165,
                    f"clock {m['clock']:.0f}, battery {m['battery']:.0f}; need 165+ for dark status-bar text"))
    out.append(("quiet centre column",
                m["centre"] <= 0.85,
                f"centre/sides edge ratio {m['centre']:.2f}; shipped plates 0.62-0.76, fail above 0.85"))
    out.append(("plain bottom fifth",
                m["bottom_std"] <= 35,
                f"luma std {m['bottom_std']:.1f} over the bottom 20%; shipped plates 12-31"))
    out.append(("floor line 0.58-0.74",
                0.58 <= m["floor"] <= 0.74,
                f"wall meets ground at {m['floor']:.2f} of the plate height"))
    out.append(("bottom row is one colour after the fade",
                m["bottom_row_spread"] <= 2,
                f"spread {m['bottom_row_spread']} (should be 0-2)"))
    return out, dark


# --- pictures -------------------------------------------------------------------
def mascot():
    if not os.path.exists(STILL):
        return None
    st = Image.open(STILL).convert("RGBA")
    return st.crop(st.getbbox())


def props_picture(plate, items):
    im = plate.copy()
    d = ImageDraw.Draw(im, "RGBA")
    x0, x1, y0, y1 = ALWAYS
    d.rectangle([x0 * W, y0 * H, x1 * W, y1 * H], outline=(255, 255, 255, 230), width=5)
    d.rectangle([MASCOT_X[0] * W, y0 * H, MASCOT_X[1] * W, y1 * H], fill=(255, 255, 255, 40))
    for p in items:
        bx0, bx1, by0, by1 = p["box"]
        bad = bool(cut_by(p["box"])) if p["key"] else False
        col = (230, 60, 60, 255) if bad else (60, 200, 90, 255) if p["key"] else (255, 210, 60, 200)
        d.rectangle([bx0 * W, by0 * H, bx1 * W, by1 * H], outline=col, width=6 if p["key"] else 3)
    d.text((x0 * W + 12, y0 * H + 10), "always visible", fill=(255, 255, 255, 255))
    return im


def surface_tile(plate, name, spec, still, dark):
    """The plate as that surface shows it, at 3x, with the mascot where it stands."""
    pw, ph = spec["pt"]
    px_w, px_h = pw * SCALE, ph * SCALE
    x0, x1, y0, y1 = spec["win"]
    crop = plate.crop((int(x0 * W), int(y0 * H), int(x1 * W), int(y1 * H)))
    tile = crop.resize((px_w, px_h), Image.LANCZOS)
    if name in ("focus band", "friend card"):
        paper = Image.new("RGB", tile.size, (243, 236, 224))
        tile = Image.blend(paper, tile, 0.5)
    if still and spec["mascot"]:
        want = px_h * spec["mascot"]
        k = want / still.height
        st = still.resize((round(still.width * k), round(still.height * k)), Image.LANCZOS)
        feet = px_h - int(px_h * (0.07 if name.startswith("home") else 0.05))
        if name in ("kin header", "focus band", "friend card"):
            feet = px_h - int(px_h * 0.18)
        tile.paste(st, ((px_w - st.width) // 2, feet - st.height), st)
    d = ImageDraw.Draw(tile, "RGBA")
    if name.startswith("home"):
        chip = (30, 30, 30, 235) if dark else (255, 255, 255, 235)
        cy0, cy1 = int(px_h * 0.20), int(px_h * 0.30)
        d.rounded_rectangle((int(px_w * 0.05), cy0, int(px_w * 0.33), cy1), (cy1 - cy0) // 2, fill=chip)
        d.rounded_rectangle((int(px_w * 0.60), cy0, int(px_w * 0.95), cy1), (cy1 - cy0) // 2, fill=chip)
    return tile


def surfaces_sheet(plate, dark):
    still = mascot()
    tiles = [(name, surface_tile(plate, name, spec, still, dark)) for name, spec in SURFACES.items()]
    pad, label_h = 40, 44
    cols = 4
    cell_w = max(t.width for _, t in tiles) + pad
    cell_h = max(t.height for _, t in tiles) + pad + label_h
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cell_w * cols + pad, cell_h * rows + pad), (250, 248, 244))
    d = ImageDraw.Draw(sheet)
    for i, (name, t) in enumerate(tiles):
        cx, cy = pad + (i % cols) * cell_w, pad + (i // cols) * cell_h
        sheet.paste(t, (cx, cy + label_h))
        d.text((cx, cy + 12), f"{name}  ({SURFACES[name]['pt'][0]}x{SURFACES[name]['pt'][1]}pt)",
               fill=(60, 50, 45))
    return sheet


def zones(out, src_w=1536, src_h=1024):
    """The composition map on a 3:2 canvas the size Grok gives us, in SOURCE fractions.
    The cutter takes 5.5% off each side to reach 4:3, so plate x maps to source x as
    0.0555 + 0.889 * x. The always-visible window and the mascot column come from
    the measured surfaces above, not from a guess."""
    to_src = lambda x: 0.0555 + 0.889 * x
    ax0, ax1, ay0, ay1 = ALWAYS
    im = Image.new("RGB", (src_w, src_h), (245, 242, 236))
    d = ImageDraw.Draw(im, "RGBA")
    f = lambda x, y: (int(src_w * x), int(src_h * y))
    d.rectangle([f(to_src(ax0), ay0), f(to_src(ax1), ay1)], outline=(60, 60, 60, 255), width=5)
    d.text((f(to_src(ax0), ay0)[0] + 12, f(to_src(ax0), ay0)[1] + 10),
           "ALWAYS VISIBLE: the only place a key item may stand", fill=(40, 40, 40))
    boxes = [
        ((to_src(STAGES["left"][0]), 0.69, to_src(STAGES["left"][1]), STAGE_BOTTOM), (240, 120, 60, 255), "STAGE: bare floor"),
        ((to_src(STAGES["right"][0]), 0.69, to_src(STAGES["right"][1]), STAGE_BOTTOM), (240, 120, 60, 255), "STAGE: bare floor"),
        ((to_src(ax0), ay0, to_src(MASCOT_X[0]), ay1), (60, 200, 90, 255), "KEY ITEM LEFT"),
        ((to_src(MASCOT_X[1]), ay0, to_src(ax1), ay1), (60, 200, 90, 255), "KEY ITEM RIGHT"),
        ((to_src(MASCOT_X[0]), 0.14, to_src(MASCOT_X[1]), 1.0), (230, 60, 60, 255), "EMPTY: the fish"),
        ((0, 0, 1, 0.18), (240, 200, 60, 255), "top: pale wall + hanging decoration (gets cut)"),
        ((0, 0.80, 1, 1.0), (120, 160, 240, 255), "bottom fifth: plain floor (fades into the page)"),
    ]
    for (x0, y0, x1, y1), col, label in boxes:
        d.rectangle([f(x0, y0), f(x1, y1)], outline=col, width=6)
        d.text((f(x0, y0)[0] + 12, f(x0, y0)[1] + 34 if label.startswith("ALWAYS") else f(x0, y0)[1] + 10),
               label, fill=(50, 50, 50))
    d.rectangle([f(0, 0), f(0.055, 1)], fill=(120, 120, 120, 60))
    d.rectangle([f(0.945, 0), f(1, 1)], fill=(120, 120, 120, 60))
    for y in (0.62, 0.68):
        d.line([f(0, y), f(1, y)], fill=(90, 90, 90), width=3)
    d.text(f(0.40, 0.69), "horizon between these lines", fill=(60, 60, 60))
    im.save(out)
    print("wrote", out)
    print(f"always-visible window (plate fractions): x {ax0:.3f}-{ax1:.3f}, y {ay0:.3f}-{ay1:.3f}")
    print(f"key item boxes (source fractions): left x {to_src(ax0):.2f}-{to_src(MASCOT_X[0]):.2f}, "
          f"right x {to_src(MASCOT_X[1]):.2f}-{to_src(ax1):.2f}, y {ay0:.2f}-{ay1:.2f}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image", nargs="?")
    ap.add_argument("--id", default=None, help="tank id, used for the output names")
    ap.add_argument("--out", default=os.path.join(HERE, "out"))
    ap.add_argument("--floor-row", type=int, default=None, help="override the detected floor row")
    ap.add_argument("--zones", action="store_true", help="draw the composition map and exit")
    ap.add_argument("--empty", action="store_true",
                    help="the painting is an EMPTY tank (no props yet): check its stages are bare, skip the key-item rules")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)
    if args.zones:
        zones(os.path.join(args.out, "zones-3x2.png"))
        return
    if not args.image:
        ap.error("give a painting, or --zones")
    tank = args.id or os.path.splitext(os.path.basename(args.image))[0]
    im = Image.open(args.image).convert("RGB")
    row = args.floor_row or floor_line(im)
    plate, scale = cut(im, row)
    plate, handoff, per_px = finish(plate)
    small = plate.convert("P", palette=Image.ADAPTIVE, colors=256).convert("RGB")
    floor = small.getpixel((W // 2, H - 2))
    deep = page_deep(np.array(floor, float), per_px)
    y0 = 0 if im.height * scale <= H else max(0, min(im.height * scale - H, row * scale - FLOOR_AT * H))
    floor_frac = (row * scale - y0) / H
    known = known_props(args.image)
    items = known or props(plate)
    m = measure(plate, floor_frac)
    checks, dark = verdicts(m, items)
    if args.empty or not known:
        # An empty tank (or any painting without the compositor's sidecar): the
        # stages must be bare floor, or the slots cannot work.
        for side, (ok, note) in stage_report(plate, floor_frac).items():
            checks.append((f"bare floor on the {side} stage", ok, note))
        if args.empty:
            # an empty tank has no key items yet; that rule does not apply to it
            checks = [c for c in checks if not c[0].startswith("every key item") and not c[0].startswith("no key item")]

    print(f"{tank}: source {im.width}x{im.height} (aspect {im.width / im.height:.2f}), "
          f"scaled x{scale:.2f}" + ("  — upscaled hard, ask for a bigger export" if scale > 1.35 else ""))
    print(f"  floor line: source row {row}  ->  FLOOR_LINE[\"{tank}\"] = {row}")
    for p in items:
        bx0, bx1, by0, by1 = p["box"]
        c = cut_by(p["box"])
        print(f"  {'KEY ' if p['key'] else 'small'} item x {bx0:.2f}-{bx1:.2f} y {by0:.2f}-{by1:.2f}"
              f" ({p['area'] * 100:.1f}% of plate)" + (f" — cut by: {', '.join(c)}" if c else " — visible everywhere"))
    ok = True
    for label, passed, note in checks:
        ok &= passed
        print(f"  [{'PASS' if passed else 'FAIL'}] {label}: {note}")
    print(f"  Theme.swift:  Scene0(id: \"{tank}\", name: \"{tank.title()}\", price: ???, asset: \"scene-{tank}\","
          f"\n                isDark: {'true' if dark else 'false'}, floor: Theme.hex(0x{floor[0]:02X}{floor[1]:02X}{floor[2]:02X}),"
          f" floorDeep: Theme.hex(0x{deep[0]:02X}{deep[1]:02X}{deep[2]:02X}))")
    small.save(os.path.join(args.out, f"{tank}-plate.png"), optimize=True)
    props_picture(plate, items).save(os.path.join(args.out, f"{tank}-props.png"))
    surfaces_sheet(plate, dark).save(os.path.join(args.out, f"{tank}-surfaces.png"))
    print(f"  wrote {tank}-plate.png, {tank}-props.png, {tank}-surfaces.png in {args.out}")
    print("  RESULT:", "PASS — send it to the cutter" if ok else "FAIL — fix the failed rule and regenerate")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
