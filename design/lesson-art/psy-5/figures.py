#!/usr/bin/env python3
"""The spotlight effect: Gilovich 2000, by about double, the flipped question, and
the halving rule."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def study():
    c = Canvas(); title(c, "Who noticed the shirt")
    vbars(c, [("what the wearers\nguessed", 46, CORAL), ("who actually\nnoticed", 23, MINT)], fmt=lambda v: f"{v}%", base=660, top=220, width=280)
    note(c, "Gilovich, Medvec and Savitsky, 2000", 840, size=22)
    c.save(f"{OUT}/fig-03-study.png")

def double():
    c = Canvas(); title(c, "Off by about double")
    rows = ["the stumble on the stairs", "the wrong answer in class", "the bad haircut"]
    for i, label in enumerate(rows):
        y = 200 + i * 160
        c.text(label, 120, y + 40, 26, INK, "Bold", anchor="lm")
        c.rrect(560, y + 10, 1080, y + 70, 20, FAINT); c.rrect(560, y + 10, 820, y + 70, 20, CORAL)
    legend(c, [("who actually noticed", CORAL), ("who you think noticed", FAINT)], 720, x0=200, gap=420)
    note(c, "half the people you think saw it did not", 820)
    c.save(f"{OUT}/fig-04-double.png")

def flip():
    c = Canvas()
    c.rrect(160, 200, 1040, 640, 40, INK)
    c.text("What was the person next to you", 600, 320, 32, WHITE); c.text("wearing last Tuesday?", 600, 380, 32, WHITE)
    c.text("that blank is how much they remember about you", 600, 520, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-07-flip.png")

def rule():
    c = Canvas(); title(c, "The halving rule")
    steps(c, [("Whatever you think they noticed", "halve it", CORAL), ("However long you think they will remember", "halve that too", GOLD), ("What is left", "about the truth, and not much", MINT)], y0=190, h=170)
    c.save(f"{OUT}/fig-09-rule.png")

if __name__ == "__main__":
    study(); double(); flip(); rule()
