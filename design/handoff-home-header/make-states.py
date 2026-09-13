"""Seeds Home states on a simulator and shoots them. Adapted from
design/screenshots/home-a-plus-2026-09-10/make-states.py (see that README for the
save-file rules: null the pairing first, terminate before writing).

  python3 make-states.py <udid> <base-state.json> a b c d e xl
"""
import json, sys, subprocess, time, datetime, pathlib

U = sys.argv[1]
BASE = pathlib.Path(sys.argv[2])
OUT = pathlib.Path(__file__).parent / "shots"
OUT.mkdir(exist_ok=True)

def sh(*a): return subprocess.run(a, capture_output=True, text=True)
def iso(dt): return dt.strftime("%Y-%m-%dT%H:%M:%SZ")

container = sh("xcrun", "simctl", "get_app_container", U, "com.prepkin.canvas", "data").stdout.strip()
SD = pathlib.Path(container) / "Library" / "Application Support" / "PrepkinCanvas"
SD.mkdir(parents=True, exist_ok=True)

now = datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)

def base():
    d = json.load(open(BASE))
    s = d["state"]
    s["canvasItems"] = []; s["canvasEvents"] = []; s["canvasCourses"] = []
    s["datedTasks"] = []
    s["lastCanvasSyncAt"] = None
    s["pairingCode"] = None
    s["pairingToken"] = None
    s["firstRunOffersDone"] = True
    s["widgetOfferDone"] = True
    s["owned"] = [dict(o, level=3) for o in s["owned"]]
    s["ledger"] = {"openingBalance": 0,
                   "entries": [{"amount": 99000, "at": iso(now), "day": s["currentDay"],
                                "key": "debug:unlock-all", "reason": "legacy", "units": 1}]}
    for t in s["templates"]: t["isActive"] = False
    return d

def active(s, ids):
    for t in s["templates"]: t["isActive"] = t["id"] in ids

def canvas(s, items):
    s["canvasItems"] = items
    s["canvasCourses"] = [{"id": "1", "name": "Physics 13", "code": "PHYS 13",
                           "score": 88.5, "grade": "B+", "colorHex": "#FF6F61"}]

def pay(s, key, amount):
    s["ledger"]["entries"].append({"amount": amount, "at": iso(now), "day": s["currentDay"],
                                   "key": key, "reason": "task", "units": 1})

def days(n, hour=23):
    local = (datetime.datetime.now() + datetime.timedelta(days=n)).replace(
        hour=hour, minute=59, second=0, microsecond=0)
    return iso(local.astimezone().astimezone(datetime.timezone.utc).replace(tzinfo=None))

def dated(titles):
    day = (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d")
    return [{"id": f"d-{i}", "title": t, "kind": "study", "source": "mine", "day": day,
             "createdAt": iso(now)} for i, t in enumerate(titles)]

def write_and_shot(d, name, wait=9):
    sh("xcrun", "simctl", "terminate", U, "com.prepkin.canvas"); time.sleep(1.5)
    json.dump(d, open(SD / "state.json", "w"))
    (SD / "state.backup.json").write_text(json.dumps(d))
    sh("xcrun", "simctl", "launch", U, "com.prepkin.canvas"); time.sleep(wait)
    sh("xcrun", "simctl", "io", U, "screenshot", str(OUT / f"built-{name}.png"))
    print("shot", name)

for which in sys.argv[3:]:
    if which == "a":  # four habits, no laptop, two stars, 40 to the next
        d = base(); s = d["state"]
        s["owned"] = [dict(o, level=2) for o in s["owned"]]
        s["ledger"] = {"openingBalance": 60, "entries": []}
        active(s, {"s-5", "l-1", "l-2", "l-3"})
        write_and_shot(d, "a-no-canvas")
    elif which == "b":
        d = base(); s = d["state"]
        s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
        s["datedTasks"] = dated(["Essay outline", "Week 3 quiz", "Lab report", "Reading response"])
        write_and_shot(d, "b-paired-nothing-due")
    elif which == "c":
        d = base(); s = d["state"]
        s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
        canvas(s, [{"id": "c-101", "title": "Ch. 5 Problem Set", "courseName": "Physics 13", "dueAt": days(0, 23)},
                   {"id": "c-102", "title": "Essay outline", "courseName": "Writing 5", "dueAt": days(0, 23)}])
        s["datedTasks"] = dated(["Bio quiz", "Essay draft", "Office hours"])
        active(s, {"s-5", "l-1"})
        pay(s, "task:c-101", 30)
        pay(s, f"task:s-5:{s['currentDay']}", 20)
        write_and_shot(d, "c-four-tasks-two-done")
    elif which == "d":
        d = base(); s = d["state"]
        s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
        canvas(s, [{"id": "c-101", "title": "Ch. 5 Problem Set", "courseName": "Physics 13", "dueAt": days(0, 23)}])
        s["datedTasks"] = dated(["Bio quiz"])
        active(s, {"s-5", "l-1", "l-3"})
        pay(s, "task:c-101", 30)
        for tid in ("s-5", "l-1", "l-3"):
            pay(s, f"task:{tid}:{s['currentDay']}", 20)
        write_and_shot(d, "d-all-done")
    elif which == "e":  # one star, ready for the next
        d = base(); s = d["state"]
        s["owned"] = [dict(o, level=1) for o in s["owned"]]
        s["ledger"] = {"openingBalance": 400, "entries": []}
        s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
        canvas(s, [{"id": "c-101", "title": "Ch. 5 Problem Set", "courseName": "Physics 13", "dueAt": days(0, 23)},
                   {"id": "c-102", "title": "Essay outline", "courseName": "Writing 5", "dueAt": days(0, 23)},
                   {"id": "c-103", "title": "Week 3 quiz", "courseName": "Intro Psych", "dueAt": days(0, 23)}])
        active(s, {"s-5", "l-1", "l-2", "l-3"})
        write_and_shot(d, "e-day-1-seven-goals")
    elif which == "xl":
        sh("xcrun", "simctl", "ui", U, "content_size", "accessibility-extra-extra-extra-large")
        d = base(); s = d["state"]
        s["owned"] = [dict(o, level=1) for o in s["owned"]]
        s["ledger"] = {"openingBalance": 400, "entries": []}
        s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
        canvas(s, [{"id": "c-101", "title": "Ch. 5 Problem Set", "courseName": "Physics 13", "dueAt": days(0, 23)}])
        active(s, {"s-5", "l-1"})
        write_and_shot(d, "xl-axxl")
        sh("xcrun", "simctl", "ui", U, "content_size", "medium")
