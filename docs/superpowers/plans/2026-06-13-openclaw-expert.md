# openclaw-expert Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an opencode skill that manages OpenClaw lifecycle operations (install, configure, update, fix, uninstall) with a self-evolving knowledge base.

**Architecture:** Modular skill with main SKILL.md as router (~60 lines), five domain sub-skills in `ops/`, four automation scripts in `scripts/`, and a dual-dimension knowledge base in `references/` (evolution dimension: official-docs / experience; topic dimension: 10 categories matching OpenClaw docs structure).

**Tech Stack:** Shell scripts (bash), Markdown (skill content), JSON (index/metadata), webfetch (docs fetching)

---

### Task 1: Create Directory Structure

**Files:** Create all directories (no files yet)

- [ ] **Step 1: Create all directories**

```bash
mkdir -p openclaw-expert/{ops,scripts,evals}
mkdir -p openclaw-expert/references/official-docs/{start,install,concepts,providers,gateway,tools,nodes,platforms,plugins,workspace}
mkdir -p openclaw-expert/references/experience/active/{start,install,concepts,providers,gateway,tools,nodes,platforms,plugins,workspace}
mkdir -p openclaw-expert/references/experience/archived/{start,install,concepts,providers,gateway,tools,nodes,platforms,plugins,workspace}
```

- [ ] **Step 2: Verify directories exist**

```bash
find openclaw-expert -type d | sort
```

Expected: 38 directories listed (1 root + 6 subdirs + 10 official-docs topics + 10 active topics + 10 archived topics + evals).

---

### Task 2: Write Main SKILL.md (Router)

**Files:**
- Create: `openclaw-expert/SKILL.md`

- [ ] **Step 1: Write SKILL.md**

```markdown
---
name: openclaw-expert
description: 管理 OpenClaw 的全生命周期运维：安装（npm/nix/docker）、配置（openclaw.json、模型、provider、channels、Gateway）、更新升级、故障诊断修复（Gateway 启停异常、channel 连接失败、模型调用报错、插件崩溃、sandbox 问题、agent 异常等）、卸载清理。当用户提到 openclaw 相关任何问题时都应触发——"openclaw 安装不了""Gateway 启动失败""模型不回复""telegram channel 连不上""openclaw 更新后出问题""插件不工作""sandbox 报错""openclaw 报错/异常/BUG"等。也覆盖 opencode 模型回退问题（常与 openclaw 模型配置相关）。
---

# OpenClaw Expert

管理 OpenClaw 全生命周期运维，知识库支持自进化。

## 启动流程

### 1. 版本检测

读取 `~/.openclaw-expert/version-state.json`，对比当前 `openclaw --version`：

- 文件不存在 → 首次运行，询问用户是否初始化知识库
- 版本一致 → 跳过，进入步骤 2
- 版本不同 → 提示用户检测到版本变化，询问是否更新知识库。用户确认后先执行 `ops/update.md` 子 skill，再处理用户意图

### 2. 意图路由

根据用户的表达，读取对应的子 skill：

| 用户意图 | 子 skill |
|---------|---------|
| 安装/install/setup/部署/openclaw 怎么装 | `ops/install.md` |
| 配置/config/settings/模型/model/provider/channel/密钥/token | `ops/configure.md` |
| 更新/upgrade/update/升级/openclaw 版本 | `ops/update.md` |
| 报错/异常/不工作/失败/BUG/问题/修复/诊断/修/error/crash | `ops/fix.md` |
| 卸载/uninstall/删除/清理/remove | `ops/uninstall.md` |

路由规则：
- 关键词匹配优先级：fix > update > install > configure > uninstall
- 如果用户表达模糊（如"openclaw 出问题了"），默认走 `ops/fix.md`
- 版本变化检测到但用户也想做其他操作 → 先 `ops/update.md` 再处理用户意图

### 3. 经验积累入口

运维操作完成后（特别是 fix 子 skill 完成后），检查是否满足经验积累条件：

- 用户说了"修好了/解决了/可以了/好了/OK/thanks"等确认信号 → 自动触发经验积累
- 用户没有明确确认 → 主动询问"问题是否已解决？需要将此经验记录到知识库吗？"

触发经验积累后，执行以下流程：
1. 总结本次运维操作：问题描述、根因、解决方案、适用版本、关键步骤
2. 确定主题归属 — 匹配 10 个主题目录中最相关的一个
3. 将总结内容写入临时文件，运行 `scripts/knowledge-manager.sh check-dedup --topic <topic> --title "<标题>" --content <临时文件路径>`
   - 输出 `new` → 运行 `add-experience` 新增经验文件
   - 输出 `merge:<existing_file>` → 运行 `merge-experience` 合并优化
   - 输出 `skip` → 与官方文档或已有经验完全重叠，放弃积累
4. 告知用户结果
```

- [ ] **Step 2: Verify file exists and has correct frontmatter**

```bash
head -5 openclaw-expert/SKILL.md
```

---

### Task 3: Write ops/install.md

**Files:**
- Create: `openclaw-expert/ops/install.md`

