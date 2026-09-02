import json, numpy as np
import art, curve, make_gif
GREEN, MINT, INK = (81,207,160), (177,237,212), (16,24,32)
def fill(c): return {"ty":"fl","c":{"a":0,"k":[c[0]/255,c[1]/255,c[2]/255,1]},
                     "o":{"a":0,"k":100},"r":1}
def tr(): return {"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},
                  "s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}
def lay(ind,nm,shapes,op): return {"ddd":0,"ind":ind,"ty":4,"nm":nm,"sr":1,"parent":99,
    "ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[0,0]},
          "a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]}},
    "ao":0,"shapes":shapes,"ip":0,"op":op,"st":0}
W,H = 1200, 885
OFF, ANC = [713.0, 851.8], [443.0, 795.0]
def render(paths, out, cols=2, scale=1.0):
    n=len(paths)
    kf=[{"t":i,"s":[curve.to_bezier(p)],"h":1} for i,p in enumerate(paths)]
    NULL={"ddd":0,"ind":99,"ty":3,"nm":"root","sr":1,
          "ks":{"o":{"a":0,"k":0},"r":{"a":0,"k":0},"p":{"a":0,"k":OFF},
                "a":{"a":0,"k":ANC},"s":{"a":0,"k":[100,100,100]}},"ao":0,"ip":0,"op":n,"st":0}
    doc={"v":"5.7.1","fr":30,"ip":0,"op":n,"w":W,"h":H,"nm":"still","ddd":0,"assets":[],
         "layers":[lay(1,"face",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(g)}}
                                  for g in art.FACES]+[fill(INK),tr()]}],n),
                   lay(2,"belly",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":0,"k":art.to_lottie(art.BELLY)}},
                                  fill(MINT),tr()]}],n),
                   lay(3,"slime",[{"ty":"gr","it":[{"ty":"sh","ks":{"a":1,"k":kf}},fill(GREEN),tr()]}],n),
                   NULL]}
    t=(int(W*scale)//2*2, int(H*scale)//2*2)
    make_gif.render_frames(doc,out,list(range(n)),t,cols=cols)
    return out+"_f"
