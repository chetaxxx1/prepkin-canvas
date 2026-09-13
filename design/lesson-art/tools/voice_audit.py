#!/usr/bin/env python3
"""The LESSON-VOICE audit (design/LESSON-VOICE.md section 6), run on plans instead of
lessons.json. python3 tools/voice_audit.py [ids]"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

sents = lambda t: [s for s in re.split(r"(?<=[.!?])\s+", t.strip()) if s]
UNC = r"\b(it is|that is|do not|does not|is not|are not|you are|you will|cannot|did not|there is|here is|they are|we are|you have|it was not|was not|will not|would not|could not|should not|has not|have not)\b"

def audit(lid):
    L = P.load(lid)
    bodies = [c["body"] for c in L["cards"] if c.get("body")]
    punch = sum(1 for b in bodies if len(sents(b)) >= 2 and len(sents(b)[-1].split()) <= 7)
    txt = " ".join(bodies + [L["blurb"], L["takeaway"], L["cards"][-1]["why"]])
    unc = len(re.findall(UNC, txt, re.I)); con = len(re.findall(r"\b\w+'(s|t|re|ll|ve|d|m)\b", txt))
    cop = len(re.findall(r"(?:^|[.!?]\s+)(That is|It is|This is)\b", txt))
    year = bool(re.search(r"\b(19|20)\d\d\b", txt)); fake = len(re.findall(r"\bHere is\b|\bHere's what\b", txt))
    print(f"{lid:8s} punch {punch:2d}/{len(bodies)}  unc {unc:2d} con {con:2d}  copula {cop}  year {'y' if year else '-'}  fake-candid {fake}  teacher {len(re.findall(r'teachers?', txt, re.I))}")
    return punch, unc, con, cop

if __name__ == "__main__":
    ids = sys.argv[1:] or sorted(d for d in os.listdir(P.ROOT) if d != "tools" and os.path.exists(os.path.join(P.ROOT, d, "plan.py")))
    tot = [0, 0, 0, 0]
    for i in ids:
        r = audit(i); tot = [a + b for a, b in zip(tot, r)]
    print("TOTAL punch", tot[0], "unc", tot[1], "con", tot[2], "copula", tot[3])
