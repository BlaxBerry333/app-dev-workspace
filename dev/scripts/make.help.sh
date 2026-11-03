#!/usr/bin/env bash
# ============================================================
# 命令说明读的是 Makefile 里每个目标正上方的分隔框
# 第一行是说明，后面几行是参数，缩进对齐显示
# 分隔框下面紧跟的不是目标（比如开头的「设置」）就不算命令
# ============================================================
set -euo pipefail

WORKSPACE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$WORKSPACE_ROOT/dev/scripts/lib.color.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.log.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.app.sh"

printf '%s  make <命令>\n\n' "$(color.bold '用法')"

log.title '命令'
awk '
  /^# =+$/ {
    if (inside) { inside = 0; closed = 1 } else { inside = 1; n = 0 }
    next
  }
  inside { sub(/^# ?/, ""); line[++n] = $0; next }
  closed && /^[a-z][a-z0-9-]*:/ {
    target = $0
    sub(/:.*/, "", target)
    for (i = 1; i <= n; i++) print target "\t" i "\t" line[i]
  }
  { closed = 0 }
' "$WORKSPACE_ROOT/Makefile" | while IFS=$'\t' read -r target index text; do
  if [ "$index" = 1 ]; then
    printf '  %s %s\n' "$(color.yellow "$(printf '%-8s' "$target")")" "$text"
  else
    printf '  %8s %s\n' '' "$(color.dim "$text")"
  fi
done

echo
log.title 'app'
apps=$(app.list)
if [ -z "$apps" ]; then
  printf '  %s\n' "$(color.dim '还没有 app')"
fi
for name in $apps; do
  if app.is_private "$name"; then
    visibility=$(color.cyan '私有')
  else
    visibility='    '
  fi
  case "$(app.runner "$name")" in
    make) printf '  %s %s %s\n' "$(color.green "$(printf '%-12s' "$name")")" "$visibility" "$(color.dim 'make')" ;;
    npm)  printf '  %s %s %s\n' "$(color.green "$(printf '%-12s' "$name")")" "$visibility" "$(color.dim 'npm')" ;;
    *)    printf '  %s %s %s\n' "$(printf '%-12s' "$name")" "$visibility" "$(color.dim '没有 Makefile 也没有 package.json')" ;;
  esac
done
