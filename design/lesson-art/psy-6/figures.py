#!/usr/bin/env python3
"""The habit loop, drawn: three stops on a circle and the arrows between them, then the
same loop with the middle swapped. Diagram, not chart: the only numbers are none."""
import math, os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
SKY_SOFT = (226, 238, 250)

def arc_arrow(c, cx, cy, r, a0, a1, colour, w=9):
    """An arrow along a circle from angle a0 to a1 (degrees, clockwise from the top)."""
    pts = []
    n = 40
    for i in range(n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n - 90)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    c.line(pts, colour, w)
    # arrow head at the end
    ax, ay = pts[-1]; bx, by = pts[-3]
    ang = math.atan2(ay - by, ax - bx)
    L = 30
    p1 = (ax - L * math.cos(ang - 0.5), ay - L * math.sin(ang - 0.5))
    p2 = (ax - L * math.cos(ang + 0.5), ay - L * math.sin(ang + 0.5))
    c.d.polygon([c.p(*p1), c.p(ax, ay), c.p(*p2)], fill=colour)

def node(c, x, y, label, fill, ink=(255, 255, 255), sub=None, strike=False):
    w = 300; h = 120
    c.rrect(x - w / 2, y - h / 2, x + w / 2, y + h / 2, 34, fill)
    c.text(label, x, y - (12 if sub else 0), 34, ink)
    if sub: c.text(sub, x, y + 30, 22, ink, "Bold")
    if strike:
        c.line([(x - 120, y), (x + 120, y)], CORAL, 10)

def loop(swap=False):
    c = Canvas()
    cx, cy, r = 600, 470, 260
    positions = {"cue": (cx, cy - r), "routine": (cx + r * math.cos(math.radians(30)), cy + r * math.sin(math.radians(30))),
                 "reward": (cx - r * math.cos(math.radians(30)), cy + r * math.sin(math.radians(30)))}
    # arrows between the three, leaving room for the nodes
    gap = 34
    for a0, a1 in ((0 + gap, 120 - gap), (120 + gap, 240 - gap), (240 + gap, 360 - gap)):
        arc_arrow(c, cx, cy, r, a0, a1, FAINT if False else (200, 190, 175))
    node(c, *positions["cue"], "The cue", SKY)
    if swap:
        # The old routine is lifted out of the loop and struck; the new one takes its
        # place, so the arrows still run cue -> routine -> reward.
        nx, ny = positions["routine"]
        node(c, nx + 60, ny + 190, "The routine", (232, 224, 210), MUTED, strike=True)
        node(c, nx, ny, "New routine", MINT)
    else:
        node(c, *positions["routine"], "The routine", CORAL)
    node(c, *positions["reward"], "The reward", GOLD, INK)
    c.text("Keep the cue. Keep the reward. Swap the middle." if swap else "It runs on its own", 600, 80, 40)
    c.save(f"{OUT}/fig-{'06-swap' if swap else '02-loop'}.png")

if __name__ == "__main__":
    loop(); loop(swap=True)
