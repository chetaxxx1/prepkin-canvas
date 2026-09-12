"""Build a tank plate from an empty tank painting and up to five props on magenta.

    python3 design/tanks/compose_tank.py --id treasure --tank treasure-tank.png \\
        --left chest.png --right diver.png \\
        --tl net.png --tr seaweed.png --light lantern.png --light-color '#FFD98A' \\
        --out ~/Downloads/Sprout-handoff/public/tanks/treasure.png --layers <dir>

The six pieces of a tank (the shop model, 2026-09-11):
  tank        the painting: wall, ridge, discs, light shaft, a BARE floor, EMPTY corners
  left/right  the two stands: feet on the floor just below the horizon, inside the
              window every screen keeps — the only two pieces visible everywhere
  tl/tr       the corners: hang from the top edge in the top corners (net, vine,
              string lights, neon sign); Home and Kin see them, the shop hero crops them
  light       the lamp: hangs from the top centre, above the fish; its colour drives
              the tank's light rays on the live page (`--light-color`)

Why the props are not painted into the tank: an image model puts a prop wherever it
likes, and it likes the frame edge; every surface crops the plate differently (see
SURFACES in check_tank.py). Code owns geometry: the painter draws objects, this puts
them where they belong, and any piece fits any tank.

What it does: cover-cuts the painting to the 1440x1080 plate as the cutter will;
refuses a tank whose stages are not bare (`--force` overrides); keys each prop off
magenta (or green, --key), scales it to its slot, tints it toward the tank's floor
colour, shadows the stands, pastes; writes the flat plate (what the stills use), a
`<out>.props.json` sidecar for check_tank.py, and with --layers the empty plate plus
each cut-out for the live tank, printing the `tanks.ts` entry with exact boxes.
"""
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import argparse, json, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_tank as ct

W, H = ct.W, ct.H
# cx: centre; anchor "feet" stands on the floor (y from the horizon), "top" hangs from y=0.
SLOTS = {
    "left":  dict(kind="stand",  cx=0.212, anchor="feet", max_w=0.155, max_h=0.34, motion="none"),
    "right": dict(kind="stand",  cx=0.788, anchor="feet", max_w=0.155, max_h=0.34, motion="none"),
    "tl":    dict(kind="corner", cx=0.15,  anchor="top",  max_w=0.24,  max_h=0.19, motion="swing"),
    "tr":    dict(kind="corner", cx=0.85,  anchor="top",  max_w=0.24,  max_h=0.19, motion="swing"),
    "light": dict(kind="light",  cx=0.50,  anchor="top",  max_w=0.20,  max_h=0.24, motion="swing", top=0.08),
}
# The lamp's painted cord starts 8% down, under the Dynamic Island, and the compositor
# draws the stub of cord above it, so the fixture itself hangs clear of the island.
# What Home draws OVER the band on an iPhone 17 Pro, in plate fractions (HomeView:
# chipsTop 64pt, chips ~36pt tall; the Dynamic Island 126x37pt from y 11pt). A piece
# hidden behind these is a piece nobody sees, so the compositor measures the overlap.
OVERLAYS = {
    "name chip": (0.09, 0.39, 0.19, 0.30),
    "coin chip": (0.54, 0.91, 0.19, 0.30),
    "dynamic island": (0.36, 0.64, 0.03, 0.14),
}
FEET_BELOW_HORIZON = 0.10                 # feet follow the horizon, so a prop stands on the ground in every tank
FEET_RANGE = (0.72, 0.78)                 # ...but never above the fade or below the always-visible window
TINT = 0.18                               # how far a prop leans toward the tank's floor colour
KEY = "auto"


