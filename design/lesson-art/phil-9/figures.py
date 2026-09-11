#!/usr/bin/env python3
"""Chesterton's fence: the test, not 'never', and the three questions."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def test():
    c = Canvas()
    c.rrect(200, 110, 1000, 250, 40, INK); c.text("Why is this here?", 600, 180, 36, WHITE)
    for x, ans, col, what in ((330, "I can say", MINT, "keep it, fix it,\nor drop it on purpose"), (870, "I can't yet", CORAL, "not yet.\ngo and find out")):
        c.line([(600, 250), (x, 380)], STONE, 6)
        c.rrect(x - 200, 380, x + 200, 500, 34, col); c.text(ans, x, 440, 34, WHITE)
        c.rrect(x - 200, 540, x + 200, 700, 34, WHITE, outline=FAINT, ow=4)
        for j, ln in enumerate(what.split("\n")): c.text(ln, x, 600 + j * 40, 26, INK, "Bold")
    note(c, "you earn a say by answering", 790)
    c.save(f"{OUT}/fig-04-test.png")

def not_never():
    c = Canvas(); title(c, "Not 'never'")
    rows = [("Never change anything", STONE, True), ("Know the reason first", MINT, False)]
    for i, (label, col, struck) in enumerate(rows):
        y = 260 + i * 240
        c.rrect(160, y, 1040, y + 160, 40, col)
        c.text(label, 600, y + 80, 40, WHITE if col == MINT else INK)
        if struck: c.strike(300, y + 80, 900, y + 80, CORAL, 12)
    note(c, "then keep it, fix it, or drop it. All three are allowed.", 760, size=22)
    c.save(f"{OUT}/fig-07-not-never.png")

def questions():
    c = Canvas(); title(c, "Before you remove anything old")
    steps(c, [("Who put it here?", "", SKY), ("What were they worried about?", "", GOLD), ("Is that still true?", "if not, take it down with a clear conscience", MINT)], y0=200, h=150)
    c.save(f"{OUT}/fig-09-questions.png")

if __name__ == "__main__":
    test(); not_never(); questions()
