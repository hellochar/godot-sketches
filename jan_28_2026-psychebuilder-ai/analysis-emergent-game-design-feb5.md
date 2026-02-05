# Emergent Game Design Analysis: PsycheBuilder
**Date:** February 5, 2026
**Analyst:** Claude (Emergent Game Design Skill)

---

## Executive Summary

PsycheBuilder is a mental health city-builder with **48 buildings**, **33 resources**, **20 events**, and **~500 tunable parameters**. The game demonstrates sophisticated emergent design with 25+ implemented subsystems (saturation, resonance, momentum, harmony, etc.) but suffers from **severe complexity overload**. The atomic vocabulary far exceeds the recommended 12-20, complexity isn't gated properly, and many advanced mechanics are invisible to players.

**Critical Finding:** The game has the depth of a 200+ hour roguelike squeezed into a 20-day run. Players will never discover most systems.

---

## 1. Atomic Vocabulary Analysis

### Current Atom Count: **~45** (Recommended: 12-20)

#### Output Atoms (13)
1. Resource generation (generates: X)
2. Resource processing (input → output)
3. Storage capacity
4. Habit daily output (habit_generates)
5. Coping trigger output (coping_output)
6. Energy bonus (habit_energy_bonus)
7. Global multipliers (positive_generation_multiplier, etc.)
8. Spillover effects
9. Conditional outputs (calm → joy, tension → grief)
10. Resource reduction (habit_reduces)
11. Output bonus (adjacency output_bonus)
12. Wisdom from processing
13. Insight chance

#### Input Atoms (8)
1. Energy cost (build_cost)
2. Resource consumption (input, habit_consumes)
3. Worker requirement (requires_worker)
4. Coping trigger threshold (anxiety > 10)
5. Adjacency requirements
6. Insight unlock thresholds
7. FTUE day gates
8. Event rewards unlock

#### Modifier Atoms (12)
1. Process time
2. Generation rate
3. Efficiency multipliers (adjacency)
4. Transport bonus
5. Speed multiplier (highway)
6. Stacking diminishing returns
7. Cooldown (coping_cooldown)
8. Building size
9. Storage types
10. Weather modifiers
11. Wellbeing-based modifiers
12. Attention costs

#### Emergent System Atoms (~12 MORE in config.gd)
- Saturation (joy numbness, grief wisdom, anxiety panic)
- Resonance (positive cascade, negative amplification)
- Momentum (processing rhythm, break penalty)
- Purity (resource quality decay)
- Fragility (building cracking/leaking)
- Stagnation (resource aging, decay transforms)
- Mastery (building specialization)
- Velocity (processing flow momentum)
- Harmony (building pairs bonus)
- Attunement (neighbor bonding)
- Echo (resource type memory)
- Legacy (long-term imprints)

### Assessment: CRITICAL OVERLOAD

**Problem:** 45+ atoms is 2-3x the recommended maximum. No player can hold this mental model.

**Evidence from config.gd:**
- 40+ @export_groups of tunable mechanics
- Many systems have 8-12 parameters each
- Systems like "Emotional Weather" have 15 parameters
- "Building Saturation" alone has 10 parameters

### Recommendation: Consolidate to 16 Core Atoms

| Keep | Merge Into It |
|------|---------------|
| **Generation** | All passive resource output |
| **Processing** | All input → output transforms |
| **Storage** | Capacity, purity |
| **Habit** | Daily triggers, energy bonus |
| **Coping** | Emergency triggers, cooldowns |
| **Adjacency** | Synergy, conflict, harmony |
| **Unlock** | Insight gates, FTUE days, events |
| **Global Effect** | All city-wide multipliers |
| **Momentum** | Velocity, flow state, rhythm |
| **Burden** | Grief slowdown, tension accumulation, fragility |
| **Spiral** | Worry compounding, anxiety spreading, resonance negative |
| **Calm Aura** | Suppression, healing |
| **Mastery** | Awakening, legacy, specialization |
| **Weather** | All weather effects |
| **Wellbeing** | All wellbeing tier effects |
| **Attention** | Habituation, echo, focus imprint |

