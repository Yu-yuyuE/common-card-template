---
name: team-level
description: "Orchestrate level design team: level-designer + narrative-director + world-builder + art-director + systems-designer + qa-tester for complete area/level creation."
argument-hint: "[level name or area to design]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, new_task, ask_followup_question, TodoWrite
---

When this skill is invoked:

**Decision Points:** At each step transition, use `ask_followup_question` to present
the user with the delegate's proposals as selectable options. Write the agent's
full analysis in conversation, then capture the decision with concise labels.
The user must approve before moving to the next step.

1. **Read the argument** for the target level or area (e.g., `tutorial`,
   `forest dungeon`, `hub town`, `final boss arena`).

2. **Gather context**:
   - Read the game concept at `design/gdd/game-concept.md`
   - Read game pillars at `design/gdd/game-pillars.md`
   - Read existing level docs in `design/levels/`
   - Read relevant narrative docs in `design/narrative/`
   - Read world-building docs for the area's region/faction

## How to Delegate

Use the `new_task` tool to delegate to each team member via `new_task`:
- `role: narrative-director` — Narrative purpose, characters, emotional arc
- `role: world-builder` — Lore context, environmental storytelling, world rules
- `role: level-designer` — Spatial layout, pacing, encounters, navigation
- `role: systems-designer` — Enemy compositions, loot tables, difficulty balance
- `role: art-director` — Visual theme, color palette, lighting, asset requirements
- `role: qa-tester` — Test cases, boundary testing, playtest checklist

Always provide full context in each agent's prompt (game concept, pillars, existing level docs, narrative docs).

3. **Orchestrate the level design team** in sequence:

### Step 1: Narrative Context (narrative-director + world-builder)
Delegate to the `narrative-director` agent to:
- Define the narrative purpose of this area (what story beats happen here?)
- Identify key characters, dialogue triggers, and lore elements
- Specify emotional arc (how should the player feel entering, during, leaving?)

Delegate to the `world-builder` agent to:
- Provide lore context for the area (history, faction presence, ecology)
- Define environmental storytelling opportunities
- Specify any world rules that affect gameplay in this area

### Step 2: Layout and Encounter Design (level-designer)
Delegate to the `level-designer` agent to:
- Design the spatial layout (critical path, optional paths, secrets)
- Define pacing curve (tension peaks, rest areas, exploration zones)
- Place encounters with difficulty progression
- Design environmental puzzles or navigation challenges
- Define points of interest and landmarks for wayfinding
- Specify entry/exit points and connections to adjacent areas

### Step 3: Systems Integration (systems-designer)
Delegate to the `systems-designer` agent to:
- Specify enemy compositions and encounter formulas
- Define loot tables and reward placement
- Balance difficulty relative to expected player level/gear
- Design any area-specific mechanics or environmental hazards
- Specify resource distribution (health pickups, save points, shops)

### Step 4: Visual Direction (art-director)
Delegate to the `art-director` agent to:
- Define the visual theme and color palette for the area
- Specify lighting mood and time-of-day settings
- List required art assets (environment props, unique assets)
- Define visual landmarks and sight lines
- Specify any special VFX needs (weather, particles, fog)

### Step 5: QA Planning (qa-tester)
Delegate to the `qa-tester` agent to:
- Write test cases for the critical path
- Identify boundary and edge cases (sequence breaks, softlocks)
- Create a playtest checklist for the area
- Define acceptance criteria for level completion

4. **Compile the level design document** combining all team outputs into the
   level design template format.

5. **Save to** `design/levels/[level-name].md`.

6. **Output a summary** with: area overview, encounter count, estimated asset
   list, narrative beats, and any cross-team dependencies or open questions.
