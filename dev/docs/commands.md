# 命令

| 命令                               | 做什么                                                                 |
| ---------------------------------- | ---------------------------------------------------------------------- |
| `make`                             | 列出命令和 app                                                         |
| `make setup [app=<app>[,<app>…]]`  | clone 清单里还没有的 app，跑各 app 的 `setup`；带 `app=` 只管这几个    |
| `make status`                      | 看每个 app 有没有没提交、没 push 的                                    |
| `make update`                      | 拉各 app 远端的主分支，只快进本地主分支，正在开发的分支不动            |
| `make start app=<app>[,<app>…]`    | 转给 app 的 `dev`；多个 app 同时起，每行输出前标 app 名，Ctrl-C 一起关 |
| `make ports`                       | 列出 `apps/ports.list` 分配的端口和现在谁在用，查出重复的              |
| `make ports stop=<端口或 app>[,…]` | 先关掉这些进程再列表，多个同时关                                       |

app 建议要有 `dev` 命令。没有 `Makefile` 的 app 用 `package.json` 的 scripts，`setup` 没有时就是 `npm install`；有 `Makefile` 但没有 `setup` 的，`make setup` 跳过它。打包、测试各 app 不一样，按 app 自己的 README。

端口由工作区分配，写在 `apps/ports.list`，一行一个「app 名 变量名 端口」。`make setup`、`make start` 转发前把这个 app 的几行作为环境变量传进去，app 自己 `.env` 里的同名变量盖不过它。

`apps/` 下有 app、`apps/apps.list` 或 `apps/ports.list` 还没有时，`make setup` 建出来，只写一个框着列名的分隔框。没有 app 时不建，只给提示。

`make update` 只动主分支：远端用 `origin`，主分支看远端的 HEAD，没有就试 `main`、`master`。当前就在主分支上时，有没提交的改动就跳过；主分支和远端分叉了不合并，只报出来。
