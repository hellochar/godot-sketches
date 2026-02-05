# PsycheBuilder Execution Plan
**Date:** February 5, 2026
**Based on:** emergent-game-design analysis

---

## Overview

This plan addresses the critical issues identified in the emergent game design analysis. Tasks are ordered by priority and dependency.

---

## Phase 1: Fix Critical Balance Issues (P0)

### Task 1.1: Fix Negative Generator Stacking
**File:** `src/data/adjacency_rules.gd`
**Change:** Modify generator_stacking dict to use diminishing returns for negative generators

```gdscript
# BEFORE
static var generator_stacking: Dictionary = {
  "memory_well": 0.85,
  "comfort_hearth": 0.9,
  "worry_loop": 1.1,      # COMPOUNDS
  "wound": 1.05,          # COMPOUNDS
  "rumination_spiral": 1.15,  # COMPOUNDS
  "inner_critic": 1.1     # COMPOUNDS
}

# AFTER
static var generator_stacking: Dictionary = {
  "memory_well": 0.85,
  "comfort_hearth": 0.9,
  "worry_loop": 0.9,      # Diminishes like positive
  "wound": 0.9,           # Diminishes like positive
  "rumination_spiral": 0.85,  # Diminishes like positive
  "inner_critic": 0.9     # Diminishes like positive
}
```

**Rationale:** Prevents runaway negative spirals from stacked negative generators.

---

### Task 1.2: Add Uniqueness Flag to Global Effect Buildings
**File:** `src/data/building_definitions.gd`
**Change:** Add `"unique": true` to all GLOBAL_EFFECT buildings

Buildings to modify:
- optimism_lens
- stoic_foundation
- creative_core
- compassion_center
- acceptance_shrine
- attention_amplifier

**Rationale:** Prevents stacking global multipliers without limit.

---

### Task 1.3: Implement Uniqueness Check in Building System
**File:** `src/systems/building_system.gd`
**Change:** Add check in placement logic to prevent placing unique buildings that already exist

```gdscript
func can_place_building(building_id: String, coord: Vector2i) -> Dictionary:
  var def = BuildingDefinitions.get_definition(building_id)

  # Check uniqueness
  if def.get("unique", false):
    for building in GameState.active_buildings:
      if building.building_id == building_id:
        return {"success": false, "reason": "Only one " + def.name + " allowed"}

  # ... rest of existing checks
```

---

## Phase 2: Improve Complexity Gating (P1)

### Task 2.1: Restructure FTUE Unlock Days
**File:** `src/data/building_definitions.gd`
**Change:** Modify ftue_unlock_day values to delay complex buildings

| Building | Current Day | New Day | Reason |
|----------|-------------|---------|--------|
| mourning_chapel | 1 | 3 | L2 too early |
| memory_processor | 5 | 7 | L3 conditional output |
| grounding_station | 5 | 7 | L2 multi-input |
| morning_routine | 3 | 2 | L1 habit intro |
| exercise_yard | 5 | 3 | L1 habit |
| meditation_garden | 5 | 5 | Keep |
| journaling_corner | 5 | 5 | Keep |
| anger_forge | 7 | 9 | L2 processor |
| wound | 7 | 5 | Negative intro |
| worry_loop | 7 | 5 | Negative intro |
| rumination_spiral | 7 | 7 | Keep |
| inner_critic | 7 | 9 | Complex negative |

---

### Task 2.2: Add Conditions to Global Effect Buildings
**File:** `src/data/building_definitions.gd`
**Change:** Add activation_condition and/or downside to globals

```gdscript
"optimism_lens": {
  ...
  "global_effect": {
    "positive_generation_multiplier": 1.25,
  },
  "activation_condition": "wellbeing > 40",
  "activation_description": "Active when wellbeing above 40",
},

"creative_core": {
  ...
  "global_effect": {
    "habit_bonus_multiplier": 1.5,
    "processing_speed_multiplier": 0.85,  # DOWNSIDE
  },
},

"compassion_center": {
  ...
  "global_effect": {
    "processing_speed_multiplier": 1.3,
  },
  "activation_condition": "coping_buildings > 0",
  "activation_description": "Requires at least one coping building",
},
```

---

### Task 2.3: Implement Activation Conditions in Building
**File:** `src/entities/building.gd`
**Change:** Check activation_condition before applying global effects

