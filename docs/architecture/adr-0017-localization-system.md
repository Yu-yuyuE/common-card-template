# ADR-0017: 本地化系统架构

## Status

Accepted

## Date

2026-04-09

## Last Verified

2026-04-09

## Decision Makers

用户 + 技术代理团队

## Summary

本地化系统需要支持中文、英文、日文三种语言，实现运行时语言切换、文本-逻辑分离和跨UI一致的多语言体验。决定采用Godot 4.6.1内置的本地化框架，结合CSV翻译文件和自定义资源管理，实现统一的多语言支持方案。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6.1 |
| **Domain** | Infrastructure / Localization |
| **Knowledge Risk** | LOW — Godot 4.x Localization API 在训练数据范围 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, Godot Localization docs |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (场景管理策略), ADR-0002 (系统通信模式), ADR-0003 (资源通知机制), ADR-0005 (存档序列化), ADR-0016 (UI数据绑定) |
| **Enables** | 多语言游戏内容、国际化发布 |
| **Blocks** | 所有依赖多语言文本的系统（卡牌、地图、事件、UI） |
| **Ordering Note** | 本ADR依赖Signal通信模式ADR-0002和UI数据绑定ADR-0016 |

## Context

### Problem Statement

游戏需要支持三种语言（中文、英文、日文），确保在不同语言环境下玩家都能获得完整的策略体验。需要解决：
- 如何分离代码与静态文本，避免硬编码字符串
- 如何实现运行时语言切换而不重启游戏
- 如何处理不同语言的字体、布局和文本长度差异
- 如何确保所有UI、卡牌、地图文本一致更新

### Current State

目前有部分UI元素包含硬编码文本，缺乏系统化的多语言支持能力。需要从基础设施层统一管理所有游戏文本资源。

### Constraints

- **技术栈**: 必须使用Godot 4.6.1内置本地化功能
- **性能**: 语言切换需在200ms内完成，不影响游戏流畅度
- **内存**: 多语言包总内存占用不超过50MB
- **UI**: 必须遵循已定义的UI数据绑定模式ADR-0016
- **本地化质量**: 所有文本必须支持参数化替换，适应不同语言语法

### Requirements

- **文本分离**: 所有显示文本必须通过键值引用，禁止硬编码
- **运行时切换**: 支持游戏过程中即时切换语言
- **回退机制**: 缺失翻译时自动回退到主语言（中文）
- **字体适配**: 不同语言使用优化字体，支持自动布局调整
- **系统集成**: 与存档、UI、卡牌、地图系统深度集成

## Decision

采用**Godot原生本地化框架 + 自定义资源管理器**的混合方案：

### 核心架构

```
┌─────────────────────────────────────────────────────────────┐
│                    本地化系统架构                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  LocalizationManager (Autoload 单例)               │   │
│  │  ├── current_language: String                      │   │
│  │  ├── translation_packs: Dictionary                 │   │
│  │  ├── font_cache: Dictionary                        │   │
│  │  │                                                 │   │
│  │  ├── set_language(lang)                           │   │
│  │  ├── get_text(key, params...)                    │   │
│  │  ├── get_localized_font(lang)                    │   │
│  │  └── language_changed 信号                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │ 信号广播                        │
│                            ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  UI System (遵循 ADR-0016 数据绑定模式)            │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │ UIBinder 自动绑定: language_changed → 刷新   │   │   │
│  │  │ - Label.text = Localization.get(key)        │   │   │
│  │  │ - Button.text = Localization.get(key)       │   │   │
│  │  │ - Tooltip 更新                              │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ↓ 文本查询                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  翻译文件资源 (resources/translations/)            │   │
│  │  ├── localization_zh.tres (主语言-中文)            │   │
│  │  ├── localization_en.tres (英文)                   │   │
│  │  └── localization_ja.tres (日文)                   │   │
│  │                                                     │   │
│  │  格式: Translation(entries: Dictionary)           │   │
│  │  {"ui.button.start": "开始游戏"}                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  字体资源系统 (resources/fonts/)                   │   │
│  │  ├── font_source_han_sans_zh.tres (中文)          │   │
│  │  ├── font_roboto_en.tres (英文)                   │   │
│  │  └── font_noto_sans_ja.tres (日文)                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  其他系统集成                                        │   │
│  │  ├── 存档系统: 保存/恢复 current_language         │   │
│  │  ├── 卡牌系统: 卡牌名称/描述从语言键获取           │   │
│  │  ├── 地图系统: 事件文本通过语言键引用              │   │
│  │  └── 音频系统: 语音文件按语言组织播放              │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 核心接口定义

```gdscript
# localization_manager.gd
class_name LocalizationManager extends Node

