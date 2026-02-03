# Emergent Game Design Analysis: PsycheBuilder

## Executive Summary

PsycheBuilder is a city-builder metaphor for mental health with 56 buildings, 21 events, and 480+ tunable parameters. The game shows strong emergent design foundations but has critical issues in complexity layering, archetype clarity, and synergy web coherence. This analysis applies the Emergent Game Design skill framework to identify strengths, weaknesses, and actionable improvements.

---

## 1. Atomic Vocabulary Analysis

### Identified Atoms (Current Count: ~24)

**Output Atoms:**
1. Resource generation (generates: X)
2. Resource processing (input -> output)
3. Resource storage (storage_capacity)
4. Habit output (habit_generates)
5. Energy bonus (habit_energy_bonus)
6. Global effect modifiers

**Input Atoms:**
7. Energy cost (build_cost)
8. Resource consumption (input, habit_consumes)
9. Worker requirement (requires_worker)
10. Coping trigger conditions (coping_trigger)
11. Unlock conditions (unlock_condition)

**Modifier Atoms:**
12. Process time (process_time)
13. Generation rate (generation_rate)
14. Adjacency efficiency (efficiency multipliers)
15. Spillover effects
16. Conditional outputs
17. Habit reduction (habit_reduces)
18. Coping cooldown

**Emergent System Atoms (from config.gd):**
19. Grief slowdown
20. Anxiety spreading
21. Calm aura suppression
22. Worry compounding
23. Doubt propagation
24. Tension accumulation

### Assessment

**Problem: Atom count exceeds recommended 12-20.** The game has ~24 core atoms plus an additional ~40 emergent system parameters in config.gd (saturation, resonance, momentum, fatigue, echo, harmony, purity, attunement, fragility, stagnation, mastery, velocity, weather, breakthrough, legacy, etc.).

**Red Flag:** The building.gd file has 24+ separate state variables and processes 30+ effects per tick. This is excessive cognitive load.

### Recommendation: Atom Consolidation

| Current Atoms | Consolidate Into |
|--------------|------------------|
| Grief slowdown, Tension slowdown | Single "burden" mechanic |
| Worry compounding, Anxiety spreading | Single "spiral" mechanic |
| Momentum, Velocity, Flow state | Single "rhythm" mechanic |
| Purity, Stagnation, Fragility | Single "freshness" mechanic |
| Attunement, Harmony, Legacy | Single "bond" mechanic |

---

## 2. Lenticular Design Analysis

### Current Lenticular Examples (Strong)

**Mourning Chapel** - "Grief -> Wisdom"
- Novice: Process grief, get wisdom
- Intermediate: Sees adjacency with Memory Well (+20%), avoids Rumination Spiral (-30%)
- Expert: Recognizes grief processing creates tension, chains with Exercise Yard for cathartic release

**Memory Processor** - "Nostalgia -> Joy or Grief"
- Novice: Processes nostalgia
- Intermediate: Notices conditional output (needs calm nearby for joy, tension for grief)
- Expert: Positions near Comfort Hearth for consistent joy conversion

**Exercise Yard** - "Energy -> Tension reduction + Calm"
- Novice: Reduces tension
- Intermediate: Discovers cathartic release converts all stored tension to calm
- Expert: Chains with Sleep Chamber adjacency (+25%) for energy economy

### Lenticular Checklist Assessment

| Building | Obvious Use | 3+ Interactions | Changes Draft Priority | Expert "Sees" More |
|----------|-------------|-----------------|----------------------|-------------------|
| Mourning Chapel | Pass | Pass | Pass | Pass |
| Memory Processor | Pass | Pass | Pass | Pass |
| Comfort Hearth | Pass | Pass | Fail | Fail |
| Hope Beacon | Pass | Fail | Fail | Fail |
| Emotion Fountain | Pass | Fail | Fail | Fail |
| Integration Temple | Pass | Pass | Pass | Pass |

