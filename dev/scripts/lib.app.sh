# ============================================================
# app
# 要先设好 WORKSPACE_ROOT
# 用 app.hint 要先 source lib.log.sh
# ============================================================

APP_LIST_FILE="$WORKSPACE_ROOT/apps/apps.list"
APP_PORTS_FILE="$WORKSPACE_ROOT/apps/ports.list"

app.list() {
  local dir
  for dir in "$WORKSPACE_ROOT"/apps/*/; do
    [ -d "$dir" ] && basename "$dir"
  done
  return 0
}

# ============================================================
# 清单一行一个「app 名 可见性 git 地址」，以 # 开头的行是注释
# 可见性是 public 或 private，省略就是 public
# 地址可以先空着
# 输出统一成「app 名 可见性 地址」，可见性一定有，地址可能空
# ============================================================
app.entries() {
  local name second url visibility
  [ -f "$APP_LIST_FILE" ] || return 0
  while read -r name second url || [ -n "$name" ]; do
    case "$name" in
      '' | '#'*) continue ;;
    esac
    case "$second" in
      public | private) visibility=$second ;;
      *)
        visibility=public
        url=$second
        ;;
    esac
    printf '%s %s %s\n' "$name" "$visibility" "$url"
  done < "$APP_LIST_FILE"
}

app.registered() { app.entries | awk '!seen[$1]++ { print $1 }'; }

app.is_registered() {
  local name
  for name in $(app.registered); do
    [ "$name" = "$1" ] && return 0
  done
  return 1
}

app.url() {
  local name visibility url
  while read -r name visibility url; do
    if [ "$name" = "$1" ]; then
      printf '%s' "$url"
      return 0
    fi
  done <<< "$(app.entries)"
  return 0
}

app.is_private() { app.entries | awk -v app="$1" '$1 == app { found = ($2 == "private") } END { exit found ? 0 : 1 }'; }

# ============================================================
# 端口表一行一个「app 名 变量名 端口」，以 # 开头的行是注释
# ============================================================
app.port_entries() {
  local name var port
  [ -f "$APP_PORTS_FILE" ] || return 0
  while read -r name var port || [ -n "$name" ]; do
    case "$name" in
      '' | '#'*) continue ;;
    esac
    printf '%s %s %s\n' "$name" "$var" "$port"
  done < "$APP_PORTS_FILE"
}

# ============================================================
# app.ports <app 名>：这个 app 分到的端口，一行一个「变量名 端口」
# ============================================================
app.ports() { app.port_entries | awk -v app="$1" '$1 == app { print $2, $3 }'; }

app.valid_port_var() { printf '%s' "$1" | grep -qE '^[A-Z][A-Z0-9_]*$'; }

# ============================================================
# app.split <a,b,c>：逗号隔开的参数拆成一行一个，去掉空白、空的和重复的
# ============================================================
app.split() { printf '%s\n' "$1" | tr ',' '\n' | awk '{ gsub(/[[:space:]]/, "") } NF && !seen[$0]++'; }

app.dir() { printf '%s/apps/%s' "$WORKSPACE_ROOT" "$1"; }

app.valid() {
  case "$1" in
    '' | .* | */*) return 1 ;;
  esac
  return 0
}

app.exists() { app.valid "$1" && [ -d "$(app.dir "$1")" ]; }

# ============================================================
# 按清单里的地址 clone 到 apps/<app 名>
# git 的报错走 stderr，调用的地方自己收起来再显示
# ============================================================
app.clone() { git clone -q "$(app.url "$1")" "$(app.dir "$1")"; }

# ============================================================
# 怎么驱动：有 Makefile 用 make，没有但有 package.json 用 npm，都没有就驱动不了
# ============================================================
app.runner() {
  local dir
  dir=$(app.dir "$1")
  if [ -f "$dir/Makefile" ]; then
    printf 'make'
  elif [ -f "$dir/package.json" ]; then
    printf 'npm'
  else
    printf 'none'
  fi
}

# ============================================================
# app.has_script <app 名> <名字>：package.json 的 scripts 里有没有这一项
# 只看 "scripts": { … } 这一段，不用 node
# 整段写在一行里也认，段落在第一个 } 结束
# ============================================================
app.has_script() {
  awk -v key="$2" '
    !inside {
      i = index($0, "\"scripts\"")
      if (i == 0) next
      $0 = substr($0, i + 9)
      inside = 1
    }
    {
      last = sub(/\}.*/, "")
      if ($0 ~ "\"" key "\"[[:space:]]*:") { found = 1; exit }
      if (last) exit
    }
    END { exit found ? 0 : 1 }
  ' "$(app.dir "$1")/package.json"
}

# ============================================================
# app.has_target <app 名> <命令>：这个 app 能不能回答 setup / dev
# make 看 Makefile 里有没有目标
# npm 看 scripts，setup 没有 scripts 时退回 npm install，所以总是能
# ============================================================
app.has_target() {
  case "$(app.runner "$1")" in
    make) grep -qE "^$2:" "$(app.dir "$1")/Makefile" ;;
    npm) [ "$2" = setup ] || app.has_script "$1" "$2" ;;
    *) return 1 ;;
  esac
}

# ============================================================
# app.run <app 名> <命令>：exec 过去，信号直接到 make / npm
# 先清掉工作区 make 的 MAKEFLAGS：参数里带空格时会漏出没有等号的词，被 app 的 make 当成 -p -i 这类选项
# ============================================================
app.run() {
  local dir
  dir=$(app.dir "$1")
  unset MAKEFLAGS MFLAGS MAKEOVERRIDES
  case "$(app.runner "$1")" in
    make) exec make --no-print-directory -C "$dir" "$2" ;;
    npm)
      cd "$dir"
      if [ "$2" = setup ] && ! app.has_script "$1" setup; then
        exec npm install
      fi
      exec npm run "$2"
      ;;
  esac
  return 1
}

# ============================================================
# 出错时提示现有的 app
# 一个都没有时告诉下一步怎么做
# ============================================================
app.hint() {
  local apps
  apps=$(app.list | tr '\n' ' ')
  apps=${apps% }
  if [ -n "$apps" ]; then
    log.hint "现有 app：$apps"
  else
    log.hint '还没有 app：照 apps/apps.list.example 建 apps/apps.list，登记后跑 make setup'
  fi
}