---

## 2. Lenticular Design Analysis

### Strong Lenticular Examples

**Mourning Chapel** (grief → wisdom)
- Novice: "I put grief here, get wisdom"
- Intermediate: "Near Memory Well (+20%), avoid Rumination Spiral (-30%)"
- Expert: "Grief slowdown affects all nearby buildings, chain with Exercise Yard for cathartic release"

**Memory Processor** (nostalgia → joy OR grief)
- Novice: "Transforms nostalgia"
- Intermediate: "Calm nearby = joy, Tension nearby = grief"
- Expert: "Position near Comfort Hearth, becomes joy engine; near Wound becomes grief factory - strategic choice"

**Grounding Station** (worry + calm → insight)
- Novice: "Combines worry and calm"
- Intermediate: "Inner Critic nearby reduces efficiency (-15%)"
- Expert: "Links Anxiety archetype to Insight archetype - key bridge building"

### Flat Buildings (No Depth)

These buildings have only surface-level reading:

| Building | Current Design | Problem |
|----------|---------------|---------|
| Hope Beacon | Generates hope | No interactions, no choices |
| Emotion Fountain | Generates joy | Description says "randomly generates Joy, Love, or Hope" but generates only joy |
| Pride Monument | Generates pride | No adjacency effects, no synergies |
| Love Shrine | Generates love | No adjacency effects, pride/love underused |
| Memory Archive | Stores 30 | Pure storage, no mechanics |
| Thought Library | Stores 18 | Pure storage |
| Quick Cache | Stores 8 | "Good for active chains" but no actual chain mechanics |
| Deep Storage | Stores 50 | Just bigger storage |
| Bridge | Infrastructure | Identical to Road |
| Highway | 1.5x speed | Speed bonus, but worker pathing unclear |

**Count:** ~15 buildings (31%) have no lenticular depth

### Lenticular Checklist Results

| Criterion | Pass Rate |
|-----------|-----------|
| Obvious use for beginners | 95% |
| Interacts with 3+ elements | 55% |
| Changes draft/selection priorities | 40% |
| Experts "see" something beginners can't | 50% |

### Recommendation: Add Depth to Flat Buildings

```
hope_beacon:
  NEW: "Adjacent to high-grief buildings, generation rate doubles"
  EXPERT SEES: Counter-play against grief spiral, positional puzzle

emotion_fountain:
  NEW: "Random positive emotion, weighted by emotional weather"
  EXPERT SEES: Weather manipulation, timing placement

pride_monument:
  NEW: "Generates Pride when any building completes 5 processes in a day"
  EXPERT SEES: Rewards high-throughput layouts

memory_archive:
  NEW: "Resources stored here don't stagnate, but purity decays faster"
  EXPERT SEES: Trade-off between stagnation and purity systems

quick_cache:
  NEW: "Adjacent processors draw from here first, +20% speed"
  EXPERT SEES: Positioning hub for processing chains
```

---

## 3. Complexity Layering Assessment

### Current Layer Distribution

| Layer | Description | Target | Actual | Buildings |
|-------|-------------|--------|--------|-----------|
| Layer 0 | Vocabulary (basic verbs) | 10-15% | 6% | Road, Emotional Reservoir, Quick Cache |
| Layer 1 | Combinations (2 basics) | 40-50% | 35% | Most generators, basic processors |
| Layer 2 | Conditions (game state dependent) | 25-35% | 45% | Memory Processor, coping buildings, conditional outputs |
| Layer 3 | Build-arounds (strategy-defining) | 10-15% | 14% | Integration Temple, Global Effects, Resilience Monument |

### Problem: Inverted Complexity Pyramid

The game has **too many Layer 2 buildings available early** and **insufficient Layer 0/1 vocabulary**.

**Day 1 unlocks:**
- Road (L0)
- Emotional Reservoir (L0)
- Memory Well (L1)
- Mourning Chapel (L2 - conditional processing, adjacency-sensitive)

