---
paths:
  - "{apps/*,dev/playground}/**/*.{ts,tsx}"
---

# TypeScript

## 命名

| 对象 | 写法 | 例子 |
|---|---|---|
| 组件文件夹、组件文件、类文件 | 大驼峰，跟导出同名 | `Menu/`、`JobRunner.ts` |
| 其他文件夹、函数分组文件 | 小写，多个词用 `-` 连 | `core/`、`job-queue/`、`url.ts` |
| 变量、函数 | 小驼峰，函数用动词开头 | `pageSize`、`createClient` |
| 布尔值 | `is` / `has` / `can` 开头 | `isLoading` |
| 类型 | 大驼峰，不加 `I` 前缀 | `MenuProps` |
| 常量 | 收进对象，对象名和键都大写 | `PAGINATION.PAGE_SIZE` |

- 名字可以长，脱离上下文也要看得懂
- 不缩写，通用的除外：`id`、`url`、`env`
- Next.js 按框架的约定：`app/` 下路由文件夹小写，`page.tsx`、`layout.tsx` 这类文件名固定；框架要求的导出（`metadata`、`dynamic`、`revalidate`）按框架写，不套常量规则

## 文件和函数的大小

- 一个文件只做一件事：一个组件、一个类，或者一组相关的函数
- 文件超过 200 行，先停下来看能不能拆；超过 300 行必须拆。import 和类型也算
- 普通函数超过 50 行，拆成几个小函数，名字说明各自做什么
- 只放数据、没有逻辑的文件不限行数，比如常量、文案、路由表
- 不建 `utils.ts`、`common.ts`、`misc.ts` 这种什么都往里放的文件，按用途起名，比如 `url.ts`、`format.ts`。`utils/` 目录可以有，里面分 `helpers/`、`hooks/`
- 加新功能时先想清楚放在哪个文件，不因为现有文件里有相关代码就往里追加
- 项目里用 lint 的 `max-lines` 把 300 行设成报错

## 常量和变量

- 常量不单独定义，收进对象，加 `as const satisfies <类型>`

  ```ts
  export const PAGINATION = {
    PAGE_SIZE: 20,
    MAX_PAGE: 100,
  } as const satisfies PaginationConfig
  ```

- 一起变、一起用的变量收进一个对象
- 函数里算到一半的临时值不收

## import

- 分三组，组之间空一行：`react` / `next` 和 `node:` 内置的、第三方、自己的
- 自己的那组按 `@/`、`./`、样式的顺序排
- 只导入类型的用 `import type`
- 自己的函数分组文件用 `import * as`，别名用文件名转大驼峰：`Menu.helpers.ts` → `MenuHelpers`，`url.ts` → `Url`。会跟内置名字撞上的（`Date`、`Map`）换个文件名
- 第三方库按它自己文档的写法导入，不套上面的规则
- React、组件、类型用解构。带子组件的组件按 `style.react.md`，用 `import * as`
- 跨目录用 `@/`，同一个文件夹里用 `./`，不准用 `../`。别名指向哪里、有没有别的别名，按项目自己的规范

## 不用

- `namespace`、`enum`：改用 `as const` 对象或联合类型
- 把函数打包成对象导出（`export const UrlHelpers = { join }`）：打包时删不掉没用到的函数
