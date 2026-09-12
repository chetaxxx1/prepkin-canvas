import subprocess, sys, os
from concurrent.futures import ThreadPoolExecutor
PY=os.path.expanduser("~/.claude/skills/nano-banana/.venv/bin/python")
GEN=os.path.expanduser("~/.claude/skills/nano-banana/scripts/genimage.py")
STYLE=("Keep the character EXACTLY as drawn in the first image: the same pear body, face, eyes, mouth, fins, mint colour and white sticker rim. "
 "Add ONLY the costume described, drawn in the same flat vector style: smooth shapes, no outlines except the soft white rim, matte colours, a few fabric folds, one small highlight. "
 "Match the craft and detail level of the ninja in the second image, which is our quality bar. "
 "The costume must fit the pear body and the fins, worn naturally, not floating. The character has NO legs, NO feet, NO hands, NO fingers: the costume ends at the rounded bottom of the body exactly like the ninja suit, and anything held is held by the flat fin tip. "
 "The face (eyes and mouth) must stay fully visible and uncovered. Front facing, centered, plain flat background #F6F4EE, no text, no props on the ground, nothing behind the character.")
C={
 "champ":"a full champion boxer costume: a glossy white satin boxing robe with gold trim, the hood down around the shoulders and the robe hanging open at the front, a gold championship title belt with a big oval gold plate worn across the belly, big glossy red boxing gloves on both fin tips with white hand-wrap tape at the wrists",
 "headliner":"a full headliner DJ costume: chunky chrome over-ear headphones on the head with a glowing neon-magenta light ring on each ear cup, a cropped bomber jacket in iridescent holographic silver with a black ribbed collar and cuffs, a plain black tee under it, a thin glowing magenta wristband on one fin",
 "netrunner":"a full cyberpunk netrunner costume: a matte black techwear jacket with a tall zipped collar, thin glowing cyan seam lines and two small buckle straps across the chest, a translucent angular visor across the eyes with a thin cyan HUD glow (the eyes clearly visible through it), a brushed-chrome cybernetic plating sleeve on one fin with a single cyan light strip",
 "count":"a full vampire count costume: a black cape with a tall stiff standing collar behind the head and a deep crimson satin lining, fastened at the neck with a thin gold chain and a small ruby brooch, a black waistcoat with a white ruffled cravat at the chest, two tiny white fangs at the corners of the mouth, a small black bat perched on one fin tip",
 "abyss":"a full deep-sea anglerfish costume: a dark midnight-navy body suit covering the pear body and both fins, rows of small glowing teal bioluminescent dots along the belly and along each fin, a thin curved lure stalk rising from the top of the head with a softly glowing teal bulb at its tip, translucent jagged dark fin frills along the edges of both fins, a small translucent frill along the back. NO jaw, NO teeth, NO hood over the face",
}
def run(k):
    out=f"costume-{k}.png"
    if os.path.exists(out): return k,"cached"
    r=subprocess.run([PY,GEN,"--prompt",f"Dress this character in {C[k]}. {STYLE}","--aspect-ratio","1:1","--output",out,"--images","base-mint.png","ref-ninja.png"],capture_output=True,text=True)
    return k,("ok" if os.path.exists(out) else (r.stdout[-400:]+r.stderr[-400:]))
keys=sys.argv[1:] or list(C)
with ThreadPoolExecutor(5) as ex:
    for k,s in ex.map(run,keys): print(k,s)