**Day 3 unlocks:**
- Morning Routine (L2 - habit system)
- Comfort Hearth (L1)
- Thought Library (L0)
- Quick Cache (L0)
- Bridge (L0)

**Day 5 unlocks:**
- Meditation Garden (L2 - habit + reduction)
- Memory Processor (L3 - conditional output based on neighbors!)
- Curiosity Garden (L1)
- Grounding Station (L2 - multi-input processor)
- Tension Release (L1)
- Journaling Corner (L2)
- Anxiety Diffuser (L1)
- Memory Archive (L0)

**Assessment:** By Day 5, players face 6 Layer 2+ buildings before mastering basics.

### Problem: Layer 3 Buildings Don't Define Strategies

Current global effects are passive multipliers, not build-arounds:

| Building | Effect | Problem |
|----------|--------|---------|
| Optimism Lens | +25% positive generation | Always good, no trade-off |
| Stoic Foundation | -25% negative impact | Always good, no trade-off |
| Creative Core | +50% habit bonus | Always good if you have habits |
| Compassion Center | +30% processing speed | Always good |
| Acceptance Shrine | +20% processing efficiency | Always good |
| Attention Amplifier | +3 attention pool | Always good |

**None of these warp strategy.** Compare to StS: "Snecko Eye" changes your entire card valuation.

### Recommendation: Restructure Complexity Ladder

**New Layer 0 (Start):** Road, Emotional Reservoir, Quick Cache, Thought Library
**New Layer 1 (Day 2-3):** Memory Well, Comfort Hearth, Morning Routine, Tension Release
**New Layer 2 (Day 5-7):** Mourning Chapel, Anxiety Diffuser, Exercise Yard, Meditation Garden
**New Layer 3 (Insight 3+):** Memory Processor, Grounding Station, Integration Temple

**New Build-Around Globals:**
```
optimism_lens:
  CHANGE: "All positive generation +50%, but negative emotions can't be processed"
  STRATEGY: All-in positive generation, avoid negative events

stoic_foundation:
  CHANGE: "Negative emotions deal 50% less wellbeing damage, but derived resources generate 50% slower"
  STRATEGY: Survival focus, slower progression

creative_core:
  CHANGE: "Habits trigger twice daily, but non-habit buildings work 30% slower"
  STRATEGY: Habit-focused build

compassion_center:
  CHANGE: "Processing speed +50%, but coping buildings disabled"
  STRATEGY: Pure processing, no safety net
```

---

## 4. Synergy Web Analysis

### Implicit Archetypes (from adjacency_rules.gd)

| Archetype | Core Mechanic | Enablers | Payoffs | Color |
|-----------|---------------|----------|---------|-------|
| **Grief Processing** | grief → wisdom | Wound, Memory Well | Mourning Chapel, Fear Processing Plant | Purple |
| **Anxiety Management** | anxiety → calm | Worry Loop, Inner Critic | Anxiety Diffuser, Grounding Station, Emergency Calm Center | Teal |
| **Insight Seeking** | thoughts → insight | Rumination Spiral, Curiosity Garden | Reflection Pool, Journaling Corner | Blue |
| **Habit Building** | daily automation | Morning Routine, Exercise Yard | Sleep Chamber, Meditation Garden | Gold |
| **Integration** | derived → meaning | Multiple derived resources | Integration Temple | Iridescent |

### 30-50-20 Distribution Analysis

| Category | Target | Actual | Assessment |
|----------|--------|--------|------------|
| Dedicated archetype | 30% | ~20% | Too few specialists |
| Bridge cards | 50% | ~35% | Weak cross-archetype support |
| Generic value | 20% | ~45% | Too many "good in any deck" |

### Current Adjacency Rules: Only 20 Pairs Defined

