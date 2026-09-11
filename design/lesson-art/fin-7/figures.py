#!/usr/bin/env python3
"""Where your paycheck goes: $1,000 gross, the FICA bites, the net range, and a stub."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
GROSS = 1000; SS = 62; MED = 14.5; TAX = 50; NET = GROSS - SS - MED - TAX
def dollars(v): return f"${v:,.2f}" if v != int(v) else money(v)

def split():
    c = Canvas(); title(c, "$1,000, before and after")
    hbars(c, [("take-home", NET, MINT), ("Social Security", SS, CORAL), ("income tax", TAX, GOLD), ("Medicare", MED, SKY)], fmt=dollars, x0=430, y0=200, step=140, vmax=1000)
    note(c, "two fixed bites, one that varies, and the rest is yours", 800)
    c.save(f"{OUT}/fig-02-split.png")

def social_security():
    c = Canvas(); title(c, "Social Security: 6.2%")
    stack(c, [("the rest", GROSS - SS, FAINT), ("Social Security", SS, CORAL)], fmt=dollars, top=200, bottom=760, ink=INK)
    note(c, "$62 of every $1,000, paid to people who are retired now", 830)
    c.save(f"{OUT}/fig-03-ss.png")

def medicare():
    c = Canvas(); title(c, "Medicare: 1.45%. Together, FICA: 7.65%")
    hbars(c, [("Social Security", 6.2, CORAL), ("Medicare", 1.45, SKY), ("FICA, both", 7.65, INK)], fmt=lambda v: f"{v}%", x0=420, y0=220, step=150, vmax=8)
    note(c, "$76.50 of every $1,000, from almost every worker", 780)
    c.save(f"{OUT}/fig-04-medicare.png")

def net_range():
    c = Canvas(); title(c, "What lands in your account")
    x0, x1 = 120, 1080; y = 420
    c.rrect(x0, y, x1, y + 100, 30, FAINT)
    lo, hi = 825, 925
    c.rrect(x0 + (x1 - x0) * lo / 1000, y, x0 + (x1 - x0) * hi / 1000, y + 100, 30, MINT)
    c.text("$0", x0, y + 150, 24, MUTED, "Bold"); c.text("$1,000 gross", x1 - 40, y + 150, 24, MUTED, "Bold")
    c.text("$825 to $925 net", x0 + (x1 - x0) * 800 / 1000, y - 50, 34, INK)
    note(c, "the gap is FICA plus whatever income tax your W-4 set", 700)
    c.save(f"{OUT}/fig-06-net.png")

def stub():
    c = Canvas()
    c.rrect(160, 60, 1040, 840, 24, WHITE, outline=FAINT, ow=4)
    c.text("Pay statement", 220, 130, 34, INK, anchor="lm")
    c.line([(220, 170), (980, 170)], FAINT, 3)
    rows = [("Gross pay", GROSS, INK), ("Social Security (6.2%)", -SS, CORAL), ("Medicare (1.45%)", -MED, SKY), ("Federal income tax", -TAX, GOLD)]
    for i, (label, v, col) in enumerate(rows):
        y = 240 + i * 90
        c.text(label, 220, y, 28, INK, "Bold", anchor="lm")
        c.text(("-" if v < 0 else "") + dollars(abs(v)), 980, y, 28, col, anchor="rm")
    c.line([(220, 620), (980, 620)], INK, 4)
    c.text("Net pay", 220, 690, 34, INK, anchor="lm"); c.text(dollars(NET), 980, 690, 34, MINT, anchor="rm")
    c.text("what lands in your account", 220, 760, 22, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-08-stub.png")

if __name__ == "__main__":
    split(); social_security(); medicare(); net_range(); stub()
