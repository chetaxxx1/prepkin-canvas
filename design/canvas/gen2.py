exec(open('gen.py').read())

def header(title, coins=1450):
    return (f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;'
            f'justify-content:space-between;align-items:center">'
            f'<span class="h1">{title}</span>{coinpill(coins)}</div>')

def ring(size, progress=None, label="", sub_html="", track=None):
    """White disc + track; progress 0..1 draws a coral arc with round caps."""
    track = track or T["hair"]
    r = (size - 10) / 2; c = size / 2; circ = 2 * 3.14159265 * r
    arc = ''
    if progress is not None:
        arc = (f'<circle cx="{c}" cy="{c}" r="{r}" fill="none" stroke="{T["coral"]}" stroke-width="10" '
               f'stroke-linecap="round" stroke-dasharray="{circ:.1f}" '
               f'stroke-dashoffset="{circ*(1-progress):.1f}" transform="rotate(-90 {c} {c})"/>')
    return (f'<div style="position:relative;width:{size}px;height:{size}px;flex:none">'
            f'<svg viewBox="0 0 {size} {size}" width="{size}" height="{size}" style="display:block">'
            f'<circle cx="{c}" cy="{c}" r="{r}" fill="#fff"/>'
            f'<circle cx="{c}" cy="{c}" r="{r}" fill="none" stroke="{track}" stroke-width="10"/>{arc}</svg>'
            f'<div style="position:absolute;inset:0;display:flex;flex-direction:column;'
            f'align-items:center;justify-content:center;gap:6px">'
            f'<div style="font-size:58px;font-weight:900;letter-spacing:-2px;'
            f'font-variant-numeric:tabular-nums;line-height:1">{label}</div>{sub_html}</div></div>')

reward_line = (f'<div style="display:flex;align-items:center;gap:5px">{coin(15)}'
               f'<span style="font-size:14px;font-weight:800;color:{T["warm"]}">+25 when you finish</span></div>')

# ═══════════ 2. FOCUS — READY ═══════════
focus_ready = page(
  header("Focus")
  + f'<div style="position:absolute;top:112px;left:24px;right:24px">'
    f'<div style="font-size:13px;font-weight:800;color:{T["warm"]};letter-spacing:.6px">WORKING ON</div>'
    f'<div class="card" style="margin-top:8px;padding:14px 16px;display:flex;align-items:center;gap:12px">'
    f'<div style="width:40px;height:40px;border-radius:14px;background:{T["coralSoft"]};display:flex;'
    f'align-items:center;justify-content:center;flex:none">'
    f'<svg viewBox="0 0 24 24" width="18" height="18" fill="{T["coralIcon"]}">'
    f'<path d="M4 4h6a3 3 0 0 1 2 .8V21a3 3 0 0 0-2-.8H4zm16 0h-6a3 3 0 0 0-2 .8V21a3 3 0 0 1 2-.8h6z"/></svg></div>'
    f'<div style="flex:1;min-width:0"><div style="font-size:15px;font-weight:800">Essay outline</div>'
    f'<div class="meta" style="margin-top:2px">English 11 · due Sat 8:59 AM</div></div>'
    f'<span style="font-size:14px;font-weight:800;color:{T["coral"]}">Change</span></div></div>'
  + f'<div style="position:absolute;top:232px;left:0;right:0;display:flex;justify-content:center">'
    + ring(264, None, "25", f'<div style="font-size:15px;font-weight:800;color:{T["warm"]};margin-top:-4px">minutes</div>')
    + f'</div>'
  + f'<div style="position:absolute;top:508px;left:0;right:0;display:flex;justify-content:center">{reward_line}</div>'
  + f'<div style="position:absolute;top:548px;left:0;right:0;display:flex;flex-direction:column;'
    f'align-items:center;gap:6px">{mascot(120, 3, "faceIdle")}'
    f'<div style="font-size:13px;font-weight:700;color:{T["warm"]}">Slime will nap next to you while you work</div></div>'
  + f'<div style="position:absolute;left:24px;right:24px;bottom:132px">'
    f'<div style="background:{T["coral"]};border-radius:22px;padding:17px;text-align:center;color:#fff;'
    f'font-size:17px;font-weight:900;box-shadow:0 6px 16px rgba(255,111,97,.35)">Start focus</div></div>'
  + tabbar("clock"))
write("FocusReady.dc.html", focus_ready)

# ═══════════ 3. FOCUS — RUNNING ═══════════
zzz = (f'<div style="position:absolute;left:calc(50% + 46px);top:-6px;font-size:15px;font-weight:900;'
       f'color:{T["warm"]}">z<span style="font-size:11px;opacity:.65"> z</span></div>')
focus_run = page(
  header("Focus")
  + f'<div style="position:absolute;top:112px;left:24px;right:24px">'
    f'<div style="font-size:13px;font-weight:800;color:{T["warm"]};letter-spacing:.6px">WORKING ON</div>'
    f'<div class="card" style="margin-top:8px;padding:14px 16px;display:flex;align-items:center;gap:12px">'
    f'<div style="width:40px;height:40px;border-radius:14px;background:{T["coralSoft"]};display:flex;'
    f'align-items:center;justify-content:center;flex:none">'
    f'<svg viewBox="0 0 24 24" width="18" height="18" fill="{T["coralIcon"]}">'
    f'<path d="M4 4h6a3 3 0 0 1 2 .8V21a3 3 0 0 0-2-.8H4zm16 0h-6a3 3 0 0 0-2 .8V21a3 3 0 0 1 2-.8h6z"/></svg></div>'
    f'<div style="flex:1;min-width:0"><div style="font-size:15px;font-weight:800">Essay outline</div>'
    f'<div class="meta" style="margin-top:2px">English 11 · due Sat 8:59 AM</div></div></div></div>'
  + f'<div style="position:absolute;top:232px;left:0;right:0;display:flex;justify-content:center">'
    + ring(264, 0.75, "18:42", f'<div style="font-size:15px;font-weight:800;color:{T["warm"]};margin-top:-4px">left</div>')
    + f'</div>'
  + f'<div style="position:absolute;top:508px;left:0;right:0;display:flex;justify-content:center">{reward_line}</div>'
  + f'<div style="position:absolute;top:548px;left:0;right:0;display:flex;flex-direction:column;'
    f'align-items:center;gap:6px"><div style="position:relative">{mascot(120, 3, "faceDeadpan")}{zzz}</div>'
    f'<div style="font-size:13px;font-weight:700;color:{T["warm"]}">Slime is napping. You\'ve got this.</div></div>'
  + f'<div style="position:absolute;left:24px;right:24px;bottom:120px;display:flex;flex-direction:column;'
    f'align-items:center;gap:10px">'
    f'<div style="width:100%;background:#fff;border:2px solid {T["hair"]};border-radius:22px;padding:15px;'
    f'text-align:center;color:{T["warm"]};font-size:16px;font-weight:800">End early</div>'
    f'<div style="font-size:12px;font-weight:700;color:{T["muted"]};text-align:center;max-width:290px">'
    f'Ending early just means no coins this time. Slime won\'t mind.</div></div>')
write("FocusRunning.dc.html", focus_run)