**Adjacency coverage by archetype:**
- Grief: 4 rules (Mourning Chapel ↔ Memory Well, ↔ Rumination)
- Anxiety: 5 rules (Anxiety Diffuser ↔ Comfort Hearth, ↔ Grounding)
- Habit: 4 rules (Exercise Yard ↔ Sleep Chamber, Morning Routine ↔ Comfort Hearth)
- Insight: 3 rules (Meditation Garden ↔ Reflection Pool, ↔ Worry Loop)
- Integration: 0 rules (!)

**Missing Critical Bridges:**
- Integration Temple has NO adjacency rules (should bridge all archetypes)
- No bridge between Grief and Insight
- No bridge between Habit and Anxiety
- Positive generators (Hope, Joy, Love, Pride) have NO adjacency interactions

### Recommendation: Add 25 Adjacency Rules

**Integration Temple bridges (new):**
```gdscript
"integration_temple": {
  "mourning_chapel": {"type": SYNERGY, "efficiency": 1.2, "description": "Processed grief enriches meaning"},
  "reflection_pool": {"type": SYNERGY, "efficiency": 1.2, "description": "Insight flows into integration"},
  "gratitude_practice": {"type": SYNERGY, "efficiency": 1.15, "description": "Gratitude grounds meaning"},
  "meditation_garden": {"type": SYNERGY, "efficiency": 1.15, "description": "Stillness allows integration"}
}
```

**Grief ↔ Insight bridge (new):**
```gdscript
"reflection_pool": {
  "mourning_chapel": {"type": SYNERGY, "efficiency": 1.15, "description": "Reflection on grief yields deeper insight"}
}
```

**Habit ↔ Anxiety bridge (new):**
```gdscript
"meditation_garden": {
  "anxiety_diffuser": {"type": SYNERGY, "efficiency": 1.2, "description": "Meditation accelerates anxiety diffusion"}
}
```

**Positive generators need interactions:**
```gdscript
"hope_beacon": {
  "wound": {"type": SYNERGY, "efficiency": 1.3, "description": "Hope shines brighter near darkness"},
  "despair_alchemist": {"type": SYNERGY, "output_bonus": 1, "description": "Hope fuels the transformation"}
},
"love_shrine": {
  "social_connection_hub": {"type": SYNERGY, "efficiency": 1.25, "description": "Connection deepens love"}
}
```

---

## 5. Engine Building Pattern Analysis

### Current Engine Taxonomy

**Passive Generators (12):**
- Memory Well (+nostalgia)
- Comfort Hearth (+calm)
- Curiosity Garden (+curiosity)
- Hope Beacon (+hope)
- Emotion Fountain (+joy)
- Excitement Generator (+excitement)
- Pride Monument (+pride)
- Love Shrine (+love)
- Wound (+grief) - NEGATIVE
- Worry Loop (+anxiety) - NEGATIVE
- Rumination Spiral (+worry) - NEGATIVE
- Inner Critic (+doubt) - NEGATIVE

**Converters (12):**
- Mourning Chapel (grief → wisdom)
- Anxiety Diffuser (anxiety → calm)
- Memory Processor (nostalgia → joy/grief)
- Anger Forge (anger → courage)
- Fear Processing Plant (fear → wisdom)
- Shame Sanctuary (shame → comfort + insight)
- Gratitude Converter (worry + doubt → gratitude)
- Tension Release (tension → calm)
- Rumination Recycler (rumination + worry → insight + calm)
- Reflection Pool (worry + doubt → insight)
- Grounding Station (worry + calm → insight)
- Despair Alchemist (despair + calm → hope + resilience)
- Integration Temple (wisdom + insight + gratitude → meaning)

**Multipliers (6):**
- Optimism Lens (+25% positive gen)
- Stoic Foundation (-25% negative impact)
- Creative Core (+50% habit)
- Compassion Center (+30% processing speed)
- Acceptance Shrine (+20% processing efficiency)
- Resilience Monument (-20% negative decay)

### The Compounding Question: "What if player stacks 3?"

