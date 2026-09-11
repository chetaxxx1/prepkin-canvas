#!/usr/bin/env python3
"""Confirmation bias: the filter, more sure not more right, the flipped question,
Wason's two kinds of test, and the habit."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def filter_fig():
    c = Canvas(); title(c, "Two lanes")
    columns(c, ("Fits what you think", ["feels obviously true", "sails straight through", "remembered"], MINT), ("Does not fit", ["gets a harder look", "or a shrug, or no look", "forgotten by dinner"], STONE), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-filter.png")

def more_sure():
    c = Canvas(); title(c, "More sure, not more right")
    x0, x1, y0, y1 = 200, 1060, 200, 700
    for v in (0, 50, 100):
        y = y1 - (y1 - y0) * v / 100; c.line([(x0, y), (x1, y)], FAINT, 2); c.text(f"{v}%", x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    c.text("weeks", x1 + 20, y1 + 34, 22, MUTED, "Bold", anchor="lm")
    for t, lab in ((0, "0"), (4, "4"), (8, "8")): c.text(lab, x0 + (x1 - x0) * t / 8, y1 + 34, 22, MUTED, "Bold")
    sure = [(x0 + (x1 - x0) * t / 8, y1 - (y1 - y0) * (50 + 45 * (1 - 2.718 ** (-t / 3))) / 100) for t in range(9)]
    right = [(x0 + (x1 - x0) * t / 8, y1 - (y1 - y0) * 0.5) for t in range(9)]
    c.line(sure, CORAL, 9); c.line(right, MINT, 9)
    legend(c, [("how sure you feel", CORAL), ("how right you are", MINT)], 790, x0=240, gap=340)
    c.save(f"{OUT}/fig-04-more-sure.png")

def ask_instead():
    c = Canvas()
    c.rrect(160, 220, 1040, 620, 40, INK)
    c.text("What would I see", 600, 340, 38, WHITE); c.text("if they weren't?", 600, 400, 38, WHITE)
    c.text("look for the evidence that breaks the belief", 600, 520, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-06-ask-instead.png")

def two_tests():
    c = Canvas(); title(c, "Two kinds of test")
    rows = [("8, 10, 12", "fits what you already believe. A yes teaches nothing.", STONE), ("3, 2, 1", "would break it. A yes here changes your mind.", MINT)]
    for i, (seq, sub, col) in enumerate(rows):
        y = 220 + i * 250
        c.rrect(120, y, 1080, y + 190, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 30, 400, y + 160, 30, col); c.text(seq, 270, y + 95, 40, WHITE if col == MINT else INK)
        for j, ln in enumerate(wrap(c, sub, 24, 620)): c.text(ln, 440, y + 70 + j * 34, 24, INK, "Bold", anchor="lm")
    note(c, "the rule was only 'any rising numbers'. Only the second test finds that out.", 780, size=22)
    c.save(f"{OUT}/fig-08-two-tests.png")

def habit():
    c = Canvas(); title(c, "The habit")
    steps(c, [("State the belief", "", SKY), ("Name what would prove it wrong", "", CORAL), ("Go and look for exactly that", "", MINT)], y0=200, h=150)
    c.save(f"{OUT}/fig-09-habit.png")

if __name__ == "__main__":
    filter_fig(); more_sure(); ask_instead(); two_tests(); habit()
