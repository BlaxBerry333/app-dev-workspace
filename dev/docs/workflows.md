# 流程

## 新开一个 app

1. 在 `apps/` 下建好，`git init`
2. 在 GitHub 建好仓库，`git remote add origin <地址>`
3. `apps/apps.list` 加一行，没有这个文件就照 `.example` 新建：app 名、可见性、地址。可见性写 public 或 private，省略就是 public
4. 跑 `make ports` 看哪段空着，`apps/ports.list` 给它登记端口
5. `make setup app=<app>`

## 换电脑

1. clone 这个仓库
2. 把旧电脑的 `apps/apps.list`、`apps/ports.list` 放回来；格式看同名的 `.example`
3. `make setup`：按清单把 app 都 clone 下来并跑 `setup`
4. `.claude/launch.json`、`dev/notes/`、各 app 的 `.env.local` 不进 git，自己带过去