- [ ] **Step 1: Write ops/install.md**

```markdown
---
name: openclaw-expert-install
description: 安装 OpenClaw — npm 全局安装、Nix、Docker。在 openclaw-expert skill 的安装上下文中使用。
---

# OpenClaw 安装

## 前置检测

先检查当前环境：

```bash
which openclaw && openclaw --version
node --version
npm list -g openclaw 2>/dev/null
```

如果已安装，告知用户当前版本和安装方式，询问是否需要重装或更新。

## 安装流程

### npm 全局安装（首选）

```bash
npm install -g openclaw@latest
```

安装后验证：
```bash
openclaw --version
openclaw doctor
```

如果 `openclaw doctor` 有 warning，按提示修复。对于错误，查阅：
- `references/official-docs/install/` 下的官方文档
- `references/experience/active/install/` 下的运维经验

### Nix 安装

```bash
nix profile install github:openclaw/openclaw
```

查阅 `references/official-docs/install/` 下 Nix 相关文档获取完整步骤。

### Docker 安装

```bash
docker pull ghcr.io/openclaw/openclaw:latest
```

查阅 `references/official-docs/install/` 下 Docker 相关文档获取完整步骤。

## 常见安装问题

查阅 `references/experience/active/install/` 获取已知安装问题的解决方案。

## 安装后

更新版本状态：
```bash
openclaw --version > /dev/null 2>&1 && \
  scripts/version-check.sh --record
```

建议用户运行 `openclaw onboard --install-daemon` 完成初始配置。
```

- [ ] **Step 2: Verify file has valid YAML frontmatter**

```bash
head -5 openclaw-expert/ops/install.md
```

---

### Task 4: Write ops/configure.md

**Files:**
- Create: `openclaw-expert/ops/configure.md`

- [ ] **Step 1: Write ops/configure.md**

```markdown
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
```

- [ ] **Step 2: Verify file**

```bash
wc -l openclaw-expert/ops/configure.md
```

---

### Task 5: Write ops/update.md

**Files:**
- Create: `openclaw-expert/ops/update.md`

- [ ] **Step 1: Write ops/update.md**

```markdown
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
```

- [ ] **Step 2: Verify file**

```bash
head -5 openclaw-expert/ops/update.md
```

---

### Task 6: Write ops/fix.md

**Files:**
- Create: `openclaw-expert/ops/fix.md`

- [ ] **Step 1: Write ops/fix.md**

```markdown
---
name: openclaw-expert-fix
description: 诊断和修复 OpenClaw 问题 — Gateway 异常、channel 失败、模型报错、插件崩溃、sandbox 错误、agent 异常等。含源码级修复。在 openclaw-expert skill 的修复上下文中使用。
---

# OpenClaw 故障修复

## 诊断流程

### 1. 接收错误描述并分类

根据错误信息关键词确定问题主题：

| 关键词 | 主题 | 查阅路径 |
|--------|------|---------|
| gateway/daemon/端口/启动/守护进程/EADDRINUSE | gateway | `references/official-docs/gateway/` + `references/experience/active/gateway/` |
| channel/telegram/whatsapp/discord/slack/signal/matrix/连接/消息 | providers | `references/official-docs/providers/` + `references/experience/active/providers/` |
| model/provider/anthropic/openai/api/key/认证/模型 | providers | `references/official-docs/providers/` + `references/experience/active/providers/` |
| plugin/插件 | plugins | `references/official-docs/plugins/` + `references/experience/active/plugins/` |
| sandbox/沙箱/container | tools | `references/official-docs/tools/` + `references/experience/active/tools/` |
| agent/agent loop/session/memory | concepts | `references/official-docs/concepts/` + `references/experience/active/concepts/` |
| install/安装/npm | install | `references/official-docs/install/` + `references/experience/active/install/` |
| config/配置 | gateway | `references/official-docs/gateway/` + `references/experience/active/gateway/` |
| node/移动端/ios/android | nodes | `references/official-docs/nodes/` + `references/experience/active/nodes/` |

### 2. 查阅知识库

**优先级：** experience/active > official-docs > experience/archived（仅供参考）

- 先读取对应主题的 `references/experience/active/{topic}/` 下所有经验文件
- 如果没有匹配，读取 `references/official-docs/{topic}/` 下的相关文档
- `references/experience/archived/{topic}/` 仅作为背景参考

### 3. 本地诊断

使用 openclaw 内置诊断工具：

```bash
openclaw doctor             # 全面诊断
openclaw doctor --fix       # 自动修复常见问题
openclaw logs              # 查看 Gateway 日志
openclaw health            # Gateway 健康检查
openclaw gateway status    # Gateway 运行状态
openclaw models status     # 模型/provider 状态
openclaw channels status   # Channel 连接状态
```

### 4. 源码级修复

当问题无法通过配置或知识库解决时，尝试源码修复：

1. 定位 openclaw 安装路径：
```bash
npm root -g
# 通常在 /home/<user>/.nvm/versions/node/vXX/lib/node_modules/openclaw
```

2. 用 Read 工具查看相关源文件，定位问题代码

3. 用 Edit 工具修复代码

4. 修复后验证：
```bash
openclaw doctor
openclaw gateway restart
```

5. 修复完成后，触发经验积累流程（参考主 SKILL.md 第 3 节）

## 常见故障速查

以下问题直接查阅对应经验文件：
- Gateway 启动失败 → `references/experience/active/gateway/` + `references/experience/active/install/`
- 模型不回复/回复异常 → `references/experience/active/providers/`
- Channel 连接失败 → `references/experience/active/providers/`
- openclaw 命令找不到 → `references/experience/active/install/`
- opencode 模型回退到 big-pickle → 这通常是 openclaw 模型配置问题，查阅 `references/experience/active/providers/`
```

