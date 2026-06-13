# openclaw-expert Design Spec

> 基于 skill 机制、支持知识库自进化的 OpenClaw 运维专家

## 1. 概述

### 1.1 目标

`openclaw-expert` 是一个 opencode skill，负责本机 OpenClaw 的全生命周期运维，并具备知识库自进化能力。

### 1.2 核心能力

- **运维覆盖**：安装、配置、更新、故障修复（含源码级修复）、卸载
- **知识库自进化**：随 OpenClaw 版本更新自动同步官方文档，积累并优化运维经验
- **完全符合 skill 机制**：按需加载、渐进式披露、遵循 skill-creator 规范

### 1.3 关键决策

| 决策项 | 结论 |
|--------|------|
| 运维范围 | 全范围 — OpenClaw CLI、Gateway、channels、agents、MCP、plugins、memory 等 |
| 版本检测触发 | 自动检测 + 用户确认后执行 |
| BUG 修复方式 | 源码级修复（定位并修改 openclaw 源码） |
| 知识库存储 | Skill 内置 `references/` 目录 |
| 冲突处理 | 经验与官方文档并陈标注，不覆盖 |
| BUG 审核深度 | changelog 比对 + 本地回归验证 + 自动归档 |
| 经验积累触发 | 用户确认（主动说"修好了"）或技能主动询问 |
| 安装支持 | 先支持 npm，经验积累时自然扩展 |

---

## 2. Skill 目录结构

```
openclaw-expert/
├── SKILL.md                      # 主路由 skill（~60行）
├── ops/                          # 运维子 skill
│   ├── install.md
│   ├── configure.md
│   ├── update.md
│   ├── fix.md
│   └── uninstall.md
├── scripts/                      # 自动化脚本（不加载入 context，仅通过 Bash 执行）
│   ├── version-check.sh          # 检测 openclaw 版本变化
│   ├── fetch-docs.sh             # 拉取官方文档
│   ├── bug-regression.sh         # BUG 回归验证
│   └── knowledge-manager.sh      # 知识库去重/合并/归档
├── references/                   # 知识库（双维度组织）
│   ├── official-docs/            # 进化维度1：官方文档快照
│   │   ├── index.json
│   │   ├── start/
│   │   ├── install/
│   │   ├── concepts/
│   │   ├── providers/
│   │   ├── gateway/
│   │   ├── tools/
│   │   ├── nodes/
│   │   ├── platforms/
│   │   ├── plugins/
│   │   └── workspace/
│   └── experience/               # 进化维度2：运维经验
│       ├── index.json
│       ├── active/               # 活跃经验
│       │   ├── start/
│       │   ├── install/
│       │   ├── concepts/
│       │   ├── providers/
│       │   ├── gateway/
│       │   ├── tools/
│       │   ├── nodes/
│       │   ├── platforms/
│       │   ├── plugins/
│       │   └── workspace/
│       └── archived/             # 已归档经验（目录结构镜像 active/）
└── evals/
    └── evals.json
```

---

## 3. 渐进式披露（三层加载）

### 第 1 层：元数据（始终在 context）

**name:** `openclaw-expert`

**description:**

```
管理 OpenClaw 的全生命周期运维：安装（npm/nix/docker）、配置（openclaw.json、模型、provider、channels、Gateway）、
更新升级、故障诊断修复（Gateway 启停异常、channel 连接失败、模型调用报错、插件崩溃、sandbox 问题、agent 异常等）、
卸载清理。当用户提到 openclaw 相关任何问题时都应触发——"openclaw 安装不了""Gateway 启动失败""模型不回复"
"telegram channel 连不上""openclaw 更新后出问题""插件不工作""sandbox 报错""openclaw 报错/异常/BUG"等。
也覆盖 opencode 模型回退问题（常与 openclaw 模型配置相关）。
```

### 第 2 层：主 SKILL.md（技能激活时加载，~60行）

职责：
1. 版本检测入口 → 读取 `~/.openclaw-expert/version-state.json`，对比当前版本
2. 意图路由 → 根据用户表达指向对应 `ops/` 子 skill
3. 经验积累入口 → 运维操作完成后触发

