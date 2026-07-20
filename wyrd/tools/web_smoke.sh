#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
node --check tools/web_smoke_probe.js
node tools/validate_web_smoke_probe.js
rm -rf build/web
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
godot --headless --path tools/pck_audit_project \
  --script "$(pwd)/tools/audit_pck.gd" -- "$(pwd)/build/web/index.pck"
if [ -f assets/brand/wayfinder_social.png ]; then
  cp assets/brand/wayfinder_social.png build/web/og.png
fi
cp tools/web_smoke_probe.js build/web/web_smoke_probe.js
awk '{ sub("</body>", "<script src=\"web_smoke_probe.js\"></script></body>"); print }' \
  build/web/index.html > build/web/index.qa.html
mv build/web/index.qa.html build/web/index.html

port="${1:-8066}"
echo "Wayfinder Web smoke: http://127.0.0.1:${port}/?wyrd_smoke=snug"
echo "Codex + Web smoke: http://127.0.0.1:${port}/?wyrd_smoke=snug&wyrd_ui_smoke=codex"
echo "C2 source smoke: http://127.0.0.1:${port}/?wyrd_smoke=snug&wyrd_ui_smoke=c2"
echo "D1 First Knot smoke: http://127.0.0.1:${port}/?wyrd_smoke=snug&wyrd_ui_smoke=d1"
echo "D2 First Knot Reprise smoke: http://127.0.0.1:${port}/?wyrd_smoke=snug&wyrd_ui_smoke=d2"
echo "D3 Golden Wallow smoke: http://127.0.0.1:${port}/?wyrd_smoke=snug&wyrd_ui_smoke=d3"
echo "D4 Seventh Road smoke: http://127.0.0.1:${port}/?wyrd_smoke=snug&wyrd_ui_smoke=d4"
echo "D5 Queen's Summit smoke: http://127.0.0.1:${port}/?wyrd_smoke=snug&wyrd_ui_smoke=d5"
echo "D6 Pale Oath smoke: http://127.0.0.1:${port}/?smoke=1&ui=d6"
echo "D7 Fire in the Bough smoke: http://127.0.0.1:${port}/?smoke=1&ui=d7"
echo "Click New Game. Inspect window.__wyrdSmokeHarness: status must become 'passed'."
python3 -m http.server "$port" --directory build/web
