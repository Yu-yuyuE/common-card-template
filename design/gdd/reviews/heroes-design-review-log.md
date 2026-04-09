# 武将系统设计审查日志

## Review — 2026-04-09 — Verdict: NEEDS REVISION → RESOLVED
Scope signal: M
Specialists: game-designer, systems-designer, qa-lead
Blocking items: 3 | Recommended: 3
Summary: 审查发现3个阻塞级冲突（司马懿事件接口缺失、行动点规则矛盾、AC5不可测试）。已通过设计决策修复：定义OnCurseCardDrawn事件payload结构，统一行动点累积规则（战斗内可累积，阶段切换重置），量化AC5验收标准。
Prior verdict resolved: First review

---

## Review — 2026-04-09 — Initial Verdict: NEEDS REVISION (Pre-Fix)

### 阻塞级问题
1. 司马懿与诅咒系统接口未定义（OnCurseCardDrawn事件payload）
2. 行动点规则冲突（D3 vs F2 vs C2）
3. AC5验收标准不可测试

### 建议修改
4. 隐忍层数"持续一回合"表述混淆
5. 张角复活在多阶段战斗中行为未定义
6. F3缺少基准权重定义
