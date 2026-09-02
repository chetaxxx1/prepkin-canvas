"""Render a lottie doc to PNG via headless Chrome + lottie-web."""
import json, subprocess, os
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
CDN = "https://cdnjs.cloudflare.com/ajax/libs/bodymovin/5.12.2/lottie.min.js"

def render(doc, out, frames, cols=8, tile=(505, 405)):
    """frames: list of frame numbers. Writes <out>.png grid; returns (cols,rows)."""
    w, h = tile
    rows = (len(frames) + cols - 1) // cols
    html = (f'<!DOCTYPE html><html><head><script src="{CDN}"></script>'
            f'<style>body{{margin:0;background:#fff;width:{cols*w}px}}'
            f'.f{{width:{w}px;height:{h}px;display:inline-block;vertical-align:top}}'
            f'</style></head><body><script>\nconst data = {json.dumps(doc)};\n'
            f'const FR = {json.dumps(frames)};\n'
            'for (const k of FR) {\n'
            "  const d = document.createElement('div'); d.className='f';\n"
            '  document.body.appendChild(d);\n'
            "  const a = lottie.loadAnimation({container:d, renderer:'svg', loop:false,\n"
            '    autoplay:false, animationData: JSON.parse(JSON.stringify(data))});\n'
            "  a.addEventListener('DOMLoaded', () => a.goToAndStop(k, true));\n"
            '}\n</script></body></html>')
    hp = out + ".html"
    open(hp, "w").write(html)
    subprocess.run([CHROME, "--headless", "--disable-gpu",
                    f"--window-size={cols*w},{rows*h}",
                    f"--screenshot={out}.png", "file://" + os.path.abspath(hp)],
                   capture_output=True)
    return cols, rows

def tiles(out, frames, cols=8, tile=(505, 405)):
    """slice the grid png into per-frame pngs named <out>_NNN.png"""
    w, h = tile
    for n, k in enumerate(frames):
        c, r = n % cols, n // cols
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", f"{out}.png",
                        "-vf", f"crop={w}:{h}:{c*w}:{r*h}", f"{out}_{k:03d}.png"],
                       capture_output=True)
