exec(open('gen.py').read())

def header(title, coins=1450):
    return (f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;'
            f'justify-content:space-between;align-items:center">'
            f'<span class="h1">{title}</span>{coinpill(coins)}</div>')

SPECIES = {"slime":("#51CFA0","#B1EDD4"),"ember":("#F7A8B8","#FBDCE3"),
           "droplet":("#9BC8F2","#D7E9FA"),"sprout":("#A5CE6B","#DBEAC4"),
           "wisp":("#C3B2F0","#E4DCF9")}
def sp(k): return SPECIES[k]

# ═══════════ 4. GAMES ═══════════
def game_card(title, sub, reward=None, locked=False, glyph="word"):
    g = ('<path d="M7 7h10a5 5 0 0 1 5 5v2a4 4 0 0 1-7.2 2.4L14 15h-4l-.8 1.4A4 4 0 0 1 2 14v-2a5 5 0 0 1 5-5z"/>'
         if glyph=="vs" else
         '<path d="M4 4h16v16H4zm3 3v4h4V7zm6 0v4h4V7zM7 13v4h4v-4zm6 0v4h4v-4z"/>')
    tile_bg = T["mintSoft"] if not locked else "#EFEAE1"
    tile_fg = T["mint"] if not locked else T["muted"]
    right = (f'<div style="display:flex;align-items:center;gap:5px;background:{T["coinSoft"]};'
             f'padding:5px 11px;border-radius:999px">{coin(13)}'
             f'<span style="font-size:12px;font-weight:900;color:{T["coinDark"]}">+{reward}</span></div>'
             if reward else
             f'<div style="display:flex;align-items:center;gap:5px;background:#EFEAE1;padding:5px 11px;'
             f'border-radius:999px"><svg viewBox="0 0 24 24" width="12" height="12" fill="{T["muted"]}">'
             f'<path d="M12 2a5 5 0 0 0-5 5v3H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2h-1V7a5 5 0 0 0-5-5zm0 2a3 3 0 0 1 3 3v3H9V7a3 3 0 0 1 3-3z"/></svg>'
             f'<span style="font-size:12px;font-weight:900;color:{T["muted"]}">Soon</span></div>')
    return (f'<div class="card" style="padding:16px;display:flex;align-items:center;gap:14px;'
            f'opacity:{0.62 if locked else 1}">'
            f'<div style="width:52px;height:52px;border-radius:16px;background:{tile_bg};display:flex;'
            f'align-items:center;justify-content:center;flex:none">'
            f'<svg viewBox="0 0 24 24" width="24" height="24" fill="{tile_fg}">{g}</svg></div>'
            f'<div style="flex:1;min-width:0"><div style="font-size:16px;font-weight:900">{title}</div>'
            f'<div class="meta" style="margin-top:2px">{sub}</div></div>{right}</div>')

def board_row(rank, name, val, species, you=False):
    c,b = sp(species)
    w = 900 if you else 700
    return (f'<div style="display:flex;align-items:center;gap:12px;padding:9px 0">'
            f'<span style="width:20px;font-size:14px;font-weight:900;color:{T["muted"]}">{rank}</span>'
            f'{avatar(34,1,"faceIdle",c,b)}'
            f'<span style="flex:1;font-size:15px;font-weight:{w}">{name}</span>'
            f'<span style="font-size:14px;font-weight:800;color:{T["warm"]}">{val}</span></div>')

games = page(
  header("Games")
  + f'<div style="position:absolute;top:118px;left:20px;right:20px;display:flex;flex-direction:column;gap:12px">'
  + game_card("Daily Word", "One word a day · everyone gets the same one", 30)
  + game_card("Versus", "Word battles with friends", locked=True, glyph="vs")
  + f'<div class="card" style="padding:16px;margin-top:4px">'
    f'<div class="h2" style="font-size:16px">Today\'s leaderboard</div>'
    f'<div style="margin-top:4px">'
  + board_row(1,"Maya","2 guesses","ember")
  + board_row(2,"You","3 guesses","slime",you=True)
  + board_row(3,"Josh","3 guesses","droplet")
  + board_row(4,"Ava","4 guesses","sprout")
  + board_row(5,"Sam","5 guesses","wisp")
  + f'</div></div></div>'
  + tabbar("game"))
