# Inbox for Ink's paintings

Drop here, then run `python3 design/lesson-art/tools/unpack.py` (or tell Claude Code
"paintings are in"):

- a zip named after the lesson: `work-4.zip`, `hlth-1.zip`, ...
- or a folder named after the lesson with the PNGs inside: `inbox/work-4/p01-inbox.png`

Unpack moves the pictures into `design/lesson-art/<lesson-id>/`, forces 4:3 at
1200 x 900, files the zip under `inbox/done/`, and prints which paintings are still owed.
Nothing in `inbox/` is ever read by the app.