### Problem: Too Many "Flat" Buildings

~15 buildings are simple generators with no interesting interactions:
- Hope Beacon, Emotion Fountain, Pride Monument, Love Shrine - just generate resource X
- Curiosity Garden, Excitement Generator - no synergies defined
- Memory Archive, Thought Library, Quick Cache - pure storage

### Recommendation: Add Depth to Flat Buildings

**Hope Beacon** - Add: "Adjacent to buildings with high grief, processing speed doubles" (lenticular: expert places near wounds for counter-synergy)

**Emotion Fountain** - Add: "Random positive emotion, but affected by emotional weather" (lenticular: expert times placement for clear weather)

**Curiosity Garden** - Add: "Generates more when adjacent to newly-placed buildings" (already in spec but not implemented)

---

## 3. Complexity Layering Assessment

### Current Layer Distribution

**Layer 0 (Vocabulary) - 10%:**
- Road, Emotional Reservoir, Quick Cache
- Problem: Only 3 buildings, should be 8-12

**Layer 1 (Combinations) - ~45%:**
- Most generators (Memory Well, Comfort Hearth, Hope Beacon)
- Basic processors (Anxiety Diffuser, Tension Release)
- Basic habits (Morning Routine, Exercise Yard)

**Layer 2 (Conditions) - ~35%:**
- Conditional processors (Memory Processor, Grounding Station)
- Coping buildings (Emergency Calm Center, Anger Vent)
- Adjacency-dependent buildings

**Layer 3 (Build-arounds) - ~10%:**
- Integration Temple (needs wisdom + insight + gratitude)
- Global effect buildings (Optimism Lens, Creative Core, Compassion Center)
- Resilience Monument (event reward unlock)

### Problems Identified

1. **Too Many Layer 2 Buildings Available Immediately**
   - Memory Processor, Grounding Station unlocked by default
   - New players face complex conditional outputs too early

2. **Layer 3 Buildings Lack Build-Defining Impact**
   - Global effects are passive multipliers (1.25x, 1.5x), not strategy-warping
   - No buildings that say "build your entire strategy around me"

3. **Missing Gating**
   - 28 buildings unlocked by default
   - Only insight requirements for unlocks (no other gates)

### Recommendation: Restructure Complexity Ladder

**Layer 0 (Default Start):**
Road, Emotional Reservoir, Memory Well, Comfort Hearth, Morning Routine, Exercise Yard, Anxiety Diffuser

**Layer 1 (Unlock at Insight 2-3):**
Tension Release, Journaling Corner, Meditation Garden, Anger Forge, Memory Archive

**Layer 2 (Unlock at Insight 4-5 or Events):**
Memory Processor, Grounding Station, Reflection Pool, Coping buildings

**Layer 3 (Unlock at Insight 8+ or Special Conditions):**
Integration Temple, Global Effects, Resilience Monument

---

## 4. Synergy Web Analysis

### Current Archetypes (Implicit)

Analyzing building_definitions.gd and adjacency_rules.gd reveals 5 implicit archetypes:

| Archetype | Core Mechanic | Enablers | Payoffs |
|-----------|--------------|----------|---------|
| Grief Processing | grief -> wisdom | Memory Well, Wound | Mourning Chapel, Resilience Monument |
| Anxiety Management | anxiety -> calm | Worry Loop, Inner Critic | Anxiety Diffuser, Grounding Station, Emergency Calm Center |
| Reflection | thoughts -> insight | Rumination Spiral | Reflection Pool, Journaling Corner |
| Habit Routine | daily triggers | Morning Routine, Exercise Yard | Sleep Chamber, Meditation Garden |
| Integration | derived -> meaning | Multiple processors | Integration Temple |

### 30-50-20 Distribution Analysis

| Category | Target | Actual | Assessment |
|----------|--------|--------|------------|
| Dedicated archetype | 30% | ~20% | Too few specialist buildings |
| Bridge cards | 50% | ~35% | Some cross-archetype support |
| Generic value | 20% | ~45% | Too many generic buildings |

