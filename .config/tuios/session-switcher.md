# fzf session 切换器

脚本：`~/.config/tuios/session-switcher.py`。依赖 Python 3、tuios、fzf、git。

当前按 **Ctrl+F s** 打开（`prefix+s` 的 popup 绑定）。Enter 切换，Esc / Ctrl+C 取消，Ctrl+/ 切换预览。脚本不创建或 attach session，不修改 Git。

## 列表字段

```text
SESSION  GIT REPOSITORY  PROJECT BRANCH / REF  PANE DIR  PANE BRANCH / COMMIT  PANES  STATUS
```

- **GIT REPOSITORY / PROJECT BRANCH / REF**：优先直接使用 `tuios ls --json` 的 `worktree.repo` / `worktree.branch`，与内置仓库分组树使用同一份 daemon 元数据。包括主 checkout、linked worktree 和 tuios 管理的 worktree；不会被焦点 pane 的另一个目录或分支覆盖，也不在脚本内重新推断“第一个窗口”。
- **PANE DIR / PANE BRANCH / COMMIT**：独立显示所选 pane 的 CWD 最后一段，以及在该 CWD 实时查询的 Git 分支或 detached commit。源 session 优先使用呼出弹窗前的 pane，其他 session 优先使用焦点 pane，再回退到有 CWD 的 pane。已确定的焦点 pane 缺少 CWD 时显示 `—`，不冒用另一个 pane。
- 没有 `worktree` 元数据时，项目前两列回退为所选 pane 的 Git 根目录名和实时 ref，以兼容旧 daemon 或未分组 session。路径不可读且有普通 daemon branch 时，仅项目 ref 标记为 `(cached)`；不把缓存冒充 pane 实时分支。已确认不是 Git 仓库时不使用旧 branch。
- 没有 pane / CWD 时，pane 列显示 `—`；worktree 路径不会被当作 pane CWD。已存在的分组元数据字段缺失时显示 `—`，不与其他仓库的实时信息拼接。

所有列均可通过 fzf 搜索。预览区分别展示项目来源、仓库根目录、worktree 路径及目录已删除标记，以及所选 pane 完整目录、Git 根目录、ref、commit 和其他 panes。

分组元数据可能暂时落后于实际 Git 状态，因此项目分支与 pane 分支不同并不一定是错误：前者用来与侧边栏对齐，后者展示实时工作上下文。脚本不读取或模仿侧边栏的分组开关、折叠顺序、显示名称和宽度布局；它保留按最近活跃时间排序和精确 session 名切换。

## 只读查看与验证

```sh
python3 ~/.config/tuios/session-switcher.py --list
python3 -m unittest discover -s ~/.config/tuios/tests -p 'test_session_switcher.py' -v
```

`--list` 只读取 session/pane 元数据和 Git，不打开弹窗、不切换客户端。测试使用替身及一次性临时 Git 仓库，不操作现有 session。
