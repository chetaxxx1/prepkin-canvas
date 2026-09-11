#!/usr/bin/env python3
"""What an apartment really costs: day one, the monthly extras, the two piles, two
roommates, and the rule of thumb."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
RENT = 1200; EXTRAS = [("power", 100, CORAL), ("water", 50, SKY), ("gas", 30, GOLD), ("wifi", 60, MINT), ("renters insurance", 15, STONE)]

def day_one():
    c = Canvas(); title(c, "Before you get a key")
    stack(c, [("first month", RENT, GOLD), ("deposit", RENT, SKY)], fmt=money, top=220, bottom=760, ink=WHITE)
    note(c, "$2,400 on day one. The deposit comes back when you leave it clean.", 830, size=22)
    c.save(f"{OUT}/fig-02-day-one.png")

def monthly():
    c = Canvas(); title(c, "Every month, on top of rent")
    hbars(c, EXTRAS, fmt=money, x0=460, y0=190, step=112)
    note(c, f"{money(sum(v for _, v, _ in EXTRAS))} a month the listing never mentioned", 800)
    c.save(f"{OUT}/fig-03-monthly.png")

def two_piles():
    c = Canvas(); title(c, "The two piles")
    cols = [(120, 580, "to walk in", [("first month", 1200), ("deposit", 1200), ("furniture, used", 800)], GOLD), (620, 1080, "every month", [("rent", 1200), ("bills and wifi", 240), ("renters insurance", 15)], MINT)]
    for x0, x1, head, rows, col in cols:
        c.rrect(x0, 170, x1, 780, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(x0, 170, x1, 250, 36, col); c.rrect(x0, 220, x1, 250, 0, col)
        c.text(head, (x0 + x1) / 2, 210, 30, WHITE if col == MINT else INK)
        for i, (label, v) in enumerate(rows):
            y = 320 + i * 90
            c.text(label, x0 + 40, y, 26, INK, "Bold", anchor="lm"); c.text(money(v), x1 - 40, y, 26, MUTED, "Bold", anchor="rm")
        c.line([(x0 + 40, 600), (x1 - 40, 600)], FAINT, 3)
        c.text(money(sum(v for _, v in rows)), (x0 + x1) / 2, 680, 44, col if col == MINT else GOLD)
    c.save(f"{OUT}/fig-05-two-piles.png")

def roommates():
    c = Canvas(); title(c, "Two roommates, a $1,600 place")
    vbars(c, [("what rent\nlooks like", 800, STONE), ("day one,\neach", 2000, GOLD), ("every month,\neach", 935, MINT)], fmt=money, base=660, top=220, width=220)
    c.save(f"{OUT}/fig-06-roommates.png")

def rule():
    c = Canvas(); title(c, "The rule of thumb")
    steps(c, [("Three months' rent to get in", "first month, deposit, and filling the empty rooms", GOLD), ("Rent plus about 20%, every month", "bills, wifi, insurance", MINT)], y0=230, h=190, num=False)
    note(c, "run any listing through those two numbers", 760)
    c.save(f"{OUT}/fig-08-rule.png")

if __name__ == "__main__":
    day_one(); monthly(); two_piles(); roommates(); rule()
