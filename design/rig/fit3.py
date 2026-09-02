"""Fit the rest arms to the approved art, with the arm long enough to rig.

The k=58 fit turns the drawn mitten into a vague bump - the whole point of the
mitten is that it reads as a little arm. A tighter blend keeps it, but an
unconstrained fit then collapses the shoulder onto the paw and there is nothing
left to swing. So: minimise the difference from the art subject to the arm
being at least MINLEN long.
"""
import os, math
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
import art
from smooth_torso import TORSO

PAD, SC = 120, 2
W, H = (886+2*PAD)//SC, (795+2*PAD)//SC
YY, XX = np.mgrid[0:H, 0:W]
MINLEN = 140.0

def flat(segs, n=16):
    p=[]
    for s in segs:
        for i in range(n):
            t=i/n
            p.append((((1-t)**3*s[0]+3*(1-t)**2*t*s[2]+3*(1-t)*t*t*s[4]+t**3*s[6]+PAD)/SC,
                      ((1-t)**3*s[1]+3*(1-t)**2*t*s[3]+3*(1-t)*t*t*s[5]+t**3*s[7]+PAD)/SC))
    return p
def mask(segs):
    im=Image.new("1",(W,H),0); ImageDraw.Draw(im).polygon(flat(segs),fill=1)
    return np.asarray(im,dtype=bool)
def sdf(m):
    return (ndimage.distance_transform_edt(~m)-ndimage.distance_transform_edt(m))*SC
def caps(a,b,ra,rb):
    ax,ay,bx,by=(a[0]+PAD)/SC,(a[1]+PAD)/SC,(b[0]+PAD)/SC,(b[1]+PAD)/SC
    pax,pay=XX-ax,YY-ay; bax,bay=bx-ax,by-ay
    h=np.clip((pax*bax+pay*bay)/max(bax*bax+bay*bay,1e-6),0,1)
    dx,dy=pax-bax*h,pay-bay*h
    return np.sqrt(dx*dx+dy*dy)*SC-(ra+(rb-ra)*h)
def smin(d1,d2,k):
    hh=np.clip(0.5+0.5*(d2-d1)/k,0,1)
    return d2*(1-hh)+d1*hh-k*hh*(1-hh)

TARGET=mask(art.BODY); D_T=sdf(mask(TORSO)); AREA=TARGET.sum()

def score(p,K):
    shx,shy,rsh,hx,hy,rp = p
    if math.hypot(hx-shx, hy-shy) < MINLEN: return 10**9
    if rsh<10 or rp<10: return 10**9
    aL=caps((shx,shy),(hx,hy),rsh,rp); aR=caps((886-shx,shy),(886-hx,hy),rsh,rp)
    return int(((smin(smin(D_T,aL,K),aR,K)<0)^TARGET).sum())

best=None
for K in (16,22,28,34,42,50,58):
    p=[161,465,57,48,575,56]; s=score(p,K)
    step=[8,8,6,8,8,6]
    while True:
        imp=False
        for i in range(6):
            for d in (-step[i],step[i]):
                q=list(p); q[i]+=d; sc=score(q,K)
                if sc<s: s,p,imp=sc,q,True
        if not imp:
            if max(step)<=1: break
            step=[max(1,int(x*0.6)) for x in step]
    L=math.hypot(p[3]-p[0],p[4]-p[1])
    print("k=%2d  XOR %.2f%%  shoulder(%d,%d) r_sh=%d hand(%d,%d) r_paw=%d  armlen=%.0f"
          %(K,100*s/AREA,p[0],p[1],p[2],p[3],p[4],p[5],L))
    if best is None or s<best[0]: best=(s,p,K)
s,p,K=best
print("BEST k=%d XOR %.2f%%"%(K,100*s/AREA))
open("blobfit.txt","w").write(repr(p+[int(K)]))