### Problem: Weak Archetype Bridges

Current adjacency_rules.gd defines only 15 adjacency relationships for 56 buildings. Most buildings have 0-1 adjacency effects.

**Bridges in adjacency_rules:**
- Memory Well <-> Mourning Chapel (Grief archetype only)
- Meditation Garden <-> Reflection Pool (Reflection archetype only)
- Exercise Yard <-> Sleep Chamber (Habit archetype only)
- Comfort Hearth <-> Anxiety Diffuser (Anxiety archetype only)

**Missing bridges between archetypes:**
- No bridge between Grief and Reflection
- No bridge between Habit and Anxiety
- No bridge between Integration and anything

### Recommendation: Expand Synergy Web

Add these adjacency rules:

```gdscript
"reflection_pool": {
  "mourning_chapel": {  # Bridge: Grief <-> Reflection
    "type": EffectType.SYNERGY,
    "efficiency": 1.15,
    "description": "Reflection on grief yields deeper insight"
  }
},
"meditation_garden": {
  "anxiety_diffuser": {  # Bridge: Habit <-> Anxiety
    "type": EffectType.SYNERGY,
    "efficiency": 1.2,
    "description": "Meditation accelerates anxiety diffusion"
  }
},
"integration_temple": {
  "mourning_chapel": {  # Bridge: Integration <-> Grief
    "type": EffectType.SYNERGY,
    "output_bonus": 1,
    "description": "Processed grief enriches meaning"
  },
  "reflection_pool": {  # Bridge: Integration <-> Reflection
    "type": EffectType.SYNERGY,
    "output_bonus": 1,
    "description": "Insight flows into integration"
  }
}
```

---

## 5. Engine Building Pattern Analysis

### Current Engine Taxonomy

**Passive Generators:**
- Memory Well (+1 nostalgia per 5 ticks)
- Comfort Hearth (+1 calm per 6.67 ticks)
- Hope Beacon (+1 hope per 8.33 ticks)
- Negative generators: Wound, Worry Loop, Rumination Spiral, Inner Critic

**Triggered Generators:**
- Coping buildings (trigger on threshold)
- Habit buildings (trigger daily)

**Converters:**
- All processors (grief -> wisdom, anxiety -> calm, etc.)

**Multipliers:**
- Global effect buildings (1.25x positive generation, 1.3x processing speed, etc.)

### The Compounding Question Assessment

**"What happens if player stacks 3 of these?"**

| Building | Stack 3 Effect | Assessment |
|----------|---------------|------------|
| Comfort Hearth | 3x calm generation | Boring but fine |
| Memory Well | 3x nostalgia | Needs processor capacity |
| Worry Loop | 3x worry generation | PROBLEM: compounds via worry_compounding |
| Wound | 3x grief | Manageable |
| Optimism Lens | Can't stack (unique?) | Not enforced! |
| Creative Core | Can't stack (unique?) | Not enforced! |

### Problem: No Stacking Limits on Global Effects

`generator_stacking` in adjacency_rules.gd only covers 6 buildings. Global effect buildings have no uniqueness enforcement.

### Recommendation: Enforce Global Effect Uniqueness

Add to building_definitions.gd:
```gdscript
"unique_global_effect": true  # Only one of this building allowed
```

For stackable generators, the diminishing returns are:
- memory_well: 0.85x per additional copy
- comfort_hearth: 0.9x per additional copy
- worry_loop: 1.1x per additional copy (compounds!)

**Red Flag:** Negative generators compound while positive generators diminish. This creates runaway negative spirals.

---

## 6. Resource Manipulation Analysis

### Resource Tension Principles

**Current Resource Types:**

