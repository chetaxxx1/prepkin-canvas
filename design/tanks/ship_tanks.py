#!/usr/bin/env python3
"""Put the fifteen trial tanks and every piece into the iOS app.

Reads the composed sets the Sprout build already has (`public/tanks/ios/` in the
handoff repo, made by build_sets.py → compose_tank.py) plus the loose and earned
pieces (`trial/sets/loose`, `trial/sets/earned`, still on magenta) and writes:

  ios/SproutWeb/tanks/ios/<id>*.png            the live Home tank's plates + pieces
  ios/SproutWeb/tanks/ios/pieces/<name>.png     loose + earned cut-outs (also into the
                                                Sprout repo's public/, so one build)
  Assets.xcassets/scene-<id>, scene-<id>-empty  the stills (with props / bare)
  Assets.xcassets/piece-<name>                  every cut-out, for the Decorate tray
  ios/Sources/Core/TankCatalog.swift            Scene0 rows, piece rows, slot defaults

A cut-out is scaled to its slot's maximum at plate scale (1440x1080), so its own
pixel size IS its box: the page and Swift both divide by the plate to place it.
"""
import json, os, re, shutil, sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import compose_tank as cmp
import check_tank as ct

SPROUT = os.path.expanduser("~/Downloads/Sprout-handoff")
SRC = os.path.join(SPROUT, "public", "tanks", "ios")
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
WEB = os.path.join(REPO, "ios", "SproutWeb", "tanks", "ios")
CATALOG = os.path.join(REPO, "ios", "Resources", "Assets.xcassets")
SWIFT = os.path.join(REPO, "ios", "Sources", "Core", "TankCatalog.swift")
THEME = os.path.join(REPO, "ios", "Sources", "Theme.swift")
SETS = os.path.join(HERE, "trial", "sets")
W, H = ct.W, ct.H

# Order, price and light/dark from GROK-TANK-PROMPTS.md (prices are its suggestion).
TANKS = [
    ("treasure", "Treasure", 300, False), ("castle", "Castle", 300, False),
    ("zen", "Zen", 320, False), ("frost", "Frost", 320, False), ("vapor", "Vapor", 340, False),
    ("lantern", "Lantern", 360, True), ("disco", "Disco", 380, True), ("orbit", "Orbit", 380, True),
    ("arcade", "Arcade", 400, True), ("magma", "Magma", 400, True),
    ("library", "Library", 340, True), ("cottage", "Cottage", 320, False),
    ("lofi", "Lofi", 360, True), ("court", "Court", 340, False), ("haunt", "Haunt", 300, True),
]
SLOT_KIND = {"left": "stand", "right": "stand", "tl": "corner", "tr": "corner", "light": "light"}
# Loose (for sale) and earned (never sold) pieces: name, slot kind, price, lamp colour.
LOOSE = [
    ("coffee", "Coffee cups", "stand", 120, None), ("books", "Textbooks", "stand", 120, None),
    ("laptop", "Laptop", "stand", 140, None), ("plant", "Monstera", "stand", 120, None),
    ("trophy", "Trophy", "stand", 160, None), ("radio", "Retro radio", "stand", 140, None),
    ("pennants", "Pennants", "corner", 80, None), ("planes", "Paper planes", "corner", 90, None),
    ("lights", "String lights", "corner", 100, None), ("calendar", "Wall calendar", "corner", 80, None),
    ("desk", "Desk lamp", "light", 120, "#FFC98A"), ("moon", "Moon lamp", "light", 140, "#EEF2FF"),
]
EARNED = [
    ("first-assignment", "First Assignment", "stand", "first Canvas task done", None),
    ("clean-week", "Clean Week", "corner", "a week with nothing overdue", None),
    ("deep-work", "Deep Work", "stand", "one Focus shift of 45 minutes", None),
    ("reader", "Reader", "stand", "a Learn unit finished", None),
    ("semester", "Semester", "stand", "100 assignments", None),
    ("league", "League", "corner", "first week at the top of a pod", None),
    ("night-owl", "Night Owl", "light", "a Focus shift after midnight", "#EEF2FF"),
]

