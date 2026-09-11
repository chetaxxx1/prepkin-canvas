#!/usr/bin/env python3
"""Your first budget in 4 lines: the 50/30/20 split of $2,000, the needs, the savings
line, the payday order, and the four lines themselves."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
IN = 2000

def four_lines():
    c = Canvas(); title(c, "Four lines from $2,000")
    stack(c, [("savings", IN * 0.2, MINT), ("wants", IN * 0.3, GOLD), ("needs", IN * 0.5, CORAL)], fmt=money, ink=WHITE)
    c.text("20%", 820, 705, 26, MINT, "Bold", anchor="lm"); c.text("30%", 820, 560, 26, GOLD, "Bold", anchor="lm"); c.text("50%", 820, 340, 26, CORAL, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-02-four-lines.png")

def needs():
    c = Canvas(); title(c, "Needs: the half that happens anyway")
    hbars(c, [("rent", 700, CORAL), ("food", 220, CORAL), ("phone", 40, CORAL), ("bus", 40, CORAL)], fmt=money, x0=300, y0=200, step=130)
    note(c, "$1,000 of the $2,000, before you plan a thing", 780)
    c.save(f"{OUT}/fig-03-needs.png")

def savings_line():
    c = Canvas(); title(c, "The line that changes things")
    vbars(c, [("a month", 400, MINT), ("a year", 4800, MINT)], fmt=money, base=700, top=220, width=260)
    note(c, "the first $500 of it is your emergency fund", 820)
    c.save(f"{OUT}/fig-05-savings-line.png")

def automate():
    c = Canvas(); title(c, "Payday, in this order")
    c.rrect(90, 300, 390, 460, 34, INK); c.text("payday", 240, 360, 32, WHITE); c.text("$2,000 lands", 240, 410, 22, WHITE, "Bold")
    arrow(c, 410, 380, 500, 380, STONE)
    c.rrect(520, 300, 820, 460, 34, MINT); c.text("$400 moves", 670, 360, 32, WHITE); c.text("to savings, by itself", 670, 410, 22, WHITE, "Bold")
    arrow(c, 840, 380, 930, 380, STONE)
    c.rrect(950, 300, 1150, 460, 34, GOLD); c.text("$1,600", 1050, 360, 32, INK); c.text("to live on", 1050, 410, 22, INK, "Bold")
    note(c, "you cannot overspend money you never see", 600)
    c.save(f"{OUT}/fig-07-automate.png")

def the_budget():
    c = Canvas()
    c.rrect(200, 90, 1000, 820, 30, WHITE, outline=FAINT, ow=4)
    c.text("This month", 600, 170, 36)
    rows = [("in", 2000, INK), ("needs", 1000, CORAL), ("wants", 600, GOLD), ("save", 400, MINT)]
    for i, (label, v, col) in enumerate(rows):
        y = 270 + i * 120
        c.dot(300, y, 16, col)
        c.text(label, 340, y, 34, INK, anchor="lm")
        c.text(money(v), 900, y, 34, col if col != INK else INK, anchor="rm")
        if i < 3: c.line([(260, y + 60), (940, y + 60)], FAINT, 3)
    c.save(f"{OUT}/fig-09-budget.png")

if __name__ == "__main__":
    four_lines(); needs(); savings_line(); automate(); the_budget()
