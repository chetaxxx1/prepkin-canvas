#!/usr/bin/env python3
"""Build design/icons/index.html — the sign-off sheet for the icon set.

Shows every icon at the two sizes it actually ships at, plus a task row, so a
judgement is made at 44pt rather than at a flattering blow-up.

Run:  python3 design/icons/sheet.py
"""
import os, sys, base64, html, io
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import icons as M

PNG = os.path.join(HERE, "png")


def uri(name, px=112):
    """96-128px is plenty for a review page; the 512s would make it a 7MB file."""
    im = Image.open(os.path.join(PNG, name + ".png")).convert("RGBA")
    im.thumbnail((px, px), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "PNG", optimize=True)
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


_cache = {}


def once(name):
    if name not in _cache:
        _cache[name] = uri(name)
    return _cache[name]


def main():
    cards, cur = [], None
    for name, label, group, tint, _, _ in M.SET:
        if group != cur:
            cards.append(f'<h2 class="grp">{group}s</h2><div class="grid">' if cur is None
                         else f'</div><h2 class="grp">{group}s</h2><div class="grid">')
            cur = group
        cards.append(f'''<figure>
  <div class="tiles">
    <span class="tile t44" style="--t:{M.TINT[tint]};--td:{M.TINT_DARK[tint]}"><img src="{once(name)}" alt=""></span>
    <span class="tile t52" style="--t:{M.TINT[tint]};--td:{M.TINT_DARK[tint]}"><img src="{once(name)}" alt=""></span>
    <img class="bare" src="{once(name)}" alt="">
  </div>
  <figcaption>{html.escape(label)}<small>{name} · {tint}</small></figcaption>
</figure>''')
    cards.append("</div>")

    rows = []
    for name, label, group, tint, _, _ in M.SET[:6]:
        rows.append(f'''<div class="row">
  <span class="tile t44" style="--t:{M.TINT[tint]};--td:{M.TINT_DARK[tint]}"><img src="{once(name)}" alt=""></span>
  <span class="g"><b>{html.escape(label)} task goes here</b><i>{group}</i></span>
  <span class="rw">10</span><span class="cb"></span>
</div>''')

    open(os.path.join(HERE, "index.html"), "w").write(
        PAGE.replace("{{CARDS}}", "\n".join(cards))
            .replace("{{ROWS}}", "\n".join(rows))
            .replace("{{N}}", str(len(M.SET))))
    print("index.html written")


