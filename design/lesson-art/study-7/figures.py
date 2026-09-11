#!/usr/bin/env python3
"""Notes you'll actually reread: the three-zone page, the question column, the bottom
strip, transcript vs quiz, and the timing."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))

def page(c, x0=220, y0=140, x1=980, y1=820, fill_notes=False, fill_q=False, fill_sum=False, labels=True):
    c.rrect(x0, y0, x1, y1, 20, WHITE, outline=STONE, ow=4)
    cx = x0 + (x1 - x0) * 0.32; sy = y1 - 120
    c.line([(cx, y0), (cx, sy)], STONE, 4); c.line([(x0, sy), (x1, sy)], STONE, 4)
    if fill_notes:
        for i in range(9): c.rrect(cx + 30, y0 + 40 + i * 52, x1 - 40 - (i % 3) * 90, y0 + 58 + i * 52, 6, FAINT)
    if fill_q:
        for i in range(3): c.rrect(x0 + 24, y0 + 60 + i * 160, cx - 24, y0 + 130 + i * 160, 16, MINT_SOFT); c.text("?", (x0 + cx) / 2, y0 + 95 + i * 160, 34, MINT)
    if fill_sum:
        c.rrect(x0 + 30, sy + 40, x1 - 60, sy + 62, 8, GOLD); c.rrect(x0 + 30, sy + 78, x1 - 300, sy + 100, 8, GOLD_SOFT)
    if labels:
        c.text("questions", (x0 + cx) / 2, y0 - 30, 22, MUTED, "Bold"); c.text("notes from class", (cx + x1) / 2, y0 - 30, 22, MUTED, "Bold")
        c.text("one sentence", (x0 + x1) / 2, y1 + 34, 22, MUTED, "Bold")

def three_zones():
    c = Canvas(); title(c, "One page, three zones", y=60); page(c, y0=160, y1=800)
    c.save(f"{OUT}/fig-01-page.png")

def question_column():
    c = Canvas(); title(c, "After class: the left column", y=60); page(c, y0=160, y1=800, fill_notes=True, fill_q=True)
    c.save(f"{OUT}/fig-03-questions.png")

def summary():
    c = Canvas(); title(c, "The bottom strip", y=60); page(c, y0=160, y1=800, fill_notes=True, fill_q=True, fill_sum=True)
    c.save(f"{OUT}/fig-04-summary.png")

def transcript_vs_quiz():
    c = Canvas(); title(c, "Transcript or quiz")
    columns(c, ("A transcript", ["everything that was said", "no questions", "you will never reread it"], STONE), ("A quiz page", ["the same notes", "a question for each chunk", "cover, answer, check"], MINT), y0=170, y1=780)
    c.save(f"{OUT}/fig-06-transcript-vs-quiz.png")

def timing():
    c = Canvas(); title(c, "Three touches, one page")
    steps(c, [("In class", "write fast and messy on the right", CORAL), ("The same day", "ten minutes: turn the notes into questions", GOLD), ("A week later", "cover the right side and quiz yourself", MINT)], y0=190, h=170)
    c.save(f"{OUT}/fig-08-timing.png")

if __name__ == "__main__":
    three_zones(); question_column(); summary(); transcript_vs_quiz(); timing()