| Category | Count | Examples |
|----------|-------|----------|
| Positive emotions | 11 | Joy, Love, Hope, Calm, Pride, Excitement, Contentment, Gratitude, Curiosity, Courage, Confidence |
| Negative emotions | 11 | Grief, Anger, Fear, Shame, Anxiety, Loneliness, Despair, Doubt, Worry, Tension, Fatigue |
| Derived | 4 | Wisdom, Insight, Resilience, Meaning |
| Sensations | 4 | Comfort, Restlessness, Boredom, Nostalgia |
| Total | ~30 | |

**Problem: Too Many Resources**

The spec targets 25-30 resources but many lack distinct mechanical identity:
- Pride, Confidence, Courage - no unique processing chains
- Restlessness, Boredom - generated by only 1-2 buildings
- Loneliness - only 2 buildings interact with it

### Resource Scarcity Analysis

| Resource | Sources | Sinks | Scarcity |
|----------|---------|-------|----------|
| Calm | 5 generators, 4 processors | Consumed by Grounding Station, Memory Processor | Abundant |
| Wisdom | 2 processors | Integration Temple | Scarce |
| Insight | 5 sources | Integration Temple, unlock condition | Medium |
| Meaning | 1 source | None | Very scarce |
| Grief | 3 generators, events | 2 processors | Abundant (problem!) |
| Anxiety | 2 generators, events | 2 processors | Abundant (problem!) |

### Recommendation: Consolidate Resources

Merge underused resources:
- Pride + Confidence + Courage -> "Confidence" 
- Restlessness + Boredom -> "Restlessness"
- Fear + Anxiety -> Keep "Anxiety" (fear as acute, anxiety as chronic is unclear)

Create new processing chains:
- Loneliness -> Social Connection Hub -> Love (currently habit only)
- Meaning -> ??? (no sink! meaning accumulates forever)

---

## 7. Keyword Abstraction Assessment

### Current Implicit Keywords

The game uses behavior tags but not explicit keywords:
- GENERATOR, PROCESSOR, STORAGE, CONSUMER, HABIT, COPING, INFRASTRUCTURE, GLOBAL_EFFECT

### Missing Keywords for Emergent Mechanics

The config.gd has 40+ emergent systems with no player-facing vocabulary:
- Saturation (joy numbness, grief wisdom, anxiety panic)
- Resonance (positive/negative cascades)
- Momentum (processing rhythm)
- Fragility (building damage)
- Stagnation (resource decay)
- Mastery (building specialization)
- Velocity (processing speed)
- Legacy (long-term building bonus)
- Attunement (building harmony)
- etc.

### Problem: Hidden Complexity

Players have no vocabulary to understand these systems. Config.gd exposes 480+ parameters but the UI has no way to communicate:
- Why this building is processing slowly (fragility? stagnation? grief? tension?)
- What "attuned" or "harmony" means
- When momentum breaks or builds

### Recommendation: Create Player-Facing Keywords

**Tier 1 (Always Show):**
- **Burden** - Slowed by grief/tension
- **Spiral** - Negative emotions multiply
- **Calm** - Suppresses spirals

**Tier 2 (Hover/Expert):**
- **Attuned** - Bonded with adjacent building
- **Awakened** - Building gained permanent boost
- **Fresh/Stagnant** - Resource age state

---

## 8. Text Brevity Assessment

### Building Description Word Counts

| Building | Description | Words | Assessment |
|---------|-------------|-------|------------|
| Road | "Connects buildings, allowing workers to travel between them." | 8 | Good |
| Mourning Chapel | "A quiet space to process grief into wisdom." | 8 | Good |
| Memory Processor | "Transforms Nostalgia into Joy when Calm is present, or into Grief when Tension is present." | 17 | Good |
| Integration Temple | "A complex processor that synthesizes multiple emotions into Meaning." | 10 | Good |
| Emergency Calm Center | "Activates when Anxiety spikes, rapidly converting it to Calm." | 10 | Good |

**Assessment:** Building descriptions are well within the 10-25 word target for standard elements.

### Event Description Assessment

