<IMPORTANT>
回答时必须使用简体中文语言回答用户！
</IMPORTANT>

shell 工具报错命令找不到时，优先尝试添加前缀 `/opt/homebrew/bin/` 重新调用命令。

## skills 使用说明

OpenCode 的全局 skill 根目录位于 `$HOME/.config/opencode/skill/`。创建全局 skill 时请放在此目录下。
如果用户指定项目维度 skill 请放在 `<cwd>/.opencode/skill/` 目录下。

当你需要调用 skill 脚本时，可以选择使用绝对路径调用，比如
```bash
python $HOME/.config/opencode/skill/xxx-skill/scripts/run-it.py
```
或者先 cd 到 skill目录再执行：
```fish-shell
cd $HOME/.config/opencode/skill/xxx-skill; python scripts/run-it.py
```


