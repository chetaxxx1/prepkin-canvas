#!/usr/bin/env python3
"""Your employer's match is free money: the offer letter, the paycheck split, the match
doubling, nine years vs day one, vesting, and the sign-up screen. $52,000, 4%, 8%."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255); STONE = (200, 190, 175)
SALARY = 52000; PCT = 0.04; YOU = SALARY * PCT

def letter():
    c = Canvas()
    c.rrect(160, 50, 1040, 850, 24, WHITE, outline=FAINT, ow=4)
    c.text("Offer of employment", 220, 130, 34, INK, anchor="lm")
    c.line([(220, 170), (980, 170)], FAINT, 3)
    c.text("Salary", 220, 230, 24, MUTED, "Bold", anchor="lm")
    c.text(money(SALARY) + " a year", 220, 280, 40, INK, anchor="lm")
    for i in range(3):
        c.rrect(220, 340 + i * 34, 980 - i * 120, 356 + i * 34, 8, FAINT)
    c.text("Benefits", 220, 500, 24, MUTED, "Bold", anchor="lm")
    for i in range(2):
        c.rrect(220, 530 + i * 34, 900 - i * 200, 546 + i * 34, 8, FAINT)
    c.rrect(200, 610, 1000, 690, 20, MINT_SOFT)
    c.text("401(k) match: 100% of the first 4% of pay", 600, 650, 28, INK)
    c.text(f"worth {money(YOU)} a year, on top of the salary", 600, 740, 24, MINT, "Bold")
    for i in range(2):
        c.rrect(220, 780 + i * 30, 800 - i * 150, 794 + i * 30, 8, FAINT)
    c.save(f"{OUT}/fig-02-letter.png")

def paycheck():
    c = Canvas()
    c.text("Where a paycheck goes", 600, 80, 44)
    x0, x1 = 120, 1080
    c.rrect(x0, 300, x1, 420, 30, MINT)
    c.rrect(x0, 300, x0 + (x1 - x0) * PCT, 420, 30, CORAL)
    c.rrect(x0 + (x1 - x0) * PCT - 30, 300, x0 + (x1 - x0) * PCT, 420, 0, CORAL)
    c.text("to you, as usual", (x0 + x1) / 2 + 40, 360, 30, WHITE)
    c.line([(x0 + (x1 - x0) * PCT / 2, 430), (x0 + (x1 - x0) * PCT / 2, 520)], CORAL, 4)
    c.text("4% into the 401(k) before you see it", x0, 560, 26, INK, "Bold", anchor="lm")
    c.text(f"{money(YOU)} a year, still yours, invested, locked until you are older", x0, 606, 22, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-03-paycheck.png")

def match():
    c = Canvas()
    c.text("Day one", 600, 80, 44)
    base = 700; scale = 0.11
    cols = [("you put in", YOU, MINT, None), ("they add", YOU, GOLD, None), ("in the account", YOU * 2, None, None)]
    for i, (label, v, col, _) in enumerate(cols):
        x0 = 150 + i * 330; x1 = x0 + 250
        if col:
            c.rrect(x0, base - v * scale, x1, base, 24, col)
        else:
            c.rrect(x0, base - YOU * scale, x1, base, 24, MINT)
            c.rrect(x0, base - v * scale, x1, base - YOU * scale, 24, GOLD)
            c.rrect(x0, base - YOU * scale - 24, x1, base - YOU * scale + 24, 0, GOLD if False else MINT)
            c.rrect(x0, base - YOU * scale - 24, x1, base - YOU * scale, 0, GOLD)
        c.text(money(v), (x0 + x1) / 2, base - v * scale - 40, 36)
        c.text(label, (x0 + x1) / 2, base + 44, 26, MUTED, "Bold")
        if i < 2:
            c.text("+" if i == 0 else "=", x1 + 40, base - 120, 44, MUTED)
    c.save(f"{OUT}/fig-04-match.png")

def nine_years():
    c = Canvas()
    c.text("Doubling it yourself at 8%", 600, 80, 44)
    x0, x1, y0, y1 = 200, 1060, 180, 720
    ymax = 5000
    for v in range(0, ymax + 1, 1000):
        y = y1 - (y1 - y0) * v / ymax
        c.line([(x0, y), (x1, y)], FAINT, 2)
        c.text(money(v), x0 - 18, y, 22, MUTED, "Bold", anchor="rm")
    for t in range(0, 11, 2):
        c.text(str(t), x0 + (x1 - x0) * t / 10, y1 + 34, 24, MUTED, "Bold")
    c.text("years", x1 + 24, y1 + 34, 24, MUTED, "Bold", anchor="lm")
    pts = [(x0 + (x1 - x0) * t / 40, y1 - (y1 - y0) * YOU * 1.08 ** (t / 4) / ymax) for t in range(41)]
    c.line(pts, STONE, 9)
    ty = y1 - (y1 - y0) * YOU * 2 / ymax
    c.dash(x0, ty, x1, ty, MINT, 4)
    c.text(f"{money(YOU * 2)}: the match gets you here on day one", x0 + 10, ty - 28, 24, MINT, "Bold", anchor="lm")
    tx = x0 + (x1 - x0) * 9 / 10
    c.dot(tx, ty, 12, STONE); c.dot(tx, ty, 6, CREAM)
    c.text("on your own: 9 years", tx - 20, ty + 40, 24, INK, "Bold", anchor="rm")
    c.save(f"{OUT}/fig-05-nine-years.png")

def vesting():
    c = Canvas()
    c.text("The catch: vesting", 600, 80, 44)
    x0, x1 = 160, 1040; y = 440
    c.line([(x0, y), (x1, y)], STONE, 8)
    steps = [(0, "0%"), (1, "33%"), (2, "66%"), (3, "100%")]
    for yr, pct in steps:
        x = x0 + (x1 - x0) * yr / 3
        c.dot(x, y, 22, MINT if yr == 3 else (STONE if yr == 0 else GOLD))
        c.text(f"year {yr}", x, y + 60, 24, MUTED, "Bold")
        c.text(pct, x, y - 60, 32, INK)
    c.text("how much of their half is yours if you leave", 600, 300, 24, MUTED, "Bold")
    c.text("Your own half is always yours. Ask which schedule you are on before you sign.", 600, 700, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-vesting.png")

def signup():
    c = Canvas()
    c.text("Five minutes, then automatic", 600, 80, 44)
    c.rrect(330, 150, 870, 840, 60, WHITE, outline=FAINT, ow=5)
    c.rrect(540, 170, 660, 196, 13, FAINT)
    c.text("401(k) contribution", 600, 260, 30, INK)
    c.rrect(380, 320, 820, 440, 30, MINT_SOFT, outline=MINT, ow=4)
    c.text("4% of each paycheck", 600, 366, 30, INK)
    c.text("employer matches 4%", 600, 410, 22, MINT, "Bold")
    for i, (label, on) in enumerate((("1%", False), ("4%", True), ("6%", False))):
        x = 420 + i * 140
        c.rrect(x, 500, x + 100, 570, 24, MINT if on else FAINT)
        c.text(label, x + 50, 535, 26, WHITE if on else INK)
    c.rrect(380, 640, 820, 720, 30, CORAL)
    c.text("Save", 600, 680, 30, WHITE)
    c.text("type in at least the number they match", 600, 790, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-signup.png")

if __name__ == "__main__":
    letter(); paycheck(); match(); nine_years(); vesting(); signup()
