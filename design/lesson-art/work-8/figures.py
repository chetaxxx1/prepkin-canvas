#!/usr/bin/env python3
"""The cold email: what it is, five lines, before and after, subject lines, one follow-up."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "One job: make replying easy")
    columns(c, ("Gets archived", ["four paragraphs", "'pick your brain'", "no time, no ask"], STONE),
            ("Gets a reply", ["under 100 words", "one small ask", "a time and a length"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def five_lines():
    c = Canvas(); title(c, "Five lines")
    steps(c, [("Who you are", "one line", SKY), ("Why them, specifically", "one line that proves you looked", GOLD),
              ("The ask", "one small thing", CORAL), ("Make yes easy", "a time, a length", MINT), ("Thanks", "", STONE)],
          y0=150, h=110, step=128)
    c.save(f"{OUT}/fig-03-five-lines.png")

def before_after():
    c = Canvas()
    c.rrect(80, 120, 580, 820, 36, FAINT); c.rrect(620, 120, 1120, 820, 36, MINT_SOFT)
    c.text("Before", 330, 180, 32, MUTED); c.text("After", 870, 180, 32, MINT)
    before = ["Hi, I'm a student who is", "really interested in your", "industry and I would love", "to pick your brain sometime", "if you ever have a moment.", "I've attached my resume", "and some thoughts on", "the sector. Let me know!"]
    after = ["Hi Maya, I'm a junior at", "Purdue. Your pricing talk", "changed how I did my", "project. Could I ask you", "two questions about your", "first year? Fifteen minutes,", "any day next week.", "Thanks, Sam"]
    for i, ln in enumerate(before): c.text(ln, 120, 250 + i * 46, 24, MUTED, "Bold", anchor="lm")
    for i, ln in enumerate(after): c.text(ln, 660, 250 + i * 46, 24, INK, "Bold", anchor="lm")
    c.text("a chore", 330, 720, 26, MUTED, "Bold"); c.text("a yes or a no", 870, 720, 26, MINT)
    c.save(f"{OUT}/fig-04-before-after.png")

def subject():
    c = Canvas(); title(c, "The subject line")
    rows = [("Hello", STONE, "opened last"), ("Quick question", STONE, "what question?"), ("Two questions from a Purdue junior", MINT, "size of the ask, right there")]
    for i, (s, col, note_) in enumerate(rows):
        y = 190 + i * 190
        c.rrect(120, y, 1080, y + 140, 30, WHITE, outline=FAINT, ow=4)
        c.dot(180, y + 70, 22, col)
        c.text(s, 230, y + 50, 30, INK, anchor="lm"); c.text(note_, 230, y + 100, 24, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-06-subject.png")

def follow_up():
    c = Canvas(); title(c, "One follow-up, then stop")
    x0, x1, y = 150, 1050, 430
    c.rrect(x0, y - 8, x1, y + 8, 8, FAINT)
    for label, t, col, sub in [("day 0", 0, MINT, "send it"), ("day 7", 7, GOLD, "two-line bump"), ("day 14", 14, STONE, "stop")]:
        x = x0 + (x1 - x0) * t / 14
        c.dot(x, y, 26, col); c.text(label, x, y + 70, 26, MUTED, "Bold"); c.text(sub, x, y - 66, 30, INK)
    c.rrect(200, 620, 1000, 720, 30, FAINT)
    c.text("'Bumping this in case it got buried. Totally understand if not.'", 600, 670, 24, INK, "Bold")
    c.save(f"{OUT}/fig-08-follow-up.png")

if __name__ == "__main__":
    what_it_is(); five_lines(); before_after(); subject(); follow_up()
