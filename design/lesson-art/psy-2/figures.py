#!/usr/bin/env python3
"""Why you can't stop scrolling: twelve pulls, three reward schedules, the notification
loop, and the two-minute settings fix."""
import os, sys, math
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from lib import *
OUT = os.path.dirname(os.path.abspath(__file__))
WHITE = (255, 255, 255); STONE = (200, 190, 175)

def heart(c, x, y, r, col):
    c.dot(x - r * 0.5, y - r * 0.35, r * 0.55, col); c.dot(x + r * 0.5, y - r * 0.35, r * 0.55, col)
    c.d.polygon([c.p(x - r * 1.02, y - r * 0.2), c.p(x + r * 1.02, y - r * 0.2), c.p(x, y + r)], fill=col)

def pulls():
    c = Canvas()
    c.text("Twelve pulls", 600, 80, 44)
    hits = {4, 10}
    for i in range(12):
        x = 100 + (i % 6) * 180; y = 240 + (i // 6) * 260
        c.rrect(x, y, x + 140, y + 190, 30, CORAL_SOFT if i in hits else FAINT)
        if i in hits:
            heart(c, x + 70, y + 90, 34, CORAL)
        else:
            c.text("nothing", x + 70, y + 95, 22, MUTED, "Bold")
    c.text("Two out of twelve. That is enough to keep you pulling.", 600, 800, 26, INK)
    c.save(f"{OUT}/fig-02-pulls.png")

def schedules():
    c = Canvas()
    c.text("How long you keep going", 600, 80, 44)
    rows = [("reward every time", 30, STONE, "boring fast"), ("reward on a schedule", 45, SKY, "you learn when to stop"),
            ("reward at random", 100, CORAL, "you never know when to stop")]
    for i, (label, w, col, note) in enumerate(rows):
        y = 210 + i * 190
        c.text(label, 120, y, 28, INK, "Bold", anchor="lm")
        c.rrect(120, y + 30, 120 + 900 * w / 100, y + 110, 26, col)
        c.text(note, 120 + 900 * w / 100 + 20 if w < 60 else 140, y + 70, 24, MUTED if w < 60 else WHITE, "Bold", anchor="lm")
    c.text("Skinner, 1950s: the random schedule keeps the pecking going longest", 600, 830, 22, MUTED, "Bold")
    c.save(f"{OUT}/fig-03-schedules.png")

def arc_arrow(c, cx, cy, r, a0, a1, colour, w=9):
    pts = []
    for i in range(41):
        a = math.radians(a0 + (a1 - a0) * i / 40 - 90)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    c.line(pts, colour, w)
    ax, ay = pts[-1]; bx, by = pts[-3]
    ang = math.atan2(ay - by, ax - bx); L = 30
    c.d.polygon([c.p(ax - L * math.cos(ang - 0.5), ay - L * math.sin(ang - 0.5)), c.p(ax, ay),
                 c.p(ax - L * math.cos(ang + 0.5), ay - L * math.sin(ang + 0.5))], fill=colour)

def loop():
    c = Canvas()
    c.text("Thirty times a day", 600, 80, 44)
    cx, cy, r = 600, 480, 250
    pos = {"buzz": (cx, cy - r), "pull": (cx + r * 0.87, cy + r * 0.5), "maybe": (cx - r * 0.87, cy + r * 0.5)}
    gap = 36
    for a0, a1 in ((gap, 120 - gap), (120 + gap, 240 - gap), (240 + gap, 360 - gap)):
        arc_arrow(c, cx, cy, r, a0, a1, STONE)
    for k, (label, col, ink) in {"buzz": ("a buzz", SKY, WHITE), "pull": ("you pull", CORAL, WHITE), "maybe": ("maybe a reward", GOLD, INK)}.items():
        x, y = pos[k]
        c.rrect(x - 160, y - 60, x + 160, y + 60, 34, col)
        c.text(label, x, y, 32, ink)
    c.save(f"{OUT}/fig-06-loop.png")

def settings():
    c = Canvas()
    c.text("Two minutes, once", 600, 80, 44)
    c.rrect(330, 150, 870, 840, 60, WHITE, outline=FAINT, ow=5)
    c.rrect(540, 170, 660, 196, 13, FAINT)
    c.text("Notifications", 600, 260, 34, INK)
    rows = [("Feed apps", "video, photos, the timeline", False), ("Messages from people", "texts, calls, group chats", True)]
    for i, (head, sub, on) in enumerate(rows):
        y = 330 + i * 190
        c.rrect(370, y, 830, y + 140, 30, MINT_SOFT if on else CORAL_SOFT)
        c.text(head, 400, y + 50, 28, INK, anchor="lm")
        c.text(sub, 400, y + 96, 22, MUTED, "Bold", anchor="lm")
        # a toggle
        c.rrect(730, y + 42, 810, y + 90, 24, MINT if on else STONE)
        c.dot(790 if on else 750, y + 66, 18, WHITE)
    c.text("off for feeds, on for people", 600, 760, 26, MUTED, "Bold")
    c.save(f"{OUT}/fig-08-settings.png")

if __name__ == "__main__":
    pulls(); schedules(); loop(); settings()
