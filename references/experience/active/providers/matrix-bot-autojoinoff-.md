## 问题描述

Matrix bot 在 Element 中创建私聊并发送消息后无响应，bot 不会回复任何消息。

## 根因

配置中 `channels.matrix.autoJoin` 默认为 `"off"`。OpenClaw 无法在邀请时区分房间是群组还是私聊，所有邀请（包括 DM 邀请）都经过 `autoJoin` 判断。`"off"` 导致 bot 不会接受任何邀请，因此无法加入私聊房间，也看不到用户发送的消息。

## 解决方案

将 `channels.matrix.autoJoin` 改为 `"always"`（接受所有邀请）或 `"allowlist"`（配合 `autoJoinAllowlist` 限制接受指定房间）：

```json5
{
  channels: {
    matrix: {
      autoJoin: "always",  // 或 "allowlist" + autoJoinAllowlist
    },
  },
}
```

修改后执行 `openclaw gateway restart` 使配置生效。

## 注意点

1. `dm.policy`（默认为 `"pairing"`）仅在 bot **加入房间并完成分类后**才生效，`autoJoin` 是前置条件
2. `autoJoin: "off"` 下，即使手动在其他客户端接受邀请，bot 也不会自动进入新房间
3. 若需限制 bot 只加入特定房间，使用 `autoJoin: "allowlist"` + `autoJoinAllowlist`，如 `["!roomId:server", "#alias:server"]`

## 适用版本

OpenClaw 2026.6.6
