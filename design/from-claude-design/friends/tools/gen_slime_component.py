"""Rebuild Slime.dc.html from the app's real traced mascot.

Claude Design shipped a hand-redrawn approximation. This regenerates the same
Design Component contract (props face / level / species) using the authoritative
art: body + belly + the 4 traced faces from design/canvas/mascot-paths.json, and
the 5 parametric faces ported from ios/Sources/SlimeView.swift (SlimeArt,
expression set 2). Colours come from Theme.species plus the 57%-toward-white
belly rule in Slime.belly(for:).

Run from the repo root:  python3 design/from-claude-design/friends/tools/gen_slime_component.py
"""
import json, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[3].parent
P = json.loads((ROOT / "design/canvas/mascot-paths.json").read_text())
OUT = ROOT / "design/from-claude-design/friends/Slime.dc.html"

VB_W, VB_H = 1000.0, 897.3
INK = "#101820"
CROWN = "M120 250 L96 92 L232 178 L330 40 L428 178 L564 92 L540 250 Z"

# --- traced faces, split into [left eye, mouth, right eye] -------------------
def subpaths(d):
    return [s.strip() + "Z" for s in d.split("Z") if s.strip()]

TRACED = {k: subpaths(P[k]) for k in ("faceIdle", "faceDeadpan", "faceJudging", "faceDelight")}

# --- parametric builders, ported 1:1 from SlimeArt --------------------------
K = 0.5523

def seg(a, b):
    return [a[0], a[1],
            a[0] + (b[0] - a[0]) / 3, a[1] + (b[1] - a[1]) / 3,
            a[0] + 2 * (b[0] - a[0]) / 3, a[1] + 2 * (b[1] - a[1]) / 3,
            b[0], b[1]]

def ellipse_sub(cx, cy, rx, ry):
    return [
        [cx + rx, cy, cx + rx, cy + K * ry, cx + K * rx, cy + ry, cx, cy + ry],
        [cx, cy + ry, cx - K * rx, cy + ry, cx - rx, cy + K * ry, cx - rx, cy],
        [cx - rx, cy, cx - rx, cy - K * ry, cx - K * rx, cy - ry, cx, cy - ry],
        [cx, cy - ry, cx + K * rx, cy - ry, cx + rx, cy - K * ry, cx + rx, cy],
    ]

def arc_stroke(cx, cy, w, t, bow):
    x0, x1 = cx - w / 2, cx + w / 2
    return [
        [x0, cy, cx - w / 6, cy + bow, cx + w / 6, cy + bow, x1, cy],
        seg((x1, cy), (x1, cy + t)),
        [x1, cy + t, cx + w / 6, cy + bow + t, cx - w / 6, cy + bow + t, x0, cy + t],
        seg((x0, cy + t), (x0, cy)),
    ]

def brow(cx, cy, half_w, slant, t):
    yl, yr = cy - slant / 2, cy + slant / 2
    return [
        seg((cx - half_w, yl), (cx + half_w, yr)),
        seg((cx + half_w, yr), (cx + half_w, yr + t)),
        seg((cx + half_w, yr + t), (cx - half_w, yl + t)),
        seg((cx - half_w, yl + t), (cx - half_w, yl)),
    ]

def to_d(shape):
    """Unit-space cubic list -> an SVG subpath in the 1000x897.3 viewBox."""
    def pt(x, y):
        return f"{x * VB_W:.1f} {y * VB_H:.1f}"
    c = shape[0]
    out = ["M" + pt(c[0], c[1])]
    for c in shape:
        out.append("C" + pt(c[2], c[3]) + " " + pt(c[4], c[5]) + " " + pt(c[6], c[7]))
    return "".join(out) + "Z"

EYE_L, EYE_R, EYE_Y = 0.3308, 0.6681, 0.4326

FACES = {
    "idle":     TRACED["faceIdle"],
    "deadpan":  TRACED["faceDeadpan"],
    "judging":  TRACED["faceJudging"],
    "delight":  TRACED["faceDelight"],
    "sleep": [to_d(arc_stroke(EYE_L, 0.435, 0.135, 0.028, 0.048)),
              to_d(arc_stroke(EYE_R, 0.435, 0.135, 0.028, 0.048)),
              to_d(ellipse_sub(0.5, 0.505, 0.020, 0.016))],
    "surprised": [to_d(ellipse_sub(EYE_L, EYE_Y - 0.008, 0.078, 0.086)),
                  to_d(ellipse_sub(EYE_R, EYE_Y - 0.008, 0.078, 0.086)),
                  to_d(ellipse_sub(0.5, 0.535, 0.040, 0.050))],
    "sad": [to_d(ellipse_sub(EYE_L, EYE_Y + 0.012, 0.064, 0.070)),
            to_d(ellipse_sub(EYE_R, EYE_Y + 0.012, 0.064, 0.070)),
            to_d(arc_stroke(0.5, 0.520, 0.130, 0.026, -0.048))],
    "focused": [to_d(brow(EYE_L, 0.292, 0.054, 0.026, 0.026)),
                to_d(brow(EYE_R, 0.292, 0.054, -0.026, 0.026)),
                TRACED["faceJudging"][0], TRACED["faceJudging"][2], TRACED["faceIdle"][1]],
    "wink": [TRACED["faceIdle"][0], TRACED["faceDelight"][2], TRACED["faceIdle"][1]],
}

