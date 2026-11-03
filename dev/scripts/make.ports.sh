#!/usr/bin/env bash
# ============================================================
# 按 apps/ports.list 列出分配的端口和现在的状态
# 表里格式不对、端口重复、关不掉进程时算失败
# apps/ 下有进程占着表里没有的端口时只提醒
# stop= 先关进程再列表：端口关掉监听它的进程，app 关掉工作目录在它下面、正在监听端口的进程
# 多个同时关
# ============================================================
set -euo pipefail

WORKSPACE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$WORKSPACE_ROOT/dev/scripts/lib.color.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.log.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.app.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.port.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.proc.sh"

is_under() {
  [ -n "$2" ] || return 1
  case "$1/" in
    "$2"/*) return 0 ;;
  esac
  return 1
}

# ============================================================
# pids_of <端口或 app 名>：一行一个「pid 说明」
# 端口找监听它的进程，app 找工作目录在它下面、正在监听端口的进程
# ============================================================
pids_of() {
  local target=$1 pid dir
  if port.valid "$target"; then
    awk -v port="$target" '$2 == port && !seen[$1]++ { print $1 }' <<< "$listeners" | while read -r pid; do
      printf '%s 端口 %s\n' "$pid" "$target"
    done
    return 0
  fi
  dir=$(cd "$(app.dir "$target")" && pwd -P)
  for pid in $(awk '!seen[$1]++ { print $1 }' <<< "$listeners"); do
    if is_under "$(proc.cwd "$pid")" "$dir"; then
      printf '%s apps/%s\n' "$pid" "$target"
    fi
  done
}

failed=0
targets=$(app.split "${1:-}")
if [ -n "$targets" ]; then
  bad=0
  for target in $targets; do
    if ! port.valid "$target" && ! app.exists "$target"; then
      log.error "不是端口也不是 app：$target"
      bad=1
    fi
  done
  if [ "$bad" = 1 ]; then
    log.hint 'stop= 后面写 1 到 65535 的端口或 app 名，多个用逗号隔开'
    app.hint
    exit 2
  fi

  # ============================================================
  # 几个目标可能指向同一个进程（app 和它的端口一起写），按 pid 去重
  # 后台只管关进程，结果等都关完后按顺序打，log 不会交错
  # ============================================================
  listeners=$(port.listeners)
  found=''
  for target in $targets; do
    lines=$(pids_of "$target")
    if [ -z "$lines" ]; then
      if port.valid "$target"; then
        log.ok "没有进程在监听端口 $target"
      else
        log.ok "没有进程在监听 apps/$target"
      fi
    fi
    found="$found$lines"$'\n'
  done
  found=$(awk 'NF && !seen[$1]++' <<< "$found")

  waiting=''
  commands=''
  while read -r pid what; do
    [ -n "$pid" ] || continue
    commands="$commands$pid $(proc.command "$pid")"$'\n'
    proc.stop "$pid" &
    waiting="$waiting $pid:$!"
  done <<< "$found"

  while read -r pid what; do
    [ -n "$pid" ] || continue
    for pair in $waiting; do
      [ "${pair%%:*}" = "$pid" ] || continue
      ports=$(awk -v pid="$pid" '$1 == pid { print $2 }' <<< "$listeners" | sort -un | tr '\n' ' ')
      command=$(awk -v pid="$pid" '$1 == pid { $1 = ""; sub(/^ /, ""); print; exit }' <<< "$commands")
      if wait "${pair#*:}"; then
        log.ok "${what}：关掉 ${command:-进程} · pid $pid · 端口 ${ports% }"
      else
        log.error "${what}：关不掉 $command · pid $pid"
        failed=1
      fi
    done
  done <<< "$found"
  echo
fi

if [ ! -f "$APP_PORTS_FILE" ]; then
  log.warn '还没有 apps/ports.list'
  log.hint '照 apps/ports.list.example 建 apps/ports.list 登记端口'
  exit "$failed"
fi

entries=$(app.port_entries)
listeners=$(port.listeners)
apps_root=$(cd "$WORKSPACE_ROOT/apps" && pwd -P)

log.title '端口'
if [ -z "$entries" ]; then
  printf '  %s\n' "$(color.dim 'apps/ports.list 里还没有登记')"
fi

# ============================================================
# 一个 app 一段：app 名一行，下面一行一个端口，要处理的再跟一行说明
# 说明行缩进到状态那一列：4 + 变量名 26 + 1 + 端口 5 + 2
# ============================================================
for name in $(awk '!seen[$1]++ { print $1 }' <<< "$entries"); do
  echo
  dir=''
  if app.exists "$name"; then
    dir=$(cd "$(app.dir "$name")" && pwd -P)
    printf '  %s\n' "$(color.bold "$(color.cyan "$name")")"
  else
    printf '  %s %s\n' "$(color.bold "$(color.cyan "$name")")" "$(color.dim '还没 clone')"
  fi

  while read -r app var port; do
    [ "$app" = "$name" ] || continue
    note=''
    if ! app.valid_port_var "$var" || ! port.valid "$port"; then
      state=$(color.red '✖ 格式不对')
      note='一行是「app 名 变量名 端口」，变量名用大写字母、数字、下划线'
      failed=1
    else
      others=$(awk -v port="$port" -v app="$app" -v var="$var" '$3 == port && !($1 == app && $2 == var) { print $1 }' <<< "$entries" | sort -u | tr '\n' ' ')
      pid=$(awk -v port="$port" '$2 == port { print $1; exit }' <<< "$listeners")
      if [ -n "$others" ]; then
        state=$(color.red "✖ 和 ${others% } 重复")
        note='改掉 apps/ports.list 里其中一行'
        failed=1
      elif [ -z "$pid" ]; then
        state=$(color.dim '○ 空闲')
      elif is_under "$(proc.cwd "$pid")" "$dir"; then
        state=$(color.green '● 正在运行')
      else
        state=$(color.yellow "⚠ 被别的程序占着（$(proc.command "$pid")）")
        note="这个 app 用到它时会启动失败。关掉：make ports stop=$port"
      fi
    fi
    printf '    %s %s  %s\n' "$(color.dim "$(printf '%-26s' "$var")")" "$(color.yellow "$(printf '%5s' "$port")")" "$state"
    if [ -n "$note" ]; then
      printf '%38s%s\n' '' "$(color.dim "$note")"
    fi
  done <<< "$entries"
done

# ============================================================
# apps/ 下在监听、但表里没有的端口
# ============================================================
undeclared=''
for pid in $(awk '!seen[$1]++ { print $1 }' <<< "$listeners"); do
  cwd=$(proc.cwd "$pid")
  is_under "$cwd" "$apps_root" || continue
  rel=${cwd#"$apps_root"/}
  owner=${rel%%/*}
  for port in $(awk -v pid="$pid" '$1 == pid { print $2 }' <<< "$listeners"); do
    if ! awk -v port="$port" '$3 == port { found = 1 } END { exit found ? 0 : 1 }' <<< "$entries"; then
      undeclared="$undeclared$owner $port $(proc.command "$pid")"$'\n'
    fi
  done
done

if [ -n "$undeclared" ]; then
  echo
  log.warn 'apps/ 下有进程占着表里没有的端口'
  while read -r owner port command; do
    [ -n "$owner" ] || continue
    printf '    %s %s  %s\n' "$(color.dim "$(printf '%-26s' "$owner")")" "$(color.yellow "$(printf '%5s' "$port")")" "$(color.dim "$command")"
  done <<< "$undeclared"
  log.hint '登记到 apps/ports.list，app 从环境变量读端口'
fi

exit "$failed"
