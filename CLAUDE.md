# Claude Code Game Studios -- Game Studio Agent Architecture

> **Compatibility**: This project works with **Claude Code** AND **OpenCode**.
>
> - Skills: `.claude/skills/` + `.opencode/skills/` (both supported)
> - Agents: `.claude/agents/` + `.opencode/agents/` (both supported)

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## OpenCode Usage

To use with OpenCode, run:

```
opencode
```

Skills and agents are automatically loaded from both `.claude/` and `.opencode/` directories.

See https://opencode.ai/docs/skills/ and https://opencode.ai/docs/agents/ for documentation.

## Technology Stack

- **Engine**: Godot 4.6.1
- **Language**: GDScript (primary), C# (utilities)
- **Version Control**: Git with trunk-based development
- **Build System**: Godot Export Templates, .NET SDK
- **Asset Pipeline**: Godot Import System

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md

## Design Data Consistency Rules

三国称雄项目的武将数据分布在三个文件中，**任何修改必须同步**：

### 武将数据三源文件

| 文件                                       | 内容                                                   | 格式               |
| ------------------------------------------ | ------------------------------------------------------ | ------------------ |
| `design/gdd/heroes-design.md`              | 武将完整设计（被动/基础值/地图主题）                   | Markdown（叙述性） |
| `design/detail/heroes_passive_skills.csv`  | 被动技能结构化数据（引擎实现参考）                     | CSV                |
| `design/detail/heroes_exclusive_decks.csv` | 专属卡组结构化数据（含Lv2升级/离场机制，引擎实现参考） | CSV                |

### 修改任一文件时的必检清单

修改 `heroes-design.md` 时：

- [ ] 同步更新 `heroes_passive_skills.csv` 对应武将行
- [ ] 若卡组数量/卡名/效果有变，同步更新 `heroes_exclusive_decks.csv`

修改 `heroes_exclusive_decks.csv` 时：

- [ ] 若被动触发机制有变，同步更新 `heroes-design.md` 和 `heroes_passive_skills.csv`
- [ ] 若卡组数量变化，同步更新 `heroes-design.md` 中对应武将的专属卡数量字段

修改 CSV 文件时：

- [ ] CSV 是引擎实现的数据源，改动必须反映 GDD 中已批准的设计
- [ ] 不得在 CSV 中自行发明新机制，所有新机制须先写入 GDD

### 卡牌术语标准（全项目统一）

| 术语         | 定义                                                                             | 错误用法示例                                     |
| ------------ | -------------------------------------------------------------------------------- | ------------------------------------------------ |
| **丢弃**     | 将卡牌加入弃牌堆（仍在本局循环中）                                               | ~~移除~~、~~丢掉~~                               |
| **移除**     | 本场战斗移出循环（战斗结束后回卡组）                                             | ~~使用后消失~~、~~临时删除~~                     |
| **移出卡组** | 在商店整理后从卡组永久移走（整张地图有效，进入下一张地图后如未再次整理则仍移出） | ~~净化~~（净化是操作，移出卡组是结果）、~~删除~~ |

> 在所有设计文档、CSV、代码注释中必须严格使用以上术语，避免混用。

### 卡组数量上限（强制）

- 司马懿：≤15张（含2张初始韬晦负面卡，功能卡≤13张）
- 其他所有武将：≤12张（基础攻击卡 + 特色卡合计）

### 负面卡三种类型（设计基准）

| 类型       | 触发时机                           | 消除方式                       |
| ---------- | ---------------------------------- | ------------------------------ |
| 抽到触发型 | 抽入手牌时立即触发，触发后正常丢弃 | 自动丢弃                       |
| 常驻牌库型 | 在牌库中持续生效                   | 仅移出卡组才消除（丢弃不消除） |
| 常驻手牌型 | 抽入手牌后占位，需支付费用才能丢弃 | 付费丢弃                       |
