#!/usr/bin/env python3
"""How to study for a science quiz: the osmosis drawing, one drawing for any wording,
two nights, mechanisms with a direction, and the four checks."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def osmosis(c, cx=600, cy=470, w=760, h=360, labels=True):
    c.rrect(cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2, 30, SKY_SOFT, outline=SKY, ow=6)
    c.line([(cx, cy - h / 2), (cx, cy + h / 2)], SKY, 8)
    # salt dots: few on the left, many on the right
    import random; random.seed(7)
    for _ in range(6): c.dot(random.uniform(cx - w / 2 + 40, cx - 40), random.uniform(cy - h / 2 + 40, cy + h / 2 - 40), 9, INK)
    for _ in range(28): c.dot(random.uniform(cx + 40, cx + w / 2 - 40), random.uniform(cy - h / 2 + 40, cy + h / 2 - 40), 9, INK)
    arrow(c, cx - 120, cy + h / 2 + 50, cx + 120, cy + h / 2 + 50, MINT, 10)
    if labels:
        c.text("less salty", cx - w / 4, cy - h / 2 - 34, 24, MUTED, "Bold"); c.text("saltier", cx + w / 4, cy - h / 2 - 34, 24, MUTED, "Bold")
        c.text("water moves this way", cx, cy + h / 2 + 100, 26, MINT, "Bold")

def draw_it():
    c = Canvas(); title(c, "Osmosis, drawn"); osmosis(c)
    c.save(f"{OUT}/fig-02-osmosis.png")

def any_wording():
    c = Canvas(); title(c, "One drawing, any question")
    osmosis(c, cx=600, cy=330, w=520, h=220, labels=False)
    qs = ["Which way does the water move?", "What happens to the cell in salt water?", "Why does a slug shrivel on salt?"]
    for i, q in enumerate(qs):
        y = 560 + i * 90
        c.rrect(140, y, 1060, y + 66, 22, WHITE, outline=FAINT, ow=4); c.text(q, 600, y + 33, 26, INK, "Bold")
    c.save(f"{OUT}/fig-03-any-wording.png")

def two_nights():
    c = Canvas(); title(c, "Two evenings before the quiz")
    steps(c, [("Night one", "write and draw what you remember, then check", MINT), ("Night two", "redraw only the gaps", CORAL)], y0=230, h=190, num=False)
    note(c, "rereading the chapter is not on the list", 760)
    c.save(f"{OUT}/fig-05-two-nights.png")

def mechanisms():
    c = Canvas(); title(c, "If there is an arrow in it, draw it")
    items = ["osmosis", "photosynthesis", "a circuit", "the water cycle", "a food web", "digestion"]
    for i, it in enumerate(items):
        x = 130 + (i % 3) * 330; y = 220 + (i // 3) * 240
        c.rrect(x, y, x + 280, y + 180, 30, [MINT_SOFT, GOLD_SOFT, SKY_SOFT][i % 3])
        arrow(c, x + 60, y + 120, x + 220, y + 120, [MINT, GOLD, SKY][i % 3], 8)
        c.text(it, x + 140, y + 60, 26, INK, "Bold")
    c.save(f"{OUT}/fig-06-mechanisms.png")

def checks():
    c = Canvas(); title(c, "You are ready when you can")
    steps(c, [("draw it", "", MINT), ("label it", "", MINT), ("say which way it goes", "", MINT), ("say why", "", MINT)], y0=180, h=130, step=155)
    c.save(f"{OUT}/fig-08-checks.png")

if __name__ == "__main__":
    draw_it(); any_wording(); two_nights(); mechanisms(); checks()
