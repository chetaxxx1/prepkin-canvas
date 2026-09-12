"""Record costume signature acts as GIFs for sign-off.

Serves the Sprout build, dresses him, pauses the page and steps it one frame at a time
through `RiverSprite.step`, screenshotting each. Real-time recording is useless here: a
screenshot takes longer than a frame, so a two-second act would come out as whatever the
clock landed on. Stepping makes every run land on the same frames.

    python3 design/vfx/capture_act.py ninja coral 1        # one act: costume, coat, index
    python3 design/vfx/capture_act.py --set legendary      # every act of a tier, one browser
    python3 design/vfx/capture_act.py --set legendary --phone
    python3 design/vfx/capture_act.py --set legendary --phone --force   # redo ones already captured

`--phone` is the iPhone Home look: 390x560 view, radius 72, over the lagoon plate. Without
it the view is a 520px square on the page's own mint, no tank.

Per act, into design/vfx/out/: <costume>-<coat>-<n>[-phone].gif at full size,
...-small.gif at half size and 15fps for review pages, and ...-sheet.png with a frame
every 0.2s so the beats can be read at a glance.
"""
import asyncio, os, subprocess, sys, time
from PIL import Image
from playwright.async_api import async_playwright

WEB = os.path.expanduser("~/Downloads/Sprout-handoff/dist")
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
PORT = 8934
DPR = 2
FPS = 30
SECONDS = 2.9         # the longest act plus a beat of settle

# Which coat shows each costume on a review page. The ninja is coral's default; the rest
# are picked for contrast with the garment.
SETS = {
    "legendary": [("ninja", "coral"), ("sorcerer", "lilac"), ("grad", "mint"), ("hex", "sky"),
                  ("champ", "coral"), ("headliner", "sky"), ("netrunner", "butter"), ("count", "lilac"), ("abyss", "mint")],
    "epic": [("biker", "butter"), ("astronaut", "lilac"), ("monster", "mint")],
    "rare": [("happi", "peach"), ("idol", "sky"), ("racer", "butter"), ("ballet", "lilac"), ("hanbok", "coral")],
    "uncommon": [("scholar", "mint"), ("varsity", "coral"), ("pajamas", "sky"), ("keynote", "butter")],
    "common": [("hoodie", "sky"), ("flannel", "peach"), ("barista", "mint")],
}

PHONE = "--phone" in sys.argv
if PHONE:
    VIEW_W, VIEW_H, RADIUS, TANK = 390, 560, 72, "lagoon"
else:
    VIEW_W, VIEW_H, RADIUS, TANK = 520, 520, 84, None

args = [a for a in sys.argv[1:] if not a.startswith("--")]
def parse_index(v):
    return "ult" if v == "ult" else int(v)


# Ults are for rare and above; the cheaper tiers stop at five moves.
ULT_TIERS = {"legendary", "epic", "rare"}

if "--set" in sys.argv:
    tier = sys.argv[sys.argv.index("--set") + 1]
    indices = [0, 1, 2, 3, 4] + (["ult"] if tier in ULT_TIERS else [])
    JOBS = [(c, coat, i) for c, coat in SETS[tier] for i in indices]
else:
    JOBS = [(args[0] if args else "ninja", args[1] if len(args) > 1 else "coral", parse_index(args[2]) if len(args) > 2 else 1)]

BG = (223, 243, 234, 255)  # the page's own mint, so a transparent shot reads as the app


def flatten(im):
    base = Image.new("RGBA", im.size, BG)
    base.alpha_composite(im)
    return base


def save(name, frames, logs):
    for line in logs:
        print("  page:", line)
    gif = os.path.join(OUT, f"{name}.gif")
    flat = [flatten(im).resize((VIEW_W, VIEW_H), Image.LANCZOS).convert("P", palette=Image.ADAPTIVE, colors=128) for im in frames]
    flat[0].save(gif, save_all=True, append_images=flat[1:], duration=int(1000 / FPS), loop=0, optimize=False)
    small = [flatten(im).resize((VIEW_W // 2, VIEW_H // 2), Image.LANCZOS).convert("P", palette=Image.ADAPTIVE, colors=96)
             for im in frames[::2]]
    small[0].save(os.path.join(OUT, f"{name}-small.gif"), save_all=True, append_images=small[1:],
                  duration=int(2000 / FPS), loop=0, optimize=True)
    pick = frames[::6]
    cols = 7
    rows = (len(pick) + cols - 1) // cols
    cw, ch = VIEW_W // 2, VIEW_H // 2
    sheet = Image.new("RGBA", (cols * cw, rows * ch), BG)
    for k, im in enumerate(pick):
        sheet.paste(flatten(im).resize((cw, ch), Image.LANCZOS), ((k % cols) * cw, (k // cols) * ch))
    sheet.save(os.path.join(OUT, f"{name}-sheet.png"))
    print("wrote", name, len(flat), "frames", flush=True)


async def main():
    os.makedirs(OUT, exist_ok=True)
    srv = subprocess.Popen([sys.executable, "-m", "http.server", str(PORT), "--bind", "127.0.0.1"],
                           cwd=WEB, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.9)
    try:
        async with async_playwright() as p:
            b = await p.chromium.launch(channel="chrome")
            ctx = await b.new_context(viewport={"width": VIEW_W, "height": VIEW_H}, device_scale_factor=DPR)
            pg = await ctx.new_page()
            logs = []
            pg.on("console", lambda m: logs.append(f"[{m.type}] {m.text}"))
            pg.on("pageerror", lambda e: logs.append(f"[pageerror] {e}"))
            for costume, coat, index in JOBS:
                name = f"{costume}-{coat}-{index}" + ("-phone" if PHONE else "")
                if "--force" not in sys.argv and os.path.exists(os.path.join(OUT, f"{name}-sheet.png")):
                    print("have", name, flush=True)
                    continue
                logs.clear()
                q = ["embed=1", "type=sprout", f"coat={coat}", "evo=3", f"radius={RADIUS}", "skin=classic", f"costume={costume}"]
                if TANK:
                    q.append(f"tank={TANK}")
                await pg.goto(f"http://127.0.0.1:{PORT}/index.html?" + "&".join(q))
                await pg.wait_for_function("() => !!window.RiverSprite && !!window.RiverSprite.step", timeout=30000)
                await pg.evaluate("() => window.RiverSprite.setReduceMotion(false)")
                # Let him settle and the effects layer warm its WASM.
                await pg.wait_for_timeout(1500)
                await pg.evaluate("() => window.RiverSprite.setPaused(true)")
                if index == "ult":
                    await pg.evaluate("() => window.RiverSprite.ult()")
                else:
                    await pg.evaluate(f"() => window.RiverSprite.signature({index})")
                st = await pg.evaluate("() => window.RiverSprite.state()")
                print(f"{costume}/{coat}/{index}: start", st, flush=True)
                frames = []
                seconds = 5.6 if index == "ult" else SECONDS
                for i in range(int(seconds * FPS)):
                    await pg.evaluate(f"() => window.RiverSprite.step({1 / FPS})")
                    # The effect seeks on the same step; give the WASM renderer a paint.
                    await pg.wait_for_timeout(8)
                    raw = f"/tmp/act-{i:03d}.png"
                    await pg.screenshot(path=raw, omit_background=not TANK)
                    frames.append(Image.open(raw).convert("RGBA"))
                save(name, frames, logs)
            await b.close()
    finally:
        srv.terminate()


asyncio.run(main())
