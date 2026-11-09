---
paths:
  - "{apps/*,dev/playground}/**/*.{ts,tsx,js,mjs,css,scss,html,astro}"
  - "{apps/*,dev/playground}/**/{package.json,pnpm-workspace.yaml,tsconfig*.json,configs/**,.husky/**,.env*}"
---

# web 项目

## 根目录

- tsconfig、`package.json`、`.tool-versions`、`.gitignore` 这类配置留在根目录。用 pnpm workspaces 时 `.tool-versions` 放 workspaces 的根，见下面一节
- lint、format 的配置放 `configs/`，文件名不加点：`configs/oxlint.json`、`configs/prettier.json`、`configs/prettierignore`
  - oxlint：`package.json` 的命令里写 `-c configs/oxlint.json`
  - prettier：命令里写 `--config configs/prettier.json --ignore-path .gitignore --ignore-path configs/prettierignore`，lint-staged 里的也一样
- prettier 加 `--cache --cache-location .cache/prettier/cache.json`，tsc 的 `tsBuildInfoFile` 放 `.cache/tsc/`
- `public/` 只放必须有固定网址的：favicon、PWA 的 manifest 和图标
- 要打进前端包的环境变量，在 `dir.apps.md` 定的 `<APP>__<名字>` 前面再加框架要求的前缀（Vite 是 `VITE_`，Astro 是 `PUBLIC_`）。打进包的谁都看得到，不放密钥
- 版本号写在 `package.json` 的 `version`。版本跟环境无关，不放环境变量里
- 正式打包不生成 source map，别人拿不到原始代码

## 一个仓库里有几个 web 项目

- 用 pnpm workspaces。web 的东西都放一个目录（比如 `apps/web/`），项目放它的 `projects/<项目>/`，项目之间共用的代码放 `packages/`。`packages/` 等第二个项目真要共用代码时再建，把代码挪进去
- workspaces 的根只放管全部项目的：`package.json`（`private`、`packageManager` 写 pnpm 的精确版本、依赖 husky 和 lint-staged，不写 scripts）、`pnpm-workspace.yaml`、`pnpm-lock.yaml`、`.tool-versions`、`.husky/`、`.gitignore`
- 每个项目照上面「根目录」那节，tsconfig、`configs/`、`.gitignore`、lint-staged 的配置放在项目自己的根目录
- app 仓库的根目录要有 `Makefile`，`setup`、`dev` 写在里面。workspaces 根的 `package.json` 不写 scripts，工作区的 `make setup`、`make start` 只能靠 `Makefile` 转发。husky 由 `setup` 从仓库根目录装，不写 `prepare`
- `pre-commit` 进 workspaces 的根，用 `corepack pnpm -r exec lint-staged` 在每个项目的目录里跑 lint-staged。只找到一个配置时 lint-staged 在启动它的目录里跑任务，从 workspaces 的根直接跑会找不到项目自己的命令和 `configs/`
- pnpm 用 Node 自带的 Corepack 调（`corepack pnpm`）：不全局装、不跑 `corepack enable`；`COREPACK_HOME` 设成 workspaces 根的 `.cache/corepack/`，`COREPACK_ENABLE_DOWNLOAD_PROMPT=0`。在 `.tool-versions` 所在的目录里调，用的才是项目定的 Node 带的 Corepack
- 项目的 `package.json` 的 scripts 里不写 `npm run`、`pnpm run`：用 Corepack 调的 pnpm 不在 scripts 的 PATH 里。要串几个检查时把命令直接连起来

## 检查

- `test` 脚本跑类型检查、lint、格式检查
- 提交前用 husky 跑 lint-staged：暂存的文件做格式化和 lint，类型检查跑整个项目。配置写在 `package.json` 的 `"lint-staged"` 里；lint-staged 会把文件名接在命令后面，tsc 收到文件名会报错，所以写成 `bash -c 'tsc -b'`。`package.json` 不在 git 仓库根目录时，`prepare` 写成从仓库根目录装 husky，钩子放在项目的 `.husky/`。用 pnpm workspaces 时见上面一节
- 一个 git 仓库只能装一套 husky（`core.hooksPath` 只有一个）。同一个仓库里别的项目也要检查时，加进已有的 `pre-commit`，不再装第二套

## 测试

- 单元测试跟被测的文件放一起：`InventoryStore.test.ts`、`<功能>.helpers.test.ts`、`Menu.test.tsx`
- E2E 测试和测试设置放 `tests/`
