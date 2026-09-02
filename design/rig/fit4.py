"""Fit the rest mitten with the pivot AT ITS ATTACHMENT, not buried mid-body.

The earlier fits were free to bury the shoulder deep inside the torso, because
that reproduces the resting silhouette slightly better. But that shoulder is
also the point the arm rotates about, and a pivot at 58% body height sweeps the
arm across the HEAD when it lifts - which is why the raised arm read as a fin
growing out of the skull instead of an arm at the side. The TFT slime's arms
pivot low, at belly height, so the arm rises alongside the body.

So: pin the pivot onto the mitten's own attachment chord, and fit the rest.
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
A=np.array(art.A); B=np.array(art.B)             # the mitten's attachment chord

def score(px,py,hx,hy,rs,rp,K):
    if math.hypot(hx-px,hy-py)<70: return 10**9
    if rs<20 or rp<18 or rs>110 or rp>90: return 10**9
    aL=caps((px,py),(hx,hy),rs,rp); aR=caps((886-px,py),(886-hx,hy),rs,rp)
    return int(((smin(smin(D_T,aL,K),aR,K)<0)^TARGET).sum())

best=None
for u in (0.30,0.45,0.60):                        # where on the chord to pivot
    P0=B+(A-B)*u
    for inset in (10.0,26.0,42.0):                # how far inside the surface
        px,py = P0[0]+inset, P0[1]
        for K in (16,26,36):
            p=[float(px),float(py),46.0,600.0,64.0,50.0]
            s=score(p[0],p[1],p[2],p[3],p[4],p[5],K)
            step=[6,6,6,6]
            while True:
                imp=False
                for i in (2,3,4,5):
                    for d in (-step[i-2],step[i-2]):
                        q=list(p); q[i]+=d
                        sc=score(q[0],q[1],q[2],q[3],q[4],q[5],K)
                        if sc<s: s,p,imp=sc,q,True
                if not imp:
                    if max(step)<=1: break
                    step=[max(1,int(x*0.6)) for x in step]
            if best is None or s<best[0]:
                best=(s,p,K,u,inset)
s,p,K,u,inset=best
print("pivot(%.0f,%.0f)  tip(%.0f,%.0f)  r_root=%.0f r_tip=%.0f  k=%d  chord_u=%.2f inset=%.0f"
      %(p[0],p[1],p[2],p[3],p[4],p[5],K,u,inset))
print("rest XOR %.2f%%   arm length %.0f px  (pivot at %.0f%% body height)"
      %(100*s/AREA, math.hypot(p[2]-p[0],p[3]-p[1]), 100*p[1]/795))
# write in rig.py order: pivot x, pivot y, r_root, tip x, tip y, r_tip, k
open("blobfit.txt","w").write(repr([int(round(p[0])),int(round(p[1])),int(round(p[4])),int(round(p[2])),int(round(p[3])),int(round(p[5])),int(K)]))
