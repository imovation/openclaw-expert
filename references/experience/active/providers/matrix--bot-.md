# Matrix 群聊多 bot 响应逻辑改造

## 需求
群聊中有多个 Matrix bot 账号时，实现以下行为：
- 无 @提及 → 所有 bot 都回复
- @提及特定 bot → 仅被提及的 bot 回复
- @提及其他人 → 无人回复（不打扰）

## 方案
修改 Matrix 插件源码 `monitor-BWHn9jy2.js`：

### 修改 1：`resolveMentions()` 新增 `hasAnyUserMention`
在 `m.mentions.user_ids` 中提取是否有人被 @提及，返回新字段。

### 修改 2：destructuring 提取新字段
```javascript
const { wasMentioned, hasExplicitMention, hasAnyUserMention } = resolveMentions({...});
```

### 修改 3：新增跳过逻辑
当 `autoReply: true`（`shouldRequireMention = false`）时，如消息中包含对其他用户的 @提及、但不包含当前 bot，则跳过：

```javascript
if (isRoom && !shouldRequireMention && hasAnyUserMention && !wasMentioned && !hasExplicitMention) {
    logger.info("skipping room message", { roomId, reason: "other-mention" });
    await commitInboundEventIfClaimed();
    return;
}
```

## 代码位置
`monitor-BWHn9jy2.js`（Matrix 插件 dist 目录）

## 配置依赖关系
此改造影响 `openclaw.json` 中 `channels.matrix.groups.<room>` 的行为：

| 配置项 | 未改造时的行为 | 改造后的行为 |
|--------|---------------|-------------|
| `autoReply: true` | 所有消息都触发所有 bot（无差别） | 无 @提及 → 全部触发；有 @提及 → 仅目标 |
| `autoReply: false`/未设置 | 仅 @提及触发 | 不变 |

即此改造让 `autoReply: true` 有了按 @提及 分流的能力。如升级后未重新应用此改造，`autoReply: true` 会回到"无差别全触发"的原始行为。

## 升级注意
OpenClaw 升级会覆盖 `dist/` 下的修改，需要重新应用此补丁。修改后重启 Gateway。
