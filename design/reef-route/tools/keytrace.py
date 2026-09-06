"""Key magenta out of a flat-colour render and trace it to SVG with vtracer."""
import re, numpy as np, vtracer
from PIL import Image, ImageFilter
def key(src, dst, trim=True, maxw=None):
    im=Image.open(src).convert('RGB'); a=np.asarray(im).astype(int); r,g,b=a[...,0],a[...,1],a[...,2]
    mag=(r>140)&(b>140)&(g<140)&((r-g)>60)&((b-g)>60)
    al=Image.fromarray(np.where(mag,0,255).astype(np.uint8)).filter(ImageFilter.MinFilter(3))
    out=Image.fromarray(a.astype(np.uint8)).convert('RGBA'); out.putalpha(al); arr=np.asarray(out).astype(int).copy()
    tint=(arr[...,0]>arr[...,1]+60)&(arr[...,2]>arr[...,1]+60)&(arr[...,3]>0); arr[tint,3]=0
    out=Image.fromarray(arr.astype(np.uint8)); m=arr[...,3]>0
    if trim:
        ys=np.where(m.any(axis=1))[0]; xs=np.where(m.any(axis=0))[0]
        out=out.crop((max(0,xs.min()-4),max(0,ys.min()-6),min(out.width,xs.max()+5),min(out.height,ys.max()+7)))
    if maxw and out.width>maxw: out=out.resize((maxw,int(out.height*maxw/out.width)),Image.LANCZOS)
    o=np.asarray(out).copy(); o[...,3]=np.where(o[...,3]>110,255,0); Image.fromarray(o).save(dst); return Image.open(dst).size
def trace(png, svg, precision=6, speckle=6):
    vtracer.convert_image_to_svg_py(png, svg, colormode='color', hierarchical='stacked', mode='spline', filter_speckle=speckle, color_precision=precision, layer_difference=16, corner_threshold=60, length_threshold=4.0, max_iterations=10, splice_threshold=45, path_precision=2)
def symbol(svg, sid):
    s=open(svg).read(); w=re.search(r'width="(\d+)',s).group(1); h=re.search(r'height="(\d+)',s).group(1)
    body=re.sub(r'^.*?<svg[^>]*>','',s,flags=re.S).replace('</svg>','').strip()
    return f'<symbol id="{sid}" viewBox="0 0 {w} {h}">{body}</symbol>', int(w), int(h)
