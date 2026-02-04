# TIGHTNESS AUDIT: PsycheBuilder

## TIGHTNESS AUDIT SUMMARY

```
Game/System: PsycheBuilder (Mind-City Builder)
Mechanics Audited: 35+
Systems Discovered: 56 buildings, 32 resources, 19 events, 480+ config parameters

OVERALL TIGHTNESS: LOOSE (Broken in some areas)

By Layer:
  Core Mechanics:      [██████████] 85% Tight
  Intermediate:        [████░░░░░░] 40% LOOSE
  Meta Systems:        [██░░░░░░░░] 20% BROKEN (too many hidden systems)
```

---

## MECHANIC INVENTORY

### CORE MECHANICS

| Mechanic | Action | Expected Result | Critical Path |
|----------|--------|-----------------|---------------|
| Building Placement | Click grid | Building appears | Yes |
| Road Connection | Place roads adjacent | Buildings become connected | Yes |
| Worker Assignment | Click source, click dest | Worker transports resources | Yes |
| Basic UI Interaction | Click buttons | Building selected/placed | Yes |

### INTERMEDIATE SYSTEMS

| Mechanic | Action | Expected Result | Critical Path |
|----------|--------|-----------------|---------------|
| Processing | Provide inputs | Outputs generated | Yes |
| Storage | Resources delivered | Resources held | Yes |
| Generation | Building exists | Resources spawn | Yes |
| Coping | Threshold reached | Emergency processing | No |
| Habituation | Repeat worker jobs | Cost decreases | No |
| Adjacency | Place buildings near each other | Efficiency changes | No |
| Day/Night Cycle | Time passes | Phases change | Yes |

### META SYSTEMS (30+ systems affecting outcomes)

| System | Visibility | Config Params |
|--------|-----------|---------------|
| Wellbeing Tiers | Partial | 12 params |
| Emotional Weather | Hidden | 15 params |
| Building Awakening | Partial | 6 params |
| Flow State | Hidden | 9 params |
| Resource Purity | Hidden | 12 params |
| Harmony/Attunement | Partial | 12 params |
| Building Mastery | Partial | 7 params |
| Resource Velocity | Hidden | 11 params |
| Legacy Imprints | Hidden | 6 params |
| Emotional Momentum | Hidden | 8 params |
| Support Networks | Hidden | 6 params |
| Saturation Effects | Hidden | 10 params |
| Fragility/Cracking | Hidden | 10 params |
| Stagnation/Decay | Hidden | 9 params |
| Emotional Echo | Hidden | 6 params |
| Resonance | Hidden | 8 params |
| Beliefs | Hidden | 10 params |
| Sync Chains | Hidden | 7 params |
| Road Memory | Hidden | 8 params |
| Processing Cascades | Hidden | 4 params |
| Breakthrough System | Hidden | 10 params |
| Worker Fatigue | Hidden | 9 params |
| Attention Echoes | Hidden | 6 params |
| Overflow Transmutation | Hidden | 8 params |
| Nostalgia Crystallization | Hidden | 5 params |

---

## DETAILED AUDIT

### CORE MECHANICS

```
 Building Placement [TIGHT - 42/50]
  + Instant response on click
  + Visual confirmation (building appears)
  + Cost shown in UI
  + Grid highlights placement
  - No preview of adjacency effects before placing
  - No undo functionality
```

```
 Road Connection [TIGHT - 40/50]
  + Visual "disconnected" warning on buildings
  + Roads visually distinct
  + Pathfinding works consistently
  - No preview of connection before placing
  - Emotional memory system is hidden
```

```
 Worker Assignment [ACCEPTABLE - 35/50]
  + Workers visually move
  + Source/destination clear
  + Attention cost shown
  - 15+ hidden speed modifiers on worker movement
  - Habituation progress not shown
  - Worker fatigue completely hidden
```

### INTERMEDIATE SYSTEMS

