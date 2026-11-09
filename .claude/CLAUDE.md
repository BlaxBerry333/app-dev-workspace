# app-dev-workspace

## 回答

- 必须用中文，称呼我为【我尊敬的领主大人】
- 不要 AI 腔：不客套、不复述问题、不说套话，直接说结论
- 做完事情要说明做了什么：改了哪些文件、各改了什么、哪些没做或没验证
- 检查的结果只报有问题的。没问题就一句「没问题」，不列清单、不写没问题的项

## 做事

- 不确定的地方先问，不要猜着做
- 只做要求的事，不顺手改别的
- 删文件、整个重写一个已有文件之前先问我，我明确说了要删、要改的除外；按要求改文件的某处不算
- 我定的文件名、目录名照原样用，跟规则冲突时先问我，不要建议改名
- 看、改项目里的文件先用 Read 工具读，不用 `cat`、`sed`、`head` 代替：`.claude/rules/` 按路径加载的规则只在 Read 时加载
- 测试用的临时文件跑完就删；测试不访问网络
- 不污染宿主机：不全局安装、不开机自启、不往家目录写数据
  - 运行时的版本由项目自己指定，用本机已有的版本管理工具；要装新版本先问我
  - 依赖包、工具只装进用它的那个项目里
  - 项目自己的缓存放 `.cache/`，不进 git。npm、pnpm、Go 自己的缓存先不管

## Git

- 不准自己 commit 或 push，也不要主动问要不要提交。commit message 写好给我过目，由我自己提交
- 写 commit message 之前先用 `commit` skill
- 密钥、token、私有路径不写进任何被 git 跟踪的文件和 commit message

## 动 app 之前

- 先读 `dev/notes/<app>/TODO.md` 和 `apps/<app>/README.md`，再按 README 里的链接读跟这次改动有关的文档，按里面的约定做
- 搜 app 的代码要指定 `apps/<app>/` 目录。`.gitignore` 忽略了 `apps/*/`，从根目录全局搜找不到 app 里的文件
- 起 app 只用 `make start app=<app>`，关只用 `make ports stop=<app 或端口>`，不自己 `cd` 进去跑 `npm` 或 `make`。打包、测试按 app 的 README
- 要在浏览器里看 app，先跑 `make ports`。已经在跑就直接用那个端口，不另起、不换端口；没在跑才自己起，看完就关。我起的不关
- 端口只用 `apps/ports.list` 分配的。要新端口先跑 `make ports` 看哪段空着，登记进表里

## 目录

- app 在这个工作区里开发，会话开在工作区根目录。工作区的规矩对 app 同样有效
- app 仓库里不放任何 Claude 相关的文件。工作区的规矩按类别写（web 项目、游戏这类），只适用于某一个 app 的约定写在 app 仓库自己的 README 和它链接的文档里；跟工作区冲突时先问我
- 根目录里进 git 的文件只放 `Makefile`、`README.md` 和 git 相关的
- 新开的 app 在 `apps/` 下建好，登记到 `apps/apps.list`，端口登记到 `apps/ports.list`，这两个文件不进 git；属于游戏、Vite 单页项目这类的再加进那类 `dev.*.md` 的 `paths`
- `dev/notes/` 是我自己的笔记，不进 git。只有 `TODO.md`（工作区的计划）和 `<app>/TODO.md`（各 app 的进度和计划）要读、要照着做，别的不是规矩，不按它们做事
