#!/usr/bin/env python3
"""Anxiety is a body thing: the alarm, the loop, the physiological sigh, why the exhale, the
study, shrinking the thought."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "The alarm, with no fire")
    columns(c, ("The alarm is physical", ["fast heart", "fast breath", "tight muscles"], CORAL),
            ("The thoughts come after", ["'I'm going to fail'", "'everyone will see'", "the brain explaining"], STONE), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def loop():
    c = Canvas(); title(c, "The loop")
    cx, cy, r = 600, 480, 230
    nodes = [("body fires", -90, CORAL), ("brain explains", 30, SKY), ("the story scares the body", 150, GOLD)]
    pts = []
    for label, ang, col in nodes:
        x = cx + r * math.cos(math.radians(ang)); y = cy + r * math.sin(math.radians(ang)); pts.append((x, y, col, label))
    for i, (x, y, col, label) in enumerate(pts):
        nx, ny, _, _ = pts[(i + 1) % 3]
        ax, ay = x + (nx - x) * 0.32, y + (ny - y) * 0.32; bx, by = x + (nx - x) * 0.68, y + (ny - y) * 0.68
        arrow(c, ax, ay, bx, by, STONE, 6)
    for x, y, col, label in pts:
        c.dot(x, y, 60, col)
    c.text("body fires", pts[0][0], pts[0][1] - 100, 28, INK, "Bold")
    c.text("brain explains", pts[1][0] + 90, pts[1][1] + 10, 28, INK, "Bold", anchor="lm")
    c.text("the story scares", pts[2][0] - 90, pts[2][1] - 6, 28, INK, "Bold", anchor="rm"); c.text("the body more", pts[2][0] - 90, pts[2][1] + 30, 28, INK, "Bold", anchor="rm")
    c.text("start with the body", 600, 820, 28, CORAL)
    c.save(f"{OUT}/fig-03-loop.png")

def sigh():
    c = Canvas(); title(c, "The physiological sigh")
    x0, x1, base = 150, 1050, 640
    pts = []
    for i in range(0, 201):
        t = i / 200
        if t < 0.22: v = t / 0.22
        elif t < 0.30: v = 1 - 0.25 * (t - 0.22) / 0.08
        elif t < 0.38: v = 0.75 + 0.35 * (t - 0.30) / 0.08
        else: v = 1.1 * (1 - (t - 0.38) / 0.62)
        pts.append((x0 + (x1 - x0) * t, base - 380 * max(0, v)))
    c.line(pts, SKY, 9)
    c.text("in, through the nose", x0 + 40, base + 50, 24, INK, "Bold", anchor="lm")
    c.text("one more sip", x0 + (x1 - x0) * 0.30, base - 470, 24, INK, "Bold")
    c.text("long, slow out, through the mouth", x0 + (x1 - x0) * 0.70, base + 50, 24, INK, "Bold")
    c.text("that is one. Do three.", 600, 800, 28, MINT)
    c.save(f"{OUT}/fig-04-sigh.png")

def why():
    c = Canvas(); title(c, "Breathe in, heart speeds. Out, it slows.")
    x0, x1, base = 150, 1050, 560
    pts = [(x0 + (x1 - x0) * i / 200, base - 160 * math.sin(i / 200 * 2 * math.pi * 2)) for i in range(201)]
    c.line(pts, CORAL, 8)
    for k in range(2):
        xi = x0 + (x1 - x0) * (0.125 + k * 0.5); xo = x0 + (x1 - x0) * (0.375 + k * 0.5)
        c.text("in", xi, base + 60 + 30, 24, MUTED, "Bold"); c.text("out", xo, base + 60 + 30, 24, MUTED, "Bold")
    c.text("faster", x0 - 30, base - 160, 22, MUTED, "Bold", anchor="rm"); c.text("slower", x0 - 30, base + 160, 22, MUTED, "Bold", anchor="rm")
    c.text("a long exhale tips the balance toward slow", 600, 800, 26, MINT)
    c.save(f"{OUT}/fig-05-why.png")

def study():
    c = Canvas(); title(c, "Five minutes a day, one month")
    vbars(c, [("meditation", 6, STONE), ("cyclic sighing", 10, MINT)], fmt=lambda v: "", base=640, top=240, width=280, gap=180)
    c.text("bigger lift in mood, lower resting breathing rate", 600, 760, 24, MUTED, "Bold")
    note(c, "Balban et al., 2023, Cell Reports Medicine", y=820, size=20)
    c.save(f"{OUT}/fig-06-study.png")

def thoughts():
    c = Canvas(); title(c, "Then the thought gets smaller")
    c.rrect(100, 200, 1100, 400, 40, CORAL); c.text("'I'm going to fail'", 600, 300, 40, WHITE)
    arrow(c, 600, 430, 600, 500, STONE, 8)
    c.rrect(300, 540, 900, 680, 34, MINT_SOFT); c.text("'I'm worried about question three'", 600, 610, 28, INK, "Bold")
    c.text("smaller, truer, something you can act on", 600, 780, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-thoughts.png")

if __name__ == "__main__":
    what_it_is(); loop(); sigh(); why(); study(); thoughts()
