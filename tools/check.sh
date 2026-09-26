#!/bin/sh
# 本地检查：语法、静态检查、冒烟测试、导出脚本单元测试。在仓库根目录运行：sh tools/check.sh
# 内部采集插件 WowHandbook_Collector/ 不在公开仓库中；存在时顺带运行它自己的检查。
set -e
cd "$(dirname "$0")/.."

echo "== luac -p"
find WowHandbook -name '*.lua' -not -path '*/Libs/*' -exec luac -p {} +

echo "== luacheck"
luacheck WowHandbook

echo "== smoke tests"
lua tools/tests/core_smoke.lua enUS
lua tools/tests/core_smoke.lua zhCN
lua tools/tests/ui_smoke.lua

echo "== python tests"
python3 -m unittest discover -s tools/tests -p 'test_*.py'

if [ -f WowHandbook_Collector/dev/check.sh ]; then
    sh WowHandbook_Collector/dev/check.sh
fi
