#!/usr/bin/env python3
"""Active recall: recognising vs remembering, the ten-minute method, the study list,
and the Roediger and Karpicke 2006 numbers."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255)

def arrow(c, x0, y0, x1, y1, colour, w=10):
    import math
    c.line([(x0, y0), (x1, y1)], colour, w)
    ang = math.atan2(y1 - y0, x1 - x0); L = 34
    p1 = (x1 - L * math.cos(ang - 0.5), y1 - L * math.sin(ang - 0.5))
    p2 = (x1 - L * math.cos(ang + 0.5), y1 - L * math.sin(ang + 0.5))
    c.d.polygon([c.p(*p1), c.p(x1, y1), c.p(*p2)], fill=colour)

def recognise_vs_recall():
    c = Canvas()
    c.text("Two directions", 600, 80, 44)
    for i, (head, a, b, col, note) in enumerate((("Rereading", "notes", "you", (200, 190, 175), "trains recognising"),
                                                 ("Recall", "you", "page", MINT, "trains remembering"))):
        y = 240 + i * 300
        c.text(head, 130, y - 60, 30, INK, anchor="lm")
        c.rrect(130, y, 430, y + 120, 30, FAINT); c.text(a, 280, y + 60, 32, INK)
        arrow(c, 460, y + 60, 740, y + 60, col)
        c.rrect(770, y, 1070, y + 120, 30, col); c.text(b, 920, y + 60, 32, WHITE if col == MINT else INK)
        c.text(note, 600, y + 160, 24, MUTED, "Bold")
    c.text("Exams only test the second one", 600, 840, 26, INK)
    c.save(f"{OUT}/fig-02-directions.png")

def method():
    c = Canvas()
    c.text("Ten minutes", 600, 80, 44)
    steps = [("2 min", "Close everything", "laptop shut, notes away", (200, 190, 175)),
             ("5 min", "Write what you remember", "blank page, no peeking", MINT),
             ("3 min", "Check what you missed", "open the notes, mark the gaps", CORAL)]
    for i, (mins, head, sub, col) in enumerate(steps):
        y = 180 + i * 210
        c.rrect(100, y, 1100, y + 170, 34, WHITE, outline=FAINT, ow=4)
        c.rrect(120, y + 20, 300, y + 150, 26, col)
        c.text(mins, 210, y + 85, 34, WHITE if col != (200, 190, 175) else INK)
        c.text(head, 340, y + 62, 34, INK, anchor="lm")
        c.text(sub, 340, y + 116, 24, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-03-method.png")

def study_list():
    c = Canvas()
    c.text("What you actually need to study", 600, 80, 40)
    items = [("Newton's second law", True), ("free body diagrams", True), ("friction on a slope", False),
             ("normal force", True), ("tension in a rope", False), ("net force", True)]
    for i, (it, got) in enumerate(items):
        y = 170 + i * 105
        c.rrect(140, y, 1060, y + 85, 26, MINT_SOFT if got else CORAL_SOFT)
        c.dot(200, y + 42, 22, MINT if got else CORAL)
        if got:
            c.line([(188, y + 42), (197, y + 52), (214, y + 32)], WHITE, 6)
        else:
            c.line([(190, y + 32), (210, y + 52)], WHITE, 6); c.line([(210, y + 32), (190, y + 52)], WHITE, 6)
        c.text(it, 250, y + 42, 28, INK if not got else MUTED, "Bold", anchor="lm")
        c.text("already learned" if got else "study this", 1020, y + 42, 22, MINT if got else CORAL, "Bold", anchor="rm")
    c.text("Two gaps. That is the whole list.", 600, 830, 28, INK)
    c.save(f"{OUT}/fig-05-study-list.png")

def research():
    c = Canvas()
    c.text("One week later, how much stuck", 600, 80, 44)
    bars = [("read it\nfour times", 40, (200, 190, 175)), ("read once,\ntested three times", 61, MINT)]
    base = 700; scale = 7.5
    for i, (label, v, col) in enumerate(bars):
        x0 = 260 + i * 440; x1 = x0 + 260
        c.rrect(x0, base - v * scale, x1, base, 26, col)
        c.text(f"{v}%", (x0 + x1) / 2, base - v * scale - 44, 44)
        for j, ln in enumerate(label.split("\n")):
            c.text(ln, (x0 + x1) / 2, base + 44 + j * 32, 24, MUTED, "Bold")
    c.text("Roediger and Karpicke, 2006, students learning a science passage", 600, 850, 20, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-research.png")

if __name__ == "__main__":
    recognise_vs_recall(); method(); study_list(); research()
