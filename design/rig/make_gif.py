"""Render a lottie doc to a GIF with headless Chrome + lottie-web.

qlmanage silently drops valid SVG paths, so it is never used here.
"""
import json, os, subprocess, sys, math
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CDN = "https://cdnjs.cloudflare.com/ajax/libs/bodymovin/5.12.2/lottie.min.js"

def render_frames(doc, out, frames, tile, cols=10, bg="#ffffff"):
    w, h = tile
    rows = (len(frames)+cols-1)//cols
    html = (f'<!DOCTYPE html><html><head><script src="{CDN}"></script><style>'
            f'html,body{{margin:0;padding:0;background:{bg};width:{cols*w}px;height:{rows*h}px}}'
            f'.f{{width:{w}px;height:{h}px;display:block;float:left}}'
            '</style></head><body><script>\n'
            f'const D={json.dumps(doc)};\nconst FR={json.dumps(frames)};\n'
            'for(const k of FR){const d=document.createElement("div");d.className="f";\n'
            ' document.body.appendChild(d);\n'
            ' const a=lottie.loadAnimation({container:d,renderer:"svg",loop:false,'
            'autoplay:false,animationData:JSON.parse(JSON.stringify(D))});\n'
            ' a.addEventListener("DOMLoaded",()=>a.goToAndStop(k,true));}\n'
            '</script></body></html>')
    hp = out+".html"; open(hp,"w").write(html)
    r = subprocess.run([CHROME,"--headless","--disable-gpu","--hide-scrollbars",
                        "--force-device-scale-factor=1",
                        f"--window-size={cols*w},{rows*h}",
                        f"--screenshot={out}_grid.png","file://"+os.path.abspath(hp)],
                       capture_output=True)
    os.makedirs(out+"_f", exist_ok=True)
    for n,k in enumerate(frames):
        c, rr = n % cols, n//cols
        subprocess.run(["ffmpeg","-loglevel","error","-y","-i",f"{out}_grid.png",
                        "-vf",f"crop={w}:{h}:{c*w}:{rr*h}",f"{out}_f/{n:04d}.png"],
                       capture_output=True)
    return cols, rows

def gif(out, fps, scale=None):
    vf = "fps=%d" % fps + (",scale=%d:-1:flags=lanczos" % scale if scale else "")
    subprocess.run(["ffmpeg","-loglevel","error","-y","-framerate",str(fps),
                    "-i",f"{out}_f/%04d.png","-vf",
                    vf+",split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3",
                    "-loop","0",f"{out}.gif"], capture_output=True)
    return out+".gif"

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv)>1 else "wave.json"
    out = sys.argv[2] if len(sys.argv)>2 else "wave"
    doc = json.load(open(src))
    W, H, DUR, FR = doc["w"], doc["h"], int(doc["op"]), int(doc["fr"])
    s = 2.6
    tile = (int(W/s)//2*2, int(H/s)//2*2)
    render_frames(doc, out, list(range(DUR)), tile, cols=10)
    print("frames rendered", tile)
    print(gif(out, FR, scale=380))
