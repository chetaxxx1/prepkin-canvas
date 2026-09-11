#!/usr/bin/env python3
"""The first minute of a test: sixty seconds, easy first, the time budget, two
students, and how to mark a question."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def sixty():
    c = Canvas(); title(c, "Sixty seconds. Just reading.")
    cx, cy, r = 600, 480, 220
    c.d.ellipse([c.p(cx - r, cy - r), c.p(cx + r, cy + r)], fill=WHITE, outline=STONE, width=6 * SS)
    c.d.pieslice([c.p(cx - r + 16, cy - r + 16), c.p(cx + r - 16, cy + r - 16)], -90, -90 + 7, fill=CORAL)
    for k in range(12):
        a = math.radians(k * 30 - 90); c.dot(cx + (r - 36) * math.cos(a), cy + (r - 36) * math.sin(a), 6, STONE)
    c.text("1 min", cx, cy + 40, 40, INK)
    c.text("of 50", cx, cy + 90, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-sixty.png")

def order():
    c = Canvas(); title(c, "Easy first, hard marked for later")
    c.rrect(200, 170, 1000, 820, 24, WHITE, outline=FAINT, ow=4)
    kinds = ["easy", "easy", "hard", "easy", "hard", "easy"]
    for i, k in enumerate(kinds):
        y = 230 + i * 95
        col = MINT if k == "easy" else CORAL
        c.dot(260, y + 20, 20, col)
        c.rrect(310, y + 8, 940 - (i % 3) * 80, y + 32, 8, FAINT)
    legend(c, [("do now", MINT), ("mark, skip, come back", CORAL)], 780, x0=300, gap=260)
    c.save(f"{OUT}/fig-03-order.png")

def budget():
    c = Canvas(); title(c, "Fifty minutes")
    x0, x1, y = 120, 1080, 400
    parts = [(1, "read", CORAL), (30, "the ones you know", MINT), (19, "the hard ones", GOLD)]
    x = x0
    for v, label, col in parts:
        w = (x1 - x0) * v / 50
        c.rrect(x, y, x + w, y + 120, 20 if v > 3 else 6, col)
        if v > 3: c.text(f"{v} min", x + w / 2, y + 46, 30, WHITE if col != GOLD else INK); c.text(label, x + w / 2, y + 88, 22, WHITE if col != GOLD else INK, "Bold")
        x += w
    c.text("1 min: read it all", x0, y - 40, 24, CORAL, "Bold", anchor="lm")
    note(c, "the order protects the points you were always going to get", 640, size=22)
    c.save(f"{OUT}/fig-05-budget.png")

def two_students():
    c = Canvas(); title(c, "Same knowledge, two orders")
    columns(c, ("Pushes through", ["15 minutes on question one", "runs out of time", "three easy ones left blank"], STONE), ("Banks the easy ones", ["reads everything first", "easy points in twenty minutes", "comes back to the hard one"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-06-two-students.png")

def marks():
    c = Canvas(); title(c, "How to mark one")
    c.rrect(200, 190, 1000, 760, 24, WHITE, outline=FAINT, ow=4)
    for i in range(4):
        y = 260 + i * 120
        c.dot(270, y + 20, 22, CORAL if i == 1 else FAINT); c.text(str(i + 1), 270, y + 20, 20, WHITE if i == 1 else MUTED, "Bold")
        c.rrect(320, y + 8, 940 - (i % 2) * 120, y + 32, 8, FAINT)
        if i == 1: c.text("later", 320, y + 62, 22, CORAL, "Bold", anchor="lm")
    note(c, "circle the number, one word beside it. It saves the reread when you come back.", 820, size=22)
    c.save(f"{OUT}/fig-08-marks.png")

if __name__ == "__main__":
    sixty(); order(); budget(); two_students(); marks()