- [ ] **Step 2: Verify file**

```bash
wc -l openclaw-expert/ops/fix.md
```

---

### Task 7: Write ops/uninstall.md

**Files:**
- Create: `openclaw-expert/ops/uninstall.md`

- [ ] **Step 1: Write ops/uninstall.md**

```markdown
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
```

- [ ] **Step 2: Verify file**

```bash
head -5 openclaw-expert/ops/uninstall.md
```

---

### Task 8: Write scripts/version-check.sh

**Files:**
- Create: `openclaw-expert/scripts/version-check.sh`

- [ ] **Step 1: Write scripts/version-check.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="$HOME/.openclaw-expert/version-state.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

command_exists() {
  command -v "$1" &>/dev/null
}

get_current_version() {
  if command_exists openclaw; then
    openclaw --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
  else
    echo ""
  fi
}

do_detect() {
  CURRENT=$(get_current_version)
  if [ -z "$CURRENT" ]; then
    echo "NOT_INSTALLED"
    return 1
  fi

  if [ ! -f "$STATE_FILE" ]; then
    echo "FIRST_RUN:$CURRENT"
    return 2
  fi

  LAST=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('last_known_version',''))" 2>/dev/null || echo "")
  if [ "$CURRENT" != "$LAST" ]; then
    echo "VERSION_CHANGED:${LAST}->${CURRENT}"
    return 0
  else
    echo "UP_TO_DATE:$CURRENT"
    return 0
  fi
}

do_record() {
  CURRENT=$(get_current_version)
  if [ -z "$CURRENT" ]; then
    echo "Error: openclaw not installed"
    exit 1
  fi
  mkdir -p "$(dirname "$STATE_FILE")"
  python3 -c "
import json, datetime
state = {
  'last_known_version': '$CURRENT',
  'last_docs_update': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
  'installed_method': 'npm'
}
with open('$STATE_FILE', 'w') as f:
  json.dump(state, f, indent=2)
"
  echo "Recorded version: $CURRENT"
}

case "${1:-detect}" in
  --detect|-d) do_detect ;;
  --record|-r) do_record ;;
  --version|-v)
    get_current_version
    ;;
  *)
    echo "Usage: $0 [--detect|--record|--version]"
    echo "  --detect    Check if openclaw version changed"
    echo "  --record    Record current version to state file"
    echo "  --version   Print current openclaw version"
    exit 1
    ;;
esac
```

- [ ] **Step 2: Make executable**

```bash
chmod +x openclaw-expert/scripts/version-check.sh
```

- [ ] **Step 3: Test basic invocation**

```bash
openclaw-expert/scripts/version-check.sh --version
```

Expected: prints current openclaw version (e.g., "2026.6.6") or empty if not installed.

---

### Task 9: Write scripts/fetch-docs.sh

**Files:**
- Create: `openclaw-expert/scripts/fetch-docs.sh`

- [ ] **Step 1: Write scripts/fetch-docs.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/../references/official-docs"
INDEX_FILE="$DOCS_DIR/index.json"
NEW_VERSION="${1:-}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

if [ -z "$NEW_VERSION" ]; then
  echo "Usage: $0 --version <version>"
  echo "  Fetches/refreshes all official docs from openclaw.ai"
  exit 1
fi

if [ "$NEW_VERSION" = "--version" ]; then
  NEW_VERSION="${2:-}"
  if [ -z "$NEW_VERSION" ]; then
    echo "Error: version required"
    exit 1
  fi
fi

echo "Fetching OpenClaw docs for version: $NEW_VERSION"

if [ -f "$INDEX_FILE" ]; then
  echo "Found existing index, refreshing docs..."

  # Use python to parse index and fetch each URL
  python3 -c "
import json, subprocess, sys, os, datetime

with open('$INDEX_FILE') as f:
    index = json.load(f)

updated = 0
failed = 0
skipped = 0

for doc in index.get('docs', []):
    url = doc['source_url']
    filepath = os.path.join('$DOCS_DIR', doc['file'])
    os.makedirs(os.path.dirname(filepath), exist_ok=True)

    html_tmp = os.path.join('$TMP_DIR', os.path.basename(doc['file']) + '.html')
    result = subprocess.run(['curl', '-sL', '--max-time', '30', url],
                          capture_output=True, text=True)
    if result.returncode != 0:
        print(f'FAIL: {url}')
        failed += 1
        continue

    with open(html_tmp, 'w') as f:
        f.write(result.stdout)

    # Simple HTML-to-text extraction
    import re
    content = result.stdout
    content = re.sub(r'<script[^>]*>.*?</script>', '', content, flags=re.DOTALL)
    content = re.sub(r'<style[^>]*>.*?</style>', '', content, flags=re.DOTALL)
    content = re.sub(r'<[^>]+>', ' ', content)
    content = re.sub(r'\s+', ' ', content).strip()

    with open(filepath, 'w') as f:
        f.write(f'# {doc.get(\"title\", os.path.basename(doc[\"file\"]))}\n\n')
        f.write(f'> Source: {url}\n')
        f.write(f'> Fetched: {datetime.datetime.utcnow().strftime(\"%Y-%m-%dT%H:%M:%SZ\")}\n\n')
        f.write(content[:50000])  # Truncate to ~50K chars

    doc['fetched_at'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    updated += 1
    print(f'OK: {doc[\"file\"]}')

index['version'] = '$NEW_VERSION'
index['updated_at'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')

with open('$INDEX_FILE', 'w') as f:
    json.dump(index, f, indent=2, ensure_ascii=False)

print(f'\\nSummary: {updated} updated, {failed} failed, {skipped} skipped')
"
else
  echo "No index file found at $INDEX_FILE"
  echo "Run knowledge base initialization first (Task 10)"
  exit 1
fi

echo "Docs fetch complete"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x openclaw-expert/scripts/fetch-docs.sh
```

