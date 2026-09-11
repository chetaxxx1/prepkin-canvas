#!/usr/bin/env python3
"""Why the minimum payment is a trap: every number on these five figures comes from the
simulation at the bottom ($1,000 at 22%, minimum = 1% + interest, $25 floor)."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255)

def run(fixed=None, balance=1000.0, apr=0.22, floor=25.0):
    hist = [balance]; paid = 0.0; interest = 0.0; first = None
    while balance > 0.005:
        i = balance * apr / 12
        pay = fixed if fixed else max(floor, 0.01 * balance + i)
        pay = min(pay, balance + i)
        if first is None: first = (pay, i, pay - i)
        balance += i - pay; paid += pay; interest += i; hist.append(max(balance, 0.0))
    return hist, paid, interest, first

MIN, MIN_PAID, MIN_INT, MIN_FIRST = run()
FIFTY, FIFTY_PAID, FIFTY_INT, _ = run(50)
THREE_YEAR = 38.2
_, TY_PAID, TY_INT, _ = run(THREE_YEAR)

def ym(months):
    y, m = divmod(months, 12)
    return f"{y} yr {m} mo" if m else f"{y} yr"

# ---------------------------------------------------------------- 2: month one
def month_one():
    c = Canvas()
    c.text("Month one: the $28 minimum", 600, 80, 44)
    pay, i, principal = MIN_FIRST
    x0, x1 = 300, 900; top, bottom = 200, 700
    scale = (bottom - top) / pay
    yi = bottom - i * scale
    c.rrect(x0, top, x1, bottom, 30, CORAL)            # interest block on top
    c.rrect(x0, yi, x1, bottom, 30, MINT)              # principal at the bottom
    c.rrect(x0, yi - 30, x1, yi + 30, 0, MINT)         # square the seam
    c.text(money(i), 600, (top + yi) / 2 - 18, 52, WHITE)
    c.text("interest, for still owing the money", 600, (top + yi) / 2 + 34, 24, WHITE, "Bold")
    c.text(money(principal), 600, (yi + bottom) / 2 - 14, 44, WHITE)
    c.text("comes off the $1,000", 600, (yi + bottom) / 2 + 30, 24, WHITE, "Bold")
    c.text("$1,000 at 22%, minimum = 1% of the balance + interest", 600, 780, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-month-one.png")

# ---------------------------------------------------------------- 3: the slow slide
def axes(c, x0, x1, y0, y1, months, ymax):
    for v in range(0, ymax + 1, 250):
        y = y1 - (y1 - y0) * v / ymax
        c.line([(x0, y), (x1, y)], FAINT, 2)
        c.text(money(v), x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    for yr in range(0, months // 12 + 1):
        x = x0 + (x1 - x0) * yr * 12 / months
        c.text(str(yr), x, y1 + 34, 24, MUTED, "Bold")
    c.text("years", x1 + 24, y1 + 34, 24, MUTED, "Bold", anchor="lm")

def series(c, hist, x0, x1, y0, y1, months, ymax, colour, fill=None):
    pts = [(x0 + (x1 - x0) * m / months, y1 - (y1 - y0) * v / ymax) for m, v in enumerate(hist)]
    if fill: c.area(pts, y1, fill)
    c.line(pts, colour, 9)
    return pts

def slide():
    c = Canvas()
    c.text("Paying the minimum", 600, 80, 44)
    x0, x1, y0, y1 = 200, 1060, 180, 720
    months = 72; ymax = 1000
    axes(c, x0, x1, y0, y1, months, ymax)
    pts = series(c, MIN, x0, x1, y0, y1, months, ymax, CORAL, CORAL_SOFT)
    # after one year
    x, y = pts[12]
    c.dot(x, y, 12, CORAL); c.dot(x, y, 6, CREAM)
    c.text(f"after a year: {money(MIN[12])} still owed", x + 24, y - 30, 26, INK, anchor="lm")
    # the end
    x, y = pts[-1]
    c.dot(x, y, 12, CORAL); c.dot(x, y, 6, CREAM)
    n = len(MIN) - 1
    c.dash(x, y - 24, x, 280, MUTED, 3)
    c.text(f"paid off after {ym(n)}", x + 16, 248, 26, INK, anchor="rm")
    c.save(f"{OUT}/fig-03-slide.png")

# ---------------------------------------------------------------- 4: what you paid
def total():
    c = Canvas()
    c.text("What the laptop actually cost", 600, 80, 44)
    base = 740; scale = 0.30
    # left: the price tag
    x0, x1 = 210, 500
    c.rrect(x0, base - 1000 * scale, x1, base, 24, FAINT)
    c.text("$1,000", 355, base - 1000 * scale - 40, 40)
    c.text("price tag", 355, base + 46, 28, MUTED, "Bold")
    # right: everything you handed over
    x0, x1 = 700, 990
    c.rrect(x0, base - MIN_PAID * scale, x1, base, 24, CORAL)
    c.rrect(x0, base - 1000 * scale, x1, base, 24, MINT)
    c.rrect(x0, base - 1000 * scale - 24, x1, base - 1000 * scale + 24, 0, CORAL)
    c.rrect(x0, base - 1000 * scale, x1, base - 1000 * scale + 30, 0, MINT)
    c.text("$1,000", 845, base - 500 * scale, 34, WHITE)
    c.text("the laptop", 845, base - 500 * scale + 40, 22, WHITE, "Bold")
    c.text(money(MIN_INT), 845, base - (1000 + MIN_INT / 2) * scale, 34, WHITE)
    c.text("interest", 845, base - (1000 + MIN_INT / 2) * scale + 40, 22, WHITE, "Bold")
    c.text(money(MIN_PAID), 845, base - MIN_PAID * scale - 40, 40)
    c.text("paid over 70 months", 845, base + 46, 28, MUTED, "Bold")
    c.save(f"{OUT}/fig-04-total.png")

# ---------------------------------------------------------------- 6: $28 vs $50
def two_ways():
    c = Canvas()
    c.text("Same card. $28 a month vs $50", 600, 80, 44)
    x0, x1, y0, y1 = 200, 1060, 180, 720
    months = 72; ymax = 1000
    axes(c, x0, x1, y0, y1, months, ymax)
    pm = series(c, MIN, x0, x1, y0, y1, months, ymax, CORAL)
    pf = series(c, FIFTY, x0, x1, y0, y1, months, ymax, MINT)
    x, y = pf[-1]
    c.dot(x, y, 12, MINT); c.dot(x, y, 6, CREAM)
    c.text(f"$50 a month: done in {ym(len(FIFTY) - 1)}", x + 20, y - 52, 26, INK, anchor="lm")
    c.text(f"{money(FIFTY_INT)} interest", x + 20, y - 20, 24, MINT, "Bold", anchor="lm")
    x, y = pm[-1]
    c.dot(x, y, 12, CORAL); c.dot(x, y, 6, CREAM)
    mx, my = pm[48]
    c.text(f"minimum: {ym(len(MIN) - 1)}", mx - 70, my + 24, 26, INK, anchor="rm")
    c.text(f"{money(MIN_INT)} interest", mx - 70, my + 56, 24, CORAL, "Bold", anchor="rm")
    c.save(f"{OUT}/fig-06-two-ways.png")

# ---------------------------------------------------------------- 7: the box on the statement
def warning_box():
    """The Minimum Payment Warning every US card statement has carried since 2010,
    filled in with this card's numbers. Sized so the words survive the card."""
    c = Canvas()
    c.rrect(40, 40, 1160, 860, 22, WHITE, outline=FAINT, ow=3)
    c.text("Minimum Payment Warning", 90, 120, 42, INK, anchor="lm")
    c.text("Pay only the minimum each month and you will pay more in interest", 90, 190, 27, MUTED, "Bold", anchor="lm")
    c.text("and it will take you longer to pay off your balance.", 90, 228, 27, MUTED, "Bold", anchor="lm")
    cols = [90, 560, 830]
    y = 300
    c.line([(90, y), (1110, y)], FAINT, 3)
    for i, h in enumerate(["If you pay each month", "Paid off in", "Total paid"]):
        c.text(h, cols[i] + 10, y + 40, 25, MUTED, "Bold", anchor="lm")
    y = 380
    c.line([(90, y), (1110, y)], FAINT, 3)
    rows = [("Only the minimum", "6 years", money(MIN_PAID), CORAL_SOFT, CORAL),
            (f"${int(round(THREE_YEAR))} a month", "3 years", money(TY_PAID), MINT_SOFT, MINT)]
    for r, (a, b, t, soft, col) in enumerate(rows):
        yy = y + r * 175
        c.rrect(90, yy + 20, 1110, yy + 150, 24, soft)
        c.text(a, cols[0] + 26, yy + 85, 38, INK, anchor="lm")
        c.text(b, cols[1] + 10, yy + 85, 38, INK, anchor="lm")
        c.text(t, cols[2] + 10, yy + 85, 38, col, anchor="lm")
    c.text(f"saves {money(MIN_PAID - TY_PAID)}", cols[2] + 10, y + 175 + 165, 26, MINT, "Bold", anchor="lm")
    c.text("Required on every US card statement since 2010", 600, 810, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-warning-box.png")

if __name__ == "__main__":
    print(f"minimum: {len(MIN)-1} months, paid {money(MIN_PAID)}, interest {money(MIN_INT)}")
    print(f"$50: {len(FIFTY)-1} months, interest {money(FIFTY_INT)}; $38: paid {money(TY_PAID)}")
    month_one(); slide(); total(); two_ways(); warning_box()

# ---------------------------------------------------------------- 10: autopay, drawn
def autopay():
    c = Canvas()
    c.text("Set it once", 600, 80, 44)
    c.rrect(330, 150, 870, 860, 60, WHITE, outline=FAINT, ow=5)
    c.rrect(540, 170, 660, 196, 13, FAINT)
    c.text("Autopay", 600, 260, 36, INK)
    rows = [("Minimum due", "about $28, changes monthly", False),
            ("Fixed amount", "$50 every month", True)]
    for i, (head, sub, on) in enumerate(rows):
        y = 330 + i * 170
        c.rrect(370, y, 830, y + 130, 30, MINT_SOFT if on else CREAM, outline=MINT if on else FAINT, ow=4)
        c.text(head, 400, y + 48, 30, INK, anchor="lm")
        c.text(sub, 400, y + 92, 22, MUTED, "Bold", anchor="lm")
        c.dot(780, y + 65, 24, MINT if on else FAINT)
        if on:
            c.line([(768, y + 65), (778, y + 77), (796, y + 52)], WHITE, 6)
    c.text("Pick the amount, not the minimum", 600, 760, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-10-autopay.png")

if __name__ == "__main__":
    autopay()
