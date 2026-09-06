"""Rebuild the floor tile inside reef-route.html: TILE that divides both the 60 s demo and 90 s app tick,
a bare stretch where the arch lands, planted objects, and sand life. Usage: python retile.py page.html"""
import re, sys, math
p=sys.argv[1]; page=open(p).read()
TILE=660.0; SAND=214.0; AMP=5.0; V_MID=22.0; ARCH_H=88.0
sand_y=lambda x: SAND+AMP*math.sin(2*math.pi*x/TILE)
def dims(name):
    m=re.search(rf'<symbol id="{name}" viewBox="0 0 (\d+) (\d+)"', page); return int(m.group(1)), int(m.group(2))
aw,ah=dims('arch'); arch_w=aw*ARCH_H/ah
# the arch reaches screen x=125 on every tick; with TILE dividing tick*V_MID the scroll offset is 0 there,
# so its tile-x is fixed: keep that stretch bare
gap=(125-arch_w/2-12, 125+arch_w/2+12); print('arch gap', [round(g) for g in gap])
# the chest passes Sprout 20 s after a tick: scroll offset there is (20*V_MID) mod TILE, so its tile-x is fixed too
CHEST_W=63.9; cs=(20*V_MID)%TILE; gap2=(125-CHEST_W/2-12+cs, 125+CHEST_W/2+12+cs); print('chest gap', [round(g) for g in gap2])
def clear(cx, ww):
    ok=lambda g: not (cx+ww/2>g[0] and cx-ww/2<g[1])
    return ok(gap) and ok(gap2) and cx-ww/2>=0 and cx+ww/2<=TILE
layout=[('plant-4',30,100,0),('plant-1',230,92,0),('plant-2',300,70,0),('plant-4',370,96,0),('plant-1',440,88,0),('plant-2',500,66,0),('plant-4',635,96,0),
        ('coral-2',250,44,1),('coral-1',330,54,1),('coral-4',410,50,1),('coral-3',475,48,1),
        ('plant-3',30,34,2),('plant-5',270,28,2),('plant-3',355,32,2),('plant-5',425,26,2),('plant-3',505,30,2),('plant-5',632,27,2)]
layout.sort(key=lambda l:l[3]); placed=''
for name,cx,hgt,depth in layout:
    w,h=dims(name); ww=w*hgt/h
    assert clear(cx,ww), (name,cx)
    placed+=f'<use href="#{name}" x="{cx-ww/2:.1f}" y="{sand_y(cx)+6-hgt:.1f}" width="{ww:.1f}" height="{hgt}"/>'
life=[('star',215,15,'s1'),('clam-1',360,13,'clamA'),('crab-1',430,16,'crabA'),('coral-6',505,12,'sh1'),('coral-7',325,8,'pb1'),('coral-7',642,7,'pb2'),('star',22,13,'s2'),('clam-1',470,11,'clamB'),('crab-1',262,14,'crabB')]
items={}; lifeplaced=''
for name,cx,hgt,eid in life:
    w,h=dims(name); ww=w*hgt/h; walk=14 if eid.startswith('crab') else 0
    assert clear(cx,ww+2*walk), (eid,cx)
    span=[cx-ww/2-walk+i*(ww+2*walk)/12 for i in range(13)]; top=max(sand_y(x) for x in span)
    y=top-0.45*hgt if eid.startswith('crab') else top+3
    items[eid]=(cx-ww/2-walk,cx+ww/2+walk)
    lifeplaced+=f'<use id="{eid}" href="#{name}" x="{cx-ww/2:.1f}" y="{y:.1f}" width="{ww:.1f}" height="{hgt}" data-cx="{cx}" data-w="{ww:.1f}"/>'
ids=list(items)
for i in range(len(ids)):
    for j in range(i+1,len(ids)):
        a,b=items[ids[i]],items[ids[j]]; assert not (a[0]<b[1]+4 and b[0]<a[1]+4), (ids[i],ids[j])
pts=[f'{x:.1f} {sand_y(x):.2f}' for x in [i*TILE/33 for i in range(34)]]; sandTop='M'+' L'.join(pts)
crest=[f'{x:.1f} {sand_y(x)+9:.2f}' for x in [i*TILE/33 for i in range(34)]]
tile=f'<symbol id="tile" viewBox="0 0 {TILE:.0f} 250" width="{TILE:.0f}" height="250" overflow="visible"><g class="tile">{placed}<path d="{sandTop} L{TILE:.0f} 250 L0 250 Z" fill="#F1DFAE"/><path d="{sandTop} L{TILE:.0f} {sand_y(TILE)+9:.2f} {" ".join("L"+p for p in reversed(crest))} Z" fill="#F8EBC4"/>{lifeplaced}</g></symbol>'
page,n=re.subn(r'<symbol id="tile" viewBox="[^"]*"[^>]*>.*?</symbol>', lambda m: tile, page, count=1, flags=re.S); assert n==1
page,n=re.subn(r'<g id="mid"><use href="#tile" x="0" y="0"/><use href="#tile" x="[\d.]+" y="0"/>', f'<g id="mid"><use href="#tile" x="0" y="0"/><use href="#tile" x="{TILE:.0f}" y="0"/>', page); assert n==1
page,n=re.subn(r'mid:\d+(?:\.\d+)?, near:300', f'mid:{TILE:.0f}, near:300', page); assert n==1
page,n=re.subn(r'TILE=\d+(?:\.\d+)?;', f'TILE={TILE:.0f};', page); assert n==1
page,n=re.subn(r'<svg viewBox="0 90 \d+ 160"><use href="#tile"/></svg>', f'<svg viewBox="0 90 {TILE:.0f} 160"><use href="#tile"/></svg>', page); assert n==1
page=page.replace('The floor tile is 520 pt wide', f'The floor tile is {TILE:.0f} pt wide')
open(p,'w').write(page); print('retiled', TILE)
