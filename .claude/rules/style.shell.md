---
paths:
  - "Makefile"
  - "dev/scripts/**/*.sh"
  - "apps/*/{Makefile,scripts/**/*.sh}"
---

# Makefile 和 shell 脚本

工作区和 app 仓库的 Makefile、shell 脚本都按这里写。app 不一定有 Makefile、`scripts/`、shell 脚本，没有的不用为了这里去建。

- 改了工作区的命令、流程，同步改 `dev/docs/` 里对应的文档
- `Makefile` 只登记入口。每个目标正上方一个分隔框，不写目标名：第一行是说明，参数另起一行（`make help` 读它，参数行缩进显示）
- 逻辑写在工作区的 `dev/scripts/`、app 仓库根目录的 `scripts/`。shell 脚本要能在 macOS 自带的 bash 3.2 上跑
- shell 脚本开头固定：`#!/usr/bin/env bash`、分隔框写这个脚本怎么做、要注意什么（不重复文件名，用法写在 Makefile 里）、`set -euo pipefail`、算出仓库根目录（工作区的叫 `WORKSPACE_ROOT`）、依次 source `lib.color.sh`、`lib.log.sh` 和用到的 lib
- 文件名：`lib.<组>.sh` 放共用函数，`make.<命令>.sh` 是 Makefile 调用的命令（转发单个 app 的 `setup`、`dev` 用 `make.run.sh`，`make setup app=`、`make start` 都调它）
- 函数名：`<组>.<动作>`，组名和所在的 `lib.<组>.sh` 一致。只在一个 `make.<命令>.sh` 里用的小函数写在那个脚本里，用小写加下划线，比如 `stop_one`
- 变量名：共用的用大写 `<组>_<名字>`，临时的用小写
- 变量后面紧跟中文或全角符号时写成 `${变量}`：终端是 UTF-8 时，bash 3.2 会把全角字符当成变量名的一部分，`$want，` 会报变量未定义
- 终端输出只用 `log.*` / `color.*`
  - 单独一行的结果用 `log.ok`、`log.warn`、`log.error`，带颜色和「✔ 完成」「⚠ 警告」「✖ 错误」前缀；警告和错误走 stderr
  - 下一步怎么做用 `log.hint`，跟在警告、错误后面
  - 一条 log 连同后面的 `log.hint` 算一块，块和块之间、出错退出前的最后一块后面，`lib.log.sh` 会自动空一行，脚本里不用自己加 `echo`
  - 表格里每行的状态用 `color.*`
  - `setup` 这类准备步骤，已经就绪、不用做的也用 `log.ok` 说一声
  - 自己往 stderr 写带颜色的内容时，函数里先 `local COLOR_TO_STDERR=1`，颜色才按 stderr 是不是终端来判断
- `lib.log.sh` 的 ERR 陷阱会在命令意外失败时报出哪个脚本、哪条命令；预料中会失败的命令放在 `if`、`||` 里自己处理
- `lib.log.sh` 还占了 EXIT 陷阱。脚本要自己的 EXIT 陷阱时，在里面先调 `log.on-exit $?`，不然出错退出前不空行
- app 有 shell 脚本时，`lib.color.sh`、`lib.log.sh` 从工作区复制过去，工作区的改了要同步
- 测工作区的脚本不用真实的 `apps/apps.list`、`apps/ports.list`，在副本里放假的
