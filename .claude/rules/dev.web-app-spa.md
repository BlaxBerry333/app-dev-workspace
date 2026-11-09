---
paths:
  - "apps/tenebrae/**"
---

# Vite 单页项目

新加文件时先按「怎么判断放哪」找位置。

## 根目录

- `vite.config.ts`、`index.html` 留在根目录
- `vite.config.ts` 只放设置。打包时要算的东西写在 `scripts/` 里，再导入进来；`scripts/` 放开发和打包用的脚本
- 环境变量放 `envs/`，`vite.config.ts` 里设 `envDir`
  - `.env.production`：正式部署用，进 git
  - `.env.local`：app 的 `setup`、`dev` 时没有就从 `.env.example` 复制
  - 不带 `VITE_` 的变量只在 `vite.config.ts` 里用
  - 代码里只在 `src/utils/helpers/env.ts` 读，写成 `ENV` 常量对象，缺了就报错；别的地方用 `ENV.<名字>`，不直接写 `import.meta.env.VITE_…`
- 构建日期、commit 这类打包时才知道的，在 `scripts/build-info.ts` 里生成，`vite.config.ts` 用 `define` 写进代码，只在 `src/utils/helpers/version.ts` 读

## src

| 目录 | 放什么 | 不放什么 |
|---|---|---|
| `main.tsx` | 入口，只负责挂载 | |
| `app/` | 应用本体。`root/` 放根组件、全局 provider、画面状态机或路由；`views/`（有路由时 `pages/`）放画面，把功能组件拼起来 | 功能逻辑（改设置、存档这类）。画面里只放管自己界面的 state，比如确认框开没开 |
| `features/<功能>/` | 一个功能的全部：组件、状态、类型 | 别的功能的东西 |
| `ui/` | `components/` 基础组件、`styles/` 全局样式、`tokens/` 设计系统 | 业务逻辑 |
| `utils/` | 换一个项目也能原样用的逻辑：`helpers/` 函数、`hooks/` hooks、`types/` 生成的类型；大块的按用途分组 | 只有一个地方用的、这个项目专属的东西 |
| `dev/` | `debug/` 开发工具、`mocks/` 假数据 | 正式功能 |

- 用到时才建目录

## 怎么判断放哪

| 问题 | 放哪 |
|---|---|
| 换一个项目也能原样用吗？ | 逻辑放 `utils/`，界面放 `ui/` |
| 只跟一个功能有关吗？ | 那个功能的文件夹 |
| 只有这个项目用、但两个以上功能共用的函数或 hook？ | 放在用它的一个功能里，别的功能通过它的 `index.ts` 用 |
| 是一整个画面吗？ | `app/views/` 或 `app/pages/` |
| 只有开发时用吗？ | `dev/` |

## 依赖方向

- `app/root` → `app/views` → `features` → `ui` / `utils`，只能往右用
- `ui` 只能用 `utils`；`utils` 不用别的目录，里面只有 `hooks/` 碰 React
- `views` 从 props 拿画面的状态和操作，不拿 `app/root` 的对象；一个功能自己的完整界面（比如设置）放在那个功能的 `components/` 里，不放 `views`
- 功能外面的（`app`、`dev`、别的功能）只能通过它的 `index.ts` 用；功能自己内部跨子目录时用 `@/features/<功能>/…`
- 这些由 oxlint 的 `no-restricted-imports` 按目录检查（`configs/oxlint.json`），`../` 的导入也在里面拦；新加功能时加一条 override（不加的话只拦 app、dev、`../`，拦不住绕过别的功能的 index.ts）
- 正式代码用 `dev/` 时只能用 `import.meta.env.DEV` 判断后动态导入，测试不受限。这条 lint 查不了，靠自觉

## features 里

```
features/<功能>/
├── components/                 这个功能的组件
├── <ClassName>.ts              类文件
├── <功能>.types.ts
├── <功能>.constants.ts
├── <功能>.helpers.ts
└── index.ts                    唯一出口
```

- 类文件按 `style.typescript.md` 用类名，其他逻辑文件用 `<功能>.<用途>.ts`；`components/` 里的文件不加 `<功能>.` 前缀
- 文案这类只放数据的文件按语言拆开（`i18n.messages.zh.ts`）
- 功能的组件要懒加载时，在功能的 `index.ts` 里包好再导出，外面照常 `import { Settings } from '@/features/settings'`，用的地方包一层 `Suspense`：

  ```ts
  export const Settings = lazy(() =>
    import('@/features/settings/components/Settings').then((m) => ({
      default: m.Settings,
    })),
  )
  ```

## 别名

- `@/` 指向这个项目的 `src/`
- 定义在 tsconfig 的 `paths`，Vite 用 `resolve.tsconfigPaths` 读，不在 `vite.config` 里另写 alias

## 测试

- 假数据从 `src/dev/mocks/` 取
