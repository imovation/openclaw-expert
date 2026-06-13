---
name: openclaw-expert
description: 管理 OpenClaw 的全生命周期运维：安装（npm/nix/docker）、配置（openclaw.json、模型、provider、channels、Gateway）、更新升级、故障诊断修复（Gateway 启停异常、channel 连接失败、模型调用报错、插件崩溃、sandbox 问题、agent 异常等）、卸载清理。当用户提到 openclaw 相关任何问题时都应触发——"openclaw 安装不了""Gateway 启动失败""模型不回复""telegram channel 连不上""openclaw 更新后出问题""插件不工作""sandbox 报错""openclaw 报错/异常/BUG"等。也覆盖 opencode 模型回退问题（常与 openclaw 模型配置相关）。
---

# OpenClaw Expert

管理 OpenClaw 全生命周期运维，知识库支持自进化。

## 启动流程

### 1. 版本检测

读取 `~/.openclaw-expert/version-state.json`，对比当前 `openclaw --version`：

- 文件不存在 → 首次运行，询问用户是否初始化知识库
- 版本一致 → 跳过，进入步骤 2
- 版本不同 → 提示用户检测到版本变化，询问是否更新知识库。用户确认后先执行 `ops/update.md` 子 skill，再处理用户意图

### 2. 意图路由

根据用户的表达，读取对应的子 skill：

| 用户意图 | 子 skill |
|---------|---------|
| 安装/install/setup/部署/openclaw 怎么装 | `ops/install.md` |
| 配置/config/settings/模型/model/provider/channel/密钥/token | `ops/configure.md` |
| 更新/upgrade/update/升级/openclaw 版本 | `ops/update.md` |
| 报错/异常/不工作/失败/BUG/问题/修复/诊断/修/error/crash | `ops/fix.md` |
| 卸载/uninstall/删除/清理/remove | `ops/uninstall.md` |

路由规则：
- 关键词匹配优先级：fix > update > install > configure > uninstall
- 如果用户表达模糊（如"openclaw 出问题了"），默认走 `ops/fix.md`
- 版本变化检测到但用户也想做其他操作 → 先 `ops/update.md` 再处理用户意图

### 3. 经验积累入口

运维操作完成后（特别是 fix 子 skill 完成后），检查是否满足经验积累条件：

- 用户说了"修好了/解决了/可以了/好了/OK/thanks"等确认信号 → 自动触发经验积累
- 用户没有明确确认 → 主动询问"问题是否已解决？需要将此经验记录到知识库吗？"

触发经验积累后，执行以下流程：
1. 总结本次运维操作：问题描述、根因、解决方案、适用版本、关键步骤
2. 确定主题归属 — 匹配 10 个主题目录中最相关的一个
3. 将总结内容写入临时文件，运行 `scripts/knowledge-manager.sh check-dedup --topic <topic> --title "<标题>" --content <临时文件路径>`
   - 输出 `new` → 运行 `add-experience` 新增经验文件
   - 输出 `merge:<existing_file>` → 运行 `merge-experience` 合并优化
   - 输出 `skip` → 与官方文档或已有经验完全重叠，放弃积累
4. 告知用户结果
