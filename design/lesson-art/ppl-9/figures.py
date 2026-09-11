#!/usr/bin/env python3
"""Why texts sound cold: the same word two ways, the gap, one dot, type it in,
and the three-second check."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def two_readings():
    c = Canvas(); title(c, "The same word, two ways")
    for k, (head, col) in enumerate((("from a happy friend", MINT), ("from an annoyed one", CORAL))):
        x0 = 110 + k * 520; x1 = x0 + 460
        c.rrect(x0, 180, x1, 760, 36, WHITE, outline=FAINT, ow=4)
        c.text(head, (x0 + x1) / 2, 240, 24, MUTED, "Bold")
        c.rrect(x0 + 120, 380, x1 - 120, 500, 40, col); c.text("fine.", (x0 + x1) / 2, 440, 40, WHITE)
        c.text("means fine" if k == 0 else "means anything but", (x0 + x1) / 2, 620, 26, INK, "Bold")
    c.save(f"{OUT}/fig-02-two-readings.png")

def gap():
    c = Canvas(); title(c, "The gap")
    vbars(c, [("how often senders\nthought the tone landed", 78, SKY), ("how often readers\nactually got it", 56, CORAL)], fmt=lambda v: f"{v}%", base=640, top=220, width=300)
    note(c, "Kruger, Epley, Parker and Ng, 2005, email", 840, size=22)
    c.save(f"{OUT}/fig-05-gap.png")

def one_dot():
    c = Canvas(); title(c, "One dot")
    for k, (txt, verdict, col) in enumerate((("Yeah", "read as sincere", MINT), ("Yeah.", "read as less sincere", CORAL))):
        x0 = 110 + k * 520; x1 = x0 + 460
        c.rrect(x0, 180, x1, 760, 36, WHITE, outline=FAINT, ow=4)
        c.rrect(x0 + 40, 240, x1 - 40, 320, 30, FAINT); c.text("wanna come tonight?", (x0 + x1) / 2, 280, 24, INK, "Bold")
        c.rrect(x0 + 120, 380, x1 - 40, 470, 34, SKY); c.text(txt, (x0 + x1) / 2 + 40, 425, 34, WHITE)
        c.rrect(x0 + 40, 620, x1 - 40, 700, 24, col); c.text(verdict, (x0 + x1) / 2, 660, 24, WHITE, "Bold")
    note(c, "Gunraj and others, 2016", 830, size=22)
    c.save(f"{OUT}/fig-06-one-dot.png")

def type_it_in():
    c = Canvas(); title(c, "Type the tone in")
    columns(c, ("Reads cold", ["ok.", "fine.", "sure."], STONE), ("Reads warm", ["ok!", "all good!", "sure, sounds fun"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-07-type-it-in.png")

def check():
    c = Canvas(); title(c, "Before you send")
    steps(c, [("Reread it as a stranger", "one in a bad mood", STONE), ("Add the feeling in words", "if it is not already there", MINT), ("Say the big things out loud", "sorry, no, and thank you", SKY)], y0=190, h=170)
    c.save(f"{OUT}/fig-09-check.png")

if __name__ == "__main__":
    two_readings(); gap(); one_dot(); type_it_in(); check()
