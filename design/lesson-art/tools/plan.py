"""Load a lesson plan (design/lesson-art/<id>/plan.py) and turn it into the shapes the
other tools want: the app's lesson JSON, the list of paintings Ink owes, the list of code
figures figures.py must have drawn.

A plan is one Python dict, LESSON, in the lesson's own folder. Every image card has a
`src` (the PNG's stem inside that folder). A card with a `paint` key is a scene Ink paints;
a card without one is a figure drawn by figures.py. The app never sees `src` or `paint`.
"""
import importlib.util, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def folder(lesson_id):
    return os.path.join(ROOT, lesson_id)

def load(lesson_id):
    path = os.path.join(folder(lesson_id), "plan.py")
    spec = importlib.util.spec_from_file_location(f"plan_{lesson_id}", path)
    mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
    L = mod.LESSON
    assert L["id"] == lesson_id, f"{path}: id is {L['id']!r}, folder is {lesson_id!r}"
    return L

def asset_name(lesson_id, n):
    """lesson-work4-03: the imageset name the app looks up. n is 1-based."""
    return f"lesson-{lesson_id.replace('-', '')}-{n:02d}"

def image_cards(L):
    """(1-based card number, card) for every picture card, in deck order."""
    return [(i + 1, c) for i, c in enumerate(L["cards"]) if c["kind"] == "image"]

def paintings(L):
    return [(n, c) for n, c in image_cards(L) if "paint" in c]

def figures(L):
    return [(n, c) for n, c in image_cards(L) if "paint" not in c]

def to_app_json(L):
    """The dict lessons.json stores. Strips the build-only keys."""
    out = {k: L[k] for k in ("id", "title", "track", "minutes", "blurb", "takeaway")}
    cards = []
    for i, c in enumerate(L["cards"]):
        if c["kind"] == "image":
            cards.append({"kind": "image", "image": asset_name(L["id"], i + 1),
                          "eyebrow": c["eyebrow"], "body": c["body"]})
        elif c["kind"] == "key":
            cards.append({"kind": "key", "body": c["body"]})
        elif c["kind"] == "check":
            cards.append({"kind": "check", "question": c["question"], "choices": list(c["choices"]),
                          "answer": c["answer"], "why": c["why"]})
        else:
            raise ValueError(f"{L['id']} card {i + 1}: unknown kind {c['kind']!r}")
    out["cards"] = cards
    return out

def source_path(lesson_id, card):
    """The PNG or JPEG for a picture card, or None if it has not landed yet."""
    for ext in ("png", "jpg", "jpeg"):
        p = os.path.join(folder(lesson_id), f"{card['src']}.{ext}")
        if os.path.exists(p): return p
    return None
