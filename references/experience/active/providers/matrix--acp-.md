# Matrix 群聊 ACP 命令授权问题

## 问题
在 Matrix 群聊（rooms）中，slash 命令（`/acp spawn`、`/status` 等）不生效，消息被当作普通文本发给 agent（导致 agent 调用模型失败或无法触发 ACP 会话）。私聊中命令正常工作。

## 根因
Matrix 插件在 `monitor-BWHn9jy2.js:759` 中，群聊的命令授权列表被硬编码为空数组：

```javascript
const commandAllowFrom = state.isRoom ? [] : state.messageIngress.senderAccess.effectiveAllowFrom;
```

- **私聊**：`commandAllowFrom` 使用 DM 授权列表，用户可通过授权
- **群聊**：`commandAllowFrom = []`，没有任何用户被授权发送命令
- `groupOwnerAllowFrom: "none"` 进一步阻止了群组级授权

结果：命令被识别但 `commandAuthorized = false`，核心网关不执行命令，消息降级为普通 agent 消息。

## 解决方案
在 room 配置中显式添加 `users` 字段，将用户的 Matrix ID 加入群聊命令授权列表：

```json5
"groups": {
  "!roomId:matrix.example.org": {
    "autoReply": true,           // 可选：允许免 @提及
    "users": ["@user:matrix.example.org"]  // 关键：填充 commandGroupAllowFrom
  }
}
```

`users` 列表会填充 `commandGroupAllowFrom`，使命令授权通过。

## 修复位置
- 配置文件：`openclaw.json` → `channels.matrix.groups.<roomId>.users`
- 代码位置（根因）：`monitor-BWHn9jy2.js:759`

## 相关配置
- `commands.ownerAllowFrom` — 仅控制 owner 级命令，不影响常规命令的群聊授权
- `groups.<room>.autoReply` — 允许免 @提及响应，但不解决命令授权问题

## 诊断方法
检查 Gateway 日志中是否有 `embedded run agent end` 且错误为 `rate_limit` 等模型错误，说明命令未被识别，进入了 agent 路径而非命令路径。