Add function:
```gdscript
func _check_activation_condition() -> bool:
  var condition = definition.get("activation_condition", "")
  if condition.is_empty():
    return true

  # Parse and evaluate simple conditions
  # "wellbeing > 40"
  # "coping_buildings > 0"
  var parts = condition.split(" ")
  if parts.size() != 3:
    return true

  var metric = parts[0]
  var op = parts[1]
  var value = int(parts[2])

  var actual = 0
  match metric:
    "wellbeing":
      actual = GameState.wellbeing
    "coping_buildings":
      actual = _count_coping_buildings()
    _:
      return true

  match op:
    ">": return actual > value
    "<": return actual < value
    ">=": return actual >= value
    "<=": return actual <= value
    "==": return actual == value

  return true
```

---

## Phase 3: Expand Synergy Web (P2)

### Task 3.1: Add Integration Temple Adjacency Rules
**File:** `src/data/adjacency_rules.gd`
**Change:** Add Integration Temple to rules dict

```gdscript
"integration_temple": {
  "mourning_chapel": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.2,
    "description": "Processed grief enriches meaning"
  },
  "reflection_pool": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.2,
    "description": "Insight flows into integration"
  },
  "gratitude_practice": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.15,
    "description": "Gratitude grounds meaning"
  },
  "meditation_garden": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.15,
    "description": "Stillness allows integration"
  },
  "journaling_corner": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.1,
    "description": "Written reflection aids synthesis"
  }
},
```

---

### Task 3.2: Add Cross-Archetype Bridges
**File:** `src/data/adjacency_rules.gd`
**Change:** Add bridges between archetypes

```gdscript
# Grief <-> Insight bridge
"reflection_pool": {
  ...existing rules...
  "mourning_chapel": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.15,
    "description": "Reflection on grief yields deeper insight"
  }
},

# Habit <-> Anxiety bridge
"meditation_garden": {
  ...existing rules...
  "anxiety_diffuser": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.2,
    "description": "Meditation accelerates anxiety diffusion"
  }
},

# Positive generator interactions
"hope_beacon": {
  "wound": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.3,
    "description": "Hope shines brighter near darkness"
  },
  "despair_alchemist": {
    "type": EffectType.SYNERGY,
    "output_bonus": 1,
    "description": "Hope fuels the transformation"
  }
},

"love_shrine": {
  "social_connection_hub": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.25,
    "description": "Connection deepens love"
  }
},

"curiosity_garden": {
  "reflection_pool": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.15,
    "description": "Curiosity drives deeper reflection"
  }
},

"emotion_fountain": {
  "hope_beacon": {
    "type": EffectType.SYNERGY,
    "efficiency": 1.1,
    "description": "Hope sustains positive emotions"
  }
},
```

---

### Task 3.3: Add Lenticular Depth to Flat Buildings
**File:** `src/data/building_definitions.gd`
**Change:** Add mechanics to flat generators

```gdscript
"hope_beacon": {
  ...existing...
  "generation_rate": 0.12,
  "generation_bonus_condition": "nearby_grief",
  "generation_bonus_multiplier": 2.0,
  "generation_bonus_description": "Doubles when grief is nearby",
},

"emotion_fountain": {
  ...existing...
  "generates": "random_positive",  # Change from just "joy"
  "weather_affected": true,
},

"curiosity_garden": {
  ...existing...
  "generation_bonus_condition": "new_building_nearby",
  "generation_bonus_multiplier": 1.5,
  "generation_bonus_duration": 10.0,
  "generation_bonus_description": "Generates more near newly-placed buildings",
},

"quick_cache": {
  ...existing...
  "processor_priority": true,
  "processor_speed_bonus": 0.2,
},

"memory_archive": {
  ...existing...
  "prevents_stagnation": true,
  "purity_decay_multiplier": 1.5,
},
```

---

## Phase 4: Resource Consolidation (P2)

### Task 4.1: Merge Redundant Resources
**Files:** `resources/resource_types/*.tres`, `src/data/building_definitions.gd`, `src/data/event_definitions.gd`

**Merges:**
1. pride + courage + confidence → **confidence**
2. restlessness + boredom → **restlessness**
3. contentment + comfort → **comfort**

**Steps:**
1. Update resource_types folder (delete merged .tres, update remaining)
2. Search/replace in building_definitions.gd
3. Search/replace in event_definitions.gd
4. Update any references in building.gd or other files

