exec(open('gen.py').read())
def header(title, coins=1450, right=None):
    r = right if right is not None else coinpill(coins)
    return (f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;'
            f'justify-content:space-between;align-items:center"><span class="h1">{title}</span>{r}</div>')
SPECIES = {"slime":("#51CFA0","#B1EDD4"),"ember":("#F7A8B8","#FBDCE3"),
           "droplet":("#9BC8F2","#D7E9FA"),"sprout":("#A5CE6B","#DBEAC4"),
           "wisp":("#C3B2F0","#E4DCF9")}

# ═══════════ 8. FRIENDS ═══════════
def story(name, species, unseen=True, you=False):
    c,b = SPECIES[species]
    ring = T["coral"] if unseen else T["checkb"]
    return (f'<div style="display:flex;flex-direction:column;align-items:center;gap:6px;flex:none">'
            f'{avatar(62,1,"faceIdle",c,b,ring=ring,ringw=3)}'
            f'<span style="font-size:12px;font-weight:{900 if you else 700};'
            f'color:{T["ink"] if you else T["warm"]}">{name}</span></div>')

def frow(rank, name, val, species, you=False):
    c,b = SPECIES[species]
    return (f'<div style="display:flex;align-items:center;gap:12px;padding:9px 0">'
            f'<span style="width:18px;font-size:14px;font-weight:900;color:{T["muted"]}">{rank}</span>'
            f'{avatar(34,1,"faceIdle",c,b)}'
            f'<span style="flex:1;font-size:15px;font-weight:{900 if you else 700}">{name}</span>'
            f'<div style="display:flex;align-items:center;gap:4px">{coin(13)}'
            f'<span style="font-size:14px;font-weight:900;color:{T["coinDark"]}">{val}</span></div></div>')

def flist(name, status, species):
    c,b = SPECIES[species]
    return (f'<div style="display:flex;align-items:center;gap:12px;padding:11px 0">'
            f'{avatar(42,1,"faceIdle",c,b)}'
            f'<div style="flex:1;min-width:0"><div style="font-size:15px;font-weight:800">{name}</div>'
            f'<div class="meta" style="margin-top:2px">{status}</div></div></div>')

addbtn = (f'<div style="display:flex;align-items:center;gap:6px;padding:8px 14px;border-radius:999px;'
          f'background:{T["coralSoft"]}"><svg viewBox="0 0 24 24" width="15" height="15" fill="none" '
          f'stroke="{T["coral"]}" stroke-width="3.2" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>'
          f'<span style="font-size:13px;font-weight:900;color:{T["coral"]}">Add</span></div>')

friends = page(
  header("Friends", right=addbtn)
  + f'<div style="position:absolute;top:112px;left:0;right:0;overflow:hidden">'
    f'<div style="display:flex;gap:14px;padding:0 24px">'
  + story("You","slime",False,True) + story("Maya","ember") + story("Josh","droplet")
  + story("Ava","sprout") + story("Sam","wisp",False) + f'</div></div>'
  + f'<div class="card" style="position:absolute;top:230px;left:20px;right:20px;padding:16px">'
    f'<div class="h2" style="font-size:16px;margin-bottom:2px">This week\'s coins</div>'
  + frow(1,"Maya",320,"ember") + frow(2,"Josh",280,"droplet")
  + frow(3,"You",245,"slime",True) + frow(4,"Ava",210,"sprout") + f'</div>'
  + f'<div class="card" style="position:absolute;top:492px;left:20px;right:20px;padding:6px 16px 10px">'
    f'<div class="h2" style="font-size:16px;margin:10px 0 2px">Today</div>'
  + flist("Maya","Focused 45 min","ember") + flist("Josh","Solved the word in 3","droplet")
  + flist("Ava","Finished 'Compound interest'","sprout") + flist("Sam","4 tasks done","wisp")
  + f'</div>'
  + tabbar("people"), h=880)
write("Friends.dc.html", friends, h=880)

# ═══════════ 9. STORY VIEWER ═══════════
bars = ''.join(f'<div style="flex:1;height:3px;border-radius:999px;background:'
               f'{"#fff" if i<1 else "rgba(255,255,255,.34)"}"></div>' for i in range(4))
c,b = SPECIES["ember"]
storyv = f'''<div style="width:390px;height:844px;position:relative;overflow:hidden;
background:linear-gradient(165deg,#3B4470 0%,#5A5F92 48%,#7E6E9E 100%)">
  <div style="position:absolute;top:52px;left:16px;right:16px;display:flex;gap:5px">{bars}</div>
  <div style="position:absolute;top:70px;left:16px;right:16px;display:flex;align-items:center;gap:10px">
    {avatar(34,1,"faceIdle",c,b)}
    <span style="font-size:14px;font-weight:900;color:#fff">Maya</span>
    <span style="font-size:13px;font-weight:700;color:rgba(255,255,255,.6)">2h</span>
  </div>
  <div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;
  justify-content:center;gap:26px;padding:0 40px">
    {mascot(200, 2, "faceDelight", c, b)}
    <div style="text-align:center">
      <div style="font-size:44px;font-weight:900;color:#fff;letter-spacing:-1px;line-height:1">45 min</div>
      <div style="font-size:17px;font-weight:800;color:rgba(255,255,255,.8);margin-top:8px">
        Maya focused today</div>
    </div>
  </div>
  <div style="position:absolute;left:16px;right:16px;bottom:44px;display:flex;align-items:center;gap:10px">
    <div style="flex:1;height:48px;border-radius:999px;border:2px solid rgba(255,255,255,.34);
    display:flex;align-items:center;padding:0 20px;font-size:15px;font-weight:700;
    color:rgba(255,255,255,.6)">Send a cheer…</div>
    <div style="width:48px;height:48px;border-radius:999px;background:{T["coral"]};display:flex;
    align-items:center;justify-content:center">
      <svg viewBox="0 0 24 24" width="21" height="21" fill="#fff"><path d="M3 20.5 22 12 3 3.5 3 10l13 2-13 2z"/></svg>
    </div>
  </div>
</div>'''
write("StoryViewer.dc.html", storyv)
