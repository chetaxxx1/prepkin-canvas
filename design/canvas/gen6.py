exec(open('gen.py').read())
def header(title, coins=1450):
    return (f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;'
            f'justify-content:space-between;align-items:center">'
            f'<span class="h1">{title}</span>{coinpill(coins)}</div>')
SPECIES = {"slime":("#51CFA0","#B1EDD4"),"ember":("#F7A8B8","#FBDCE3"),
           "droplet":("#9BC8F2","#D7E9FA"),"sprout":("#A5CE6B","#DBEAC4"),
           "wisp":("#C3B2F0","#E4DCF9")}

# ═══════════ 10. SHOP — buddy locker ═══════════
def price_chip(n):
    return (f'<div style="display:inline-flex;align-items:center;gap:5px;background:{T["coinSoft"]};'
            f'padding:6px 12px;border-radius:999px">{coin(14)}'
            f'<span style="font-size:13px;font-weight:900;color:{T["coinDark"]}">{n}</span></div>')
def state_chip(text, bg, fg):
    return (f'<div style="display:inline-flex;align-items:center;padding:6px 14px;border-radius:999px;'
            f'background:{bg}"><span style="font-size:13px;font-weight:900;color:{fg}">{text}</span></div>')

def buddy_card(name, species, price=None, owned=False, active=False, level=None, locked=False):
    if locked:
        inner = (f'<div style="filter:grayscale(1);opacity:.32">{mascot(78,1,"faceDeadpan","#B4A996","#DED7CB",shadow=False)}</div>'
                 f'<div style="font-size:15px;font-weight:900;color:{T["muted"]}">???</div>'
                 f'{state_chip("Coming soon","#EFEAE1",T["muted"])}')
    else:
        c,b = SPECIES[species]
        if active:   foot = state_chip("Active", T["mintSoft"], T["mintDark"])
        elif owned:  foot = state_chip("Use", T["coral"], "#fff")
        else:        foot = price_chip(price)
        sub = (f'<div class="meta" style="margin-top:-2px">Lv {level}</div>' if level else
               '<div style="height:0"></div>')
        inner = (f'{mascot(78,level or 1,"faceIdle",c,b,shadow=False)}'
                 f'<div style="font-size:15px;font-weight:900">{name}</div>{sub}{foot}')
    return (f'<div class="card" style="border-radius:22px;padding:16px 12px;display:flex;'
            f'flex-direction:column;align-items:center;gap:8px;min-height:190px;'
            f'justify-content:center">{inner}</div>')

def scene_card(name, asset, price=None, equipped=False, owned=False):
    if equipped: foot = state_chip("Equipped", T["mintSoft"], T["mintDark"])
    elif owned:  foot = state_chip("Use", T["coral"], "#fff")
    else:        foot = price_chip(price)
    return (f'<div class="card" style="border-radius:22px;padding:10px;display:flex;'
            f'flex-direction:column;align-items:center;gap:8px">'
            f'<img src="{asset}" style="width:100%;height:74px;object-fit:cover;border-radius:14px;display:block">'
            f'<div style="font-size:15px;font-weight:900">{name}</div>{foot}</div>')

grid2 = 'display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px'

shop = page(
  header("Shop", 1450)
  + f'<div style="position:absolute;top:112px;left:20px;right:20px">'

  # ── hero: your buddy
  + f'<div style="background:linear-gradient(170deg,#FFFFFF 0%,{T["mintSoft"]} 100%);border-radius:28px;'
    f'padding:24px 20px 20px;display:flex;flex-direction:column;align-items:center;gap:2px;'
    f'box-shadow:0 2px 8px rgba(46,40,34,.05)">'
    f'<div style="font-size:13px;font-weight:900;color:{T["warm"]};letter-spacing:.6px;'
    f'align-self:flex-start">YOUR BUDDY</div>'
    f'<div style="width:150px;height:150px;border-radius:999px;background:#fff;display:flex;'
    f'align-items:flex-end;justify-content:center;overflow:hidden;margin:6px 0 12px;'
    f'box-shadow:inset 0 0 0 4px rgba(87,199,155,.22)">'
    f'<div style="margin-bottom:-14px">{mascot(140,3,"faceDelight",shadow=False)}</div></div>'
    f'<div style="font-size:19px;font-weight:900">Slime · Level 3</div>'
    f'<div class="meta" style="margin-top:2px">Top level — the crown is yours.</div>'
    f'<div style="margin-top:14px;width:100%;background:#fff;border:2px solid {T["hair"]};'
    f'border-radius:20px;padding:13px;text-align:center;font-size:15px;font-weight:900;'
    f'color:{T["warm"]}">Fully grown</div></div>'

  # ── new buddies
  + f'<div class="h2" style="margin:24px 0 10px">New buddies</div>'
    f'<div style="{grid2}">'
  + buddy_card("Slime","slime",owned=True,active=True,level=3)
  + buddy_card("Ember","ember",price=450)
  + buddy_card("Droplet","droplet",price=600)
  + buddy_card("Sprout","sprout",price=750)
  + buddy_card(None,None,locked=True)
  + buddy_card(None,None,locked=True)
  + f'</div>'

  # ── scenes
  + f'<div class="h2" style="margin:24px 0 10px">Scenes</div>'
    f'<div style="{grid2}">'
  + scene_card("Study room","scene-dorm.jpg",owned=True)
  + scene_card("Meadow","scene-meadow.jpg",price=200)
  + scene_card("Golden hour","scene-sunset.jpg",price=220)
  + scene_card("Night in","scene-night.jpg",equipped=True)
  + f'</div>'

  + f'<div class="meta" style="text-align:center;margin:22px 0 0;color:{T["muted"]}">'
    f'Coins come from finishing tasks and focus sessions.</div>'
  + f'</div>'
  + tabbar("house", avatar_ring=T["coral"]), h=1500)
write("Shop.dc.html", shop, h=1500)
