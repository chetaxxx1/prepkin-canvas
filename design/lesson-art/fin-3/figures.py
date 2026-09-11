#!/usr/bin/env python3
"""What an emergency fund is for: the $400 on a card, what actually breaks, the ladder
from $500 to three months, and the refill loop."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def months_to_clear(P, apr, pay):
    r = apr / 12; return math.ceil(-math.log(1 - r * P / pay) / math.log(1 + r))

def on_a_card():
    c = Canvas(); title(c, "The same $400, on a card at 24%")
    n = months_to_clear(400, 0.24, 25); total = n * 25
    vbars(c, [("with cash", 400, MINT), (f"on the card, $25 a month\nfor {n} months", total, CORAL)], fmt=money, base=680, top=220, width=260)
    note(c, f"about {money(total - 400)} of interest for a flat tyre", 830)
    c.save(f"{OUT}/fig-03-card.png")

def what_breaks():
    c = Canvas(); title(c, "What actually goes wrong")
    hbars(c, [("phone screen", 300, CORAL), ("ER co-pay", 250, CORAL), ("a tyre", 150, CORAL), ("vet visit", 120, CORAL), ("charger", 60, CORAL)], fmt=money, x0=380, y0=190, step=112)
    note(c, "$500 covers almost all of it", 800)
    c.save(f"{OUT}/fig-04-what-breaks.png")

def ladder():
    c = Canvas(); title(c, "Then keep going")
    stops = [("$500", "the small stuff", CORAL), ("one month", "rent and food", GOLD), ("three months", "a lost job is a problem, not a catastrophe", MINT)]
    for i, (head, sub, col) in enumerate(stops):
        x0 = 100 + i * 340; y1 = 740; y0 = 540 - i * 160
        c.rrect(x0, y0, x0 + 320, y1, 30, col)
        c.text(head, x0 + 160, y0 + 60, 34, WHITE if col != GOLD else INK)
        for j, ln in enumerate(wrap(c, sub, 22, 280)):
            c.text(ln, x0 + 160, y0 + 106 + j * 28, 22, WHITE if col != GOLD else INK, "Bold")
    c.save(f"{OUT}/fig-06-ladder.png")

def refill():
    c = Canvas(); title(c, "After you use it")
    boxes = [("full", MINT, WHITE), ("the car breaks", CORAL, WHITE), ("you pay cash", GOLD, INK), ("next paychecks refill it first", SKY, WHITE)]
    for i, (label, col, ink) in enumerate(boxes):
        x = 90 + i * 280
        c.rrect(x, 330, x + 250, 480, 30, col)
        for j, ln in enumerate(wrap(c, label, 24, 220)):
            c.text(ln, x + 125, 405 + (j - (len(wrap(c, label, 24, 220)) - 1) / 2) * 30, 24, ink, "Bold")
        if i < 3: arrow(c, x + 255, 405, x + 275, 405, STONE, 6)
    # back to full
    c.line([(1060, 490), (1060, 600), (215, 600), (215, 495)], STONE, 6)
    c.d.polygon([c.p(215, 485), c.p(200, 505), c.p(230, 505)], fill=STONE)
    note(c, "wants pause for a month, then the fund is back", 700)
    c.save(f"{OUT}/fig-08-refill.png")

if __name__ == "__main__":
    on_a_card(); what_breaks(); ladder(); refill()