| Element | Stack 3 Effect | Assessment |
|---------|---------------|------------|
| Comfort Hearth | 3 × 0.9 × 0.9 = 2.43x calm | Diminishing, OK |
| Memory Well | 3 × 0.85 × 0.85 = 2.17x nostalgia | Diminishing, OK |
| Worry Loop | 3 × 1.1 × 1.1 = 3.63x anxiety | **COMPOUNDS - PROBLEM** |
| Wound | 3 × 1.05 × 1.05 = 3.31x grief | Slight compound |
| Rumination Spiral | 3 × 1.15 × 1.15 = 3.97x worry | **COMPOUNDS - PROBLEM** |
| Inner Critic | 3 × 1.1 × 1.1 = 3.63x doubt | **COMPOUNDS - PROBLEM** |
| Optimism Lens | 3 × 1.25 = 3.75x? | **NOT ENFORCED UNIQUE** |

### Critical Problem: Asymmetric Stacking

**Positive generators diminish:** 0.85-0.9x per copy
**Negative generators compound:** 1.05-1.15x per copy

This creates runaway negative spirals with no counterplay. If a player gets 3 Worry Loops from events, they face 4x worry generation while their calm generation is capped at 2.4x.

### Recommendation: Fix Stacking Asymmetry

```gdscript
# Change negative generators to diminish like positive ones
static var generator_stacking: Dictionary = {
  "memory_well": 0.85,
  "comfort_hearth": 0.9,
  "worry_loop": 0.9,      # WAS 1.1
  "wound": 0.9,           # WAS 1.05
  "rumination_spiral": 0.85,  # WAS 1.15
  "inner_critic": 0.9     # WAS 1.1
}
```

**Add uniqueness to globals:**
```gdscript
"optimism_lens": {
  "unique": true,  # Only one allowed
  ...
}
```

---

## 6. Resource Manipulation Analysis

### Current Resources: 33 Types (Recommended: 15-20)

**Positive Emotions (9):** joy, love, calm, contentment, pride, hope, gratitude, courage, confidence
**Negative Emotions (11):** grief, anxiety, fear, shame, anger, doubt, worry, despair, loneliness, tension, fatigue
**Neutral (5):** curiosity, surprise, excitement, restlessness, boredom
**Sensations (3):** comfort, nostalgia, rumination
**Derived (4):** wisdom, insight, resilience, meaning
**Conditions (1):** confidence

### Resources with No Processing Chains

| Resource | Sources | Sinks | Problem |
|----------|---------|-------|---------|
| Pride | Pride Monument, Small Victory event | None | Accumulates forever |
| Confidence | Small Victory, The Failure completion | None | Accumulates forever |
| Courage | Anger Forge, The Change event | None | Accumulates forever |
| Contentment | Gratitude Practice, Quiet Moment event | None | Accumulates forever |
| Excitement | Excitement Generator, The Change event | None | Accumulates forever |
| Boredom | Distraction Station side-effect | None | Accumulates forever |
| Restlessness | Restless Night event, Creative Studio consumes | Creative Studio only | Nearly orphaned |
| Loneliness | The Loss event, Social Connection Hub reduces | Social Connection Hub habit | Nearly orphaned |
| Meaning | Integration Temple | None | **END GOAL, NO SINK** |

**9 of 33 resources (27%) have no processing paths.**

### Resource Tension Analysis

| Resource | Abundant | Scarce | Tension |
|----------|----------|--------|---------|
| Calm | 5 generators, 4 processor outputs | Consumed by Grounding Station, Memory Processor condition | Low tension |
| Grief | 3 generators, events | 2 processors (Mourning Chapel, Fear Processing) | High tension |
| Anxiety | 2 generators, events | 2 processors (Anxiety Diffuser, Grounding Station) | High tension |
| Wisdom | 2 processor outputs | Integration Temple input | Medium tension |
| Insight | 5 sources | Integration Temple input, unlock condition | Medium tension |
| Meaning | 1 source | None | **No tension - just accumulates** |

### Recommendation: Consolidate Resources to 20

**Merge:**
- Pride + Confidence + Courage → **Confidence** (self-belief cluster)
- Restlessness + Boredom → **Restlessness** (unfulfilled energy)
- Fear + Anxiety → **Anxiety** (fear is acute anxiety)
- Contentment + Comfort → **Comfort**

