#!/usr/bin/env python3
"""Loss aversion: the meter, twenty up and twenty down, the coin flip, the same two
dollars, and using it on yourself."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def meter(c, up=None, down=None):
    x, y0, y1 = 600, 200, 740; mid = (y0 + y1) / 2
    c.rrect(x - 60, y0, x + 60, y1, 30, FAINT)
    c.line([(x - 140, mid), (x + 140, mid)], INK, 5); c.text("even", x + 160, mid, 24, MUTED, "Bold", anchor="lm")
    if up: c.rrect(x - 60, mid - up, x + 60, mid, 30, MINT); c.text("+$20", x - 200, mid - up / 2, 32, MINT, anchor="rm")
    if down: c.rrect(x - 60, mid, x + 60, mid + down, 30, CORAL); c.text("-$20", x - 200, mid + down / 2, 32, CORAL, anchor="rm")

def the_meter():
    c = Canvas(); title(c, "How money feels"); meter(c)
    c.save(f"{OUT}/fig-01-meter.png")

def two_ways():
    c = Canvas(); title(c, "Same twenty dollars"); meter(c, up=120, down=250)
    note(c, "leaving lands about twice as hard as arriving", 820)
    c.save(f"{OUT}/fig-04-meter-two.png")

def coin_flip():
    c = Canvas(); title(c, "What makes a coin flip feel fair")
    vbars(c, [("you could lose", 20, CORAL), ("what most people\nwant on the win side", 40, MINT)], fmt=money, base=660, top=240, width=280)
    note(c, "twice the size, just to feel even", 840)
    c.save(f"{OUT}/fig-05-coin-flip.png")

def same_two():
    c = Canvas(); title(c, "The same $2, two signs")
    rows = [("a cash discount", "a gain you skip. Shrug.", MINT), ("a card surcharge", "a loss you take. Anger.", CORAL)]
    for i, (head, sub, col) in enumerate(rows):
        y = 230 + i * 240
        c.rrect(120, y, 1080, y + 180, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 20, 180, y + 160, 12, col)
        c.text(head, 220, y + 66, 34, INK, anchor="lm"); c.text(sub, 220, y + 122, 24, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-07-same-two.png")

def use_it():
    c = Canvas(); title(c, "Use it on yourself")
    rows = [("'I gain $5 if I go to the gym'", "works a little", STONE), ("'I lose $5 if I skip the gym'", "works about twice as hard", MINT)]
    for i, (head, sub, col) in enumerate(rows):
        y = 230 + i * 240
        c.rrect(120, y, 1080, y + 180, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 20, 180, y + 160, 12, col)
        c.text(head, 220, y + 66, 30, INK, anchor="lm"); c.text(sub, 220, y + 122, 24, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-09-use-it.png")

if __name__ == "__main__":
    two_ways(); coin_flip(); same_two(); use_it()
