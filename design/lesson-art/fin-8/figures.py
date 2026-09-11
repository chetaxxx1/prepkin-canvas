#!/usr/bin/env python3
"""Tax brackets as stacked buckets, 2025 single filer: 10% to $11,925, 12% to $48,475,
22% to $103,350. Standard deduction $15,000."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
B = [(0, 11925, 0.10, MINT), (11925, 48475, 0.12, GOLD), (48475, 103350, 0.22, CORAL)]

def buckets(c, income=None, top=180, bottom=760):
    """Three stacked buckets, filled up to income (taxable). Returns the bucket boxes."""
    x0, x1 = 380, 820; boxes = []
    heights = [0.26, 0.40, 0.34]; y = bottom
    for (lo, hi, rate, col), hfrac in zip(B, heights):
        h = (bottom - top) * hfrac
        c.rrect(x0, y - h, x1, y, 18, WHITE, outline=STONE, ow=4)
        if income is not None and income > lo:
            fill = min(1, (income - lo) / (hi - lo))
            fh = max(14, h * fill)
            c.rrect(x0 + 4, y - fh, x1 - 4, y - 4, 10, col)
        c.text(f"{int(rate * 100)}%", x1 + 40, y - h / 2, 32, INK, anchor="lm")
        c.text(f"{money(lo)} to {money(hi)}", x0 - 40, y - h / 2, 22, MUTED, "Bold", anchor="rm")
        boxes.append((y - h, y)); y -= h
    return boxes

def stacked():
    c = Canvas(); title(c, "Stacked buckets"); buckets(c)
    note(c, "taxable income fills them from the bottom up", 830)
    c.save(f"{OUT}/fig-02-buckets.png")

def first():
    c = Canvas(); title(c, "The bottom bucket"); buckets(c, income=11925)
    note(c, "$11,925 at 10% = $1,193, everyone's first dollars", 830)
    c.save(f"{OUT}/fig-03-first.png")

def second():
    c = Canvas(); title(c, "The next bucket"); buckets(c, income=48475)
    note(c, "$36,550 more at 12% = $4,386. The bottom bucket still pays 10%.", 830, size=22)
    c.save(f"{OUT}/fig-04-second.png")

def spill():
    c = Canvas(); title(c, "$50,000 of taxable income"); buckets(c, income=50000)
    note(c, "only $1,525 reaches the 22% bucket", 830)
    c.save(f"{OUT}/fig-05-spill.png")

def total():
    c = Canvas(); title(c, "What $50,000 actually pays")
    parts = [("10% bucket", 11925 * 0.10, MINT), ("12% bucket", 36550 * 0.12, GOLD), ("22% bucket", 1525 * 0.22, CORAL)]
    tot = sum(p[1] for p in parts)
    vbars(c, [(f"{l}", v, col) for l, v, col in parts] + [("the myth:\n22% of it all", 50000 * 0.22, STONE)], fmt=money, base=680, top=220, width=200)
    note(c, f"{money(tot)} in total, under 12% overall", 830)
    c.save(f"{OUT}/fig-06-total.png")

def deduction():
    c = Canvas(); title(c, "Taxable is not the same as pay")
    stack(c, [("into the buckets", 45000, GOLD), ("deduction, not taxed", 15000, MINT)], fmt=money, top=200, bottom=760, ink=WHITE)
    note(c, "$60,000 of pay, 2025, single filer", 830)
    c.save(f"{OUT}/fig-08-deduction.png")

if __name__ == "__main__":
    stacked(); first(); second(); spill(); total(); deduction()
