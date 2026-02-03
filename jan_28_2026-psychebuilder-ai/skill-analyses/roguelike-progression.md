# Progression Evaluation: PsycheBuilder

## Executive Summary

PsycheBuilder has a solid foundation for run-based progression with 50+ buildings, multiple unlock mechanisms, and emergent synergies through weather/wellbeing systems. However, the progression relies too heavily on a single unlock currency (Insight), lacks dramatic pacing moments within runs, and has no meta-progression implemented. The discovery system and belief unlocks provide good within-run variety, but discoverability of synergies is weak.

## Scores

| Dimension | Score | Status |
|-----------|-------|--------|
| Power Acquisition | 3/5 | Yellow |
| Synergy Architecture | 3/5 | Yellow |
| Decision Quality | 3/5 | Yellow |
| Pacing & Cadence | 3/5 | Yellow |
| Agency vs Randomness | 4/5 | Green |
| Meta-Progression | 2/5 | Red |
| Technical Flexibility | 4/5 | Green |

---

## Critical Findings

### Meta-Progression (2/5) - RED

**Problem:** No cross-run progression exists. The spec mentions multiple archetypes and meta-unlocks as "Future Variation (post-prototype)" but nothing is implemented.

**Evidence from `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/autoload/game_state.gd`:
```gdscript
func reset_to_defaults(...) -> void:
  # Everything resets - no persistence between runs
  discovered_buildings.clear()
  active_beliefs.clear()
  event_rewards_granted.clear()
```

**Impact:** Players have no reason to replay after completing runs at each wellbeing tier. No horizontal expansion of options across runs diminishes long-term engagement.

---

## Detailed Analysis

### A. Power Acquisition Mechanisms (3/5)

**Identified Channels:**
1. **Default Buildings** (16 buildings) - Available from start
2. **Insight Thresholds** - Most locked buildings require `unlock_condition: {"insight": X}` (ranging from 1-5)
3. **Event Rewards** - Only 1 building (`resilience_monument`) uses this
4. **Discovery System** - 40% chance each night after day 2, pick 1 of 3

**Evidence from `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd`:
```gdscript
# Example unlock conditions - note dominance of insight threshold
"emotion_fountain": { "unlock_condition": {"insight": 2} },
"hope_beacon": { "unlock_condition": {"insight": 2} },
"pride_monument": { "unlock_condition": {"insight": 3} },
"integration_temple": { "unlock_condition": {"insight": 5} },
"resilience_monument": { "unlock_condition": {"event_reward": "the_rejection"} }, # Only one!
```

**Issues:**
- Insight threshold dominates 25+ building unlocks
- Only 1 building uses event_reward unlock mechanism
- No "shop" equivalent to buy specific buildings with resources
- No rare/legendary drops from events that transform runs

**Recommendation:** Diversify unlock sources. Add:
- Buildings unlocked by processing certain emotion thresholds
- Buildings unlocked by reaching wellbeing tiers
- Buildings unlocked by core belief activation
- More event-specific reward buildings

---

### B. Synergy Architecture (3/5)

**Identified Synergy Systems:**
1. **Adjacency/Harmony** - Config defines pairs in `harmony_pairs`
2. **Processing Chains** - grief -> wisdom, anxiety -> calm, etc.
3. **Weather System** - Emotional momentum shifts weather, affects all buildings
4. **Wellbeing Tiers** - Struggling/Baseline/Stable/Thriving/Flourishing modify generation/processing
5. **Core Beliefs** - 5 beliefs provide passive bonuses

**Evidence from `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/autoload/config.gd`:
```gdscript
@export var harmony_pairs: Dictionary = {
  "memory_well": ["memory_processor", "mourning_chapel"],
  "wound": ["mourning_chapel"],
  "worry_loop": ["anxiety_diffuser", "grounding_station"],
  ...
}
```

**Build Archetypes Possible:**
1. **Grief Processing** - wound + mourning_chapel + memory_well -> wisdom
2. **Anxiety Management** - worry_loop + anxiety_diffuser + grounding_station
3. **Positive Generation** - emotion_fountain + hope_beacon + joy focus
4. **Habit Heavy** - morning_routine + meditation_garden + creative_studio
5. **Global Effect Stack** - late-game optimism_lens + compassion_center

