---
name: openclaw-expert-uninstall
description: 卸载 OpenClaw — 清理 Gateway 服务、npm 包、配置文件、状态目录。在 openclaw-expert skill 的卸载上下文中使用。
---

# OpenClaw 卸载

## 卸载前

确认当前安装状态：
```bash
openclaw --version
openclaw gateway status
npm list -g openclaw 2>/dev/null
```

## 卸载步骤

### 1. 停止并移除 Gateway 服务

```bash
openclaw uninstall
```

如果 `openclaw uninstall` 不可用，手动操作：
```bash
openclaw gateway stop
# 移除 systemd 服务（Linux）
systemctl --user stop openclaw-gateway 2>/dev/null
systemctl --user disable openclaw-gateway 2>/dev/null
# 移除 launchd 服务（macOS）
launchctl unload ~/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null
```

### 2. 移除 npm 全局包

```bash
npm uninstall -g openclaw
```

### 3. 清理残留

询问用户是否删除：
- `~/.openclaw/` — OpenClaw 状态和配置目录
- `~/.openclaw-dev/` — 开发模式状态（如存在）
- npm 全局缓存中的 openclaw 相关文件

建议用户先备份再删除：
```bash
# 备份（可选）
cp -r ~/.openclaw ~/.openclaw.backup.$(date +%Y%m%d)
```

### 4. 清理 openclaw-expert 状态

询问用户是否保留：
- `~/.openclaw-expert/version-state.json` — 技能状态文件
- `references/` — 知识库文件（在 skill 目录内，skill 卸载时一并移除）

如果用户选择保留知识库供将来重装使用，将 `references/` 备份到用户指定位置。

## 验证卸载

```bash
which openclaw    # 应返回 "openclaw not found"
openclaw doctor    # 应报错命令不存在（预期行为）
```
