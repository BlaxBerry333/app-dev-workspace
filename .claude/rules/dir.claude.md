---
paths:
  - ".claude/**"
---

# .claude

- 针对某类文件的规范放 `rules/`，用 `paths:` 按需加载
- 文件名用 `style.<内容>.md`（某种语言、文件怎么写）、`dir.<目录>.md`（某个目录的规矩）或 `dev.<领域>.md`（某类项目怎么开发）
- 按类别写的 rule（比如游戏）认不出哪个 app 属于这类，`paths` 里把这类的 app 和 `dev/playground/` 里的试验一个个列出来
- 针对某种操作的规矩（比如提交）放 `skills/`
- `CLAUDE.md` 每次会话都加载，只放动手之前就得知道的。只在特定场合才用到的写进按需加载的 rule