write("Games.dc.html", games)

# ═══════════ 5. DAILY WORD ═══════════
def cell(ch, st):
    bg,fg,bd = {"empty":("#fff",T["ink"],T["checkb"]),
                "right":(T["mint"],"#fff",T["mint"]),
                "near":(T["coin"],"#fff",T["coin"]),
                "absent":("#CFC6B8","#fff","#CFC6B8")}[st]
    return (f'<div style="width:54px;height:54px;border-radius:12px;background:{bg};'
            f'border:2px solid {bd};display:flex;align-items:center;justify-content:center;'
            f'font-size:24px;font-weight:900;color:{fg}">{ch}</div>')

rows = [[("S","absent"),("T","near"),("U","absent"),("D","absent"),("Y","right")],
        [("R","absent"),("E","near"),("A","absent"),("D","near"),("Y","right")],
        [("F","right"),("A","right"),("N","right"),("C","right"),("Y","right")]] + [[("","empty")]*5]*3
grid = ''.join('<div style="display:flex;gap:6px;justify-content:center">'
               + ''.join(cell(c,s) for c,s in r) + '</div>' for r in rows)

KB = ["QWERTYUIOP","ASDFGHJKL","ZXCVBNM"]
KEYST = {"S":"absent","T":"near","U":"absent","D":"near","Y":"right","R":"absent","E":"near",
         "A":"right","F":"right","N":"right","C":"right"}
def key(ch):
    st = KEYST.get(ch)
    bg,fg = {"right":(T["mint"],"#fff"),"near":(T["coin"],"#fff"),
             "absent":("#CFC6B8","#fff")}.get(st, ("#fff", T["ink"]))
    return (f'<div style="flex:1;height:46px;border-radius:9px;background:{bg};color:{fg};display:flex;'
            f'align-items:center;justify-content:center;font-size:15px;font-weight:900;'
            f'box-shadow:0 1px 2px rgba(46,40,34,.08)">{ch}</div>')
kb = ''.join(f'<div style="display:flex;gap:5px;padding:0 {p}px">'
             + ''.join(key(c) for c in row) + '</div>'
             for row,p in zip(KB,[0,16,30]))

word = page(
  f'<div style="position:absolute;top:56px;left:24px;right:24px;display:flex;align-items:center;gap:14px">'
  f'<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="{T["ink"]}" stroke-width="3" '
  f'stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>'
  f'<span class="h1" style="font-size:21px">Daily Word</span>'
  f'<span style="margin-left:auto">{coinpill(1480)}</span></div>'
  + f'<div style="position:absolute;top:112px;left:0;right:0;display:flex;flex-direction:column;gap:6px">{grid}</div>'
  + f'<div style="position:absolute;top:492px;left:24px;right:24px;background:{T["mintSoft"]};'
    f'border-radius:16px;padding:13px;text-align:center">'
    f'<span style="font-size:15px;font-weight:900;color:{T["mintDark"]}">Solved in 3! </span>'
    f'<span style="font-size:15px;font-weight:900;color:{T["coinDark"]}">+30 coins</span>'
    f'<div class="meta" style="margin-top:3px;color:{T["mintDark"]};opacity:.75">Next word in 6h 12m</div></div>'
  + f'<div style="position:absolute;bottom:44px;left:8px;right:8px;display:flex;flex-direction:column;gap:6px">'
    f'{kb}<div style="display:flex;gap:5px;margin-top:1px">'
    f'<div style="flex:1.6;height:46px;border-radius:9px;background:{T["ink"]};color:#fff;display:flex;'
    f'align-items:center;justify-content:center;font-size:13px;font-weight:900">ENTER</div>'
    f'<div style="flex:1.6;height:46px;border-radius:9px;background:#fff;display:flex;align-items:center;'
    f'justify-content:center;box-shadow:0 1px 2px rgba(46,40,34,.08)">'
    f'<svg viewBox="0 0 24 24" width="20" height="20" fill="{T["ink"]}">'
    f'<path d="M9 4h11a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H9l-7-8zm3.4 3L11 8.4 13.6 11 11 13.6 12.4 15 15 12.4 17.6 15 19 13.6 16.4 11 19 8.4 17.6 7 15 9.6z"/></svg></div></div></div>')
write("DailyWord.dc.html", word)