**Add processing chains for orphans:**
```gdscript
"self_belief_converter": {
  "input": {"confidence": 3},  # merged Pride/Courage/Confidence
  "output": {"resilience": 1},
  "description": "Self-belief builds lasting resilience"
}

"meaning_radiator": {
  "input": {"meaning": 2},
  "output": {"calm": 3, "wisdom": 1},
  "description": "Meaning flows back into the system"
}
```

---

## 7. Keyword Abstraction Assessment

### Current Keywords: 0 Player-Facing

The game uses **behavior enums** internally:
- GENERATOR, PROCESSOR, STORAGE, CONSUMER, HABIT, COPING, INFRASTRUCTURE, GLOBAL_EFFECT

But players see only descriptions. No standardized vocabulary.

### Hidden Systems with No Vocabulary

Config.gd has 40+ emergent systems that affect gameplay but have no player-visible keywords:

| System | Effects | Player Visibility |
|--------|---------|-------------------|
| Saturation | Joy numbness (0.5x), Grief→wisdom, Anxiety panic | None |
| Resonance | +25% speed for positive clusters, negative amplification | None |
| Momentum | +50% speed at max, break penalty | None |
| Fragility | Building cracking, resource leaking | None |
| Stagnation | Resource decay, transforms (grief→despair) | None |
| Purity | Quality decay, diluted penalty, pure bonus | None |
| Mastery | Specialization bonus, cross-penalty | None |
| Velocity | High/low flow bonuses | None |
| Harmony | Pair bonuses | None |
| Attunement | Neighbor bonding | None |
| Echo | Resource type memory | None |
| Legacy | Long-term imprints | None |
| Weather | 15 parameters affecting everything | Minimal |
| Flow State | Attention threshold, insight chance | None |
| Breakthrough | Window timing, rewards | None |
| Worker Fatigue | Speed penalty, drop chance | None |
| Sync Chains | Multi-building timing bonus | None |

**Players have no vocabulary to discuss or strategize around these systems.**

### Recommendation: Create 8 Player-Facing Keywords

**Tier 1 (Always show in UI):**
1. **Burdened** - "Slowed by accumulated negative emotions"
2. **Spiraling** - "Negative emotions multiplying"
3. **Calm Aura** - "Suppresses spirals, heals fragility"
4. **Flowing** - "Processing at peak efficiency"

**Tier 2 (Show on hover/expert mode):**
5. **Attuned** - "Bonded with neighboring building"
6. **Awakened** - "Building has gained permanent bonuses"
7. **Stagnant** - "Resources aging, quality declining"
8. **Weathered** - "Affected by current emotional weather"

---

## 8. Text Brevity Assessment

### Building Descriptions: PASS

| Building | Words | Assessment |
|----------|-------|------------|
| Road | 8 | Good |
| Mourning Chapel | 8 | Good |
| Memory Processor | 17 | Good |
| Integration Temple | 10 | Good |
| Emergency Calm Center | 10 | Good |

All descriptions under 25 words. Clear and concise.

### Config System Descriptions: NOT EXPOSED

The config.gd has 480+ parameters with no player-facing descriptions. Players can't understand:
- Why efficiency is 0.7x (fragility? grief? doubt? stagnation?)
- What "harmony" means
- Why processing suddenly sped up (momentum? velocity? resonance?)

### Screenshot Test

**Pass:** Building cards are readable
**Fail:** Game state is opaque. A screenshot of gameplay shows buildings with efficiency numbers but no explanation of contributing factors.

---

## 9. Balance Through Constraints Assessment

### Anti-Combo Constraints

**No Triple-Threat Buildings:** PASS
- Buildings do 1-2 things, not everything

**Mutual Exclusivity:** FAIL
- Global effect buildings all stack
- No "choose one" mechanics

