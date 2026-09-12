"""The effects library for costume acts, one Lottie file each.

    python3 design/vfx/gen_effects.py            # all of them
    python3 design/vfx/gen_effects.py confetti   # just one

Each is a short burst centred on (200, 200) in a 400x400 comp; acts place and size them in
radii (see `Cue.fxDx/fxDy/fxScale` in the Sprout build's src/acts.ts). The smoke poof has
its own file, gen_ninja_smoke.py.
"""
import math, random, sys
from lottie import C, SIZE, Comp, anim, ellipse, fill, group, path, rect, soft_fill, star, still, stroke, transform

random.seed(11)

GOLD = (0.96, 0.78, 0.30)
VIOLET = (0.62, 0.45, 0.90)
LILAC = (0.80, 0.70, 0.98)
WHITE = (0.98, 0.98, 1.0)
GREY = (0.55, 0.58, 0.64)
ASH = (0.40, 0.43, 0.49)
INK = (0.13, 0.14, 0.18)
ACID = (0.55, 0.92, 0.45)
PLUM = (0.45, 0.20, 0.60)
CONFETTI = [(0.96, 0.40, 0.35), (0.98, 0.78, 0.30), (0.35, 0.78, 0.62), (0.40, 0.60, 0.95), (0.90, 0.55, 0.85), (0.99, 0.96, 0.85)]


