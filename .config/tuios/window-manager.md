# Television 窗口管理器

脚本：`~/.config/tuios/window-manager.py`。依赖 `python3`（标准库即可）、`tuios`、`tv`、`bash`。针对 tuios 0.10.1、Television 0.15.9。

## 呼出

配置中的快捷键：**Ctrl+F o**（Leader → 小写 o）。不占用 `w` 新建窗口、`s` 会话切换。替换默认的 Leader → o「跳到最早待处理项」；该功能仍可从命令面板运行。

也可在要整理的 tuios session 中执行：

```fish
python3 ~/.config/tuios/window-manager.py
```

从外部终端显式指定来源：

```fish
python3 ~/.config/tuios/window-manager.py --session session-1
```

必须有客户端显示该 session。如果多个客户端显示同一 session，先 `tuios list-clients --json`，再用 `--client ID` 明确指定；不猜测应该跟随哪一个客户端。不要从后台常驻 Pi 的 pane 直接启动来代替用户当前 session。

## 操作

窗口列表只展示打开时所在 workspace 的普通本地窗口，包含最小化窗口。名称、命令、目录可搜索；右侧只读预览最近 60 行终端输出，不向程序输入任何按键。

| 按键 | 功能 |
|---|---|
| ↑ / ↓ | 选择窗口 |
| Tab / Shift+Tab | 多选 / 反向勾选 |
| Enter / Ctrl+x | 打开 Television 原生 actions 菜单：move、move_follow、focus |
| Alt+m | 执行 move：直接选择移动目的地 |
| Alt+g | 执行 move_follow：选择目的地，移动成功后跟随 |
| Alt+f | 执行 focus：聚焦选中的一个窗口 |
| Ctrl+r | 刷新已列窗口的状态，移除已关闭或移走的窗口 |
| PageUp / PageDown | 滚动预览 |
| Esc / Ctrl+c | 退出窗口列表，或从操作/目的地页返回 |

原生菜单可输入 `move`、`move_follow`、`focus` 搜索，↑/↓ 选择，Enter 执行动作；Esc、Ctrl+c 或再次 Ctrl+x 仅返回窗口列表，不执行动作。窗口多选会保留到菜单确认；focus 始终可见，但多选时提示仅支持单选，不聚焦任何窗口。

目的地将 **session / workspace** 放在同一列表。当前 session 的其他 workspaces 优先，其他 session 随后，空 workspace 也可选。输入 `review 2` 可筛选 review 的 workspace 2。只选择一个目的地；Enter 确认后才移动，Esc 返回不移动。

正常移动后返回源列表，可继续整理。动作确认使用 `execute` 结束当前 tv，Python 再打开目的地选择器；移动完成或目的地取消后重新打开窗口列表，搜索和多选重置。移动并跟随时，先批量移动，再关闭弹窗、聚焦本批第一个窗口，跨 session 时显式切换原客户端。普通移动没有偷偷切换 session；源 workspace 移空时，tuios 自己的 `return_when_empty` 设置仍然有效。源列表变空会显示提示，按 Enter 关闭。

错误和部分成功显示完整明细，按 Enter 返回；按 Esc 再 Enter 退出。批量移动不是事务：成功的窗口保留在目的地，不自动回滚；部分失败不跟随。

## 配置

`~/.config/tuios/config.toml`：

```toml
# Add this key to the EXISTING prefix_mode table (do not duplicate the table).
[keybindings.prefix_mode]
prefix_next_attention = []

[[keybindings.command]]
key = "prefix+o"
type = "shell"
command = "python3 ~/.config/tuios/window-manager.py"
name = "window-manager"
description = "Manage workspace windows (Television)"
```

这里 **必须使用 `type = "shell"`**，不是 popup。脚本负责创建 92% × 85% 的弹窗；外层在弹窗创建前捕获 session/workspace、原焦点、窗口 UUID 和唯一客户端，并在弹窗结束后聚焦/跟随。这样弹窗不会把自己当成源窗口，关闭弹窗也不会把目标焦点覆盖回去。

配置文件由运行中的客户端监视，不需要重启 daemon。macOS 默认 CLI 路径与客户端可能不同：当前客户端有 `XDG_CONFIG_HOME=$HOME/.config`，因此读取本目录，而不是 `~/Library/Application Support/tuios/config.toml`。

