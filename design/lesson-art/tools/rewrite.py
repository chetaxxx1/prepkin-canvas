#!/usr/bin/env python3
"""Replace a plan's words and keep its pictures. Feed it a dict:
  {"blurb":..., "takeaway":..., "bodies":[9 x (eyebrow, body)], "key":..., 
   "check": {"question":..., "choices":[3], "answer":0, "why":...}}
Scenes (paint specs), srcs, title, track stay as they were. Regenerates plan.py."""
import os, pprint, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plan as P

def apply(lid, new):
    L = P.load(lid)
    imgs = [c for c in L["cards"] if c["kind"] == "image"]
    assert len(new["bodies"]) == len(imgs), (lid, len(new["bodies"]), len(imgs))
    for c, (eyebrow, body) in zip(imgs, new["bodies"]):
        c["eyebrow"], c["body"] = eyebrow, body
    L["blurb"], L["takeaway"] = new["blurb"], new["takeaway"]
    L["cards"][-2]["body"] = new["key"]
    L["cards"][-1].update(new["check"])
    if "title" in new: L["title"] = new["title"]
    write(lid, L)

def write(lid, L):
    lines = ["LESSON = dict(", f"    id={L['id']!r}, track={L['track']!r}, minutes={L['minutes']},",
             f"    title={L['title']!r},", f"    blurb={L['blurb']!r},", f"    takeaway={L['takeaway']!r},", "    cards=["]
    for c in L["cards"]:
        if c["kind"] == "image":
            s = f"        dict(kind='image', src={c['src']!r}, eyebrow={c['eyebrow']!r},\n             body={c['body']!r}"
            if "paint" in c: s += f",\n             paint={c['paint']!r}"
            lines.append(s + "),")
        elif c["kind"] == "key":
            lines.append(f"        dict(kind='key', body={c['body']!r}),")
        else:
            lines.append(f"        dict(kind='check',\n             question={c['question']!r},\n             choices={c['choices']!r},\n             answer={c['answer']},\n             why={c['why']!r}),")
    lines += ["    ])", ""]
    open(os.path.join(P.folder(lid), "plan.py"), "w").write("\n".join(lines))
    print("rewrote", lid)

if __name__ == "__main__":
    import json
    for path in sys.argv[1:]:
        data = json.load(open(path))
        for lid, new in data.items(): apply(lid, new)
