import json, os
P = json.load(open('mascot-paths.json'))
VB = "0 0 1000 897.3"; ASPECT = 1.1145

T = dict(paper="#FAF5EC", card="#FFFFFF", ink="#2E2822", warm="#988D80", muted="#B4A996",
         inactive="#C9BEAC", hair="#F0E9DC", checkb="#E5DDD0",
         coral="#FF6F61", coralSoft="#FFE9E5", coralIcon="#FF8A7E",
         mint="#57C79B", mintSoft="#E3F6EE", mintDark="#2E8C68",
         coin="#FFC24B", coinB="#E8A62E", coinSoft="#FFF3D6", coinDark="#B07A1A",
         body="#51CFA0", belly="#B1EDD4", eye="#101820", blush="#FF9E94")

CROWN = ("M120 250 L96 92 L232 178 L330 40 L428 178 L564 92 L540 250 Z")

def mascot(w, level=3, face="faceIdle", color=None, belly=None, shadow=True, crown_ok=True):
    """Inline SVG of the real traced mascot. w = character width in px."""
    color = color or T["body"]; belly = belly or T["belly"]
    h = w / ASPECT
    sh = (f'<ellipse cx="500" cy="870.3" rx="460" ry="58.3" fill="{T["eye"]}" opacity="0.10"/>'
          if shadow else '')
    bl = ('<ellipse cx="195" cy="484.5" rx="55" ry="20.2" fill="%s" opacity="0.7"/>'
          '<ellipse cx="805" cy="484.5" rx="55" ry="20.2" fill="%s" opacity="0.7"/>' % (T["blush"], T["blush"])
          ) if level >= 2 else ''
    cr = (f'<g transform="translate(300 18) rotate(-12) scale(0.42)">'
          f'<path d="{CROWN}" fill="{T["coin"]}" stroke="{T["coinB"]}" stroke-width="26" '
          f'stroke-linejoin="round"/></g>') if (level >= 3 and crown_ok) else ''
    return (f'<svg viewBox="{VB}" width="{w:.0f}" height="{h:.0f}" style="display:block;overflow:visible">'
            f'{sh}<path d="{P["body"]}" fill="{color}"/><path d="{P["belly"]}" fill="{belly}"/>'
            f'<path d="{P[face]}" fill="{T["eye"]}"/>{bl}{cr}</svg>')

def avatar(size, level=1, face="faceIdle", color=None, belly=None, ring=None, ringw=3):
    color = color or T["body"]; belly = belly or T["belly"]
    inner = size * 1.34
    ringcss = f'border:{ringw}px solid {ring};' if ring else ''
    return (f'<div style="width:{size}px;height:{size}px;border-radius:999px;{ringcss}'
            f'background:{belly}8C;overflow:hidden;display:flex;align-items:flex-end;'
            f'justify-content:center;flex:none">'
            f'<div style="margin-bottom:-{inner*0.30:.0f}px">'
            f'{mascot(inner, level, face, color, belly, shadow=False, crown_ok=False)}</div></div>')

# ---------- shared chrome ----------
ICONS = {
 "house":'<path d="M3 10.5 12 3l9 7.5V21a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1z"/>',
 "clock":'<path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm1 5v5.6l3.8 2.2-1 1.7L11 13.7V7z"/>',
 "game":'<path d="M7 7h10a5 5 0 0 1 5 5v2a4 4 0 0 1-7.2 2.4L14 15h-4l-.8 1.4A4 4 0 0 1 2 14v-2a5 5 0 0 1 5-5zm-1 3v1.5H4.5V13H6v1.5h1.5V13H9v-1.5H7.5V10zm10 .5a1.2 1.2 0 1 0 0 2.4 1.2 1.2 0 0 0 0-2.4zm2.6 2.6a1.2 1.2 0 1 0 0 2.4 1.2 1.2 0 0 0 0-2.4z"/>',
 "book":'<path d="M4 4h6a3 3 0 0 1 2 .8V21a3 3 0 0 0-2-.8H4zm16 0h-6a3 3 0 0 0-2 .8V21a3 3 0 0 1 2-.8h6z"/>',
 "people":'<path d="M9 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zm7 0a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM2 20c0-3.3 3.1-5.5 7-5.5s7 2.2 7 5.5v1H2zm15.5-4.6c2.6.5 4.5 2.3 4.5 4.6v1h-4.4v-1c0-1.7-.7-3.2-1.8-4.3z"/>',
}
def icon(name, size, fill):
    return (f'<svg viewBox="0 0 24 24" width="{size}" height="{size}" fill="{fill}" '
            f'style="display:block">{ICONS[name]}</svg>')

