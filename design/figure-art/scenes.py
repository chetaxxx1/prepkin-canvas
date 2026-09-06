#!/usr/bin/env python3
"""Generate one full scene per lesson figure in the locked custom style.

    python3 design/figure-art/scenes.py cave trolley      # named scenes
    python3 design/figure-art/scenes.py --all              # every scene
    python3 design/figure-art/scenes.py --model recraftv4_1_vector cave

Scenes are the whole picture: the labels, chips and reveal steps stay in code and
sit on top, so every prompt reserves empty space for them. Output goes to
design/figure-art/svg/scene-<id>.svg and design/figure-art/preview/scene-<id>.png;
pack.py turns them into fig-scene-<id> image sets. The style id comes from
design/figure-art/style.json (made from the first ten objects).
"""
import json, os, sys, time, urllib.request, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import recraft

STYLE_ID = json.load(open(os.path.join(recraft.HERE, "style.json")))["style_id"]

RULES = ("Flat vector scene, big flat colour shapes, thin dark outline of equal weight on every shape, "
         "no gradients, no shadows, no texture, no text, no letters, no numbers, no signs, "
         "friendly and simple, wide 6:5 composition, plain flat background. ")

# id -> (scene, colours most important first)
SCENES = {
    "slots":     ("A cardboard drink carrier with four cup slots seen slightly from above, four paper cups sitting in the slots, a fifth cup tipping off the right edge. Empty space across the top third.", ["coin", "paper", "coral", "ink"]),
    "refresh":   ("A hand holding a smartphone upright, thumb on the screen pulling down, the screen plain light blue and empty. Empty space on the right third.", ["paper", "sky", "coin", "ink"]),
    "sunk":      ("A large cinema ticket with a perforated tear line one third from the left, lying on a cinema seat armrest, a small popcorn bucket beside it. Empty space across the bottom quarter.", ["coin", "coral", "paper", "ink"]),
    "filter":    ("A large funnel standing upright, marbles pouring toward its mouth from the left, some bouncing off its rim, a glass jar under the spout. Empty space on the right third.", ["sky", "leaf", "faint", "ink"]),
    "spotlight": ("A stage spotlight lamp at the top shining a wide cone of light down onto one small person on a round stage, four smaller people standing in the dark on either side each under a faint small cone. Empty space at the top corners.", ["coin", "lav", "coral", "ink"]),
    "loop":      ("A round race track seen from above forming a ring, three small flags planted at three points on the ring, one small runner on the track. The centre of the ring empty.", ["sky", "coin", "coral", "leaf", "ink"]),
    "arousal":   ("A person standing facing forward with a large heart shape over the chest and a pulse line across the heart, two empty thought bubbles above, one at the left and one at the right.", ["coral", "paper", "sky", "ink"]),
    "email":     ("An open laptop on a desk showing an empty email window with a blank white body, a paper envelope leaning against the laptop. The email body empty.", ["paper", "sky", "coral", "ink"]),
    "no":        ("A person standing in front of a closed door in a wall, one hand raised palm out in a stop gesture, calm face. Empty wall space above the door.", ["coral", "paper", "coin", "ink"]),
    "echo":      ("Two people sitting on a bench facing each other, one with a sad expression, two large empty speech bubbles above them, one over each person.", ["lav", "paper", "leaf", "ink"]),
    "ladder":    ("A wooden step ladder with three rungs standing on the floor, a person climbing on the lowest rung. Empty space on the right half.", ["coin", "paper", "ink"]),
    "apology":   ("Two grassy banks with a gap between them, a plank bridge of three planks laid across the gap, one small person standing on each bank. Empty space across the top third.", ["leaf", "coin", "paper", "ink"]),
    "paycheck":  ("A pay slip sheet of paper lying on a desk beside a coffee mug and a pen, the pay slip large with only a coloured header band and blank space below.", ["paper", "coin", "leaf", "ink"]),
    "brackets":  ("Three buckets stacked in a tower, the bottom bucket full of gold coins, the middle bucket half full, the top bucket with only a few coins. Empty space on the left third.", ["coin", "leaf", "sky", "ink"]),
    "jar":       ("A glass jar with a yellow lid standing on a wooden shelf, a few gold coins at the bottom and a small green sprout growing from them. Empty space on the right third.", ["paper", "coin", "leaf", "ink"]),
    "burrito":   ("A burrito wrapped in foil on a plate, one end cut open showing green lettuce, red salsa and rice, a small blank price tag on a string. Empty space across the top quarter.", ["coin", "leaf", "coral", "faint", "ink"]),
    "trolley":   ("A red tram on a railway track that forks into two branches ahead of it, five people standing on the upper branch and one person on the lower branch, a lever beside the fork, flat side view. Empty space at the top left.", ["coral", "lav", "sky", "ink"]),
    "ship":      ("A wooden sailing ship with a white sail moored at a dock, a stack of old grey planks on the dock and a carpenter holding a hammer. Empty space across the top quarter.", ["faint", "paper", "coin", "leaf", "ink"]),
    "cave":      ("The inside of a cave, three people sitting in a row facing the cave wall where dark shadows fall, a campfire burning behind them, a bright opening to the outside on the right. Empty space on the wall above the shadows.", ["lav", "coral", "coin", "ink"]),
    "cornell":   ("A notebook page divided by lines into a narrow left column, a wide right area and a strip along the bottom, a pencil lying beside it, all areas blank.", ["paper", "coin", "sky", "ink"]),
    "feynman":   ("A person standing at a large blank chalkboard explaining to a child sitting on a stool, the chalkboard filling most of the picture and empty.", ["leaf", "coin", "paper", "ink"]),
    "sleep":     ("A person asleep in a bed under a window showing a crescent moon, a long horizontal empty bar below the bed like a timeline. Empty space at the bottom.", ["lav", "sky", "coin", "ink"]),
    "exam":      ("An exam paper on a desk with five blank numbered lines, a pencil and a small clock beside it. Empty space at the bottom of the paper.", ["paper", "leaf", "coral", "ink"]),
}

