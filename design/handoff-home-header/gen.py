"""Generates the artboards for the Home header band handoff. Run: python3 gen.py"""
import json, os
from PIL import Image

INK="#2E2622"; MUTED="#96877F"; MUTED_INK="#5F534A"; CARD_EDGE="#ECEAE6"
TILE="#FDF9F4"; TILE_RING="#EDE1D3"; CHECK_FILL="#F4F0EB"; CHECK_BORDER="#E6DFD7"; CHECK="#6FC79E"
COIN="#FFC24B"; COIN_BORDER="#E8A62E"; COIN_INK="#8A5F14"; PIP_OFF="#DDD3C4"
FLOOR="#E4EFD9"; PAGE_END="#D6DFCA"
FONT='ui-rounded, "SF Pro Rounded", -apple-system, system-ui, sans-serif'

STAR="M10 1.6l2.6 5.5 6 .7-4.4 4.1 1.2 5.9L10 14.9l-5.4 2.9 1.2-5.9L1.4 7.8l6-.7z"
def pips(level, size=13, gap=4):
    out=[]
    for i in range(1,4):
        on = i<=level
        fill = COIN if on else "none"; stroke = COIN_BORDER if on else PIP_OFF
        w = size*0.108 if on else size*0.138
        out.append(f'<svg width="{size}" height="{size}" viewBox="0 0 20 20" style="display:block"><path d="{STAR}" fill="{fill}" stroke="{stroke}" stroke-width="{w*20/size:.2f}" stroke-linejoin="round"></path></svg>')
    return f'<div style="display:flex;gap:{gap}px;align-items:center;flex-shrink:0">{"".join(out)}</div>'

def edit_pill(s=1.0):
    return (f'<div style="display:flex;align-items:center;justify-content:center;height:{30*s:.0f}px;padding:0 12px;'
            f'border-radius:999px;background:rgba(46,38,34,0.08);font-size:{13*s:.1f}px;font-weight:900;color:rgba(46,38,34,0.75);flex-shrink:0">Edit</div>')

def band(headline, level, words, quiet=None, s=1.0, plate=False, chip=False):
    """Direction A: eyebrow (pips + words) / headline + Edit / quiet line. plate=True draws today's band; chip=True the alternate."""
    eyebrow = (f'<div style="display:flex;align-items:center;gap:7px">{pips(level)}'
               f'<div style="font-size:{12.5*s:.1f}px;font-weight:900;color:{MUTED_INK};line-height:1.25">{words}</div></div>')
    if plate:
        eyebrow = (f'<div style="display:flex;align-items:center;gap:11px;padding:11px 14px;border-radius:18px;background:rgba(46,38,34,0.08)">'
                   f'{pips(level,17,5)}<div style="font-size:{12.5*s:.1f}px;font-weight:900;color:{INK}">{words}</div></div>')
    if chip:
        eyebrow = (f'<div style="display:flex"><div style="display:flex;align-items:center;gap:7px;padding:0 11px 0 9px;height:26px;border-radius:999px;background:rgba(46,38,34,0.08)">'
                   f'{pips(level)}<div style="font-size:{12.5*s:.1f}px;font-weight:900;color:{INK}">{words}</div></div></div>')
    goals = (f'<div style="display:flex;align-items:center;gap:9px">'
             f'<div style="font-size:{16*s:.1f}px;font-weight:900;color:{INK};line-height:1.2;flex-grow:1">{headline}</div>{edit_pill(s)}</div>')
    q = f'<div style="font-size:{12.5*s:.1f}px;font-weight:700;color:{MUTED};line-height:1.3">{quiet}</div>' if quiet else ''
    gap = 12 if plate else (8 if chip else 5)
    return (f'<div style="display:flex;flex-direction:column;gap:{gap}px;padding:12px 18px 10px 18px">'
            f'{eyebrow}<div style="display:flex;flex-direction:column;gap:4px">{goals}{q}</div></div>')

def coin(s=1.0):
    return (f'<div style="display:flex;align-items:center;gap:3px;flex-shrink:0">'
            f'<div style="width:{12*s:.0f}px;height:{12*s:.0f}px;border-radius:50%;background:{COIN};border:1.5px solid {COIN_BORDER}"></div></div>')

