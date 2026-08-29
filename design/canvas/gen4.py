exec(open('gen.py').read())
def header(title, coins=1450):
    return (f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;'
            f'justify-content:space-between;align-items:center">'
            f'<span class="h1">{title}</span>{coinpill(coins)}</div>')

# ═══════════ 6. LEARN ═══════════
GL = {
 "money":'<path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm.9 15.4v1.3h-1.6v-1.3c-1.6-.2-2.8-1.1-3-2.7h1.9c.1.8.8 1.3 1.9 1.3 1 0 1.7-.4 1.7-1.1 0-.6-.4-.9-1.7-1.2l-1.1-.3c-1.7-.4-2.6-1.3-2.6-2.7 0-1.5 1.1-2.5 2.9-2.7V6.4h1.6v1.6c1.6.2 2.7 1.2 2.8 2.7h-1.9c-.1-.7-.7-1.2-1.7-1.2-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.6 1.2l1.1.2c1.8.4 2.7 1.2 2.7 2.7 0 1.6-1.1 2.5-3 2.7z"/>',
 "column":'<path d="M12 2 3 6.5V8h18V6.5zM5 10v8H3v2h18v-2h-2v-8h-2v8h-3v-8h-2v8H8v-8z"/>',
 "brain":'<path d="M9 2a4 4 0 0 0-4 4 3.5 3.5 0 0 0-1 6.8V15a4 4 0 0 0 4 4h1V2zm6 0v17h1a4 4 0 0 0 4-4v-2.2A3.5 3.5 0 0 0 19 6a4 4 0 0 0-4-4zM8 20v2h8v-2z"/>',
}
def lesson_row(glyph, title, sub, done=False, tint=("#FFF3D6","#B07A1A")):
    right = (f'<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="{T["mint"]}" '
             f'stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 13l4 4L19 7"/></svg>'
             if done else
             f'<div style="display:flex;align-items:center;gap:4px">{coin(13)}'
             f'<span style="font-size:13px;font-weight:900;color:{T["coinDark"]}">+20</span></div>')
    return (f'<div class="card" style="padding:13px 16px;display:flex;align-items:center;gap:13px;'
            f'opacity:{0.7 if done else 1}">'
            f'<div style="width:40px;height:40px;border-radius:14px;background:{tint[0]};display:flex;'
            f'align-items:center;justify-content:center;flex:none">'
            f'<svg viewBox="0 0 24 24" width="19" height="19" fill="{tint[1]}">{GL[glyph]}</svg></div>'
            f'<div style="flex:1;min-width:0"><div style="font-size:15px;font-weight:800">{title}</div>'
            f'<div class="meta" style="margin-top:2px">{sub}</div></div>{right}</div>')

def track(name, rows):
    return (f'<div style="margin-bottom:20px"><div style="font-size:13px;font-weight:900;'
            f'color:{T["warm"]};letter-spacing:.6px;margin-bottom:9px">{name.upper()}</div>'
            f'<div style="display:flex;flex-direction:column;gap:8px">{"".join(rows)}</div></div>')

learn = page(
  header("Learn")
  + f'<div style="position:absolute;top:112px;left:20px;right:20px">'
  + track("Personal finance", [
      lesson_row("money","Why compound interest wins","4 cards · 2 min",True),
      lesson_row("money","Your first budget in 4 lines","4 cards · 2 min")])
  + track("Philosophy", [
      lesson_row("column","Stoicism: control what you can","4 cards · 2 min",tint=("#EAE6F8","#6B5CA5")),
      lesson_row("column","The Socratic method","3 cards · 2 min",tint=("#EAE6F8","#6B5CA5"))])
  + track("Study skills", [
      lesson_row("brain","Spaced practice beats cramming","3 cards · 2 min",tint=("#E3F6EE","#2E8C68"))])
  + f'</div>'
  + tabbar("book"), h=880)
write("Learn.dc.html", learn, h=880)

# ═══════════ 7. LESSON PLAYER ═══════════
dots = ''.join(f'<div style="width:{"22" if i==1 else "7"}px;height:7px;border-radius:999px;'
               f'background:{T["coral"] if i==1 else T["checkb"]}"></div>' for i in range(4))
lesson = page(
  f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;align-items:center;gap:14px">'
  f'<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="{T["ink"]}" stroke-width="3" '
  f'stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>'
  f'<span style="font-size:16px;font-weight:900;flex:1">Why compound interest wins</span></div>'
  + f'<div class="card" style="position:absolute;top:128px;left:24px;right:24px;padding:32px 28px;'
    f'border-radius:28px;min-height:400px;display:flex;flex-direction:column;align-items:center;'
    f'justify-content:center;text-align:center;gap:22px">'
    f'<div style="width:66px;height:66px;border-radius:22px;background:{T["coinSoft"]};display:flex;'
    f'align-items:center;justify-content:center">'
    f'<svg viewBox="0 0 24 24" width="32" height="32" fill="{T["coinDark"]}">{GL["money"]}</svg></div>'
    f'<div style="font-size:22px;font-weight:900;line-height:1.35;text-wrap:pretty">'
    f'You earn interest on your interest.</div>'
    f'<div style="font-size:16px;font-weight:700;color:{T["warm"]};line-height:1.6;text-wrap:pretty">'
    f'$1,000 at 8%. Year one you earn $80. Year two you earn $86 — because the $80 is earning too.</div></div>'
  + f'<div style="position:absolute;top:568px;left:0;right:0;display:flex;justify-content:center;gap:6px">{dots}</div>'
  + f'<div style="position:absolute;left:24px;right:24px;bottom:64px;display:flex;flex-direction:column;'
    f'align-items:center;gap:12px">'
    f'<div style="background:{T["coral"]};border-radius:22px;padding:17px;width:100%;text-align:center;'
    f'color:#fff;font-size:17px;font-weight:900;box-shadow:0 6px 16px rgba(255,111,97,.35);'
    f'display:flex;align-items:center;justify-content:center;gap:8px">Finish {coin(17)} +20 coins</div>'
    f'<div class="meta">Card 2 of 4</div></div>')
write("LessonPlayer.dc.html", lesson)
