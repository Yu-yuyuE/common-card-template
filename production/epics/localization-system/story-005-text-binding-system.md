# Story 005: 文本绑定系统

> **Epic**: 本地化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/localization-system.md`
**Requirement**: 禁止硬编码字符串, UI文本绑定
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0016: UI数据绑定, ADR-0017: 本地化系统
**ADR Decision Summary**: 所有UI文本通过语言键引用，禁止硬编码字符串；UI系统必须监听language_changed信号并刷新绑定的文本。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 使用标准Signal API和ResourceLoader，无post-cutoff API风险。

**Control Manifest Rules (this layer)**:
- Required: 必须使用Signal驱动的响应式模式：数据变化→Signal广播→UI订阅更新
- Required: 所有UI元素需要遵循ADR-0016的数据绑定模式
- Required: 所有UI元素必须通过语言键引用文本，禁止硬编码字符串
- Forbidden: 禁止在代码中使用硬编码字符串
- Forbidden: 禁止使用手动刷新(Polling)方式更新UI

---

## Acceptance Criteria

*From GDD `design/gdd/localization-system.md`, scoped to this story:*

- [ ] 所有UI文本通过语言键引用，禁止硬编码字符串
- [ ] UI元素通过meta属性绑定语言键
- [ ] UI系统监听language_changed信号并刷新绑定的文本
- [ ] 所有卡牌、事件、系统消息使用语言键
- [ ] 支持参数化文本替换（如"{name}使用了{skill}"）

---

## Implementation Notes

*Derived from ADR-0016 and ADR-0017 Implementation Guidelines:*

1. 文本绑定系统：
   ```gdscript
   # UI系统中
   
   # UI元素绑定语言键（通过meta属性）
   func bind_text_to_key(node: Node, key: String):
       node.set_meta("localization_key", key)
       
       # 立即设置初始文本
       node.text = LocalizationManager.get_text(key)
   
   # 在语言切换时刷新所有绑定文本
   func refresh_all_bound_text():
       var ui_nodes = get_tree().get_nodes_in_group("localization_text")
       for node in ui_nodes:
           if node.has_meta("localization_key"):
               var key = node.get_meta("localization_key")
               node.text = LocalizationManager.get_text(key)
   
   # 在LanguageManager中
   signal language_changed(old_lang: String, new_lang: String)
   
   # 在UI系统中
   func _ready():
       LocalizationManager.language_changed.connect(refresh_all_bound_text)
       
       # 注册所有绑定文本的UI元素到组
       for node in get_children():
           if node.has_meta("localization_key"):
               node.add_to_group("localization_text")
   ```

2. 参数化文本替换：
   ```gdscript
   # LocalizationManager.gd
   func get_text_with_params(key: String, params: Dictionary) -> String:
       var base_text = get_text(key)
       
       # 替换参数
       for param_key in params.keys():
           var placeholder = "{" + param_key + "}"
           if base_text.find(placeholder) != -1:
               base_text = base_text.replace(placeholder, str(params[param_key]))
       
       return base_text
   
   # 使用示例：
   # LocalizationManager.get_text_with_params("card.swordmaster.desc", {"name": "张飞", "skill": "怒吼"})
   # 返回："张飞 激活了 怒吼"
   ```

3. 代码规范：
   - 所有UI文本必须使用语言键，禁止直接字符串
   - 卡牌描述、事件文本等都必须使用语言键
   - 任何新UI元素必须绑定语言键

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

- **AC-1**: 禁止硬编码字符串
  - Given: UI元素
  - When: 查找代码中的硬编码字符串
  - Then: 无硬编码字符串，所有文本都通过语言键获取
  - Edge cases: 文本在脚本中直接写入

- **AC-2**: UI绑定语言键
  - Given: 按钮节点
  - When: 绑定语言键 "ui.button.start"
  - Then: 按钮显示"开始游戏"（中文）
  - Edge cases: 绑定无效键

- **AC-3**: 参数化文本替换
  - Given: 键="card.swordmaster.desc", 参数={"name": "张飞", "skill": "怒吼"}
  - When: 调用get_text_with_params()
  - Then: 返回"张飞 激活了 怒吼"
  - Edge cases: 参数缺失

- **AC-4**: UI刷新
  - Given: UI元素绑定语言键，当前语言=zh-CN
  - When: 切换语言到en
  - Then: UI文本更新为英文
  - Edge cases: 部分UI未绑定

- **AC-5**: 参数化文本回退
  - Given: 键="card.swordmaster.desc"，无中文翻译
  - When: 调用get_text_with_params()
  - Then: 返回"[MISSING: card.swordmaster.desc]"（不应用参数）
  - Edge cases: 参数值为null

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/localization/text_binding_system_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（基础架构）, Story 003（语言切换）
- Unlocks: Story 007（语言选择UI）
