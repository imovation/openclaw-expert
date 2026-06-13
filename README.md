# openclaw-expert

基于 opencode skill 机制、支持知识库自进化的 OpenClaw 运维专家。

## 核心能力

- **全生命周期运维**：安装、配置、更新、故障修复（含源码级修复）、卸载
- **知识库自进化**：随 OpenClaw 版本更新自动同步官方文档，积累并优化运维经验
- **渐进式披露**：三层加载（元数据 → 主 SKILL.md → 子 skill + 知识库 + 脚本）

## 目录结构

```
openclaw-expert/
├── SKILL.md                # 主路由 skill
├── ops/                    # 运维子 skill
│   ├── install.md          # 安装（npm/nix/docker）
│   ├── configure.md        # 配置
│   ├── update.md           # 更新 + 知识库同步 + BUG 审核
│   ├── fix.md              # 故障诊断修复
│   └── uninstall.md        # 卸载
├── scripts/                # 自动化脚本
│   ├── version-check.sh    # 版本检测
│   ├── fetch-docs.sh       # 拉取官方文档
│   ├── bug-regression.sh   # BUG 回归验证
│   └── knowledge-manager.sh # 知识库管理
├── references/             # 知识库（双维度组织）
│   ├── official-docs/      # 官方文档快照
│   └── experience/         # 运维经验（active/archived）
├── evals/                  # 测试用例
└── docs/                   # 设计文档
```

## 使用说明

### 安装

将 `openclaw-expert` 复制到 opencode 的 skills 目录：

```bash
cp -r openclaw-expert ~/.config/opencode/skills/
```

### 触发使用

skill 通过 SKILL.md 的 description 自动匹配触发，无需手动调用。在 opencode 对话中直接描述你的问题即可：

| 你对 opencode 说 | 触发子 skill |
|-----------------|-------------|
| "openclaw 怎么装" | ops/install.md |
| "openclaw model 怎么配 / telegram channel 怎么接入" | ops/configure.md |
| "更新 openclaw" | ops/update.md |
| "openclaw Gateway 启动失败 / 模型不回复 / 插件崩溃" | ops/fix.md |
| "卸载 openclaw" | ops/uninstall.md |

### 知识库

- **官方文档**：`references/official-docs/` 下已预置 34 篇 OpenClaw 官方文档快照（v2026.6.6）
- **运维经验**：`references/experience/active/` 下会随使用自然积累

### 手动运维命令

skill 的自动化脚本也可以直接在终端使用：

```bash
# 版本检测
./scripts/version-check.sh --detect

# 记录当前版本
./scripts/version-check.sh --record

# 更新知识库文档
./scripts/fetch-docs.sh --version <版本号>
```

### 状态文件

`~/.openclaw-expert/version-state.json` 记录 openclaw 版本信息，skill 每次激活自动检测版本变化。

## 设计文档

- [设计 Spec](docs/superpowers/specs/2026-06-13-openclaw-expert-design.md)
- [实施计划](docs/superpowers/plans/2026-06-13-openclaw-expert.md)
