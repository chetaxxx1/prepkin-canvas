"""Re-render every Sprout still in Assets.xcassets from the CURRENT web build.

The app draws a WKWebView only on Home. Everywhere else — Kin, Collection, Friends, Focus, the
day editor, first run — it draws a pre-rendered PNG, so those stills were still the old costume
art months after the rack was rebuilt. This regenerates all 45 imagesets from the live rig.

Two things the layout depends on, both preserved here:
  * every still is a SQUARE box, bottom-anchored, and the three-star art fills the width;
  * stages 1 and 2 are smaller INSIDE that same box, so the size ladder survives.
That means one shared crop measured across every capture, not a per-image tight crop.

After recapturing, run design/portraits.py so the round kin portraits stay
centred on each still's face.
"""
import asyncio, json, os, subprocess, sys, time
from PIL import Image
from playwright.async_api import async_playwright

WEB = "/Users/georgeshi/Downloads/Sprout-handoff/dist"
ASSETS = "/Users/georgeshi/Desktop/app/prepkin-canvas/ios/Resources/Assets.xcassets"
PORT = 8930
# Stage III wears the coat's default from COAT_DEFAULT; the ninja LOOK wears the ninja costume,
# which is what makes that family different art rather than a duplicate of the plain set.
COAT_DEFAULT = {"mint": "scholar", "coral": "ninja", "sky": "hoodie",
                "peach": "flannel", "lilac": "astronaut", "butter": "racer"}
FAMILIES = (
    [("sprout", "", c) for c in COAT_DEFAULT]
    + [("sprout", "ninja-", c) for c in COAT_DEFAULT]
    # The orca and axolotl rigs came out of the app on 2026-09-10 (Sprout only at launch).
)
SHOT = 1400          # capture canvas, px
RADIUS = 300         # stage-III radius in that canvas


async def main():
    srv = subprocess.Popen([sys.executable, "-m", "http.server", str(PORT), "--bind", "127.0.0.1"],
                           cwd=WEB, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.9)
    shots = {}
    try:
        async with async_playwright() as p:
            b = await p.chromium.launch(channel="chrome")
            pg = await (await b.new_context(viewport={"width": SHOT, "height": SHOT},
                                            device_scale_factor=1)).new_page()
            for kind, look, coat in FAMILIES:
                for evo in (1, 2, 3):
                    name = f"{kind}-{look}{coat}-{evo}"
                    q = [f"embed=1", f"type={kind}", f"coat={coat}", f"evo={evo}",
                         f"radius={RADIUS}", "skin=classic"]
                    if evo == 3:
                        q.append(f"costume={'ninja' if look else COAT_DEFAULT[coat]}")
                    await pg.goto(f"http://127.0.0.1:{PORT}/index.html?" + "&".join(q))
                    await pg.wait_for_function("() => !!window.RiverSprite", timeout=20000)
                    await pg.wait_for_timeout(650)
                    await pg.add_style_tag(content="#fx{display:none}")
                    # Rest pose, eyes open: a still caught mid-blink looks broken on a card.
                    for _ in range(90):
                        st = await pg.evaluate("() => window.RiverSprite.state()")
                        if not st["blinking"] and not st["emote"]:
                            break
                        await pg.wait_for_timeout(40)
                    raw = f"/tmp/still-{name}.png"
                    await pg.screenshot(path=raw, omit_background=True)
                    shots[name] = Image.open(raw).convert("RGBA")
                    print(" captured", name, flush=True)
            await b.close()
    finally:
        srv.terminate()

    # One shared box, measured over every capture. Width comes from the widest stage-III art so
    # a three-star kin fills the box; height is the tallest thing anywhere (Droplet's headphones,
    # the sorcerer hat) so nothing is clipped.
    boxes = {n: im.getbbox() for n, im in shots.items() if im.getbbox()}
    w = max(b[2] - b[0] for n, b in boxes.items() if n.endswith("-3"))
    h = max(b[3] - b[1] for b in boxes.values())
    side = max(w, h)
    print(f"\nshared box {side}px  (widest III {w}, tallest {h})  heightRatio {h / side:.3f}")

    for name, im in shots.items():
        bb = boxes.get(name)
        if not bb:
            print("  SKIPPED (empty)", name); continue
        art = im.crop(bb)
        box = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        # Centred across, sitting on the bottom edge: the app anchors these by their feet.
        box.paste(art, ((side - art.width) // 2, side - art.height), art)
        d = os.path.join(ASSETS, f"{name}.imageset")
        os.makedirs(d, exist_ok=True)
        for scale, px in ((1, side // 3), (2, side * 2 // 3), (3, side)):
            box.resize((px, px), Image.LANCZOS).save(os.path.join(d, f"{name}@{scale}x.png"))
        json.dump({"images": [{"filename": f"{name}@{s}x.png", "idiom": "universal", "scale": f"{s}x"}
                              for s in (1, 2, 3)],
                   "info": {"author": "xcode", "version": 1}},
                  open(os.path.join(d, "Contents.json"), "w"), indent=2)
    print(f"wrote {len(shots)} imagesets")

asyncio.run(main())