---

### Task 10: Write scripts/bug-regression.sh

**Files:**
- Create: `openclaw-expert/scripts/bug-regression.sh`

- [ ] **Step 1: Write scripts/bug-regression.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXP_INDEX="$SCRIPT_DIR/../references/experience/index.json"
BUG_ID="${1:-}"

if [ -z "$BUG_ID" ]; then
  echo "Usage: $0 --id <exp-id>"
  echo "  Attempts to reproduce a known bug locally"
  echo "  Returns 0 if bug is STILL PRESENT, 1 if FIXED, 2 if UNVERIFIABLE"
  exit 1
fi

if [ "$BUG_ID" = "--id" ]; then
  BUG_ID="${2:-}"
  if [ -z "$BUG_ID" ]; then
    echo "Error: exp-id required"
    exit 1
  fi
fi

get_bug_field() {
  local field="$1"
  python3 -c "
import json, sys
with open('$EXP_INDEX') as f:
    data = json.load(f)
for exp in data.get('experiences', []):
    if exp.get('id') == '$BUG_ID':
        print(exp.get('$field', ''))
        sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

TITLE=$(get_bug_field "title")
TOPIC=$(get_bug_field "topic")
STATUS=$(get_bug_field "status")
BUG_FILE=$(get_bug_field "file")

if [ -z "$TITLE" ]; then
  echo "Bug $BUG_ID not found in experience index"
  exit 2
fi

echo "============================================"
echo "BUG Regression Test: $TITLE"
echo "ID: $BUG_ID | Topic: $TOPIC | Status: $STATUS"
echo "============================================"

REPRO_SCRIPT="$SCRIPT_DIR/../references/experience/$BUG_FILE.repro.sh"

if [ -f "$REPRO_SCRIPT" ]; then
  echo "Running reproduction script: $REPRO_SCRIPT"
  if bash "$REPRO_SCRIPT"; then
    echo ""
    echo "RESULT: BUG STILL PRESENT"
    echo "The reproduction script succeeded, indicating the bug is NOT fixed."
    exit 0
  else
    echo ""
    echo "RESULT: BUG APPEARS FIXED"
    echo "The reproduction script failed, indicating the bug may be fixed."
    exit 1
  fi
fi

echo "No reproduction script found ($REPRO_SCRIPT)."
echo "Checking changelog for mentions of this bug..."

# Try to fetch GitHub release notes
OPENCLAW_VERSION=$(openclaw --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")
if [ -n "$OPENCLAW_VERSION" ]; then
  RELEASE_URL="https://github.com/openclaw/openclaw/releases/tag/v${OPENCLAW_VERSION}"
  echo "Fetching release notes: $RELEASE_URL"
  CHANGELOG=$(curl -sL --max-time 15 "$RELEASE_URL" 2>/dev/null || echo "")

  if [ -n "$CHANGELOG" ]; then
    # Search for keywords from the bug title
    KEYWORDS=$(echo "$TITLE" | tr ' ' '|')
    if echo "$CHANGELOG" | grep -qiE "($KEYWORDS)"; then
      echo "RESULT: CHANGELOG MENTIONS RELATED FIX - likely fixed"
      exit 1
    else
      echo "RESULT: NO MENTION IN CHANGELOG - likely still present"
      exit 0
    fi
  fi
fi

echo "RESULT: UNVERIFIABLE (no repro script, no changelog data)"
exit 2
```

- [ ] **Step 2: Make executable**

```bash
chmod +x openclaw-expert/scripts/bug-regression.sh
```

---

### Task 11: Write scripts/knowledge-manager.sh

**Files:**
- Create: `openclaw-expert/scripts/knowledge-manager.sh`

- [ ] **Step 1: Write scripts/knowledge-manager.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXP_INDEX="$SCRIPT_DIR/../references/experience/index.json"
DOCS_INDEX="$SCRIPT_DIR/../references/official-docs/index.json"
EXP_ACTIVE_DIR="$SCRIPT_DIR/../references/experience/active"

command="${1:-}"
shift || true

usage() {
  echo "Usage: $0 <command> [options]"
  echo ""
  echo "Commands:"
  echo "  check-dedup --topic <topic> --title <title> --content <file>"
  echo "      Check if new experience overlaps with existing docs/experiences"
  echo "      Outputs: new | merge:<file> | skip"
  echo ""
  echo "  add-experience --topic <topic> --title <title> --content <file> --type <bug|experience>"
  echo "      Add a new experience file and update index"
  echo ""
  echo "  merge-experience --existing <file> --content <file>"
  echo "      Merge new content into existing experience file"
  echo ""
  echo "  archive-experience --id <exp-id> --fixed-in <version>"
  echo "      Move an experience from active/ to archived/"
  echo ""
  echo "  unarchive-experience --id <exp-id>"
  echo "      Move an experience from archived/ back to active/"
  echo ""
}

check_dedup() {
  local topic="" title="" content_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --topic) topic="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --content) content_file="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ -z "$topic" ] || [ -z "$title" ] || [ -z "$content_file" ]; then
    echo "Error: --topic, --title, and --content are required"
    exit 1
  fi

  NEW_TITLE=$(echo "$title" | tr '[:upper:]' '[:lower:]')
  NEW_CONTENT=$(cat "$content_file" | tr '[:upper:]' '[:lower:]')
  NEW_KEYWORDS=$(echo "$NEW_TITLE" | tr -c 'a-z0-9' ' ')

  # Check against official docs
  DOCS_TOPIC_DIR="$SCRIPT_DIR/../references/official-docs/$topic"
  if [ -d "$DOCS_TOPIC_DIR" ]; then
    for doc in "$DOCS_TOPIC_DIR"/*.md; do
      [ -f "$doc" ] || continue
      DOC_CONTENT=$(cat "$doc" | tr '[:upper:]' '[:lower:]')
      # Simple overlap check: count common significant words
      COMMON=0
      for word in $NEW_KEYWORDS; do
        [ ${#word} -lt 4 ] && continue
        if echo "$DOC_CONTENT" | grep -qw "$word"; then
          COMMON=$((COMMON + 1))
        fi
      done
      TOTAL=$(echo "$NEW_KEYWORDS" | wc -w)
      if [ "$TOTAL" -gt 0 ] && [ "$COMMON" -gt $((TOTAL * 3 / 4)) ]; then
        echo "skip"
        return
      fi
    done
  fi

  # Check against active experiences
  ACTIVE_TOPIC_DIR="$EXP_ACTIVE_DIR/$topic"
  if [ -d "$ACTIVE_TOPIC_DIR" ]; then
    for exp_file in "$ACTIVE_TOPIC_DIR"/*.md; do
      [ -f "$exp_file" ] || continue
      EXP_CONTENT=$(cat "$exp_file" | tr '[:upper:]' '[:lower:]')
      EXP_TITLE=$(basename "$exp_file" .md | tr '-' ' ' | tr '[:upper:]' '[:lower:]')

      COMMON=0
      for word in $NEW_KEYWORDS; do
        [ ${#word} -lt 4 ] && continue
        if echo "$EXP_CONTENT" | grep -qw "$word"; then
          COMMON=$((COMMON + 1))
        fi
      done
      TOTAL=$(echo "$NEW_KEYWORDS" | wc -w)
      if [ "$TOTAL" -gt 0 ] && [ "$COMMON" -gt $((TOTAL * 2 / 3)) ]; then
        REL_PATH=$(echo "$exp_file" | sed "s|$EXP_ACTIVE_DIR/||")
        echo "merge:$REL_PATH"
        return
      fi
    done
  fi

  echo "new"
}

add_experience() {
  local topic="" title="" content_file="" exp_type="experience"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --topic) topic="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --content) content_file="$2"; shift 2 ;;
      --type) exp_type="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ -z "$topic" ] || [ -z "$title" ] || [ -z "$content_file" ]; then
    echo "Error: --topic, --title, and --content are required"
    exit 1
  fi

  EXP_DIR="$EXP_ACTIVE_DIR/$topic"
  mkdir -p "$EXP_DIR"

  FILE_NAME=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
  EXP_FILE="$EXP_DIR/${FILE_NAME}.md"
  TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  OPENCLAW_VER=$(openclaw --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")

  cp "$content_file" "$EXP_FILE"
  EXP_ID="exp-$(date +%s)"

  python3 -c "
import json, sys
with open('$EXP_INDEX') as f:
    index = json.load(f)

new_exp = {
    'id': '$EXP_ID',
    'title': '''$title''',
    'topic': '$topic',
    'file': 'active/$topic/${FILE_NAME}.md',
    'keywords': '''$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' ',')''',
    'type': '$exp_type',
    'related_bug': None,
    'status': 'active',
    'created_at': '$TIMESTAMP',
    'openclaw_version': '$OPENCLAW_VER'
}

index['experiences'].append(new_exp)
index['updated_at'] = '$TIMESTAMP'

with open('$EXP_INDEX', 'w') as f:
    json.dump(index, f, indent=2, ensure_ascii=False)
print('Added: $EXP_ID')
"
}

merge_experience() {
  local existing_file="" content_file=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --existing) existing_file="$2"; shift 2 ;;
      --content) content_file="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  if [ -z "$existing_file" ] || [ -z "$content_file" ]; then
    echo "Error: --existing and --content are required"
    exit 1
  fi

  FULL_EXISTING="$EXP_ACTIVE_DIR/$existing_file"
  if [ ! -f "$FULL_EXISTING" ]; then
    echo "Error: existing file not found: $FULL_EXISTING"
    exit 1
  fi

  {
    cat "$FULL_EXISTING"
    echo ""
    echo "---"
    echo "## 补充经验（$(date -u +"%Y-%m-%d")）"
    cat "$content_file"
  } > "${FULL_EXISTING}.tmp"

  mv "${FULL_EXISTING}.tmp" "$FULL_EXISTING"
  echo "Merged into: $existing_file"
}

archive_experience() {
  local exp_id="" fixed_in=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id) exp_id="$2"; shift 2 ;;
      --fixed-in) fixed_in="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  python3 -c "
import json, shutil, os

with open('$EXP_INDEX') as f:
    index = json.load(f)

for exp in index['experiences']:
    if exp['id'] == '$exp_id':
        topic = exp['topic']
        old_file = '$EXP_ACTIVE_DIR/' + exp['file'].replace('active/', '')
        new_relative = 'archived/' + topic + '/' + os.path.basename(exp['file'])
        new_file = '$SCRIPT_DIR/../references/experience/' + new_relative

        os.makedirs(os.path.dirname(new_file), exist_ok=True)
        if os.path.exists(old_file):
            shutil.move(old_file, new_file)

        exp['file'] = new_relative
        exp['status'] = 'archived'
        if '$fixed_in':
            exp['fixed_in'] = '$fixed_in'

        print(f'Archived: ' + exp['id'] + ' -> ' + new_relative)
        break

index['updated_at'] = '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
with open('$EXP_INDEX', 'w') as f:
    json.dump(index, f, indent=2, ensure_ascii=False)
"
}

unarchive_experience() {
  local exp_id=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id) exp_id="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  python3 -c "
import json, shutil, os

with open('$EXP_INDEX') as f:
    index = json.load(f)

for exp in index['experiences']:
    if exp['id'] == '$exp_id':
        topic = exp['topic']
        old_file = '$SCRIPT_DIR/../references/experience/' + exp['file']
        new_relative = 'active/' + topic + '/' + os.path.basename(exp['file'])
        new_file = '$EXP_ACTIVE_DIR/' + topic + '/' + os.path.basename(exp['file'])

        os.makedirs(os.path.dirname(new_file), exist_ok=True)
        if os.path.exists(old_file):
            shutil.move(old_file, new_file)

        exp['file'] = new_relative
        exp['status'] = 'active'
        if 'fixed_in' in exp:
            del exp['fixed_in']

        print(f'Unarchived: ' + exp['id'] + ' -> ' + new_relative)
        break

index['updated_at'] = '$(date -u +"%Y-%m-%dT%H:%M:%SZ")'
with open('$EXP_INDEX', 'w') as f:
    json.dump(index, f, indent=2, ensure_ascii=False)
"
}

case "$command" in
  check-dedup)  check_dedup "$@" ;;
  add-experience) add_experience "$@" ;;
  merge-experience) merge_experience "$@" ;;
  archive-experience) archive_experience "$@" ;;
  unarchive-experience) unarchive_experience "$@" ;;
  -h|--help|"") usage ;;
  *) echo "Unknown command: $command"; usage; exit 1 ;;
esac
```

- [ ] **Step 2: Make executable**

```bash
chmod +x openclaw-expert/scripts/knowledge-manager.sh
```

---

### Task 12: Initialize Knowledge Base Index Files

**Files:**
- Create: `openclaw-expert/references/official-docs/index.json`
- Create: `openclaw-expert/references/experience/index.json`

- [ ] **Step 1: Write official-docs/index.json**

```json
{
  "version": "2026.6.6",
  "updated_at": "",
  "docs": [
    {"title": "Getting Started", "topic": "start", "file": "start/getting-started.md", "source_url": "https://docs.openclaw.ai/start/getting-started", "fetched_at": ""},
    {"title": "Onboarding", "topic": "start", "file": "start/onboarding.md", "source_url": "https://docs.openclaw.ai/start/onboarding", "fetched_at": ""},
    {"title": "Setup", "topic": "start", "file": "start/setup.md", "source_url": "https://docs.openclaw.ai/start/setup", "fetched_at": ""},
    {"title": "Docs Directory", "topic": "start", "file": "start/docs-directory.md", "source_url": "https://docs.openclaw.ai/start/docs-directory", "fetched_at": ""},
    {"title": "Installation", "topic": "install", "file": "install/installation.md", "source_url": "https://docs.openclaw.ai/install/docker", "fetched_at": ""},
    {"title": "Updating", "topic": "install", "file": "install/updating.md", "source_url": "https://docs.openclaw.ai/install/updating", "fetched_at": ""},
    {"title": "Architecture", "topic": "concepts", "file": "concepts/architecture.md", "source_url": "https://docs.openclaw.ai/concepts/architecture", "fetched_at": ""},
    {"title": "Agent Runtime", "topic": "concepts", "file": "concepts/agent.md", "source_url": "https://docs.openclaw.ai/concepts/agent", "fetched_at": ""},
    {"title": "Multi-Agent Routing", "topic": "concepts", "file": "concepts/multi-agent.md", "source_url": "https://docs.openclaw.ai/concepts/multi-agent", "fetched_at": ""},
    {"title": "Memory", "topic": "concepts", "file": "concepts/memory.md", "source_url": "https://docs.openclaw.ai/concepts/memory", "fetched_at": ""},
    {"title": "Sessions", "topic": "concepts", "file": "concepts/session.md", "source_url": "https://docs.openclaw.ai/concepts/session", "fetched_at": ""},
    {"title": "Model Failover", "topic": "providers", "file": "providers/model-failover.md", "source_url": "https://docs.openclaw.ai/concepts/model-failover", "fetched_at": ""},
    {"title": "Channels Overview", "topic": "providers", "file": "providers/channels.md", "source_url": "https://docs.openclaw.ai/channels", "fetched_at": ""},
    {"title": "Telegram Channel", "topic": "providers", "file": "providers/telegram.md", "source_url": "https://docs.openclaw.ai/channels/telegram", "fetched_at": ""},
    {"title": "WhatsApp Channel", "topic": "providers", "file": "providers/whatsapp.md", "source_url": "https://docs.openclaw.ai/channels/whatsapp", "fetched_at": ""},
    {"title": "Gateway Runbook", "topic": "gateway", "file": "gateway/runbook.md", "source_url": "https://docs.openclaw.ai/gateway", "fetched_at": ""},
    {"title": "Gateway Configuration", "topic": "gateway", "file": "gateway/configuration.md", "source_url": "https://docs.openclaw.ai/gateway/configuration", "fetched_at": ""},
    {"title": "Gateway Health", "topic": "gateway", "file": "gateway/health.md", "source_url": "https://docs.openclaw.ai/gateway/health", "fetched_at": ""},
    {"title": "Gateway Security", "topic": "gateway", "file": "gateway/security.md", "source_url": "https://docs.openclaw.ai/gateway/security", "fetched_at": ""},
    {"title": "Gateway Troubleshooting", "topic": "gateway", "file": "gateway/troubleshooting.md", "source_url": "https://docs.openclaw.ai/gateway/troubleshooting", "fetched_at": ""},
    {"title": "Gateway Remote Access", "topic": "gateway", "file": "gateway/remote.md", "source_url": "https://docs.openclaw.ai/gateway/remote", "fetched_at": ""},
    {"title": "Gateway Logging", "topic": "gateway", "file": "gateway/logging.md", "source_url": "https://docs.openclaw.ai/gateway/logging", "fetched_at": ""},
    {"title": "Gateway Sandboxing", "topic": "gateway", "file": "gateway/sandboxing.md", "source_url": "https://docs.openclaw.ai/gateway/sandboxing", "fetched_at": ""},
    {"title": "Tools Overview", "topic": "tools", "file": "tools/overview.md", "source_url": "https://docs.openclaw.ai/tools", "fetched_at": ""},
    {"title": "Exec Tool", "topic": "tools", "file": "tools/exec.md", "source_url": "https://docs.openclaw.ai/tools/exec", "fetched_at": ""},
    {"title": "Browser Tool", "topic": "tools", "file": "tools/browser.md", "source_url": "https://docs.openclaw.ai/tools/browser", "fetched_at": ""},
    {"title": "Sub-agents", "topic": "tools", "file": "tools/subagents.md", "source_url": "https://docs.openclaw.ai/tools/subagents", "fetched_at": ""},
    {"title": "Cron Jobs", "topic": "tools", "file": "tools/cron-jobs.md", "source_url": "https://docs.openclaw.ai/automation/cron-jobs", "fetched_at": ""},
    {"title": "Nodes Overview", "topic": "nodes", "file": "nodes/overview.md", "source_url": "https://docs.openclaw.ai/nodes", "fetched_at": ""},
    {"title": "Platforms Overview", "topic": "platforms", "file": "platforms/overview.md", "source_url": "https://docs.openclaw.ai/platforms", "fetched_at": ""},
    {"title": "Linux Platform", "topic": "platforms", "file": "platforms/linux.md", "source_url": "https://docs.openclaw.ai/platforms/linux", "fetched_at": ""},
    {"title": "Plugins Overview", "topic": "plugins", "file": "plugins/overview.md", "source_url": "https://docs.openclaw.ai/tools/plugin", "fetched_at": ""},
    {"title": "Building Plugins", "topic": "plugins", "file": "plugins/building-plugins.md", "source_url": "https://docs.openclaw.ai/plugins/building-plugins", "fetched_at": ""},
    {"title": "Skills", "topic": "workspace", "file": "workspace/skills.md", "source_url": "https://docs.openclaw.ai/tools/skills", "fetched_at": ""}
  ]
}
```

- [ ] **Step 2: Write experience/index.json**

```json
{
  "updated_at": "",
  "experiences": []
}
```

- [ ] **Step 3: Verify JSON syntax**

```bash
python3 -c "import json; json.load(open('openclaw-expert/references/official-docs/index.json')); print('OK')"
python3 -c "import json; json.load(open('openclaw-expert/references/experience/index.json')); print('OK')"
```

---

### Task 13: Populate Official Docs (Initial Fetch)

**Files:**
- Create: initial doc files under `references/official-docs/*/`

- [ ] **Step 1: Run initial docs fetch**

```bash
scripts/fetch-docs.sh --version 2026.6.6
```

This will iterate through all URLs in `official-docs/index.json` and create markdown files in each topic directory.

- [ ] **Step 2: Verify docs were created**

```bash
find references/official-docs -name "*.md" | wc -l
```

Expected: 34 markdown files (one per doc entry in index.json).

- [ ] **Step 3: Verify each topic directory has content**

```bash
for topic in start install concepts providers gateway tools nodes platforms plugins workspace; do
  count=$(find references/official-docs/$topic -name "*.md" 2>/dev/null | wc -l)
  echo "$topic: $count files"
done
```

---

### Task 14: Record Initial Version State

**Files:**
- Create: `~/.openclaw-expert/version-state.json` (via script)

- [ ] **Step 1: Record current version**

```bash
scripts/version-check.sh --record
```

- [ ] **Step 2: Verify state file**

```bash
cat ~/.openclaw-expert/version-state.json
```

---

### Task 15: Create Eval Test Cases

**Files:**
- Create: `openclaw-expert/evals/evals.json`

- [ ] **Step 1: Write evals.json**

```json
{
  "skill_name": "openclaw-expert",
  "evals": [
    {
      "id": 1,
      "prompt": "我的 openclaw 突然启动不了了，Gateway 一直在报错说端口被占用，怎么解决？",
      "expected_output": "Skill should route to ops/fix.md, diagnose port conflict, check gateway troubleshooting docs and active experiences, suggest solution (kill competing process or change port).",
      "files": []
    },
    {
      "id": 2,
      "prompt": "我刚装了 openclaw 但不知道怎么配置 telegram channel，需要什么步骤？",
      "expected_output": "Skill should route to ops/configure.md, guide through channels config, reference telegram channel docs in official-docs/providers/.",
      "files": []
    },
    {
      "id": 3,
      "prompt": "openclaw 模型一直不回消息，是不是 api key 配置有问题？",
      "expected_output": "Skill should route to ops/fix.md, classify as providers/model issue, check model status, guide debugging api key configuration.",
      "files": []
    },
    {
      "id": 4,
      "prompt": "我用的 NixOS，怎么在 openclaw 里装插件？",
      "expected_output": "Skill should route to ops/install.md (Nix path) + ops/configure.md (plugins), reference official-docs/install/ and official-docs/plugins/.",
      "files": []
    },
    {
      "id": 5,
      "prompt": "openclaw 更新到最新版后 sandbox 报错，之前都能用的",
      "expected_output": "Skill should route to ops/update.md first (version change detected), sync docs, run bug audit, then route to ops/fix.md for the sandbox issue.",
      "files": []
    }
  ]
}
```

- [ ] **Step 2: Verify JSON syntax**

```bash
python3 -c "import json; json.load(open('openclaw-expert/evals/evals.json')); print('OK')"
```

---

### Task 16: Add .gitignore

**Files:**
- Create: `openclaw-expert/.gitignore`

- [ ] **Step 1: Write .gitignore**

```
.superpowers/
```

- [ ] **Step 2: Verify**

```bash
cat openclaw-expert/.gitignore
```

---

### Task 17: Final Verification

**Files:** Verify all created

- [ ] **Step 1: List all files**

```bash
find openclaw-expert -type f | sort
```

- [ ] **Step 2: Verify SKILL.md frontmatter is valid**

```bash
head -6 openclaw-expert/SKILL.md
```

- [ ] **Step 3: Verify all scripts are executable**

```bash
ls -la openclaw-expert/scripts/
```

- [ ] **Step 4: Verify all ops files have YAML frontmatter**

```bash
for f in openclaw-expert/ops/*.md; do
  echo "=== $f ==="
  head -5 "$f"
done
```

- [ ] **Step 5: Run version check**

```bash
openclaw-expert/scripts/version-check.sh --detect
```

Expected: outputs `FIRST_RUN:<version>` or `UP_TO_DATE:<version>`.
