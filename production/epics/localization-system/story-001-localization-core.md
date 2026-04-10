# Story 001: 本地化框架基础架构

> **Epic**: 本地化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/localization-system.md`
**Requirement**: 三语言支持, 三层回退机制
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: 本地化系统
**ADR Decision Summary**: 使用Godot 4.6.1内置的本地化框架，通过Autoload实现LocalizationManager单例，支持三层翻译回退（当前语言→中文→键名）。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用Godot原生Translation资源，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 必须使用Godot 4.6.1内置的本地化框架
- Required: 必须通过Autoload方式实现LocalizationManager单例
- Required: 必须支持三层翻译回退：当前语言→中文(zh)→键名
- Forbidden: 禁止使用纯手动文本管理方式（为每种语言创建独立场景和脚本）

---

## Acceptance Criteria

*From GDD `design/gdd/localization-system.md`, scoped to this story:*

- [ ] 支持中文、英文、日文三种语言的翻译文件
- [ ] 翻译系统采用三层回退机制：当前语言→中文→键名
- [ ] 系统在缺少翻译时显示键名而非空白
- [ ] LocalizationManager作为Autoload节点加载
- [ ] 系统在启动时加载语言包并初始化

---

## Implementation Notes

*Derived from ADR-0017 Implementation Guidelines:*

1. 创建 `LocalizationManager.gd` 脚本并作为Autoload节点注册：
   ```gdscript
   extends Node
   
   # 翻译系统
   var translation_server: TranslationServer
   
   # 支持的语言列表
   var supported_languages = ["zh-CN", "en", "ja-JP"]
   
   # 当前语言
   var current_language = "zh-CN"
   
   # 语言到文件路径映射
   var language_files = {
       "zh-CN": "res://translations/zh-CN.csv",
       "en": "res://translations/en.csv",
       "ja-JP": "res://translations/ja-JP.csv"
   }
   
   func _ready():
       translation_server = TranslationServer
       load_language(current_language)
   
   func load_language(lang_code: String):
       if not supported_languages.has(lang_code):
           print("Error: Unsupported language ", lang_code)
           return
       
       current_language = lang_code
       
       # 加载翻译文件
       var translation_resource = load(language_files[lang_code])
       if translation_resource:
           translation_server.add_translation(translation_resource)
       else:
           print("Warning: Translation file not found: ", language_files[lang_code])
   
   func get_text(key: String) -> String:
       # 三层回退机制
       var result = translation_server.translate(key, current_language)
       if result == key:  # 未找到当前语言翻译
           result = translation_server.translate(key, "zh-CN")
           if result == key:  # 未找到中文翻译
               result = "[MISSING: " + key + "]"
       return result
   ```

2. 创建三个CSV翻译文件：
   - `translations/zh-CN.csv`
   - `translations/en.csv`
   - `translations/ja-JP.csv`

3. 翻译文件格式（CSV）：
   ```csv
   key,translation
   ui.button.start,开始游戏
   ui.button.start,Start
   ui.button.start,スタート
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 翻译资源加载与缓存优化
- Story 003: 语言切换机制
- Story 007: 语言选择UI

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 三层回退机制
  - Given: 当前语言=zh-CN, 键="ui.button.start"，存在中文翻译
  - When: 调用get_text("ui.button.start")
  - Then: 返回"开始游戏"
  - Edge cases: 键不存在于任何语言

- **AC-2**: 缺失翻译回退
  - Given: 当前语言=en, 键="ui.button.start"，存在中文但不存在英文
  - When: 调用get_text("ui.button.start")
  - Then: 返回"开始游戏"（中文回退）
  - Edge cases: 中文也不存在

- **AC-3**: 键名回退
  - Given: 当前语言=en, 键="unknown.key"，不存在任何语言翻译
  - When: 调用get_text("unknown.key")
  - Then: 返回"[MISSING: unknown.key]"
  - Edge cases: 键名包含特殊字符

- **AC-4**: Autoload加载
  - Given: 游戏启动
  - When: LocalizationManager节点存在
  - Then: 语言文件被加载，current_language=zh-CN
  - Edge cases: 语言文件缺失

- **AC-5**: 支持语言
  - Given: supported_languages列表
  - When: 仅包含zh-CN, en, ja-JP
  - Then: 其他语言代码拒绝加载
  - Edge cases: 语言代码格式错误

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/localization/localization_core_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 无（基础层）
- Unlocks: Story 002（资源加载）, Story 003（语言切换）, Story 005（文本绑定）