# 信号定义
signal language_changed(new_lang: String)
signal translation_missing(key: String, lang: String)

# 公共方法
func initialize() -> void
func set_language(lang_code: String) -> bool
func get_text(key: String, params: Array = []) -> String
func get_available_languages() -> Array[Dictionary]
func get_current_language() -> String
func get_font_for_language(lang_code: String = "") -> Font

# 内部方法
func _load_translation_pack(lang: String) -> Translation
func _get_fallback_text(key: String) -> String
func _notify_language_change()
func _handle_missing_translation(key: String, lang: String)
```

### 翻译文件结构

```gdscript
# resources/translations/localization_zh.tres
[resource]
resource_name = "Chinese Translations"
content = {
    "ui.main.title": "三国战略",
    "ui.button.start": "开始游戏",
    "ui.button.settings": "设置",
    "card.swordmaster.name": "剑豪",
    "card.swordmaster.desc": "对单个敌人造成{damage}点伤害"
}
```

### 字体资源配置

每种语言使用独立的字体资源，按语言代码动态加载：

```gdscript
# 字体映射配置
const FONT_MAPPING = {
    "zh": "res://resources/fonts/font_source_han_sans_zh.tres",
    "en": "res://resources/fonts/font_roboto_en.tres",
    "ja": "res://resources/fonts/font_noto_sans_ja.tres"
}
```

### UI绑定模式

所有UI元素遵循ADR-0016的绑定模式：

```gdscript
# localization_bound_label.gd
class_name LocalizationBoundLabel extends Label

@export var localization_key: String = ""
@export var param_replacements: Dictionary = {}

func _ready():
    LocalizationManager.language_changed.connect(_refresh_text)
    _refresh_text()

func _refresh_text():
    text = LocalizationManager.get_text(localization_key, param_replacements.values())