**Diminishing Returns:** PARTIAL
- Positive generators: Yes (0.85-0.9x)
- Negative generators: No (1.05-1.15x) - INVERTED
- Global effects: No diminishing returns

**Counter-Synergies:** PASS
- Rumination conflicts Sleep
- Worry conflicts Hope
- Inner Critic conflicts Grounding

### The Playtest Question: "Always Correct to Take?"

| Building | Always Correct? | Assessment |
|----------|-----------------|------------|
| Integration Temple | No (needs inputs) | Good design |
| Optimism Lens | **Yes** | Needs nerf or condition |
| Creative Core | **Yes** (if any habits) | Needs nerf |
| Compassion Center | **Yes** | Needs nerf |
| Acceptance Shrine | **Yes** | Needs nerf |
| Attention Amplifier | **Yes** | Needs nerf |
| Morning Routine | Nearly yes | Low cost, high value |
| Comfort Hearth | Nearly yes | Cheap calm |

**6 of 48 buildings (12.5%) are "always correct" - should be 0%**

### Recommendation: Add Conditions/Downsides

```gdscript
"optimism_lens": {
  "global_effect": {"positive_generation_multiplier": 1.5},
  "downside": {"negative_processing_multiplier": 0.0},
  "description": "All positive generation +50%, but negative emotions cannot be processed"
}

"attention_amplifier": {
  "global_effect": {"attention_bonus": 5},
  "downside": {"habituation_disabled": true},
  "description": "+5 attention, but workers never habituate (costs never decrease)"
}
```

---

## 10. Summary: Critical Issues

### Red Flags Present

| Red Flag | Present? | Evidence |
|----------|----------|----------|
| Element does too many unrelated things | YES | building.gd is 2800+ lines with 35+ subsystems |
| One strategy dominates | UNKNOWN | Needs playtesting |
| Can't understand element in 5 seconds | YES | Hidden mechanics, no keywords |
| Stacking 3x trivializes | PARTIAL | Global effects stack without limit |
| Archetype has no losing matchups | UNKNOWN | Events seem balanced |
| New players overwhelmed | **YES** | 45+ atoms, 33 resources, hidden systems |
| Veterans solved optimal path | UNKNOWN | Too complex to solve mentally |

### Priority Actions

#### P0: Critical (Do First)
1. **Reduce atomic vocabulary from 45 to 16** by consolidating emergent systems
2. **Fix negative generator stacking** (change from compound to diminish)
3. **Add uniqueness to global effect buildings**

#### P1: High (This Sprint)
4. **Restructure unlock progression** - fewer Layer 2 buildings early
5. **Add conditions/downsides to global effects**
6. **Define 5 archetypes explicitly** with visual identity

#### P2: Medium (Next Sprint)
7. **Add 25 adjacency rules** - especially Integration Temple bridges
8. **Create 8 player-facing keywords** with UI support
9. **Add lenticular depth to flat buildings** (Hope Beacon, etc.)
10. **Consolidate resources from 33 to 20**

#### P3: Polish (Month)
11. **Expose complexity to players** - tooltips explaining efficiency factors
12. **Build-defining Layer 3 buildings** with real trade-offs
13. **Playtest archetype balance**

---

## Appendix: Files Referenced

| File | Path | Purpose |
|------|------|---------|
| Building Definitions | `src/data/building_definitions.gd` | 55+ buildings (7 new), all parameters |
| Adjacency Rules | `src/data/adjacency_rules.gd` | 80+ adjacency pairs (60+ new), stacking rules |
| Config | `src/autoload/config.gd` | 496 lines, 40+ @export_groups |
| Event Definitions | `src/data/event_definitions.gd` | 20 events |
| Building Entity | `src/entities/building.gd` | 2800+ lines, all behavior logic |
| Components | `src/components/*.gd` | 25 component files |

---

## Implementation Summary (February 5, 2026)

### Completed Changes (6 commits)

#### Phase 1: Critical Balance Fixes
- [x] Fixed negative generator stacking (now all generators use diminishing returns)
- [x] Added `unique: true` flag to all 6 global effect buildings
- [x] Implemented uniqueness check in building placement

