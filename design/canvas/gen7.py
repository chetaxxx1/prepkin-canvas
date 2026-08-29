exec(open('gen.py').read())
def header(title, coins=1450):
    return (f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;'
            f'justify-content:space-between;align-items:center">'
            f'<span class="h1">{title}</span>{coinpill(coins)}</div>')

# ═══════════ 11. GRADE CALCULATOR ═══════════
def slider(label, value, pct, suffix="%"):
    return (f'<div style="margin-bottom:26px">'
            f'<div style="display:flex;justify-content:space-between;align-items:baseline;margin-bottom:10px">'
            f'<span style="font-size:15px;font-weight:800;color:{T["warm"]}">{label}</span>'
            f'<span style="font-size:24px;font-weight:900;font-variant-numeric:tabular-nums">{value}'
            f'<span style="font-size:15px;color:{T["muted"]}">{suffix}</span></span></div>'
            f'<div style="position:relative;height:10px;border-radius:999px;background:{T["hair"]}">'
            f'<div style="position:absolute;left:0;top:0;bottom:0;width:{pct}%;border-radius:999px;'
            f'background:{T["coral"]}"></div>'
            f'<div style="position:absolute;left:calc({pct}% - 13px);top:-8px;width:26px;height:26px;'
            f'border-radius:999px;background:#fff;box-shadow:0 2px 8px rgba(46,40,34,.22)"></div></div></div>')

grade = page(
  f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;align-items:center;gap:14px">'
  f'<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="{T["ink"]}" stroke-width="3" '
  f'stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>'
  f'<span class="h1" style="font-size:21px">Grade calculator</span></div>'
  + f'<div class="card" style="position:absolute;top:120px;left:20px;right:20px;padding:24px 20px 4px;'
    f'border-radius:24px">'
  + slider("Current grade", 88, 88)
  + slider("Grade I want", 90, 90)
  + slider("Final is worth", 20, 20, "% of grade")
  + f'</div>'
  + f'<div class="card" style="position:absolute;top:470px;left:20px;right:20px;padding:28px 24px;'
    f'border-radius:24px;text-align:center">'
    f'<div style="font-size:15px;font-weight:800;color:{T["warm"]}">You need</div>'
    f'<div style="font-size:64px;font-weight:900;letter-spacing:-2.5px;line-height:1.1;margin:6px 0 4px;'
    f'font-variant-numeric:tabular-nums">98.0<span style="font-size:36px">%</span></div>'
    f'<div style="font-size:15px;font-weight:800;color:{T["warm"]};line-height:1.5;text-wrap:pretty">'
    f'Tough but possible.</div></div>'
  + f'<div class="card" style="position:absolute;top:672px;left:20px;right:20px;padding:16px;'
    f'display:flex;gap:12px;align-items:center;background:{T["mintSoft"]};box-shadow:none">'
    f'<div style="flex:none">{mascot(52,1,"faceJudging",shadow=False)}</div>'
    f'<div style="font-size:13px;font-weight:700;color:{T["mintDark"]};line-height:1.5;text-wrap:pretty">'
    f'That is the test\'s math, not a verdict on you. Put the hours in and see.</div></div>')
write("GradeCalc.dc.html", grade)

# ═══════════ 12. WEEKLY SUMMARY ═══════════
def stat(n, label, tint):
    return (f'<div style="flex:1;text-align:center;padding:14px 4px;border-radius:18px;background:{tint}">'
            f'<div style="font-size:26px;font-weight:900;line-height:1;font-variant-numeric:tabular-nums">{n}</div>'
            f'<div style="font-size:11.5px;font-weight:800;color:{T["warm"]};margin-top:5px">{label}</div></div>')

