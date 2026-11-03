#!/usr/bin/env bash
# ============================================================
# 转发一个 app 的 setup 或 dev
# make setup app=、make start 都转到这里
# make start 多个 app 时每个 app 调一次
# 有 Makefile 转给 make，没有转给 npm run
# setup 没有 scripts 时是 npm install
# 端口以 apps/ports.list 为准，作为环境变量传给 app，app 自己 .env 里的同名变量盖不过它
# ============================================================
set -euo pipefail

WORKSPACE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$WORKSPACE_ROOT/dev/scripts/lib.color.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.log.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.app.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.port.sh"

target=$1
name=${2:-}

if [ -z "$name" ]; then
  log.error "要指定 app"
  app.hint
  exit 2
fi

if ! app.exists "$name"; then
  log.error "没有这个 app：$name"
  app.hint
  exit 2
fi

case "$(app.runner "$name")" in
  make) ;;
  npm) ;;
  *)
    log.error "apps/$name 里没有 Makefile 也没有 package.json，不知道怎么跑 $target"
    exit 2
    ;;
esac

if ! app.has_target "$name" "$target"; then
  log.error "apps/$name 没有 $target"
  case "$(app.runner "$name")" in
    make) log.hint "Makefile 里加一个 $target 目标" ;;
    npm) log.hint "package.json 的 scripts 里加一个 $target" ;;
  esac
  exit 2
fi

ports=''
while read -r var port; do
  [ -n "$var" ] || continue
  if ! app.valid_port_var "$var" || ! port.valid "$port"; then
    log.error "apps/ports.list 里 ${name} 的这行不对：$var $port"
    log.hint '一行是「app 名 变量名 端口」，变量名用大写字母、数字、下划线，端口是 1 到 65535'
    exit 2
  fi
  export "$var=$port"
  ports="$ports $var=$port"
done <<< "$(app.ports "$name")"

log.step "$name · $target"
if [ -n "$ports" ]; then
  printf '%s\n' "$(color.dim "端口${ports}")"
fi
app.run "$name" "$target"
