# Television session 切换器

脚本：`~/.config/tuios/session-switcher.py`。依赖 Python 3、tuios、tv（Television）、bash、git。

使用独立 `television/tuios-session-switcher.toml` 和 `cable/tuios-sessions.toml`，不继承共享查询历史和 shell integration；Tab / Shift+Tab 显式禁用多选，只操作当前高亮 session。两个配置目录已整目录映射，无需新增 Home Manager 映射。

当前按 **Ctrl+F s** 打开（`prefix+s` 的 popup 绑定）。Enter 切换，Esc / Ctrl+C 取消，Ctrl+/ 切换预览，**Ctrl+R 删除所选 session（需确认）**。脚本不创建或 attach session，不修改 Git。

## 自动进入 terminal mode

Ctrl+F s 的 popup 绑定显式传入 `--inline --terminal-mode`。脚本在 popup 中启动后，先对源 session 执行 `TerminalMode`，再打开 Television，因此从 window mode 呼出后可直接输入搜索，无需再手动按 i。不修改全局 `auto_enter_terminal_on_focus` 设置。

直接运行脚本创建的 popup 同样会传入该选项；普通 `--inline` 不改变模式，`--list` 始终只读。模式命令需要现有权限；拒绝时直接报错，不调整授权。当前 tuios 按 session 路由模式命令，为避免改到其他客户端，只允许恰好一个客户端显示源 session；多个客户端时停止并报错。关闭 popup 后不强制恢复 window mode。

## 删除 session

Ctrl+R 打开二次确认，明确说明会终止 session 的全部窗口／进程并断开客户端。默认选中 **Cancel**；按 Down 选择 Kill，再按 Enter 才执行。直接 Enter、Esc / Ctrl+C 均不删除。确认取消或删除成功后重新读取列表；失败／超时退出并报错，不自动重试。

- 禁止在弹窗内删除弹窗所属的当前 session；请从另一个 session 打开选择器。
- 删除前及确认后均校验 daemon UUID 和原始名称，拒绝已消失、重命名或同名重建的目标。没有 UUID 的旧 daemon 不支持该删除入口。
- 删除使用 `tuios call kill-session` 的 JSON 参数，名称不进入 shell 命令或 host/session 解析，不执行 eval。
- daemon 删除 API 仍以名称寻址，校验与执行间的极短竞争窗口无法完全消除；如删除返回未知结果，请先检查状态，不盲目重试。

## 颜色

Television 使用 `--ansi`，channel 不设置 `source.display`（tv 0.15.x 的显示模板会覆盖 ANSI 解析）：session 名加粗、仓库青色、项目分支紫色、pane 目录蓝色、pane 分支黄色、当前／attached 状态绿色，缺失值与 detached 状态弱化。字段先清洗控制字符，再添加脚本自己的 ANSI；颜色不参与列宽计算，中文宽字符和组合符有专门处理。

`--list` 始终输出纯文本。在环境中设置 `NO_COLOR=1`，或使用 `TERM=dumb`，可关闭列表的 ANSI 字段配色（Television UI 主题仍保留）。

## 列表字段

```text
SESSION  GIT REPOSITORY  PROJECT BRANCH / REF  PANE DIR  PANE BRANCH / COMMIT  PANES  STATUS
```

- **GIT REPOSITORY / PROJECT BRANCH / REF**：优先直接使用 `tuios ls --json` 的 `worktree.repo` / `worktree.branch`，与内置仓库分组树使用同一份 daemon 元数据。包括主 checkout、linked worktree 和 tuios 管理的 worktree；不会被焦点 pane 的另一个目录或分支覆盖，也不在脚本内重新推断“第一个窗口”。
- **PANE DIR / PANE BRANCH / COMMIT**：独立显示所选 pane 的 CWD 最后一段，以及在该 CWD 实时查询的 Git 分支或 detached commit。源 session 优先使用呼出弹窗前的 pane，其他 session 优先使用焦点 pane，再回退到有 CWD 的 pane。已确定的焦点 pane 缺少 CWD 时显示 `—`，不冒用另一个 pane。
- 没有 `worktree` 元数据时，项目前两列回退为所选 pane 的 Git 根目录名和实时 ref，以兼容旧 daemon 或未分组 session。路径不可读且有普通 daemon branch 时，仅项目 ref 标记为 `(cached)`；不把缓存冒充 pane 实时分支。已确认不是 Git 仓库时不使用旧 branch。
- 没有 pane / CWD 时，pane 列显示 `—`；worktree 路径不会被当作 pane CWD。已存在的分组元数据字段缺失时显示 `—`，不与其他仓库的实时信息拼接。

所有列均可通过 Television 搜索。预览区分别展示项目来源、仓库根目录、worktree 路径及目录已删除标记，以及所选 pane 完整目录、Git 根目录、ref、commit 和其他 panes。

分组元数据可能暂时落后于实际 Git 状态，因此项目分支与 pane 分支不同并不一定是错误：前者用来与侧边栏对齐，后者展示实时工作上下文。脚本不读取或模仿侧边栏的分组开关、折叠顺序、显示名称和宽度布局；它保留按最近活跃时间排序和精确 session 名切换。候选左侧保留小型 snapshot ID（s0、s1…）列，只有 token 进入 shell 模板和输出；展示名称不作为命令参数解析。Enter 直接输出 token，Ctrl+R 额外输出按键行；未知 token、按键或多选输出一律拒绝。

## 只读查看与验证

```sh
python3 ~/.config/tuios/session-switcher.py --list
python3 -m unittest discover -s ~/.config/tuios/tests -p 'test_session_switcher*.py' -v
```

`--list` 只读取 session/pane 元数据和 Git，不打开弹窗、不切换客户端。测试使用替身及一次性临时 Git 仓库；PTY 测试只启动真实 Television 验证 Enter / Ctrl+R 和确认默认取消，不调用 tuios 或操作现有 session。
