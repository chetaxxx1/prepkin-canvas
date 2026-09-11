#!/usr/bin/env python3
"""The sunk cost trap, drawn: the $15 that is gone on both branches, the 90 minutes that
are still yours, and the line between spent and still-yours."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255)

def arrow(c, x0, y0, x1, y1, colour, w=8):
    import math
    c.line([(x0, y0), (x1, y1)], colour, w)
    ang = math.atan2(y1 - y0, x1 - x0); L = 28
    p1 = (x1 - L * math.cos(ang - 0.5), y1 - L * math.sin(ang - 0.5))
    p2 = (x1 - L * math.cos(ang + 0.5), y1 - L * math.sin(ang + 0.5))
    c.d.polygon([c.p(*p1), c.p(x1, y1), c.p(*p2)], fill=colour)

# ---------------------------------------------------------------- 2: gone either way
def either_way():
    c = Canvas()
    c.text("Twenty minutes in. Two choices.", 600, 80, 44)
    # the fork
    c.rrect(430, 170, 770, 290, 34, FAINT)
    c.text("bad movie", 600, 230, 34, INK)
    arrow(c, 540, 300, 330, 430, MUTED); arrow(c, 660, 300, 870, 430, MUTED)
    for x, label, col in ((330, "Stay", CORAL), (870, "Leave", MINT)):
        c.rrect(x - 150, 440, x + 150, 560, 34, col)
        c.text(label, x, 500, 40, WHITE)
        # the ticket under each branch, spent both ways
        c.rrect(x - 150, 600, x + 150, 720, 28, WHITE, outline=FAINT, ow=4)
        c.text("$15", x, 645, 40, MUTED)
        c.line([(x - 60, 645), (x + 60, 645)], CORAL, 8)
        c.text("spent either way", x, 695, 22, MUTED, "Bold")
    c.text("The ticket does not get a vote", 600, 810, 30, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-either-way.png")

# ---------------------------------------------------------------- 3: what is still yours
def ninety():
    c = Canvas()
    c.text("What the decision is actually about", 600, 80, 42)
    x0, x1 = 120, 1080; y0, y1 = 360, 520
    total = 110  # minutes
    split = x0 + (x1 - x0) * 20 / total
    c.rrect(x0, y0, x1, y1, 30, MINT_SOFT)
    c.rrect(x0, y0, split, y1, 30, FAINT)
    c.rrect(split - 30, y0, split, y1, 0, FAINT)
    c.text("20 min", (x0 + split) / 2, 440, 28, MUTED)
    c.text("watched", (x0 + split) / 2, 476, 20, MUTED, "Bold")
    c.text("the next 90 minutes", (split + x1) / 2, 424, 40, INK)
    c.text("still yours to spend", (split + x1) / 2, 472, 26, MUTED, "Bold")
    c.dash(split, 300, split, 580, INK, 4)
    c.text("now", split, 270, 26, INK)
    c.text("gone", (x0 + split) / 2, 620, 26, MUTED, "Bold")
    c.text("the only part you still control", (split + x1) / 2, 620, 26, MINT, "Bold")
    c.save(f"{OUT}/fig-03-ninety.png")

# ---------------------------------------------------------------- 7: the line
def the_line():
    c = Canvas()
    c.text("Draw the line", 600, 80, 44)
    y = 450
    c.line([(140, y), (1060, y)], INK, 6)
    c.text("spent", 160, y - 30, 26, MUTED, "Bold", anchor="lm")
    c.text("still yours", 160, y + 30, 26, MINT, "Bold", anchor="lm")
    above = [("$15 ticket", 300), ("20 minutes", 600), ("3 semesters", 900)]
    for label, x in above:
        c.rrect(x - 140, y - 200, x + 140, y - 90, 28, FAINT)
        c.text(label, x, y - 145, 30, MUTED)
        c.line([(x - 90, y - 145), (x + 90, y - 145)], CORAL, 8)
    below = [("90 minutes", 300), ("tonight", 600), ("3 more semesters", 900)]
    for label, x in below:
        c.rrect(x - 135, y + 90, x + 135, y + 200, 28, MINT)
        c.text(label, x, y + 145, 26, WHITE)
    c.text("Decide with what is below the line", 600, 780, 30, INK)
    c.save(f"{OUT}/fig-07-line.png")

if __name__ == "__main__":
    either_way(); ninety(); the_line()
