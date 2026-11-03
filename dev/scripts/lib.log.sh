# ============================================================
# 终端输出
# 要先 source lib.color.sh
# log.ok 走 stdout，log.warn、log.error、log.hint 走 stderr
# ============================================================

# ============================================================
# 一条 log 连同跟在后面的 log.hint 算一块，块和块之间空一行
# LOG_IN_BLOCK 记着上一块打过没有
# 空行跟着下一块走同一个输出
# log.title 开始新的一段，清掉记录，后面的表格不算 log 块
# ============================================================
LOG_IN_BLOCK=0

log.title() { LOG_IN_BLOCK=0; printf '%s\n' "$(color.bold "$1")"; }
log.step()  { printf '%s\n' "$(color.bold "$(color.cyan "▶ $1")")"; }

log.ok() {
  [ "$LOG_IN_BLOCK" = 1 ] && echo
  LOG_IN_BLOCK=1
  printf '%s  %s\n' "$(color.green '✔ 完成')" "$1"
}

log.warn() {
  local COLOR_TO_STDERR=1
  [ "$LOG_IN_BLOCK" = 1 ] && echo >&2
  LOG_IN_BLOCK=1
  printf '%s  %s\n' "$(color.yellow '⚠ 警告')" "$1" >&2
}

log.error() {
  local COLOR_TO_STDERR=1
  [ "$LOG_IN_BLOCK" = 1 ] && echo >&2
  LOG_IN_BLOCK=1
  printf '%s  %s\n' "$(color.red '✖ 错误')" "$1" >&2
}

# ============================================================
# 跟在 log.warn、log.error 后面，说下一步怎么做
# 缩进到跟上一行的正文对齐
# ============================================================
log.hint() { local COLOR_TO_STDERR=1; printf '        %s\n' "$(color.dim "$1")" >&2; }

# ============================================================
# 命令意外失败时（set -e 会让脚本直接退出），先说清楚是哪个脚本、哪条命令
# 不报行号：bash 3.2 在函数和 if 里报的行号不准
# errtrace 让函数里的失败也能触发
# $( ) 里的失败交给外面判断：
# 外面当条件用（if、||）时本来就是预料中的，不当条件用时外面会再触发一次
# ============================================================
log.on-error() {
  [ "$BASH_SUBSHELL" -gt 0 ] && return 0
  log.error "$(basename "$3") 里这条命令出错：$2（退出码 $1）"
}

# ============================================================
# 出错退出时，最后一块 log 后面空一行，跟 make 接着打的报错分开
# ============================================================
log.on-exit() {
  [ "$1" != 0 ] && [ "$LOG_IN_BLOCK" = 1 ] && [ "$BASH_SUBSHELL" = 0 ] && echo >&2
  return 0
}

set -o errtrace
trap 'log.on-error $? "$BASH_COMMAND" "${BASH_SOURCE[0]}"' ERR
trap 'log.on-exit $?' EXIT
