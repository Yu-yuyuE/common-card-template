# Story 002: 翻译资源加载与管理

> **Epic**: 本地化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/localization-system.md`
**Requirement**: 三语言支持, 翻译资源管理
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: 本地化系统
**ADR Decision Summary**: 使用Godot 4.6.1内置Translation资源，运行时动态加载/卸载语言包，实现高效内存管理。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准ResourceLoader加载Translation资源，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 必须使用Godot原生Translation资源存储翻译内容
- Required: 必须支持运行时语言切换并自动刷新所有绑定UI
- Forbidden: 禁止在语言切换时出现UI闪烁或不一致

---

## Acceptance Criteria

*From GDD `design/gdd/localization-system.md`, scoped to this story:*

- [ ] 翻译资源使用Godot Translation资源格式
- [ ] 实现翻译缓存机制，避免重复加载
- [ ] 语言包加载失败时提供错误处理和回退机制
- [ ] 系统能够验证翻译文件完整性
- [ ] 内存使用符合F3公式（5-20MB总内存占用）

---

## Implementation Notes

*Derived from ADR-0017 Implementation Guidelines:*

1. 翻译资源管理器：
   ```gdscript
   # LocalizationManager.gd 新增
   
   # 翻译缓存
   var translation_cache: Dictionary = {}
   
   # 加载翻译资源（with caching）
   func load_translation_resource(lang_code: String) -> Translation:
       # 检查缓存
       if translation_cache.has(lang_code):
           return translation_cache[lang_code]
       
       # 加载资源
       var translation_file = language_files[lang_code]
       var resource = ResourceLoader.load(translation_file)
       
       if not resource:
           print("Error: Failed to load translation: ", translation_file)
           return null
       
       # 验证资源类型
       if not resource is Translation:
           print("Error: Invalid translation resource type")
           return null
       
       # 缓存资源
       translation_cache[lang_code] = resource
       return resource
   
   # 卸载未使用的翻译资源
   func unload_unused_translations(active_lang: String):
       for lang in supported_languages:
           if lang != active_lang and translation_cache.has(lang):
               # 保留当前语言和中文
               if lang != "zh-CN":
                   translation_cache.erase(lang)
   
   # 验证翻译文件完整性
   func validate_translation_file(lang_code: String) -> bool:
       var translation = load_translation_resource(lang_code)
       if not translation or not translation is Translation:
           return false
       
       # 检查是否有翻译条目
       var locale = translation.get_locale()
       if locale == "":
           print("Warning: Translation locale is empty")
           return false
       
       return true
   ```

2. 翻译资源组织：
   ```
   res://translations/
   ├── zh-CN.translation
   ├── en.translation
   └── ja-JP.translation
   ```

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 基础架构
- Story 003: 语言切换机制

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 翻译资源缓存
  - Given: 首次加载zh-CN翻译
  - When: 调用load_translation_resource("zh-CN")
  - Then: 翻译资源被缓存，重复调用返回相同对象
  - Edge cases: 缓存被清除

- **AC-2**: 翻译文件完整性验证
  - Given: 有效的zh-CN翻译文件
  - When: 调用validate_translation_file("zh-CN")
  - Then: 返回true
  - Edge cases: 文件损坏、错误格式

- **AC-3**: 加载失败处理
  - Given: 不存在的语言代码（"fr"）
  - When: 调用load_translation_resource("fr")
  - Then: 返回null，输出错误日志
  - Edge cases: 文件存在但格式错误

- **AC-4**: 内存管理
  - Given: 系统加载zh-CN, en, ja-JP三种语言
  - When: 当前语言=zh-CN
  - Then: 内存使用<20MB，中文翻译保留缓存
  - Edge cases: 切换到en，中文保留但ja-JP被卸载

- **AC-5**: 卸载未使用翻译
  - Given: 缓存包含zh-CN, en, ja-JP
  - When: 调用unload_unused_translations("en")
  - Then: en和zh-CN保留，ja-JP被卸载
  - Edge cases: 卸载当前语言

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/localization/translation_resource_management_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（基础架构）
- Unlocks: Story 003（语言切换）, Story 004（字体管理）
