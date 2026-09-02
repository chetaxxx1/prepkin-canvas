"""Render Sprout (coat x evo) to transparent PNGs from the bundled web build."""
import asyncio, os, subprocess, sys, time
from PIL import Image
from playwright.async_api import async_playwright

WEB = "/Users/georgeshi/Desktop/app/prepkin-canvas/ios/SproutWeb"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
COATS = ["mint", "sky", "peach", "lilac", "butter", "coral"]
EVOS = ["1", "2", "3"]
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
            page = await ctx.new_page()
            for coat in COATS:
                for evo in EVOS:
                    url = f"http://127.0.0.1:8765/index.html?embed=1&coat={coat}&evo={evo}"
                    await page.goto(url)
                    await page.wait_for_function("() => !!window.RiverSprite", timeout=15000)
                    await page.wait_for_timeout(900)
                    path = os.path.join(OUT, f"sprout-{coat}-{evo}.png")
                    await page.screenshot(path=path, omit_background=True, full_page=False)
                    print("captured", path)
            await browser.close()
    finally:
        server.terminate()

    # Uniform crop: union bbox over every capture so relative sizes survive.
    boxes = []
    for f in os.listdir(OUT):
        if f.endswith(".png") and f.startswith("sprout-"):
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
        if not (f.endswith(".png") and f.startswith("sprout-")): continue
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

asyncio.run(main())
