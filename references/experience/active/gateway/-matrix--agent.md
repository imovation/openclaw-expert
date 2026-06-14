## 问题描述

需要在 OpenClaw 上接入多个 Matrix 机器人，每个机器人拥有独立的 Agent 身份和独立的工作空间。

## 解决方案

### 1. Matrix 多账号配置

使用 OpenClaw 的 `channels.matrix.accounts` 多账号机制，将单账号配置升级为多账号：

```json5
{
  channels: {
    matrix: {
      enabled: true,
      homeserver: "https://matrix.example.org",
      defaultAccount: "shiningbot", // 指定默认账号
      groupPolicy: "open",
      autoJoin: "off",
      accounts: {
        shiningbot: {
          userId: "@shiningbot:example.org",
          password: "***",
          deviceName: "OpenClaw Gateway",
          encryption: false,
        },
        mianhuatang: {
          userId: "@mianhuatang:example.org",
          password: "***",
          deviceName: "OpenClaw Gateway",
          encryption: false,
        },
        // ...更多账号
      },
    },
  },
}
```

关键点：
- 账号级别的配置（`userId`、`password`、`encryption`）放在 `accounts.<id>` 下
- 共享配置（`homeserver`、`groupPolicy`、`autoJoin`）保持在顶层
- `defaultAccount` 指定 CLI 和路由的默认账号
- 账号名会被规范化用于环境变量（如 `MATRIX_MIANHUATANG_*`）

### 2. 多 Agent 配置

使用 `agents.list` 为每个机器人创建独立 Agent：

```json5
{
  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace", // 默认工作空间
      model: { primary: "provider/model" },
    },
    list: [
      {
        id: "shiningbot",
        default: true,
        workspace: "~/.openclaw/workspaces/shiningbot", // 独立工作空间
        identity: {
          name: "机器猫",
          theme: "角色性格描述",
          emoji: "🤖",
        },
      },
      // ...更多 Agent
    ],
  },
}
```

关键点：
- 每个 Agent 有唯一的 `id`
- `identity` 定义 name/theme/emoji，注入系统提示词
- `workspace` 覆盖 `defaults.workspace` 实现数据隔离
- 第一个 `default: true` 的 Agent 是默认路由目标

### 3. Channel Routing（账号 → Agent 绑定）

使用 `bindings` 将 Matrix 账号路由到对应 Agent：

```json5
{
  bindings: [
    {
      match: { channel: "matrix", accountId: "shiningbot" },
      agentId: "shiningbot",
    },
    {
      match: { channel: "matrix", accountId: "mianhuatang" },
      agentId: "mianhuatang",
    },
  ],
}
```

- `match.channel` 指定渠道类型（如 `matrix`）
- `match.accountId` 匹配 `channels.matrix.accounts` 中的账号 ID
- `agentId` 指向 `agents.list` 中定义的 Agent

## 关键命令

```bash
# 安装 Matrix 插件
openclaw plugins install @openclaw/matrix

# 交互式添加 Matrix 渠道
openclaw channels add

# 验证配置
openclaw config validate

# 重启 Gateway
openclaw gateway restart
```

## 注意点

1. 密码会首次登录后缓存到 `~/.openclaw/credentials/matrix/credentials-<account>.json`
2. 多账号模式下，需通过 `bindings` 显式路由，否则所有消息走默认 Agent
3. `commands.ownerAllowFrom` 中使用 `matrix:@user:server` 格式指定所有者

4. `autoJoin: "off"`（默认值）会导致 bot 不接受任何 Matrix 邀请，包括私聊（DM）邀请。如果需要 bot 自动接受邀请，改为 `"always"` 或 `"allowlist"`（配合 `autoJoinAllowlist`）。详见经验 `exp-1781424164`。
