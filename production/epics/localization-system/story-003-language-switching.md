# Story 003: 语言切换机制

> **Epic**: 本地化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/localization-system.md`
**Requirement**: 运行时切换, 200ms性能
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: 本地化系统, ADR-0016: UI数据绑定
**ADR Decision Summary**: 采用Signal驱动的响应式模式，当语言切换时，LocalizationManager广播language_changed信号，所有UI元素订阅此信号并刷新。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准Signal API，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 必须使用Signal驱动的响应式模式：数据变化→Signal广播→UI订阅更新
- Required: 必须实现运行时语言切换功能，切换时间不超过200ms
- Forbidden: 禁止在语言切换时重启游戏
- Forbidden: 禁止使用手动刷新(Polling)方式更新UI

---

## Acceptance Criteria

*From GDD `design/gdd/localization-system.md`, scoped to this story:*

- [ ] 支持在游戏过程中随时切换语言
- [ ] 切换时间不超过200ms（F2公式）
- [ ] 所有UI元素响应language_changed信号并刷新
- [ ] 语言切换时不会中断游戏逻辑或动画
- [ ] 语言设置持久化到存档系统

---

## Implementation Notes

*Derived from ADR-0017 and ADR-0016 Implementation Guidelines:*

1. 添加语言切换信号：
   ```gdscript
   # LocalizationManager.gd
   signal language_changed(old_lang: String, new_lang: String)
   
   func switch_language(lang_code: String):
       if not supported_languages.has(lang_code):
           print("Error: Unsupported language ", lang_code)
           return false
       
       var old_lang = current_language
       
       # 1. 加载新语言翻译资源
       var translation = load_translation_resource(lang_code)
       if not translation:
           print("Error: Failed to load translation for ", lang_code)
           return false
       
       # 2. 更新当前语言
       current_language = lang_code
       
       # 3. 从存档系统加载/保存语言偏好
       var save_manager = get_node("/root/SaveManager")
       save_manager.set_language_preference(lang_code)
       
       # 4. 卸载未使用的翻译资源
       unload_unused_translations(lang_code)
       
       # 5. 广播语言切换信号
       language_changed.emit(old_lang, lang_code)
       
       return true
   ```

2. UI响应语言切换：
   ```gdscript
   # HUD.gd
   func _ready():
       # 订阅语言切换信号
       LocalizationManager.language_changed.connect(_on_language_changed)
   
   func _on_language_changed(old_lang: String, new_lang: String):
       # 刷新所有绑定的UI文本
       refresh_all_text_elements()
   
   func refresh_all_text_elements():
       # 遍历所有UI元素，更新文本
       for node in get_children():
           if node.has_meta("localization_key"):
               var key = node.get_meta("localization_key")
               node.text = LocalizationManager.get_text(key)
   ```

3. 性能优化：
   - 所有文本刷新在下一帧处理（使用call_deferred）
   - 使用批量更新避免频繁重绘
   - 仅刷新可见UI元素

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 基础架构
- Story 002: 翻译资源管理
- Story 007: 语言选择UI

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 运行时语言切换
  - Given: 游戏正在运行，当前语言=zh-CN
  - When: 调用switch_language("en")
  - Then: language_changed信号被触发，当前语言=en
  - Edge cases: 在战斗中切换语言

- **AC-2**: 切换时间性能
  - Given: 1000个UI元素需要刷新
  - When: 调用switch_language("en")
  - Then: 完成时间≤200ms
  - Edge cases: 5000个UI元素

- **AC-3**: UI刷新一致性
  - Given: 所有UI元素绑定语言键
  - When: 语言切换
  - Then: 所有UI文本更新为新语言
  - Edge cases: 部分UI元素未绑定

- **AC-4**: 存档持久化
  - Given: 当前语言=en
  - When: 游戏重启
  - Then: 自动加载en语言
  - Edge cases: 存档被删除

- **AC-5**: 无中断切换
  - Given: 正在播放动画
  - When: 语言切换
  - Then: 动画继续，无中断
  - Edge cases: 网络请求正在进行

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/localization/language_switching_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（基础架构）, Story 002（翻译资源管理）
- Unlocks: Story 005（文本绑定）, Story 007（语言选择UI）
