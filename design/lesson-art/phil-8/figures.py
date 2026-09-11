#!/usr/bin/env python3
"""Plato's cave, drawn: the cross-section every textbook uses (prisoners, wall, walkway,
fire, the way out) and the three steps of knowing."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255)
ROCK = (120, 104, 96); ROCK_SOFT = (214, 200, 186); SHADOW = (98, 84, 78)

def person(c, x, y, col, h=70, seated=False):
    """A simple lit figure: head and a body, never a black silhouette."""
    c.dot(x, y - h + 14, 14, col)
    if seated:
        c.rrect(x - 16, y - h + 30, x + 16, y - 10, 12, col)
        c.rrect(x - 16, y - 24, x + 30, y - 6, 8, col)
    else:
        c.rrect(x - 15, y - h + 30, x + 15, y, 12, col)

def cave():
    c = Canvas()
    ROCK = (176, 158, 144); AIR = (241, 233, 221); FLOOR = (128, 110, 100)
    floor = 700
    # the rock mass, with the outside world showing top right
    c.rrect(0, 0, 1200, 900, 0, ROCK)
    c.d.polygon([c.p(940, 0), c.p(1200, 0), c.p(1200, 330)], fill=CREAM)
    # the chamber and the passage up to the light
    c.d.polygon([c.p(100, 150), c.p(900, 150), c.p(900, 300), c.p(1200, 20), c.p(1200, 250),
                 c.p(900, 520), c.p(900, floor), c.p(100, floor)], fill=AIR)
    c.rrect(100, floor, 900, 900, 0, FLOOR)
    c.rrect(100, floor, 1200, 900, 0, ROCK); c.rrect(100, floor, 900, 760, 0, FLOOR)
    # the sun, outside
    c.dot(1110, 110, 54, GOLD)
    for a in range(0, 360, 45):
        r = math.radians(a)
        c.line([(1110 + 70 * math.cos(r), 110 + 70 * math.sin(r)), (1110 + 92 * math.cos(r), 110 + 92 * math.sin(r))], GOLD, 6)
    # the wall the prisoners face, with shadows on it
    c.rrect(100, 150, 190, floor, 0, (200, 184, 170))
    c.d.ellipse([c.p(120, 380), c.p(170, 450)], fill=SHADOW)
    c.rrect(133, 355, 157, 385, 4, SHADOW)
    c.d.polygon([c.p(118, 520), c.p(172, 495), c.p(154, 560), c.p(174, 575), c.p(118, 575)], fill=SHADOW)
    # prisoners, seated, facing the wall
    for x in (290, 380, 470):
        person(c, x, floor, SKY, h=110, seated=True)
    c.line([(270, floor - 88), (490, floor - 88)], (90, 80, 76), 4)
    # the low wall, and the carriers behind it holding objects up
    c.rrect(560, floor - 150, 600, floor, 8, (150, 132, 120))
    for x, obj in ((660, "jug"), (760, "bird")):
        person(c, x, floor, GOLD, h=130)
        if obj == "jug":
            c.d.ellipse([c.p(x - 48, floor - 250), c.p(x - 8, floor - 185)], fill=INK)
            c.rrect(x - 38, floor - 272, x - 18, floor - 245, 4, INK)
            c.line([(x - 28, floor - 185), (x - 10, floor - 130)], GOLD, 10)
        else:
            c.d.polygon([c.p(x - 50, floor - 220), c.p(x - 6, floor - 245), c.p(x - 22, floor - 190),
                         c.p(x - 4, floor - 180), c.p(x - 50, floor - 180)], fill=INK)
            c.line([(x - 28, floor - 180), (x - 10, floor - 130)], GOLD, 10)
    # the fire
    fx, fy = 860, floor
    c.d.polygon([c.p(fx - 44, fy), c.p(fx - 22, fy - 100), c.p(fx, fy - 44), c.p(fx + 12, fy - 134),
                 c.p(fx + 32, fy - 56), c.p(fx + 48, fy)], fill=CORAL)
    c.d.polygon([c.p(fx - 20, fy), c.p(fx - 6, fy - 56), c.p(fx + 10, fy - 22), c.p(fx + 24, fy)], fill=GOLD)
    # light from the fire, over the low wall, onto the far wall
    c.line([(820, 330), (230, 330)], MUTED, 5)
    c.d.polygon([c.p(200, 330), c.p(236, 314), c.p(236, 346)], fill=MUTED)
    c.text("the light throws the objects onto the wall", 520, 300, 22, MUTED, "Bold")
    # labels
    c.text("shadows", 145, 190, 22, INK, "Bold")
    c.text("prisoners", 380, floor + 40, 24, CREAM, "Bold")
    c.text("low wall", 580, floor - 170, 20, INK, "Bold")
    c.text("carriers", 710, floor + 40, 24, CREAM, "Bold")
    c.text("fire", 860, floor + 40, 24, CREAM, "Bold")
    c.text("the way out", 1000, 470, 24, INK, "Bold")
    c.save(f"{OUT}/fig-03-cave.png")

def ladder():
    c = Canvas()
    c.text("Three steps of knowing", 600, 80, 44)
    steps = [("Shadows", "what you are shown", (170, 152, 140)),
             ("Objects", "what is really there", SKY),
             ("The sun", "why it is there at all", GOLD)]
    for i, (head, sub, col) in enumerate(steps):
        x0 = 120 + i * 330; y1 = 760; y0 = 560 - i * 170
        c.rrect(x0, y0, x0 + 300, y1, 30, col)
        c.text(head, x0 + 150, y0 + 60, 36, WHITE if i else INK)
        c.text(sub, x0 + 150, y0 + 106, 24, WHITE if i else INK, "Bold")
    c.text("Most of us live one step up from the wall, at best", 600, 830, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-ladder.png")

if __name__ == "__main__":
    cave(); ladder()
