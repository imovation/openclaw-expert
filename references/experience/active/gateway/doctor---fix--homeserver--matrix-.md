# doctor --fix 移动 homeserver 导致 Matrix 全离线

## 问题
`openclaw doctor --fix` 将 `channels.matrix.homeserver` 和 `groupPolicy` 从顶层移入 `accounts.default`，Gateway 重启后所有 Bot 离线。

## 根因
`dist/setup-promotion-keys-Oj7oZvpC.js` 的 `COMMON_SINGLE_ACCOUNT_PROMOTION_KEYS` 错误包含了 `homeserver` 和 `groupPolicy`。这两个是 channel 级别配置，config merge 不做 `accounts.default`→命名账户继承，导致命名账号丢失 homeserver。

## 修复
从 `COMMON_SINGLE_ACCOUNT_PROMOTION_KEYS` 移除 `"homeserver"` 和 `"groupPolicy"`。

## 临时规避
在 `channels.matrix` 顶层手动补回 `homeserver` 和 `groupPolicy`。

## 适用版本
OpenClaw 2026.6.6
