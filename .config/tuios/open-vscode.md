# 在 session 项目目录打开 VS Code

**Ctrl+F → Shift+E**（大写 `E`）调用 `open-vscode.py`，在当前 tuios session 的项目根目录打开 VS Code。小写 `e` 的侧边栏快捷键保持不变，不创建 tuios 窗口、不切换 session。替换默认 prefix+E 的 scrollback 编辑功能，后者仍可从命令面板调用。

目录优先使用 `tuios ls --json` 的 `worktree.path`：linked worktree 打开当前分支 checkout，不是主仓库的 `repo_root`。没有 worktree 元数据时，按 session 的首个窗口识别项目，使用该本地 pane 的 Git 根目录；非 Git 目录直接打开其目录。不会因焦点切到另一个项目的 pane 而换目录，也不使用启动脚本的 PWD。

目录缺失、远程/不可信 pane、session 已停止或读取失败时不打开 VS Code，不猜测其他目录。路径通过 argv 传递，兼容空格、引号。依赖 `python3`、`tuios`、`git` 和 PATH 中的 `code`（VS Code 的命令面板可安装 shell command）。

只读检查，不打开编辑器：

```fish
python3 ~/.config/tuios/open-vscode.py --print-root
# 外部终端须显式指定 session：
python3 ~/.config/tuios/open-vscode.py --session session-1 --print-root
```

配置随现有 tuios 整目录链接实时生效，无需重新构建系统或重启 daemon。

隔离回归，不操作真实 session 或打开 VS Code：

```fish
python3 -B -m unittest discover -s ~/.config/tuios/tests -p 'test_open_vscode.py' -v
```