Events average 15-25 words, which is appropriate:
- "Something you cared about deeply has ended. A relationship, a job, a dream. The loss hits hard." (17 words)

### Screenshot Test

Most buildings pass the screenshot test. However, the config.gd complexity is invisible. A player cannot see:
- Why their building shows efficiency 0.7x
- What the "A M V L S" indicators mean in storage display
- How adjacency effects are calculated

---

## 9. Balance Through Constraints Assessment

### Anti-Combo Constraint Check

**No Triple-Threat Cards:** Pass
- Buildings do 1-2 things well (generate OR process OR store)
- No building provides "high output + high storage + coping"

**Mutual Exclusivity:** Fail
- Multiple global effect buildings can stack
- No positioning constraints for powerful buildings

**Diminishing Returns:** Partial
- Generator stacking has diminishing returns (0.85x-0.9x per copy)
- BUT negative generators compound (1.1x-1.15x per copy)
- Global effects have no diminishing returns

**Counter-Synergies:** Pass
- Rumination Spiral conflicts with Sleep Chamber
- Worry Loop conflicts with Hope Beacon
- Inner Critic conflicts with Grounding Station

### The Playtest Question

**"Is this element always correct to take?"**

| Building | Always Correct? | Assessment |
|----------|----------------|------------|
| Integration Temple | No (needs inputs) | Good design |
| Optimism Lens | Yes (passive +25%) | Needs nerf or condition |
| Creative Core | Yes (passive +50% habits) | Needs nerf or condition |
| Compassion Center | Yes (passive +30% processing) | Needs nerf or condition |
| Morning Routine | Nearly yes | Needs downside |
| Comfort Hearth | Nearly yes | Needs downside |

### Recommendation: Add Constraints to Global Effects

```gdscript
"optimism_lens": {
  # Add condition
  "active_condition": "wellbeing > 50",
  "description": "Active only when wellbeing is stable."
},
"creative_core": {
  # Add downside
  "global_effect": {
    "habit_bonus_multiplier": 1.5,
    "processing_penalty_multiplier": 0.9  # NEW
  }
}
```

---

## 10. Quick Reference Checklist

### For Every Element

| Criterion | Buildings Pass | Issues |
|-----------|---------------|--------|
| Uses 1-4 atoms maximum | ~80% | Some have 5+ (processors with coping) |
| Has lenticular depth | ~50% | Many flat generators |
| Fits into at least one archetype | ~70% | Orphan buildings exist |
| Has clear counterplay/weakness | ~60% | Positive generators have no counters |
| Text under 40 words | 100% | Pass |
| Passes screenshot test | ~80% | Config complexity invisible |

### For the Whole System

| Criterion | Status | Action Needed |
|-----------|--------|---------------|
| 12-20 total atomic mechanics | **Fail (24+)** | Consolidate emergent systems |
| 4-6 archetypes with overlapping synergies | **Partial** | Define archetypes, add bridges |
| 30-50-20 distribution | **Fail (20-35-45)** | Reduce generic, add dedicated |
| No "always correct" picks | **Fail** | Add conditions to global effects |
| Complexity properly gated | **Fail** | Restructure unlock progression |
| At least 3 manipulable resource types | **Pass** | Energy, Attention, Wellbeing |
| Keyword list under 10 terms | **Fail** | 40+ systems, no vocabulary |

### Red Flags Assessment

| Red Flag | Present? | Evidence |
|----------|----------|----------|
| Element does too many unrelated things | Yes | Building.gd processes 30+ systems |
| One strategy dominates all others | Unknown | Needs playtesting |
| Players can't understand element in 5 seconds | Yes | Config complexity invisible |
| Stacking 3x trivializes the game | Partial | Global effects stackable |
| An archetype has no losing matchups | Unknown | Events seem balanced |
| New players overwhelmed by complexity | **Yes** | 28 buildings unlocked by default |
| Veterans have solved optimal path | Unknown | Needs playtesting |

