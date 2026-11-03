#!/usr/bin/env bash
# ============================================================
# 转给各 app 的 dev
# 一个 app 时直接转过去，跟在它自己目录里跑一样
# 多个 app 时同时起，每行输出前标上 app 名
# Ctrl-C 一起关掉
# ============================================================
set -euo pipefail

WORKSPACE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$WORKSPACE_ROOT/dev/scripts/lib.color.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.log.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.app.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.port.sh"

names=$(app.split "${1:-}")
if [ -z "$names" ]; then
  log.error '要指定 app：make start app=<app 名>，多个用逗号隔开'
  app.hint
  exit 2
fi

# ============================================================
# 先全部检查一遍，有一个不对就都不起
# ============================================================
bad=0
for name in $names; do
  if ! app.exists "$name"; then
    log.error "没有这个 app：$name"
    bad=1
  elif ! app.has_target "$name" dev; then
    log.error "apps/$name 没有 dev"
    case "$(app.runner "$name")" in
      make) log.hint 'Makefile 里加一个 dev 目标' ;;
      npm) log.hint 'package.json 的 scripts 里加一个 dev' ;;
      *) log.hint 'app 根目录加一个 Makefile，写上 dev 目标' ;;
    esac
    bad=1
  fi
  while read -r var port; do
    [ -n "$var" ] || continue
    if ! app.valid_port_var "$var" || ! port.valid "$port"; then
      log.error "apps/ports.list 里 ${name} 的这行不对：$var $port"
      bad=1
    fi
  done <<< "$(app.ports "$name")"
done
if [ "$bad" = 1 ]; then
  app.hint
  exit 2
fi

if [ "$(printf '%s\n' "$names" | wc -l | tr -d ' ')" = 1 ]; then
  exec "$WORKSPACE_ROOT/dev/scripts/make.run.sh" dev "$names"
fi

# ============================================================
# 多个 app：每个放在自己的进程组里，关的时候整组关，app 起的子进程也跟着停
# 后台任务在非交互的 bash 里收不到 Ctrl-C，所以由这里收到后转发 TERM
# 起完就关掉作业控制，被关掉的任务就不会打「Terminated」
# ============================================================
set -m

# ============================================================
# 有 Makefile 的 app 被 make ports stop= 关掉时，make 只报一行「*** [dev] Terminated」并以 2 退出
# 看到这行就不打出来，按被信号关掉算
# ============================================================
make_killed='^g?make(\[[0-9]+\])?: \*\*\* \[[^]]*\] (Terminated|Killed|Interrupt|Hangup|Error (129|1[3-9][0-9]|2[0-4][0-9]|25[0-5]))'

width=$(printf '%s\n' "$names" | awk '{ if (length > w) w = length } END { print w }')
colors='color.cyan color.green color.yellow'
pids=''

stop_all() {
  local pid
  for pid in $pids; do
    kill -TERM -- "-$pid" 2>/dev/null || true
  done
}
trap stop_all INT TERM

i=0
for name in $names; do
  set -- $colors
  shift $((i % 3))
  label=$("$1" "$(printf "%-${width}s │" "$name")")
  (
    "$WORKSPACE_ROOT/dev/scripts/make.run.sh" dev "$name" 2>&1 | {
      killed=0
      while IFS= read -r line; do
        if [[ $line =~ $make_killed ]]; then
          killed=1
          continue
        fi
        printf '%s %s\n' "$label" "$line"
      done
      [ "$killed" = 0 ] || exit 143
    }
  ) 2>/dev/null &
  pids="$pids $!"
  i=$((i + 1))
done

set +m

# ============================================================
# 按顺序等每个 app 结束
# wait 被信号打断时返回 128 以上但进程还在，要接着等
# 被信号关掉的（Ctrl-C，或者 make ports stop= 从外面关的）退出码大于 128，不算失败
# ============================================================
summary=''
failed=0
set -- $pids
for name in $names; do
  pid=$1
  shift
  status=0
  while true; do
    if wait "$pid"; then
      status=0
    else
      status=$?
    fi
    kill -0 "$pid" 2>/dev/null || break
  done
  label=$(printf '%-12s' "$name")
  if [ "$status" = 0 ]; then
    summary="$summary  $label $(color.green '✔ 结束了')"$'\n'
  elif [ "$status" -gt 128 ]; then
    summary="$summary  $label $(color.dim '○ 关掉了')"$'\n'
  else
    summary="$summary  $label $(color.red "✖ 退出码 $status")"$'\n'
    failed=1
  fi
done

echo
log.title 'app'
printf '%s' "$summary"
exit "$failed"
