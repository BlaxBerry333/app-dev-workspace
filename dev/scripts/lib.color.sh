# ============================================================
# 颜色
# 不在终端里或设了 NO_COLOR 时不上色
# stdout、stderr 分开判断：
# 写到 stderr 的地方先 local COLOR_TO_STDERR=1，里面调用的 color.* 就按 stderr 判断
# ============================================================

COLOR_STDOUT=0
COLOR_STDERR=0
if [ -z "${NO_COLOR:-}" ]; then
  if [ -t 1 ]; then COLOR_STDOUT=1; fi
  if [ -t 2 ]; then COLOR_STDERR=1; fi
fi

color.wrap() {
  local enabled=$COLOR_STDOUT
  if [ "${COLOR_TO_STDERR:-0}" = 1 ]; then enabled=$COLOR_STDERR; fi
  if [ "$enabled" = 1 ]; then
    printf '\033[%sm%s\033[0m' "$1" "$2"
  else
    printf '%s' "$2"
  fi
}

color.bold()   { color.wrap 1 "$1"; }
color.dim()    { color.wrap 2 "$1"; }
color.red()    { color.wrap 31 "$1"; }
color.green()  { color.wrap 32 "$1"; }
color.yellow() { color.wrap 33 "$1"; }
color.cyan()   { color.wrap 36 "$1"; }
