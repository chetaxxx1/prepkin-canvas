#!/usr/bin/env bash
# Builds the zip you upload to the Chrome Web Store.
#
# There is exactly one way to do this, and it is this script, because the two
# ways to get it wrong are both silent:
#
#   1. Shipping without extension/config.js. The extension installs, reads
#      Canvas fine, and every sync fails with "missing config.js" — visible only
#      if a student opens the popup.
#   2. Zipping the wrong checkout. Worktrees under .claude/ hold older copies of
#      background.js. This script only ever packages the tree it lives in.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

fail() { echo "  ✗ $1" >&2; exit 1; }
ok()   { echo "  ✓ $1"; }

echo "Packaging from $ROOT"

# --- 1. The tests have to pass ------------------------------------------------
node --test extension/canvas.test.js extension/content.test.js extension/receipt.test.js > /dev/null 2>&1 || fail "extension tests fail — fix them before shipping"
ok "extension tests pass"

# --- 2. Config has to be there and real --------------------------------------
[ -f extension/config.js ] || fail "extension/config.js is missing — run bridge/apply-config.sh"
grep -q 'PREPKIN_BRIDGE' extension/config.js || fail "extension/config.js does not define PREPKIN_BRIDGE"
grep -q '"url": *"https://' extension/config.js || fail "extension/config.js has no bridge url"
grep -q '"key": *"[^"]\+"' extension/config.js || fail "extension/config.js has no bridge key"
grep -q 'service_role' extension/config.js && fail "extension/config.js holds a service_role key — that must never ship"
ok "config.js present and publishable"

# --- 3. Everything the manifest names has to exist ----------------------------
VERSION=$(python3 -c "import json;print(json.load(open('extension/manifest.json'))['version'])")
python3 - <<'PY'
import json, pathlib, sys
m = json.load(open('extension/manifest.json'))
need = ['background.js', 'popup.html']
need += [f for e in m.get('web_accessible_resources', []) for f in e.get('resources', [])]
need += list(m.get('icons', {}).values())
missing = [f for f in need if not (list(pathlib.Path('extension').glob(f)) if '*' in f else pathlib.Path('extension', f).exists())]
if missing:
    sys.exit("  ✗ manifest names files that do not exist: " + ", ".join(missing))
if not m.get('icons'):
    sys.exit("  ✗ manifest has no icons — the Chrome Web Store listing needs 16/32/48/128")
PY
ok "manifest references resolve"

# --- 4. Zip only what ships ---------------------------------------------------
OUT="$ROOT/dist/prepkin-canvas-$VERSION.zip"
mkdir -p "$ROOT/dist"
rm -f "$OUT"
( cd extension && zip -q -r "$OUT" . \
    -x '*.test.js' -x '.DS_Store' -x '__MACOSX/*' -x 'README.md' -x 'icons/icon.svg' )
ok "wrote dist/prepkin-canvas-$VERSION.zip ($(du -h "$OUT" | cut -f1))"

cat <<EOF

Next:
  - Bump "version" in extension/manifest.json before every upload; the store
    refuses a version it has already seen.
  - Upload at https://chrome.google.com/webstore/devconsole
  - The listing needs the hosted privacy policy URL. See bridge/PRIVACY.md for
    the text; it has to live at a real URL, not in this repo.
EOF
