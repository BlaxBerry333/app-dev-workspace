#!/usr/bin/env bash
# ============================================================
# 登记了还没 clone 的先 clone，再跑 app 的 setup
# 跑几次结果都一样，只有 clone 时要联网
# 不带 app= 时是全部：清单里登记的在前，没登记、只在本地的在后
# 带 app= 时只管这几个，检查和汇总跟全部时一样
# 有 app 时，还没有的 apps.list、ports.list 建出来，只写一个分隔框，框里是同名 .example 里的列名
# 没有 app 时不建，只给提示
# 建完自己空一行：后面接的是 log.step、log.title 或 app 的输出，lib.log.sh 不会自动空行
# ============================================================
set -euo pipefail

WORKSPACE_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
source "$WORKSPACE_ROOT/dev/scripts/lib.color.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.log.sh"
source "$WORKSPACE_ROOT/dev/scripts/lib.app.sh"

all=$(
  app.registered
  app.list | while read -r local_name; do
    app.is_registered "$local_name" || printf '%s\n' "$local_name"
  done
)

# ============================================================
# 带 app= 时先全部检查一遍，有一个不认识就都不跑
# ============================================================
names=$(app.split "${1:-}")
if [ -n "$names" ]; then
  bad=0
  for name in $names; do
    if ! printf '%s\n' "$all" | grep -qxF -- "$name"; then
      log.error "没有这个 app：$name"
      bad=1
    fi
  done
  if [ "$bad" = 1 ]; then
    if [ -n "$all" ]; then
      log.hint "现有 app：$(printf '%s\n' "$all" | paste -sd ' ' -)"
    fi
    log.hint '新的 app 先登记进 apps/apps.list'
    exit 2
  fi
else
  if [ -z "$all" ]; then
    log.warn '还没有 app'
    log.hint '照 apps/apps.list.example 建 apps/apps.list 登记 app，端口照 apps/ports.list.example 登记到 apps/ports.list，再跑 make setup'
    exit 0
  fi
  names=$all
fi

for file in "$APP_LIST_FILE" "$APP_PORTS_FILE"; do
  rel=${file#"$WORKSPACE_ROOT"/}
  if [ -e "$file" ]; then
    log.ok "已经有 ${rel}"
  else
    line='# ============================================================'
    printf '%s\n%s\n%s\n' "$line" "$(grep -m1 '^# <app 名>' "$file.example")" "$line" > "$file"
    log.ok "建了 ${rel}，只有列名"
    log.hint "照 ${rel}.example 登记"
  fi
done
echo
LOG_IN_BLOCK=0

summary=''
failed=0
for name in $names; do
  dir=$(app.dir "$name")
  label=$(printf '%-12s' "$name")
  note=''

  if app.is_registered "$name"; then
    if ! app.valid "$name"; then
      summary="$summary  $label $(color.red '✖ app 名不能用：不能以 . 开头，也不能带 /')"$'\n'
      failed=1
      continue
    fi
    if [ ! -e "$dir" ]; then
      if [ -z "$(app.url "$name")" ]; then
        summary="$summary  $label $(color.red '✖ 还没 clone，清单里也没写 git 地址')"$'\n'
        failed=1
        continue
      fi
      log.step "$name · clone"
      if ! detail=$(app.clone "$name" 2>&1); then
        log.error "clone 失败：apps/$name"
        log.hint "${detail%%$'\n'*}"
        echo
        summary="$summary  $label $(color.red '✖ clone 失败')"$'\n'
        failed=1
        continue
      fi
      note='clone 了，'
    elif [ ! -e "$dir/.git" ]; then
      summary="$summary  $label $(color.red '✖ 文件夹已经存在，但不是 git 仓库')"$'\n'
      failed=1
      continue
    fi
  else
    note='没登记在清单里，'
  fi

  if ! app.has_target "$name" setup; then
    summary="$summary  $label $(color.dim "✔ ${note}没有 setup")"$'\n'
    continue
  fi

  if "$WORKSPACE_ROOT/dev/scripts/make.run.sh" setup "$name"; then
    summary="$summary  $label $(color.green "✔ ${note}setup 完成")"$'\n'
  else
    summary="$summary  $label $(color.red "✖ ${note}setup 失败")"$'\n'
    failed=1
  fi
  echo
done

log.title 'app'
printf '%s' "$summary"
exit "$failed"
