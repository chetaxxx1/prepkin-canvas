#!/usr/bin/env python3
"""Generate a Rive-import-ready layered SVG of the Prepkin slime from the
path data in SlimeView.swift. Layers: body (arms+antenna spliced out),
antenna, armLeft, armRight, belly, and all 9 faces (each its own group).
Also emits a tinted debug SVG to eyeball the layer split."""
import re, math, sys

SWIFT = "/Users/georgeshi/Desktop/app/prepkin-canvas/ios/Sources/SlimeView.swift"
W, H = 886, 795
BODY, BELLY, INK = "#51CFA0", "#B1EDD4", "#101820"

src = open(SWIFT).read()

def parse_paths(name):
    """Return list of subpaths; each subpath is a list of 8-float segments."""
    m = re.search(rf"static let {name}: \[\[\[Double\]\]\] = \[(.*?)\n    \]\n", src, re.S)
    if not m:
        raise SystemExit(f"cannot find {name}")
    block = m.group(1)
    subpaths = []
    for sub in re.findall(r"\[\n((?:\s*\[[^\]]+\],\n)+)\s*\]", block):
        segs = [[float(x) for x in re.findall(r"-?\d+\.\d+|-?\d+", row)]
                for row in re.findall(r"\[([^\]]+)\]", sub)]
        subpaths.append([s for s in segs if len(s) == 8])
    return subpaths

body = parse_paths("body")[0]
belly = parse_paths("belly")[0]
faces_traced = {n: parse_paths("face" + n) for n in ["Idle", "Deadpan", "Judging", "Delight"]}

def line8(a, b):
    return [a[0], a[1],
            a[0] + (b[0]-a[0])/3, a[1] + (b[1]-a[1])/3,
            a[0] + 2*(b[0]-a[0])/3, a[1] + 2*(b[1]-a[1])/3,
            b[0], b[1]]

def curve8(a, b, bow):
    import math
    mx, my = (a[0]+b[0])/2, (a[1]+b[1])/2
    dx, dy = b[0]-a[0], b[1]-a[1]
    n = math.hypot(dx, dy) or 1
    nx, ny = -dy/n, dx/n
    return [a[0], a[1], a[0]+dx/3+nx*bow, a[1]+dy/3+ny*bow,
            a[0]+2*dx/3+nx*bow, a[1]+2*dy/3+ny*bow, b[0], b[1]]

# Segment map (verified by index dump):
# 0-4 antenna outline, 5-9 right dome+shoulder, 10-14 right mitten,
# 15-29 hips+bottom, 30-33 left mitten, 34-39 left dome, 40 climb to tip.
ARM_R = (10, 15)   # splice: seg10.start -> seg15.start
ARM_L = (30, 34)   # splice: seg30.start -> seg34.start
ANT_HEAD, ANT_TAIL = 5, 40

def start(i): return (body[i][0], body[i][1])
def end(i): return (body[i][6], body[i][7])

smooth = []
i = ANT_HEAD
while i < ANT_TAIL:
    if i == ARM_R[0]:
        smooth.append(curve8(start(i), start(ARM_R[1]), -0.008))
        i = ARM_R[1]; continue
    if i == ARM_L[0]:
        smooth.append(curve8(start(i), start(ARM_L[1]), 0.008))
        i = ARM_L[1]; continue
    smooth.append(body[i]); i += 1
smooth.append(curve8(end(ANT_TAIL - 1), start(ANT_HEAD), -0.015))

# limbs get roots that extend INTO the body; they draw behind it, so the
# joint is always covered and can rotate without ever showing a seam
armR = body[ARM_R[0]:ARM_R[1]] + [
    line8(end(ARM_R[1]-1), (0.855, 0.735)),
    line8((0.855, 0.735), (0.855, 0.575)),
    line8((0.855, 0.575), start(ARM_R[0]))]
armL = body[ARM_L[0]:ARM_L[1]] + [
    line8(end(ARM_L[1]-1), (0.150, 0.545)),
    line8((0.150, 0.545), (0.150, 0.725)),
    line8((0.150, 0.725), start(ARM_L[0]))]
antenna = [body[ANT_TAIL]] + body[0:ANT_HEAD] + [
    line8(end(ANT_HEAD-1), (0.565, 0.165)),
    line8((0.565, 0.165), (0.515, 0.150)),
    line8((0.515, 0.150), start(ANT_TAIL))]

# --- parametric faces (same builders as SlimeArt) ---
K = 0.5523
eL, eR, eY = 0.3308, 0.6681, 0.4326

