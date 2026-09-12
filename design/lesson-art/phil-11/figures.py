#!/usr/bin/env python3
"""The experience machine: what a thought experiment is, three reasons, the small machine,
the twist, status quo bias."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "The idea it tests")
    c.rrect(150, 200, 1050, 380, 40, SKY_SOFT)
    c.text("Is feeling good the only thing that matters?", 600, 290, 32, INK)
    c.text("if yes", 330, 480, 28, MUTED, "Bold"); c.text("if no", 870, 480, 28, MUTED, "Bold")
    c.rrect(150, 520, 550, 680, 34, MINT); c.text("everyone plugs in", 350, 600, 28, WHITE)
    c.rrect(650, 520, 1050, 680, 34, CORAL); c.text("people refuse", 850, 600, 28, WHITE)
    note(c, "Robert Nozick, 1974", y=790, size=22)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def three_reasons():
    c = Canvas(); title(c, "What the no reveals")
    steps(c, [("We want to do things", "not only feel like we did", CORAL), ("We want to be someone", "not a body in a tank", GOLD), ("We want contact with what is real", "even when it is worse", MINT)], y0=180, h=160, step=185)
    c.save(f"{OUT}/fig-03-three-reasons.png")

def feed():
    c = Canvas(); title(c, "The small machine")
    c.rrect(400, 150, 800, 850, 56, WHITE, outline=FAINT, ow=5)
    c.rrect(540, 170, 660, 194, 12, FAINT)
    for i in range(4):
        y = 230 + i * 150
        c.rrect(440, y, 760, y + 125, 24, SKY_SOFT if i % 2 else GOLD_SOFT)
        c.rrect(460, y + 20, 560, y + 40, 8, FAINT); c.rrect(460, y + 60, 700, y + 72, 6, FAINT)
    c.text("a little of the feeling,", 210, 400, 26, INK, "Bold"); c.text("none of the climb", 210, 440, 26, INK, "Bold")
    c.save(f"{OUT}/fig-05-feed.png")

def twist():
    c = Canvas(); title(c, "Both doors say no")
    for i, (q, a, col) in enumerate([("Plug in?", "most say no", CORAL), ("Already in. Unplug?", "most say no", SKY)]):
        x0 = 100 + i * 520
        c.rrect(x0, 200, x0 + 480, 640, 36, col)
        c.text(q, x0 + 240, 330, 34, WHITE)
        c.rrect(x0 + 90, 430, x0 + 390, 530, 30, WHITE); c.text(a, x0 + 240, 480, 28, INK, "Bold")
    note(c, "the 2010 flip, by Felipe De Brigard", y=760, size=22)
    c.save(f"{OUT}/fig-06-twist.png")

def status_quo():
    c = Canvas(); title(c, "Two things inside the no")
    stack(c, [("the real point", 6, CORAL), ("just habit", 4, STONE)], x0=430, x1=770, top=200, bottom=740, fmt=lambda v: "", ink=INK, label_size=28)
    c.text("status quo bias: keeping whatever you already have", 600, 820, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-status-quo.png")

if __name__ == "__main__":
    what_it_is(); three_reasons(); feed(); twist(); status_quo()
