"""Tiny Lottie writer for the mascot's effects.

Just enough of the format for shape layers: ellipses, rectangles, stars, paths, solid and
radial-gradient fills, strokes, and keyframed transforms with cubic easing. Nothing here
needs a layer effect, so every file renders the same in dotlottie-web, lottie-web and
LottieFiles Creator — Creator can open any of these for a hand pass.

Conventions: 30 fps, a 400x400 comp with the effect centred on (200, 200). Layers are
listed front to back (Lottie draws the first layer on top). Colours are 0..1 tuples.
"""
import json, os, shutil

FPS = 30
SIZE = 400
C = SIZE / 2

SPROUT_PUBLIC = os.path.expanduser("~/Downloads/Sprout-handoff/public/vfx")
HERE = os.path.dirname(os.path.abspath(__file__))


# --- keyframes -----------------------------------------------------------------------
def ease(name, dims):
    """A Lottie key carries the OUT tangent of its own key and the IN tangent of the next."""
    tangents = {
        "out": ((0.10, 0.80), (0.35, 1.00)),
        "in": ((0.55, 0.00), (0.90, 0.60)),
        "inout": ((0.42, 0.00), (0.58, 1.00)),
        "linear": ((0.33, 0.33), (0.67, 0.67)),
        "back": ((0.20, 1.35), (0.55, 1.00)),
    }[name]
    (ox, oy), (ix, iy) = tangents
    return {"o": {"x": [ox] * dims, "y": [oy] * dims}, "i": {"x": [ix] * dims, "y": [iy] * dims}}


def anim(keys, dims):
    """keys: [(frame, [values], ease into the NEXT key)]. A single key is a still."""
    if len(keys) == 1:
        v = keys[0][1]
        return {"a": 0, "k": v[0] if dims == 1 else list(v)}
    out = []
    for n, (t, v, e) in enumerate(keys):
        k = {"t": t, "s": list(v)}
        if n < len(keys) - 1:
            k.update(ease(e, dims))
        out.append(k)
    return {"a": 1, "k": out}


def still(v):
    return {"a": 0, "k": v}


# --- shapes --------------------------------------------------------------------------
def ellipse(d, dy=None):
    return {"ty": "el", "p": still([0, 0]), "s": still([d, dy if dy is not None else d]), "d": 1, "nm": "e"}


def rect(w, h, r=0):
    return {"ty": "rc", "p": still([0, 0]), "s": still([w, h]), "r": still(r), "d": 1, "nm": "r"}


def star(points, outer, inner, rot=0):
    return {"ty": "sr", "sy": 1, "p": still([0, 0]), "r": still(rot), "pt": still(points),
            "or": still(outer), "ir": still(inner), "os": still(0), "is": still(0), "d": 1, "nm": "s"}


def path(points, closed=True, keys=None):
    """A polyline/bezier path. `points` is [(x, y)] with straight segments; pass `keys` as
    [(frame, [(x, y)...], ease)] to morph between point sets of the same length."""
    def shape(pts):
        return {"c": closed, "v": [list(p) for p in pts], "i": [[0, 0]] * len(pts), "o": [[0, 0]] * len(pts)}
    if keys:
        k = []
        for n, (t, pts, e) in enumerate(keys):
            entry = {"t": t, "s": [shape(pts)]}
            if n < len(keys) - 1:
                entry.update(ease(e, 1))
            k.append(entry)
        return {"ty": "sh", "ks": {"a": 1, "k": k}, "d": 1, "nm": "p"}
    return {"ty": "sh", "ks": still(shape(points)), "d": 1, "nm": "p"}


def fill(rgb, opacity=100):
    r, g, b = rgb
    return {"ty": "fl", "c": still([r, g, b, 1]), "o": still(opacity), "r": 1, "bm": 0, "nm": "f"}


def soft_fill(rgb, d, solid_to=0.55):
    """Radial gradient: the colour holds to `solid_to` of the radius, then fades out."""
    r, g, b = rgb
    stops = [0, r, g, b, solid_to, r, g, b, 1, r, g, b, 0, 1, solid_to, 0.92, 1, 0]
    return {"ty": "gf", "o": still(100), "r": 1, "bm": 0, "g": {"p": 3, "k": still(stops)},
            "s": still([0, 0]), "e": still([d / 2, 0]), "t": 2, "h": still(0), "a": still(0), "nm": "gf"}


def stroke(rgb, width, opacity=100):
    """`width` and `opacity` may be numbers or key lists for anim()."""
    r, g, b = rgb
    w = anim(width, 1) if isinstance(width, list) else still(width)
    o = anim(opacity, 1) if isinstance(opacity, list) else still(opacity)
    return {"ty": "st", "c": still([r, g, b, 1]), "o": o, "w": w, "lc": 2, "lj": 2, "nm": "st"}


def transform(p=(0, 0), s=(100, 100), r=0, o=100):
    return {"ty": "tr", "p": still(list(p)), "a": still([0, 0]), "s": still(list(s)),
            "r": still(r), "o": still(o), "sk": still(0), "sa": still(0), "nm": "tr"}


def group(items, name="g", tr=None):
    return {"ty": "gr", "it": items + [tr or transform()], "nm": name, "np": len(items) + 1,
            "cix": 2, "bm": 0, "ix": 1, "hd": False}


# --- layers and files ----------------------------------------------------------------
class Comp:
    def __init__(self, name, frames):
        self.name = name
        self.frames = frames
        self.layers = []

    def add(self, name, shapes, p=None, s=None, o=None, r=None, ip=0, op=None):
        """Front to back: call order is draw order, first call on top."""
        ks = {
            "o": o if o is not None else still(100),
            "r": r if r is not None else still(0),
            "p": p if p is not None else still([C, C, 0]),
            "a": still([0, 0, 0]),
            "s": s if s is not None else still([100, 100, 100]),
        }
        self.layers.append({
            "ddd": 0, "ind": len(self.layers) + 1, "ty": 4, "nm": name, "sr": 1, "ks": ks,
            "ao": 0, "shapes": shapes, "ip": ip, "op": op if op is not None else self.frames, "st": 0, "bm": 0,
        })

    def write(self):
        doc = {"v": "5.7.4", "fr": FPS, "ip": 0, "op": self.frames, "w": SIZE, "h": SIZE,
               "nm": self.name, "ddd": 0, "assets": [], "layers": self.layers}
        out = os.path.join(HERE, f"{self.name}.json")
        with open(out, "w") as f:
            json.dump(doc, f, separators=(",", ":"))
        if os.path.isdir(os.path.dirname(SPROUT_PUBLIC)):
            os.makedirs(SPROUT_PUBLIC, exist_ok=True)
            shutil.copy(out, os.path.join(SPROUT_PUBLIC, f"{self.name}.json"))
        print(f"wrote {self.name}.json  {os.path.getsize(out):>6} bytes  {len(self.layers)} layers  {self.frames / FPS:.2f}s")
