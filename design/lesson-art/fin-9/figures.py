#!/usr/bin/env python3
"""A Roth IRA at 18: one deposit growing 47 years, the two rules, two savers, the jar
and what goes in it, and the monthly amount. All numbers computed at 7%."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255); STONE = (200, 190, 175)
R = 0.07
def fv_series(start_age, end_age, amount, at=65):
    return sum(amount * (1 + R) ** (at - a) for a in range(start_age, end_age + 1))
EARLY = fv_series(18, 24, 2000); LATE = fv_series(30, 65, 2000)
ONE = 2000 * (1 + R) ** 47

def growth():
    c = Canvas()
    c.text("One $2,000 deposit at 18", 600, 80, 44)
    x0, x1, y0, y1 = 200, 1060, 180, 720
    ymax = 50000
    for v in range(0, ymax + 1, 10000):
        y = y1 - (y1 - y0) * v / ymax
        c.line([(x0, y), (x1, y)], FAINT, 2)
        c.text(money(v), x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    for age in range(18, 66, 10):
        x = x0 + (x1 - x0) * (age - 18) / 47
        c.text(str(age), x, y1 + 34, 24, MUTED, "Bold")
    c.text("age", x1 + 24, y1 + 34, 24, MUTED, "Bold", anchor="lm")
    pts = [(x0 + (x1 - x0) * t / 47, y1 - (y1 - y0) * 2000 * (1 + R) ** t / ymax) for t in range(48)]
    c.area(pts, y1, MINT_SOFT); c.line(pts, MINT, 9)
    x, y = pts[-1]
    c.dot(x, y, 12, MINT); c.dot(x, y, 6, CREAM)
    c.text(f"{money(ONE)} at 65", x - 30, y - 80, 30, INK, anchor="rm")
    c.text("no tax on any of it", x - 30, y - 46, 24, MINT, "Bold", anchor="rm")
    c.save(f"{OUT}/fig-02-growth.png")

def rules():
    c = Canvas()
    c.text("Two rules", 600, 80, 44)
    cards = [("Any time", "the money you put in", "comes out with no penalty", MINT),
             ("After 59½", "and once the jar is five years old,", "everything comes out tax-free", GOLD)]
    for i, (head, a, b, col) in enumerate(cards):
        x0 = 100 + i * 520; x1 = x0 + 480
        c.rrect(x0, 200, x1, 700, 40, col)
        c.text(head, (x0 + x1) / 2, 300, 44, WHITE if col == MINT else INK)
        c.text(a, (x0 + x1) / 2, 420, 26, WHITE if col == MINT else INK, "Bold")
        c.text(b, (x0 + x1) / 2, 470, 26, WHITE if col == MINT else INK, "Bold")
    c.text("The growth is the part that waits. What you put in never was locked.", 600, 800, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-rules.png")

def two_savers():
    c = Canvas()
    c.text("Seven years early, or thirty-five years late", 600, 80, 40)
    base = 720; scale = 0.00155
    cols = [("starts at 18, stops at 24", 14000, EARLY, MINT), ("starts at 30, never stops", 70000, LATE, STONE)]
    for i, (label, put_in, end, col) in enumerate(cols):
        x0 = 180 + i * 500; x1 = x0 + 340
        c.rrect(x0, base - end * scale, x1, base, 26, col)
        c.rrect(x0, base - put_in * scale, x1, base, 26, INK)
        c.rrect(x0, base - put_in * scale - 20, x1, base - put_in * scale, 0, col)
        c.rrect(x0, base - put_in * scale, x1, base - put_in * scale + 20, 0, INK)
        c.text(money(end), (x0 + x1) / 2, base - end * scale - 40, 36)
        c.text(f"{money(put_in)} put in", (x0 + x1) / 2, base - put_in * scale / 2, 22, WHITE, "Bold")
        c.text(label, (x0 + x1) / 2, base + 44, 24, MUTED, "Bold")
    c.text("$2,000 a year at 7%, value at 65", 600, 830, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-05-two-savers.png")

def jar():
    c = Canvas()
    c.text("The jar and what goes in it", 600, 80, 44)
    # a jar outline
    c.rrect(380, 220, 820, 760, 70, WHITE, outline=INK, ow=8)
    c.rrect(430, 170, 770, 240, 24, INK)
    c.text("Roth IRA", 600, 205, 26, WHITE)
    c.rrect(430, 420, 770, 700, 40, MINT)
    c.text("one broad", 600, 530, 30, WHITE); c.text("index fund", 600, 575, 30, WHITE)
    c.text("the jar keeps the tax off", 600, 300, 24, MUTED, "Bold")
    c.text("the fund does the growing", 600, 810, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-jar.png")

def monthly():
    c = Canvas()
    c.text("Set it to automatic", 600, 80, 44)
    rows = [("$167 a month", "$2,000 a year", MINT), ("$50 a month", "$600 a year, still counts", GOLD)]
    for i, (a, b, col) in enumerate(rows):
        y = 240 + i * 250
        c.rrect(140, y, 1060, y + 180, 40, col)
        c.text(a, 600, y + 70, 44, WHITE if col == MINT else INK)
        c.text(b, 600, y + 128, 26, WHITE if col == MINT else INK, "Bold")
    c.text("the habit matters more than the amount at 18", 600, 800, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-09-monthly.png")

if __name__ == "__main__":
    print(f"one deposit: {money(ONE)}; early: {money(EARLY)}; late: {money(LATE)}")
    growth(); rules(); two_savers(); jar(); monthly()
