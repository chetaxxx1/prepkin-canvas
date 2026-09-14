#!/usr/bin/env bash
# Builds the Firefox copy of the extension into build/firefox/ and lints it.
#
# Same code, one manifest rewritten. Firefox's MV3 differs from Chrome's in
# four places, each handled here rather than in the source:
#   1. it runs no background.service_worker: the same files run as an event
#      page through background.scripts (background.js guards importScripts);
#   2. it has no side_panel / sidePanel: the panel is a sidebar_action;
#   3. it ignores use_dynamic_url and minimum_chrome_version, and needs a
#      browser_specific_settings.gecko id and a strict_min_version;
#   4. host_permissions are not granted at install; the popup asks (it
#      already does, from a click) and the bridge host is asked for at pairing.
# Requires web-ext (npm i -g web-ext, or the test deps folder's copy).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/firefox
rm -rf "$OUT"; mkdir -p "$OUT"
rsync -a --exclude '*.test.js' --exclude 'README.md' extension/ "$OUT/"
python3 - "$OUT" <<'PY'
import json, sys
out = sys.argv[1]
m = json.load(open('extension/manifest.json'))
m['background'] = { 'scripts': ['errlog.js', 'canvas.js', 'day.js', 'config.js', 'background.js'] }
m.pop('side_panel', None)
m['sidebar_action'] = { 'default_panel': 'sidepanel.html', 'default_title': 'Prepkin', 'default_icon': m['icons']['48'] }
m['permissions'] = [p for p in m['permissions'] if p != 'sidePanel']
m.pop('minimum_chrome_version', None)
for entry in m.get('web_accessible_resources', []): entry.pop('use_dynamic_url', None)
m['browser_specific_settings'] = { 'gecko': { 'id': 'canvas@prepkin.com', 'strict_min_version': '128.0' } }
json.dump(m, open(f'{out}/manifest.json', 'w'), indent=2)
print(f"  ✓ {out}/manifest.json for Firefox {m['browser_specific_settings']['gecko']['strict_min_version']}+")
PY
[ -f "$OUT/config.js" ] || { echo "  ✗ no extension/config.js (run bridge/apply-config.sh); the build will lint but never reach the bridge" >&2; echo "var PREPKIN_BRIDGE = null;" > "$OUT/config.js"; }
WEBEXT=$(command -v web-ext || echo "${PREPKIN_TEST_DEPS:-$HOME/Library/Developer/prepkin-canvas-test-deps}/node_modules/.bin/web-ext")
"$WEBEXT" lint --source-dir "$OUT" --warnings-as-errors=false --no-input
echo "  ✓ build/firefox is ready: web-ext run --source-dir $OUT --firefox=/Applications/Firefox.app/Contents/MacOS/firefox"
