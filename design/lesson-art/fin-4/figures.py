#!/usr/bin/env python3
"""Credit scores, plainly: the FICO range and bands, the five inputs and their weights,
what 30% of a limit looks like, and a late mark next to a balance."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255)
BANDS = [(300, 579, "poor", CORAL), (580, 669, "fair", GOLD), (670, 739, "good", (150, 200, 120)),
         (740, 799, "very good", MINT), (800, 850, "exceptional", SKY)]
WEIGHTS = [("Paying on time", 35, CORAL), ("How much of your limit you use", 30, GOLD),
           ("How long you have had credit", 15, SKY), ("Mix of card and loan", 10, FAINT), ("New applications", 10, FAINT)]

def gauge():
    c = Canvas()
    c.text("300 to 850", 600, 80, 44)
    cx, cy, r, w = 600, 660, 380, 90
    lo, hi = 300, 850
    def ang(v):  # 180 degrees, left to right
        return math.pi + math.pi * (v - lo) / (hi - lo)
    for a, b, label, col in BANDS:
        a0, a1 = ang(a), ang(b + 1 if b < hi else hi)
        c.d.arc([c.p(cx - r, cy - r), c.p(cx + r, cy + r)], math.degrees(a0), math.degrees(a1), fill=col, width=int(w * SS))
        m = (a0 + a1) / 2
        c.text(label, cx + (r + 125) * math.cos(m), cy + (r + 125) * math.sin(m), 24, INK, "Bold")
    # the boundary numbers, just outside the arc
    for v in (300, 580, 670, 740, 800, 850):
        a = ang(v)
        c.text(str(v), cx + (r + 72) * math.cos(a), cy + (r + 72) * math.sin(a), 20, MUTED, "Bold")
    # the needle at the US average
    avg = 715
    a = ang(avg)
    c.line([(cx, cy), (cx + (r - w / 2 - 20) * math.cos(a), cy + (r - w / 2 - 20) * math.sin(a))], INK, 8)
    c.dot(cx, cy, 22, INK)
    c.text(f"US average: about {avg}", cx, cy + 70, 30, INK)
    c.save(f"{OUT}/fig-02-gauge.png")

def inputs():
    c = Canvas()
    c.text("What feeds the number", 600, 80, 44)
    x0 = 470; scale = 17
    for i, (label, pct, col) in enumerate(WEIGHTS):
        y = 190 + i * 130
        c.text(label, x0 - 24, y + 40, 24, INK, "Bold", anchor="rm")
        c.rrect(x0, y, x0 + pct * scale, y + 80, 22, col)
        c.text(f"{pct}%", x0 + pct * scale + 20, y + 40, 30, INK, anchor="lm")
    c.text("The top two are 65% of the score, and both are in your hands", 600, 840, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-inputs.png")

def utilization():
    c = Canvas()
    c.text("How much of the limit you use", 600, 80, 44)
    x0, x1 = 120, 1080
    rows = [(300, "30%: the usual ceiling", GOLD), (100, "10%: better", MINT), (800, "80%: hurts", CORAL)]
    for i, (used, label, col) in enumerate(rows):
        y = 200 + i * 200
        c.rrect(x0, y, x1, y + 90, 26, FAINT)
        c.rrect(x0, y, x0 + (x1 - x0) * used / 1000, y + 90, 26, col)
        c.text(money(used), x0 + 30, y + 45, 28, WHITE if used > 150 else INK, anchor="lm")
        c.text(label, x0, y + 130, 26, INK, "Bold", anchor="lm")
    c.text("a $1,000 limit", x1, 170, 24, MUTED, "Bold", anchor="rm")
    c.save(f"{OUT}/fig-05-utilization.png")

def late_vs_balance():
    c = Canvas()
    c.text("Which one hurts more?", 600, 80, 44)
    cols = [(120, 580, "Paid in full, 30 days late", CORAL_SOFT, CORAL, "the mark stays 7 years"),
            (620, 1080, "Paid the minimum, on time", MINT_SOFT, MINT, "gone the month you clear it")]
    for x0, x1, head, soft, col, foot in cols:
        c.rrect(x0, 170, x1, 800, 36, soft)
        c.text(head, (x0 + x1) / 2, 230, 28, INK)
        # a seven-year timeline
        ty = 520
        c.line([(x0 + 50, ty), (x1 - 50, ty)], (200, 190, 175), 6)
        for yr in range(8):
            xx = x0 + 50 + (x1 - x0 - 100) * yr / 7
            c.dot(xx, ty, 7, (200, 190, 175))
            c.text(str(yr), xx, ty + 36, 18, MUTED, "Bold")
        if col == CORAL:
            c.rrect(x0 + 50, ty - 40, x1 - 50, ty - 12, 14, CORAL)
        else:
            c.rrect(x0 + 50, ty - 40, x0 + 50 + (x1 - x0 - 100) / 7 * 0.4, ty - 12, 14, MINT)
        c.text("years on your report", (x0 + x1) / 2, ty + 80, 20, MUTED, "Bold")
        c.text(foot, (x0 + x1) / 2, 720, 24, col, "Bold")
    c.save(f"{OUT}/fig-07-late-vs-balance.png")

if __name__ == "__main__":
    gauge(); inputs(); utilization(); late_vs_balance()
