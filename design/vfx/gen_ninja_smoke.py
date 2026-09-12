"""Ninja smoke poof, written as a Lottie file.

One burst, 20 frames at 30fps in a 400x400 comp, centred: a pale flash ring, a charcoal
core puff, seven ink puffs that shove outward and thin, four light flecks that fly off
first. Every fill is a radial gradient that goes transparent at its own edge, so the
puffs stay soft without a blur effect — lottie-web cannot render layer effects, and the
plan is for this to look the same in Creator, dotlottie-web and lottie-web.

Writes design/vfx/ninja-smoke.json and copies it into the Sprout build's public/vfx so
`vite build` ships it. Open the JSON in LottieFiles Creator to polish by hand, then
export back over the same file.

    python3 design/vfx/gen_ninja_smoke.py
"""
import json, math, os, random, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "ninja-smoke.json")
SPROUT_PUBLIC = os.path.expanduser("~/Downloads/Sprout-handoff/public/vfx")

FPS = 30
FRAMES = 20
SIZE = 400
C = SIZE / 2

# Colours 0..1. Ink-dark body, mid-grey rim puffs, a pale fleck and flash.
CORE = (0.16, 0.18, 0.23)
PUFF = [(0.22, 0.25, 0.31), (0.29, 0.32, 0.39), (0.36, 0.40, 0.47)]
FLECK = (0.66, 0.70, 0.77)
FLASH = (0.90, 0.92, 0.95)

random.seed(7)


# --- easing ---------------------------------------------------------------------------
# A Lottie keyframe carries the OUT tangent of its own key and the IN tangent of the next.
def ease(name, dims):
    tangents = {
        "out": ((0.10, 0.80), (0.35, 1.00)),
        "in": ((0.55, 0.00), (0.90, 0.60)),
        "inout": ((0.42, 0.00), (0.58, 1.00)),
        "linear": ((0.33, 0.33), (0.67, 0.67)),
    }[name]
    (ox, oy), (ix, iy) = tangents
    return {"o": {"x": [ox] * dims, "y": [oy] * dims}, "i": {"x": [ix] * dims, "y": [iy] * dims}}


def anim(keys, dims):
    """keys: list of (frame, value_list, ease_name_for_segment_after)."""
    out = []
    for n, (t, v, e) in enumerate(keys):
        k = {"t": t, "s": list(v)}
        if n < len(keys) - 1:
            k.update(ease(e, dims))
        out.append(k)
    return {"a": 1, "k": out}


def still(v):
    return {"a": 0, "k": v}


# --- shapes ---------------------------------------------------------------------------
def ellipse(d):
    return {"ty": "el", "p": still([0, 0]), "s": still([d, d]), "d": 1, "nm": "e"}


def soft_fill(rgb, d, solid_to=0.55):
    """Radial gradient: the colour holds to `solid_to` of the radius, then fades out."""
    r, g, b = rgb
    stops = [0, r, g, b, solid_to, r, g, b, 1, r, g, b, 0, 1, solid_to, 0.92, 1, 0]
    return {
        "ty": "gf", "o": still(100), "r": 1, "bm": 0,
        "g": {"p": 3, "k": still(stops)},
        "s": still([0, 0]), "e": still([d / 2, 0]), "t": 2,
        "h": still(0), "a": still(0), "nm": "gf",
    }


def stroke(rgb, width_keys, opacity_keys):
    r, g, b = rgb
    return {
        "ty": "st", "c": still([r, g, b, 1]),
        "o": anim(opacity_keys, 1), "w": anim(width_keys, 1),
        "lc": 2, "lj": 2, "nm": "st",
    }


def transform():
    return {
        "ty": "tr", "p": still([0, 0]), "a": still([0, 0]), "s": still([100, 100]),
        "r": still(0), "o": still(100), "sk": still(0), "sa": still(0), "nm": "tr",
    }


def group(items, name):
    return {"ty": "gr", "it": items + [transform()], "nm": name, "np": len(items) + 1,
            "cix": 2, "bm": 0, "ix": 1, "hd": False}


def layer(ind, name, shapes, p, s, o):
    return {
        "ddd": 0, "ind": ind, "ty": 4, "nm": name, "sr": 1,
        "ks": {"o": o, "r": still(0), "p": p, "a": still([0, 0, 0]), "s": s},
        "ao": 0, "shapes": shapes, "ip": 0, "op": FRAMES, "st": 0, "bm": 0,
    }


layers = []
ind = 1


