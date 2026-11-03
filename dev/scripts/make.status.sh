#!/usr/bin/env bash
# ============================================================
# 不 fetch，没 push 的数量是跟本地记录的远程比
# ============================================================
set -euo pipefail

WORKSPACE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$WORKSPACE_ROOT/dev/scripts/lib.color.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.log.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.app.sh"

log.title 'app 仓库'

apps=$(app.list)
if [ -z "$apps" ] && [ -z "$(app.registered)" ]; then
  printf '  %s\n' "$(color.dim '还没有 app')"
  exit 0
fi

# ============================================================
# 私有的在名字后面标出来
# 中文不按 printf 宽度对齐，公开的直接补 4 个空格
# ============================================================
visibility_of() {
  if app.is_private "$1"; then
    color.cyan '私有'
  else
    printf '    '
  fi
}

for name in $apps; do
  dir=$(app.dir "$name")
  label="$(printf '%-12s' "$name") $(visibility_of "$name")"

  if [ ! -e "$dir/.git" ]; then
    printf '  %s %s  %s\n' "$label" "$(color.dim "$(printf '%-10s' '-')")" "$(color.red '✖ 不是 git 仓库')"
    continue
  fi

  branch=$(git -C "$dir" symbolic-ref --short -q HEAD || echo '(detached)')
  issues=''

  changed=$(git -C "$dir" status --porcelain | wc -l | tr -d ' ')
  [ "$changed" -gt 0 ] && issues="$issues  $(color.yellow "● $changed 个文件没提交")"

  if [ -z "$(git -C "$dir" remote)" ]; then
    issues="$issues  $(color.yellow '○ 没配远程')"
  elif ! git -C "$dir" rev-parse -q --verify HEAD >/dev/null 2>&1; then
    issues="$issues  $(color.dim '还没有 commit')"
  elif ! git -C "$dir" rev-parse -q --verify '@{u}' >/dev/null 2>&1; then
    issues="$issues  $(color.yellow '↑ 没设上游分支')"
  else
    ahead=$(git -C "$dir" rev-list --count '@{u}..HEAD')
    [ "$ahead" -gt 0 ] && issues="$issues  $(color.yellow "↑ $ahead 个 commit 没 push")"
  fi

  if ! app.is_registered "$name"; then
    issues="$issues  $(color.yellow '○ 没登记在清单里')"
  elif [ -z "$(app.url "$name")" ]; then
    issues="$issues  $(color.yellow '○ 清单里还没写 git 地址')"
  fi

  [ -z "$issues" ] && issues="  $(color.green '✔ 都已提交并 push')"
  printf '  %s %s%s\n' "$label" "$(color.dim "$(printf '%-10s' "$branch")")" "$issues"
done

for name in $(app.registered); do
  app.exists "$name" && continue
  label="$(printf '%-12s' "$name") $(visibility_of "$name")"
  if ! app.valid "$name"; then
    note=$(color.red '✖ 清单里的 app 名不能用')
  elif [ -z "$(app.url "$name")" ]; then
    note=$(color.red '✖ 还没 clone，清单里也没写 git 地址')
  else
    note=$(color.yellow '↓ 还没 clone，跑 make setup')
  fi
  printf '  %s %s  %s\n' "$label" "$(color.dim "$(printf '%-10s' '-')")" "$note"
done
