#!/usr/bin/env python3
"""Tell me about yourself: what they want, present-past-future, the word budget, the
example, the last line."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "What they are really asking")
    columns(c, ("Not this", ["your resume, read out", "your life story", "your hobbies"], STONE),
            ("This", ["why are you here?", "can you explain yourself?", "can you talk?"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def shape():
    c = Canvas(); title(c, "Present, past, future")
    blocks = [("Present", "what you do now, one line", SKY), ("Past", "the two things that led here", GOLD), ("Future", "why this role is next", MINT)]
    for i, (h, s, col) in enumerate(blocks):
        x0 = 100 + i * 340
        c.rrect(x0, 200, x0 + 320, 700, 36, col)
        c.text(h, x0 + 160, 300, 38, WHITE)
        for j, ln in enumerate(wrap(c, s, 26, 260)):
            c.text(ln, x0 + 160, 420 + j * 38, 26, WHITE, "Bold")
        if i < 2: arrow(c, x0 + 320, 450, x0 + 340 + 2, 450, INK, 6)
    c.text("that order, every time", 600, 790, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-shape.png")

def length():
    c = Canvas(); title(c, "The word budget")
    vbars(c, [("30 seconds", 75, STONE), ("60 seconds", 150, GOLD), ("90 seconds", 225, MINT), ("3 minutes", 450, CORAL)],
          fmt=lambda v: f"{v} words", base=700, top=260, width=190)
    note(c, "about 150 words a minute, spoken", y=830)
    c.save(f"{OUT}/fig-04-length.png")

def example():
    c = Canvas()
    parts = [("I'm a junior in econ.", SKY), ("Last summer I ran the data for a campus food pantry, which is where I got hooked on analysis.", GOLD), ("This role is that, full time.", MINT)]
    y = 170
    for txt, col in parts:
        lines = wrap(c, txt, 30, 900)
        h = 40 + len(lines) * 46
        c.rrect(120, y, 1080, y + h, 30, WHITE, outline=col, ow=6)
        for i, ln in enumerate(lines): c.text(ln, 160, y + 43 + i * 46, 30, INK, "Bold", anchor="lm")
        y += h + 24
    legend(c, [("present", SKY), ("past", GOLD), ("future", MINT)], y + 40, x0=340, gap=220)
    c.text("forty words", 600, y + 110, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-06-example.png")

def last_line():
    c = Canvas(); title(c, "The last line")
    y = bubbles(c, [("And that's why this one caught my eye.", "me")], y0=180, phone_frame=False)
    steps(c, [("hands the conversation back", "", MINT), ("says this job, not any job", "", SKY), ("then stop talking", "", CORAL)], y0=y + 40, h=110, step=130)
    c.save(f"{OUT}/fig-07-last-line.png")

if __name__ == "__main__":
    what_it_is(); shape(); length(); example(); last_line()
