#!/bin/bash
# Re-render every artboard in "Friends v2.dc.html" to screens/<id>.png.
# Must be served over http: dc-import fetches sibling .dc.html files, which
# file:// blocks — and the temp pages must sit BESIDE Slime.dc.html, because
# the runtime resolves component names relative to the page's own directory.
set -e
D="$(cd "$(dirname "$0")" && pwd)"
CH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mkdir -p "$D/screens"
cd "$D" && python3 -m http.server 8732 >/dev/null 2>&1 &
SRV=$!; sleep 1.5
python3 - "$D" <<'PY'
import pathlib, re, sys
d = pathlib.Path(sys.argv[1])
src = (d/'Friends v2.dc.html').read_text()
for i in re.findall(r'<div class="dv-opt" id="([^"]+)"', src):
    css = ('<style>.dv-thd{display:none!important}.dv-turn{padding:6px!important}'
           '.dv-opts{display:block!important}.dv-opt{display:none!important}'
           f'.dv-olabel{{display:none!important}}[id="{i}"]{{display:block!important}}</style>')
    (d/f'_ab_{i}.html').write_text(src.replace('</body>', css+'</body>'))
PY
for f in "$D"/_ab_*.html; do
  i=$(basename "$f" .html); i=${i#_ab_}
  case "$i" in 1w|2d) SIZE="1100,1700" ;; *) SIZE="404,858" ;; esac
  "$CH" --headless=new --disable-gpu --hide-scrollbars --window-size=$SIZE \
    --virtual-time-budget=7000 --default-background-color=EDE7DC \
    --screenshot="$D/screens/$i.png" "http://localhost:8732/_ab_$i.html" >/dev/null 2>&1
  echo "  $i"
done
kill $SRV 2>/dev/null || true
rm -f "$D"/_ab_*.html
