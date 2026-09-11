#!/usr/bin/env python3
"""Ask for an extension: before not after, then the four lines of the email, one
at a time, then the whole thing."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

LINES = ["The bio lab report is due Friday.", "Could I turn it in Monday at 8am?", "I've attached my draft with the first two sections done.", "Thanks either way."]
LABELS = ["what and when", "the ask, with a date", "proof you've started", "thanks, and stop"]

def email(c, filled, stamp=None):
    c.rrect(120, 150, 1080, 850, 44, WHITE, outline=FAINT, ow=5)
    c.rrect(160, 190, 1040, 250, 20, FAINT); c.text("to: your teacher", 190, 220, 26, MUTED, "Bold", anchor="lm")
    for i in range(4):
        y = 300 + i * 125
        col = MINT if i < filled else FAINT
        c.dot(190, y + 30, 22, col); c.text(str(i + 1), 190, y + 30, 22, WHITE if i < filled else MUTED)
        if i < filled:
            lines = wrap(c, LINES[i], 26, 780)
            for j, ln in enumerate(lines): c.text(ln, 240, y + 18 + j * 34, 26, INK, "Bold", anchor="lm")
            c.text(LABELS[i], 240, y + 32 + len(lines) * 34, 22, MINT, "Bold", anchor="lm")
        else:
            c.rrect(240, y + 14, 700, y + 46, 12, FAINT)
    if stamp: c.text(stamp, 1010, 220, 24, CORAL, "Bold", anchor="rm")

def before_after():
    c = Canvas(); title(c, "Before or after the deadline")
    columns(c, ("Before", ["it is a request", "easy to say yes to", "you look organised"], MINT), ("After", ["it is an excuse", "the policy kicks in", "you look caught out"], STONE), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-before-after.png")

def line(n):
    c = Canvas(); email(c, n); c.save(f"{OUT}/fig-0{n + 2}-line{n}.png")

def whole():
    c = Canvas(); email(c, 4, stamp="sent Thursday, 9pm"); c.save(f"{OUT}/fig-08-whole.png")

if __name__ == "__main__":
    before_after(); [line(n) for n in (1, 2, 3, 4)]; whole()
