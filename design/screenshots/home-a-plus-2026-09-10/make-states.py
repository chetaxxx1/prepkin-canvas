import json, sys, subprocess, time, datetime, copy, pathlib
U = "2A015A89-6DC3-4E91-9D3C-417F76DB523A"
SD = pathlib.Path(open("/private/tmp/claude-501/-Users-georgeshi-Desktop-app-prepkin-canvas/5147930d-5dec-408d-8a7f-d25782783a38/scratchpad/savedir.txt").read().strip())
OUT = pathlib.Path("design/screenshots/home-a-plus-2026-09-10/states")

def sh(*a, **k): return subprocess.run(a, capture_output=True, text=True, **k)

def iso(dt): return dt.strftime("%Y-%m-%dT%H:%M:%SZ")

def base():
    d = json.load(open(SD / "state.json"))
    s = d["state"]
    s["canvasItems"] = []; s["canvasEvents"] = []; s["canvasCourses"] = []
    s["datedTasks"] = []
    s["lastCanvasSyncAt"] = None
    # No code, no client: `AppState.defaultClient` returns nil, `syncCanvas` bails
    # at its first guard, and the list we seed below is the list Home draws.
    s["pairingCode"] = None
    s["pairingToken"] = None
    s["ledger"] = {"openingBalance": 0,
                   "entries": [{"amount": 99000, "at": iso(datetime.datetime.utcnow()),
                                "day": s["currentDay"], "key": "debug:unlock-all",
                                "reason": "legacy", "units": 1}]}
    for t in s["templates"]: t["isActive"] = False
    return d

def active(s, ids):
    for t in s["templates"]: t["isActive"] = t["id"] in ids

def canvas(s, items):
    s["canvasItems"] = items
    s["canvasCourses"] = [{"id": "1", "name": "Physics 13", "code": "PHYS 13",
                           "score": 88.5, "grade": "B+", "colorHex": "#FF6F61"}]

def pay(s, key, amount):
    s["ledger"]["entries"].append({"amount": amount, "at": iso(datetime.datetime.utcnow()),
                                   "day": s["currentDay"], "key": key,
                                   "reason": "task", "units": 1})

def write_and_shot(d, name, wait=9):
    sh("xcrun", "simctl", "terminate", U, "com.prepkin.canvas"); time.sleep(1.5)
    json.dump(d, open(SD / "state.json", "w"))
    (SD / "state.backup.json").write_text(json.dumps(d))
    sh("xcrun", "simctl", "launch", U, "com.prepkin.canvas"); time.sleep(wait)
    sh("xcrun", "simctl", "io", U, "screenshot", str(OUT / f"{name}.png"))
    print("shot", name)

now = datetime.datetime.utcnow()
today = None
def days(n, hour=23):
    """`hour` is the wall clock on the phone. The save wants UTC, so build the
    local time first and convert; both machines are on America/Chicago."""
    local = (datetime.datetime.now() + datetime.timedelta(days=n)).replace(
        hour=hour, minute=59, second=0, microsecond=0)
    return iso(local.astimezone().astimezone(datetime.timezone.utc).replace(tzinfo=None))

which = sys.argv[1]

if which == "a-unpaired":
    d = base(); s = d["state"]
    active(s, {"s-5", "l-1", "l-2", "l-3"})
    write_and_shot(d, "a-no-canvas")

