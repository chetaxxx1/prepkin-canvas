#!/usr/bin/env python3
"""Style-locked scene art. One look, a completely different picture per scene.

    python3 design/figure-art/gemini.py trolley-runaway trolley-lever
    python3 design/figure-art/gemini.py --all
    python3 design/figure-art/gemini.py --field leaf trolley-runaway   # other field colour
    python3 design/figure-art/gemini.py -n 3 trolley-lever             # pick from three

The style block and the three reference images below never change; only the SCENE
paragraph does. That is the whole mechanism — see design/figure-art/STYLE-BLOCK.md for
why, and for the rules on writing a scene block.

Never send previous_interaction_id from here. That is chain mode, and it drags the last
composition along, which is exactly what this is built to avoid.

The key comes from GEMINI_API_KEY, or from the nanobanana MCP entry in ~/.claude.json.
PNGs land in design/art-src/figures/<id>.png, ready for `pack.py --raster`.
"""
import base64, json, os, sys, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "art-src", "figures")
MODEL = "gemini-3.1-flash-image"

# Three refs that look alike and depict nothing alike. A reference carries content as
# well as style — a tram's pantograph once transferred from an attached preview — so if
# all three shared a subject, that subject would leak into every scene.
REFS = [os.path.join(HERE, "preview", f) for f in ("scene-cave.png", "jar.png", "ticket.png")]

FIELDS = {"coin": "soft cream #FFF4DC", "leaf": "pale mint green #EAF4E0",
          "sky": "pale sky blue #E6F0FB", "lav": "pale lavender #EDE7FB",
          "rose": "pale peach #FFEDE7"}

STYLE = """The attached pictures are the house style. Match them exactly and ignore their subjects.

STYLE. A flat vector illustration for a learning app. Every shape is filled with one \
single flat colour, uniform edge to edge, with a hard clean boundary. Every shape is \
traced with the same thick even dark brown #2E2622 outline, the same weight all the way \
round every object. Colours are drawn only from coral red #FF6F61, warm yellow #FFC24B, \
sky blue #9BC8F2, leaf green #A5CE6B, lavender #C3B2F0, white and warm grey #D9CFC0. \
The background is one plain solid {field} filling the whole frame. Every surface is \
blank and unlettered: signs are plain painted boards, screens show only shape and \
colour, paper is ruled but unwritten. Shapes are large and simple and fill the frame. \
The top third of the frame is open and empty."""

# A scene that does not name its own camera gets the house one appended.
CAMERA = (" Camera at eye level, straight on, a flat side view with everything at true "
          "size and no perspective.")

# id -> (scene paragraph, field). Name objects by their marks, and enumerate any count:
# "five people" comes back as four, every time.
SCENES = {
 # work-2, the salary question. A wide two-shot, then a close-up of hands.
 "work-question": ("Two people sitting facing each other across a small plain table, seen from the side at eye level, both drawn as simple flat figures. The person on the right leans forward slightly. Above the person on the right floats one large empty rounded speech bubble with a tail pointing down at them, and the inside of the bubble is completely blank. The person on the left sits upright with their hands resting on the table. Empty space fills the upper left of the frame.", "rose"),
 "work-handback": ("A close view of two open hands facing each other against a plain background, filling the frame. The hand on the left holds a small blank rounded card flat on its palm, tilted slightly toward the other hand. The hand on the right is open and turned palm up, waiting to receive it. A short curved arrow arcs from the left hand over to the right hand, showing the card moving across. The card is plain and unwritten.", "rose"),
 # work-3, asking for a raise. A calendar, then a desk of evidence.
 "work-calendar": ("A wall calendar hanging on a plain wall, seen straight on and filling most of the frame. The calendar is one large sheet with a solid coloured band across its top and a grid of empty square day boxes below it, five rows of seven. One single box low in the grid has a thick ring drawn around it. A small hole and a nail hold the calendar to the wall. Every box is plain and unwritten.", "leaf"),
 "work-evidence": ("A close view of a desk from directly above, filling the frame. On the desk sits one open folder with a small stack of plain paper inside it, each sheet ruled with short lines of different lengths like paragraphs. Beside the folder lies a pen, and beside that a small plain notebook, closed. One sheet has been pulled half out of the folder so it sits proud of the others. Every sheet is plain and unwritten.", "leaf"),
 "trolley-runaway": ("A red tram runs alone down a straight railway track, moving fast to the right. The track is two long parallel rails with short wooden sleepers laid across them in an even row, running from the left edge to the right edge across the lower third. The tram sits on the track with its two round black wheels resting on the rails. Three short straight speed lines trail behind it in the open air. The track ahead of the tram is empty and clear all the way to the right edge.", "sky"),
 "trolley-lever": ("A close view of one hand gripping a tall upright switch lever beside a railway track, seen from the side. The lever is a straight post rising from a heavy base plate, with a long straight handle angled out from its top and a round knob at the handle's end. The hand and forearm come in from the left edge and close around the handle. Behind the lever, low and small, a railway track runs left to right, drawn as two parallel rails with short sleepers across them, and it splits into two branches that separate as they go right. The lever fills the left half of the frame and is much larger than the track behind it.", "sky"),
 "trolley-map": ("A bird's-eye view looking straight down from directly above at a railway junction, like a map. The track enters at the bottom of the frame as two parallel rails with short sleepers laid across them, and splits into two branches that spread apart as they run toward the top of the frame. On the left branch stand five small people seen from directly overhead, each a plain round head with shoulders, in a row and evenly spaced. On the right branch stands one small person of the same overhead shape, alone. A small square switch plate sits beside the split where the two branches part.", "sky"),
 # work-1, the 401k match. Four different pictures, one look: a document, a jar seen
 # from above, two stacks side on, two hands. Nothing shared but the style block.
 "work-offer": ("A single sheet of paper standing upright and filling most of the frame, seen straight on, with a pen lying diagonally across its lower right corner. In the top left of the sheet sits a small solid square logo mark with two short rules beside it, and a wider gap below. Then one short rule on its own, like a greeting. Then three separate blocks of ruled lines, four lines to a block, and within every block the lines are of different lengths, each ending at a different point well short of the right edge, the way paragraphs of text do. One line sits by itself inside a pale tinted band that also stops short of the right edge. Near the bottom left a looping handwritten squiggle rests on top of a short horizontal rule. The paper is plain and unwritten throughout.", "coin"),
 "work-second": ("A close view, tilted slightly, of two sheets of paper lying one on top of the other on a flat surface. A hand comes in from the right edge, pinches the near corner of the top sheet and curls it up and back, revealing the sheet underneath. Across the revealed sheet run ruled lines of different lengths, each ending at a different point, like paragraphs of text. One of those lines sits inside a bright solid highlight band that stands out hard against the plain lines around it. The lifted corner of the top sheet fills the upper right of the frame. Both sheets are plain and unwritten.", "coin"),
 "work-both-in": ("A close view looking down into the open mouth of a wide glass jar that fills the lower half of the frame. Two hands come in from opposite sides, one from the left edge and one from the right edge. Each hand holds one round coin above the jar, pinched between finger and thumb, about to drop it. Inside the jar, below them, a shallow layer of coins already sits at the bottom. The two hands are the same size and mirror each other.", "coin"),
 "work-doubled": ("A flat surface runs across the lower third of the frame. Standing on it, two stacks of round coins side by side, seen from the side at eye level. Each stack is four coins tall and the two stacks are exactly the same height, touching at their edges so they read as one block twice the width of either. Beside them on the same surface, to the left, stands a single coin lying flat, and to the right another single coin lying flat. The stacks are small in the frame with generous empty space above and to both sides.", "coin"),
 "work-refused": ("A close view of two hands facing each other against an open background, filling the frame. The hand on the left is held out flat and open, palm up, with one round coin resting on it, offering it forward. The hand on the right is raised upright with the palm turned outward in a flat stop gesture, fingers together, held between itself and the coin. The two hands do not touch.", "coin"),
 "trolley-bridge": ("A railway track runs left to right across the lower third: two long parallel rails with short wooden sleepers laid across them in an even row. A small red tram with two round black wheels sits on the track at the far left, its wheels on the rails, facing right. Standing on the track at the far right is a row of people. Count them as you draw: the first person, then a second beside them, then a third, then a fourth, then a fifth. Five people in total and no more, all identical and evenly spaced. Spanning the track between the tram and those five stands a footbridge: one straight flat deck on two straight vertical legs, one leg each side of the track, raised high enough that the tram would pass underneath. On the middle of the deck stand two people seen from the side: one small person of the same shape as the five, and beside them one noticeably larger and heavier person close to the deck's edge, with the small person's arm reaching toward their back.", "sky"),
}

