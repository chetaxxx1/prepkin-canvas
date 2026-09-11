#!/usr/bin/env python3
"""Anchoring: two stores, the wheel results (Tversky and Kahneman 1974), the pay
range, and the three moves."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def store(c, first, pay, name):
    title(c, f"Store {name}")
    c.rrect(160, 200, 560, 620, 36, CORAL_SOFT); c.text("first tag you see", 360, 260, 22, MUTED, "Bold"); c.text(money(first), 360, 400, 60, CORAL)
    arrow(c, 590, 410, 640, 410, STONE, 6)
    c.rrect(660, 200, 1060, 620, 36, MINT_SOFT); c.text("what you'd pay", 860, 260, 22, MUTED, "Bold"); c.text(money(pay), 860, 400, 60, MINT)
    note(c, "same jacket", 720)

def store_a():
    c = Canvas(); store(c, 1200, 900, "A"); c.save(f"{OUT}/fig-02-store-a.png")

def store_b():
    c = Canvas(); store(c, 300, 450, "B"); c.save(f"{OUT}/fig-03-store-b.png")

def wheel():
    c = Canvas(); title(c, "The wheel and the guess")
    vbars(c, [("wheel landed on 10", 25, SKY), ("wheel landed on 65", 45, CORAL)], fmt=lambda v: f"{v}%", base=660, top=220, width=300)
    note(c, "guessed share of UN countries in Africa. Tversky and Kahneman, 1974.", 840, size=22)
    c.save(f"{OUT}/fig-05-wheel.png")

def pay():
    c = Canvas(); title(c, "Whoever says a number first")
    rows = [("you say $14", "the talk is about $14", STONE), ("you say $18", "the talk is about $18", MINT)]
    for i, (head, sub, col) in enumerate(rows):
        y = 230 + i * 240
        c.rrect(120, y, 1080, y + 180, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 20, 180, y + 160, 12, col)
        c.text(head, 220, y + 66, 34, INK, anchor="lm"); c.text(sub, 220, y + 122, 24, MUTED, "Bold", anchor="lm")
    note(c, "bring your own number before you hear theirs", 760)
    c.save(f"{OUT}/fig-07-pay.png")

def moves():
    c = Canvas(); title(c, "Three moves")
    steps(c, [("Decide what it is worth to you", "before you look", MINT), ("Then look at the price", "", SKY), ("Ignore the crossed-out 'was' number", "it was put there to be your anchor", CORAL)], y0=190, h=170)
    c.save(f"{OUT}/fig-09-moves.png")

if __name__ == "__main__":
    store_a(); store_b(); wheel(); pay(); moves()