# --- species: Theme.species + Slime.belly(for:) -----------------------------
def belly_of(hexstr):
    r, g, b = (int(hexstr[i:i + 2], 16) for i in (1, 3, 5))
    t = 0.57
    return "#%02X%02X%02X" % tuple(round(c + (255 - c) * t) for c in (r, g, b))

SPECIES = {"green": "#51CFA0", "pink": "#F7A8B8", "sky": "#9BC8F2",
           "lavender": "#C3B2F0", "leaf": "#A5CE6B"}
PALETTE = {k: [v, "#B1EDD4" if k == "green" else belly_of(v)] for k, v in SPECIES.items()}

# --- emit -------------------------------------------------------------------
def face_block(name, paths):
    key = "is" + name[0].upper() + name[1:]
    d = "".join(paths)
    return (f'<sc-if value="{{{{ {key} }}}}">\n'
            f'<path d="{d}" fill="{INK}"></path>\n</sc-if>')

flags = ", ".join(f"is{n[0].upper()}{n[1:]}: f === '{n}'" for n in FACES)
pal = ", ".join(f"{k}: ['{v[0]}', '{v[1]}']" for k, v in PALETTE.items())

props = ('{"$preview":{"width":160,"height":160},'
         '"face":{"editor":"enum","options":["idle","deadpan","judging","delight","sleep",'
         '"surprised","sad","focused","wink"],"default":"idle","tsType":"string"},'
         '"level":{"editor":"int","default":1,"min":1,"max":3,"tsType":"number"},'
         '"species":{"editor":"enum","options":["green","pink","sky","lavender","leaf"],'
         '"default":"green","tsType":"string"}}').replace('"', "&quot;")

html = f'''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<script src="./support.js"></script>
</head>
<body>
<!-- GENERATED by tools/gen_slime_component.py from the app's real traced mascot.
     Do not hand-edit: rerun the script instead. Source of truth is
     design/canvas/mascot-paths.json + ios/Sources/SlimeView.swift. -->
<x-dc>
<svg viewBox="0 0 {VB_W:g} {VB_H:g}" width="100%" height="100%"
     preserveAspectRatio="xMidYMax meet" style="display:block;overflow:visible">
<path d="{P['body']}" fill="{{{{ body }}}}"></path>
<path d="{P['belly']}" fill="{{{{ belly }}}}"></path>
{chr(10).join(face_block(n, p) for n, p in FACES.items())}
<sc-if value="{{{{ hasBlush }}}}">
<g><ellipse cx="195" cy="484.5" rx="55" ry="20.2" fill="#FF9E94" opacity="0.7"></ellipse><ellipse cx="805" cy="484.5" rx="55" ry="20.2" fill="#FF9E94" opacity="0.7"></ellipse></g>
</sc-if>
<sc-if value="{{{{ hasCrown }}}}">
<g transform="translate(300 18) rotate(-12) scale(0.42)"><path d="{CROWN}" fill="#FFC24B" stroke="#E8A62E" stroke-width="26" stroke-linejoin="round"></path></g>
</sc-if>
</svg>
</x-dc>
<script type="text/x-dc" data-dc-script data-props="{props}">
class Component extends DCLogic {{
  renderVals() {{
    const f = this.props.face || 'idle';
    const lv = this.props.level || 1;
    // Theme.species(), with the belly derived by Slime.belly(for:) — a 57%
    // blend toward white. Mint keeps its exact #B1EDD4.
    const species = {{ {pal} }};
    const [body, belly] = species[this.props.species] || species.green;
    return {{ body, belly, {flags}, hasBlush: lv >= 2, hasCrown: lv >= 3 }};
  }}
}}
</script>
</body>
</html>
'''
OUT.write_text(html)
print("wrote", OUT, len(html), "bytes")
for k, v in PALETTE.items():
    print(f"  {k:9} body {v[0]}  belly {v[1]}")
