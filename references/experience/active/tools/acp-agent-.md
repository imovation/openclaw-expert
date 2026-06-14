# ACP Agent 配置

## 步骤
1. `openclaw plugins install @openclaw/acpx`
2. 在 `openclaw.json` 添加 `acp` 段：`backend: "acpx"`、`allowedAgents`（只放 harness ID）、`defaultAgent`、`stream`、`runtime`
3. 配置 `plugins.entries.acpx.config` 权限模式

## 关键原则
- `acp.allowedAgents` 只放 harness ID（opencode、codex、claude），不放 OpenClaw agent ID
- `/acp spawn <harness_id> --bind here` 显式绑会话到 ACP
- `runtime.type: "acp"` 只用于 `sessions_spawn` API，不自动路由 Channel 消息
- ACP binding（`type: "acp"`）需指定 `match.peer.id`，不支持全账号路由
- Matrix `autoJoin: "off"` 时 bot 被邀请不 join 房间，收不到消息需手动 join

## 常见坑
- `doctor --fix` 把 `homeserver`/`groupPolicy` 从顶层移入 `accounts.default` 会导致所有 bot 登录失败——源码 BUG，见 `exp-1781414379`

## 核心配置
| 键 | 说明 |
|---|---|
| `acp.backend` | 固定 `"acpx"` |
| `acp.allowedAgents` | harness ID 白名单 |
| `plugins.entries.acpx.config.permissionMode` | `approve-all` / `approve-reads` / `deny-all` |
| `agents.list[].runtime.type` | `"acp"`（仅 sessions_spawn 用） |
| `agents.list[].runtime.acp.agent` | 映射到哪个 harness ID |