PAGE = """<title>Prepkin Icon Set</title>
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@600;700;800;900&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
:root{--bg:#F4F2EE;--panel:#fff;--edge:#E4DFD7;--ink:#2E2622;--ink2:#6B5D55;--muted:#95867D;--tile:var(--t)}
@media (prefers-color-scheme:dark){:root:not([data-theme="light"]){--bg:#151210;--panel:#201B17;--edge:#372F29;--ink:#F3EDE6;--ink2:#C4B7AD;--muted:#9B8D84;--tile:var(--td)}}
:root[data-theme="dark"]{--bg:#151210;--panel:#201B17;--edge:#372F29;--ink:#F3EDE6;--ink2:#C4B7AD;--muted:#9B8D84;--tile:var(--td)}
*{box-sizing:border-box}
body{background:var(--bg);color:var(--ink);font-family:'Nunito',ui-rounded,-apple-system,sans-serif;font-weight:700}
.wrap{max-width:1080px;margin:0 auto;padding:0 clamp(20px,4vw,44px) 90px}
h1{font-size:clamp(30px,5vw,46px);font-weight:900;letter-spacing:-.03em;margin:0;line-height:1.05}
.eyebrow{font-family:'IBM Plex Mono',monospace;font-size:11px;font-weight:500;letter-spacing:.14em;text-transform:uppercase;color:var(--muted)}
header{padding:60px 0 34px;display:grid;gap:14px}
.lede{font-size:16px;color:var(--ink2);max-width:60ch;line-height:1.6;font-weight:600}
.grp{font-size:13px;font-family:'IBM Plex Mono',monospace;font-weight:500;letter-spacing:.12em;text-transform:uppercase;color:var(--muted);margin:44px 0 16px;padding-bottom:9px;border-bottom:1px solid var(--edge)}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(178px,1fr));gap:12px}
figure{margin:0;background:var(--panel);border:1px solid var(--edge);border-radius:18px;padding:16px 16px 14px;display:grid;gap:13px}
.tiles{display:flex;align-items:center;gap:11px}
.tile{background:var(--tile);display:grid;place-items:center;flex:0 0 auto}
.t44{width:44px;height:44px;border-radius:14px}
.t44 img{width:27px;height:27px}
.t52{width:52px;height:52px;border-radius:17px}
.t52 img{width:32px;height:32px}
img{display:block}
.bare{width:30px;height:30px}
figcaption{font-size:13.5px;font-weight:800;line-height:1.3}
figcaption small{display:block;font-family:'IBM Plex Mono',monospace;font-size:10.5px;font-weight:400;color:var(--muted);margin-top:3px}
.demo{background:var(--panel);border:1px solid var(--edge);border-radius:22px;padding:14px;display:grid;gap:9px;max-width:400px}
.row{display:flex;align-items:center;gap:11px;background:var(--bg);border:1px solid var(--edge);border-radius:20px;padding:9px 12px 9px 9px}
.g{flex:1 1 auto;min-width:0;display:grid}
.g b{font-size:14px;font-weight:800;line-height:1.25}
.g i{font-style:normal;font-size:11.5px;font-weight:700;color:var(--muted);margin-top:1px}
.rw{font-size:12px;font-weight:800;color:#A8761D;background:#FFF3D6;border-radius:999px;padding:3px 9px}
.cb{width:22px;height:22px;border-radius:8px;border:1.5px solid var(--edge);background:var(--bg);flex:0 0 auto}
.note{margin-top:18px;font-size:13.5px;color:var(--muted);line-height:1.6;font-weight:600;max-width:64ch}
.note b{color:var(--ink2);font-weight:800}
.rules{display:grid;grid-template-columns:repeat(auto-fit,minmax(215px,1fr));gap:12px;margin-top:22px}
.rules div{background:var(--panel);border:1px solid var(--edge);border-radius:16px;padding:15px 16px}
.rules h3{margin:0 0 5px;font-size:14px;font-weight:900}
.rules p{margin:0;font-size:13px;color:var(--ink2);line-height:1.5;font-weight:600}
</style>
<div class="wrap">
<header>
  <div class="eyebrow">Prepkin iOS · icon set v1 · {{N}} icons · flat vector</div>
  <h1>One set, one family,<br>six tints.</h1>
  <p class="lede">Every content icon in the app. Cut from a handful of generated sheets so the whole family shares a light source, a palette and an optical size, then normalised by ink area so no tile looks heavier than the one beside it. The flat black Learn glyphs are gone — a track tile and a task row now draw from the same set.</p>
</header>

<div class="rules">
  <div><h3>Objects, never symbols</h3><p>A pencil, not a document. If it is a thing you could pick up, it is drawn as one.</p></div>
  <div><h3>Cut a sheet at a time</h3><p>Style locks inside one generated image, so icons are always made a sheetful at a time against the same reference.</p></div>
  <div><h3>Six tints, fixed</h3><p>The tile takes the object's hue family. An icon does not get to invent a seventh colour.</p></div>
  <div><h3>Even by ink, not by box</h3><p>A thin diagonal pencil and a round apple are matched on painted area, which is what the eye actually measures.</p></div>
</div>

<h2 class="grp">In a task row, at real size</h2>
<div class="demo">{{ROWS}}</div>
<p class="note">This is the size that matters. If an icon does not read here at a glance it fails, however good the blow&#8209;up looks.</p>

{{CARDS}}

<p class="note" style="margin-top:40px"><b>What is not in here.</b> The six tab-bar icons and the mascot chip are untouched — they already agree with each other. Redrawing them is a separate call.</p>
</div>
"""

if __name__ == "__main__":
    main()
