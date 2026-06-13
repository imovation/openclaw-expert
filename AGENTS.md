## Project: openclaw-expert

这是基于 opencode skill 机制的 OpenClaw 运维专家技能项目。

### 项目约定

- skill 文件使用 Markdown + YAML frontmatter 格式
- 所有运维子 skill 放在 `ops/` 目录，遵循渐进式披露原则
- 知识库按进化维度（official-docs / experience）和主题维度（10 个主题）双维度组织
- 脚本使用 bash，放在 `scripts/`，通过 Bash 工具执行而非加载入 context
- 技能触发描述放在 SKILL.md 的 frontmatter description 字段
- 遵循 skill-creator 规范：不超过 500 行，三层渐进式披露

### 常用命令

```bash
# 检测 openclaw 版本变化
./scripts/version-check.sh --detect

# 记录当前版本
./scripts/version-check.sh --record

# 拉取官方文档
./scripts/fetch-docs.sh --version <版本号>

# BUG 回归验证
./scripts/bug-regression.sh --id <exp-id>

# 知识库去重检查
./scripts/knowledge-manager.sh check-dedup --topic <topic> --title <title> --content <file>

# 添加经验
./scripts/knowledge-manager.sh add-experience --topic <topic> --title <title> --content <file> --type <bug|experience>

# 归档经验
./scripts/knowledge-manager.sh archive-experience --id <exp-id> --fixed-in <version>

# 验证 JSON 索引
python3 -c "import json; json.load(open('references/official-docs/index.json')); print('OK')"
python3 -c "import json; json.load(open('references/experience/index.json')); print('OK')"
```
