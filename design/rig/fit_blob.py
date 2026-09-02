"""Fit the arm blobs + blend radius so the RESTING blob equals the approved art."""
import numpy as np, math
from scipy import ndimage
from PIL import Image, ImageDraw
import art
from smooth_torso import TORSO

PAD, AW, AH = 120, 886, 795
SC = 2                      # work at half resolution; plenty for a fit
W, H = (AW+2*PAD)//SC, (AH+2*PAD)//SC
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
    return (ndimage.distance_transform_edt(~m) - ndimage.distance_transform_edt(m))*SC
def caps(a,b,ra,rb):
    ax,ay,bx,by = (a[0]+PAD)/SC,(a[1]+PAD)/SC,(b[0]+PAD)/SC,(b[1]+PAD)/SC
    pax,pay = XX-ax, YY-ay; bax,bay = bx-ax, by-ay
    L2 = bax*bax+bay*bay
    h = np.clip((pax*bax+pay*bay)/max(L2,1e-6),0,1)
    dx,dy = pax-bax*h, pay-bay*h
    return np.sqrt(dx*dx+dy*dy)*SC - (ra+(rb-ra)*h)
def smin(d1,d2,k):
    hh=np.clip(0.5+0.5*(d2-d1)/k,0,1)
    return d2*(1-hh)+d1*hh - k*hh*(1-hh)

TARGET = mask(art.BODY)
D_T = sdf(mask(TORSO))

def score(shx,shy,rsh,hx,hy,rp,k):
    aL = caps((shx,shy),(hx,hy),rsh,rp)
    aR = caps((AW-shx,shy),(AW-hx,hy),rsh,rp)
    d  = smin(smin(D_T,aL,k),aR,k)
    return int(((d<0) ^ TARGET).sum())

p=[170,460,58,30,590,52,34]      # measured off the drawn mitten
s=score(*p)
print('start XOR',s,'->',(100.0*s/TARGET.sum()),'%')
step=[10,10,8,8,8,6,6]
imp=True
while imp:
    imp=False
    for i in range(7):
        for d in (-step[i],step[i]):
            q=list(p); q[i]+=d
            if q[6]<8: continue
            sc=score(*q)
            if sc<s: s,p,imp=sc,q,True
    step=[max(1,int(x*0.6)) for x in step]
    if max(step)<=1 and not imp: break
print("refined XOR %d (%.2f%% of the character)"%(s,100*s/TARGET.sum()))
print("shoulder(%d,%d) r_sh=%d  hand(%d,%d) r_paw=%d  blend k=%d"%tuple(p))
open("blobfit.txt","w").write(repr(p))
