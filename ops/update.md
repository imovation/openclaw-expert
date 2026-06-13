---
name: openclaw-expert-update
description: 更新升级 OpenClaw 版本，同步知识库官方文档，审核 BUG 修复状态。在 openclaw-expert skill 的更新上下文中使用。
---

# OpenClaw 更新

## 更新前

记录当前版本：
```bash
openclaw --version
```

检查当前状态：
```bash
openclaw gateway status
openclaw doctor
```

## 执行更新

```bash
openclaw update
```

如果 `openclaw update` 不可用（某些版本），使用 npm：
```bash
npm install -g openclaw@latest
```

## 更新后验证

```bash
openclaw --version
openclaw doctor --fix
openclaw gateway status
```

## 知识库文档同步

版本更新后，触发文档同步流程：

1. 运行 `scripts/version-check.sh --detect` 确认版本变化
2. 询问用户："检测到 openclaw 从 vX 更新到 vY，是否更新知识库官方文档？"
3. 用户确认后：
   - 运行 `scripts/fetch-docs.sh --version <新版本号>`
   - 脚本会遍历 `references/official-docs/index.json` 中的所有文档 URL 重新抓取
   - 对比更新，生成变更摘要
   - 更新 `~/.openclaw-expert/version-state.json`
4. 将变更摘要展示给用户

## BUG 修复审核

文档更新完成后，触发 BUG 审核流程：

1. 读取 `references/experience/index.json`，找出所有 `type: "bug"` 的经验
2. 对每条 `status: "active"` 的 bug：
   - 拉取新版本 release notes（从 GitHub releases 页面获取 changelog）
   - 关键词匹配判断是否提及修复
   - 运行 `scripts/bug-regression.sh --id <exp-id>` 本地验证 bug 是否仍存在
   - 综合判断：已修复则移动到 `archived/` 并标记 `fixed_in`；未修复则保留并检查 workaround 是否需要更新
3. 对每条 `status: "archived"` 的 bug：
   - 检查是否有 regression（之前修复的 bug 在新版本复现），如有则移回 `active/`
4. 生成审核报告展示给用户：
   - 已修复 X 条，未修复 Y 条，存档回归 Z 条
   - 每条列出：标题、审核结果、依据

## 更新 `~/.openclaw-expert/version-state.json`

```json
{
  "last_known_version": "<新版本>",
  "last_docs_update": "<当前ISO时间>",
  "installed_method": "npm"
}
```