def row(title, sub, coins, done=False, icon="#F3B39A", s=1.0):
    box = (f'<div style="width:{26*s:.0f}px;height:{26*s:.0f}px;border-radius:50%;background:{CHECK if done else CHECK_FILL};border:1.5px solid {CHECK if done else CHECK_BORDER};display:flex;align-items:center;justify-content:center;flex-shrink:0">'
           + ('<svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 7.5l2.6 2.6L11 4.6" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"></path></svg>' if done else '') + '</div>')
    return (f'<div style="display:flex;align-items:center;gap:11px;padding:10px 13px;min-height:44px;background:#fff;border-radius:16px;border:1px solid {CARD_EDGE}">'
            f'<div style="width:{38*s:.0f}px;height:{38*s:.0f}px;border-radius:12px;background:{TILE};border:1px solid {TILE_RING};display:flex;align-items:center;justify-content:center;flex-shrink:0">'
            f'<div style="width:{18*s:.0f}px;height:{18*s:.0f}px;border-radius:5px;background:{icon}"></div></div>'
            f'<div style="display:flex;flex-direction:column;gap:2px;flex-grow:1;min-width:0">'
            f'<div style="font-size:{15.5*s:.1f}px;font-weight:900;color:{INK};line-height:1.2">{title}</div>'
            f'<div style="font-size:{12.5*s:.1f}px;font-weight:700;color:{MUTED};line-height:1.2">{sub}</div></div>'
            f'<div style="display:flex;align-items:center;gap:3px;flex-shrink:0">{coin(s)}<div style="font-size:{13*s:.1f}px;font-weight:900;color:{COIN_INK}">{coins}</div></div>{box}</div>')

def tomorrow(text, s=1.0):
    return (f'<div style="display:flex;align-items:center;gap:8px;padding:6px 18px 2px 18px">'
            f'<div style="font-size:{12.5*s:.1f}px;font-weight:700;color:{MUTED_INK};flex-grow:1">{text}</div>'
            f'<svg width="8" height="12" viewBox="0 0 8 12"><path d="M1.5 1.5L6 6l-4.5 4.5" fill="none" stroke="{MUTED}" stroke-width="1.8" stroke-linecap="round"></path></svg></div>')

def rows(items, s=1.0):
    return f'<div style="display:flex;flex-direction:column;gap:8px;padding:0 14px">{"".join(row(*it, s=s) for it in items)}</div>'

def page(inner, h, tank=None, floor_strip=0, w=402):
    top = (f'<img src="tank.jpg" style="display:block;width:{w}px;height:337px">' if tank else
           (f'<div style="height:{floor_strip}px;background:linear-gradient(#D0E6CD,{FLOOR})"></div>' if floor_strip else ''))
    return f'''<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <style>
    body {{ margin: 0; font-family: {FONT}; -webkit-font-smoothing: antialiased; }}
    a {{ color: #E4735F; }} a:hover {{ color: #C4523F; }}
  </style>
</helmet>
<div style="width:{w}px;height:{h}px;overflow:hidden;background:linear-gradient(180deg,{FLOOR} 0%,{FLOOR} 55%,{PAGE_END} 100%);display:flex;flex-direction:column">
{top}
{inner}
</div>
</x-dc>
</body>
</html>
'''

def tabbar():
    tabs=["Home","Focus","Play","Calendar","Friends"]
    t="".join(f'<div style="display:flex;flex-direction:column;align-items:center;gap:3px;width:50px"><div style="width:22px;height:18px;border-radius:5px;background:{"#FFE0DA" if i==0 else "#E9E1D6"}"></div><div style="font-size:9.5px;font-weight:900;color:{"#C24A3E" if i==0 else "#6E5F53"}">{n}</div></div>' for i,n in enumerate(tabs))
    return (f'<div style="margin-top:auto;padding:0 14px 28px 14px;display:flex;gap:8px;align-items:center">'
            f'<div style="flex-grow:1;display:flex;justify-content:space-around;align-items:center;height:62px;border-radius:31px;background:#FFFDF8;box-shadow:0 4px 14px rgba(46,38,34,0.10)">{t}</div>'
            f'<div style="width:62px;height:62px;border-radius:50%;background:#B9E3CF;border:3px solid #FFFDF8;box-shadow:0 4px 14px rgba(46,38,34,0.10);flex-shrink:0"></div></div>')

C_ROWS=[("Ch. 5 Problem Set","Physics 13 · due Thu 11:59 PM",30,True,"#8FB8E6"),("Essay outline","Writing 5 · due Thu 11:59 PM",30,False,"#E6B58F"),
        ("Read for one class","Study",20,True,"#F3B39A"),("Drink a glass of water","Life care",10,False,"#9ED1E8")]