NAMES = {  # hand-picked from the pack's prompts; two words that name the thing
    "treasure": ["Treasure chest", "Deep-sea diver", "Fishing net", "Seaweed sprig", "Diving lantern"],
    "castle": ["Castle tower", "Stone column", "Ivy strand", "Stone corbel", "Chandelier"],
    "zen": ["Stone lantern", "Stacked stones", "Blossom branch", "Wind chime", "Paper lantern"],
    "frost": ["Ice blocks", "Frosted pine", "Icicles", "Ice cluster", "Frosted lantern"],
    "vapor": ["Marble bust", "Palm pair", "Bead string", "Greek column", "Neon ring"],
    "lantern": ["Lantern post", "Wooden bench", "Round lanterns", "Paper lanterns", "Amber lantern"],
    "disco": ["Speaker stack", "Mirror ball", "Pastel bulbs", "Party streamer", "Disco ball lamp"],
    "orbit": ["Ringed planet", "Rocket", "Crescent moon", "Satellite", "Planet lamp"],
    "arcade": ["Arcade cabinet", "Pinball machine", "Neon zigzag", "Coiled cable", "Neon ring lamp"],
    "magma": ["Volcano", "Ember rocks", "Hanging root", "Root pair", "Magma lamp"],
    "library": ["Book stack", "Globe", "Ivy strand", "Reading lamp", "Banker's lamp"],
    "cottage": ["Stone cottage", "Wheelbarrow", "Wisteria", "Flower basket", "Wooden lantern"],
    "lofi": ["Desk lamp", "Monstera", "Warm lights", "Headphones", "Cord lamp"],
    "court": ["Basketball hoop", "Basketball", "Pennants", "Whistle", "Floodlight"],
    "haunt": ["Carved pumpkin", "Iron cauldron", "Cobweb", "Iron lantern", "Paper moon"],
}


def piece_names():
    return {tid: dict(zip(["left", "right", "tl", "tr", "light"], row)) for tid, row in NAMES.items()}


