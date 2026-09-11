#!/usr/bin/env python3
"""Good debt, bad debt: a rate is rent, the $1,000 night out on a card, the payoff
order, and the zero-percent deadline."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def rate_is_rent():
    c = Canvas(); title(c, "24% a year is a price")
    stack(c, [("what you borrowed", 1000, STONE), ("rent for a year", 240, CORAL)], fmt=money, top=240, bottom=740, ink=WHITE)
    note(c, "owe $1,000 for a year at 24%: $240 for the owing, nothing bought", 820)
    c.save(f"{OUT}/fig-02-rate.png")

def night_out():
    c = Canvas(); title(c, "A $1,000 night, paid at $25 a month")
    r = 0.02; n = math.ceil(-math.log(1 - r * 1000 / 25) / math.log(1 + r)); total = n * 25
    vbars(c, [("the night", 1000, GOLD), (f"what you pay back\nover {n // 12} years {n % 12} months", total, CORAL)], fmt=money, base=680, top=220, width=260)
    note(c, f"{money(total - 1000)} of that is rent on a night you forgot", 830)
    c.save(f"{OUT}/fig-06-night-out.png")

def order():
    c = Canvas(); title(c, "If you owe on more than one thing")
    rows = [("credit card", "24%", CORAL, "every spare dollar goes here"), ("car loan", "8%", GOLD, "minimum"), ("student loan", "5%", MINT, "minimum")]
    for i, (name, rate, col, what) in enumerate(rows):
        y = 200 + i * 170
        c.rrect(120, y, 1080, y + 130, 34, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 20, 330, y + 110, 26, col); c.text(rate, 235, y + 65, 36, WHITE if col != GOLD else INK)
        c.text(name, 370, y + 48, 30, INK, anchor="lm")
        c.text(what, 370, y + 92, 22, MUTED, "Bold", anchor="lm")
    note(c, "highest rate first, always. That order saves the most.", 780)
    c.save(f"{OUT}/fig-07-order.png")

def zero_percent():
    c = Canvas(); title(c, "Zero percent for twelve months")
    x0, x1, y = 120, 1080, 480
    c.line([(x0, y), (x1, y)], STONE, 8)
    for m in range(0, 13, 3):
        x = x0 + (x1 - x0) * m / 12
        c.dot(x, y, 8, STONE); c.text(f"month {m}" if m else "day 1", x, y + 44, 22, MUTED, "Bold")
    c.rrect(x0, y - 120, x1 - 80, y - 60, 20, MINT_SOFT); c.text("0%: no interest charged, yet", (x0 + x1 - 80) / 2, y - 90, 24, MINT, "Bold")
    c.rrect(x1 - 60, y - 220, x1 + 60, y - 30, 26, CORAL); c.text("all of it", x1, y - 150, 24, WHITE, "Bold"); c.text("at once", x1, y - 110, 24, WHITE, "Bold")
    note(c, "still owe anything on the last day, or pay late once, and the skipped interest lands", 640, size=22)
    c.save(f"{OUT}/fig-08-zero-percent.png")

if __name__ == "__main__":
    rate_is_rent(); night_out(); order(); zero_percent()