#### Phase 2: Complexity Gating
- [x] Restructured FTUE unlock days (L2 buildings delayed to Day 3+)
- [x] Added activation conditions to global effects:
  - Optimism Lens: requires wellbeing > 40
  - Compassion Center: requires a coping building
  - Creative Core: -15% processing speed trade-off
  - Attention Amplifier: disables habituation trade-off
- [x] Implemented global effects aggregation system in game_state.gd
- [x] Wired worker_system.gd to use global effects

#### Phase 3: Synergy Web Expansion
- [x] Added 60+ new adjacency rules (from 20 to 80+)
- [x] Integration Temple now has 5 synergies
- [x] Cross-archetype bridges implemented:
  - Grief ↔ Insight (reflection_pool + mourning_chapel)
  - Habit ↔ Anxiety (meditation_garden + anxiety_diffuser)
- [x] Positive generators now have interactions (hope_beacon, love_shrine, etc.)
- [x] All 6 coping buildings now have adjacency rules

#### Phase 4: Resource Chain Completion
- [x] Added 7 new buildings to process orphan resources:
  - Self-Belief Forge: pride + courage → resilience
  - Meaning Radiator: meaning → calm + wisdom
  - Excitement Channeler: excitement → curiosity + energy
  - Contentment Garden: contentment → gratitude
  - Confidence Anchor: confidence → wisdom
  - Boredom Alchemist: boredom → curiosity
  - Rest Sanctuary: fatigue → calm
- [x] Quick Cache now gives +20% efficiency to adjacent processors

#### Phase 5: Lenticular Depth
- [x] Hope Beacon: 2x generation when grief is nearby
- [x] Curiosity Garden: +50% when new buildings placed nearby
- [x] Quick Cache: processors_priority, +20% speed for adjacent processors
- [x] Memory Archive: prevents stagnation, +50% purity decay

#### Phase 6: Bidirectional Synergy Rules
- [x] Added 20+ bidirectional adjacency rules ensuring symmetric synergy effects
- [x] Key bidirectional pairs:
  - meditation_garden ↔ reflection_pool, integration_temple, meaning_radiator, anxiety_diffuser
  - curiosity_garden ↔ reflection_pool, excitement_channeler, boredom_alchemist
  - love_shrine ↔ social_connection_hub
  - comfort_hearth ↔ contentment_garden, comfort_den
  - sleep_chamber ↔ rest_sanctuary
  - mourning_chapel ↔ integration_temple
  - gratitude_practice ↔ integration_temple, contentment_garden
  - creative_studio ↔ excitement_channeler, curiosity_garden
  - journaling_corner ↔ integration_temple, reflection_pool
  - resilience_monument ↔ self_belief_forge, hope_beacon

#### Testing
- [x] Added 10 new test functions:
  - test_adjacency_stacking_multiplier_diminishes
  - test_global_effect_buildings_are_unique
  - test_new_orphan_resource_buildings_exist
  - test_quick_cache_has_processor_adjacencies
  - test_integration_temple_has_adjacencies
  - test_coping_buildings_have_adjacencies
  - test_new_orphan_buildings_have_adjacencies
  - test_all_buildings_have_valid_behaviors
  - test_key_bidirectional_adjacencies_exist
  - test_creative_studio_has_adjacencies

### Remaining Work (Phase 5: UI)
- [ ] Add efficiency breakdown tooltip showing contributing factors
- [ ] Add keyword status icons (Burdened, Spiraling, Flowing, etc.)
- [ ] Run full test suite with Godot

### Statistics After Implementation

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Buildings | 48 | 55 | +7 |
| Adjacency Rules | ~20 | 95 | +75 |
| Orphan Resources | 9 | 0 | -9 |
| Global Effects with Conditions | 0 | 4 | +4 |
| Coping Buildings with Adjacencies | 0 | 6 | +6 |
| Bidirectional Rule Pairs | 0 | 15+ | +15 |
| Tests | 25 | 35 | +10 |