def ellipse(cx, cy, rx, ry):
    return [[cx+rx, cy, cx+rx, cy+K*ry, cx+K*rx, cy+ry, cx, cy+ry],
            [cx, cy+ry, cx-K*rx, cy+ry, cx-rx, cy+K*ry, cx-rx, cy],
            [cx-rx, cy, cx-rx, cy-K*ry, cx-K*rx, cy-ry, cx, cy-ry],
            [cx, cy-ry, cx+K*rx, cy-ry, cx+rx, cy-K*ry, cx+rx, cy]]

def arc_stroke(cx, cy, w, t, bow):
    x0, x1 = cx-w/2, cx+w/2
    return [[x0, cy, cx-w/6, cy+bow, cx+w/6, cy+bow, x1, cy],
            line8((x1, cy), (x1, cy+t)),
            [x1, cy+t, cx+w/6, cy+bow+t, cx-w/6, cy+bow+t, x0, cy+t],
            line8((x0, cy+t), (x0, cy))]

def brow(cx, cy, hw, slant, t):
    yl, yr = cy-slant/2, cy+slant/2
    return [line8((cx-hw, yl), (cx+hw, yr)), line8((cx+hw, yr), (cx+hw, yr+t)),
            line8((cx+hw, yr+t), (cx-hw, yl+t)), line8((cx-hw, yl+t), (cx-hw, yl))]

faces = {
    "idle": faces_traced["Idle"],
    "deadpan": faces_traced["Deadpan"],
    "judging": faces_traced["Judging"],
    "delight": faces_traced["Delight"],
    "sleep": [arc_stroke(eL, 0.435, 0.135, 0.028, 0.048),
              arc_stroke(eR, 0.435, 0.135, 0.028, 0.048),
              ellipse(0.5, 0.505, 0.020, 0.016)],
    "surprised": [ellipse(eL, eY-0.008, 0.078, 0.086), ellipse(eR, eY-0.008, 0.078, 0.086),
                  ellipse(0.5, 0.535, 0.040, 0.050)],
    "sad": [ellipse(eL, eY+0.012, 0.064, 0.070), ellipse(eR, eY+0.012, 0.064, 0.070),
            arc_stroke(0.5, 0.520, 0.130, 0.026, -0.048)],
    "focused": [brow(eL, 0.292, 0.054, 0.026, 0.026), brow(eR, 0.292, 0.054, -0.026, 0.026),
                faces_traced["Judging"][0], faces_traced["Judging"][2], faces_traced["Idle"][1]],
    "wink": [faces_traced["Idle"][0], faces_traced["Delight"][2], faces_traced["Idle"][1]],
}

def d_attr(subpaths):
    if subpaths and isinstance(subpaths[0][0], float):
        subpaths = [subpaths]
    out = []
    for segs in subpaths:
        out.append(f"M {segs[0][0]*W:.1f},{segs[0][1]*H:.1f}")
        for s in segs:
            out.append(f"C {s[2]*W:.1f},{s[3]*H:.1f} {s[4]*W:.1f},{s[5]*H:.1f} {s[6]*W:.1f},{s[7]*H:.1f}")
        out.append("Z")
    return " ".join(out)

def emit(path_out, tint=False):
    def col(base, dbg):
        return dbg if tint else base
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">']
    body_op = ' opacity="0.75"' if tint else ''
    parts.append(f'<g id="antenna"><path d="{d_attr(antenna)}" fill="{col(BODY, "#E06666")}"/></g>')
    parts.append(f'<g id="armLeft"><path d="{d_attr(armL)}" fill="{col(BODY, "#6FA8DC")}"/></g>')
    parts.append(f'<g id="armRight"><path d="{d_attr(armR)}" fill="{col(BODY, "#FFD966")}"/></g>')
    parts.append(f'<g id="body"{body_op}><path d="{d_attr(smooth)}" fill="{col(BODY, "#51CFA0")}"/></g>')
    parts.append(f'<g id="belly"><path d="{d_attr(belly)}" fill="{BELLY}"/></g>')
    for name, art in faces.items():
        vis = "" if name == "idle" else ' style="display:none"'
        parts.append(f'<g id="face-{name}"{vis}><path d="{d_attr(art)}" fill="{INK}"/></g>')
    parts.append("</svg>")
    open(path_out, "w").write("\n".join(parts))
    print("wrote", path_out)

emit("slime-layers.svg")
emit("slime-layers-debug.svg", tint=True)