---

### Task 4.2: Add Processing Chains for Orphan Resources
**File:** `src/data/building_definitions.gd`
**Change:** Add new buildings or modify existing ones

```gdscript
"self_actualization_hub": {
  "id": "self_actualization_hub",
  "name": "Self-Actualization Hub",
  "description": "Transforms confidence into lasting resilience.",
  "behaviors": [Behavior.PROCESSOR, Behavior.STORAGE],
  "build_cost": {"energy": 6},
  "size": Vector2i(2, 2),
  "color": Color(0.85, 0.75, 0.45),
  "input": {"confidence": 4},
  "output": {"resilience": 1},
  "process_time": 8.0,
  "requires_worker": true,
  "storage_capacity": 10,
  "unlocked_by_default": false,
  "unlock_condition": {"insight": 4},
},

"meaning_radiator": {
  "id": "meaning_radiator",
  "name": "Meaning Radiator",
  "description": "Meaning flows back into the system as calm and wisdom.",
  "behaviors": [Behavior.PROCESSOR, Behavior.STORAGE],
  "build_cost": {"energy": 7},
  "size": Vector2i(2, 2),
  "color": Color(0.9, 0.85, 0.95),
  "input": {"meaning": 1},
  "output": {"calm": 2, "wisdom": 1},
  "process_time": 10.0,
  "requires_worker": false,
  "storage_capacity": 6,
  "unlocked_by_default": false,
  "unlock_condition": {"insight": 5},
},
```

---

## Phase 5: Expose Complexity to Players (P3)

### Task 5.1: Add Building Efficiency Breakdown
**File:** `src/ui/hud.gd` or new `building_info_panel.gd`
**Change:** Show tooltip explaining efficiency factors

When hovering a building with efficiency != 1.0:
```
Efficiency: 0.85x

Factors:
- Grief nearby: -15%
- Inner Critic conflict: -15%
+ Comfort Hearth synergy: +15%
```

---

### Task 5.2: Add Keyword Status Icons
**File:** `src/ui/hud.gd` or new overlay system
**Change:** Show status icons on buildings

Icons to add:
- 🔴 Burdened (grief/tension slowdown active)
- 🌀 Spiraling (worry compounding, anxiety spreading)
- 💚 Calm Aura (suppressing negatives)
- ⚡ Flowing (momentum/velocity bonus active)
- ⭐ Awakened (building has awakening bonus)
- 🔗 Attuned (building is attuned to neighbor)

---

## Execution Order

### Session 1 (Completed)
1. ✅ Task 1.1: Fix negative generator stacking
2. ✅ Task 1.2: Add unique flag to globals
3. ✅ Task 1.3: Implement uniqueness check
4. ✅ Task 2.1: Restructure FTUE unlock days
5. ✅ Task 3.1: Add Integration Temple adjacency
6. ✅ Task 3.2: Add cross-archetype bridges

### Session 2 (Completed)
7. ✅ Task 2.2: Add conditions to global effects
8. ✅ Task 2.3: Implement activation conditions (game_state.gd, worker_system.gd)
9. ✅ Task 3.3: Add lenticular depth to flat buildings

### Session 3 (Completed)
10. ✅ Task 4.2: Add processing chains for orphans (7 new buildings total)
11. ✅ Add quick_cache adjacency rules for processors
12. ✅ Add adjacency rules for new buildings
13. ✅ Add tests for new functionality

### Session 4 (Completed)
14. ✅ Add bidirectional adjacency rules (20+ pairs)
15. ✅ Add tests for bidirectional rules
16. ✅ Update analysis with final statistics (95 rules total)

### Remaining (Phase 5 - UI)
17. Task 5.1: Add efficiency breakdown UI
18. Task 5.2: Add keyword status icons
19. Final testing and polish

---

## Success Criteria

After all phases:
- [x] No negative generator compounds (all use diminishing returns)
- [x] Global effect buildings are unique
- [x] No Layer 2+ buildings unlocked before Day 3
- [x] Integration Temple has 5+ adjacency synergies
- [x] All archetypes have bridges to at least 2 other archetypes
- [x] No resources without processing chains (except derived end-goals)
- [x] All "always correct" buildings have conditions or trade-offs
- [ ] Players can see efficiency breakdown on hover (UI work remaining)
- [ ] Tests pass (need Godot to run)
