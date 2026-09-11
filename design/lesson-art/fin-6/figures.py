#!/usr/bin/env python3
"""Why index funds beat picking: a slice of everything, the pros' scoreboard, the fee
drag, the expense ratio, and thirty years of the S&P 500 with its dents."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
SP = {1995: 616, 1996: 741, 1997: 970, 1998: 1229, 1999: 1469, 2000: 1320, 2001: 1148, 2002: 880, 2003: 1112, 2004: 1212,
      2005: 1248, 2006: 1418, 2007: 1468, 2008: 903, 2009: 1115, 2010: 1258, 2011: 1258, 2012: 1426, 2013: 1848, 2014: 2059,
      2015: 2044, 2016: 2239, 2017: 2674, 2018: 2507, 2019: 3231, 2020: 3756, 2021: 4766, 2022: 3840, 2023: 4770, 2024: 5882}

def slice_of_everything():
    c = Canvas(); title(c, "A slice of every company on the list")
    cols, rows = 25, 8; s = 32; gap = 8
    x0 = 600 - (cols * (s + gap) - gap) / 2; y0 = 220
    for i in range(cols * rows):
        x = x0 + (i % cols) * (s + gap); y = y0 + (i // cols) * (s + gap)
        c.rrect(x, y, x + s, y + s, 6, MINT if (i * 7) % 5 else (150, 200, 120))
    note(c, "500 companies, one bucket, one rule: buy them all and leave it alone", 640, size=22)
    c.save(f"{OUT}/fig-02-slice.png")

def pros():
    c = Canvas(); title(c, "Twenty years of professional pickers")
    vbars(c, [("beat the index", 10, MINT), ("fell behind it", 90, STONE)], fmt=lambda v: f"{v}%", base=700, top=220, width=300)
    note(c, "large US stock funds, about nine in ten behind, after fees", 820, size=22)
    c.save(f"{OUT}/fig-04-pros.png")

def fees():
    c = Canvas(); title(c, "$10,000 for twenty years")
    a = 10000 * 1.07 ** 20; b = 10000 * 1.06 ** 20
    vbars(c, [("7%, almost no fee", a, MINT), ("7% minus a 1% fee", b, STONE)], fmt=money, base=700, top=220, width=300)
    note(c, f"the 1% fee quietly took {money(a - b)}", 820)
    c.save(f"{OUT}/fig-05-fees.png")

def expense_ratio():
    c = Canvas(); title(c, "The number to find: expense ratio")
    rows = [("0.03%", "broad index fund", "$3 a year on $10,000", MINT), ("1.0%", "a typical picked fund", "$100 a year on $10,000", CORAL)]
    for i, (rate, name, cost, col) in enumerate(rows):
        y = 220 + i * 260
        c.rrect(120, y, 1080, y + 200, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(140, y + 30, 400, y + 170, 30, col); c.text(rate, 270, y + 100, 44, WHITE)
        c.text(name, 440, y + 76, 32, INK, anchor="lm"); c.text(cost, 440, y + 126, 24, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-06-expense-ratio.png")

def long_run():
    c = Canvas(); title(c, "Every crash is a dent in a line that goes up", 40)
    x0, x1, y0, y1 = 200, 1080, 180, 720
    years = sorted(SP); ymax = 6000
    for v in range(0, ymax + 1, 2000):
        y = y1 - (y1 - y0) * v / ymax; c.line([(x0, y), (x1, y)], FAINT, 2); c.text(f"{v:,}", x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    for yr in (1995, 2005, 2015, 2024):
        c.text(str(yr), x0 + (x1 - x0) * (yr - 1995) / 29, y1 + 34, 24, MUTED, "Bold")
    pts = [(x0 + (x1 - x0) * (yr - 1995) / 29, y1 - (y1 - y0) * SP[yr] / ymax) for yr in years]
    c.area(pts, y1, MINT_SOFT); c.line(pts, MINT, 8)
    for yr, label in ((2002, "dot-com"), (2008, "2008"), (2022, "2022")):
        x, y = pts[years.index(yr)]
        c.dot(x, y, 10, CORAL); c.dot(x, y, 5, CREAM)
        c.text(label, x, y + 40, 22, CORAL, "Bold")
    c.text("S&P 500, year-end level", x0 + 10, y0 + 60, 22, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-08-long-run.png")

if __name__ == "__main__":
    slice_of_everything(); pros(); fees(); expense_ratio(); long_run()