def imageset(name, img, scale="3x"):
    d = os.path.join(CATALOG, f"{name}.imageset")
    os.makedirs(d, exist_ok=True)
    img.save(os.path.join(d, f"{name}.png"), optimize=True)
    json.dump({"images": [{"filename": f"{name}.png", "idiom": "universal", "scale": scale},
                          {"idiom": "universal", "scale": "1x"}, {"idiom": "universal", "scale": "2x"}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(d, "Contents.json"), "w"))


def fit(prop, kind):
    """Scale a cut-out to its slot's maximum at plate scale — the same rule compose_tank uses."""
    spec = cmp.SLOTS[{"stand": "left", "corner": "tl", "light": "light"}[kind]]
    scale = min(spec["max_h"] * H / prop.height, spec["max_w"] * W / prop.width)
    return prop.resize((max(1, round(prop.width * scale)), max(1, round(prop.height * scale))), Image.LANCZOS)


def hexs(rgb):
    return "0x%02X%02X%02X" % tuple(int(v) for v in rgb)


def main():
    os.makedirs(os.path.join(WEB, "pieces"), exist_ok=True)
    os.makedirs(os.path.join(SRC, "pieces"), exist_ok=True)
    entries = json.load(open(os.path.join(SETS, "tanks-entries.json")))
    names = piece_names()
    scenes, defaults, pieces = [], [], []

    for tid, name, price, dark in TANKS:
        for suffix in ("", "-empty", "-left", "-right", "-tl", "-tr", "-light"):
            shutil.copy(os.path.join(SRC, f"{tid}{suffix}.png"), os.path.join(WEB, f"{tid}{suffix}.png"))
        plate = Image.open(os.path.join(SRC, f"{tid}.png")).convert("RGB")
        imageset(f"scene-{tid}", plate)
        imageset(f"scene-{tid}-empty", Image.open(os.path.join(SRC, f"{tid}-empty.png")).convert("RGB"))
        # floor / floorDeep exactly as cut_ios_tanks.py samples them for the five
        a = np.asarray(plate).astype(float)[:, W // 4: 3 * W // 4, :]
        hi = a[int(H * 0.86): int(H * 0.90)].mean(axis=(0, 1))
        lo = a[int(H * 0.96): int(H * 0.995)].mean(axis=(0, 1))
        per_px = (lo - hi) / ((0.975 - 0.88) * H)
        floor = plate.getpixel((W // 2, H - 2))
        deep = ct.page_deep(np.array(floor, float), per_px)
        props = re.findall(r"src: '([^']+)', slot: '(\w+)', box: \[([^\]]+)\](?:, motion: '(\w+)')?(?:, light: '([^']+)')?",
                           entries[tid])
        feet = next(float(box.split(",")[3]) for _, slot, box, _, _ in props if slot == "left")
        scenes.append(f'        Scene0(id: "{tid}", name: "{name}", price: {price}, asset: "scene-{tid}",\n'
                      f'               isDark: {"true" if dark else "false"}, floor: Theme.hex({hexs(floor)}), '
                      f'floorDeep: Theme.hex({hexs(deep)}),\n'
                      f'               emptyAsset: "scene-{tid}-empty", feet: {feet:.4f}),')
        for src, slot, box, motion, light in props:
            pid = f"{tid}-{slot}"
            img = Image.open(os.path.join(SRC, os.path.basename(src))).convert("RGBA")
            imageset(f"piece-{pid}", img)
            x0, x1, y0, y1 = (float(v) for v in box.split(","))
            defaults.append(f'        "{tid}": [.left: "{tid}-left", .right: "{tid}-right", .tl: "{tid}-tl", '
                            f'.tr: "{tid}-tr", .light: "{tid}-light"],' if slot == "left" else None)
            light_s = f', light: "{light}"' if light else ""
            pieces.append(f'        TankProp(id: "{pid}", name: "{names[tid][slot]}", kind: .{SLOT_KIND[slot]}, '
                          f'price: {130 if SLOT_KIND[slot] == "stand" else 100}, asset: "piece-{pid}", '
                          f'file: "{tid}-{slot}.png", size: CGSize(width: {img.width}, height: {img.height}), '
                          f'theme: "{tid}"{light_s}),')

    for pid, name, kind, price, light in LOOSE:
        pieces.append(cut_piece("loose", pid, name, kind, price, None, light))
    for pid, name, kind, rule, light in EARNED:
        pieces.append(cut_piece("earned", pid, name, kind, 0, rule, light))

    defaults = [d for d in defaults if d]
    theme = open(THEME).read()
    head, rest = theme.split("    // themed:begin\n")
    _, tail = rest.split("    // themed:end\n")
    open(THEME, "w").write(head + "    // themed:begin\n    static let themed: [Scene0] = [\n"
                           + "\n".join(scenes) + "\n    ]\n    // themed:end\n" + tail)
    body = "\n".join([
        "import CoreGraphics",
        "",
        "// GENERATED by design/tanks/ship_tanks.py — do not edit by hand.",
        "// The fifteen themed tanks' pieces (Gemini stand-ins until Grok paints the",
        "// real ones), the twelve loose pieces and the seven earned ones. The tanks",
        "// themselves are `Scene0.themed` in Theme.swift.",
        "enum TankCatalog {",
        "    /// What each tank stands in its slots until the student changes something.",
        "    static let defaults: [String: [PropSlot: String]] = [",
        *defaults,
        "    ]",
        "",
        "    /// Every piece: the tanks' own, then loose, then earned.",
        "    static let pieces: [TankProp] = [",
        *pieces,
        "    ]",
        "}",
        "",
    ])
    open(SWIFT, "w").write(body)
    print(f"{len(scenes)} tanks → Theme.swift, {len(pieces)} pieces → {os.path.relpath(SWIFT, REPO)}")


def cut_piece(folder, pid, name, kind, price, rule, light):
    raw = Image.open(os.path.join(SETS, folder, f"{pid}.png"))
    img = fit(cmp.key_out(raw), kind)
    for out in (os.path.join(WEB, "pieces"), os.path.join(SRC, "pieces")):
        img.save(os.path.join(out, f"{pid}.png"), optimize=True)
    imageset(f"piece-{pid}", img)
    rule_s = f', rule: "{rule}"' if rule else ""
    light_s = f', light: "{light}"' if light else ""
    return (f'        TankProp(id: "{pid}", name: "{name}", kind: .{kind}, price: {price}, asset: "piece-{pid}", '
            f'file: "pieces/{pid}.png", size: CGSize(width: {img.width}, height: {img.height}){rule_s}{light_s}),')


if __name__ == "__main__":
    main()
