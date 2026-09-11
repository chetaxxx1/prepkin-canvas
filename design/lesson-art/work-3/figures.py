#!/usr/bin/env python3
"""Asking at your review is too late: what a review is, the two rooms on a year
line, mid-year, evidence not need, a number, and if it is no."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def what_it_is():
    c = Canvas(); title(c, "What a review is")
    columns(c, ("What it feels like", ["the money meeting", "where you make your case", "decided in the room"], STONE), ("What it is", ["the results meeting", "the split is already done", "decided months ago"], CORAL), y0=170, y1=780)
    c.save(f"{OUT}/fig-02-what-it-is.png")

def two_rooms():
    c = Canvas(); title(c, "Two rooms")
    x0, x1, y = 140, 1060, 480
    c.rrect(x0, y - 10, x1, y + 10, 10, FAINT)
    months = ["Jan", "Mar", "May", "Jul", "Sep", "Nov"]
    for i, m in enumerate(months):
        x = x0 + (x1 - x0) * (i * 2) / 11
        c.text(m, x, y + 50, 22, MUTED, "Bold")
    xs = x0 + (x1 - x0) * 7 / 11; xr = x0 + (x1 - x0) * 11 / 11
    c.dot(xs, y, 26, CORAL); c.text("the split is decided", xs, y - 120, 26, CORAL, "Bold"); c.text("August", xs, y - 82, 22, MUTED, "Bold")
    c.dot(xr, y, 26, STONE); c.text("your review", xr - 20, y - 120, 26, INK, "Bold", anchor="rm"); c.text("December", xr - 20, y - 82, 22, MUTED, "Bold", anchor="rm")
    xa = x0 + (x1 - x0) * 5 / 11
    arrow(c, xa, 700, xa, y + 100, MINT, 8); c.text("ask here", xa, 740, 28, MINT)
    c.save(f"{OUT}/fig-04-two-rooms.png")

def mid_year():
    c = Canvas(); title(c, "When and how")
    steps(c, [("The middle of the year", "before the planning meeting", MINT), ("In a one to one, out loud", "not by email", SKY), ("Say the word 'raise'", "so nobody has to guess what you meant", CORAL)], y0=190, h=170)
    c.save(f"{OUT}/fig-05-mid-year.png")

def evidence():
    c = Canvas(); title(c, "Evidence, not need")
    columns(c, ("Need", ["rent went up", "a friend earns more", "it has been a year"], STONE), ("Evidence", ["what I shipped", "what it saved", "what I do that is not my job"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-06-evidence.png")

def a_number():
    c = Canvas(); title(c, "A number, not a feeling")
    y = bubbles(c, [("I was hoping for a bit more.", "me")], y0=230)
    c.strike(380, 352, 1010, 352, CORAL)
    bubbles(c, [("I'd like to be at $78,000.", "me")], y0=y - 60, phone_frame=False)
    c.text("say it, then stop talking", 600, 760, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-08-a-number.png")

def if_no():
    c = Canvas()
    y = bubbles(c, [("Not this cycle, I'm afraid.", "them"), ("Okay. What would I need to be doing to get there?", "me"), ("Honestly? Own the Tuesday report end to end and I can make the case.", "them")])
    c.text("now you have a list, and a reason to come back", 600, y + 30, 24, MINT, "Bold")
    c.save(f"{OUT}/fig-09-if-no.png")

if __name__ == "__main__":
    what_it_is(); two_rooms(); mid_year(); evidence(); a_number(); if_no()