A_ROWS=[("Read for one class","Study",20,False,"#F3B39A"),("Drink a glass of water","Life care",10,False,"#9ED1E8")]

boards = {
 # the deliverable in context: the normal evening
 "Main": page(band("2 goals left today",3,"Fully grown","From your laptop 2h ago.") + rows(C_ROWS) + tomorrow("Tomorrow: Bio quiz, Essay draft and 1 more") + tabbar(), 874, tank=True),
 # what ships today, same state, for the side-by-side
 "Today": page(band("2 goals left today",3,"Fully grown","From your laptop 2h ago.",plate=True) + rows(C_ROWS) + tomorrow("Tomorrow: Bio quiz, Essay draft and 1 more") + tabbar(), 874, tank=True),
 # the alternate: the words keep a plate, but one that hugs its content
 "AltChip": page(band("2 goals left today",3,"Fully grown","From your laptop 2h ago.",chip=True) + rows(C_ROWS) + tomorrow("Tomorrow: Bio quiz, Essay draft and 1 more") + tabbar(), 874, tank=True),
 # the five states, band only
 "StateA_NoCanvas": page(band("4 goals left today",2,"40 to the next") + rows(A_ROWS), 250, floor_strip=44),
 "StateB_Empty":    page(band("Nothing due today",3,"Fully grown","Last list from your laptop 2h ago.") + tomorrow("Tomorrow: Essay outline, Week 3 quiz and 2 more"), 250, floor_strip=44),
 "StateC_Evening":  page(band("2 goals left today",3,"Fully grown","From your laptop 2h ago.") + rows(C_ROWS[:2]), 250, floor_strip=44),
 "StateD_AllDone":  page(band("All goals done today",3,"Fully grown","From your laptop 2h ago.") + rows([(*C_ROWS[0][:3],True,C_ROWS[0][4]),(*C_ROWS[1][:3],True,C_ROWS[1][4])]), 250, floor_strip=44),
 "StateE_Day1":     page(band("7 goals left today",1,"Ready for the next star") + rows(A_ROWS), 250, floor_strip=44),
 "AXXL":            page(band("7 goals left today",1,"Ready for the next star","From your laptop 2h ago.",s=1.4) + rows(A_ROWS[:1],s=1.4), 300, floor_strip=44),
}
os.makedirs("artboards", exist_ok=True)
for name, html in boards.items():
    open(f"artboards/{name}.dc.html","w").write(html)

layout = {"artboards":[
  {"file":"Today.dc.html","x":0,"y":0,"w":402,"h":874,"title":"Today (ships now)"},
  {"file":"Main.dc.html","x":500,"y":0,"w":402,"h":874,"title":"A · Eyebrow (build this)"},
  {"file":"AltChip.dc.html","x":1000,"y":0,"w":402,"h":874,"title":"B · Chip (alternate)"},
  {"file":"StateA_NoCanvas.dc.html","x":0,"y":1020,"w":402,"h":250,"title":"a · no laptop paired"},
  {"file":"StateB_Empty.dc.html","x":500,"y":1020,"w":402,"h":250,"title":"b · empty day"},
  {"file":"StateC_Evening.dc.html","x":1000,"y":1020,"w":402,"h":250,"title":"c · normal evening"},
  {"file":"StateD_AllDone.dc.html","x":0,"y":1400,"w":402,"h":250,"title":"d · all done"},
  {"file":"StateE_Day1.dc.html","x":500,"y":1400,"w":402,"h":250,"title":"e · Day 1, one star"},
  {"file":"AXXL.dc.html","x":1000,"y":1400,"w":402,"h":300,"title":"accessibility XL"},
 ],
 "annotations":[
  {"id":"why","x":1500,"y":0,"w":300,"text":"The plate goes. It was a full-width tint carrying three pips and two words, and a plate says 'tap me' or 'meter' when it is neither. Finch, Headspace and Fabulous all put a plain headline row straight under the scene.\n\nA: pips + words become an eyebrow above the headline (Headspace's greeting-over-headline). 30pt shorter than today. Nothing shares a row, so XL only stacks.\n\nB: same, but the eyebrow keeps a plate that hugs its words. Pick if the green needs a foothold."},
  {"id":"calc","x":1500,"y":330,"w":300,"text":"Grade calculator: not drawn. It left Home on 2026-09-12 (Kin Card + Calendar's export menu), so the brief's first problem is already solved and the band gets no fourth element."},
 ],
 "launch":{"view":"canvas"}}
json.dump(layout, open("artboards/canvas.json","w"), indent=1)
print("wrote", len(boards), "artboards")