def generate(sid, model):
    scene, colours = SCENES[sid]
    body = {"prompt": RULES + scene, "model": model, "style_id": STYLE_ID, "size": "1024x1024", "n": 1,
            "response_format": "url",
            "controls": {"colors": [recraft.rgb(c) for c in colours], "transparent_background": True}}
    for _ in range(6):
        req = urllib.request.Request(recraft.API, data=json.dumps(body).encode(),
                                     headers={"Authorization": f"Bearer {recraft.TOKEN}", "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=180) as r: out = json.load(r); break
        except urllib.error.HTTPError as e:
            import re
            msg = e.read().decode()
            m = re.search(r"doesn't support the '(\w+)' control", msg)
            if m and m.group(1) in body["controls"]:
                del body["controls"][m.group(1)]; continue
            print(f"{sid}: HTTP {e.code} {msg[:300]}"); return None
    else:
        return None
    data = urllib.request.urlopen(out["data"][0]["url"], timeout=180).read()
    ext = "svg" if data[:200].lstrip().startswith(b"<") else "png"
    path = os.path.join(recraft.SVG, f"scene-{sid}.{ext}")
    open(path, "wb").write(data)
    print(f"scene-{sid}: {len(data)} bytes .{ext}, credits {out.get('credits')}")
    if ext == "svg":
        os.makedirs(recraft.PREVIEW, exist_ok=True)
        subprocess.run(["rsvg-convert", "-w", "720", "-h", "720", "-b", "#FFFFFF", path,
                        "-o", os.path.join(recraft.PREVIEW, f"scene-{sid}.png")], check=True)
    return path

if __name__ == "__main__":
    args = sys.argv[1:]
    model = "recraftv4_styles_vector"
    if "--model" in args:
        i = args.index("--model"); model = args[i + 1]; del args[i:i + 2]
    ids = list(SCENES) if "--all" in args else [a for a in args if not a.startswith("--")]
    for sid in ids:
        generate(sid, model); time.sleep(0.3)