def slash():
    """One white crescent along a blade sweep, drawn in 3 frames and gone by 9. Two thin
    streaks trail it. The act mirrors nothing here: the crescent is symmetric enough that a
    left or right fin reads the same."""
    c = Comp("slash", 10)
    # Crescent: outer arc down, inner arc back, as a polygon of arc samples. Shape space is
    # the layer's own, centred on (0, 0); the layer's position puts it at the comp centre.
    pts = []
    for i in range(13):
        a = math.radians(-150 + i * 10)
        pts.append((math.cos(a) * 150, math.sin(a) * 150))
    for i in range(12, -1, -1):
        a = math.radians(-150 + i * 10)
        w = 26 * math.sin(math.pi * i / 12) + 4
        pts.append((math.cos(a) * (150 - w), math.sin(a) * (150 - w)))
    c.add("crescent", [group([path(pts), fill(WHITE)])],
          s=anim([(0, [55, 55, 100], "out"), (3, [104, 104, 100], "linear"), (9, [118, 118, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (1, [96], "linear"), (4, [96], "in"), (9, [0], "linear")], 1),
          r=anim([(0, [-16], "out"), (9, [8], "linear")], 1))
    for n, (a0, ln) in enumerate(((-120, 70), (-100, 90), (-80, 60))):
        a = math.radians(a0)
        x0, y0 = math.cos(a) * 95, math.sin(a) * 95
        x1, y1 = math.cos(a) * (95 + ln), math.sin(a) * (95 + ln)
        c.add(f"streak{n}", [group([path([(x0, y0), (x1, y1)], closed=False), stroke(WHITE, 5)])],
              o=anim([(1 + n, [0], "out"), (2 + n, [80], "linear"), (5 + n, [80], "in"), (9, [0], "linear")], 1),
              p=anim([(0, [C, C, 0], "out"), (9, [C + math.cos(a) * 30, C + math.sin(a) * 30, 0], "linear")], 3))
    c.write()


def sparkle_burst():
    """Ten four-point stars thrown outward, each spinning and swelling before it winks out,
    over a soft gold flash. The spell's payoff and the diploma's shine both use it."""
    c = Comp("sparkle-burst", 22)
    for n in range(10):
        a = math.radians(n * 36 + random.uniform(-10, 10))
        far = random.uniform(95, 150)
        col = (GOLD, VIOLET, WHITE)[n % 3]
        size = random.uniform(16, 26)
        d0 = random.randint(0, 3)
        c.add(f"star{n}", [group([star(4, size, size * 0.38), fill(col)])],
              p=anim([(d0, [C, C, 0], "out"), (d0 + 9, [C + math.cos(a) * far, C + math.sin(a) * far, 0], "linear"),
                      (21, [C + math.cos(a) * far * 1.12, C + math.sin(a) * far * 1.12 - 8, 0], "linear")], 3),
              s=anim([(d0, [20, 20, 100], "out"), (d0 + 5, [110, 110, 100], "inout"), (d0 + 12, [70, 70, 100], "in"), (21, [0, 0, 100], "linear")], 3),
              r=anim([(d0, [0], "linear"), (21, [random.choice((-1, 1)) * random.uniform(90, 200)], "linear")], 1),
              o=anim([(d0, [100], "linear"), (d0 + 10, [100], "in"), (21, [0], "linear")], 1))
    c.add("flash", [group([ellipse(180), soft_fill(GOLD, 180, 0.2)])],
          s=anim([(0, [30, 30, 100], "out"), (5, [120, 120, 100], "linear"), (16, [150, 150, 100], "linear")], 3),
          o=anim([(0, [90], "linear"), (4, [90], "out"), (16, [0], "linear")], 1))
    c.write()


def arcane_ring():
    """A flat spell circle under him: two rings seen at an angle, six motes orbiting the
    outer one, a violet glow that breathes. Fades in, holds while he floats, fades out."""
    frames = 54
    c = Comp("arcane-ring", frames)
    rx, ry = 150, 46
    for n in range(6):
        keys = []
        for f in range(0, frames + 1, 3):
            a = math.radians(n * 60 + f * 6)
            keys.append((f, [C + math.cos(a) * rx, C + math.sin(a) * ry, 0], "linear"))
        c.add(f"mote{n}", [group([ellipse(16), soft_fill(LILAC, 16, 0.4)])],
              p=anim(keys, 3),
              o=anim([(0, [0], "out"), (8, [100], "linear"), (frames - 12, [100], "in"), (frames - 1, [0], "linear")], 1))
    c.add("outer", [group([ellipse(rx * 2, ry * 2), stroke(VIOLET, 6)])],
          s=anim([(0, [40, 40, 100], "out"), (10, [100, 100, 100], "linear"), (frames - 1, [104, 104, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (8, [85], "linear"), (frames - 12, [85], "in"), (frames - 1, [0], "linear")], 1))
    c.add("inner", [group([ellipse(rx * 1.2, ry * 1.2), stroke(LILAC, 4)])],
          s=anim([(0, [40, 40, 100], "out"), (12, [100, 100, 100], "linear"), (frames - 1, [96, 96, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (10, [70], "linear"), (frames - 12, [70], "in"), (frames - 1, [0], "linear")], 1))
    c.add("glow", [group([ellipse(rx * 2.2, ry * 2.4), soft_fill(VIOLET, rx * 2.2, 0.1)])],
          s=anim([(0, [50, 50, 100], "out"), (10, [100, 100, 100], "inout"), (27, [112, 112, 100], "inout"),
                  (44, [100, 100, 100], "linear"), (frames - 1, [90, 90, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (10, [60], "linear"), (frames - 12, [60], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def fizzle():
    """The spell that does not happen: three grey wisps and four sparks that pop, drop and die."""
    c = Comp("fizzle", 16)
    for n in range(4):
        a = math.radians(-120 + n * 30 + random.uniform(-8, 8))
        far = random.uniform(40, 70)
        c.add(f"spark{n}", [group([star(4, 12, 4), fill(GOLD)])],
              p=anim([(0, [C, C, 0], "out"), (5, [C + math.cos(a) * far, C + math.sin(a) * far, 0], "in"),
                      (15, [C + math.cos(a) * far * 1.1, C + math.sin(a) * far + 60, 0], "linear")], 3),
              s=anim([(0, [30, 30, 100], "out"), (3, [100, 100, 100], "in"), (15, [10, 10, 100], "linear")], 3),
              o=anim([(0, [100], "linear"), (6, [100], "in"), (13, [0], "linear"), (15, [0], "linear")], 1))
    for n in range(3):
        a = math.radians(-100 + n * 40)
        d = random.uniform(44, 60)
        c.add(f"wisp{n}", [group([ellipse(d), soft_fill(GREY, d, 0.35)])],
              p=anim([(0, [C, C, 0], "out"), (15, [C + math.cos(a) * 55, C + math.sin(a) * 55 - 30, 0], "linear")], 3),
              s=anim([(0, [30, 30, 100], "out"), (8, [100, 100, 100], "linear"), (15, [120, 120, 100], "linear")], 3),
              o=anim([(0, [70], "linear"), (5, [70], "in"), (15, [0], "linear")], 1))
    c.write()


def confetti():
    """Twenty-four slips thrown up in a fan, falling under gravity and flipping as they go.
    The flip is a scale-x wobble, which is how a flat slip reads as tumbling in 2D."""
    frames = 42
    c = Comp("confetti", frames)
    for n in range(24):
        a = math.radians(-90 + random.uniform(-55, 55))
        v = random.uniform(150, 230)
        col = CONFETTI[n % len(CONFETTI)]
        w, h = random.uniform(12, 18), random.uniform(8, 12)
        keys = []
        vx, vy = math.cos(a) * v, math.sin(a) * v
        x, y = C, C
        for f in range(0, frames + 1, 3):
            t = f / 30
            keys.append((f, [C + vx * t, C + vy * t + 260 * t * t, 0], "linear"))
        sk = []
        period = random.uniform(6, 10)
        for f in range(0, frames + 1, 2):
            sk.append((f, [max(12, abs(math.cos(f / period * math.pi)) * 100), 100, 100], "linear"))
        c.add(f"slip{n}", [group([rect(w, h, 2), fill(col)])],
              p=anim(keys, 3), s=anim(sk, 3),
              r=anim([(0, [random.uniform(0, 360)], "linear"), (frames - 1, [random.uniform(0, 360) + random.choice((-1, 1)) * 240], "linear")], 1),
              o=anim([(0, [100], "linear"), (frames - 10, [100], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def bats():
    """Three small bats that flit up and out from the bow, wings beating. Each bat is one
    path that morphs between wings-up and wings-down; the morph IS the flap."""
    frames = 40
    c = Comp("bats", frames)

    def bat(up):
        w = -18 if up else 14      # wing tip height relative to the body
        return [(-34, w), (-14, -4), (-6, -12), (0, -6), (6, -12), (14, -4), (34, w), (18, 8), (8, 6), (0, 12), (-8, 6), (-18, 8)]

    for n in range(3):
        side = -1 if n % 2 else 1
        keys = []
        for f in range(0, frames + 1, 4):
            keys.append((f, bat(up=(f // 4) % 2 == 0), "inout"))
        x_end = C + side * random.uniform(120, 170)
        y_end = C - random.uniform(140, 190)
        d0 = n * 3
        c.add(f"bat{n}", [group([path(None, keys=keys), fill(INK)])],
              p=anim([(d0, [C, C - 20, 0], "out"), (d0 + 12, [C + side * 60, C - 90, 0], "inout"),
                      (frames - 1, [x_end, y_end, 0], "linear")], 3),
              s=anim([(d0, [40, 40, 100], "out"), (d0 + 6, [100, 100, 100], "linear"), (frames - 1, [70, 70, 100], "linear")], 3),
              r=anim([(d0, [side * 20], "linear"), (frames - 1, [side * -15], "linear")], 1),
              o=anim([(d0, [0], "out"), (d0 + 3, [100], "linear"), (frames - 8, [100], "in"), (frames - 1, [0], "linear")], 1),
              ip=d0)
    c.write()


def hex_burst():
    """A curse landing: an acid-green flash, two plum rings that snap outward, twelve green
    sparks, and a five-point star that flares and is gone."""
    c = Comp("hex-burst", 20)
    c.add("sigil", [group([star(5, 70, 28), stroke(ACID, 6)])],
          s=anim([(0, [20, 20, 100], "out"), (5, [110, 110, 100], "inout"), (19, [150, 150, 100], "linear")], 3),
          r=anim([(0, [0], "linear"), (19, [90], "linear")], 1),
          o=anim([(0, [0], "out"), (2, [95], "linear"), (8, [95], "in"), (19, [0], "linear")], 1))
    for n in range(12):
        a = math.radians(n * 30 + random.uniform(-6, 6))
        far = random.uniform(110, 160)
        c.add(f"spark{n}", [group([ellipse(10), fill(ACID)])],
              p=anim([(1, [C, C, 0], "out"), (10, [C + math.cos(a) * far, C + math.sin(a) * far, 0], "linear"),
                      (19, [C + math.cos(a) * far * 1.15, C + math.sin(a) * far * 1.15, 0], "linear")], 3),
              s=anim([(1, [120, 120, 100], "linear"), (19, [0, 0, 100], "linear")], 3),
              o=anim([(1, [100], "linear"), (9, [100], "in"), (19, [0], "linear")], 1))
    for n, (delay, w) in enumerate(((0, 9), (3, 5))):
        c.add(f"ring{n}", [group([ellipse(200), stroke(PLUM, [(delay, [w], "out"), (19, [1], "linear")],
                                                        [(delay, [90], "out"), (19, [0], "linear")])])],
              s=anim([(delay, [10, 10, 100], "out"), (19, [140 - n * 20, 140 - n * 20, 100], "linear")], 3))
    c.add("flash", [group([ellipse(160), soft_fill(ACID, 160, 0.15)])],
          s=anim([(0, [20, 20, 100], "out"), (4, [110, 110, 100], "linear"), (14, [130, 130, 100], "linear")], 3),
          o=anim([(0, [95], "linear"), (3, [95], "out"), (14, [0], "linear")], 1))
    c.write()


def shuriken():
    """One throwing star flying right and a little up, spinning, two ghosts behind it. Acts
    mirror the canvas when he faces left, so the star always flies the way he looks."""
    frames = 16
    c = Comp("shuriken", frames)
    for n, (lag, op) in enumerate(((0, 100), (2, 40), (4, 18))):
        c.add(f"star{n}", [group([star(4, 30, 11), fill(ASH)]), group([star(4, 30, 11), stroke(WHITE, 3, 70)])],
              p=anim([(lag, [C - 20, C + 10, 0], "out"), (12 + lag, [C + 190, C - 60, 0], "linear"), (frames - 1, [C + 230, C - 78, 0], "linear")], 3),
              r=anim([(0, [0], "linear"), (frames - 1, [900], "linear")], 1),
              s=anim([(lag, [40, 40, 100], "out"), (lag + 3, [100, 100, 100], "linear"), (frames - 1, [80, 80, 100], "linear")], 3),
              o=anim([(lag, [op], "linear"), (11, [op], "in"), (frames - 1, [0], "linear")], 1), ip=lag)
    c.write()


def speed_lines():
    """Six horizontal streaks that stretch out to the LEFT of the centre — the wake of a dash
    to the right. Mirrored by the act for a dash the other way."""
    frames = 12
    c = Comp("speed-lines", frames)
    for n in range(6):
        y = C + (n - 2.5) * 34 + random.uniform(-6, 6)
        ln = random.uniform(90, 170)
        x1 = C - random.uniform(20, 60)
        c.add(f"line{n}", [group([path([(0, 0), (-ln, 0)], closed=False), stroke(WHITE, random.uniform(4, 8), 85)])],
              p=anim([(0, [x1 + 40, y, 0], "out"), (frames - 1, [x1 - 90, y, 0], "linear")], 3),
              s=anim([(0, [20, 100, 100], "out"), (4, [100, 100, 100], "linear"), (frames - 1, [60, 100, 100], "linear")], 3),
              o=anim([(0, [0], "out"), (1, [85], "linear"), (5, [85], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def starfall():
    """Fourteen stars raining down and to the left with thin trails, over 1.5 seconds. Scaled
    up by the ult it covers the whole tank."""
    frames = 46
    c = Comp("starfall", frames)
    for n in range(14):
        x0 = random.uniform(-40, SIZE + 60)
        d0 = random.randint(0, 24)
        col = (GOLD, WHITE, LILAC)[n % 3]
        size = random.uniform(10, 18)
        c.add(f"trail{n}", [group([path([(0, 0), (70, -120)], closed=False), stroke(col, 3, 60)])],
              p=anim([(d0, [x0, -40, 0], "linear"), (d0 + 18, [x0 - 140, SIZE + 40, 0], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 2, [60], "linear"), (d0 + 14, [60], "in"), (d0 + 18, [0], "linear")], 1),
              ip=d0, op=d0 + 19)
        c.add(f"star{n}", [group([star(4, size, size * 0.4), fill(col)])],
              p=anim([(d0, [x0, -40, 0], "linear"), (d0 + 18, [x0 - 140, SIZE + 40, 0], "linear")], 3),
              r=anim([(d0, [0], "linear"), (d0 + 18, [180], "linear")], 1),
              o=anim([(d0, [0], "out"), (d0 + 2, [100], "linear"), (d0 + 15, [100], "in"), (d0 + 18, [0], "linear")], 1),
              ip=d0, op=d0 + 19)
    c.write()


def comet():
    """A shooting star crossing from lower-left to upper-right with a long fading tail."""
    frames = 24
    c = Comp("comet", frames)
    c.add("head", [group([ellipse(22), soft_fill(WHITE, 22, 0.5)]), group([star(4, 20, 8), fill(GOLD)])],
          p=anim([(0, [C - 190, C + 120, 0], "out"), (16, [C + 170, C - 110, 0], "linear"), (frames - 1, [C + 230, C - 150, 0], "linear")], 3),
          r=anim([(0, [0], "linear"), (frames - 1, [300], "linear")], 1),
          o=anim([(0, [0], "out"), (2, [100], "linear"), (17, [100], "in"), (frames - 1, [0], "linear")], 1))
    for n in range(3):
        lag = 2 + n * 2
        c.add(f"tail{n}", [group([ellipse(16 - n * 3), soft_fill(GOLD, 16 - n * 3, 0.3)])],
              p=anim([(lag, [C - 190, C + 120, 0], "out"), (16 + lag, [C + 170, C - 110, 0], "linear"), (frames - 1, [C + 200, C - 130, 0], "linear")], 3),
              o=anim([(lag, [0], "out"), (lag + 2, [70 - n * 15], "linear"), (16, [70 - n * 15], "in"), (frames - 1, [0], "linear")], 1), ip=lag)
    for n in range(8):
        f0 = 3 + n * 2
        t = f0 / 16
        x, y = C - 190 + 360 * t, C + 120 - 230 * t
        c.add(f"dust{n}", [group([ellipse(8), fill(WHITE)])],
              p=anim([(f0, [x, y, 0], "out"), (f0 + 8, [x - 20 + random.uniform(-10, 10), y + 24 + random.uniform(-8, 8), 0], "linear")], 3),
              s=anim([(f0, [100, 100, 100], "linear"), (f0 + 8, [0, 0, 100], "linear")], 3),
              o=anim([(f0, [80], "linear"), (f0 + 8, [0], "linear")], 1), ip=f0, op=f0 + 9)
    c.write()


def spotlights():
    """Two pale beams from above that sweep across each other and fade. Wide and long — the
    ult scales this to the whole tank."""
    frames = 50
    c = Comp("spotlights", frames)
    beam = [(-40, 0), (40, 0), (150, 420), (-150, 420)]
    for n, (r0, r1) in enumerate(((-28, 22), (30, -20))):
        c.add(f"beam{n}", [group([path(beam), soft_fill(WHITE, 600, 0.0)])],
              p=still([C + (n * 2 - 1) * 60, -60, 0]),
              r=anim([(0, [r0], "inout"), (frames - 1, [r1], "linear")], 1),
              o=anim([(0, [0], "out"), (8, [55], "linear"), (frames - 10, [55], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def camera_flash():
    """A white flash and four viewfinder corners that snap in, hold, and fade."""
    frames = 16
    c = Comp("camera-flash", frames)
    corner = [(0, 0), (40, 0), (40, 7), (7, 7), (7, 40), (0, 40)]
    for n, (sx, sy) in enumerate(((1, 1), (-1, 1), (1, -1), (-1, -1))):
        c.add(f"corner{n}", [group([path(corner), fill(WHITE)])],
              p=anim([(0, [C - sx * 150, C - sy * 150, 0], "out"), (3, [C - sx * 120, C - sy * 120, 0], "linear"), (frames - 1, [C - sx * 120, C - sy * 120, 0], "linear")], 3),
              s=still([sx * 100, sy * 100, 100]),
              o=anim([(0, [0], "out"), (2, [95], "linear"), (10, [95], "in"), (frames - 1, [0], "linear")], 1))
    c.add("flash", [group([ellipse(300), soft_fill(WHITE, 300, 0.4)])],
          s=anim([(2, [40, 40, 100], "out"), (5, [140, 140, 100], "linear"), (frames - 1, [160, 160, 100], "linear")], 3),
          o=anim([(2, [0], "out"), (3, [100], "linear"), (5, [100], "in"), (12, [0], "linear")], 1), ip=2)
    c.write()


def brew_bubbles():
    """Acid-green bubbles that rise, wobble and pop."""
    frames = 36
    c = Comp("brew-bubbles", frames)
    for n in range(9):
        x = C + random.uniform(-70, 70)
        d0 = random.randint(0, 14)
        d = random.uniform(14, 30)
        c.add(f"bubble{n}", [group([ellipse(d), stroke(ACID, 4, 90)]), group([ellipse(d * 0.3), fill(WHITE, 60)], tr=transform(p=(-d * 0.2, -d * 0.2)))],
              p=anim([(d0, [x, C + 60, 0], "out"), (d0 + 8, [x + random.uniform(-12, 12), C - 10, 0], "inout"), (d0 + 18, [x + random.uniform(-14, 14), C - 110, 0], "linear")], 3),
              s=anim([(d0, [30, 30, 100], "out"), (d0 + 6, [100, 100, 100], "linear"), (d0 + 17, [110, 110, 100], "linear"), (d0 + 18, [140, 140, 100], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 2, [100], "linear"), (d0 + 16, [100], "in"), (d0 + 18, [0], "linear")], 1),
              ip=d0, op=d0 + 19)
    c.write()


def lightning():
    """Three jagged green bolts from the top, each a flash of a few frames, with an afterglow."""
    frames = 18
    c = Comp("lightning", frames)
    for n, (x0, d0) in enumerate(((C - 90, 0), (C + 70, 5), (C - 10, 10))):
        pts = [(x0, -60)]
        y = -60
        x = x0
        while y < SIZE + 20:
            y += random.uniform(40, 70)
            x += random.uniform(-45, 45)
            pts.append((x, y))
        c.add(f"glow{n}", [group([path(pts, closed=False), stroke(ACID, 16, 35)])],
              o=anim([(d0, [0], "out"), (d0 + 1, [35], "linear"), (d0 + 4, [35], "in"), (d0 + 7, [0], "linear")], 1), ip=d0, op=d0 + 8)
        c.add(f"bolt{n}", [group([path(pts, closed=False), stroke(WHITE, 4, 100)])],
              o=anim([(d0, [0], "out"), (d0 + 1, [100], "linear"), (d0 + 3, [100], "in"), (d0 + 5, [0], "linear")], 1), ip=d0, op=d0 + 6)
    c.write()


def bat_swarm():
    """Nine bats wheeling around the centre for a second and a half, flapping."""
    frames = 48
    c = Comp("bat-swarm", frames)

    def bat(up):
        w = -18 if up else 14
        return [(-34, w), (-14, -4), (-6, -12), (0, -6), (6, -12), (14, -4), (34, w), (18, 8), (8, 6), (0, 12), (-8, 6), (-18, 8)]

    for n in range(9):
        a0 = n * 40
        rx, ry = random.uniform(120, 190), random.uniform(60, 110)
        speed = random.choice((-1, 1)) * random.uniform(5, 8)
        keys, flap = [], []
        for f in range(0, frames + 1, 3):
            a = math.radians(a0 + f * speed)
            keys.append((f, [C + math.cos(a) * rx, C + math.sin(a) * ry - 20, 0], "linear"))
        for f in range(0, frames + 1, 3):
            flap.append((f, bat(up=(f // 3) % 2 == 0), "inout"))
        c.add(f"bat{n}", [group([path(None, keys=flap), fill(INK)])],
              p=anim(keys, 3),
              s=anim([(0, [0, 0, 100], "out"), (6, [random.uniform(70, 100)] * 2 + [100], "linear"), (frames - 8, [90, 90, 100], "in"), (frames - 1, [0, 0, 100], "linear")], 3),
              o=anim([(0, [0], "out"), (4, [100], "linear"), (frames - 8, [100], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def supernova():
    """The big one: a white core, a twenty-ray star that spins as it grows, three violet
    rings, and a gold flash. About a second, and it wants to be scaled to the whole tank."""
    frames = 30
    c = Comp("supernova", frames)
    c.add("core", [group([ellipse(160), soft_fill(WHITE, 160, 0.45)])],
          s=anim([(0, [10, 10, 100], "out"), (6, [120, 120, 100], "inout"), (frames - 1, [200, 200, 100], "linear")], 3),
          o=anim([(0, [100], "linear"), (8, [100], "out"), (frames - 1, [0], "linear")], 1))
    c.add("rays", [group([star(20, 190, 60), fill(GOLD, 85)])],
          s=anim([(0, [5, 5, 100], "out"), (8, [110, 110, 100], "inout"), (frames - 1, [170, 170, 100], "linear")], 3),
          r=anim([(0, [0], "linear"), (frames - 1, [70], "linear")], 1),
          o=anim([(0, [100], "linear"), (10, [100], "out"), (frames - 1, [0], "linear")], 1))
    for n in range(3):
        d0 = n * 3
        c.add(f"ring{n}", [group([ellipse(200), stroke(VIOLET, [(d0, [14], "out"), (frames - 1, [2], "linear")], [(d0, [90], "out"), (frames - 1, [0], "linear")])])],
              s=anim([(d0, [10, 10, 100], "out"), (frames - 1, [230 - n * 30, 230 - n * 30, 100], "linear")], 3), ip=d0)
    c.add("wash", [group([ellipse(400), soft_fill(GOLD, 400, 0.2)])],
          s=anim([(0, [20, 20, 100], "out"), (8, [120, 120, 100], "linear"), (frames - 1, [150, 150, 100], "linear")], 3),
          o=anim([(0, [80], "linear"), (6, [80], "out"), (frames - 1, [0], "linear")], 1))
    c.write()


def exhaust():
    """Engine or rocket exhaust: grey puffs pushed down and out from the centre with a hot
    orange core at the start. Below him for a rocket, behind him for a bike."""
    frames = 20
    c = Comp("exhaust", frames)
    for n in range(7):
        a = math.radians(90 + random.uniform(-28, 28))
        far = random.uniform(80, 130)
        d = random.uniform(50, 80)
        d0 = random.randint(0, 5)
        c.add(f"puff{n}", [group([ellipse(d), soft_fill(GREY, d, 0.35)])],
              p=anim([(d0, [C, C, 0], "out"), (d0 + 12, [C + math.cos(a) * far, C + math.sin(a) * far, 0], "linear")], 3),
              s=anim([(d0, [30, 30, 100], "out"), (d0 + 8, [100, 100, 100], "linear"), (d0 + 12, [125, 125, 100], "linear")], 3),
              o=anim([(d0, [80], "linear"), (d0 + 5, [80], "in"), (d0 + 12, [0], "linear")], 1), ip=d0, op=d0 + 13)
    c.add("core", [group([ellipse(70, 110), soft_fill((1.0, 0.62, 0.25), 90, 0.3)])],
          p=anim([(0, [C, C + 30, 0], "out"), (6, [C, C + 70, 0], "linear")], 3),
          s=anim([(0, [40, 40, 100], "out"), (3, [110, 110, 100], "linear"), (6, [60, 60, 100], "linear")], 3),
          o=anim([(0, [100], "linear"), (3, [100], "in"), (6, [0], "linear")], 1), op=7)
    c.write()


def sparks():
    """Orange sparks thrown to one side and falling: a tyre on the floor, a grinder."""
    frames = 18
    c = Comp("sparks", frames)
    for n in range(12):
        a = math.radians(-40 + random.uniform(-45, 45))
        v = random.uniform(120, 220)
        d0 = random.randint(0, 4)
        keys = []
        for f in range(0, 15, 3):
            t = f / 30
            keys.append((d0 + f, [C + math.cos(a) * v * t, C + math.sin(a) * v * t + 320 * t * t, 0], "linear"))
        c.add(f"spark{n}", [group([path([(0, 0), (-14, 3)], closed=False), stroke((1.0, 0.7, 0.25), 4, 100)])],
              p=anim(keys, 3), r=still(-math.degrees(a)),
              o=anim([(d0, [100], "linear"), (d0 + 8, [100], "in"), (d0 + 14, [0], "linear")], 1), ip=d0, op=d0 + 15)
    c.write()


def roar_lines():
    """A roar: twelve short lines shoved outward from the mouth, white with a green tint."""
    frames = 12
    c = Comp("roar-lines", frames)
    for n in range(12):
        a = math.radians(n * 30 + 15)
        ln = random.uniform(40, 70)
        c.add(f"line{n}", [group([path([(60, 0), (60 + ln, 0)], closed=False), stroke((0.9, 1.0, 0.9), 7, 90)])],
              r=still(math.degrees(a)),
              s=anim([(0, [40, 40, 100], "out"), (4, [110, 110, 100], "linear"), (frames - 1, [150, 150, 100], "linear")], 3),
              o=anim([(0, [0], "out"), (1, [90], "linear"), (6, [90], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def shockwave():
    """A stomp: a fat white ring seen at an angle that snaps outward, and six pebbles that hop."""
    frames = 16
    c = Comp("shockwave", frames)
    c.add("ring", [group([ellipse(200, 70), stroke(WHITE, [(0, [14], "out"), (frames - 1, [2], "linear")], [(0, [90], "out"), (frames - 1, [0], "linear")])])],
          s=anim([(0, [15, 15, 100], "out"), (frames - 1, [150, 150, 100], "linear")], 3))
    for n in range(6):
        a = math.radians(n * 60 + random.uniform(-15, 15))
        far = random.uniform(70, 120)
        c.add(f"pebble{n}", [group([ellipse(10), fill(GREY)])],
              p=anim([(0, [C, C, 0], "out"), (6, [C + math.cos(a) * far, C + math.sin(a) * far * 0.35 - 40, 0], "in"),
                      (12, [C + math.cos(a) * far * 1.2, C + math.sin(a) * far * 0.35 + 10, 0], "linear")], 3),
              o=anim([(0, [100], "linear"), (10, [100], "in"), (12, [0], "linear")], 1), op=13)
    c.write()


def notes():
    """Music notes rising and wobbling out of the centre, black with a white edge so they
    read on any tank."""
    frames = 36
    c = Comp("notes", frames)
    note = [(-2, 0), (-2, -46), (14, -40), (14, -30), (2, -36), (2, 0)]
    for n in range(7):
        d0 = n * 4
        x = C + random.uniform(-40, 40)
        drift = random.uniform(-30, 30)
        c.add(f"note{n}", [group([ellipse(22, 16)], tr=transform(p=(-8, 0))), group([path(note), fill(INK)]), group([ellipse(22, 16), fill(INK)], tr=transform(p=(-8, 0)))],
              p=anim([(d0, [x, C + 20, 0], "out"), (d0 + 10, [x + drift, C - 60, 0], "inout"), (d0 + 20, [x + drift * 1.6, C - 130, 0], "linear")], 3),
              r=anim([(d0, [-10], "inout"), (d0 + 10, [12], "inout"), (d0 + 20, [-8], "linear")], 1),
              s=anim([(d0, [40, 40, 100], "out"), (d0 + 4, [100, 100, 100], "linear"), (d0 + 20, [90, 90, 100], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 2, [100], "linear"), (d0 + 15, [100], "in"), (d0 + 20, [0], "linear")], 1),
              ip=d0, op=d0 + 21)
    c.write()


def lantern():
    """One paper lantern drifting up and away, glowing, swaying."""
    frames = 54
    c = Comp("lantern", frames)
    body = [group([rect(46, 60, 14), fill((0.98, 0.55, 0.28))]), group([rect(46, 6, 2), fill((0.55, 0.22, 0.1))], tr=transform(p=(0, -30))),
            group([rect(46, 6, 2), fill((0.55, 0.22, 0.1))], tr=transform(p=(0, 30))), group([path([(0, 34), (0, 52)], closed=False), stroke((0.55, 0.22, 0.1), 3)]),
            group([ellipse(14, 14), fill((1.0, 0.85, 0.5), 70)], tr=transform(p=(0, -8)))]
    # The whole rise stays inside the comp and the fade finishes before the top edge, or the
    # canvas clips the lantern while it is still lit — George saw exactly that.
    c.add("glow", [group([ellipse(110), soft_fill((1.0, 0.7, 0.35), 110, 0.15)])],
          p=anim([(0, [C, C + 60, 0], "out"), (frames - 1, [C + 24, C - 110, 0], "linear")], 3),
          o=anim([(0, [0], "out"), (6, [70], "linear"), (frames - 18, [70], "in"), (frames - 6, [0], "linear")], 1))
    c.add("lantern", body,
          p=anim([(0, [C, C + 60, 0], "out"), (frames - 1, [C + 24, C - 110, 0], "linear")], 3),
          r=anim([(0, [-6], "inout"), (18, [6], "inout"), (36, [-5], "inout"), (frames - 1, [4], "linear")], 1),
          s=anim([(0, [30, 30, 100], "out"), (8, [100, 100, 100], "linear"), (frames - 1, [72, 72, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (4, [100], "linear"), (frames - 18, [100], "in"), (frames - 6, [0], "linear")], 1))
    c.write()


def firework():
    """A firework: a rising streak, then a spherical burst of thirty dots in one hue that
    fall and fade, with a flash at the centre. The hue is picked per file build."""
    frames = 40
    c = Comp("firework", frames)
    hue = random.choice([(1.0, 0.45, 0.4), (0.98, 0.8, 0.3), (0.5, 0.85, 1.0), (0.9, 0.5, 0.95), (0.5, 0.95, 0.6)])
    burst_f = 12
    for n in range(30):
        a = math.radians(n * 12 + random.uniform(-4, 4))
        far = random.uniform(120, 175)
        keys = []
        for f in range(0, 27, 3):
            t = f / 30
            keys.append((burst_f + f, [C + math.cos(a) * far * (1 - math.exp(-t * 4)), C - 80 + math.sin(a) * far * (1 - math.exp(-t * 4)) + 90 * t * t, 0], "linear"))
        c.add(f"dot{n}", [group([ellipse(9), fill(hue)])],
              p=anim(keys, 3),
              s=anim([(burst_f, [110, 110, 100], "linear"), (frames - 1, [0, 0, 100], "linear")], 3),
              o=anim([(burst_f, [100], "linear"), (burst_f + 18, [100], "in"), (frames - 1, [0], "linear")], 1), ip=burst_f)
    c.add("flash", [group([ellipse(140), soft_fill(WHITE, 140, 0.3)])],
          p=still([C, C - 80, 0]),
          s=anim([(burst_f, [10, 10, 100], "out"), (burst_f + 4, [120, 120, 100], "linear"), (burst_f + 12, [140, 140, 100], "linear")], 3),
          o=anim([(burst_f, [100], "linear"), (burst_f + 3, [100], "out"), (burst_f + 12, [0], "linear")], 1), ip=burst_f, op=burst_f + 13)
    c.add("streak", [group([ellipse(10), fill(WHITE)])],
          p=anim([(0, [C, C + 190, 0], "out"), (burst_f, [C, C - 80, 0], "linear")], 3),
          o=anim([(0, [100], "linear"), (burst_f - 1, [100], "linear"), (burst_f, [0], "linear")], 1), op=burst_f + 1)
    c.write()


def petals():
    """Pink petals fluttering down across the whole comp, each turning as it falls."""
    frames = 60
    c = Comp("petals", frames)
    petal = [(0, -14), (10, -4), (8, 10), (0, 14), (-8, 10), (-10, -4)]
    for n in range(16):
        x0 = random.uniform(-20, SIZE + 20)
        d0 = random.randint(0, 24)
        col = ((1.0, 0.72, 0.8), (0.98, 0.6, 0.72), (1.0, 0.85, 0.9))[n % 3]
        keys = []
        for f in range(0, 37, 4):
            t = f / 30
            keys.append((d0 + f, [x0 + math.sin(t * 5 + n) * 26 - 30 * t, -30 + 380 * t, 0], "linear"))
        c.add(f"petal{n}", [group([path(petal), fill(col)])],
              p=anim(keys, 3),
              r=anim([(d0, [random.uniform(0, 360)], "linear"), (d0 + 36, [random.uniform(0, 360) + 300], "linear")], 1),
              s=anim([(d0, [100, 100, 100], "inout"), (d0 + 9, [40, 100, 100], "inout"), (d0 + 18, [100, 100, 100], "inout"), (d0 + 27, [40, 100, 100], "inout"), (d0 + 36, [100, 100, 100], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 3, [100], "linear"), (d0 + 30, [100], "in"), (d0 + 36, [0], "linear")], 1),
              ip=d0, op=d0 + 37)
    c.write()


def ribbons():
    """Three long ribbons whipping around the centre in a spiral, each a thick coloured
    stroke that draws on and trails off."""
    frames = 40
    c = Comp("ribbons", frames)
    cols = ((1.0, 0.45, 0.5), (0.35, 0.7, 0.95), (0.98, 0.8, 0.3))
    for n in range(3):
        pts = []
        for i in range(20):
            a = math.radians(i * 30 + n * 120)
            r = 50 + i * 4
            pts.append((math.cos(a) * r, math.sin(a) * r * 0.7 - i * 2))
        c.add(f"ribbon{n}", [group([path(pts, closed=False), stroke(cols[n], 6, 95)])],
              r=anim([(0, [0], "linear"), (frames - 1, [220], "linear")], 1),
              s=anim([(0, [20, 20, 100], "out"), (12, [100, 100, 100], "linear"), (frames - 1, [110, 110, 100], "linear")], 3),
              o=anim([(0, [0], "out"), (4, [95], "linear"), (frames - 12, [95], "in"), (frames - 1, [0], "linear")], 1), ip=n * 3)
    c.write()


def checkered_flag():
    """A chequered flag on a pole, waving. The cloth is a 6x3 grid of cells that each morph
    with the ripple, so the checks wave WITH the cloth instead of sitting still on top of it."""
    frames = 40
    c = Comp("checkered-flag", frames)
    cols, rows = 6, 3
    cw, ch = 20, 24

    def corner(i, r, phase):
        return (i * cw, -92 + r * ch + math.sin(i * 1.1 + phase) * 7 * (r * 0.4 + 0.6))

    def cell(i, r, phase):
        return [corner(i, r, phase), corner(i + 1, r, phase), corner(i + 1, r + 1, phase), corner(i, r + 1, phase)]

    pos = anim([(0, [C - 60, C + 40, 0], "out"), (6, [C - 60, C - 10, 0], "linear"), (frames - 1, [C - 60, C - 10, 0], "linear")], 3)
    fade = anim([(0, [0], "out"), (3, [100], "linear"), (frames - 8, [100], "in"), (frames - 1, [0], "linear")], 1)
    cells = []
    for r in range(rows):
        for i in range(cols):
            keys = [(f, cell(i, r, f * 0.45), "inout") for f in range(0, frames + 1, 4)]
            cells.append(group([path(None, keys=keys), fill(INK if (r + i) % 2 == 0 else WHITE)]))
    c.add("cloth", cells, p=pos, o=fade)
    c.add("pole", [group([path([(0, -100), (0, 120)], closed=False), stroke((0.35, 0.3, 0.28), 6)]), group([ellipse(12), fill((0.85, 0.7, 0.3))], tr=transform(p=(0, -104)))],
          p=pos, o=fade)
    c.write()


def podium():
    """A three-step winners' podium rising up from below the tank floor: the tall middle
    block with a gold plate, silver left, bronze right. Drawn behind him; the top step's
    surface sits 60 comp units above the centre, which the act uses to land him on it."""
    frames = 60
    c = Comp("podium", frames)
    STONE = (0.86, 0.88, 0.9)
    EDGE = (0.62, 0.66, 0.72)
    steps = ((-110, 60, (0.78, 0.8, 0.84)), (0, 120, (0.98, 0.8, 0.3)), (110, 40, (0.8, 0.55, 0.35)))
    parts = []
    for x, h, plate in steps:
        parts.append(group([rect(104, h), fill(STONE)], tr=transform(p=(x, C + 60 - h / 2 - C))))
        parts.append(group([rect(104, 10), fill(EDGE)], tr=transform(p=(x, 60 - h + 5))))
        parts.append(group([rect(44, 22, 4), fill(plate)], tr=transform(p=(x, 60 - h + 30))))
    c.add("blocks", parts,
          p=anim([(0, [C, C + 190, 0], "out"), (14, [C, C - 8, 0], "linear"), (20, [C, C, 0], "linear"), (frames - 1, [C, C, 0], "linear")], 3),
          o=anim([(0, [100], "linear"), (frames - 6, [100], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def trophy():
    """A gold cup that drops in from above, lands with a bounce and a shine, and holds."""
    frames = 66
    c = Comp("trophy", frames)
    GOLD2 = (0.85, 0.62, 0.15)
    cup = [group([path([(-40, -70), (40, -70), (30, -10), (-30, -10)]), fill(GOLD)]),
           group([ellipse(84, 20), fill(GOLD2)], tr=transform(p=(0, -70))),
           group([rect(14, 24), fill(GOLD2)], tr=transform(p=(0, 2))),
           group([rect(60, 12, 3), fill(GOLD2)], tr=transform(p=(0, 20))),
           group([rect(76, 10, 3), fill((0.35, 0.22, 0.12))], tr=transform(p=(0, 30))),
           group([path([(-40, -60), (-62, -52), (-58, -22), (-34, -18)], closed=False), stroke(GOLD, 8)]),
           group([path([(40, -60), (62, -52), (58, -22), (34, -18)], closed=False), stroke(GOLD, 8)]),
           group([path([(-16, -56), (-10, -20)], closed=False), stroke(WHITE, 6, 55)])]
    c.add("cup", cup,
          p=anim([(0, [C, C - 260, 0], "in"), (12, [C, C + 6, 0], "out"), (17, [C, C - 12, 0], "in"), (22, [C, C, 0], "linear"), (frames - 1, [C, C, 0], "linear")], 3),
          s=anim([(0, [60, 60, 100], "in"), (12, [110, 92, 100], "out"), (17, [96, 104, 100], "inout"), (22, [100, 100, 100], "linear"), (frames - 1, [100, 100, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (3, [100], "linear"), (frames - 6, [100], "in"), (frames - 1, [0], "linear")], 1))
    for n in range(6):
        a = math.radians(n * 60 + 20)
        d0 = 13 + n * 2
        c.add(f"shine{n}", [group([star(4, 16, 6), fill(WHITE)])],
              p=anim([(d0, [C + math.cos(a) * 50, C - 40 + math.sin(a) * 40, 0], "out"), (d0 + 10, [C + math.cos(a) * 90, C - 40 + math.sin(a) * 70, 0], "linear")], 3),
              s=anim([(d0, [20, 20, 100], "out"), (d0 + 4, [100, 100, 100], "in"), (d0 + 10, [0, 0, 100], "linear")], 3),
              r=anim([(d0, [0], "linear"), (d0 + 10, [90], "linear")], 1), ip=d0, op=d0 + 11)
    c.add("glow", [group([ellipse(200), soft_fill(GOLD, 200, 0.1)])],
          p=still([C, C - 30, 0]),
          s=anim([(12, [30, 30, 100], "out"), (20, [110, 110, 100], "inout"), (40, [95, 95, 100], "inout"), (frames - 1, [80, 80, 100], "in")], 3),
          o=anim([(12, [0], "out"), (18, [60], "linear"), (frames - 8, [60], "in"), (frames - 1, [0], "linear")], 1), ip=12)
    c.write()


def start_lights():
    """Race start: a bar of five lights that go red one by one, then all green."""
    frames = 54
    c = Comp("start-lights", frames)
    c.add("bar", [group([rect(300, 70, 16), fill((0.15, 0.16, 0.2))])],
          p=still([C, C - 60, 0]),
          o=anim([(0, [0], "out"), (4, [100], "linear"), (frames - 8, [100], "in"), (frames - 1, [0], "linear")], 1))
    for n in range(5):
        on = 8 + n * 7
        c.add(f"light{n}", [group([ellipse(40), fill((0.95, 0.2, 0.2))])],
              p=still([C - 120 + n * 60, C - 60, 0]),
              o=anim([(0, [0], "out"), (4, [25], "linear"), (on - 1, [25], "linear"), (on, [100], "linear"), (42, [100], "linear"), (43, [0], "linear"), (frames - 1, [0], "linear")], 1))
        c.add(f"green{n}", [group([ellipse(40), fill((0.3, 0.95, 0.4))])],
              p=still([C - 120 + n * 60, C - 60, 0]),
              o=anim([(0, [0], "linear"), (42, [0], "linear"), (43, [100], "linear"), (frames - 8, [100], "in"), (frames - 1, [0], "linear")], 1), ip=42)
    c.add("greenflash", [group([ellipse(360, 160), soft_fill((0.3, 0.95, 0.4), 360, 0.2)])],
          p=still([C, C - 60, 0]),
          o=anim([(43, [0], "out"), (45, [70], "linear"), (frames - 1, [0], "linear")], 1), ip=43)
    c.write()


def steam():
    """Three soft white wisps rising and thinning out of a cup."""
    frames = 36
    c = Comp("steam", frames)
    for n in range(3):
        d0 = n * 6
        x = C + (n - 1) * 22
        c.add(f"wisp{n}", [group([ellipse(34, 52), soft_fill(WHITE, 44, 0.25)])],
              p=anim([(d0, [x, C + 10, 0], "out"), (d0 + 12, [x + (n - 1) * 14, C - 50, 0], "inout"), (d0 + 24, [x - (n - 1) * 10, C - 120, 0], "linear")], 3),
              s=anim([(d0, [40, 40, 100], "out"), (d0 + 10, [100, 100, 100], "linear"), (d0 + 24, [150, 130, 100], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 3, [70], "linear"), (d0 + 14, [70], "in"), (d0 + 24, [0], "linear")], 1),
              ip=d0, op=d0 + 25)
    c.write()


def motorbike():
    """The biker's bike, drawn behind him for the ult: rolls in from the left over 0.4s,
    idles with a bob for 1.6s, then tears off to the right. Wheels turn; the exhaust puffs
    on the way out. Mirrored by the act to match which way he faces."""
    frames = 78
    c = Comp("motorbike", frames)
    IN, OUT_ = 12, 60
    CHROME = (0.78, 0.8, 0.84)
    FRAME = (0.16, 0.17, 0.2)
    TYRE = (0.1, 0.1, 0.12)
    RED = (0.6, 0.15, 0.15)

    def ride(base_x):
        # Position track shared by every part: in, bob, out.
        keys = [(0, [C + base_x - 380, C + 70, 0], "out"), (IN, [C + base_x, C + 70, 0], "linear")]
        for f in range(IN + 6, OUT_, 6):
            keys.append((f, [C + base_x, C + 70 + (3 if (f // 6) % 2 else -3), 0], "inout"))
        keys.append((OUT_, [C + base_x, C + 70, 0], "in"))
        keys.append((frames - 1, [C + base_x + 620, C + 60, 0], "linear"))
        return anim(keys, 3)

    spin = anim([(0, [0], "linear"), (IN, [520], "linear"), (OUT_, [700], "linear"), (frames - 1, [1900], "linear")], 1)
    for n, x in enumerate((-125, 125)):
        c.add(f"wheel{n}", [group([ellipse(92), fill(TYRE)]), group([ellipse(64), stroke(CHROME, 6)]),
                            group([star(8, 30, 6), fill(CHROME)]), group([ellipse(14), fill(FRAME)])],
              p=ride(x), r=spin)
    body = [
        group([path([(-125, 0), (-70, -50), (20, -60), (90, -48), (125, 0)], closed=False), stroke(FRAME, 14)]),
        group([path([(-90, -40), (-30, -40), (-20, -10), (-100, -10)]), fill(FRAME)]),          # rear fender / seat
        group([path([(-40, -62), (40, -66), (60, -44), (-30, -44)]), fill(RED)]),               # tank
        group([path([(-60, -70), (-10, -74), (-10, -62), (-60, -60)]), fill(FRAME)]),           # seat
        group([path([(70, -52), (110, -96), (118, -90)], closed=False), stroke(CHROME, 8)]),     # fork / bars
        group([path([(96, -96), (150, -104)], closed=False), stroke(CHROME, 8)]),               # handlebar
        group([path([(-20, -8), (-110, 8)], closed=False), stroke(CHROME, 12)]),                # exhaust pipe
        group([ellipse(64, 20), fill(CHROME)], tr=transform(p=(-110, 8))),                      # muffler
        group([ellipse(22), fill((1.0, 0.9, 0.6))], tr=transform(p=(128, -60))),                # headlamp
    ]
    c.add("body", body, p=ride(0))
    for n in range(4):
        d0 = OUT_ - 2 + n * 3
        c.add(f"puff{n}", [group([ellipse(46), soft_fill(GREY, 46, 0.35)])],
              p=anim([(d0, [C - 120, C + 82, 0], "out"), (d0 + 12, [C - 210 - n * 20, C + 60, 0], "linear")], 3),
              s=anim([(d0, [30, 30, 100], "out"), (d0 + 12, [130, 130, 100], "linear")], 3),
              o=anim([(d0, [80], "linear"), (d0 + 4, [80], "in"), (d0 + 12, [0], "linear")], 1), ip=d0, op=d0 + 13)
    c.write()


HUES = {
    "gold": (0.98, 0.8, 0.3), "violet": (0.66, 0.5, 0.95), "green": (0.5, 0.92, 0.45),
    "red": (0.98, 0.42, 0.38), "blue": (0.45, 0.72, 1.0), "pink": (0.98, 0.55, 0.78),
    "teal": (0.3, 0.9, 0.85), "cyan": (0.35, 0.9, 1.0),
}
TEAL = HUES["teal"]
CYAN = HUES["cyan"]
MAGENTA = (1.0, 0.35, 0.85)


def charge(hue):
    """The ult's wind-up, behind him: a ground ring that pulses twice while motes stream up
    into him, in the costume's hue. About 1.4s."""
    frames = 42
    col = HUES[hue]
    c = Comp(f"charge-{hue}", frames)
    for n in range(10):
        d0 = random.randint(0, 20)
        x = C + random.uniform(-120, 120)
        c.add(f"mote{n}", [group([ellipse(14), soft_fill(col, 14, 0.4)])],
              p=anim([(d0, [x, C + 60, 0], "out"), (d0 + 16, [C + (x - C) * 0.2, C - 120, 0], "linear")], 3),
              s=anim([(d0, [60, 60, 100], "out"), (d0 + 8, [110, 110, 100], "linear"), (d0 + 16, [0, 0, 100], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 3, [100], "linear"), (d0 + 12, [100], "in"), (d0 + 16, [0], "linear")], 1),
              ip=d0, op=d0 + 17)
    c.add("ring", [group([ellipse(300, 96), stroke(col, 8, 90)])],
          s=anim([(0, [30, 30, 100], "out"), (10, [100, 100, 100], "inout"), (20, [88, 88, 100], "inout"), (30, [104, 104, 100], "inout"), (frames - 1, [40, 40, 100], "in")], 3),
          o=anim([(0, [0], "out"), (6, [90], "linear"), (30, [90], "in"), (frames - 1, [0], "linear")], 1))
    c.add("glow", [group([ellipse(320, 120), soft_fill(col, 320, 0.1)])],
          s=anim([(0, [40, 40, 100], "out"), (10, [100, 100, 100], "inout"), (20, [80, 80, 100], "inout"), (30, [110, 110, 100], "inout"), (frames - 1, [50, 50, 100], "in")], 3),
          o=anim([(0, [0], "out"), (6, [70], "linear"), (30, [70], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def finale(hue):
    """The ult's payoff: a screen-filling burst in the costume's hue — a white core, twelve
    long rays that sweep round, three rings, and a wash. Scaled to the whole tank."""
    frames = 34
    col = HUES[hue]
    c = Comp(f"finale-{hue}", frames)
    c.add("core", [group([ellipse(150), soft_fill(WHITE, 150, 0.45)])],
          s=anim([(0, [10, 10, 100], "out"), (5, [110, 110, 100], "inout"), (frames - 1, [170, 170, 100], "linear")], 3),
          o=anim([(0, [100], "linear"), (7, [100], "out"), (frames - 1, [0], "linear")], 1))
    c.add("rays", [group([star(12, 210, 40), fill(col, 80)])],
          s=anim([(0, [5, 5, 100], "out"), (8, [110, 110, 100], "inout"), (frames - 1, [190, 190, 100], "linear")], 3),
          r=anim([(0, [0], "linear"), (frames - 1, [60], "linear")], 1),
          o=anim([(0, [100], "linear"), (10, [100], "out"), (frames - 1, [0], "linear")], 1))
    for n in range(3):
        d0 = n * 3
        c.add(f"ring{n}", [group([ellipse(200), stroke(col, [(d0, [16], "out"), (frames - 1, [2], "linear")], [(d0, [95], "out"), (frames - 1, [0], "linear")])])],
              s=anim([(d0, [10, 10, 100], "out"), (frames - 1, [240 - n * 30, 240 - n * 30, 100], "linear")], 3), ip=d0)
    c.add("wash", [group([ellipse(420), soft_fill(col, 420, 0.2)])],
          s=anim([(0, [20, 20, 100], "out"), (8, [120, 120, 100], "linear"), (frames - 1, [150, 150, 100], "linear")], 3),
          o=anim([(0, [85], "linear"), (6, [85], "out"), (frames - 1, [0], "linear")], 1))
    c.write()


def sparkler():
    """A senko hanabi: a bright bead that crackles for 1.6s, throwing tiny sparks in every
    direction in bursts, then dims out."""
    frames = 54
    c = Comp("sparkler", frames)
    for n in range(48):
        d0 = random.randint(0, 40)
        a = math.radians(random.uniform(0, 360))
        ln = random.uniform(18, 46)
        c.add(f"spark{n}", [group([path([(6, 0), (6 + ln, 0)], closed=False), stroke((1.0, 0.86, 0.45), random.uniform(2, 4), 100)])],
              r=still(math.degrees(a)),
              s=anim([(d0, [20, 100, 100], "out"), (d0 + 3, [100, 100, 100], "linear"), (d0 + 7, [130, 100, 100], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 1, [100], "linear"), (d0 + 4, [100], "in"), (d0 + 7, [0], "linear")], 1),
              ip=d0, op=d0 + 8)
    c.add("bead", [group([ellipse(22), soft_fill(WHITE, 22, 0.5)]), group([ellipse(10), fill((1.0, 0.9, 0.6))])],
          s=anim([(0, [40, 40, 100], "out"), (4, [100, 100, 100], "linear"), (44, [100, 100, 100], "in"), (frames - 1, [0, 0, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (3, [100], "linear"), (44, [100], "in"), (frames - 1, [0], "linear")], 1))
    c.add("glow", [group([ellipse(120), soft_fill((1.0, 0.75, 0.4), 120, 0.1)])],
          s=anim([(0, [30, 30, 100], "out"), (6, [100, 100, 100], "inout"), (20, [85, 85, 100], "inout"), (34, [105, 105, 100], "inout"), (frames - 1, [40, 40, 100], "in")], 3),
          o=anim([(0, [0], "out"), (6, [60], "linear"), (44, [60], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def heart_pop():
    """A blown kiss: one big heart that pops from the centre and sails off to the right,
    turning, with two small ones trailing. Mirrored by the act to fly the way he faces."""
    frames = 30
    c = Comp("heart-pop", frames)
    heart = [(0, 14), (-30, -10), (-30, -26), (-18, -36), (-6, -32), (0, -22), (6, -32), (18, -36), (30, -26), (30, -10)]
    for n, (lag, sc, dy) in enumerate(((0, 100, 0), (4, 55, -30), (8, 45, 26))):
        c.add(f"heart{n}", [group([path(heart), fill((0.98, 0.45, 0.55))]), group([ellipse(10), fill(WHITE, 60)], tr=transform(p=(-12, -22)))],
              p=anim([(lag, [C, C, 0], "out"), (lag + 10, [C + 70, C - 30 + dy, 0], "inout"), (frames - 1, [C + 190, C - 70 + dy, 0], "linear")], 3),
              s=anim([(lag, [10, 10, 100], "back"), (lag + 6, [sc, sc, 100], "linear"), (frames - 1, [sc * 0.8, sc * 0.8, 100], "linear")], 3),
              r=anim([(lag, [-20], "inout"), (lag + 12, [12], "inout"), (frames - 1, [-8], "linear")], 1),
              o=anim([(lag, [0], "out"), (lag + 2, [100], "linear"), (frames - 8, [100], "in"), (frames - 1, [0], "linear")], 1), ip=lag)
    c.write()


def impact():
    """A punch landing: a white starburst that snaps out and is gone in a third of a second,
    with a ring and a few yellow flecks."""
    frames = 10
    c = Comp("impact", frames)
    c.add("burst", [group([star(8, 120, 45), fill(WHITE, 95)])],
          s=anim([(0, [15, 15, 100], "out"), (3, [110, 110, 100], "linear"), (frames - 1, [140, 140, 100], "linear")], 3),
          r=anim([(0, [-10], "linear"), (frames - 1, [12], "linear")], 1),
          o=anim([(0, [100], "linear"), (3, [100], "in"), (frames - 1, [0], "linear")], 1))
    c.add("ring", [group([ellipse(200), stroke((1.0, 0.9, 0.5), [(0, [12], "out"), (frames - 1, [1], "linear")], [(0, [90], "out"), (frames - 1, [0], "linear")])])],
          s=anim([(0, [10, 10, 100], "out"), (frames - 1, [140, 140, 100], "linear")], 3))
    for n in range(6):
        a = math.radians(n * 60 + 20)
        c.add(f"fleck{n}", [group([ellipse(12), fill((1.0, 0.85, 0.35))])],
              p=anim([(0, [C, C, 0], "out"), (frames - 1, [C + math.cos(a) * 150, C + math.sin(a) * 150, 0], "linear")], 3),
              s=anim([(0, [100, 100, 100], "linear"), (frames - 1, [0, 0, 100], "linear")], 3))
    c.write()


def ghost(name, col):
    """A Sprout-sized pear disc in one hue: the Netrunner's split. Snaps in beside him,
    jitters, slides a little further out, and is gone in 0.6s."""
    frames = 18
    c = Comp(name, frames)
    pear = [(0, -120), (60, -100), (95, -40), (100, 40), (80, 100), (0, 118), (-80, 100), (-100, 40), (-95, -40), (-60, -100)]
    keys = []
    for f in range(0, frames + 1, 2):
        j = random.uniform(-6, 6)
        keys.append((f, [C + j, C + random.uniform(-3, 3), 0], "linear"))
    c.add("body", [group([path(pear), fill(col, 40)]), group([path(pear), stroke(col, 5, 95)])],
          p=anim(keys, 3),
          s=anim([(0, [70, 70, 100], "out"), (3, [104, 104, 100], "linear"), (frames - 1, [112, 112, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (1, [100], "linear"), (10, [100], "in"), (frames - 1, [0], "linear")], 1))
    for n in range(4):
        y = C - 90 + n * 60
        c.add(f"scan{n}", [group([path([(-110, y - C), (110, y - C)], closed=False), stroke(col, 3, 70)])],
              o=anim([(n, [0], "out"), (n + 1, [70], "linear"), (n + 5, [70], "in"), (n + 8, [0], "linear")], 1), ip=n, op=n + 9)
    c.write()


def bubbles():
    """Plain air bubbles, white with a highlight, rising and wobbling. The neutral one — the
    brew bubbles are acid green."""
    frames = 36
    c = Comp("bubbles", frames)
    for n in range(9):
        x = C + random.uniform(-70, 70)
        d0 = random.randint(0, 14)
        d = random.uniform(12, 30)
        c.add(f"bubble{n}", [group([ellipse(d), stroke((0.9, 0.97, 1.0), 3, 85)]), group([ellipse(d * 0.3), fill(WHITE, 70)], tr=transform(p=(-d * 0.2, -d * 0.2)))],
              p=anim([(d0, [x, C + 50, 0], "out"), (d0 + 8, [x + random.uniform(-12, 12), C - 20, 0], "inout"), (d0 + 18, [x + random.uniform(-14, 14), C - 120, 0], "linear")], 3),
              s=anim([(d0, [30, 30, 100], "out"), (d0 + 6, [100, 100, 100], "linear"), (d0 + 17, [110, 110, 100], "linear"), (d0 + 18, [140, 140, 100], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 2, [100], "linear"), (d0 + 16, [100], "in"), (d0 + 18, [0], "linear")], 1),
              ip=d0, op=d0 + 19)
    c.write()


def lure_glow():
    """The anglerfish's lure in the dark: a teal orb that breathes for 2.6s, with a soft
    halo and a few motes drifting toward it."""
    frames = 78
    c = Comp("lure-glow", frames)
    for n in range(8):
        d0 = random.randint(0, 50)
        a = math.radians(random.uniform(0, 360))
        far = random.uniform(90, 150)
        c.add(f"mote{n}", [group([ellipse(10), soft_fill(TEAL, 10, 0.5)])],
              p=anim([(d0, [C + math.cos(a) * far, C + math.sin(a) * far, 0], "in"), (d0 + 20, [C + math.cos(a) * 12, C + math.sin(a) * 12, 0], "linear")], 3),
              o=anim([(d0, [0], "out"), (d0 + 4, [90], "linear"), (d0 + 16, [90], "in"), (d0 + 20, [0], "linear")], 1), ip=d0, op=d0 + 21)
    c.add("core", [group([ellipse(34), soft_fill(WHITE, 34, 0.5)])],
          s=anim([(0, [0, 0, 100], "out"), (6, [100, 100, 100], "inout"), (26, [88, 88, 100], "inout"), (46, [104, 104, 100], "inout"), (66, [92, 92, 100], "in"), (frames - 1, [0, 0, 100], "linear")], 3))
    c.add("halo", [group([ellipse(200), soft_fill(TEAL, 200, 0.12)])],
          s=anim([(0, [10, 10, 100], "out"), (8, [100, 100, 100], "inout"), (26, [82, 82, 100], "inout"), (46, [110, 110, 100], "inout"), (66, [90, 90, 100], "in"), (frames - 1, [10, 10, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (6, [80], "linear"), (66, [80], "in"), (frames - 1, [0], "linear")], 1))
    c.write()


def shockwave_teal():
    """The Abyss shockwave: a wide flat teal ring that rolls out to the glass, thinning."""
    frames = 24
    c = Comp("shockwave-teal", frames)
    for n, (d0, w) in enumerate(((0, 18), (4, 10))):
        c.add(f"ring{n}", [group([ellipse(200, 80), stroke(TEAL, [(d0, [w], "out"), (frames - 1, [1], "linear")], [(d0, [95], "out"), (frames - 1, [0], "linear")])])],
              s=anim([(d0, [8, 8, 100], "out"), (frames - 1, [190 - n * 30, 190 - n * 30, 100], "linear")], 3), ip=d0)
    c.add("glow", [group([ellipse(260, 110), soft_fill(TEAL, 260, 0.1)])],
          s=anim([(0, [10, 10, 100], "out"), (8, [120, 120, 100], "linear"), (frames - 1, [170, 170, 100], "linear")], 3),
          o=anim([(0, [80], "linear"), (5, [80], "out"), (frames - 1, [0], "linear")], 1))
    c.write()


def belt():
    """A championship belt held up: a wide leather strap with a big gold centre plate (star
    and red gem) and two side plates. Drops in from above, lands with a bounce, shines, holds."""
    frames = 66
    c = Comp("belt", frames)
    LEATHER = (0.16, 0.12, 0.12)
    GOLD2 = (0.85, 0.62, 0.15)
    RUBY = (0.85, 0.15, 0.2)
    parts = [
        group([rect(300, 46, 12), fill(LEATHER)]),
        group([rect(300, 10, 4), fill((0.28, 0.2, 0.2))], tr=transform(p=(0, -14))),
        group([ellipse(74, 60), fill(GOLD)], tr=transform(p=(-112, 0))),
        group([ellipse(74, 60), fill(GOLD)], tr=transform(p=(112, 0))),
        group([ellipse(52, 40), fill(GOLD2)], tr=transform(p=(-112, 0))),
        group([ellipse(52, 40), fill(GOLD2)], tr=transform(p=(112, 0))),
        group([ellipse(150, 118), fill(GOLD)]),
        group([ellipse(120, 92), stroke(GOLD2, 6)]),
        group([star(5, 34, 15), fill(GOLD2)], tr=transform(p=(0, -6))),
        group([ellipse(18), fill(RUBY)], tr=transform(p=(0, 30))),
        group([path([(-40, -34), (-10, -46)], closed=False), stroke(WHITE, 6, 60)]),
    ]
    # First shape in a layer draws on top, so the plates go before the strap.
    parts.reverse()
    c.add("belt", parts,
          p=anim([(0, [C, C - 260, 0], "in"), (12, [C, C + 6, 0], "out"), (17, [C, C - 10, 0], "in"), (22, [C, C, 0], "linear"), (frames - 1, [C, C, 0], "linear")], 3),
          s=anim([(0, [60, 60, 100], "in"), (12, [108, 94, 100], "out"), (17, [97, 103, 100], "inout"), (22, [100, 100, 100], "linear"), (frames - 1, [100, 100, 100], "linear")], 3),
          o=anim([(0, [0], "out"), (3, [100], "linear"), (frames - 6, [100], "in"), (frames - 1, [0], "linear")], 1))
    for n in range(6):
        a = math.radians(n * 60 + 20)
        d0 = 13 + n * 2
        c.add(f"shine{n}", [group([star(4, 16, 6), fill(WHITE)])],
              p=anim([(d0, [C + math.cos(a) * 90, C + math.sin(a) * 40, 0], "out"), (d0 + 10, [C + math.cos(a) * 150, C + math.sin(a) * 70, 0], "linear")], 3),
              s=anim([(d0, [20, 20, 100], "out"), (d0 + 4, [100, 100, 100], "in"), (d0 + 10, [0, 0, 100], "linear")], 3),
              r=anim([(d0, [0], "linear"), (d0 + 10, [90], "linear")], 1), ip=d0, op=d0 + 11)
    c.add("glow", [group([ellipse(260, 160), soft_fill(GOLD, 260, 0.1)])],
          s=anim([(12, [30, 30, 100], "out"), (20, [110, 110, 100], "inout"), (40, [95, 95, 100], "inout"), (frames - 1, [80, 80, 100], "in")], 3),
          o=anim([(12, [0], "out"), (18, [60], "linear"), (frames - 8, [60], "in"), (frames - 1, [0], "linear")], 1), ip=12)
    c.write()


def laser():
    """A visor laser: a beam from the comp centre to the right edge, white core, cyan body,
    magenta fringe. Draws on in three frames, holds half a second, thins out. Sparks at the
    far end. Mirrored by the act to fire the way he faces."""
    frames = 24
    c = Comp("laser", frames)
    # First call is on top: the hit and its sparks, then the core over the body over the fringe.
    for n in range(10):
        a = math.radians(random.uniform(-70, 70) + 180)
        far = random.uniform(40, 90)
        d0 = 3 + random.randint(0, 10)
        c.add(f"spark{n}", [group([ellipse(8), fill((1.0, 0.95, 0.8))])],
              p=anim([(d0, [C + 198, C, 0], "out"), (d0 + 8, [C + 198 + math.cos(a) * far, C + math.sin(a) * far, 0], "linear")], 3),
              s=anim([(d0, [100, 100, 100], "linear"), (d0 + 8, [0, 0, 100], "linear")], 3), ip=d0, op=d0 + 9)
    c.add("hit", [group([ellipse(90), soft_fill(WHITE, 90, 0.3)])],
          p=still([C + 198, C, 0]),
          s=anim([(2, [20, 20, 100], "out"), (5, [110, 110, 100], "inout"), (15, [90, 90, 100], "in"), (20, [0, 0, 100], "linear")], 3),
          o=anim([(2, [0], "out"), (4, [95], "linear"), (15, [95], "in"), (20, [0], "linear")], 1), ip=2, op=21)
    for name, col, h, op in (("core", WHITE, 7, 100), ("body", CYAN, 18, 90), ("fringe", MAGENTA, 34, 45)):
        c.add(name, [group([rect(200, h, h / 2), fill(col, op)], tr=transform(p=(100, 0)))],
              p=still([C, C, 0]),
              s=anim([(0, [0, 100, 100], "out"), (3, [100, 100, 100], "linear"), (15, [100, 100, 100], "in"), (19, [100, 0, 100], "linear")], 3), op=20)
    c.add("muzzle", [group([ellipse(60), soft_fill(CYAN, 60, 0.3)])],
          p=still([C, C, 0]),
          s=anim([(0, [30, 30, 100], "out"), (3, [110, 110, 100], "linear"), (15, [100, 100, 100], "in"), (20, [0, 0, 100], "linear")], 3), op=21)
    c.write()


ALL = {
    "slash": slash, "sparkle-burst": sparkle_burst, "arcane-ring": arcane_ring, "fizzle": fizzle,
    "confetti": confetti, "bats": bats, "hex-burst": hex_burst,
    "shuriken": shuriken, "speed-lines": speed_lines, "starfall": starfall, "comet": comet,
    "spotlights": spotlights, "camera-flash": camera_flash, "brew-bubbles": brew_bubbles,
    "lightning": lightning, "bat-swarm": bat_swarm, "supernova": supernova,
    "exhaust": exhaust, "sparks": sparks, "roar-lines": roar_lines, "shockwave": shockwave,
    "notes": notes, "lantern": lantern, "firework": firework, "petals": petals, "ribbons": ribbons,
    "checkered-flag": checkered_flag, "start-lights": start_lights, "steam": steam, "motorbike": motorbike,
    "sparkler": sparkler, "heart-pop": heart_pop, "podium": podium, "trophy": trophy,
    "impact": impact, "bubbles": bubbles, "lure-glow": lure_glow, "shockwave-teal": shockwave_teal,
    "ghost-cyan": lambda: ghost("ghost-cyan", CYAN), "ghost-magenta": lambda: ghost("ghost-magenta", MAGENTA),
    "belt": belt, "laser": laser,
}
for _hue in HUES:
    ALL[f"charge-{_hue}"] = (lambda h: lambda: charge(h))(_hue)
    ALL[f"finale-{_hue}"] = (lambda h: lambda: finale(h))(_hue)

if __name__ == "__main__":
    want = sys.argv[1:] or list(ALL)
    for name in want:
        ALL[name]()
