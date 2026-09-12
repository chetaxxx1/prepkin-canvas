#!/usr/bin/env python3
"""How to read an offer letter: the five parts, the real number, the maybe number,
the one-line ask, the small print."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def letter(c, x0=150, y0=130, x1=760, y1=840):
    """A printed letter: logo block, ragged lines, a signature squiggle."""
    c.rrect(x0, y0, x1, y1, 24, WHITE, outline=FAINT, ow=4)
    c.rrect(x0 + 50, y0 + 50, x0 + 130, y0 + 90, 12, STONE)
    lines = [0.55, 0.9, 0.7, 0.85, 0.5, 0.8, 0.88, 0.6, 0.75, 0.4]
    ys = []
    for i, f in enumerate(lines):
        y = y0 + 150 + i * 46
        c.rrect(x0 + 50, y, x0 + 50 + (x1 - x0 - 100) * f, y + 14, 7, FAINT); ys.append(y)
    c.d.line([c.p(x0 + 60, y1 - 60), c.p(x0 + 110, y1 - 90), c.p(x0 + 150, y1 - 50), c.p(x0 + 210, y1 - 85)],
             fill=INK, width=3 * SS, joint="curve")
    return ys

def five_parts():
    c = Canvas(); title(c, "Five parts, one letter")
    ys = letter(c)
    parts = [("Base pay", 0, GOLD), ("Start date", 2, SKY), ("Bonus", 4, CORAL), ("Benefits", 6, MINT), ("The deadline", 8, STONE)]
    for label, li, col in parts:
        y = ys[li] + 7
        c.rrect(190, y - 20, 640, y + 20, 14, (col[0], col[1], col[2], 90))
        c.dot(830, y, 16, col); c.text(label, 870, y, 30, INK, anchor="lm")
    c.save(f"{OUT}/fig-02-five-parts.png")

def base():
    c = Canvas(); title(c, "$60,000 a year is $5,000 a month")
    vbars(c, [("before tax", 5000, GOLD), ("lands in your account", 4000, MINT)],
          fmt=money, base=700, top=220, width=300, gap=160)
    note(c, "after-tax is roughly; your state sets the rest", y=840)
    c.save(f"{OUT}/fig-03-base.png")

def bonus():
    c = Canvas(); title(c, "Promised vs hoped")
    base_y, top = 720, 220; scale = (base_y - top) / 66000
    # base: solid
    c.rrect(260, base_y - 60000 * scale, 560, base_y, 24, GOLD)
    c.text("$60,000", 410, base_y - 60000 * scale - 40, 36); c.text("base", 410, base_y + 44, 26, MUTED, "Bold")
    c.text("promised", 410, base_y + 78, 24, MINT, "Bold")
    # bonus: dashed outline, sized to 10%
    x0, x1 = 640, 940; h = 6000 * scale
    for (ax, ay, bx, by) in [(x0, base_y - h, x1, base_y - h), (x0, base_y - h, x0, base_y), (x1, base_y - h, x1, base_y)]:
        c.dash(ax, ay, bx, by, CORAL, w=6, on=16, off=12)
    c.text("up to $6,000", 790, base_y - h - 40, 36, CORAL); c.text("target bonus", 790, base_y + 44, 26, MUTED, "Bold")
    c.text("maybe", 790, base_y + 78, 24, CORAL, "Bold")
    c.line([(200, base_y), (1000, base_y)], STONE, 4)
    c.save(f"{OUT}/fig-04-bonus.png")

def ask():
    c = Canvas()
    c.rrect(150, 130, 1050, 820, 40, WHITE, outline=FAINT, ow=5)
    c.text("Re: Offer", 200, 200, 30, INK, anchor="lm")
    c.line([(200, 240), (1000, 240)], FAINT, 3)
    lines = ["Thank you, I'm really excited to join.", "", "Could the letter note the two remote days",
             "we discussed? Once that's in, I'll sign", "and send it straight back.", "", "Thanks again,", "Sam"]
    c.rrect(180, 300 + 2 * 52 - 34, 1020, 300 + 4 * 52 + 34, 20, MINT_SOFT)
    for i, ln in enumerate(lines):
        if ln: c.text(ln, 200, 300 + i * 52, 28, INK, "Bold", anchor="lm")
    c.text("warm, one thing, then sign", 600, 780, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-06-ask.png")

def contingent():
    c = Canvas(); title(c, "Contingent on")
    rows = [("A background check", "a few days to a few weeks", SKY), ("Proof of your degree", "a transcript or a call to the registrar", MINT), ("Sometimes a drug test", "within a day or two of the offer", GOLD)]
    steps(c, rows, y0=180, h=150, step=175, num=False)
    c.rrect(120, 720, 1080, 800, 30, CORAL_SOFT)
    c.text("until these clear, do not quit anything", 600, 760, 28, CORAL)
    c.save(f"{OUT}/fig-08-contingent.png")

if __name__ == "__main__":
    five_parts(); base(); bonus(); ask(); contingent()
