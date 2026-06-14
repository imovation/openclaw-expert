---
name: openclaw-expert-configure
description: 配置 OpenClaw — openclaw.json、模型 provider、channels、Gateway、安全、memory、plugins。在 openclaw-expert skill 的配置上下文中使用。
---

# OpenClaw 配置

## 配置文件位置

主配置：`~/.openclaw/openclaw.json`

先检查是否已有配置文件：
```bash
cat ~/.openclaw/openclaw.json 2>/dev/null || echo "未找到配置文件"
```

如果文件不存在，运行引导式配置：
```bash
openclaw configure
```

## 配置域

### 模型和 Provider

查阅 `references/official-docs/providers/` 下的官方文档。关键步骤：
```bash
openclaw models status    # 检查当前模型状态
openclaw models list      # 列出可用模型
```

配置 `~/.openclaw/openclaw.json` 中的 `models` 部分。常见问题查阅 `references/experience/active/providers/`。

### Channels 接入

查阅 `references/official-docs/providers/` 下的 channel 文档。添加 channel：
```bash
openclaw channels add
```

支持的 channel：Telegram、WhatsApp、Discord、Slack、Signal、iMessage、Matrix、Microsoft Teams。配置 `~/.openclaw/openclaw.json` 中的 `channels` 部分。

#### Matrix 群聊多 bot 配置
如果配置 Matrix 群聊中的多个 bot 账号（如 `autoReply: true`），请注意 `references/experience/active/providers/matrix--bot-.md` 中记录的源码改造依赖。该改造实现了"无 @提及全回复、@提及仅目标"的分流逻辑。OpenClaw 升级后需重新应用补丁，否则 `autoReply: true` 会恢复为"所有消息触发所有 bot"的原始行为。

### Gateway 配置

查阅 `references/official-docs/gateway/`。关键配置项：端口、绑定地址、远程访问。运行：
```bash
openclaw gateway status    # 检查 Gateway 状态
```

### 安全配置

查阅 `references/official-docs/gateway/` 中的安全文档。关键配置：allowFrom、tokens、gateway-lock。

### Memory 和 Plugins

查阅 `references/official-docs/workspace/` 和 `references/official-docs/plugins/`。

## 配置校验

每次修改配置后运行：
```bash
openclaw config validate
openclaw doctor
```

如有报错，转到 `ops/fix.md` 处理。