---

## Actionable Recommendations Summary

### Priority 1: Critical Issues

1. **Reduce Default Unlocked Buildings from 28 to 8**
   - Start: Road, Emotional Reservoir, Memory Well, Comfort Hearth, Morning Routine, Exercise Yard, Anxiety Diffuser, Mourning Chapel
   - Gate remaining behind insight thresholds

2. **Consolidate Emergent Systems from ~20 to ~8**
   - Merge: Momentum + Velocity + Flow -> "Rhythm"
   - Merge: Purity + Stagnation + Fragility -> "Vitality"
   - Merge: Attunement + Harmony + Legacy -> "Bond"
   - Keep: Grief slowdown, Anxiety spreading, Calm aura, Weather

3. **Add Constraints to Global Effect Buildings**
   - Make unique (only one per game)
   - Add activation conditions
   - Add meaningful downsides

### Priority 2: Synergy Web

4. **Define 5 Clear Archetypes**
   - Grief Processing (dark blue)
   - Anxiety Management (teal)
   - Insight Seeking (purple)
   - Habit Building (gold)
   - Integration (iridescent)

5. **Add 15+ Adjacency Rules**
   - Every archetype needs 2+ bridges to other archetypes
   - Integration Temple needs synergies with all archetypes

6. **Create Visual Archetype Identity**
   - Color-code buildings by primary archetype
   - Show archetype icons in UI

### Priority 3: Lenticular Depth

7. **Add Depth to Flat Generators**
   - Hope Beacon: Doubles when grief nearby
   - Curiosity Garden: Generates more with new buildings
   - Emotion Fountain: Affected by weather

8. **Create Build-Defining Layer 3 Buildings**
   - "Insight Engine" - All insight processing costs 0 attention but exhausts workers
   - "Grief Amplifier" - Grief processing yields 3x wisdom but spreads anxiety
   - "Calm Monopole" - All calm generation goes to this building, +100% output

### Priority 4: Player Understanding

9. **Create Keyword UI System**
   - Tier 1: Burden, Spiral, Calm
   - Tier 2: Attuned, Awakened, Fresh/Stagnant
   - Hover tooltips explain all mechanics

10. **Consolidate Resources from 30 to 20**
    - Merge: Pride + Confidence + Courage
    - Merge: Restlessness + Boredom
    - Remove or repurpose: Nostalgia (overlap with grief/joy)

---

## TODO List for Implementation

### Immediate (This Sprint)

- [ ] Reduce default unlocked buildings from 28 to 8
- [ ] Add `"unique_global_effect": true` to all global effect buildings
- [ ] Add activation conditions to Optimism Lens, Creative Core, Compassion Center
- [ ] Fix negative generator stacking (change from 1.1x compound to 0.9x diminish)

### Short-term (Next 2 Sprints)

- [ ] Define 5 archetypes in documentation
- [ ] Add 15 new adjacency rules connecting archetypes
- [ ] Consolidate config.gd emergent systems (20 -> 8)
- [ ] Create player-facing keyword UI for top 6 mechanics

### Medium-term (Month)

- [ ] Add lenticular depth to flat generators (Hope Beacon, Curiosity Garden, etc.)
- [ ] Create 3 new Layer 3 build-defining buildings
- [ ] Consolidate resources from 30 to 20
- [ ] Add archetype color-coding to building sprites

### Long-term (Playtesting Phase)

- [ ] Playtest archetype balance
- [ ] Tune Layer 3 building power levels
- [ ] Verify no "always correct" picks remain
- [ ] Confirm complexity gating feels right

---

## Files Referenced

| File | Path |
|------|------|
| Spec | `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/spec.md` |
| Building Definitions | `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd` |
| Event Definitions | `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/data/event_definitions.gd` |
| Adjacency Rules | `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/data/adjacency_rules.gd` |
| Config | `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/autoload/config.gd` |
| Building Entity | `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/entities/building.gd` |