def add(name, shapes, p, s, o):
    global ind
    layers.append(layer(ind, name, shapes, p, s, o))
    ind += 1


# Front to back in the file: Lottie draws the FIRST layer on top.
# Flecks: fast, light, gone early.
for n in range(4):
    a = math.radians(-100 + n * 70 + random.uniform(-14, 14))
    far = random.uniform(120, 150)
    d = random.uniform(22, 34)
    add(
        f"fleck{n}",
        [group([ellipse(d), soft_fill(FLECK, d, 0.6)], "fleck")],
        p=anim([(0, [C, C, 0], "out"), (7, [C + math.cos(a) * far, C + math.sin(a) * far - 10, 0], "linear"),
                (FRAMES - 1, [C + math.cos(a) * far * 1.1, C + math.sin(a) * far * 1.1 - 22, 0], "linear")], 3),
        s=anim([(0, [40, 40, 100], "out"), (5, [100, 100, 100], "linear"), (FRAMES - 1, [60, 60, 100], "linear")], 3),
        o=anim([(0, [100], "linear"), (3, [100], "in"), (11, [0], "linear"), (FRAMES - 1, [0], "linear")], 1),
    )

# Flash ring: the bomb going off.
add(
    "ring",
    [group([ellipse(200), stroke(FLASH, [(0, [10], "out"), (9, [1], "linear"), (FRAMES - 1, [1], "linear")],
                                   [(0, [75], "out"), (9, [0], "linear"), (FRAMES - 1, [0], "linear")])], "ring")],
    p=still([C, C, 0]),
    s=anim([(0, [8, 8, 100], "out"), (9, [135, 135, 100], "linear"), (FRAMES - 1, [140, 140, 100], "linear")], 3),
    o=still(100),
)

# Seven ink puffs shoved outward, thinning as they go. Bigger ones sit lower so the
# cloud reads heavier at the bottom, the way smoke pools before it rises.
for n in range(7):
    a = math.radians(-90 + n * (360 / 7) + random.uniform(-12, 12))
    far = random.uniform(78, 108)
    d = random.uniform(96, 132) if math.sin(a) > 0 else random.uniform(84, 112)
    col = PUFF[n % len(PUFF)]
    add(
        f"puff{n}",
        [group([ellipse(d), soft_fill(col, d, 0.5)], "puff")],
        p=anim([(0, [C, C, 0], "out"), (9, [C + math.cos(a) * far, C + math.sin(a) * far - 6, 0], "linear"),
                (FRAMES - 1, [C + math.cos(a) * far * 1.08, C + math.sin(a) * far * 1.08 - 22, 0], "linear")], 3),
        s=anim([(0, [30, 30, 100], "out"), (8, [100, 100, 100], "linear"), (FRAMES - 1, [118, 118, 100], "linear")], 3),
        o=anim([(0, [92], "linear"), (6, [92], "in"), (17, [0], "linear"), (FRAMES - 1, [0], "linear")], 1),
    )

# Core puff: what he vanishes into. Soft-centred and gone early, or its dense middle
# outlives the outer puffs and reads as a dot hanging in the water.
add(
    "core",
    [group([ellipse(230), soft_fill(CORE, 230, 0.3)], "core")],
    p=anim([(0, [C, C, 0], "linear"), (FRAMES - 1, [C, C - 16, 0], "linear")], 3),
    s=anim([(0, [35, 35, 100], "out"), (8, [115, 115, 100], "linear"), (FRAMES - 1, [138, 138, 100], "linear")], 3),
    o=anim([(0, [96], "linear"), (7, [96], "out"), (14, [50], "linear"), (FRAMES - 1, [0], "linear")], 1),
)

doc = {
    "v": "5.7.4", "fr": FPS, "ip": 0, "op": FRAMES, "w": SIZE, "h": SIZE,
    "nm": "ninja-smoke", "ddd": 0, "assets": [], "layers": layers,
    "markers": [{"tm": 0, "cm": "poof", "dr": FRAMES}],
}

with open(OUT, "w") as f:
    json.dump(doc, f, separators=(",", ":"))
print("wrote", OUT, os.path.getsize(OUT), "bytes,", len(layers), "layers")
if os.path.isdir(os.path.dirname(SPROUT_PUBLIC)):
    os.makedirs(SPROUT_PUBLIC, exist_ok=True)
    shutil.copy(OUT, os.path.join(SPROUT_PUBLIC, "ninja-smoke.json"))
    print("copied to", SPROUT_PUBLIC)
