# ============================================================
# 进程
# ============================================================

proc.cwd() {
  { lsof -a -p "$1" -d cwd -Fn 2>/dev/null || true; } | awk '/^n/ { print substr($0, 2); exit }'
}

proc.command() {
  local command
  command=$(ps -p "$1" -o comm= 2>/dev/null || true)
  [ -n "$command" ] && basename "$command"
  return 0
}

# ============================================================
# 先 TERM，5 秒后还在就 KILL
# 进程已经不在了也算关掉
# ============================================================
proc.stop() {
  local i=0
  if ! kill "$1" 2>/dev/null; then
    ! kill -0 "$1" 2>/dev/null
    return
  fi
  while [ "$i" -lt 25 ]; do
    kill -0 "$1" 2>/dev/null || return 0
    sleep 0.2
    i=$((i + 1))
  done
  kill -9 "$1" 2>/dev/null || return 0
  sleep 0.2
  ! kill -0 "$1" 2>/dev/null
}