路由映射：
```
用户意图                       → 子 skill
安装/install/setup/部署        → ops/install.md
配置/config/模型/channel       → ops/configure.md
更新/upgrade/update/升级       → ops/update.md
报错/异常/不工作/BUG/修复       → ops/fix.md
卸载/uninstall/删除/清理       → ops/uninstall.md
版本变化检测到                  → 先 ops/update.md 再处理用户意图
```

### 第 3 层：按需加载

- 子 skill（`ops/*.md`）— 根据需要由 AI 通过 `read` 工具加载
- 知识库（`references/`）— 根据主题按路径加载对应文件
- 脚本（`scripts/`）— 仅通过 Bash 执行，永不加载入 context

---

## 4. 知识库双维度结构

### 4.1 进化维度（一级目录）

| 目录 | 含义 |
|------|------|
| `official-docs/` | OpenClaw 官方文档快照，随版本更新 |
| `experience/active/` | 活跃运维经验，经过验证、仍适用 |
| `experience/archived/` | 已归档经验（官方修复或不再适用的 BUG） |

### 4.2 主题维度（二级目录，10个主题）

参考 [OpenClaw 官方文档](https://docs.openclaw.ai/start/hubs) 分类：

| 主题目录 | 覆盖内容 |
|---------|---------|
| `start/` | 入门、onboarding、setup |
| `install/` | 安装方式、更新/回滚、Docker、Nix |
| `concepts/` | 架构、agent、memory、session、routing、compaction 等 |
| `providers/` | 模型 provider 配置、channels 接入 |
| `gateway/` | Gateway 运行、健康检查、日志、安全、远程访问、troubleshooting |
| `tools/` | exec、browser、subagents、cron、slash-commands |
| `nodes/` | 移动节点配对、camera、audio、voice |
| `platforms/` | macOS、Linux、Windows、iOS、Android |
| `plugins/` | 插件开发、安装、管理、hooks |
| `workspace/` | Skills、templates、AGENTS 配置 |

### 4.3 索引文件

`references/official-docs/index.json`:
```json
{
  "version": "2026.6.6",
  "updated_at": "2026-06-13T12:00:00Z",
  "docs": [
    {
      "topic": "gateway",
      "file": "gateway/health.md",
      "source_url": "https://docs.openclaw.ai/gateway/health",
      "fetched_at": "2026-06-13T12:00:00Z"
    }
  ]
}
```

`references/experience/index.json`:
```json
{
  "updated_at": "2026-06-13T12:00:00Z",
  "experiences": [
    {
      "id": "exp-001",
      "title": "Gateway 启动时端口冲突",
      "topic": "gateway",
      "file": "active/gateway/port-conflict.md",
      "keywords": ["端口", "冲突", "EADDRINUSE", "Gateway 启动"],
      "type": "bug",
      "related_bug": null,
      "status": "active",
      "created_at": "2026-06-13T10:00:00Z",
      "openclaw_version": "2026.6.6"
    }
  ]
}
```

---

## 5. 知识库自进化机制

### 5.1 版本检测 + 文档更新

```
技能激活
  ↓
读取 ~/.openclaw-expert/version-state.json
  ↓
last_known_version ≠ 当前 openclaw --version？
  ↓ 是
提示用户："检测到 openclaw 从 vX 更新到 vY，是否更新知识库文档？"
  ↓ 用户确认
scripts/fetch-docs.sh --version vY
  ↓
遍历 official-docs/index.json 中所有文档的 source_url，重新抓取
  ↓
对比更新，生成变更摘要（新增/修改/删除的文档）
  ↓
更新 version-state.json
```

### 5.2 运维经验积累

```
运维操作完成
  ↓
用户说"修好了/解决了" 或 技能主动问"是否积累此经验？"
  ↓ 用户确认
技能总结：问题描述、根因、解决方案、适用版本、关键步骤
  ↓
分析主题归属（关键词匹配 → 确定 references/experience/active/{topic}/ 目标）
  ↓
去重检查：
  ├── 主题与 official-docs 完全重叠且无新信息 → 放弃积累
  ├── 主题与已有 active 经验重叠但信息更丰富 → 合并优化原文件
  └── 主题不重叠或官方文档未覆盖 → 新增经验文件
  ↓
更新 experience/index.json
```

### 5.3 BUG 修复审核（版本更新时触发）

```
文档更新完成
  ↓
遍历 experience/active/ 和 experience/archived/ 中标记为 bug 的经验
  ↓
对每条 active bug，执行三步审核：
  ├① 拉取新版本 release notes / changelog，关键词匹配是否提及修复
  ├② scripts/bug-regression.sh：本地重现 bug 场景，验证是否仍存在
  └③ 综合判断：
       ├── 已修复 → 移动到 archived/，标记 fixed_in: vY
       └── 未修复 → 保留在 active/，若 workaround 在新版本下无效则更新
  ↓
对每条 archived bug：
  └── 检查是否有 regression（之前修复的 bug 在新版本复现），如有则移回 active/
  ↓
生成审核报告给用户
```

---

## 6. 子 Skill 设计

每个子 skill 有独立的 YAML frontmatter（name + description），按需加载。

### 6.1 `ops/install.md`

- **前置检测**：`which openclaw`、`npm list -g openclaw`、Node.js 版本
- **安装路径**：npm 全局安装（主）、Nix、Docker
- **安装后验证**：`openclaw --version`、`openclaw doctor`
- **失败处理**：查阅 `references/official-docs/install/` 和 `references/experience/active/install/`

### 6.2 `ops/configure.md`

- **配置文件**：`~/.openclaw/openclaw.json`
- **配置域**：models/provider、channels、gateway（端口/绑定）、security（allowlists/tokens）、memory、plugins
- **校验**：`openclaw config validate`、`openclaw doctor`
- **每个配置域引导查阅**对应官方文档和运维经验

### 6.3 `ops/update.md`

- 执行 `openclaw update`
- 触发知识库文档同步（见 5.1）
- 触发 BUG 审核（见 5.3）
- 更新后健康检查：`openclaw doctor --fix`

### 6.4 `ops/fix.md`

- **接收错误描述** → 分类到主题 → 查阅该主题的 `official-docs` + `experience/active`
- **诊断优先级**：experience/active > official-docs > experience/archived（参考用）
- **本地诊断**：`openclaw doctor`、`openclaw logs`、`openclaw health`、`openclaw gateway status`
- **源码修复**：定位 `npm root -g` 下的 openclaw 源码，用 Edit 工具修复
- **修复后**：触发经验积累流程（见 5.2）

### 6.5 `ops/uninstall.md`

- 执行 `openclaw uninstall` 或手动清理
- 检查残留：`~/.openclaw/` 状态目录、npm 全局包、系统服务（launchd/systemd）
- 询问是否保留本地数据：`~/.openclaw-expert/version-state.json`

---

## 7. 状态文件

### `~/.openclaw-expert/version-state.json`

```json
{
  "last_known_version": "2026.6.6",
  "last_docs_update": "2026-06-13T12:00:00Z",
  "installed_method": "npm"
}
```

由 scripts 维护，技能只读取。

---

## 8. 错误处理

| 场景 | 处理策略 |
|------|---------|
| 文档抓取失败（网络问题） | 跳过该文档，记录到日志，继续处理其他文档 |
| 版本状态文件不存在 | 视为首次运行，主动问用户是否初始化知识库 |
| BUG 回归验证失败（无法复合场景） | 标记为"无法验证"，依赖 changelog 判断 |
| 经验去重判断模糊 | 保守处理——新增独立文件，让用户后续手动合并 |
| openclaw 本身损坏无法运行 | 技能仍可工作（知识库和 scripts 独立），引导重装 |

---

## 9. 测试策略

- **运维子 skill 测试**：模拟各种错误场景，验证 skill 能否正确诊断和修复
- **知识库进化测试**：模拟版本更新，验证文档同步、经验去重、BUG 审核归档
- **触发精度测试**：用 skill-creator 的 description optimization 流程验证和优化触发率

---

## 10. 实现阶段划分

| 阶段 | 内容 | 依赖 |
|------|------|------|
| Phase 1 | 主 SKILL.md + 五个子 skill 骨架 + scripts 骨架 | 无 |
| Phase 2 | 知识库基础填充（初始化官方文档 + 基础经验） | Phase 1 |
| Phase 3 | 自进化机制（版本检测、文档更新、经验积累、BUG 审核） | Phase 2 |
| Phase 4 | 触发优化（description tuning + eval） | Phase 3 |
| Phase 5 | 完善和扩展（Nix/Docker 安装、更多经验积累） | Phase 4 |
