"""Stage III full costumes, one per kin. Capture clean stage-II bases from the live build, then ask
Gemini to dress each one, with the Ninja still as the quality bar."""
import asyncio, os, subprocess, sys, time
from playwright.async_api import async_playwright
from PIL import Image, ImageDraw, ImageFont

WEB = "/Users/georgeshi/Downloads/Sprout-handoff/dist"
S = "/private/tmp/claude-501/-Users-georgeshi-Desktop-app-prepkin-canvas/4a1ab280-f061-4265-84b5-2bcf38bb8d53/scratchpad"
OUT = f"{S}/costumes"; os.makedirs(OUT, exist_ok=True)
PY = os.path.expanduser("~/.claude/skills/nano-banana/.venv/bin/python")
GEN = os.path.expanduser("~/.claude/skills/nano-banana/scripts/genimage.py")

KINS = [
  ("moss",    "coat=mint",  "Moss · mint",   "Reads everything twice. Scholar.",
   "a full scholar-mage costume: a deep forest-green hooded cloak with the hood down around the shoulders, a leather satchel strap across the chest with a small brass buckle, round wire glasses, a tiny rolled scroll tucked in the strap"),
  ("ember",   "coat=coral&skin=ninja", "Ember · coral", "Fast, quiet, done before you notice. Ninja.", None),
  ("droplet", "coat=sky",   "Droplet · sky", "Lo-fi, do not disturb. Hoodie kid.",
   "a full streetwear costume: an oversized heather-grey hoodie with the hood up around the head and white drawstrings, big over-ear headphones in matte black worn over the hood, a tiny enamel pin on the chest"),
  ("sprout",  "coat=peach", "Sprout · peach", "Brings the snacks. Baker.",
   "a full baker costume: a cream apron with a front pocket tied at the waist, a rolled red-checked bandana around the head, rolled-up sleeves on the fins, a small flour smudge on the cheek, a wooden spoon tucked in the apron pocket"),
  ("wisp",    "coat=lilac", "Wisp · lilac", "Night owl. Astronaut.",
   "a full astronaut costume: a white space suit with soft grey panels and a small mission patch, a chunky helmet collar ring around the neck with the helmet off, a tiny star badge, the tuft poking out the top. The suit ends at the rounded bottom of the body exactly like the ninja suit does: NO legs, NO boots, NO feet, the character has none"),
  ("comet",   "coat=butter", "Comet · butter", "Competitive, loudly. Racer.",
   "a full racing-driver costume: a fitted racing jacket in navy and white with a bold number 7 on the chest and sponsor-style stripes on the fins, racing goggles pushed up on the head with a black strap"),
  ("orca",    "type=orca&coat=sky", "Orca", "Too cool for this. Biker.",
   "a full biker costume: a black leather jacket with a silver zip and lapels and small studs on the shoulders, a white t-shirt showing under it, dark aviator sunglasses resting on the face over the half-closed eyes, the dorsal fin poking out the top"),
  ("axel",    "type=axolotl&coat=lilac", "Axel · lilac axolotl", "Unbothered. Pajamas.",
   "a full pajama costume: an oversized pale-cream pajama onesie with small lilac star print, the hood down, a slightly-too-long sleeve on each fin, a tiny mug of cocoa held in one fin, the pink gill fronds poking out around the head"),
]

STYLE = ("Keep the character EXACTLY as drawn in the first image: the same pear body, face, eyes, mouth, fins, colours and white sticker rim. "
         "Add ONLY the costume described, drawn in the same flat vector style: smooth shapes, no outlines except the soft white rim, matte colours, a few fabric folds, one small highlight. "
         "Match the craft and detail level of the ninja in the second image, which is our quality bar. "
         "The costume must fit the pear body and the fins, worn naturally, not floating. Front facing, centered, plain flat background #F6F4EE, no text, no props on the ground.")

async def capture():
    server = subprocess.Popen([sys.executable, "-m", "http.server", "8772", "--bind", "127.0.0.1"], cwd=WEB, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.8)
    try:
        async with async_playwright() as p:
            b = await p.chromium.launch(channel="chrome")
            page = await (await b.new_context(viewport={"width": 320, "height": 320}, device_scale_factor=3)).new_page()
            for key, q, *_ in KINS:
                await page.goto(f"http://127.0.0.1:8772/index.html?embed=1&{q}&evo=2&radius=75")
                await page.wait_for_function("() => !!window.RiverSprite", timeout=15000)
                await page.wait_for_timeout(900)
                await page.add_style_tag(content="#fx{display:none}")
                await page.screenshot(path=f"{OUT}/base-{key}.png", omit_background=False)
            await b.close()
    finally:
        server.terminate()

def generate():
    ninja = f"{OUT}/base-ember.png"
    for key, _, _, _, costume in KINS:
        if not costume:
            continue
        out = f"{OUT}/costume-{key}.png"
        if os.path.exists(out):
            continue
        r = subprocess.run([PY, GEN, "--prompt", f"Dress this character in {costume}. {STYLE}", "--aspect-ratio", "1:1",
                            "--output", out, "--images", f"{OUT}/base-{key}.png", ninja], capture_output=True, text=True)
        print(key, "ok" if os.path.exists(out) else r.stdout[-300:] + r.stderr[-300:])

def sheet():
    C, cap = 460, 96
    im0 = Image.new("RGB", (C * 3, (C + cap) * 3), (246, 244, 238)); d = ImageDraw.Draw(im0)
    try:
        f1 = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 27)
        f2 = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 22)
    except Exception: f1 = f2 = ImageFont.load_default()
    for i, (key, _, title, line, costume) in enumerate(KINS):
        path = f"{OUT}/costume-{key}.png" if costume else f"{OUT}/base-{key}.png"
        im = Image.open(path).convert("RGB")
        if not costume:
            im = im.crop((0, int(im.height * 0.3), im.width, im.height))
            im = im.resize((C, int(C * im.height / im.width)))
        else:
            im = im.resize((C, C), Image.LANCZOS)
        x, y = (i % 3) * C, (i // 3) * (C + cap)
        im0.paste(im, (x, y + (C - im.height) // 2))
        d.text((x + 14, y + C + 8), title, fill=(30, 40, 40), font=f1); d.text((x + 14, y + C + 46), line, fill=(100, 110, 108), font=f2)
    im0.save(f"{S}/costumes.png"); print("sheet ok")

if __name__ == "__main__":
    step = sys.argv[1] if len(sys.argv) > 1 else "all"
    if step in ("capture", "all"): asyncio.run(capture())
    if step in ("gen", "all"): generate()
    if step in ("sheet", "all"): sheet()
