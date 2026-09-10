"""Capture a stage-III still for every costume on every coat, into the SAME box the
existing stills use.

`capture_sprout.py` renders the plain and Ninja families and measures its own shared
box. This one adds the other seventeen costumes without disturbing that set: the box
is pinned to the 1293px the repo's stills already use, so a costume still drops in
beside them and lines up to the pixel.

Costumes only exist at stage III, so only evo 3 is captured. Stages 1 and 2 fall back
to the plain still (see `SproutImage.asset`).

Writes to design/sprout-stills/out-costumes/ so the size can be looked at before any
of it lands in Assets.xcassets. Install with design/sprout-stills/install_stills.py.
"""
import asyncio, os, subprocess, sys, time
from PIL import Image
from playwright.async_api import async_playwright

WEB = "/Users/georgeshi/Downloads/Sprout-handoff/dist"
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "sprout-stills", "out-costumes")
PORT = 8931
# 2400, not 1400. At 1400 the astronaut's flag ran off the right edge of the canvas and was
# screenshotted in half — the art was cut before any box maths happened. Leave room.
SHOT = 2400
RADIUS = 300
SIDE = 1293          # the box every still in Assets.xcassets already uses
HEIGHT_RATIO = 0.700 # must match SproutImage.heightRatio, or a card reserves the wrong height

COATS = ["mint", "coral", "sky", "peach", "lilac", "butter"]
# The whole rack from costumes.ts, in the order the rail shows it.
COSTUMES = ["hoodie", "flannel", "barista", "scholar", "varsity", "pajamas", "keynote",
            "happi", "idol", "racer", "ballet", "hanbok", "biker", "astronaut", "monster",
            "ninja", "sorcerer", "grad", "hex"]
# Recapture a few: `python3 design/capture_costumes.py astronaut sorcerer`.
if len(sys.argv) > 1:
    COSTUMES = [c for c in COSTUMES if c in sys.argv[1:]]


async def main():
    os.makedirs(OUT, exist_ok=True)
    srv = subprocess.Popen([sys.executable, "-m", "http.server", str(PORT), "--bind", "127.0.0.1"],
                           cwd=WEB, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.9)
    shots = {}
    try:
        async with async_playwright() as p:
            b = await p.chromium.launch(channel="chrome")
            pg = await (await b.new_context(viewport={"width": SHOT, "height": SHOT},
                                            device_scale_factor=1)).new_page()
            for costume in COSTUMES:
                for coat in COATS:
                    name = f"sprout-{costume}-{coat}-3"
                    q = ["embed=1", "type=sprout", f"coat={coat}", "evo=3",
                         f"radius={RADIUS}", "skin=classic", f"costume={costume}"]
                    await pg.goto(f"http://127.0.0.1:{PORT}/index.html?" + "&".join(q))
                    await pg.wait_for_function("() => !!window.RiverSprite", timeout=20000)
                    # The idle sway swings the fins, and with them anything held: the same
                    # costume measured 1339 to 1404 px wide across eight samples. Reduce
                    # motion parks the pose, so the box these get pasted into is a number
                    # rather than a coin toss.
                    await pg.evaluate("() => window.RiverSprite.setReduceMotion(true)")
                    await pg.wait_for_timeout(1200)
                    await pg.add_style_tag(content="#fx{display:none}")
                    # Rest pose, eyes open: a still caught mid-blink looks broken on a card.
                    for _ in range(90):
                        st = await pg.evaluate("() => window.RiverSprite.state()")
                        if not st["blinking"] and not st["emote"]:
                            break
                        await pg.wait_for_timeout(40)
                    raw = f"/tmp/costume-{name}.png"
                    await pg.screenshot(path=raw, omit_background=True)
                    shots[name] = Image.open(raw).convert("RGBA")
                    print(" captured", name, flush=True)
            await b.close()
    finally:
        srv.terminate()

    over = []
    for name, im in shots.items():
        bb = im.getbbox()
        if not bb:
            print("  SKIPPED (empty)", name); continue
        art = im.crop(bb)
        if art.width > SIDE or art.height > int(SIDE * HEIGHT_RATIO):
            over.append((name, art.width, art.height))
        box = Image.new("RGBA", (SIDE, SIDE), (0, 0, 0, 0))
        box.paste(art, ((SIDE - art.width) // 2, SIDE - art.height), art)
        # The biggest a kin is ever drawn is the Kin stage at 212pt, so 646px is 1:1 at
        # @3x. Writing the full 1293 box would be twice the pixels anyone can see, and
        # 48MB of asset catalogue instead of 21.
        for scale, px in ((1, 215), (2, 431), (3, 646)):
            box.resize((px, px), Image.LANCZOS).save(os.path.join(OUT, f"{name}@{scale}x.png"))
    print(f"\nwrote {len(shots)} stills to {OUT}")
    if over:
        print("TALLER OR WIDER THAN THE SHARED BOX — these will look bigger than the rest:")
        for n, w, h in over:
            print(f"  {n}  {w}x{h}  (box {SIDE}, art height budget {int(SIDE * HEIGHT_RATIO)})")

asyncio.run(main())