def tabbar(active="house", avatar_ring="#FFFFFF"):
    items = []
    for n in ["house","clock","game","book","people"]:
        on = n == active
        bg = f'background:{T["coral"]};' if on else ''
        col = "#FFFFFF" if on else "rgba(255,255,255,.42)"
        items.append(f'<div style="width:44px;height:40px;border-radius:14px;{bg}display:flex;'
                     f'align-items:center;justify-content:center">{icon(n,19,col)}</div>')
    return (f'<div style="position:absolute;left:0;right:0;bottom:0;height:150px;pointer-events:none;'
            f'background:linear-gradient(to bottom,{T["paper"]}00,{T["paper"]}EB 55%,{T["paper"]})"></div>'
            f'<div style="position:absolute;left:16px;right:16px;bottom:30px;display:flex;gap:10px;'
            f'align-items:center">'
            f'<div style="display:flex;gap:2px;padding:8px;border-radius:999px;background:{T["ink"]};'
            f'box-shadow:0 8px 22px rgba(0,0,0,.22)">{"".join(items)}</div>'
            f'{avatar(56, 1, "faceIdle", ring=avatar_ring)}</div>')

def coin(size=18):
    return (f'<span style="width:{size}px;height:{size}px;border-radius:999px;background:{T["coin"]};'
            f'border:{max(1.5,size*0.14):.1f}px solid {T["coinB"]};display:inline-block;flex:none"></span>')

def pill(inner, pad="7px 14px"):
    return (f'<div style="display:flex;align-items:center;gap:6px;padding:{pad};border-radius:999px;'
            f'background:{T["card"]};box-shadow:0 2px 8px rgba(46,40,34,.08)">{inner}</div>')

def coinpill(n=1450):
    return pill(f'{coin(18)}<span style="font-weight:900;font-size:15px;color:{T["ink"]}">{n:,}</span>')

FONT = ("@import url('https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&display=swap');"
        "*{box-sizing:border-box}"
        "body{margin:0;font-family:Nunito,'SF Pro Rounded',system-ui,sans-serif;"
        f"background:{T['paper']};color:{T['ink']};-webkit-font-smoothing:antialiased}}"
        f"a{{color:{T['coral']};text-decoration:none}}a:hover{{color:#E2564A}}"
        ".card{background:#fff;border-radius:20px;box-shadow:0 2px 8px rgba(46,40,34,.05)}"
        ".h1{font-size:25px;font-weight:900;letter-spacing:-.3px}"
        ".h2{font-size:18px;font-weight:900}"
        ".meta{font-size:12px;font-weight:700;color:#988D80}")

def page(body, h=844, bg=None, pad_top=64):
    return (f'<div style="width:390px;height:{h}px;position:relative;overflow:hidden;'
            f'background:{bg or T["paper"]}">{body}</div>')

def doc(inner, w=390, h=844):
    return f'''<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <style>{FONT}</style>
</helmet>
{inner}
</x-dc>
<script data-dc-script data-props='{{"$preview":{{"width":{w},"height":{h}}}}}'>
class Component extends DCLogic {{}}
</script>
</body>
</html>
'''

def write(name, inner, w=390, h=844):
    open(name, 'w').write(doc(inner, w, h))
    print("wrote", name, w, "x", h)
