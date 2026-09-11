#!/usr/bin/env python3
"""Why a dollar shrinks: the $8 burrito, four-fifths, the ten-year race, $500 in a
drawer, and where each pile of money should live."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def price():
    c = Canvas(); title(c, "Same burrito, five years apart")
    vbars(c, [("2020", 8, GOLD), ("2025", 10, CORAL)], fmt=money, base=700, top=220, width=260)
    note(c, "prices across almost everything rose about a quarter", 820)
    c.save(f"{OUT}/fig-02-price.png")

def four_fifths():
    c = Canvas(); title(c, "What $8 buys now")
    x0, x1, y0, y1 = 200, 1000, 330, 560
    c.rrect(x0, y0, x1, y1, 60, FAINT)
    c.rrect(x0, y0, x0 + (x1 - x0) * 0.8, y1, 60, GOLD)
    c.text("four-fifths of a burrito", x0 + (x1 - x0) * 0.4, (y0 + y1) / 2, 30, INK)
    c.text("gone", x0 + (x1 - x0) * 0.9, (y0 + y1) / 2, 26, MUTED, "Bold")
    note(c, "the number stayed. The dollar shrank.", 680)
    c.save(f"{OUT}/fig-03-four-fifths.png")

def race():
    c = Canvas(); title(c, "Ten years, three ways to hold $1,000", 40)
    x0, x1, y0, y1 = 200, 860, 180, 720; ymax = 1600
    axes(c, x0, x1, y0, y1, 10, ymax, 400, 2, fmt=money, xunit="")
    c.text("years", x1 - 20, y1 + 70, 22, MUTED, "Bold")
    p1 = curve(c, lambda t: 1000 * 1.04 ** t, 10, x0, x1, y0, y1, ymax, MINT)
    p2 = curve(c, lambda t: 1000 * 1.03 ** t, 10, x0, x1, y0, y1, ymax, CORAL)
    p3 = curve(c, lambda t: 1000 * 1.001 ** t, 10, x0, x1, y0, y1, ymax, STONE)
    for pts, label, col in ((p1, "savings at 4%", MINT), (p2, "prices, +3% a year", CORAL), (p3, "savings at 0.1%", STONE)):
        x, y = pts[-1]; c.text(label, x + 20, y, 24, col, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-05-race.png")

def drawer():
    c = Canvas(); title(c, "$500 in a drawer for five years")
    vbars(c, [("what the bills say", 500, STONE), ("what they buy,\nin today's prices", 500 / 1.03 ** 5, CORAL)], fmt=money, base=680, top=220, width=260)
    note(c, "at 3% a year, the shelf disagrees with the drawer", 830)
    c.save(f"{OUT}/fig-07-drawer.png")

def where():
    c = Canvas(); title(c, "Where each pile lives")
    steps(c, [("This month's money", "cash, in the account you spend from", GOLD), ("This year's money", "a savings account paying close to inflation", MINT), ("Money for years from now", "somewhere it can grow faster than prices", SKY)], y0=190, h=170, num=False)
    c.save(f"{OUT}/fig-09-where.png")

if __name__ == "__main__":
    price(); four_fifths(); race(); drawer(); where()
