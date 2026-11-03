# 目录

```
app-dev-workspace/
├── .claude/
│   ├── CLAUDE.md
│   ├── launch.json             Claude 启动开发服务器用的配置，不进 git
│   ├── rules/                  按需加载的规范：style.<内容>.md、dir.<目录>.md、dev.<领域>.md
│   └── skills/                 commit、check
├── .vscode/                    各 app 通用的设置和推荐插件
├── apps/
│   ├── apps.list               app 清单：一行一个「app 名 可见性 git 地址」，不进 git
│   ├── apps.list.example       清单的样例
│   ├── ports.list              端口表：一行一个「app 名 变量名 端口」，不进 git
│   ├── ports.list.example      端口表的样例
│   └── <app>/                  各 app，各自是独立的 git 仓库
├── dev/                        不属于任何一个 app 的东西
│   ├── docs/                   工作区的开发文档
│   ├── notes/                  给自己看的笔记，不进 git；TODO.md 是工作区的计划，<app>/TODO.md 是各 app 的进度和计划
│   ├── playground/             技术试验，不进 git
│   └── scripts/                Makefile 调用的脚本
├── .gitattributes
├── .gitignore
├── Makefile
└── README.md
```