elif which == "b-nothing-due":
    # The laptop has sent a list and there is nothing on it for today. Four things
    # land tomorrow, which is what the Tomorrow line is for.
    d = base(); s = d["state"]
    s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
    s["datedTasks"] = [
        {"id": f"d-{i}", "title": t, "kind": "study", "source": "mine",
         "day": (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d"),
         "createdAt": iso(now)}
        for i, t in enumerate(["Essay outline", "Week 3 quiz", "Lab report", "Reading response"])
    ]
    write_and_shot(d, "b-paired-nothing-due")

elif which == "c-two-done":
    d = base(); s = d["state"]
    s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
    canvas(s, [
        {"id": "c-101", "title": "Ch. 5 Problem Set", "courseName": "Physics 13", "dueAt": days(0, 23)},
        {"id": "c-102", "title": "Essay outline", "courseName": "Writing 5", "dueAt": days(0, 23)},
    ])
    s["datedTasks"] = [
        {"id": "d-1", "title": "Bio quiz", "kind": "study", "source": "mine",
         "day": (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d"),
         "createdAt": iso(now)},
        {"id": "d-2", "title": "Essay draft", "kind": "study", "source": "mine",
         "day": (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d"),
         "createdAt": iso(now)},
        {"id": "d-3", "title": "Office hours", "kind": "study", "source": "mine",
         "day": (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d"),
         "createdAt": iso(now)},
    ]
    active(s, {"s-5", "l-1"})
    pay(s, "task:c-101", 30)
    pay(s, f"task:s-5:{s['currentDay']}", 20)
    write_and_shot(d, "c-four-tasks-two-done")

elif which == "d-all-done":
    d = base(); s = d["state"]
    s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
    canvas(s, [
        {"id": "c-101", "title": "Ch. 5 Problem Set", "courseName": "Physics 13", "dueAt": days(0, 23)},
    ])
    s["datedTasks"] = [
        {"id": "d-1", "title": "Bio quiz", "kind": "study", "source": "mine",
         "day": (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d"),
         "createdAt": iso(now)},
    ]
    active(s, {"s-5", "l-1", "l-3"})
    pay(s, "task:c-101", 30)
    for tid in ("s-5", "l-1", "l-3"):
        pay(s, f"task:{tid}:{s['currentDay']}", 20)
    write_and_shot(d, "d-all-done")

elif which == "e-day-one":
    d = base(); s = d["state"]
    s["firstRunOffersDone"] = False
    s["settings"]["remindersEnabled"] = False
    active(s, {"s-5", "l-1", "l-3"})
    pay(s, f"task:l-1:{s['currentDay']}", 10)
    write_and_shot(d, "e-day-1-offer", wait=12)

elif which == "f-one-star":
    d = base(); s = d["state"]
    s["owned"] = [{"level": 1, "skinID": "classic", "speciesID": o["speciesID"]} for o in s["owned"]]
    s["ledger"] = {"openingBalance": 110, "entries": []}
    active(s, {"s-5", "l-1", "l-3"})
    write_and_shot(d, "f-one-star-band")

if which == "sweep":
    # As close to the state the "before" sweep ran on as the fixtures allow: the
    # same three sample Canvas rows, the same four habits, a three-star kin and
    # the unlock balance — plus a list that arrived two hours ago and four things
    # tomorrow, which is what the new lines need in order to be visible at all.
    d = base(); s = d["state"]
    s["owned"] = [{"level": 3, "skinID": "classic", "speciesID": o["speciesID"]} for o in s["owned"]]
    s["lastCanvasSyncAt"] = iso(now - datetime.timedelta(hours=2))
    canvas(s, [
        {"id": "c-101", "title": "Ch. 5 Problem Set", "courseName": "Physics 13", "dueAt": days(0, 23)},
        {"id": "c-102", "title": "Essay outline", "courseName": "Writing 5", "dueAt": days(0, 23)},
        {"id": "c-103", "title": "Week 3 quiz", "courseName": "Intro Psych", "dueAt": days(0, 23)},
    ])
    s["datedTasks"] = [
        {"id": f"d-{i}", "title": t, "kind": "study", "source": "mine",
         "day": (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d"),
         "createdAt": iso(now)}
        for i, t in enumerate(["Bio quiz", "Essay draft", "Office hours", "Lab report"])
    ]
    active(s, {"s-1", "l-1", "l-2", "l-3"})
    write_and_shot(d, "sweep-seed")
