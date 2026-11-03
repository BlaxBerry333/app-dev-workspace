---
paths:
  - "{apps/*,dev/playground}/**/*.{ts,tsx,js,mjs,css,scss,html,astro}"
  - "{apps/*,dev/playground}/**/{package.json,tsconfig*.json,configs/**,.husky/**,.env*}"
---

# web 项目

## 根目录

- tsconfig、`package.json`、`.tool-versions`、`.gitignore` 这类配置留在根目录
- lint、format 的配置放 `configs/`，文件名不加点：`configs/oxlint.json`、`configs/prettier.json`、`configs/prettierignore`
  - oxlint：`package.json` 的命令里写 `-c configs/oxlint.json`
  - prettier：命令里写 `--config configs/prettier.json --ignore-path .gitignore --ignore-path configs/prettierignore`，lint-staged 里的也一样
- prettier 加 `--cache --cache-location .cache/prettier/cache.json`，tsc 的 `tsBuildInfoFile` 放 `.cache/tsc/`
- `public/` 只放必须有固定网址的：favicon、PWA 的 manifest 和图标
- 要打进前端包的环境变量，在 `dir.apps.md` 定的 `<APP>__<名字>` 前面再加框架要求的前缀（Vite 是 `VITE_`，Astro 是 `PUBLIC_`）。打进包的谁都看得到，不放密钥
- 版本号写在 `package.json` 的 `version`。版本跟环境无关，不放环境变量里
- 正式打包不生成 source map，别人拿不到原始代码

## 检查

- `npm test` 跑类型检查、lint、格式检查
- 提交前用 husky 跑 lint-staged：暂存的文件做格式化和 lint，类型检查跑整个项目。配置写在 `package.json` 的 `"lint-staged"` 里；lint-staged 会把文件名接在命令后面，tsc 收到文件名会报错，所以写成 `bash -c 'tsc -b'`。`package.json` 不在 git 仓库根目录时，`prepare` 写成从仓库根目录装 husky，钩子放在项目的 `.husky/`
- 一个 git 仓库只能装一套 husky（`core.hooksPath` 只有一个）。同一个仓库里别的项目也要检查时，加进已有的 `pre-commit`，不再装第二套

## 测试

- 单元测试跟被测的文件放一起：`InventoryStore.test.ts`、`<功能>.helpers.test.ts`、`Menu.test.tsx`
- E2E 测试和测试设置放 `tests/`