weekly = page(
  f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;align-items:center;gap:14px">'
  f'<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="{T["ink"]}" stroke-width="3" '
  f'stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>'
  f'<div><div class="h1" style="font-size:21px">Your week</div>'
  f'<div class="meta" style="margin-top:2px">Aug 24 – Aug 30</div></div></div>'
  + f'<div class="card" style="position:absolute;top:132px;left:20px;right:20px;padding:16px;'
    f'border-radius:24px">'
    f'<div style="display:flex;gap:8px">'
  + stat(14,"tasks",T["coralSoft"]) + stat(185,"focus min",T["mintSoft"]) + stat(5,"words",T["coinSoft"])
  + f'</div><div style="display:flex;gap:8px;margin-top:8px">'
  + stat(3,"lessons","#EAE6F8") + stat("410","coins earned",T["coinSoft"])
  + f'</div></div>'
  + f'<div style="position:absolute;top:378px;left:20px;right:20px;background:'
    f'linear-gradient(170deg,#FFFFFF,{T["mintSoft"]});border-radius:28px;padding:26px 24px;'
    f'display:flex;flex-direction:column;align-items:center;text-align:center;gap:14px;'
    f'box-shadow:0 2px 8px rgba(46,40,34,.05)">'
    f'{mascot(128,3,"faceDelight")}'
    f'<div style="font-size:18px;font-weight:900;line-height:1.4;text-wrap:pretty">'
    f'Your best focus week yet — three hours with Slime napping beside you.</div>'
    f'<div class="meta">Last week you did 120 minutes.</div></div>'
  + f'<div style="position:absolute;left:24px;right:24px;bottom:132px;display:flex;flex-direction:column;gap:10px">'
    f'<div style="background:{T["coral"]};border-radius:22px;padding:17px;text-align:center;color:#fff;'
    f'font-size:17px;font-weight:900;box-shadow:0 6px 16px rgba(255,111,97,.35)">Share my week</div>'
    f'<div class="meta" style="text-align:center;color:{T["muted"]}">'
    f'Quiet weeks are fine too — nothing here is a streak.</div></div>'
  + tabbar("house"))
write("Weekly.dc.html", weekly)

# ═══════════ 13. CONNECT CANVAS ═══════════
def step(n, title, sub):
    return (f'<div style="display:flex;gap:14px;align-items:flex-start;padding:14px 0">'
            f'<div style="width:28px;height:28px;border-radius:999px;background:{T["coralSoft"]};'
            f'display:flex;align-items:center;justify-content:center;flex:none">'
            f'<span style="font-size:14px;font-weight:900;color:{T["coral"]}">{n}</span></div>'
            f'<div style="flex:1"><div style="font-size:15px;font-weight:800;line-height:1.4">{title}</div>'
            f'<div class="meta" style="margin-top:3px;line-height:1.5">{sub}</div></div></div>')

connect = page(
  f'<div style="position:absolute;top:80px;left:24px;right:24px">'
  f'<div style="display:flex;justify-content:center;margin-bottom:22px">{mascot(104,1,"faceIdle")}</div>'
  f'<div class="h1" style="text-align:center;font-size:26px">Connect Canvas</div>'
  f'<div style="text-align:center;font-size:15px;font-weight:700;color:{T["warm"]};margin-top:8px;'
  f'line-height:1.5;text-wrap:pretty">Your assignments show up as tasks automatically.</div></div>'
  + f'<div class="card" style="position:absolute;top:342px;left:20px;right:20px;padding:8px 20px;'
    f'border-radius:24px">'
  + step(1,"Install the Prepkin extension","In Chrome, from the Web Store.")
  + f'<div style="height:1px;background:{T["hair"]}"></div>'
  + step(2,"Log into Canvas at school","Any school device works. We never see your password.")
  + f'<div style="height:1px;background:{T["hair"]}"></div>'
  + step(3,"Enter this code in the extension","That pairs it with this phone.")
  + f'</div>'
  + f'<div style="position:absolute;top:600px;left:20px;right:20px;border:2.5px dashed {T["checkb"]};'
    f'border-radius:24px;padding:22px;text-align:center;background:#FFFDF8">'
    f'<div style="font-size:12px;font-weight:900;color:{T["warm"]};letter-spacing:.8px">PAIRING CODE</div>'
    f'<div style="font-size:40px;font-weight:900;letter-spacing:7px;margin-top:8px;'
    f'font-variant-numeric:tabular-nums">A7X 99Q</div></div>'
  + f'<div style="position:absolute;left:24px;right:24px;bottom:56px;text-align:center;'
    f'font-size:16px;font-weight:800;color:{T["warm"]}">I\'ll do this later</div>')
write("ConnectCanvas.dc.html", connect)
