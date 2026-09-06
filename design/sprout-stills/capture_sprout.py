"""Render Sprout (look x coat x evo) to transparent PNGs from the bundled web build.

Every look is captured in the same run so the union crop below covers all of
them: a kin that changes its look must not change size on screen."""
import asyncio, os, subprocess, sys, time
from PIL import Image
from playwright.async_api import async_playwright

WEB = "/Users/georgeshi/Desktop/app/prepkin-canvas/ios/SproutWeb"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
COATS = ["mint", "sky", "peach", "lilac", "butter", "coral"]
EVOS = ["1", "2", "3"]
# "classic" is the plain name; every other look gets its id in the file name.
LOOKS = ["classic", "ninja"]
BOX = 320      # CSS px, square viewport; character fits width at evo 3
SCALE = 3

async def main():
    os.makedirs(OUT, exist_ok=True)
    server = subprocess.Popen([sys.executable, "-m", "http.server", "8765", "--bind", "127.0.0.1"],
                              cwd=WEB, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.8)
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(channel="chrome")
            ctx = await browser.new_context(viewport={"width": BOX, "height": BOX},
                                            device_scale_factor=SCALE)
            # The puppet picks a random breathing phase on load (`bob` in sprite.ts)
            # and keeps advancing while the page settles, so the same URL used to
            # screenshot at a different point of the breath every run. That moved the
            # union bbox below by up to 20 CSS px, which moved the crop, the size
            # ladder and heightRatio with it. Zero the clock and the phase and every
            # capture is the rest pose, identical run to run.
            await ctx.add_init_script(
                "Math.random = () => 0;"
                "performance.now = () => 0;"
                "const raf = window.requestAnimationFrame.bind(window);"
                "window.requestAnimationFrame = (cb) => raf(() => cb(0));")
            page = await ctx.new_page()
            # Sprout: every look x coat. The edge-lane types have no looks and only
            # the coats the catalogue sells (orca is fixed charcoal, coat = belly).
            jobs = [("sprout", look, coat) for look in LOOKS for coat in COATS]
            jobs += [("orca", "classic", "sky"), ("axolotl", "classic", "lilac"), ("axolotl", "classic", "coral")]
            for kind, look, coat in jobs:
                tag = "" if look == "classic" else f"{look}-"
                for evo in EVOS:
                    # radius 75 puts the stage-3 drawing (1320 art units wide) inside the box with a margin
                    url = (f"http://127.0.0.1:8765/index.html?embed=1&type={kind}&skin={look}"
                           f"&coat={coat}&evo={evo}&radius=75")
                    await page.goto(url)
                    await page.wait_for_function("() => !!window.RiverSprite", timeout=15000)
                    await page.wait_for_timeout(900)
                    # Motes drift at random, so leaving the effects canvas in
                    # makes the union crop below different on every run — and
                    # a frozen sparkle in a random spot is not part of the look.
                    await page.add_style_tag(content="#fx{display:none}")
                    path = os.path.join(OUT, f"{kind}-{tag}{coat}-{evo}.png")
                    await page.screenshot(path=path, omit_background=True, full_page=False)
                    print("captured", path)
            await browser.close()
    finally:
        server.terminate()

    # Uniform crop: union bbox over every capture so relative sizes survive.
    boxes = []
    KINDS = ("sprout-", "orca-", "axolotl-")
    for f in os.listdir(OUT):
        if f.endswith(".png") and f.startswith(KINDS):
            im = Image.open(os.path.join(OUT, f))
            bb = im.getbbox()
            if bb: boxes.append(bb)
    l = min(b[0] for b in boxes); t = min(b[1] for b in boxes)
    r = max(b[2] for b in boxes); btm = max(b[3] for b in boxes)
    print("union bbox", (l, t, r, btm), "of", BOX * SCALE)
    w, h = r - l, btm - t
    # Square-ish: pad width to be at least height so frames are predictable.
    side = max(w, h)
    for f in os.listdir(OUT):
        if not (f.endswith(".png") and f.startswith(KINDS)): continue
        src = os.path.join(OUT, f)
        im = Image.open(src).convert("RGBA")
        crop = im.crop((l, t, r, btm))
        canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        # Bottom-anchor, centred horizontally.
        canvas.paste(crop, ((side - w) // 2, side - h))
        base = f[:-4]
        for s in (1, 2, 3):
            px = round(side * s / 3)
            canvas.resize((px, px), Image.LANCZOS).save(os.path.join(OUT, f"{base}@{s}x.png"))
        os.remove(src)
    print("done, box side @3x =", side)
    print(f"SproutImage.heightRatio = {h / side:.3f}   (drawn height / box)")

asyncio.run(main())