Television 配置统一放在 `~/.config/television/`：专用配置为 `tuios-window-manager.toml`，频道为 `cable/tuios-windows.toml` 和 `cable/tuios-destinations.toml`。脚本显式读取这些路径，不再从 tuios 目录加载 tv 配置；既有 `~/.config/television/config.toml`、shell integration、其他频道和搜索历史保持不变。文件源在 `~/nix-config/dotfiles/.config/television/`，Home Manager 将 Television 目录整体链接到共享配置。导航推荐方向键，避免 tuios 的 Ctrl+h/j/k/l 全局窗口导航抢按键。

### Cable actions 与执行流程

窗口 channel 定义 `[actions.move]`、`[actions.move_follow]` 和 `[actions.focus]`，模式均为 `execute`。窗口 channel 的 Enter 打开原生菜单；独立全局配置的 Enter 仍为 `confirm_selection`，用于确认菜单动作和目的地。

Action 模板逐行从原始 TSV 条目提取安全 token（不是依赖 `source.output`），只调用 `window-manager.py --request ACTION TOKENS...`，不直接执行 tuios 命令。入口验证本次随机 picker ID、窗口类型和 token，原子写入 `request.json`。外层 Python 在 tv 退出后消费并删除请求，按源列表顺序恢复选择，继续原有目的地选择及逐项位置校验。普通移动后刷新；聚焦／跟随仍写入独立的 `intent.json`，由 launcher 在整个 popup 关闭后执行。旧请求、未知动作／token 和异常 tv 退出不会触发操作。

## 安全与限制

- 内部保存完整 window/session UUID，不用会变化的 index；显示列与真实标识分离。tuios 0.10.1 的 `-s` 只接受 session 名，所以调用前按保存的 UUID 重新查找当前名称；UUID 消失则拒绝，不使用同名替代 session。
- 标题、目录和输出过滤控制字符，不能变成 shell 命令；预览只传程序生成的短 token。
- 临时状态目录权限为 0700，退出后清理。不使用 eval，不自动输入到窗口。
- 每次移动前重新检查窗口仍在原 session/workspace。关闭、移走或不可移动时显示错误，不另找同名窗口。
- 聚焦/跟随前检查原客户端仍显示源 session；不抢已切走客户端的焦点。
- 当前版本 tuios 的 list-windows 不提供 popup 标志，因此固定使用**弹窗创建前的窗口 ID 快照**。管理器运行时新创建的窗口不会自动加入，需退出重开；已关闭/移走的窗口可以 Ctrl+r 刷新移除。
- scratch 和远程托管窗口不列入操作目标。标准快捷键在普通 workspace 中使用，不在其他 popup 中嵌套呼出；若快照中已有其他 popup，daemon 会拒绝其移动，错误可见。
- 只列当前 daemon 的既有 session/workspace；不自动创建 session，不操作其他机器，不修改权限。
- 标题只保留 session/workspace 和 Enter 操作提示，避免窄屏截断。其他快捷键见上表；无需记忆时使用 Enter 或 Ctrl+x 原生菜单。
- 没有关闭窗口、重命名、自动回滚。
- 源列表打开期间源上下文固定。其他客户端同时修改位置、重命名/删除 session 仍可能与实际操作竞争；校验降低风险，但 tuios 不提供位置条件原子移动、按 session UUID 查询等接口，不能消除 CLI 校验与执行之间的极短竞争窗口。

## 测试

```fish
python3 -m unittest discover -s ~/.config/tuios/tests -p 'test_window_manager*.py' -v
```

单元测试覆盖控制字符、目标排序、过期选择、部分失败、固定客户端、request 单次消费／过期拒绝、多选聚焦拒绝和延后跟随。PTY 测试使用真实 Television 验证 Enter / Ctrl+x 原生菜单、菜单返回、Alt+m/g/f、Tab 多选、Ctrl+r、取消以及目的地选择。集成测试创建独立 named daemon 和一次性 sleep panes/测试客户端，验证同 session/跨 session 批量移动保留 ID、PID，原生 Ctrl+x 批量移动并跟随、真实弹窗不包含自身，以及 launcher 在弹窗关闭后聚焦原客户端。测试不会输入或移动用户现有窗口。
