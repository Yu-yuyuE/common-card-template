# Story 006: 参数化文本替换

> **Epic**: 本地化系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-09

## Context

**GDD**: `design/gdd/localization-system.md`
**Requirement**: 参数化文本替换（如"{0}"、"${name}"）
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0017: 本地化系统
**ADR Decision Summary**: 必须支持参数化文本替换，确保不同语言的语法结构正确。

**Engine**: Godot 4.6.1 | **Risk**: LOW
**Engine Notes**: 标准字符串操作，无特殊API风险。

**Control Manifest Rules (this layer)**:
- Required: 必须支持参数化文本替换（如"{0}"、"${name}"）
- Required: 支持多参数替换
- Forbidden: 禁止简单字符串格式化不支持顺序或named参数

---

## Acceptance Criteria

*From GDD `design/gdd/localization-system.md`, scoped to this story:*

- [ ] 支持位置参数替换（如"{0}"代表第一个参数）
- [ ] 支持命名参数替换（如"{general_name}"）
- [ ] 支持多参数同时替换
- [ ] 参数缺失时显示占位符或错误信息（不崩溃）
- [ ] 参数值为null时使用默认占位符

---

## Implementation Notes

*Derived from ADR-0017 Implementation Guidelines:*

1. 参数化替换实现：
   ```gdscript
   # LocalizationManager.gd
   
   func get_text_with_params(key: String, params: Dictionary = {}) -> String:
       var base_text = get_text(key)
       
       # 检查是否是占位符缺失
       if base_text.begins_with("[MISSING:"):
           return base_text  # 不处理参数
       
       if params.is_empty():
           return base_text
       
       # 先替换命名参数
       for param_name in params.keys():
           var placeholder = "{" + param_name + "}"
           base_text = base_text.replace(placeholder, str(params[param_name]))
       
       # 再替换位置参数 {0}, {1}, {2}...
       # 按数字顺序替换
       var index = 0
       while true:
           var positional_placeholder = "{" + str(index) + "}"
           if base_text.find(positional_placeholder) == -1:
               break
           # 使用命名参数或默认占位符
           var default_name = "param" + str(index)
           var replacement = str(params.get(default_name, "[?unknown?]"))
           base_text = base_text.replace(positional_placeholder, replacement)
           index += 1
       
       return base_text
   
   # 使用示例：
   # {"name": "张飞", "skill": "怒吼"} → "张飞 激活了 怒吼"
   # {"0": "张飞", "1": "怒吼"} → "张飞 激活了 怒吼"
   ```

2. CSV翻译文件支持占位符：
   - 键：`event.battle_victory`
   - 中文：`{general_name} 在 {location} 取得了战役胜利！`
   - 英文：`{general_name} achieved victory at {location}!`
   - 日文：`{general_name}は{location}で勝利を収めた！`

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 基础架构
- Story 005: 文本绑定系统（调用此API）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Logic stories — automated test specs]:**

- **AC-1**: 命名参数替换
  - Given: 键="event.victory", 参数={"general_name": "张飞", "location": "长坂坡"}
  - When: 调用get_text_with_params()
  - Then: 返回"张飞 在 长坂坡 取得了战役胜利！"
  - Edge cases: 参数顺序不同

- **AC-2**: 位置参数替换
  - Given: 键="event.victory", 参数={"0": "张飞", "1": "长坂坡"}
  - When: 调用get_text_with_params()
  - Then: 返回"张飞 在 长坂坡 取得了战役胜利！"
  - Edge cases: 位置索引不连续

- **AC-3**: 混合参数
  - Given: 键="event.victory", 参数={"general_name": "张飞", "0": "长坂坡"}
  - When: 调用get_text_with_params()
  - Then: 正确替换所有占位符
  - Edge cases: 命名和位置同时存在

- **AC-4**: 参数缺失占位符
  - Given: 键="event.victory", 参数={"general_name": "张飞"}（缺少location）
  - When: 调用get_text_with_params()
  - Then: location占位符显示"[?unknown?]"
  - Edge cases: 所有参数缺失

- **AC-5**: 参数值为null
  - Given: 参数={"general_name": null, "location": "长坂坡"}
  - When: 调用get_text_with_params()
  - Then: general_name显示"null"（或默认占位符）
  - Edge cases: 参数值为空字符串

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/localization/parameterized_text_replacement_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001（基础架构）, Story 005（文本绑定）
- Unlocks: 无
