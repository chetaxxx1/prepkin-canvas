#!/usr/bin/env python3
"""What benefits mean: the pay stack, four insurance words, the one-line compare, days off,
the match, the total."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_they_are():
    c = Canvas(); title(c, "Pay is more than the number in bold")
    stack(c, [("salary", 58000, GOLD), ("days off", 3346, MINT), ("match", 2320, SKY)], x0=430, x1=770, top=200, bottom=760, fmt=money)
    c.text("minus premiums, which come out of it", 600, 830, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-what-they-are.png")

def four_words():
    c = Canvas(); title(c, "Four insurance words")
    steps(c, [("Premium", "what you pay every month, no matter what", GOLD), ("Deductible", "what you pay yourself before insurance starts", CORAL),
              ("Copay", "the flat fee per visit", SKY), ("Out-of-pocket max", "the most you can pay in a year", MINT)], y0=160, h=135, step=155, num=False)
    c.save(f"{OUT}/fig-03-four-words.png")

def compare():
    c = Canvas(); title(c, "Salary minus a year of premiums")
    vbars(c, [("Job A\n$60,000 minus $3,600", 56400, GOLD), ("Job B\n$58,000 minus $600", 57400, MINT)], fmt=money, base=680, top=220, width=300, gap=160, vmax=60000)
    c.text("B is $1,000 ahead before you see a doctor", 600, 830, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-04-compare.png")

def pto():
    c = Canvas(); title(c, "Days off, priced")
    vbars(c, [("Job A\n10 days at $60,000", 2308, GOLD), ("Job B\n15 days at $58,000", 3346, MINT)], fmt=money, base=680, top=220, width=300, gap=160)
    c.text("a working day is salary divided by 260", 600, 830, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-pto.png")

def match():
    c = Canvas(); title(c, "The match, per year")
    vbars(c, [("Job A\nno match", 0, STONE), ("Job B\n4% of $58,000", 2320, SKY)], fmt=money, base=680, top=220, width=300, gap=160, vmax=2500)
    c.text("free money, if you put some in", 600, 830, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-match.png")

def total():
    c = Canvas(); title(c, "On one line")
    rows = [("Job A", [("salary", 60000), ("premiums", -3600), ("match", 0), ("days off", 2308)], 58708, GOLD),
            ("Job B", [("salary", 58000), ("premiums", -600), ("match", 2320), ("days off", 3346)], 63066, MINT)]
    for k, (name, parts, tot, col) in enumerate(rows):
        y = 190 + k * 300
        c.rrect(100, y, 1100, y + 250, 36, WHITE, outline=FAINT, ow=4)
        c.text(name, 150, y + 50, 32, INK, anchor="lm")
        for i, (lab, v) in enumerate(parts):
            x = 150 + i * 195
            c.text(("+" if v > 0 else "") + (money(v) if v >= 0 else "-" + money(-v)) if v else "$0", x, y + 130, 26, INK if v >= 0 else CORAL, "Bold", anchor="lm")
            c.text(lab, x, y + 170, 22, MUTED, "Bold", anchor="lm")
        c.rrect(930, y + 30, 1080, y + 220, 26, col); c.text(money(tot), 1005, y + 110, 30, WHITE); c.text("a year", 1005, y + 160, 22, WHITE, "Bold")
    c.text("$2,000 apart on paper. $4,358 apart in truth.", 600, 830, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-09-total.png")

if __name__ == "__main__":
    what_they_are(); four_words(); compare(); pto(); match(); total()