```
 Processing Buildings [LOOSE - 25/50]
  + Progress bar visible
  + Status indicator color-coded
  + Input/output shown in tooltip
  
  CRITICAL PROBLEM: 25 hidden multipliers affect speed!
  From building.gd line 430, processing speed affected by:
    1. grief_multiplier
    2. tension_multiplier
    3. wisdom_multiplier
    4. doubt_multiplier
    5. resonance_multiplier
    6. momentum_multiplier
    7. support_network_multiplier
    8. weather_modifier
    9. belief_modifier
    10. awakening_multiplier
    11. breakthrough_modifier
    12. fatigue_multiplier
    13. echo_multiplier
    14. harmony_multiplier
    15. flow_multiplier
    16. purity_multiplier
    17. attunement_multiplier
    18. fragility_multiplier
    19. stagnation_multiplier
    20. mastery_multiplier
    21. velocity_multiplier
    22. wellbeing_modifier
    23. sync_chain_multiplier
    24. legacy_multiplier
    25. adjacency_multiplier

  Player has NO WAY to know why processing is fast or slow.
```

```
 Storage System [ACCEPTABLE - 33/50]
  + Storage counts shown on buildings
  + Capacity visible
  + Overflow spawns resources visually
  - Purity system hidden (only * or ~ indicator)
  - Stagnation completely hidden
  - Age of resources hidden
```

```
 Adjacency System [LOOSE - 28/50]
  + Some synergy pairs documented in adjacency_rules.gd
  + Color-coded lines in debug mode
  - No preview when placing buildings
  - Effects not visible during gameplay
  - Harmony/attunement buildup invisible
  - "Why is this building slow?" unanswerable
```

```
 Day/Night Cycle [TIGHT - 40/50]
  + Clear phase indicator
  + Clock display
  + Day counter
  + Speed controls work
  - Night phase purpose unclear
  - Dream recombination hidden
```

### META SYSTEMS

```
 Wellbeing Score [LOOSE - 24/50]
  + Big number displayed
  + Color changes based on level
  - Formula involves 7+ weighted factors
  - Changes seem unpredictable
  - "Why did wellbeing go down?" unanswerable
  
  Formula from config.gd:
    positive_emotion_weight: 2.0
    negative_emotion_weight: 1.5
    derived_resource_weight: 3.0
    unprocessed_negative_weight: 2.0
    habit_building_weight: 1.0
    adjacency_synergy_weight: 0.5
    wellbeing_normalizer: 50.0
```

```
 Emotional Weather [BROKEN - 12/50]
  - Completely invisible to player
  - 5 weather states (storm, overcast, fog, stillness, clear)
  - Each affects generation and processing differently
  - No UI element shows weather state
  - Player cannot predict or plan around weather
```

```
 Flow State [BROKEN - 15/50]
  - Hidden system with 9 parameters
  - Requires 30% attention remaining + 3 active buildings
  - Builds up invisibly
  - Can generate insight with no apparent cause
  - Player never knows they're "in flow"
```

```
 Resource Purity [LOOSE - 22/50]
  + Tiny indicator (* for pure, ~ for diluted)
  - Decay rate invisible
  - Transfer loss invisible
  - Refining mechanic completely hidden
  - Awakened buildings refine faster - who knows?
```

```
 Building Awakening [LOOSE - 26/50]
  + "Awakened" label visible after threshold
  - Progress to awakening invisible
  - 20 process cycles required (config)
  - Benefits not explained in game
```

```
 Mastery System [LOOSE - 22/50]
  + Small indicator (+1, +2, +3, +4, !)
  - Thresholds: [10, 30, 60, 100] cycles - invisible
  - Cross-type penalty exists - invisible
  - Specialization threshold - invisible
```

```
 Velocity System [BROKEN - 10/50]
  - Completely invisible
  - Tracks resource throughput over 10-second windows
  - High velocity = speed bonus
  - Low velocity = speed penalty
  - Sustained high velocity grants burst bonus
  - Player has no access to any of this information
```

```
 Stagnation System [BROKEN - 12/50]
  - Resources age over time (invisible)
  - After 20 seconds, stagnation builds (invisible)
  - Stagnant resources transform: grief->despair, joy->nostalgia
  - Fresh resources get 20% bonus (invisible)
  - Player never knows why grief became despair
```

