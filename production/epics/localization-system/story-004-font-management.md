# Story 004: 字体管理系统

> **Epic**: 本地化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/localization-system.md`
**Requirement**: 三语言字体资源, 字体缩放因子
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: 本地化系统
**ADR Decision Summary**: 根据当前语言自动选择字体资源，支持基于语言的字体大小缩放因子，确保视觉一致性。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准ResourceLoader加载字体资源，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 必须为每种语言配置独立字体资源
- Required: 必须支持基于语言的字体大小缩放因子
- Required: 必须在字体加载失败时提供回退机制
- Forbidden: 禁止使用纯手动文本管理方式

---

## Acceptance Criteria

*From GDD `design/gdd/localization-system.md`, scoped to this story:*

- [ ] 中文使用思源黑体，英文使用Roboto，日文使用Noto Sans CJK JP
- [ ] 支持基于语言的字体大小缩放因子（0.9–1.1）
- [ ] 字体加载失败时回退到Noto Sans默认字体
- [ ] 字体加载在游戏启动时预加载，避免运行时延迟
- [ ] 字体加载时间符合F4公式（100-1000ms）

---

## Implementation Notes

*Derived from ADR-0017 Implementation Guidelines:*

1. 字体配置：
   ```gdscript
   # LocalizationManager.gd
   var font_config = {
       "zh-CN": {
           "font_path": "res://fonts/SourceHanSansSC-Regular.otf",
           "scale_factor": 1.0,
           "fallback": "res://fonts/NotoSans-Regular.ttf"
       },
       "en": {
           "font_path": "res://fonts/Roboto-Regular.ttf",
           "scale_factor": 1.0,
           "fallback": "res://fonts/NotoSans-Regular.ttf"
       },
       "ja-JP": {
           "font_path": "res://fonts/NotoSansCJKjp-Regular.otf",
           "scale_factor": 1.0,
           "fallback": "res://fonts/NotoSans-Regular.ttf"
       }
   }
   
   # 字体缓存
   var font_cache: Dictionary = {}
   
   func load_font_for_language(lang_code: String) -> Font:
       if not font_config.has(lang_code):
           print("Error: No font config for ", lang_code)
           return null
       
       # 检查缓存
       if font_cache.has(lang_code):
           return font_cache[lang_code]
       
       var config = font_config[lang_code]
       var font = load(config["font_path"])
       
       if not font or not font is Font:
           print("Warning: Failed to load font ", config["font_path"], ", using fallback")
           font = load(config["fallback"])
           if not font or not font is Font:
               print("Error: Failed to load fallback font")
               return null
       
       # 应用缩放因子
       font.get_data().size *= config["scale_factor"]
       
       # 缓存字体
       font_cache[lang_code] = font
       return font
   ```

2. 字体预加载：
   ```gdscript
   func _ready():
       # 预加载所有字体
       for lang in supported_languages:
           load_font_for_language(lang)
       
       # 加载当前语言字体
       load_font_for_language(current_language)
   ```

3. 字体应用到UI：
   ```gdscript
   # 在UI系统中
   func apply_language_font_to_node(node: Node, lang_code: String):
       var font = LocalizationManager.load_font_for_language(lang_code)
       if font:
           node.font = font
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 基础架构
- Story 003: 语言切换机制
- Story 007: 语言选择UI

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 中文字体加载
  - Given: 当前语言=zh-CN
  - When: 调用load_font_for_language("zh-CN")
  - Then: 加载SourceHanSansSC-Regular.otf
  - Edge cases: 字体文件缺失

- **AC-2**: 英文字体加载
  - Given: 当前语言=en
  - When: 调用load_font_for_language("en")
  - Then: 加载Roboto-Regular.ttf
  - Edge cases: 字体文件缺失

- **AC-3**: 日文字体加载
  - Given: 当前语言=ja-JP
  - When: 调用load_font_for_language("ja-JP")
  - Then: 加载NotoSansCJKjp-Regular.otf
  - Edge cases: 字体文件缺失

- **AC-4**: 字体缩放因子
  - Given: 中文字体缩放因子=1.0
  - When: 加载中文字体
  - Then: 字体大小=1.0 * 原始大小
  - Edge cases: 缩放因子=1.1

- **AC-5**: 字体回退机制
  - Given: 主字体文件缺失
  - When: 调用load_font_for_language("zh-CN")
  - Then: 加载NotoSans-Regular.ttf作为回退
  - Edge cases: 回退字体也缺失

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/localization/font_management_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（基础架构）
- Unlocks: Story 005（文本绑定）, Story 007（语言选择UI）
