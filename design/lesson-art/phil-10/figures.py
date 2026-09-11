#!/usr/bin/env python3
"""Steelmanning: swinging at straw, the nod test, the two outcomes, three steps."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def strawman():
    c = Canvas(); title(c, "Swinging at straw")
    c.rrect(100, 220, 540, 700, 36, GOLD_SOFT); c.text("the version", 320, 300, 26, MUTED, "Bold"); c.text("you made up", 320, 340, 26, MUTED, "Bold")
    c.text("straw", 320, 470, 44, GOLD)
    c.rrect(660, 220, 1100, 700, 36, SKY_SOFT); c.text("the version", 880, 300, 26, MUTED, "Bold"); c.text("they hold", 880, 340, 26, MUTED, "Bold")
    c.text("steel", 880, 470, 44, SKY)
    arrow(c, 600, 780, 320, 720, CORAL, 10); c.text("you", 600, 810, 26, CORAL, "Bold")
    c.text("still standing", 880, 600, 24, SKY, "Bold"); c.text("knocked flat, changes nothing", 320, 600, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-strawman.png")

def nod():
    c = Canvas()
    c.rrect(200, 120, 1000, 260, 40, INK); c.text("Say their point back. Do they nod?", 600, 190, 32, WHITE)
    for x, ans, col, what in ((330, "Yes, exactly", MINT, "that is steel.\nnow you may argue"), (870, "Not what I meant", CORAL, "that is straw.\nbuild it again")):
        c.line([(600, 260), (x, 400)], STONE, 6)
        c.rrect(x - 210, 400, x + 210, 520, 34, col); c.text(ans, x, 460, 30, WHITE)
        c.rrect(x - 210, 560, x + 210, 720, 34, WHITE, outline=FAINT, ow=4)
        for j, ln in enumerate(what.split("\n")): c.text(ln, x, 620 + j * 40, 26, INK, "Bold")
    c.save(f"{OUT}/fig-04-nod.png")

def outcomes():
    c = Canvas(); title(c, "Aim at the steel one")
    columns(c, ("If it falls", ["you beat the real thing", "they have nothing left", "a win that counts"], MINT), ("If it holds", ["you learned something", "you change your mind", "also a win"], SKY), y0=170, y1=780)
    c.save(f"{OUT}/fig-06-outcomes.png")

def three_steps():
    c = Canvas(); title(c, "Three steps")
    steps(c, [("Listen for their best version", "not their worst", SKY), ("Say it back until they nod", "'yes, that is exactly it'", GOLD), ("Then disagree with that one", "and only that one", CORAL)], y0=190, h=170)
    c.save(f"{OUT}/fig-08-steps.png")

if __name__ == "__main__":
    strawman(); nod(); outcomes(); three_steps()
