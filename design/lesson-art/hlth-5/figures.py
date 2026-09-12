#!/usr/bin/env python3
"""When to see a doctor: three doors, what waits, what means today, what means the ER,
what each costs."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def three_doors():
    c = Canvas(); title(c, "Three doors")
    tiles = [("Campus clinic", "most things", MINT), ("Urgent care", "when the clinic is closed", GOLD), ("The ER", "emergencies only", CORAL)]
    for i, (h, s, col) in enumerate(tiles):
        x0 = 100 + i * 340
        c.rrect(x0, 200, x0 + 320, 680, 36, col)
        c.rrect(x0 + 110, 300, x0 + 210, 470, 16, WHITE); c.dot(x0 + 190, 390, 8, col)
        c.text(h, x0 + 160, 540, 30, WHITE if col != GOLD else INK)
        c.text(s, x0 + 160, 600, 22, WHITE if col != GOLD else INK, "Bold")
    c.save(f"{OUT}/fig-02-three-doors.png")

def checklist(c, items, col, y0=190, step=118, h=90):
    for i, it in enumerate(items):
        y = y0 + i * step
        c.rrect(120, y, 1080, y + h, 26, WHITE, outline=FAINT, ow=4)
        c.dot(175, y + h / 2, 18, col)
        c.text(it, 220, y + h / 2, 27, INK, "Bold", anchor="lm")

def wait():
    c = Canvas(); title(c, "Can wait a few days")
    checklist(c, ["a cold", "a cough, no fever", "a sore throat with a cough", "a stomach bug under a day"], MINT, y0=190)
    c.text("rest, fluids, time. See someone if it's still there in a week.", 600, 780, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-wait.png")

def today():
    c = Canvas(); title(c, "Means today")
    checklist(c, ["a fever over 103°F, or any fever past 3 days", "sore throat + fever + no cough (strep)", "an ear that hurts and leaks", "pain when you pee"], GOLD, y0=190)
    c.text("book the clinic today", 600, 780, 26, INK, "Bold")
    c.save(f"{OUT}/fig-04-today.png")

def er():
    c = Canvas(); title(c, "Means the ER, now")
    checklist(c, ["chest pain, or trouble breathing", "the worst headache of your life", "fainting, or a stiff neck with a fever", "can't keep water down for a day", "thoughts of ending your life: 988"], CORAL, y0=170, step=112, h=86)
    c.save(f"{OUT}/fig-05-er.png")

def cost():
    c = Canvas(); title(c, "The same sore throat")
    hbars(c, [("campus clinic", 25, MINT), ("urgent care", 200, GOLD), ("the ER", 1000, CORAL)],
          fmt=lambda v: {25: "$0 to $25", 200: "$150 to $250", 1000: "often over $1,000"}[v], x0=380, xmax=880, y0=240, step=170, h=90, label_size=28, value_size=26, vmax=1000)
    c.text("typical, before insurance", 600, 790, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-cost.png")

if __name__ == "__main__":
    three_doors(); wait(); today(); er(); cost()
