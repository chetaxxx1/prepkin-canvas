#!/usr/bin/env python3
"""Stoicism: the two groups, where worry goes, and the one question."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255)

def two_groups():
    c = Canvas()
    c.text("Two groups", 600, 80, 44)
    cols = [(90, 570, "Yours", MINT, ["your effort", "your reaction", "what you say", "what you do next"]),
            (630, 1110, "Not yours", (200, 190, 175), ["the posted grade", "the curve", "what they scored", "what people think"])]
    for x0, x1, head, col, items in cols:
        c.rrect(x0, 160, x1, 820, 36, col)
        c.text(head, (x0 + x1) / 2, 230, 36, WHITE if col == MINT else INK)
        for i, it in enumerate(items):
            y = 320 + i * 120
            c.rrect(x0 + 30, y, x1 - 30, y + 90, 24, WHITE)
            c.text(it, (x0 + x1) / 2, y + 45, 28, INK)
    c.save(f"{OUT}/fig-02-two-groups.png")

def energy():
    c = Canvas()
    c.text("Where the energy goes", 600, 80, 44)
    # two evenings, same energy, different split
    for i, (head, worry, act, col) in enumerate((("A bad evening", 80, 20, CORAL), ("A Stoic evening", 15, 85, MINT))):
        x0 = 120 + i * 520; x1 = x0 + 440
        c.text(head, (x0 + x1) / 2, 190, 30, INK)
        top, bottom = 250, 720
        h = bottom - top
        c.rrect(x0, top, x1, bottom, 30, FAINT)
        c.rrect(x0, top, x1, top + h * worry / 100, 30, (200, 190, 175))
        c.rrect(x0, top + h * worry / 100 - 30, x1, top + h * worry / 100, 0, (200, 190, 175))
        c.rrect(x0, top + h * worry / 100, x1, bottom, 30, col)
        c.rrect(x0, top + h * worry / 100, x1, top + h * worry / 100 + 30, 0, col)
        c.text(f"{worry}% worry", (x0 + x1) / 2, top + h * worry / 200, 26, INK if worry > 30 else WHITE, "Bold")
        c.text(f"{act}% action", (x0 + x1) / 2, top + h * worry / 100 + h * act / 200, 26, WHITE, "Bold")
    c.text("Worry is spent on the second group. Action on the first.", 600, 800, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-05-energy.png")

def question():
    c = Canvas()
    c.rrect(250, 120, 950, 260, 40, INK)
    c.text("Is this in my control?", 600, 190, 38, WHITE)
    for x, ans, col, what in ((330, "No", (200, 190, 175), "let it go"), (870, "Yes", MINT, "act on it today")):
        c.line([(600, 260), (x, 420)], (200, 190, 175), 6)
        c.rrect(x - 200, 420, x + 200, 540, 34, col)
        c.text(ans, x, 480, 40, INK if col != MINT else WHITE)
        c.rrect(x - 200, 580, x + 200, 700, 34, WHITE, outline=FAINT, ow=4)
        c.text(what, x, 640, 30, INK)
    c.text("The whole practice, in one question", 600, 800, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-question.png")

if __name__ == "__main__":
    two_groups(); energy(); question()