```

### 实现关键点

1. **语言切换原子性**: `set_language()` 包括加载翻译包、更新字体、广播信号的完整流程，确保UI一次性全部刷新

2. **参数化替换支持**: `get_text(key, params)` 支持 `{0}`, `{1}` 或 `{name}` 形式的占位符替换，每语言可定制顺序以适应语法

3. **缓存策略**:
   - 已加载翻译包在内存缓存
   - Font资源按语言预加载到字体缓存
   - 频繁访问的文本结果可短期缓存（可选）

4. **缺失处理**: 三层回退：当前语言 → 中文 → 键名显示

5. **性能保证**: 语言切换总时间 ≤ 200ms，通过预加载和增量更新实现

## Alternatives Considered

### Alternative 1: 第三方本地化插件

- **描述**: 使用Godot Asset Library中的第三方本地化插件（如Godot-Localize）
- **优点**: 功能更丰富，社区支持
- **缺点**:
  - 增加外部依赖，可能无人维护
  - 与项目架构模式可能存在冲突
  - 未经Godot 4.6.1验证
- **拒绝理由**: 自研方案更可控、更轻量、与ADR模式完美契合

### Alternative 2: CSV + 自定义解析器

- **描述**: 使用标准CSV文件加自定义解析代码
- **优点**: 简单直观，翻译人员友好
- **缺点**:
  - 需要手动加载和解析，效率较低
  - 缺少Godot原生Translation的资源优化
  - 需要自己管理缓存和更新
- **拒绝理由**: Godot Translation资源提供更好的引擎集成和性能

### Alternative 3: 纯手动文本管理

- **描述**: 为每种语言创建独立的场景和脚本
- **优点**: 无框架约束
- **缺点**:
  - 维护噩梦，内容爆炸
  - 完全违反DRY原则
  - 切换语言需要场景切换
- **拒绝理由**: 不可扩展，不符合软件工程最佳实践

## Consequences

### Positive

- **引擎原生**: 完全基于Godot 4.6.1本地化API，无第三方依赖
- **性能**: 翻译包以.tres资源格式存储，引擎优化加载
- **可维护性**: 单一系统管理所有文本，易于扩展新语言
- **开发体验**: 程序员引用语言键，翻译人员编辑CSV，职责清晰分离
- **UI集成**: 结合ADR-0016自动绑定，文本更新自动传播
- **测试友好**: 易于编写单元测试验证翻译覆盖率和回退逻辑

### Negative

- **Godot API限制**: Translation类功能相对基础，复杂格式化需自行实现
- **字体管理开销**: 每种语言独立字体增加资源打包复杂度
- **团队学习成本**: 需要遵守语言键命名规范，初期可能混乱

### Neutral

- 翻译文件从CSV转换为.tres需要构建时转换脚本（或直接编辑.tres）
- 参数化替换语法采用简单{0}/{1}而非高级功能

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 大型卡牌组导致翻译包内存过大 | Medium | Medium | 分批加载、缓存策略优化 |
| 参数化替换语法在各语言中顺序冲突 | Low | Medium | 为每个键提供语言特定的参数映射 |
| 字体文件过大影响打包大小 | Low | Low | 字体子集化，仅包含游戏所需字符 |
| 翻译遗漏导致“键名显示” | Medium | Low | 建立翻译覆盖率检查工具 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|----------------|--------|
| CPU (切换语言) | 0ms | 50-150ms | 200ms |
| 内存占用（3语言） | 0MB | 10-25MB | 50MB |
| 单次文本查询延迟 | 0ms | < 0.1ms | 1ms |
| 冷启动加载时间 | 0ms | 100-300ms | 500ms |

## Migration Plan

从零实现本地化系统（无现有系统需要迁移）：

1. **Phase 1**: 创建LocalizationManager单例和Translation资源
2. **Phase 2**: 实现翻译文件资源和基础字体管理系统
3. **Phase 3**: 集成到UI数据绑定系统（ADR-0016）
4. **Phase 4**: 改造现有UI元素使用语言键
5. **Phase 5**: 集成存档系统保存语言偏好
6. **Phase 6**: 编写翻译覆盖率检查工具

**验证计划**:
- 单元测试覆盖所有核心功能
- 手动切换语言测试UI刷新
- 验证缺失翻译回退行为
- 性能测试测量切换延迟和内存占用

## GDD Requirements Addressed

| GDD Document | Requirement | How This ADR Satisfies It |
|--------------|-------------|--------------------------|
| `design/gdd/localization-system.md` | 文本-逻辑分离 | 所有UI通过语言键绑定，代码中无硬编码字符串 |
| `design/gdd/localization-system.md` | 运行时语言切换 | LocalizationManager.set_language()实现无重启切换 |
| `design/gdd/localization-system.md` | 语言优先级回退 | 三层回退：当前语言→zh→键名 |
| `design/gdd/localization-system.md` | 字体自动适配 | get_font_for_language()按语言返回优化字体 |
| `design/gdd/localization-system.md` | UI数据绑定传播 | 结合ADR-0016，language_changed信号自动刷新所有绑定UI |
| `design/gdd/localization-system.md` | 性能要求 | 设计实现<200ms切换、<50MB内存占用 |

## Related

- **ADR-0001**: 场景管理策略 — 影响场景切换时的语言状态保留
- **ADR-0002**: 系统间通信模式 — 提供Signal通信基础
- **ADR-0003**: 资源通知机制 — 翻译包加载和通知模式
- **ADR-0005**: 存档序列化 — 语言偏好持久化
- **ADR-0016**: UI数据绑定 — 核心集成模式，文本自动刷新机制
- `design/gdd/localization-system.md` — 本地化系统GDD，详细设计规范
