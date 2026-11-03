#!/usr/bin/env bash
# ============================================================
# 拉每个 app 远端的主分支，只快进本地的主分支，当前正在用的分支不动
# 当前就在主分支上：工作区干净才快进，有没提交的改动就跳过
# 主分支和远端分叉了不合并，只报出来
# 不在主分支上时用 git fetch . 快进本地主分支：不是快进、或者被别的 worktree 检出时 git 会拒绝
# ============================================================
set -euo pipefail

WORKSPACE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$WORKSPACE_ROOT/dev/scripts/lib.color.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.log.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.app.sh"

# ============================================================
# 远端用 origin，没有 origin 就用第一个
# ============================================================
remote_of() {
  local remotes
  remotes=$(git -C "$1" remote)
  if printf '%s\n' "$remotes" | grep -qx origin; then
    printf 'origin'
  else
    printf '%s' "$(printf '%s\n' "$remotes" | head -1)"
  fi
}

# ============================================================
# 远端的主分支名：先看 <远端>/HEAD 指向哪，没有再试 main、master
# ============================================================
main_of() {
  local dir=$1 remote=$2 ref candidate
  if ref=$(git -C "$dir" symbolic-ref -q --short "refs/remotes/$remote/HEAD"); then
    printf '%s' "${ref#"$remote"/}"
    return 0
  fi
  for candidate in main master; do
    if git -C "$dir" rev-parse -q --verify "refs/remotes/$remote/$candidate" >/dev/null; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

apps=$(app.list)
log.title '更新 app 的主分支'
if [ -z "$apps" ]; then
  printf '  %s\n' "$(color.dim '还没有 app')"
  exit 0
fi

failed=0
for name in $apps; do
  dir=$(app.dir "$name")
  label=$(printf '%-12s' "$name")
  detail=''

  if [ ! -e "$dir/.git" ]; then
    printf '  %s %s\n' "$label" "$(color.red '✖ 不是 git 仓库')"
    failed=1
    continue
  fi

  remote=$(remote_of "$dir")
  if [ -z "$remote" ]; then
    printf '  %s %s\n' "$label" "$(color.dim '没配远程，跳过')"
    continue
  fi

  if ! detail=$(git -C "$dir" fetch -q "$remote" 2>&1); then
    printf '  %s %s\n' "$label" "$(color.red '✖ fetch 失败')"
    printf '    %s\n' "$(color.dim "${detail%%$'\n'*}")"
    failed=1
    continue
  fi

  if ! main=$(main_of "$dir" "$remote"); then
    printf '  %s %s\n' "$label" "$(color.red "✖ 找不到 ${remote} 的主分支")"
    failed=1
    continue
  fi

  upstream="refs/remotes/$remote/$main"
  if ! before=$(git -C "$dir" rev-parse -q --verify "refs/heads/$main"); then
    printf '  %s %s\n' "$label" "$(color.dim "本地没有 ${main}，跳过")"
    continue
  fi
  after=$(git -C "$dir" rev-parse "$upstream")
  current=$(git -C "$dir" symbolic-ref -q --short HEAD || echo '')

  if [ "$before" = "$after" ] || git -C "$dir" merge-base --is-ancestor "$upstream" "refs/heads/$main"; then
    printf '  %s %s\n' "$label" "$(color.dim "✔ ${main} 已经是最新")"
    continue
  fi

  if ! git -C "$dir" merge-base --is-ancestor "refs/heads/$main" "$upstream"; then
    printf '  %s %s\n' "$label" "$(color.yellow "⚠ ${main} 和 ${remote} 分叉了，没动")"
    continue
  fi

  count=$(git -C "$dir" rev-list --count "$before..$after")
  if [ "$current" = "$main" ]; then
    if [ -n "$(git -C "$dir" status --porcelain)" ]; then
      printf '  %s %s\n' "$label" "$(color.yellow "⚠ 在 ${main} 上有没提交的改动，跳过")"
      continue
    fi
    if ! detail=$(git -C "$dir" merge -q --ff-only "$upstream" 2>&1); then
      printf '  %s %s\n' "$label" "$(color.red "✖ ${main} 快进失败")"
      printf '    %s\n' "$(color.dim "${detail%%$'\n'*}")"
      failed=1
      continue
    fi
    printf '  %s %s\n' "$label" "$(color.green "✔ ${main} 更新了 ${count} 个 commit")"
  else
    if ! detail=$(git -C "$dir" fetch -q . "$upstream:refs/heads/$main" 2>&1); then
      printf '  %s %s\n' "$label" "$(color.red "✖ ${main} 快进失败")"
      printf '    %s\n' "$(color.dim "${detail%%$'\n'*}")"
      failed=1
      continue
    fi
    printf '  %s %s %s\n' "$label" "$(color.green "✔ ${main} 更新了 ${count} 个 commit")" "$(color.dim "当前在 ${current:-detached}，没动")"
  fi
done

exit "$failed"