def key():
    if os.environ.get("GEMINI_API_KEY"): return os.environ["GEMINI_API_KEY"]
    cfg = json.load(open(os.path.expanduser("~/.claude.json")))
    found = []
    def walk(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if k == "nanobanana" and isinstance(v, dict):
                    found.append((v.get("env") or {}).get("GEMINI_API_KEY"))
                walk(v)
        elif isinstance(o, list):
            for x in o: walk(x)
    walk(cfg)
    for k in found:
        if k: return k
    raise SystemExit("no GEMINI_API_KEY in the environment or in the nanobanana MCP entry")

def part(path):
    return {"inline_data": {"mime_type": "image/png",
                            "data": base64.b64encode(open(path, "rb").read()).decode()}}

def generate(sid, n=1, field=None):
    scene, default_field = SCENES[sid]
    style = STYLE.format(field=FIELDS[field or default_field])
    # A scene that sets its own camera overrules the house one; sending both makes the
    # model split the difference and you get neither.
    camera = "" if any(w in scene.lower() for w in ("bird's-eye", "from above", "overhead")) else CAMERA
    prompt = f"{style}{camera}\n\nSCENE. {scene}"
    body = {"contents": [{"parts": [part(p) for p in REFS] + [{"text": prompt}]}],
            "generationConfig": {"responseModalities": ["IMAGE"],
                                 "imageConfig": {"aspectRatio": "4:3", "imageSize": "2K"}}}
    url = (f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}"
           f":generateContent?key={key()}")
    os.makedirs(OUT, exist_ok=True)
    # The image models reject candidateCount > 1 with a bare 400, so variants are
    # separate requests rather than one request asking for several.
    for i in range(n):
        req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                out = json.load(r)
        except urllib.error.HTTPError as e:
            raise SystemExit(f"{sid}: HTTP {e.code}\n{e.read().decode()[:600]}")
        for cand in out.get("candidates", []):
            for p in cand["content"]["parts"]:
                if "inlineData" not in p: continue
                name = sid if i == 0 else f"{sid}-{i+1}"
                path = os.path.join(OUT, f"{name}.png")
                open(path, "wb").write(base64.b64decode(p["inlineData"]["data"]))
                print(f"{name}: {os.path.getsize(path)} bytes")

if __name__ == "__main__":
    args = sys.argv[1:]
    n, field = 1, None
    if "-n" in args: i = args.index("-n"); n = int(args[i+1]); del args[i:i+2]
    if "--field" in args: i = args.index("--field"); field = args[i+1]; del args[i:i+2]
    ids = list(SCENES) if "--all" in args else [a for a in args if not a.startswith("-")]
    for sid in ids: generate(sid, n, field)
