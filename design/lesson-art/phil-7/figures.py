#!/usr/bin/env python3
"""The ship of Theseus: planks replaced in three stages, the two claims, and the rule
you choose."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
OLD = (150, 112, 80); NEW = (222, 190, 140)

def hull(c, cx, cy, new_fraction, label):
    """A simple hull of ten planks, the first new_fraction of them in new wood."""
    w, h = 300, 150; n = 10
    for i in range(n):
        y0 = cy - h / 2 + i * (h / n)
        inset = (abs(i - (n - 1) / 2) / ((n - 1) / 2)) ** 2 * 40 if i > n / 2 else 0
        col = NEW if i < round(new_fraction * n) else OLD
        c.rrect(cx - w / 2 + inset, y0 + 2, cx + w / 2 - inset, y0 + h / n - 2, 4, col)
    c.text(label, cx, cy + h / 2 + 40, 26, INK, "Bold")

def stages():
    c = Canvas(); title(c, "One plank at a time")
    for i, (f, label) in enumerate(((0, "the original"), (0.4, "a third new"), (1.0, "all new wood"))):
        hull(c, 220 + i * 380, 440, f, label)
    legend(c, [("original planks", OLD), ("replacement planks", NEW)], 700, x0=330, gap=300)
    c.save(f"{OUT}/fig-03-stages.png")

def claims():
    c = Canvas(); title(c, "Two ships, two claims")
    columns(c, ("The harbour ship", ["never stopped being the ship", "same name, same crew", "the whole history"], SKY), ("The rebuilt ship", ["every original plank", "the wood Theseus touched", "the material"], GOLD), y0=170, y1=780)
    c.save(f"{OUT}/fig-05-claims.png")

def rule():
    c = Canvas(); title(c, "'Same' is a rule you choose")
    steps(c, [("Same by history", "the one that never stopped being it", SKY), ("Same by material", "the one made of the original stuff", GOLD)], y0=230, h=190, num=False)
    note(c, "pick the rule, and the puzzle answers itself", 760)
    c.save(f"{OUT}/fig-08-rule.png")

if __name__ == "__main__":
    stages(); claims(); rule()
