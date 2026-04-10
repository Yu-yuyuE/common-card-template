# Story 007: 语言选择UI

> **Epic**: 本地化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: UI
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/localization-system.md`
**Requirement**: 语言选择界面, 运行时切换
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: UI数据绑定, ADR-0017: 本地化系统
**ADR Decision Summary**: 语言选择界面使用Signal驱动的响应式模式，所有文本通过语言键绑定，切换立即生效。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准UI控件和Signal API，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 必须使用Signal驱动的响应式模式：数据变化→Signal广播→UI订阅更新
- Required: 所有UI元素必须通过语言键引用文本，禁止硬编码字符串
- Required: 语言切换必须立即生效，无需重启游戏
- Forbidden: 禁止在语言切换时出现UI闪烁或不一致

---

## Acceptance Criteria

*From GDD `design/gdd/localization-system.md`, scoped to this story:*

- [ ] 提供清晰的语言选择菜单，显示支持语言的本地化名称
- [ ] 当前选择的语言高亮显示
- [ ] 支持键盘导航和游戏手柄操作
- [ ] 语言切换立即生效，无重启
- [ ] 语言偏好保存到存档系统

---

## Implementation Notes

*Derived from ADR-0016 and ADR-0017 Implementation Guidelines:*

1. UI界面设计：
   ```gdscript
   # LanguageSelectionMenu.gd
   
   # 语言选项按钮
   var language_buttons = []
   
   func _ready():
       # 加载语言选项
       for lang_code in LocalizationManager.supported_languages:
           # 使用本地化名称
           var lang_name = LocalizationManager.get_text("language." + lang_code)
           var button = Button.new()
           button.text = lang_name
           button.set_meta("language_code", lang_code)
           button.add_to_group("language_option")
           add_child(button)
           language_buttons.append(button)
       
       # 订阅语言变化
       LocalizationManager.language_changed.connect(_on_language_changed)
       
       # 初始高亮当前语言
       update_highlight()
   
   func _on_language_changed(old_lang: String, new_lang: String):
       update_highlight()
   
   func update_highlight():
       for button in language_buttons:
           var lang_code = button.get_meta("language_code")
           button.disabled = lang_code != LocalizationManager.current_language
           if lang_code == LocalizationManager.current_language:
               button.add_theme_color_override("font_color", Color.GREEN)
           else:
               button.add_theme_color_override("font_color", Color.WHITE)
   
   func _on_language_button_pressed():
       var button = get_node("./" + get_node_path().get_name())
       var lang_code = button.get_meta("language_code")
       LocalizationManager.switch_language(lang_code)
   ```

2. 翻译文件（translations/zh-CN.csv）：
   ```csv
   key,translation
   language.zh-CN,中文
   language.en,English
   language.ja-JP,日本語
   ```

3. UI交互：
   - 使用方向键导航语言按钮
   - 回车/空格选择语言
   - 支持手柄方向键和A键
   - 确保焦点状态清晰可见

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 基础架构
- Story 003: 语言切换机制
- Story 005: 文本绑定系统

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For UI stories — manual verification steps]:**

- **AC-1**: 语言选项显示
  - Setup: 进入语言选择菜单
  - Verify: 显示"中文", "English", "日本語"选项
  - Pass condition: 文本正确，无硬编码

- **AC-2**: 当前语言高亮
  - Setup: 当前语言=zh-CN
  - Verify: "中文"选项显示绿色，其他为白色
  - Pass condition: 高亮状态准确

- **AC-3**: 键盘导航
  - Setup: 使用方向键导航
  - Verify: 可在三个语言选项间移动焦点
  - Pass condition: 焦点状态清晰

- **AC-4**: 手柄操作
  - Setup: 使用手柄方向键和A键
  - Verify: 可导航和选择语言
  - Pass condition: 操作流畅

- **AC-5**: 切换立即生效
  - Setup: 选择"English"
  - Verify: 所有UI文本立即变为英文
  - Pass condition: 无延迟或重启

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/language-ui-binding-evidence.md` 或交互测试

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（基础架构）, Story 003（语言切换）, Story 005（文本绑定）
- Unlocks: 无（UI层是最终消费者）
