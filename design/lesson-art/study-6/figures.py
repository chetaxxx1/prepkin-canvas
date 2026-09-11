#!/usr/bin/env python3
"""The five-minute start: where the cost is, the timer, most people keep going, the
real permission, and five-minute versions of common tasks."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def where_the_cost_is():
    c = Canvas(); title(c, "Where the hard part is")
    x0, x1, y1 = 140, 1060, 700
    # a wall at the start, then a gentle slope
    pts = [(x0, y1), (x0 + 60, y1), (x0 + 60, 260), (x0 + 120, 300)] + [(x0 + 120 + (x1 - x0 - 120) * t / 20, 300 + 60 * math.sin(t / 3)) for t in range(21)]
    c.area(pts, y1, GOLD_SOFT); c.line(pts, GOLD, 9)
    c.text("starting", x0 + 90, 220, 28, INK); c.text("doing", (x0 + x1) / 2 + 60, 230, 28, INK)
    c.text("minute 1", x0 + 90, y1 + 40, 22, MUTED, "Bold"); c.text("minute 40", x1 - 40, y1 + 40, 22, MUTED, "Bold")
    note(c, "the wall is at the door", 820)
    c.save(f"{OUT}/fig-02-where-the-cost-is.png")

def timer():
    c = Canvas(); title(c, "Five minutes, then a real choice")
    cx, cy, r = 600, 480, 230
    c.d.ellipse([c.p(cx - r, cy - r), c.p(cx + r, cy + r)], fill=WHITE, outline=STONE, width=6 * SS)
    c.d.pieslice([c.p(cx - r + 20, cy - r + 20), c.p(cx + r - 20, cy + r - 20)], -90, -90 + 30, fill=MINT)
    for k in range(12):
        a = math.radians(k * 30 - 90); c.dot(cx + (r - 40) * math.cos(a), cy + (r - 40) * math.sin(a), 6, STONE)
    c.text("5 min", cx, cy + 40, 44, INK)
    c.text("allowed to stop", cx + r + 40, cy - 140, 26, MINT, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-03-timer.png")

def most_keep_going():
    c = Canvas(); title(c, "When the timer rings")
    columns(c, ("Usually", ["you do not hear it", "you are already in", "you keep going"], MINT), ("Sometimes", ["you stop", "that is allowed", "you still started"], STONE), y0=170, y1=780)
    c.save(f"{OUT}/fig-05-most-keep-going.png")

def permission():
    c = Canvas(); title(c, "The permission has to be real")
    columns(c, ("If stopping is banned", ["five minutes means the whole task", "starting costs everything again", "your brain stops falling for it"], STONE), ("If stopping is allowed", ["five minutes means five minutes", "starting is cheap", "you usually keep going anyway"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-07-permission.png")

def starts():
    c = Canvas(); title(c, "The five-minute version")
    rows = [("An essay", "one bad first sentence", CORAL), ("A problem set", "copy out question one", GOLD), ("A chapter", "turn the first heading into a question", SKY), ("An email you are dreading", "write the first line only", MINT)]
    steps(c, rows, y0=170, h=130, step=155, num=False)
    c.save(f"{OUT}/fig-09-starts.png")

if __name__ == "__main__":
    where_the_cost_is(); timer(); most_keep_going(); permission(); starts()
