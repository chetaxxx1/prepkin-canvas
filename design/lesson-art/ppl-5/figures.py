#!/usr/bin/env python3
"""A real apology has three parts, drawn: the three parts in order, the two words that
cancel them, and one full apology as a text message."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255)
SKY_SOFT = (226, 238, 250)

# ---------------------------------------------------------------- 2: three parts
def three_parts():
    c = Canvas()
    c.text("Three parts, in this order", 600, 80, 44)
    rows = [("1", "What I did", "I told people what you said in private.", CORAL),
            ("2", "What it cost you", "That made it hard to trust me.", GOLD),
            ("3", "What changes", "I'm not going to repeat things you tell me.", MINT)]
    for i, (n, head, ex, col) in enumerate(rows):
        y = 190 + i * 210
        c.rrect(120, y, 1080, y + 170, 34, WHITE, outline=FAINT, ow=4)
        c.dot(200, y + 85, 44, col)
        c.text(n, 200, y + 85, 40, WHITE)
        c.text(head, 280, y + 62, 36, INK, anchor="lm")
        c.text("“" + ex + "”", 280, y + 116, 26, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-02-three-parts.png")

# ---------------------------------------------------------------- 6: but and if
def but_if():
    c = Canvas()
    c.text("Two words that cancel it", 600, 80, 44)
    pairs = [("I'm sorry, but...", "means: I'm not sorry"),
             ("Sorry if you were hurt.", "means: this is your problem")]
    for i, (said, means) in enumerate(pairs):
        y = 220 + i * 290
        # speech bubble
        c.rrect(120, y, 700, y + 130, 40, SKY_SOFT)
        c.d.polygon([c.p(190, y + 128), c.p(230, y + 128), c.p(180, y + 170)], fill=SKY_SOFT)
        c.text(said, 410, y + 65, 34, INK)
        # the word, struck
        word = "but" if i == 0 else "if"
        c.rrect(760, y + 20, 1080, y + 110, 30, CORAL_SOFT)
        c.text(word, 920, y + 65, 40, CORAL)
        c.line([(880, y + 65), (960, y + 65)], CORAL, 8)
        c.text(means, 120, y + 210, 28, MUTED, "Bold", anchor="lm")
    c.save(f"{OUT}/fig-06-but-if.png")

# ---------------------------------------------------------------- 7: one in full
def wrap(c, s, size, maxw, weight="Bold"):
    words = s.split(); lines = []; cur = ""
    for w in words:
        t = (cur + " " + w).strip()
        if c.width(t, size, weight) > maxw and cur:
            lines.append(cur); cur = w
        else:
            cur = t
    if cur: lines.append(cur)
    return lines

def text_message():
    c = Canvas()
    c.text("One in full, by text", 600, 80, 44)
    # phone
    c.rrect(300, 150, 900, 860, 60, WHITE, outline=FAINT, ow=5)
    c.rrect(520, 170, 680, 196, 13, FAINT)
    msg = ("I told Maya what you said about the party. That wasn't mine to share, and I get "
           "why you don't want to tell me things right now. I'm not doing that again.")
    lines = wrap(c, msg, 26, 440)
    lh = 40; top = 300; h = len(lines) * lh + 50
    c.rrect(340, top, 850, top + h, 36, SKY)
    for i, ln in enumerate(lines):
        c.text(ln, 370, top + 40 + i * lh, 26, WHITE, "Bold", anchor="lm")
    # the three parts, tagged under the bubble
    y = top + h + 50
    for i, (label, col) in enumerate((("what I did", CORAL), ("what it cost", GOLD), ("what changes", MINT))):
        x = 360 + i * 170
        c.dot(x, y, 12, col)
        c.text(label, x + 24, y, 22, MUTED, "Bold", anchor="lm")
    c.text("No but. No if. No excuses.", 600, 800, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-07-text.png")

if __name__ == "__main__":
    three_parts(); but_if(); text_message()
