#!/usr/bin/env python3
"""The fundamental attribution error: two boxes, why they split, the one question,
the name, and the flip."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def boxes(c, left_on=False, right_on=False, y0=250, y1=640):
    for k, (label, col, on) in enumerate((("the person", CORAL, left_on), ("the situation", SKY, right_on))):
        x0 = 120 + k * 520; x1 = x0 + 440
        c.rrect(x0, y0, x1, y1, 40, col if on else WHITE, outline=col, ow=8)
        c.text(label, (x0 + x1) / 2, (y0 + y1) / 2, 36, WHITE if on else col)

def two_boxes():
    c = Canvas(); title(c, "Two boxes for the cause"); boxes(c)
    note(c, "every explanation lands in one of them", 760)
    c.save(f"{OUT}/fig-01-two-boxes.png")

def why_split():
    c = Canvas(); title(c, "What you saw")
    c.text("your day", 120, 250, 28, INK, "Bold", anchor="lm")
    c.rrect(120, 290, 1080, 350, 24, MINT); c.text("you saw all of it", 600, 400, 24, MINT, "Bold")
    c.text("their day", 120, 500, 28, INK, "Bold", anchor="lm")
    c.rrect(120, 540, 1080, 600, 24, FAINT); c.dot(760, 570, 22, CORAL)
    c.text("the one moment you saw", 760, 650, 24, CORAL, "Bold")
    note(c, "their moment looks like a personality. Yours looks like a day.", 780, size=22)
    c.save(f"{OUT}/fig-04-why-split.png")

def question():
    c = Canvas()
    c.rrect(160, 220, 1040, 620, 40, INK)
    c.text("What's their situation?", 600, 380, 40, WHITE)
    c.text("not excusing them. Checking the box you skipped.", 600, 520, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-05-question.png")

def name():
    c = Canvas(); title(c, "The fundamental attribution error", 40)
    steps(c, [("Fundamental", "because everyone does it", CORAL), ("Attribution", "because it is about where you put the cause", SKY), ("Error", "because the box is usually wrong", GOLD)], y0=200, h=160, num=False)
    c.save(f"{OUT}/fig-07-name.png")

def flip():
    c = Canvas(); title(c, "Flip it, once a day")
    columns(c, ("Them", ["judged by what they did", "one moment", "the person box"], STONE), ("You", ["judged by what you meant", "the whole day", "the situation box"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-09-flip.png")

if __name__ == "__main__":
    two_boxes(); why_split(); question(); name(); flip()