def key_out(im, hue_tol=28, sat_min=0.40):
    """Alpha-mask a prop off a magenta (or green) background.

    Works in HSV: background pixels are within hue_tol degrees of the key hue and
    at least sat_min saturated. The mask is softened by one pixel so clay edges do
    not turn into a hard cut, and key-coloured spill on the fringe is pulled out.
    With --key auto (the default) the key is read off the image's own corners, so a
    set with one green-screened pink piece composes in one run."""
    rgb = np.asarray(im.convert("RGB")).astype(float) / 255
    hsv = np.asarray(im.convert("RGB").convert("HSV")).astype(float)
    hue = hsv[..., 0] * 360 / 255
    sat = hsv[..., 1] / 255
    key = KEY
    if key == "auto":
        corners = np.concatenate([hue[:8, :8].ravel(), hue[:8, -8:].ravel(), hue[-8:, :8].ravel(), hue[-8:, -8:].ravel()])
        key = "green" if np.abs((np.median(corners) - 120 + 180) % 360 - 180) < 40 else "magenta"
    key_hue = 300 if key == "magenta" else 120
    d = np.abs((hue - key_hue + 180) % 360 - 180)
    bg = (d < hue_tol) & (sat > sat_min)
    alpha = (~bg).astype(float)
    alpha = np.asarray(Image.fromarray((alpha * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.0))).astype(float) / 255
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    if key == "magenta":
        spill = np.clip(np.minimum(r, b) - g, 0, None)
        r, b, g = r - spill * 0.55, b - spill * 0.55, g + spill * 0.25
    else:
        spill = np.clip(g - np.maximum(r, b), 0, None)
        g, r, b = g - spill * 0.6, r + spill * 0.2, b + spill * 0.2
    out = (np.clip(np.stack([r, g, b, alpha], axis=-1), 0, 1) * 255).astype(np.uint8)
    prop = Image.fromarray(out, "RGBA")
    a = np.asarray(prop)[..., 3]
    ys, xs = np.where(a > 40)
    if len(xs) == 0:
        raise SystemExit("nothing left after keying — is the background really magenta?")
    return prop.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def place(plate, empty, prop, slot, size, floor_rgb, nudge, feet):
    """Scale the prop into its slot, tint it, shadow it if it stands, paste it.

    Shadows go on both the flat plate and the empty one, so a prop that bobs on the
    live tank keeps its shadow on the floor; the prop itself goes only on the flat
    plate. Returns the scaled prop and its box in plate fractions."""
    spec = SLOTS[slot]
    scale = min(spec["max_h"] * H / prop.height, spec["max_w"] * W / prop.width) * size
    prop = prop.resize((max(1, round(prop.width * scale)), max(1, round(prop.height * scale))), Image.LANCZOS)
    a = np.asarray(prop).astype(float)
    tint = np.array(floor_rgb, float) / 255
    a[..., :3] = a[..., :3] * (1 - TINT) + a[..., :3] * tint[None, None, :] * TINT * 1.6
    prop = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA")
    cx = int((spec["cx"] + nudge[0]) * W)
    if spec["anchor"] == "feet":
        base = int((feet + nudge[1]) * H)
        x0, y0 = cx - prop.width // 2, base - prop.height
        sh = Image.new("RGBA", plate.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(sh)
        sw, shh = int(prop.width * 0.92), int(prop.width * 0.16)
        dark = tuple(int(c * 0.55) for c in floor_rgb)
        sd.ellipse((cx - sw // 2, base - shh // 2, cx + sw // 2, base + shh // 2), fill=dark + (110,))
        sh = sh.filter(ImageFilter.GaussianBlur(10))
        for target in (plate, empty):
            target.alpha_composite(sh)
    else:
        x0, y0 = cx - prop.width // 2, int((spec.get("top", 0.0) + nudge[1]) * H)
        if y0 > 0:
            # bridge the gap to the top edge with a cord in the piece's own top colour
            top = np.asarray(prop)[:6, :, :]
            solid = top[..., 3] > 120
            colour = tuple(int(v) for v in top[..., :3][solid].mean(axis=0)) if solid.any() else (120, 110, 100)
            for target in (plate, empty):
                ImageDraw.Draw(target).line([(cx, 0), (cx, y0 + 3)], fill=colour + (255,), width=max(3, prop.width // 40))
    plate.alpha_composite(prop, (x0, y0))
    return prop, (x0 / W, (x0 + prop.width) / W, y0 / H, (y0 + prop.height) / H)


def covered(prop, box):
    """Fraction of the piece's opaque pixels under each Home overlay."""
    a = np.asarray(prop)[..., 3] > 40
    total = max(int(a.sum()), 1)
    x0, x1, y0, y1 = box
    out = {}
    for name, (ox0, ox1, oy0, oy1) in OVERLAYS.items():
        # overlay rect in the prop's own pixel space
        px0 = int(max(0, (ox0 - x0) / (x1 - x0) * prop.width)); px1 = int(min(prop.width, (ox1 - x0) / (x1 - x0) * prop.width))
        py0 = int(max(0, (oy0 - y0) / (y1 - y0) * prop.height)); py1 = int(min(prop.height, (oy1 - y0) / (y1 - y0) * prop.height))
        if px1 <= px0 or py1 <= py0:
            continue
        out[name] = a[py0:py1, px0:px1].sum() / total
    return out


def main():
    global KEY
    ap = argparse.ArgumentParser()
    ap.add_argument("--id", required=True)
    ap.add_argument("--tank", required=True, help="the empty tank painting (4:3 or 3:2)")
    for slot in SLOTS:
        ap.add_argument(f"--{slot}", default=None, help=f"{SLOTS[slot]['kind']} prop on magenta ({slot})")
        ap.add_argument(f"--{slot}-size", type=float, default=1.0, help=f"scale the {slot} prop within its slot")
        ap.add_argument(f"--{slot}-nudge", type=float, nargs=2, default=(0, 0), metavar=("DX", "DY"),
                        help=f"move the {slot} prop, plate fractions (+dx right, +dy down)")
        ap.add_argument(f"--{slot}-motion", default=None, choices=["none", "bob", "sway", "swing"])
    ap.add_argument("--light-color", default=None, help="hex the lamp casts; the live page tints its rays with it")
    ap.add_argument("--out", default=None, help="where to write <id>.png (default: design/tanks/out)")
    ap.add_argument("--floor-row", type=int, default=None, help="override the tank's detected floor row")
    ap.add_argument("--key", choices=["auto", "magenta", "green"], default="auto")
    ap.add_argument("--force", action="store_true", help="compose even when a stage is not bare floor")
    ap.add_argument("--layers", default=None, metavar="DIR",
                    help="also write <id>-empty.png and every cut-out here (e.g. the Sprout build's public/tanks/ios)")
    args = ap.parse_args()
    KEY = args.key
    given = {slot: getattr(args, slot) for slot in SLOTS if getattr(args, slot)}
    if not given:
        ap.error("give at least one prop (--left, --right, --tl, --tr, --light)")

    tank = Image.open(args.tank).convert("RGB")
    row = args.floor_row or ct.floor_line(tank)
    plate, _ = ct.cut(tank, row)
    floor_frac = row / tank.height if tank.height * (W / tank.width) <= H + 1 else ct.FLOOR_AT
    feet = min(FEET_RANGE[1], max(FEET_RANGE[0], floor_frac + FEET_BELOW_HORIZON))
    print(f"  horizon at {floor_frac:.2f}, feet at {feet:.2f}")
    if any(SLOTS[s]["anchor"] == "feet" for s in given):
        # A stand has to stand on bare floor. If the painting put coral, discs or a
        # mound where the stage is, say so now, before the prop hides it.
        stages_ok = True
        for side, (ok, note) in ct.stage_report(plate, floor_frac).items():
            if side in given:
                stages_ok &= ok
                print(f"  [{'PASS' if ok else 'FAIL'}] {note}")
        if not stages_ok and not args.force:
            raise SystemExit("  the stage is not bare — repaint the tank with the floor rule, or pass --force")
    plate = plate.convert("RGBA")
    empty = plate.copy()
    floor_rgb = np.asarray(plate.convert("RGB")).astype(float)[int(H * 0.86): int(H * 0.90), W // 4: 3 * W // 4].mean(axis=(0, 1))

    placed = {}
    for slot, path in given.items():
        prop = key_out(Image.open(path))
        prop, box = place(plate, empty, prop, slot, getattr(args, f"{slot}_size"), floor_rgb,
                          tuple(getattr(args, f"{slot}_nudge")), feet)
        motion = getattr(args, f"{slot}_motion") or SLOTS[slot]["motion"]
        placed[slot] = dict(image=prop, box=box, motion=motion, kind=SLOTS[slot]["kind"])
        cut = ct.cut_by(box) if SLOTS[slot]["kind"] == "stand" else []
        hidden = {k: v for k, v in covered(prop, box).items() if v > 0.02}
        # a lamp's cord is allowed under the island; its fixture is not — 20% of the
        # piece is more than a cord
        limit = 0.20 if slot == "light" else 0.05
        blocked = {k: v for k, v in hidden.items() if v > limit}
        note = (f" — CUT by {', '.join(cut)}" if cut else (" — visible on every surface" if SLOTS[slot]['kind'] == 'stand' else " — Home + Kin"))
        if blocked:
            note += " — BLOCKED: " + ", ".join(f"{int(v * 100)}% under the {k}" for k, v in blocked.items())
        elif hidden:
            note += " (" + ", ".join(f"{int(v * 100)}% under the {k}" for k, v in hidden.items()) + ")"
        print(f"  {slot:5} {SLOTS[slot]['kind']:6} x {box[0]:.2f}-{box[1]:.2f} y {box[2]:.2f}-{box[3]:.2f}" + note)

    out = args.out or os.path.join(os.path.dirname(os.path.abspath(__file__)), "out", f"{args.id}.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    plate.convert("RGB").save(out, optimize=True)
    # the sidecar check_tank.py trusts: only the stands are key items
    json.dump({s: p["box"] for s, p in placed.items() if p["kind"] == "stand"}, open(out + ".props.json", "w"))
    print(f"wrote {out}")
    if args.layers:
        os.makedirs(args.layers, exist_ok=True)
        faded, _, _ = ct.finish(empty.convert("RGB"))
        faded.convert("P", palette=Image.ADAPTIVE, colors=256).save(
            os.path.join(args.layers, f"{args.id}-empty.png"), optimize=True)
        for slot, p in placed.items():
            p["image"].save(os.path.join(args.layers, f"{args.id}-{slot}.png"), optimize=True)
        print(f"wrote {args.id}-empty.png and {', '.join(f'{args.id}-{s}.png' for s in placed)} in {args.layers}")
        print("tanks.ts:")
        print(f"    emptySrc: '/tanks/ios/{args.id}-empty.png',")
        print("    props: [")
        for slot, p in placed.items():
            b = p["box"]
            extra = f", light: '{args.light_color}'" if slot == "light" and args.light_color else ""
            print(f"      {{ src: '/tanks/ios/{args.id}-{slot}.png', slot: '{slot}', box: [{b[0]:.4f}, {b[1]:.4f}, {b[2]:.4f}, {b[3]:.4f}], motion: '{p['motion']}'{extra} }},")
        print("    ],")
    print(f"next: python3 design/tanks/check_tank.py {out} --id {args.id}")


if __name__ == "__main__":
    main()
