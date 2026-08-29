#!/usr/bin/env python3
"""Export the traced slime as a layered SVG (for importing into Rive etc.).

Reads trace_result.json (produced by trace.py). One group per layer:
body, belly, then one group per expression's face (only idle visible).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "trace_result.json")
OUT = os.path.join(HERE, "slime.svg")

W, H = 886, 795  # character bbox at reference size

res = json.load(open(SRC))


def path_d(subpaths):
    parts = []
    for segs in subpaths:
        first = segs[0]
        parts.append(f"M {first[0][0]*W:.1f} {first[0][1]*H:.1f}")
        for s in segs:
            parts.append(
                f"C {s[1][0]*W:.1f} {s[1][1]*H:.1f} {s[2][0]*W:.1f} {s[2][1]*H:.1f} {s[3][0]*W:.1f} {s[3][1]*H:.1f}")
        parts.append("Z")
    return " ".join(parts)


faces = {
    "idle": [c["segs"] for c in res["idle_face"]],
    "deadpan": [c["segs"] for c in res["expressions_meta"]["deadpan"]],
    "judging": [c["segs"] for c in res["expressions_meta"]["judging"]],
    "delight": [c["segs"] for c in res["expressions_meta"]["delight"]],
}

svg = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}">']
svg.append(f'  <g id="body"><path d="{path_d([res["body"]])}" fill="#51CFA0"/></g>')
svg.append(f'  <g id="belly"><path d="{path_d([res["belly"]])}" fill="#B1EDD4"/></g>')
for name, comps in faces.items():
    vis = "" if name == "idle" else ' display="none"'
    svg.append(f'  <g id="face-{name}"{vis}>')
    for comp in comps:
        svg.append(f'    <path d="{path_d([comp])}" fill="#101820"/>')
    svg.append("  </g>")
svg.append("</svg>")

with open(OUT, "w") as f:
    f.write("\n".join(svg))
print(f"wrote {OUT}")
