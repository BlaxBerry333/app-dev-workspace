---
name: commit
description: 要写 commit message 时用。规定 commit message 的写法（工作区本身用中文，apps 里的用英文），以及写好后交给用户自己提交
---

# commit

- 先确认是哪个仓库：工作区本身在根目录；app 是各自独立的仓库，用 `git -C apps/<app>`
- 按暂存区的实际改动写（`git diff --cached`），工作区还有没暂存的改动时提醒我。暂存区是空的就提醒我先 add，不替我 `git add`
- 语言按仓库分：
  - 工作区本身：用中文，类型前缀用英文（`chore` / `feat` / `fix` 等）
  - apps 里的仓库：标题和正文全部用英文，不出现中文
- 标题一行，写改了什么、怎么变的，不只写做了哪类活；细节不放标题
  - ○ 工作区：`feat: 增加 make update 命令`、`fix: make start 多个 app 时 Ctrl-C 关不掉`
  - ○ app：`feat: add project list query`、`fix: return an empty list when search has no results`
  - × `fix: 修 bug`、`fix: fix bug`、`fix: 处理评审意见`（只写了做的是哪类活）
- 正文分条写，一条 = 动作 + 块名：新增 / 调整 / 删除 / 修复 + 改的是哪一块。改了几块就列几块，不列文件名、不展开细节；条目里不出现括号和冒号
- 一条不超过 15 个字（英文不超过 8 个词）；同类合并成一条
  - ○ 工作区：`- 新增 Claude Code 的规矩`、`- 调整 commit skill`；app：`- Add the project list query`、`- Update the search API`
  - × `- style.react.md：组件和 props、一个文件一个组件、components 分 base 和 features……`
  - × `- Claude Code 的规矩：CLAUDE.md、rules、commit 和 cleanup skill`（冒号后面在列文件，看 diff 就知道）
  - × `- 新增 Makefile 和脚本（setup / dev / build / test …）`（括号里是细节）
- 标题已经说清楚的不写正文
- 我定了的标题照用，不再要求改
- 只写现在是什么样，不写改的经过
- 不带 Claude 的署名（`Co-Authored-By` 等）
- 写好后贴给我过目，由我自己提交。不运行 `git commit`、`git push`
