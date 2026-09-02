#!/usr/bin/env python3
"""Generates ios/Sources/KinArt.swift from kin-silhouettes.json.

Everything becomes TracedShape subpath data — the same [x0,y0,c1x,c1y,c2x,c2y,x1,y1]
segment format SlimeArt already uses — so the new kin get the existing deform, the
existing fill pipeline and the existing face paths for free. Circles and ellipses are
converted to four cubic segments (kappa) rather than kept as primitives, so a species
is one continuous path per fill and the overlapping bulges read as one silhouette.

Run from design/handoff-kin/:  python3 emit_kin_art.py
"""
import json, os, re

W, H = 1000.0, 897.0
K = 0.5522847498307936
FACE_CX, FACE_CY = 494.0 / W, 388.0 / H

def nx(x): return round(x / W, 5)
def ny(y): return round(y / H, 5)

def ellipse(cx, cy, rx, ry):
    """Four cubic segments, clockwise from the top."""
    ox, oy = rx * K, ry * K
    pts = [(cx, cy - ry), (cx + rx, cy), (cx, cy + ry), (cx - rx, cy)]
    ctl = [((cx + ox, cy - ry), (cx + rx, cy - oy)),
           ((cx + rx, cy + oy), (cx + ox, cy + ry)),
           ((cx - ox, cy + ry), (cx - rx, cy + oy)),
           ((cx - rx, cy - oy), (cx - ox, cy - ry))]
    segs = []
    for i in range(4):
        a, b = pts[i], pts[(i + 1) % 4]
        c1, c2 = ctl[i]
        segs.append([nx(a[0]), ny(a[1]), nx(c1[0]), ny(c1[1]),
                     nx(c2[0]), ny(c2[1]), nx(b[0]), ny(b[1])])
    return segs

TOKEN = re.compile(r'([MCZmcz])|(-?\d*\.?\d+)')

def parse_path(d):
    """Only M / C / Z appear in this file. Returns a list of subpaths."""
    toks = [(c or n) for c, n in TOKEN.findall(d)]
    subs, cur, i, pen, start = [], [], 0, (0.0, 0.0), (0.0, 0.0)
    while i < len(toks):
        t = toks[i]
        if t in "Mm":
            if cur: subs.append(cur); cur = []
            x, y = float(toks[i + 1]), float(toks[i + 2]); i += 3
            pen = start = (x, y)
        elif t in "Cc":
            i += 1
            while i < len(toks) and toks[i] not in "MCZmcz":
                v = [float(toks[i + k]) for k in range(6)]; i += 6
                cur.append([nx(pen[0]), ny(pen[1]), nx(v[0]), ny(v[1]),
                            nx(v[2]), ny(v[3]), nx(v[4]), ny(v[5])])
                pen = (v[4], v[5])
        elif t in "Zz":
            i += 1
            if pen != start:
                cur.append([nx(pen[0]), ny(pen[1]), nx(pen[0]), ny(pen[1]),
                            nx(start[0]), ny(start[1]), nx(start[0]), ny(start[1])])
                pen = start
        else:
            i += 1
    if cur: subs.append(cur)
    return subs

def fmt(subs, indent):
    pad = " " * indent
    out = []
    for sub in subs:
        rows = ",\n".join(pad + "    [" + ", ".join(f"{v:g}" for v in s) + "]" for s in sub)
        out.append(pad + "[\n" + rows + "\n" + pad + "]")
    return ",\n".join(out)

here = os.path.dirname(os.path.abspath(__file__))
data = json.load(open(os.path.join(here, "kin-silhouettes.json")))
order = ["ember", "droplet", "sprout", "wisp", "comet"]

