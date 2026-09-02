"""Render a list of silhouettes as a labelled contact sheet (Chrome+lottie-web).

qlmanage silently drops valid SVG paths, so everything visual goes through the
same renderer the app will use.
"""
import json, os, subprocess
import numpy as np
import field, art

GREEN, MINT, INK = (81,207,160), (177,237,212), (16,24,32)
CW, CH = 1180, 830
OFF, ANC = [660, 817], [443, 795]
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CDN = "https://cdnjs.cloudflare.com/ajax/libs/bodymovin/5.12.2/lottie.min.js"

def fill(c): return {"ty":"fl","c":{"a":0,"k":[c[0]/255,c[1]/255,c[2]/255,1]},
                     "o":{"a":0,"k":100},"r":1}
def tr(): return {"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},
                  "s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}
def lay(ind, nm, shapes, op):
    return {"ddd":0,"ind":ind,"ty":4,"nm":nm,"sr":1,"parent":99,
            "ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[0,0]},
                  "a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]}},
            "ao":0,"shapes":shapes,"ip":0,"op":op,"st":0}

def doc_of(paths, face=True):
    n = len(paths)
    kf = [{"t":i,"s":[field.to_bezier(p)],"h":1} for i, p in enumerate(paths)]
    NULL = {"ddd":0,"ind":99,"ty":3,"nm":"root","sr":1,
            "ks":{"o":{"a":0,"k":0},"r":{"a":0,"k":0},"p":{"a":0,"k":OFF},
                  "a":{"a":0,"k":ANC},"s":{"a":0,"k":[100,100,100]}},
            "ao":0,"ip":0,"op":n,"st":0}
    layers = []
    if face:
        layers.append(lay(1,"face",[{"ty":"gr","it":[
            {"ty":"sh","ks":{"a":0,"k":art.to_lottie(g)}} for g in art.FACES]
            + [fill(INK), tr()]}], n))
        layers.append(lay(2,"belly",[{"ty":"gr","it":[
            {"ty":"sh","ks":{"a":0,"k":art.to_lottie(art.BELLY)}}, fill(MINT), tr()]}], n))
    layers.append(lay(3,"slime",[{"ty":"gr","it":[
        {"ty":"sh","ks":{"a":1,"k":kf}}, fill(GREEN), tr()]}], n))
    layers.append(NULL)
    return {"v":"5.7.1","fr":30,"ip":0,"op":n,"w":CW,"h":CH,"nm":"sheet",
            "ddd":0,"assets":[],"layers":layers}

def sheet(paths, labels, out, cols=4, tile=(430, 310)):
    w, h = tile
    rows = (len(paths)+cols-1)//cols
    html = (f'<!DOCTYPE html><html><head><script src="{CDN}"></script><style>'
            f'body{{margin:0;background:#fff;width:{cols*w}px;font:13px -apple-system}}'
            f'.c{{width:{w}px;display:inline-block;vertical-align:top;position:relative}}'
            f'.f{{width:{w}px;height:{h-20}px}}'
            f'.l{{height:20px;text-align:center;color:#111}}'
            '</style></head><body><script>\n'
            f'const D={json.dumps(doc_of(paths))};\nconst L={json.dumps(labels)};\n'
            'for(let i=0;i<L.length;i++){\n'
            " const c=document.createElement('div');c.className='c';\n"
            " const d=document.createElement('div');d.className='f';\n"
            " const t=document.createElement('div');t.className='l';t.textContent=L[i];\n"
            ' c.appendChild(d);c.appendChild(t);document.body.appendChild(c);\n'
            " const a=lottie.loadAnimation({container:d,renderer:'svg',loop:false,"
            'autoplay:false,animationData:JSON.parse(JSON.stringify(D))});\n'
            " a.addEventListener('DOMLoaded',()=>a.goToAndStop(i,true));}\n"
            '</script></body></html>')
    hp = out + ".html"; open(hp, "w").write(html)
    subprocess.run([CHROME, "--headless", "--disable-gpu", "--hide-scrollbars",
                    f"--window-size={cols*w},{rows*h}",
                    f"--screenshot={out}.png", "file://"+os.path.abspath(hp)],
                   capture_output=True)
    return out + ".png"
