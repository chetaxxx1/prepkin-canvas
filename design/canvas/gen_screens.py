exec(open('gen.py').read())
import base64

def img(fn):
    return base64.b64encode(open(fn,'rb').read()).decode()

# ═══════════ 1. HOME ═══════════
def task_row(title, meta, reward, kind="school", done=False):
    tile_bg = T["coralSoft"] if kind=="school" else T["mintSoft"]
    tile_fg = T["coralIcon"] if kind=="school" else T["mint"]
    glyph = ('<path d="M4 4h6a3 3 0 0 1 2 .8V21a3 3 0 0 0-2-.8H4zm16 0h-6a3 3 0 0 0-2 .8V21a3 3 0 0 1 2-.8h6z"/>'
             if kind=="school" else
             '<path d="M12 21s-8-4.8-8-10.2A4.8 4.8 0 0 1 12 7a4.8 4.8 0 0 1 8 3.8C20 16.2 12 21 12 21z"/>')
    check = (f'<div style="width:30px;height:30px;border-radius:999px;background:{T["mint"]};display:flex;'
             f'align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(87,199,155,.4);flex:none">'
             f'<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="#fff" stroke-width="3.4" '
             f'stroke-linecap="round" stroke-linejoin="round"><path d="M5 13l4 4L19 7"/></svg></div>'
             if done else
             f'<div style="width:30px;height:30px;border-radius:999px;background:{T["paper"]};'
             f'border:2.5px solid {T["checkb"]};flex:none"></div>')
    strike = "text-decoration:line-through;" if done else ""
    return (f'<div class="card" style="display:flex;align-items:center;gap:12px;padding:12px 16px;'
            f'opacity:{0.65 if done else 1}">'
            f'<div style="width:40px;height:40px;border-radius:14px;background:{tile_bg};display:flex;'
            f'align-items:center;justify-content:center;flex:none">'
            f'<svg viewBox="0 0 24 24" width="18" height="18" fill="{tile_fg}">{glyph}</svg></div>'
            f'<div style="flex:1;min-width:0">'
            f'<div style="font-size:15px;font-weight:800;{strike}white-space:nowrap;overflow:hidden;'
            f'text-overflow:ellipsis">{title}</div>'
            f'<div style="display:flex;align-items:center;gap:4px;margin-top:3px;white-space:nowrap;'
            f'overflow:hidden">{coin(11)}'
            f'<span style="font-size:12px;font-weight:800;color:{T["coinDark"]}">+{reward}</span>'
            f'<span class="meta" style="overflow:hidden;text-overflow:ellipsis">· {meta}</span></div></div>'
            f'{check}</div>')

home = page(
  f'<div style="position:absolute;top:0;left:0;right:0;height:370px;overflow:hidden;'
  f'border-radius:0 0 30px 30px">'
  f'<img src="scene-hero.jpg" style="position:absolute;bottom:0;left:0;width:390px;height:390px;'
  f'object-fit:cover">'
  f'<div style="position:absolute;inset:0;background:radial-gradient(circle at 50% 80%,'
  f'rgba(255,255,255,.28),transparent 62%)"></div>'
  f'<div style="position:absolute;top:64px;left:24px;right:24px;display:flex;'
  f'justify-content:space-between;align-items:flex-start">'
  + pill(f'<span style="font-weight:900;font-size:14px">Slime</span>'
         f'<span style="font-size:11.5px;font-weight:900;color:{T["mint"]};background:{T["mintSoft"]};'
         f'padding:2px 8px;border-radius:999px">Lv 3</span>')
  + coinpill(1450) +
  f'</div>'
  f'<div style="position:absolute;bottom:10px;left:0;right:0;display:flex;flex-direction:column;'
  f'align-items:center;gap:10px">'
  f'<div style="background:#fff;border-radius:16px;padding:9px 16px;font-size:14px;font-weight:700;'
  f'box-shadow:0 3px 10px rgba(46,40,34,.12)">Slime is cheering you on — 3 to go!</div>'
  f'{mascot(182, 3, "faceIdle")}</div></div>'

  f'<div style="position:absolute;top:388px;left:0;right:0;padding:0 24px;display:flex;'
  f'justify-content:space-between;align-items:baseline">'
  f'<span class="h2">Today</span><span style="font-size:13px;font-weight:700;color:{T["warm"]}">2 of 5 done</span></div>'

  f'<div style="position:absolute;top:424px;left:20px;right:20px;display:flex;flex-direction:column;gap:8px">'
  + task_row("Ch. 5 Problem Set", "AP Physics · due Fri 11:59 PM · from Canvas", 30, "school", True)
  + task_row("Essay outline", "English 11 · due Sat 8:59 AM · from Canvas", 30, "school")
  + task_row("Unit 3 quiz", "APUSH · due Sun 3:59 PM · from Canvas", 30, "school")
  + task_row("20 min SAT practice", "Study", 20, "school")
  + task_row("Drink a glass of water", "Life care", 10, "life")
  + f'</div>'
  + tabbar("house"))
write("Main.dc.html", home)