```
 Events System [ACCEPTABLE - 32/50]
  + Event popup shows clearly
  + Choices presented with descriptions
  + Resources spawned are visible
  - Completion conditions only partially shown
  - Weather/state changes from events unclear
```

---

## CRITICAL TIGHTNESS PROBLEMS

### Problem 1: The "25 Multiplier Problem"

**Location:** `/home/user/godot-sketches/jan_28_2026-psychebuilder-ai/src/entities/building.gd` lines 405-430

**Symptom:** Players cannot understand why buildings process at different speeds.

**Analysis:** Processing speed is a product of 25 different multipliers, most of which are completely invisible to the player. A building might process 3x faster or 5x slower than expected with zero feedback about why.

**Impact:** Player cannot form mental model. Cannot strategize. Feels random.

### Problem 2: Hidden Meta Systems

**Location:** `config.gd` - 480+ parameters across 30+ export groups

**Symptom:** Game has rich emergent systems that players never discover.

**Analysis:** Systems like Emotional Weather, Flow State, Velocity, Stagnation, and Purity exist but have ZERO UI representation. Players cannot see, predict, or plan around these systems.

**Impact:** Wasted design effort. Players don't engage with depth. Confusion when effects manifest.

### Problem 3: Wellbeing Black Box

**Location:** Wellbeing calculation in game_state.gd

**Symptom:** Wellbeing changes feel arbitrary.

**Analysis:** 7-factor weighted formula with no breakdown shown to player. Negative emotion weight (1.5) vs unprocessed weight (2.0) vs derived weight (3.0) - player cannot optimize what they cannot see.

**Impact:** Main score feels meaningless. No strategic depth.

### Problem 4: "Why Did That Happen?" Problem

**Symptom:** Multiple systems trigger effects with no attribution.

**Examples:**
- Grief transforms to despair (stagnation - invisible)
- Joy spreads to neighbors (saturation - invisible)
- Buildings crack and leak (fragility - invisible)
- Random insight appears (flow state + sync chains - invisible)
- Processing slows down (could be 15+ different reasons)

---

## RECOMMENDED FIXES

### CRITICAL (Breaking player learning)

**1. Add Processing Speed Breakdown UI**
```
When hovering a processing building, show:
"Processing Speed: 1.8x
  + Awakened: +50%
  + Harmony: +20%
  - Fatigue: -10%
  - Weather (Storm): -25%
  Base time: 4.0s -> Actual: 2.2s"
```
**Effort:** Medium (UI work + aggregation logic)
**Impact:** Players can finally understand the core system

**2. Show Emotional Weather**
```
Add weather indicator to HUD:
[Sun icon] Clear - Processing +15%, Joy +20%
[Cloud icon] Overcast - Grief generation +15%
[Storm icon] Storm - Processing -25%, Negatives +30%
```
**Effort:** Low (UI element + existing data)
**Impact:** Players can plan around weather

**3. Show Flow State**
```
Add flow meter:
"Flow: [====----] 45%
  Attention available: 42%
  Active buildings: 4/3 required
  Effect: +18% speed, generating insight"
```
**Effort:** Low-Medium
**Impact:** Reveals rewarding system players never see

### HIGH (Degrading game feel)

**4. Simplify Multiplier Stack**
Consider reducing from 25 multipliers to categories:
- Base Speed
- Building State (awakened, fatigued, cracked)
- Environment (weather, wellbeing tier)
- Synergy (adjacency, harmony, attunement)
- Resource Quality (purity, freshness)

Show each category, hide individual multipliers.

**Effort:** High (system refactor)
**Impact:** Makes system learnable

**5. Add Wellbeing Breakdown**
```
"Wellbeing: 45
  Positive emotions: +18
  Negative emotions: -12
  Derived resources: +15
  Unprocessed negatives: -8
  Active habits: +5
  Adjacency synergies: +2"
```
**Effort:** Low (UI only)
**Impact:** Main score becomes meaningful

