# Matrix ACP 会话重复回复

## 问题
当 ACP 会话通过 `/acp spawn opencode --bind here` 绑定到 Matrix 私聊后，用户的每一条消息机器人都回复两次相同的文本。

## 根因
ACP 消息投递有两条独立路径：
1. **Block reply 路径** — `sendBlockReply()` 将文本增量/完整内容发送到 Matrix
2. **Final fallback 路径** — `finalizeAcpTurnOutput()` 在回合结束时检查"是否已有可见文本投递"，如果没有则补发一次完整内容

`hasDeliveredVisibleText()` 通过 `shouldTreatDeliveredTextAsVisible()` 判断 block reply 是否"可见"。各渠道的表现：

| 渠道 | 行为 | 结果 |
|------|------|------|
| Discord | 有 `shouldTreatDeliveredTextAsVisible` override | block 算可见，不重复 |
| Telegram | 有 `shouldTreatDeliveredTextAsVisible` override | block 算可见，不重复 |
| **Matrix** | **无 override** | **block 不可见 → 触发 fallback → 重复** |

## 修复
在 `dist/dispatch-acp-Bz2s-_MS.js` 的 `shouldTreatDeliveredTextAsVisible()` 函数中，对 Matrix 渠道的 block 投递直接返回 true：

```javascript
if (channelId === "matrix" && params.kind === "block" && typeof params.text === "string" && params.text.trim().length > 0) return true;
```

## 修复位置
`dispatch-acp-Bz2s-_MS.js:377`

## 先前的尝试（无效）
在 `channel-DtgDXmyJ.js` 的 `matrixChannelOutbound` 中添加 `shouldTreatDeliveredTextAsVisible` 方法。但运行时 `getChannelPlugin("matrix")?.outbound` 返回的对象**不包含**该方法（channel plugin registry 中的 outbound 对象与源码定义不是同一个引用），因此无效。

## 修复脚本（推荐）
使用以下 bash 脚本可以自动检测并应用修复。升级 OpenClaw 后只需重新运行一次：

```bash
#!/usr/bin/env bash
# openclaw-matrix-acp-dedupe 修补脚本
# 用法: bash patch-matrix-dedupe.sh --apply

OPENCLAW_DIR="$(dirname "$(dirname "$(which openclaw)")")/lib/node_modules/openclaw"
DISPATCH_FILE=$(find "$OPENCLAW_DIR/dist" -name 'dispatch-acp-*.js' 2>/dev/null | head -1)
DISPATCH_BACKUP="${DISPATCH_FILE}.bak"

# 检查是否已修补
grep -q "channelId === \"matrix\" && params.kind === \"block\"" "$DISPATCH_FILE" 2>/dev/null && {
    echo "✅ 已修补"
    exit 0
}

# 备份
[ ! -f "$DISPATCH_BACKUP" ] && cp "$DISPATCH_FILE" "$DISPATCH_BACKUP" && echo "✅ 备份: $DISPATCH_BACKUP"

# 修补
ANCHOR='if (channelId) return false;'
PATCH='if (channelId) return false;\n\tif (channelId === "matrix" \x26\x26 params.kind === "block" \x26\x26 typeof params.text === "string" \x26\x26 params.text.trim().length > 0) return true;'

python3 -c "
import re, sys
with open('$DISPATCH_FILE', 'r') as f: c = f.read()
# 在第一个 return false 前插入
c = c.replace('if (!channelId) return false;', 'if (!channelId) return false;\n\tif (channelId === \"matrix\" \x26\x26 params.kind === \"block\" \x26\x26 typeof params.text === \"string\" \x26\x26 params.text.trim().length > 0) return true;', 1)
with open('$DISPATCH_FILE', 'w') as f: f.write(c)
print('OK')
" 2>&1 | grep -q OK && echo "✅ 修补成功" || echo "❌ 修补失败"
```

## 相关配置
配置 `acp.stream.deliveryMode` 为 `"live"` 时会触发此问题。默认值 `"final_only"` 不会出现此问题。

```json
{
  "acp": {
    "stream": {
      "deliveryMode": "live"
    }
  }
}
```

## 升级后重新应用
OpenClaw 升级（`npm update -g openclaw`）会覆盖 `dist/`，导致修补丢失。升级后需要重新运行修复脚本并重启 Gateway：

```bash
bash patch-matrix-dedupe.sh --apply
openclaw gateway restart
```
