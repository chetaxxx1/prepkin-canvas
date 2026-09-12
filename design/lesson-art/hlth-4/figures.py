#!/usr/bin/env python3
"""The ten-minute walk: what it does, walk vs candy bar, the creativity numbers, when it
fits, stacking it."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_does():
    c = Canvas(); title(c, "Ten minutes, brisk")
    steps(c, [("Heart rate up a little", "more blood to the brain", CORAL), ("Mood chemicals shift", "energy up, tension down", GOLD), ("Fast, free, measured", "no gym, no app", MINT)], y0=180, h=160, step=185, num=False)
    c.save(f"{OUT}/fig-02-what-it-does.png")

def candy():
    c = Canvas(); title(c, "Energy over the next two hours")
    x0, x1, y0, y1 = 170, 1080, 180, 640
    axes(c, x0, x1, y0, y1, xmax=120, ymax=100, ystep=25, xstep=30, fmt=lambda v: "", xunit="min")
    curve(c, lambda t: 50 + 45 * math.exp(-((t - 25) / 22) ** 2) - 30 * math.exp(-((t - 80) / 30) ** 2), 120, x0, x1, y0, y1, 100, GOLD, w=8)
    curve(c, lambda t: 50 + 35 * (1 - math.exp(-t / 10)) * math.exp(-t / 150), 120, x0, x1, y0, y1, 100, MINT, w=8)
    c.dash(x0, y1 - (y1 - y0) * 0.5, x1, y1 - (y1 - y0) * 0.5, STONE, w=3)
    c.text("where you started", x0 + 16, y1 - (y1 - y0) * 0.5 + 36, 22, MUTED, "Bold", anchor="lm")
    legend(c, [("candy bar", GOLD), ("ten-minute walk", MINT)], 740, x0=330, gap=300)
    c.text("the candy peaks, then dips below where you started", 600, 830, 24, MUTED, "Bold")
    note(c, "Thayer, 1987", y=790, size=20)
    c.save(f"{OUT}/fig-03-candy.png")

def ideas():
    c = Canvas(); title(c, "New uses for a button")
    vbars(c, [("sitting", 100, STONE), ("walking", 160, MINT)], fmt=lambda v: "" if v == 100 else "+60%", base=640, top=240, width=260, gap=200)
    c.text("four in five people did better on their feet", 600, 760, 26, MUTED, "Bold")
    note(c, "Oppezzo and Schwartz, Stanford, 2014", y=820, size=20)
    c.save(f"{OUT}/fig-04-ideas.png")

def when():
    c = Canvas(); title(c, "Three natural slots")
    x0, x1, y = 150, 1050, 430
    c.rrect(x0, y - 8, x1, y + 8, 8, FAINT)
    for i, h in enumerate(["8am", "12pm", "4pm", "8pm"]):
        c.text(h, x0 + i * 300, y + 56, 24, MUTED, "Bold")
    for label, t, col in [("after lunch", 1.15, GOLD), ("before a hard task", 1.9, CORAL), ("after studying", 2.7, MINT)]:
        x = x0 + t * 300; c.dot(x, y, 24, col); c.text(label, x, y - 60, 24, INK, "Bold")
    c.text("pick one and tie it to something you already do", 600, 700, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-when.png")

def stack_it():
    c = Canvas(); title(c, "It adds up")
    vbars(c, [("a day", 10, MINT), ("a week", 70, MINT), ("a month", 300, MINT)], fmt=lambda v: f"{v} min" if v < 100 else "5 hours", base=680, top=240, width=220)
    c.text("walk to the far coffee shop. Take the call standing.", 600, 810, 24, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-stack.png")

if __name__ == "__main__":
    what_it_does(); candy(); ideas(); when(); stack_it()
