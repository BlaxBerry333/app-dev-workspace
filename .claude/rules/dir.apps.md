---
paths:
  - "apps/*/**"
---

# app

- app 建议要有 `dev`，没有的不能用 `make start`；要装依赖、准备本地配置的再加 `setup`，跑几次结果都一样。根目录有 `Makefile` 就用它的目标，没有就用 `package.json` 的 scripts。工作区的 `make setup app=`、`make start app=` 按这个顺序找，分别转给 `setup`、`dev`
- 端口由工作区在 `apps/ports.list` 分配，`make setup`、`make start` 时作为环境变量传进来，盖过 app 自己 `.env` 里的同名变量。app 里端口一律从变量读，不写死；`.env.example` 写同名变量的默认值，单独跑时用。变量名用 `<APP>__<用途>_PORT`，比如 `MY_APP__WEB_PORT`
- app 是各自独立的产品，离了工作区和别的 app 也能用
- 密钥放 app 自己的 `.env.local`，不进 git。`.env.example` 列出所有变量名和说明，值是本地开发用的，进 git
- 进度和计划（路线、顺序、风险）写在工作区的 `dev/notes/<app>/TODO.md`（不进 git），app 仓库里不放计划。至少分「现在在做」「接下来」，还没有就先建上。开始做一项就挪到「现在在做」，做完就删掉。只写现在的状态，不写经过
