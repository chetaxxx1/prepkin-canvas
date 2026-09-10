"""The icon manifest. One source of truth for the whole set.

`src` names a generated sheet in design/icons/src, `cell` the zero-based cell in
that sheet read left-to-right, top-to-bottom. Style is locked inside a sheet, so
new icons are always drawn a sheetful at a time against grid-a as the reference,
never one at a time.

`tint` is the tile colour behind the object. Six exist and an icon does not get
to invent a seventh — the tile takes the hue family of the thing standing in it.
"""

# sheet -> (columns, rows)
GRIDS = {"grid-a": (3, 2), "grid-b": (3, 2), "grid-c": (4, 2), "grid-d": (2, 1),
         "grid-e": (3, 1), "grid-f": (3, 2), "grid-g": (3, 2)}

TINT = {"sky": "#E3EEFB", "gold": "#FCEFD3", "mint": "#DFF3E9",
        "coral": "#FFE9E5", "lilac": "#EDE7FB", "indigo": "#E7E7F6"}
TINT_DARK = {"sky": "#20303F", "gold": "#3A2E19", "mint": "#1D3830",
             "coral": "#3D2320", "lilac": "#2C2440", "indigo": "#232238"}

# name, label, group, tint, src, cell
SET = [
    ("reading",    "Reading",          "Task category", "coral",  "grid-a", 0),
    ("writing",    "Writing",          "Task category", "gold",   "grid-b", 0),
    ("problemSet", "Problem set",      "Task category", "sky",    "grid-b", 1),
    ("labs",       "Labs",             "Task category", "mint",   "grid-b", 2),
    ("study",      "Study",            "Task category", "lilac",  "grid-b", 3),
    ("lifeCare",   "Life care",        "Task category", "sky",    "grid-a", 1),
    ("walk",       "Walk",             "Task category", "mint",   "grid-a", 2),
    ("sleep",      "Sleep",            "Task category", "indigo", "grid-d", 1),
    ("meal",       "Meal",             "Task category", "coral",  "grid-a", 4),
    ("stretch",    "Stretch",          "Task category", "lilac",  "grid-d", 0),
    ("outdoors",   "Outdoors",         "Task category", "mint",   "grid-b", 5),
    ("connect",    "Connect",          "Task category", "sky",    "grid-c", 0),
    ("tidy",       "Tidy",             "Task category", "gold",   "grid-c", 1),
    ("finance",    "Personal finance", "Learn track",   "gold",   "grid-c", 2),
    ("philosophy", "Philosophy",       "Learn track",   "lilac",  "grid-c", 3),
    ("studyTrack", "Study skills",     "Learn track",   "mint",   "grid-c", 4),
    ("psychology", "Psychology",       "Learn track",   "sky",    "grid-c", 5),
    ("people",     "People",           "Learn track",   "coral",  "grid-c", 6),
    ("work",       "Work",             "Learn track",   "indigo", "grid-a", 5),
    ("star",       "Stars earned",     "Interface",     "gold",   "grid-e", 0),
    ("calculator", "Grade calculator", "Interface",     "coral",  "grid-e", 1),
    ("heart",      "Saved cards",      "Interface",     "coral",  "grid-e", 2),
    ("tabHome",     "Home",     "Tab bar", "coral",  "grid-f", 0),
    ("tabFocus",    "Focus",    "Tab bar", "gold",   "grid-f", 1),
    ("tabLearn",    "Learn",    "Tab bar", "sky",    "grid-f", 2),
    ("tabCalendar", "Calendar", "Tab bar", "lilac",  "grid-f", 3),
    ("tabFriends",  "Friends",  "Tab bar", "coral",  "grid-f", 4),
    # Sky since 2026-09-10, when Play took Learn's slot in the bar: lilac sat beside
    # Calendar's lilac, and the bar's findability is one hue family per tab. The
    # cut PNGs were hue-shifted (+sat) rather than the sheet regenerated (PLAY-TAB.md).
    ("tabPlay",     "Play",     "Tab bar", "sky",    "grid-f", 5),
    # grid-g came back 3x2 with the palm and the card set drawn twice, so the
    # indices skip the repeats rather than the sheet being regenerated.
    ("pet",        "Pet",        "Kin", "coral", "grid-g", 0),
    ("highFive",   "High five",  "Kin", "mint",  "grid-g", 1),
    ("snack",      "Snack",      "Kin", "gold",  "grid-g", 3),
    ("collection", "Collection", "Kin", "lilac", "grid-g", 4),
]

# Icons that render with nothing behind them. They fill more of their box than an
# icon that sits in a tinted tile, or they read a size smaller than their neighbours.
NO_TILE = {"tabHome", "tabFocus", "tabLearn", "tabCalendar", "tabFriends", "tabPlay",
           "collection"}

BY_NAME = {r[0]: r for r in SET}
