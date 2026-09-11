"""Seeds the Kin tab states for the 2026-09-11 redesign shots and takes them.

    python3 design/screenshots/kin-redesign-2026-09-11/make-states.py <udid> <state> [shot]

Writes `<container>/Library/Application Support/PrepkinCanvas/state.json` directly
(shape `{"version": 6, "state": {...}}`), with `pairingCode` / `pairingToken` nulled so
`syncCanvas()` bails on appear instead of wiping what was seeded. Terminates the app
first; it saves over you otherwise. Never `-unlockAll` on this simulator — that key is
sticky and would put every costume on the rack.

States: settled (Pip, 3 stars, Ninja on, Reef, day 12, Buddies about to be announced),
zero (same kin, nothing on the rack owned, 120 coins), firstrun (day 1, no coins).
"""
import json, sys, subprocess, time, datetime, pathlib

U = sys.argv[1]
WHICH = sys.argv[2]
SHOT = sys.argv[3] if len(sys.argv) > 3 else None
OUT = pathlib.Path(__file__).parent


def sh(*a, **k):
    return subprocess.run(a, capture_output=True, text=True, **k)


def container():
    return pathlib.Path(sh("xcrun", "simctl", "get_app_container", U, "com.prepkin.canvas", "data").stdout.strip())


def iso(dt):
    return dt.strftime("%Y-%m-%dT%H:%M:%SZ")


now = datetime.datetime.utcnow()


def ago(days, hour=9):
    return iso(now - datetime.timedelta(days=days)).replace("T", "T") if hour is None else \
        iso((now - datetime.timedelta(days=days)).replace(hour=hour, minute=0, second=0))


def base():
    sd = container() / "Library" / "Application Support" / "PrepkinCanvas"
    d = json.load(open(sd / "state.json"))
    s = d["state"]
    s["canvasItems"] = []; s["canvasEvents"] = []; s["canvasCourses"] = []
    s["datedTasks"] = []
    s["lastCanvasSyncAt"] = None
    s["pairingCode"] = None
    s["pairingToken"] = None
    s["firstRunDone"] = True
    s["firstRunOffersDone"] = True
    s["hasSeenTapCoach"] = True
    s["settings"]["remindersEnabled"] = False
    s["installedAt"] = ago(11)
    return d, sd


def coins(s, n):
    s["ledger"] = {"openingBalance": 0,
                   "entries": [{"amount": n, "at": iso(now), "day": s["currentDay"],
                                "key": "seed:coins", "reason": "legacy", "units": 1}]}


def kin(s, level, skin, care, days_ago, name="Pip"):
    s["owned"] = [{"speciesID": "slime", "level": level, "name": name, "skinID": skin,
                   "adoptedAt": ago(days_ago), "careTaps": care, "stageReached": 0,
                   "statsAtAdoption": {"tasksFinished": 0, "canvasFinished": 0,
                                       "focusMinutes": 0, "lessonsRead": 0}}]
    s["activeChibiID"] = "slime"


def write(d, sd):
    sh("xcrun", "simctl", "terminate", U, "com.prepkin.canvas"); time.sleep(1.5)
    json.dump(d, open(sd / "state.json", "w"))
    (sd / "state.backup.json").write_text(json.dumps(d))


d, sd = base()
s = d["state"]

if WHICH == "settled":
    kin(s, 3, "ninja", 30, 11)
    s["ownedLooks"] = ["classic", "ninja", "hoodie"]
    s["ownedScenes"] = ["lagoon", "reef"]
    s["sceneID"] = "reef"
    s["lifetime"] = {"tasksFinished": 41, "canvasFinished": 10, "focusMinutes": 27, "lessonsRead": 9}
    s["firsts"] = {"dated": {"costume": ago(9), "scene": ago(7), "shift": ago(8), "stars:slime": ago(2)},
                   "undated": []}
    s["friendCode"] = "PK7Q-2X4M"
    coins(s, 620)
elif WHICH == "zero":
    kin(s, 3, "classic", 3, 11)
    s["ownedLooks"] = ["classic"]
    s["ownedScenes"] = ["lagoon"]
    s["sceneID"] = "lagoon"
    s["lifetime"] = {"tasksFinished": 4, "canvasFinished": 1, "focusMinutes": 0, "lessonsRead": 1}
    s["firsts"] = {"dated": {}, "undated": []}
    coins(s, 120)
elif WHICH == "firstrun":
    kin(s, 1, "classic", 0, 0, name=None)
    s["owned"][0].pop("name")
    s["ownedLooks"] = ["classic"]
    s["ownedScenes"] = ["lagoon"]
    s["sceneID"] = "lagoon"
    s["lifetime"] = {"tasksFinished": 0, "canvasFinished": 0, "focusMinutes": 0, "lessonsRead": 0}
    s["firsts"] = {"dated": {}, "undated": []}
    s["ledger"] = {"openingBalance": 0, "entries": []}
else:
    sys.exit("unknown state")

write(d, sd)
print("seeded", WHICH)
