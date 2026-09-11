#!/usr/bin/env python3
"""Occam's razor: count the assumptions, check the cheap one first, the worksheet."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255); STONE = (200, 190, 175)

def count():
    c = Canvas()
    c.text("Count what each one needs to be true", 600, 80, 40)
    cols = [(90, 570, "I typed it wrong", MINT, ["a typo in my line"]),
            (630, 1110, "The compiler is broken", CORAL, ["a bug exists", "nobody has found it", "it lives in my line", "it only showed today"])]
    for x0, x1, head, col, items in cols:
        c.rrect(x0, 160, x1, 780, 36, WHITE, outline=FAINT, ow=4)
        c.text(head, (x0 + x1) / 2, 220, 30, INK)
        for i, it in enumerate(items):
            y = 290 + i * 100
            c.rrect(x0 + 30, y, x1 - 30, y + 76, 22, MINT_SOFT if col == MINT else CORAL_SOFT)
            c.text(it, (x0 + x1) / 2, y + 38, 26, INK, "Bold")
        c.dot((x0 + x1) / 2, 720, 40, col)
        c.text(str(len(items)), (x0 + x1) / 2, 720, 36, WHITE)
    c.text("assumptions", 330, 800, 22, MUTED, "Bold"); c.text("assumptions", 870, 800, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-04-count.png")

def order():
    c = Canvas()
    c.text("An order, not an answer", 600, 80, 44)
    rows = [("1", "Check the cheap one", "one minute", MINT), ("2", "Then the expensive one", "a day, if you still need it", STONE)]
    for i, (n, head, sub, col) in enumerate(rows):
        y = 220 + i * 260
        c.rrect(120, y, 1080, y + 190, 36, WHITE, outline=FAINT, ow=4)
        c.dot(220, y + 95, 50, col); c.text(n, 220, y + 95, 40, WHITE if col == MINT else INK)
        c.text(head, 310, y + 70, 34, INK, anchor="lm")
        c.text(sub, 310, y + 126, 26, MUTED, "Bold", anchor="lm")
    c.text("If the cheap one holds, you are done. If not, you lost a minute and learned something.", 600, 800, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-05-order.png")

def worksheet():
    c = Canvas()
    c.rrect(120, 60, 1080, 840, 30, WHITE, outline=FAINT, ow=4)
    c.text("Next time something breaks", 600, 130, 36)
    steps = ["Write the two explanations down.", "Count what each one needs to be true.", "Test the smaller number first.", "Every time."]
    for i, s in enumerate(steps):
        y = 230 + i * 130
        c.rrect(180, y, 1020, y + 96, 26, FAINT if i < 3 else MINT)
        c.dot(232, y + 48, 24, INK if i < 3 else WHITE)
        c.text(str(i + 1) if i < 3 else "!", 232, y + 48, 24, WHITE if i < 3 else MINT)
        c.text(s, 280, y + 48, 28, INK if i < 3 else WHITE, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-08-worksheet.png")

if __name__ == "__main__":
    count(); order(); worksheet()
