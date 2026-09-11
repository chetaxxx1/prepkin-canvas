#!/usr/bin/env python3
"""How to say no: the three parts, every reason is a door, and one in full by text."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255); STONE = (200, 190, 175); SKY_SOFT = (226, 238, 250)

def three_parts():
    c = Canvas()
    c.text("Three parts", 600, 80, 44)
    rows = [("1", "Something warm", "Thanks for thinking of me.", GOLD),
            ("2", "The no, plain", "I can't this weekend.", CORAL),
            ("3", "What you can do (optional)", "But I'm free Tuesday.", MINT)]
    for i, (n, head, ex, col) in enumerate(rows):
        y = 190 + i * 210
        c.rrect(120, y, 1080, y + 170, 34, WHITE, outline=FAINT, ow=4)
        c.dot(200, y + 85, 44, col); c.text(n, 200, y + 85, 40, WHITE if col != GOLD else INK)
        c.text(head, 280, y + 62, 34, INK, anchor="lm")
        c.text("“" + ex + "”", 280, y + 116, 26, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-02-three-parts.png")

def doors():
    c = Canvas()
    c.text("Every reason is a door", 600, 80, 44)
    pairs = [("I have homework.", "Do it after!"), ("I'm tired.", "Just for an hour."), ("I'm broke.", "I'll cover you.")]
    for i, (reason, reply) in enumerate(pairs):
        y = 200 + i * 190
        c.rrect(100, y, 560, y + 120, 36, SKY_SOFT); c.text(reason, 330, y + 60, 28, INK)
        c.line([(580, y + 60), (640, y + 60)], STONE, 6)
        c.d.polygon([c.p(660, y + 60), c.p(636, y + 46), c.p(636, y + 74)], fill=STONE)
        c.rrect(680, y, 1100, y + 120, 36, CORAL_SOFT); c.text(reply, 890, y + 60, 28, CORAL)
    c.text("No reason, no door.", 600, 810, 32, INK)
    c.save(f"{OUT}/fig-06-doors.png")

def wrap(c, s, size, maxw, weight="Bold"):
    words = s.split(); lines = []; cur = ""
    for w in words:
        t = (cur + " " + w).strip()
        if c.width(t, size, weight) > maxw and cur: lines.append(cur); cur = w
        else: cur = t
    if cur: lines.append(cur)
    return lines

def text_message():
    c = Canvas()
    c.text("One in full, by text", 600, 70, 44)
    c.rrect(150, 130, 1050, 780, 60, WHITE, outline=FAINT, ow=5)
    c.rrect(510, 150, 690, 178, 14, FAINT)
    # their ask, grey, left
    ask = wrap(c, "Party at Sam's Saturday, you in??", 30, 560)
    top = 230
    c.rrect(190, top, 190 + 620, top + 40 + len(ask) * 46, 40, FAINT)
    for i, ln in enumerate(ask): c.text(ln, 225, top + 42 + i * 46, 30, INK, "Bold", anchor="lm")
    # the no, blue, right
    msg = wrap(c, "Thanks for the invite! I can't this weekend. Free Tuesday if you want to grab food.", 30, 620)
    top2 = top + 60 + len(ask) * 46 + 30
    h = 40 + len(msg) * 46
    c.rrect(1010 - 690, top2, 1010, top2 + h, 40, SKY)
    for i, ln in enumerate(msg): c.text(ln, 1010 - 690 + 35, top2 + 42 + i * 46, 30, WHITE, "Bold", anchor="lm")
    y = top2 + h + 60
    for i, (label, col) in enumerate((("warm", GOLD), ("no", CORAL), ("offer", MINT))):
        x = 280 + i * 220
        c.dot(x, y, 14, col); c.text(label, x + 28, y, 26, MUTED, "Bold", anchor="lm")
    c.text("No reason given. Nothing to argue with.", 600, 720, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-text.png")

if __name__ == "__main__":
    three_parts(); doors(); text_message()
