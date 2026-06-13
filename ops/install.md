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