**Issues:**
- Synergies are implicit - no in-game hints about what pairs well
- Building descriptions don't mention synergy partners
- No visual indicator for adjacent synergies (like Enter the Gungeon's synergy icon)
- Some processors require specific inputs that may be unreliable

**Recommendation:** Add synergy discoverability:
- Building tooltips should list synergy partners
- Visual indicator when buildings are placed in synergy positions
- Tag system displayed in UI (e.g., "Grief-Processing", "Calm-Source")

---

### C. Decision Quality (3/5)

**Decision Points Identified:**
1. Building placement (adjacency matters)
2. Worker routing (source to destination)
3. Discovery choices (1 of 3 buildings)
4. Event choices (from spec)
5. Energy allocation

**Evidence from `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/autoload/config.gd`:
```gdscript
@export var starting_energy: int = 8
@export var energy_regen_per_day: int = 4
# Most buildings cost 3-6 energy
```

**Issues:**
- Energy is tight (8 starting, +4/day), but most decisions are "what to build" not "whether to build"
- No clear "skip" option in discovery - can player decline all 3?
- No building removal/demolition cost shown - unclear if rebuilding is viable strategy
- Early decisions (roads, storage) may feel obligatory rather than strategic

**Recommendation:** 
- Add a "decline discovery" option that grants a small insight bonus instead
- Make building removal refund partial energy to enable pivoting
- Create more early-game divergent strategies (skip roads for isolated high-power buildings?)

---

### D. Pacing & Cadence (3/5)

**Run Structure:**
- 20 days total
- Day: 50 seconds active, Night: 8 seconds planning
- Total runtime: ~19-20 minutes per run
- Inciting incident: Day 5

**Evidence from `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/autoload/config.gd`:
```gdscript
@export var day_duration_seconds: float = 50.0
@export var night_duration_seconds: float = 8.0
@export var total_days: int = 20
@export var inciting_incident_day: int = 5
```

**Issues:**
- No mid-run milestone challenges or "boss" equivalents
- Day 5 inciting incident is the only major event beat
- Weather shifts provide some pacing but aren't dramatic moments
- Build may not "come online" until late game due to insight unlock gates
- Endings are purely score-based, no climactic final challenge

**Recommendation:**
- Add milestone challenges at days 7, 14, 20 (mini "emotional crises")
- Create a dramatic Day 20 final evaluation moment
- Front-load some building variety (lower insight requirements or more starter buildings)
- Add "breakthrough" moments with visual/audio flourish when builds come online

---

### E. Agency vs Randomness (4/5)

**Player Agency:**
- Full control over building placement
- Worker routing is player-determined
- Discovery: choose 1 of 3 (pre-action luck)
- Weather responds to player state (not pure RNG)
- Wellbeing tiers are player-influenced

**Randomness:**
- Discovery pool is random
- Event timing has 30% random chance
- Generation buildings produce at rates with some variance
- Starting emotions are fixed (good)

**Evidence from `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/autoload/game_state.gd`:
```gdscript
func _determine_weather() -> void:
  # Weather is deterministic based on emotional momentum
  var joy_mom = weather_momentum.get("joy", 0.0)
  # ... weather determined by which momentum is highest
```

**Minor Issues:**
- No pity timer for discovery (could go many nights without desired building type)
- Random events could derail carefully planned strategies

**Recommendation:**
- Add discovery category preference (player indicates "looking for processors" to weight pool)
- Implement insight pity timer (guaranteed unlock after X insight without new building)

---

### F. Meta-Progression (2/5) - CRITICAL

**Current State:**
- Single archetype implemented (The Striver)
- No cross-run persistence
- All progress resets between runs

**Evidence from spec.md:**
```markdown
### Future Variation (post-prototype)
- Multiple archetypes with distinct starting conditions
- Resource behavior modifiers ("this mind's anger burns hot")
- Meta-progression unlocks across runs
- Challenge modifiers
```

**Impact:**
- No reason to replay beyond seeing 4 endings
- Players cannot unlock new strategies across runs
- Early runs feel identical to late runs

**Recommendations (Priority: CRITICAL):**

1. **Archetype Unlocks**: Unlock new archetypes by achieving specific endings or milestones
   - Complete run at Flourishing -> Unlock "The Dreamer" archetype
   - Process 50 grief total across runs -> Unlock "The Mourner" archetype

2. **Starting Building Unlocks**: Permanently add buildings to starting palette
   - First time building Integration Temple -> Future runs start with it available

3. **Core Belief Persistence**: Beliefs unlocked in one run could provide small bonuses in future runs

4. **Challenge Modifiers**: Unlock harder modes (shorter days, more negative generation, etc.)

---

### G. Technical Flexibility (4/5)

**Strengths:**
- Building definitions are fully data-driven
- Config.gd has 400+ lines of @export tunable values
- Behavior enum system allows modular building design
- Resource system uses string identifiers

**Evidence from `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd`:
```gdscript
static var definitions: Dictionary = {
  "mourning_chapel": {
    "behaviors": [Behavior.PROCESSOR, Behavior.STORAGE],
    "input": {"grief": 2},
    "output": {"wisdom": 1},
    "unlock_condition": {"insight": X},
    ...
  }
}
```

**Minor Issues:**
- Unlock condition checking has some hardcoded logic in building_system.gd
- Event definitions would need code changes to add new events
- No hot-reload for balance iteration

**Recommendation:**
- Extract unlock condition types to enum/constants
- Move event definitions to data files
- Consider GDScript tool mode for live balance testing

---

## Prioritized Recommendations

### CRITICAL Priority

1. **[META] Implement basic meta-progression system**
   - Track cross-run statistics (total grief processed, runs completed, etc.)
   - Unlock 2-3 additional archetypes based on achievements
   - Persist at least one horizontal unlock (new starting building option)

### HIGH Priority

2. **[UNLOCK] Diversify building unlock mechanisms**
   - Add wellbeing-tier unlocks (reach Thriving -> unlock X)
   - Add belief-based unlocks (unlock Calm Foundation belief -> unlock Y)
   - Add more event-reward buildings (at least 3-4)

3. **[PACING] Add milestone challenges**
   - Day 7: First emotional test (specific resource requirement)
   - Day 14: Mid-run crisis (survive with wellbeing above threshold)
   - Day 20: Final integration (process remaining negatives for bonus)

4. **[SYNERGY] Improve synergy discoverability**
   - Add `synergy_hints` field to building definitions
   - Display synergy partners in building tooltips
   - Visual indicator when adjacent synergy is active

### MEDIUM Priority

5. **[DISCOVERY] Add discovery agency**
   - "Decline all" option grants +1 insight
   - Category preference system (weight pool toward processors/generators/etc.)

6. **[DECISIONS] Enable build pivoting**
   - Building demolition refunds 50% energy
   - Clear UI for removing buildings

7. **[PACING] Front-load building variety**
   - Reduce insight requirements on tier-1 locked buildings (2->1)
   - Or add 2-3 more default-unlocked buildings for early variety

### LOW Priority

8. **[TECH] Extract event definitions to data files**

9. **[POLISH] Add breakthrough moment celebrations**
   - Visual/audio flourish when build achieves synergy chain
   - Weather shift notifications

---

## Quick Wins (< 1 day implementation)

1. **Add synergy_hints to building definitions**
   ```gdscript
   "mourning_chapel": {
     ...
     "synergy_hints": ["memory_well", "wound"],
   }
   ```
   Display in tooltip: "Synergizes with: Memory Well, Old Wound"

2. **Add 3 more wellbeing-tier unlock conditions**
   ```gdscript
   "hope_beacon": {
     "unlock_condition": {"wellbeing_tier": "stable"},  # New unlock type
   }
   ```

3. **Add discovery decline option**
   In discovery UI, add "Skip (+1 Insight)" button that closes panel and grants insight.

4. **Reduce insight requirements on 5 buildings from 2->1**
   Makes early runs more varied without major balance changes.

5. **Track cross-run statistics in a separate autoload**
   Even without acting on them yet, start recording total_runs, best_wellbeing, total_grief_processed, etc.