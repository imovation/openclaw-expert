---
name: openclaw-expert-fix
description: 诊断和修复 OpenClaw 问题 — Gateway 异常、channel 失败、模型报错、插件崩溃、sandbox 错误、agent 异常等。含源码级修复。在 openclaw-expert skill 的修复上下文中使用。
---

# OpenClaw 故障修复

## 诊断流程

### 1. 接收错误描述并分类

根据错误信息关键词确定问题主题：

| 关键词 | 主题 | 查阅路径 |
|--------|------|---------|
| gateway/daemon/端口/启动/守护进程/EADDRINUSE | gateway | `references/official-docs/gateway/` + `references/experience/active/gateway/` |
| channel/telegram/whatsapp/discord/slack/signal/matrix/连接/消息 | providers | `references/official-docs/providers/` + `references/experience/active/providers/` |
| model/provider/anthropic/openai/api/key/认证/模型 | providers | `references/official-docs/providers/` + `references/experience/active/providers/` |
| plugin/插件 | plugins | `references/official-docs/plugins/` + `references/experience/active/plugins/` |
| sandbox/沙箱/container | tools | `references/official-docs/tools/` + `references/experience/active/tools/` |
| agent/agent loop/session/memory | concepts | `references/official-docs/concepts/` + `references/experience/active/concepts/` |
| install/安装/npm | install | `references/official-docs/install/` + `references/experience/active/install/` |
| config/配置 | gateway | `references/official-docs/gateway/` + `references/experience/active/gateway/` |
| node/移动端/ios/android | nodes | `references/official-docs/nodes/` + `references/experience/active/nodes/` |

### 2. 查阅知识库

**优先级：** experience/active > official-docs > experience/archived（仅供参考）

- 先读取对应主题的 `references/experience/active/{topic}/` 下所有经验文件
- 如果没有匹配，读取 `references/official-docs/{topic}/` 下的相关文档
- `references/experience/archived/{topic}/` 仅作为背景参考

### 3. 本地诊断

使用 openclaw 内置诊断工具：

```bash
openclaw doctor             # 全面诊断
openclaw doctor --fix       # 自动修复常见问题
openclaw logs              # 查看 Gateway 日志
openclaw health            # Gateway 健康检查
openclaw gateway status    # Gateway 运行状态
openclaw models status     # 模型/provider 状态
openclaw channels status   # Channel 连接状态
```

### 4. 源码级修复

当问题无法通过配置或知识库解决时，尝试源码修复：

1. 定位 openclaw 安装路径：
```bash
npm root -g
# 通常在 /home/<user>/.nvm/versions/node/vXX/lib/node_modules/openclaw
```

2. 用 Read 工具查看相关源文件，定位问题代码

3. 用 Edit 工具修复代码

4. 修复后验证：
```bash
openclaw doctor
openclaw gateway restart
```

5. 修复完成后，触发经验积累流程（参考主 SKILL.md 第 3 节）

## 常见故障速查

以下问题直接查阅对应经验文件：
- Gateway 启动失败 → `references/experience/active/gateway/` + `references/experience/active/install/`
- 模型不回复/回复异常 → `references/experience/active/providers/`
- Channel 连接失败 → `references/experience/active/providers/`
- openclaw 命令找不到 → `references/experience/active/install/`
- opencode 模型回退到 big-pickle → 这通常是 openclaw 模型配置问题，查阅 `references/experience/active/providers/`
