#!/usr/bin/env python3
"""Flashcards that actually work: splitting a card, the three Leitner boxes, up on a
hit, down on a miss, and the deck after two weeks."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255); STONE = (200, 190, 175)

def card(c, x, y, w, h, lines, col=WHITE, ink=INK, size=24):
    c.rrect(x, y, x + w, y + h, 24, col, outline=FAINT if col == WHITE else None, ow=4)
    for i, ln in enumerate(lines):
        c.text(ln, x + w / 2, y + h / 2 + (i - (len(lines) - 1) / 2) * (size + 10), size, ink, "Bold")

def split():
    c = Canvas()
    c.text("One card, one fact", 600, 80, 44)
    card(c, 90, 250, 420, 300, ["The causes of", "World War I", "(all of them)"], CORAL_SOFT, CORAL, 26)
    c.line([(540, 400), (620, 400)], STONE, 6)
    c.d.polygon([c.p(640, 400), c.p(616, 386), c.p(616, 414)], fill=STONE)
    card(c, 670, 200, 440, 170, ["What year did", "World War I start?"], MINT_SOFT, INK, 24)
    card(c, 670, 430, 440, 170, ["Which assassination", "set it off?"], MINT_SOFT, INK, 24)
    c.text("too much for five seconds", 300, 600, 22, MUTED, "Bold")
    c.text("two cards, each answerable in five seconds", 890, 650, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-02-split.png")

def boxes(c, y=330, fills=(None, None, None)):
    labels = [("box 1", "every day"), ("box 2", "every 3 days"), ("box 3", "once a week")]
    xs = []
    for i, (head, sub) in enumerate(labels):
        x = 110 + i * 350
        c.rrect(x, y, x + 300, y + 260, 30, FAINT, outline=STONE, ow=4)
        c.text(head, x + 150, y - 60, 30, INK)
        c.text(sub, x + 150, y - 22, 22, MUTED, "Bold")
        n = fills[i] or 0
        for j in range(n):
            c.rrect(x + 30 + j * 10, y + 200 - j * 10, x + 200 + j * 10, y + 240 - j * 10, 8, WHITE, outline=STONE, ow=2)
        xs.append(x + 150)
    return xs

def three_boxes():
    c = Canvas()
    c.text("Three boxes", 600, 70, 44)
    boxes(c, fills=(6, 4, 2))
    c.text("Each box gets checked less often than the one before", 600, 720, 26, INK)
    c.save(f"{OUT}/fig-04-boxes.png")

def up():
    c = Canvas()
    c.text("Right answer: up one box", 600, 70, 44)
    xs = boxes(c, fills=(3, 3, 3))
    for i in range(2):
        x0 = xs[i] + 130; x1 = xs[i + 1] - 130
        c.line([(x0, 300), (x1, 300)], MINT, 8)
        c.d.polygon([c.p(x1 + 16, 300), c.p(x1 - 14, 284), c.p(x1 - 14, 316)], fill=MINT)
    c.text("got it", 460, 270, 22, MINT, "Bold"); c.text("got it again", 810, 270, 22, MINT, "Bold")
    c.text("Each box up, you see it less often", 600, 720, 26, INK)
    c.save(f"{OUT}/fig-05-up.png")

def down():
    c = Canvas()
    c.text("Miss: all the way back", 600, 70, 44)
    xs = boxes(c, fills=(3, 3, 3))
    # a curved drop from box 3 to box 1, below the boxes
    import math
    pts = [(xs[2] + (xs[0] - xs[2]) * t, 660 - 80 * math.sin(math.pi * t)) for t in [i / 40 for i in range(41)]]
    pts = [(xs[2] + (xs[0] - xs[2]) * t, 620 + 60 * math.sin(math.pi * t)) for t in [i / 40 for i in range(41)]]
    c.line(pts, CORAL, 8)
    ax, ay = pts[-1]; c.d.polygon([c.p(ax - 18, ay), c.p(ax + 14, ay - 16), c.p(ax + 14, ay + 16)], fill=CORAL)
    c.text("missed it", 600, 720, 24, CORAL, "Bold")
    c.text("You see it again tomorrow", 600, 800, 26, INK)
    c.save(f"{OUT}/fig-06-down.png")

def week_two():
    c = Canvas()
    c.text("Twenty Spanish words, two weeks in", 600, 80, 40)
    groups = [("day 1", (20, 0, 0)), ("week 1", (6, 6, 8)), ("week 2", (2, 4, 14))]
    for gi, (label, dist) in enumerate(groups):
        x0 = 120 + gi * 340
        c.text(label, x0 + 130, 170, 28, INK)
        for bi, n in enumerate(dist):
            y = 230 + bi * 170
            c.rrect(x0, y, x0 + 260, y + 130, 24, FAINT)
            for j in range(n):
                c.rrect(x0 + 16 + (j % 10) * 23, y + 20 + (j // 10) * 50, x0 + 16 + (j % 10) * 23 + 18, y + 20 + (j // 10) * 50 + 40, 4,
                        CORAL if bi == 0 else (GOLD if bi == 1 else MINT))
            if gi == 0:
                c.text(f"box {bi + 1}", x0 - 20, y + 65, 22, MUTED, "Bold", anchor="rm")
    c.text("Most of the deck is resting. Ten minutes covers the rest.", 600, 800, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-week-two.png")

if __name__ == "__main__":
    split(); three_boxes(); up(); down(); week_two()
