---
paths:
  - "{apps/*,dev/playground}/**/*.tsx"
  - "{apps/*,dev/playground}/**/{components,views,pages}/**"
---

# React

## 组件

- `function` 声明、具名导出：`export function Menu(props: MenuProps) {}`
- 不用 `export default`、`forwardRef`。Next.js 的 `page.tsx`、`layout.tsx` 这类框架要求 default 的除外
- 有子组件的，`index.ts` 里改名导出：`export { Menu as Root } from './Menu'`、`export { MenuItem as Item } from './MenuItem'`。外面 `import * as Menu from '@/…/Menu'`，写 `<Menu.Root>`、`<Menu.Item>`
- 不往组件上挂属性（`Menu.Item = MenuItem`）：server component 不能点进 `'use client'` 的模块
- 一个 `.tsx` 只放一个组件，要写小组件时建子组件文件夹
- 组件超过 100 行（包括 JSX）就拆子组件

## props

- 用 `type`，名字叫 `组件名Props`
- 在参数里解构，默认值写在解构里
- 对象、数组的默认值提到组件外面写成常量，不写 `items = []`
- 回调 prop：`on` + 对象 + 动作，比如 `onItemSelect`，不写 `onSelect`
- 处理函数：`handle` + 对象 + 动作，比如 `handleItemSelect`
- 基础组件里包装原生元素的，保留原生的 `onClick`、`onChange`

## 目录

组件分三层，目录名按 app 的 README：

| 层 | 放什么 |
|---|---|
| 基础组件 | 不含业务逻辑 |
| 功能组件 | 一个功能自己的，可以用基础组件 |
| 画面 | 只拿数据、拼功能组件，不写逻辑。Next.js 里就是 `app/` 下的 `page.tsx` |

每个组件一个文件夹：

```
Menu/
├── index.ts                    唯一出口
├── Menu.tsx
├── Menu.types.ts
├── Menu.constants.ts
├── Menu.hooks.ts
├── Menu.helpers.ts             纯函数，不碰 React
├── Menu.module.scss
└── MenuItem/                   子组件，结构同上
```

- 配套文件需要时才建
- `组件名.tsx` 只导出组件，hooks 放 `.hooks.ts`
- 子组件的文件夹放在父组件文件夹里，外面只能通过父组件用
- 外面只能导入到组件文件夹这一层，不能往里导入
- 父组件和子组件之间互相导入用 `@/` 完整路径，不算往里导入；同一个文件夹里照常用 `./`
- 不建汇总整个 `components/` 的 `index.ts`

## state

- 只有这个组件用：组件里的 state
- 互不相关的 state 分开 `useState`，一起变的用一个对象或 `useReducer`
- 很少变、很多地方用的（设置、语言、主题）：context
- 变得很频繁的数据不进 React，放外部 store，用 `useSyncExternalStore` 只订阅需要的部分

## useEffect

- 只用来跟 React 外面的东西同步：DOM 事件、第三方库的实例、SSE 这类长连接
- 必须写清理函数
- 不用来算派生值，能算出来的在渲染时直接算
- 不放事件逻辑，用户操作引起的事写在 `handleXxx` 里

## 懒加载

- 在画面或功能这一层做，用框架自己的办法：React 的 `lazy`，Next.js 的 `next/dynamic`
