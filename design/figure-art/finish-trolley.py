#!/usr/bin/env python3
"""Finish the trolley scene: snap every fill to the house palette, give the tram its
windows. Built the way this art builds everything — an ink shape with the colour laid
on top, inset by the outline weight, no stroke attributes, so pack.py's thicken()
treats the new shapes exactly like Recraft's own."""
import re, subprocess

SRC, OUT = "trolley-g1.svg", "trolley-final.svg"
INK, PAPER, COIN = "rgb(46,38,34)", "rgb(255,255,255)", "rgb(255,194,75)"
W = 23                       # measured outline weight of this file, in viewBox units

# Both rails drifted: mud brown on the upper branch, gold on the lower. Snap to coin
# so the two branches match and the file stays inside the figure palette.
SNAP = {"rgb(177,142,134)": COIN, "rgb(254,181,79)": COIN}

s = open(SRC).read()
for old, new in SNAP.items():
    s = s.replace(f'fill="{old}"', f'fill="{new}"')

def rrect(x0, y0, x1, y1, r):
    return (f"M {x0+r} {y0} L {x1-r} {y0} Q {x1} {y0} {x1} {y0+r} L {x1} {y1-r} "
            f"Q {x1} {y1} {x1-r} {y1} L {x0+r} {y1} Q {x0} {y1} {x0} {y1-r} "
            f"L {x0} {y0+r} Q {x0} {y0} {x0+r} {y0} z")

def window(x0, y0, x1, y1, r=44):
    return (f'<path d="{rrect(x0, y0, x1, y1, r)}" fill="{INK}"/>'
            f'<path d="{rrect(x0+W, y0+W, x1-W, y1-W, max(r-W, 8))}" fill="{PAPER}"/>')

# Tram body is coral x 31..1005, y 53..739; the wheels sit below y 570.
s = s.replace("</svg>", window(150, 190, 510, 500) + window(566, 190, 926, 500) + "</svg>")
open(OUT, "w").write(s)
subprocess.run(["rsvg-convert","-w","900","-h","900","-b","#FFFFFF",OUT,"-o","trolley-final.png"],check=True)
print("wrote", OUT)
