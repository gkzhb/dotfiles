# Fish tvn：worktree → tuios session

```fish
tvn                        # 当前仓库
tvn ~/gitrep/project       # 指定仓库，可从仓库外调用
tvn --help
```

依赖 fish、git、tv、Python 3、tuios；使用现有 `git-worktrees` channel 和 `tv-helper.py` 的 hex JSON token / NUL 路径协议，不解析展示文本、不使用 eval。取消 picker 不创建 session、不改变当前 shell CWD；只选择已有 worktree，不修改 Git。

## 对应关系

1. 优先使用 `tuios ls --json` 的 `worktree.path`，规范化真实路径，复用手工命名/改名的 session；不按 basename 或分支猜测。
2. 没有 worktree 元数据时读取 `list-windows --all`，仅按 session **第一个窗口**的本地 CWD 所属 Git 根目录匹配（与 tuios 的仓库分组语义一致）。忽略远端和 popup pane；后续窗口进入另一个项目不改变 session 对应关系。元数据存在时不回退至另一个 pane。
3. 多个 session 对应同一 worktree 时，优先当前 session，否则选择最近活跃的一个。
4. 没有对应 session 时，调用 `tuios new --detach --cwd <worktree>`，**不设置名称**，由 tuios 自动生成 `session-N`。从创建确认输出读取新 identity，不自行命名、不改名，仍按路径复用。
5. tuios 内先确认唯一源客户端，再创建并通过 JSON `call switch-session` 切换，不嵌套 tuios。不绕过权限拒绝；失败不自动重试。外部创建后 attach，保留已有窗口。`local:` 前缀确保带冒号的手工名称不会被当成远端 host。创建成功后若切换/attach 失败，新 session 保留，可用 `ta` 进入；确认输出不可解析时停止并提示检查 `tuios ls`，不猜测目标或重复创建。

当 daemon 停止且磁盘存在保存的 session 时，listing 不提供路径，函数停止并提示先 `ta` / `tuios attach` 恢复，避免为改名 session 创建重复项；没有保存 session 时可以直接创建。超时提示检查状态，不自动重复创建。

## 现有实现对比

- 本机（未纳入共享仓库）的 `~/.config/fish/functions/ttv.fish` 已实现 tmux worktree/session 切换：固定 `~/gitrep/forgev3_fe`，按 `session_path` 复用，内部 switch-client、外部 attach。它仍期待原始路径，而共享 channel 已改为 opaque token，本轮未改旧函数。
- `tv-worktree.fish` 仅安全选择并 cd；`ta` 是 fzf 已有 tuios session picker。
- 未发现 herdr 同类 worktree/session 函数；Television 的 `herdr-remote` 是 SSH 主机选择器，并非 worktree 对应关系。
- tuios 0.12.0 原生 `worktree new` 创建新的 Git worktree，不用于打开当前已存在的 worktree，故这里使用普通 session 创建。

## 测试

```sh
python3 -m unittest discover -s dotfiles/.config/tuios/tests -p "test_worktree_session.py" -v
```

测试使用临时 Git 仓库、命令替身和真实 fish（Television 使用替身），不切换/创建/删除用户现有 session。26 项回归已通过，覆盖自动命名、改名/冒号名称、main/linked worktree、软链接与特殊路径、取消、同名目录及错误/超时保护；未进行真实客户端切换的端到端测试。