L = []
L.append("// GENERATED — do not hand-edit.")
L.append("// Re-run design/handoff-kin/emit_kin_art.py after changing kin-silhouettes.json.")
L.append("")
L.append("import SwiftUI")
L.append("")
L.append("/// Silhouette geometry for the five kin that are not the slime.")
L.append("///")
L.append("/// Same unit space as `SlimeArt` (the 1000x897 character box), same")
L.append("/// `[x0,y0,c1x,c1y,c2x,c2y,x1,y1]` segment format, so `TracedShape` draws these")
L.append("/// and the jelly deform applies unchanged. Every body-coloured bulge is folded")
L.append("/// into ONE path per fill: the kin is a blob, not a body, so the mitten lobes")
L.append("/// must never read as separate parts laid over a torso.")
L.append("///")
L.append("/// The slime itself is not here. It stays in `SlimeArt`, traced from the")
L.append("/// approved renders, and is never regenerated from this file.")
L.append("enum KinArt {")
L.append("    struct Species {")
L.append("        /// Every body-coloured subpath, in draw order.")
L.append("        let body: [[[Double]]]")
L.append("        let belly: [[[Double]]]")
L.append("        /// Comet's gold tail tip — the one place a second flat body colour is used.")
L.append("        let accent: [[[Double]]]?")
L.append("        let accentRGB: (Double, Double, Double)?")
L.append("        /// Where the existing code-drawn face sits, in unit space. The blush")
L.append("        /// follows the same numbers, so cheeks never drift off a new head.")
L.append("        let faceScale: Double, faceCX: Double, faceCY: Double")
L.append("    }")
L.append("")
for sid in order:
    sp = data[sid]
    body_subs, belly_subs, accent_subs = [], [], []
    for sh in sp["shapes"]:
        if sh["kind"] == "ellipse":
            segs = ellipse(sh["cx"], sh["cy"], sh["rx"], sh["ry"])
        elif sh["kind"] == "circle":
            segs = ellipse(sh["cx"], sh["cy"], sh["r"], sh["r"])
        else:
            segs = None
        subs = [segs] if segs else parse_path(sh["d"])
        target = {"body": body_subs, "belly": belly_subs}.get(sh["fill"], accent_subs)
        target.extend(subs)
    f = sp["face"]
    name = sid.capitalize()
    L.append(f"    // MARK: {sp['name'] if 'name' in sp else name} — tier {sp['tier']}, {sp['readsAs']}")
    L.append(f"    static let {sid}Body: [[[Double]]] = [")
    L.append(fmt(body_subs, 8))
    L.append("    ]")
    L.append(f"    static let {sid}Belly: [[[Double]]] = [")
    L.append(fmt(belly_subs, 8))
    L.append("    ]")
    if accent_subs:
        L.append(f"    static let {sid}Accent: [[[Double]]] = [")
        L.append(fmt(accent_subs, 8))
        L.append("    ]")
    L.append("")

L.append("    static let all: [String: Species] = [")
for sid in order:
    f = data[sid]["face"]
    acc = f"KinArt.{sid}Accent" if "tipAccent" in data[sid] else "nil"
    if "tipAccent" in data[sid]:
        h = data[sid]["tipAccent"].lstrip("#")
        rgb = f'({int(h[0:2],16)/255:.4f}, {int(h[2:4],16)/255:.4f}, {int(h[4:6],16)/255:.4f})'
    else:
        rgb = "nil"
    L.append(f'        "{sid}": Species(body: {sid}Body, belly: {sid}Belly, accent: {acc}, accentRGB: {rgb},')
    L.append(f'                       faceScale: {f["scale"]:g}, faceCX: {nx(f["cx"]):g}, faceCY: {ny(f["cy"]):g}),')
L.append("    ]")
L.append("")
L.append("    /// The face's own centre in unit space, which every face transform is relative to.")
L.append(f"    static let faceOriginX = {FACE_CX:g}")
L.append(f"    static let faceOriginY = {round(FACE_CY,5):g}")
L.append("}")
L.append("")
L.append("extension KinArt.Species {")
L.append("    /// Where this species wears the shared face.")
L.append("    var faceFit: KinFaceFit { KinFaceFit(scale: faceScale, cx: faceCX, cy: faceCY) }")
L.append("}")

out = os.path.join(here, "..", "..", "ios", "Sources", "KinArt.swift")
open(os.path.abspath(out), "w").write("\n".join(L) + "\n")
print("wrote", os.path.abspath(out))