**6. Visual Feedback for Hidden States**
- Stagnating resources: Dim/desaturate their color
- High purity: Sparkle effect
- Velocity high: Animated "whoosh" lines
- Flow state: Subtle glow on whole city
- Building cracked: Visual cracks on sprite

**Effort:** Medium (visual work)
**Impact:** Many systems become discoverable

### MEDIUM (Polish)

**7. Predictive Placement UI**
When holding a building to place, show:
- Adjacency effects that will apply
- Expected synergies/conflicts
- Connection status preview

**Effort:** Medium
**Impact:** Strategic placement becomes possible

**8. Resource Tooltips**
Hovering any resource shows:
- Age (fresh/normal/stagnating)
- Purity level
- What it can transform into
- Which buildings can process it

**Effort:** Low
**Impact:** Resource system becomes learnable

**9. Building Experience Bars**
Show progress toward:
- Awakening (0/20 cycles)
- Mastery levels (0/10 -> 10/30 -> etc.)
- Habituation for assigned workers

**Effort:** Low
**Impact:** Progression becomes visible

---

## QUICK WINS (Low effort, high impact)

### 1. Add Weather Display
**Currently:** Completely hidden
**Add:** Simple text label: "Weather: Clear" with tooltip explaining effects
**Effort:** 1-2 hours

### 2. Show Why Processing is Slow
**Currently:** Just a progress bar
**Add:** When processing seems slow, show dominant negative modifier
**Effort:** 2-4 hours

### 3. Wellbeing Hover Breakdown
**Currently:** Just a number
**Add:** Hover tooltip with factor breakdown
**Effort:** 2-3 hours

### 4. Stagnation Visual Warning
**Currently:** Resources silently transform
**Add:** Resources that are stagnating show a "fading" effect
**Effort:** 3-4 hours (shader or modulate)

### 5. Flow State Indicator
**Currently:** Hidden bonus
**Add:** Small "FLOW" badge when active
**Effort:** 1-2 hours

### 6. Building Status Tooltips
**Currently:** Status shown but not explained
**Add:** "Waiting for input" + "Needs: 2 grief, 0/2 available"
**Effort:** 2-3 hours

---

## TODO LIST FOR TIGHTNESS IMPROVEMENTS

```
CRITICAL PRIORITY:
[ ] Add processing speed breakdown tooltip showing all active modifiers
[ ] Create weather indicator UI element  
[ ] Add flow state meter/indicator to HUD
[ ] Implement wellbeing breakdown on hover

HIGH PRIORITY:
[ ] Group multipliers into 5 categories for display
[ ] Add visual indicators for stagnation (dimming)
[ ] Add visual indicators for purity (sparkles)
[ ] Add visual indicators for fragility (cracks)
[ ] Show building awakening progress bar

MEDIUM PRIORITY:
[ ] Add predictive adjacency preview when placing buildings
[ ] Implement resource hover tooltips with age/purity/processing info
[ ] Add mastery progress indicators to buildings
[ ] Show habituation progress for worker assignments
[ ] Add velocity indicator for high-throughput buildings

POLISH:
[ ] Create "why is this slow?" diagnostic when clicking slow buildings
[ ] Add sound feedback for state changes (entering flow, weather changing)
[ ] Show sync chain formation visually with connecting lines
[ ] Add tutorial hints explaining hidden systems as they trigger
```

---

## SUMMARY

PsycheBuilder has deep, thoughtful systems that model psychological processes beautifully. However, **the game currently fails the core tightness test: players cannot form accurate mental models of how the game works.**

The 25-multiplier processing speed calculation exemplifies the problem: emergent complexity has created an opaque black box. The game has MANY more systems than it can communicate to players.

**Recommended Approach:**
1. Immediately surface the most impactful hidden systems (weather, flow, stagnation)
2. Create aggregated feedback that shows WHY things happen
3. Reduce cognitive load by grouping related modifiers
4. Add visual language for currently-invisible states
5. Consider which systems add enough value to justify their complexity

The metaphor of "building a mind" is powerful, but players need to see and understand that mind to care about it.