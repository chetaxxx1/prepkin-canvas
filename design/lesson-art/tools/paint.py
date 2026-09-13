#!/usr/bin/env python3
"""Paint the scene cards of a lesson with Gemini (Nano Banana Pro), straight from the
plan's `paint` specs. Skips pictures already on disk, so a re-run only fills gaps.

  python3 design/lesson-art/tools/paint.py work-5 work-6
  python3 design/lesson-art/tools/paint.py --all            (every plan with a gap)
  python3 design/lesson-art/tools/paint.py --force hlth-1   (repaint even if present)

Stops on the first 429 (credits gone) instead of burning through retries. Every call is
logged to design/lesson-art/tools/paint.log with the lesson, the file and the size.
Roughly $0.13 an image at 2K on gemini-3-pro-image.
"""
import base64, io, json, os, sys, time, urllib.request, urllib.error
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

MODEL = "gemini-3-pro-image"
LOG = os.path.join(os.path.dirname(os.path.abspath(__file__)), "paint.log")

STYLE = ("A polished storybook illustration for a learning app for college students, warm and "
         "painterly, soft visible brushwork, lit like late afternoon unless the scene says "
         "otherwise. Not clip-art, not flat vector, not photoreal, not anime. "
         "The laptop or phone lid, if any, is blank with no logo. HARD RULES. No text anywhere: no letters, numbers, words, logos, brand marks, app "
         "icons, signs, clock digits, book titles, or readable phone screens; pages and screens "
         "show only soft grey bars or squiggles. People are ordinary, diverse, ordinary-looking "
         "adults with faces and light on them, never dark silhouettes. Draw exactly the number "
         "of people the scene names, no more. Landscape 4:3, the subject fills the frame.\n\n"
         "SCENE. ")

def key():
    if os.environ.get("GEMINI_API_KEY"): return os.environ["GEMINI_API_KEY"]
    cfg = json.load(open(os.path.expanduser("~/.claude.json"))); found = []
    def walk(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if k == "nanobanana" and isinstance(v, dict): found.append((v.get("env") or {}).get("GEMINI_API_KEY"))
                walk(v)
        elif isinstance(o, list):
            for x in o: walk(x)
    walk(cfg)
    for k in found:
        if k: return k
    raise SystemExit("no GEMINI_API_KEY")

def log(msg):
    line = time.strftime("%H:%M:%S ") + msg
    print(line); open(LOG, "a").write(line + "\n")

COUNT_WORDS = {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6}

def count_line(spec):
    """Gemini over-counts unless the people are enumerated. Turn 'Exactly three people'
    into a counted list it has to draw one by one."""
    import re
    m = re.search(r"[Ee]xactly (\w+) (?:people|person)", spec)
    if not m or m.group(1) not in COUNT_WORDS: return ""
    n = COUNT_WORDS[m.group(1)]
    ords = ["a first", "a second", "a third", "a fourth", "a fifth", "a sixth"]
    if n == 1: return " Count as you draw: one person and nobody else, not even in the background."
    return (" Count as you draw: " + ", then ".join(f"{ords[i]} person" for i in range(n)) +
            f". {n} people in total and no more, nobody else in the background.")

def request(parts):
    body = {"contents": [{"parts": parts}],
            "generationConfig": {"responseModalities": ["IMAGE"],
                                 "imageConfig": {"aspectRatio": "4:3", "imageSize": "2K"}}}
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json", "x-goog-api-key": key()})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=300) as r: return json.load(r)
        except urllib.error.HTTPError as e:
            text = e.read().decode()[:400]
            if e.code == 429: raise SystemExit(f"STOP: 429 from Gemini (credits or rate): {text}")
            log(f"  HTTP {e.code} on attempt {attempt + 1}: {text[:120]}"); time.sleep(8 * (attempt + 1))
    return None

def save(out, lesson_id, src):
    for cand in (out or {}).get("candidates", []):
        for p in cand["content"]["parts"]:
            if "inlineData" not in p: continue
            im = Image.open(io.BytesIO(base64.b64decode(p["inlineData"]["data"]))).convert("RGB")
            w, h = im.size
            if abs(w / h - 4 / 3) > 0.01:
                nw = int(h * 4 / 3) if w / h > 4 / 3 else w; nh = h if w / h > 4 / 3 else int(w * 3 / 4)
                im = im.crop(((w - nw) // 2, (h - nh) // 2, (w - nw) // 2 + nw, (h - nh) // 2 + nh))
            im = im.resize((1200, 900), Image.LANCZOS)
            dest = os.path.join(P.folder(lesson_id), src + ".png"); im.save(dest, "PNG")
            log(f"{lesson_id}/{src}.png  ({w}x{h} -> 1200x900)")
            return True
    log(f"  no image in the response for {lesson_id}/{src}: {json.dumps(out)[:200]}")
    return False

def edit(lesson_id, src, instruction):
    """One change to an existing picture. One thing at a time; two asks get half done."""
    path = os.path.join(P.folder(lesson_id), src + ".png")
    img = {"inline_data": {"mime_type": "image/png", "data": base64.b64encode(open(path, "rb").read()).decode()}}
    out = request([img, {"text": "Edit this picture. " + instruction + " Keep everything else exactly as it is, same style, same framing, same 4:3 landscape."}])
    return save(out, lesson_id, src)

def paint(lesson_id, card):
    spec = card["paint"].split("The card says")[0].strip()
    out = request([{"text": STYLE + spec + count_line(spec)}])
    return save(out, lesson_id, card["src"])

def main():
    args = sys.argv[1:]; force = "--force" in args
    ids = [a for a in args if not a.startswith("--")]
    if "--all" in args:
        ids = sorted(d for d in os.listdir(P.ROOT) if d != "tools" and os.path.exists(os.path.join(P.ROOT, d, "plan.py")))
    n = 0
    for lid in ids:
        L = P.load(lid)
        for _, c in P.paintings(L):
            if P.source_path(lid, c) and not force: continue
            if paint(lid, c): n += 1
    log(f"done: {n} paintings")

if __name__ == "__main__":
    main()
