## FTUE & Progression Evaluation: PsycheBuilder

### Executive Summary

PsycheBuilder has a strong conceptual foundation and thoughtful emotional resonance, but the first-time user experience is overwhelmed by **system complexity exposed too early**. The game introduces 20+ resource types, adjacency effects, habituation, auras, weather systems, and multiple building behaviors simultaneously on Day 1. New players lack clear guidance on the core loop (place building, assign worker, transport resource, process) and face a toolbar with 25+ available buildings without understanding what any of them do. The tutorial hints are brief text tips that don't match the moment-to-moment complexity players face.

### Critical Issues

**1. Information Overload at Game Start**
- **Problem**: 25+ buildings unlocked by default in the toolbar, each with different behaviors (Generator, Processor, Storage, Habit, Coping). New players see a wall of buttons with names like "Grounding Station," "Memory Processor," "Rumination Spiral" without understanding the underlying system.
- **Current State**: No building is marked as "beginner" or "learn this first." The starter buildings (Memory Well, Emotional Reservoir, Morning Routine, Exercise Yard) are automatically placed but not highlighted or explained.
- **Impact**: Players cannot form a mental model of the game before being asked to make meaningful decisions.
- **Recommendation**: Gate building availability. Start with only 4-5 core buildings (Road, Emotional Reservoir, one Generator, one Processor). Unlock building categories progressively (Days 1-3: Infrastructure + Storage, Days 4-6: Generators, Days 7-10: Processors, etc.).

**2. Core Loop Not Demonstrated**
- **Problem**: The how-to-play.md describes controls but doesn't walk through an actual complete action chain. The tutorial hints (`hint_day_1_roads`, `hint_day_2_buildings`, `hint_day_3_workers`) are single sentences that appear as toasts and disappear.
- **Current State**: Day 1 hint says "Tip: Roads connect your buildings. Workers travel along roads to transport resources between buildings." but doesn't show HOW to build a road or WHY you need workers.
- **Impact**: Players don't understand that resources must be TRANSPORTED between buildings via workers on roads. This is the entire core loop.
- **Recommendation**: Implement a forced first-action tutorial: (1) Highlight Memory Well -> (2) Force road placement -> (3) Force worker spawn -> (4) Show resource transport animation -> (5) Celebrate first resource processed.

**3. Resource System Complexity Invisible**
- **Problem**: 30+ resource types with tags (positive, negative, derived, transient, persistent), decay rates, and emotional interactions. Players see a resource list in the HUD but no explanation of WHY positive vs negative matters, or that resources can decay/compound.
- **Current State**: Worry compounds above threshold 3. Anxiety spreads when overflowing. Grief slows buildings. These are HIDDEN mechanics with major gameplay impact.
- **Example**: A player might stockpile Worry in storage without realizing it will multiply, then suddenly face a cascade of compounding Worry they can't process.
- **Recommendation**: Add tooltips that explain resource behaviors: "Worry compounds when you have more than 3. Process it before it multiplies!" Show visual warnings when resources approach danger thresholds.

**4. No Preview of Consequences**
- **Problem**: Building placement has permanent energy cost with no undo. Adjacency effects (synergies/conflicts) are discoverable only AFTER placement by selecting the building.
- **Current State**: Players can see adjacency lines AFTER placement. No preview during placement mode.
- **Impact**: Players make suboptimal placements, learn only through costly experimentation.
- **Recommendation**: Show adjacency preview during placement hover. Display green/red outlines on tiles based on nearby building synergies before committing.

### High Priority Recommendations

**5. Starter Content Teaches Multiple Concepts Simultaneously**
- **Problem**: Starting buildings each teach a different concept:
  - Memory Well (Generator + Storage) - generates Nostalgia
  - Emotional Reservoir (Storage) - holds any resource
  - Morning Routine (Habit) - triggers daily
  - Exercise Yard (Habit + consumer) - uses Energy, reduces Tension
- **Current State**: These are pre-placed but nothing explains the difference between Generator, Processor, Habit, or how they interact.
- **Recommendation**: First run should have ONLY: Road, Storage, one simple Generator (generates one resource type with no conditions), and one simple Processor (transforms A->B). Introduce Habits on Day 2-3 after processing loop is understood.

**6. Wellbeing Formula Hidden**
- **Problem**: Wellbeing is the primary success metric but its calculation (`positive_emotion_weight`, `negative_emotion_weight`, `derived_resource_weight`, etc.) is invisible.
- **Current State**: Players see a number going up or down without understanding WHY.
- **Impact**: Players can't strategize about which resources to prioritize.
- **Recommendation**: Add a Wellbeing breakdown panel accessible from the HUD showing: "+15 from Joy (7 x 2.0)", "-12 from Anxiety (8 x 1.5)", etc. This teaches the formula through observation.

**7. Worker Assignment Requires Implicit Knowledge**
- **Problem**: To assign a worker, you must: (1) Click building with storage, (2) Click "Assign Worker", (3) Click destination building. This requires understanding that buildings have storage, that workers transport between buildings, and that road connectivity matters.
- **Current State**: Day 3 hint says workers "transport resources between buildings" but doesn't explain the assignment UI flow.
- **Recommendation**: The first worker assignment should be a guided interaction with UI highlights and arrows showing the exact click sequence.

**8. Events Spawn Resources With No Warning**
- **Problem**: Events like "The Rejection" spawn 12 Grief + 6 Shame + 4 Anger instantly. Players may not have processors ready.
- **Current State**: Events appear as popups with choice buttons. After choosing, resources appear immediately.
- **Impact**: Early events can overwhelm unprepared players with no recovery path.
- **Recommendation**: Add a pre-event warning around Day 4: "Something challenging is approaching... build some processing capacity." Or spawn inciting incident resources gradually over 2-3 days instead of instantly.

**9. Day/Night Cycle Not Explained**
- **Problem**: Day phase (simulation runs) vs Night phase (paused planning) is a core rhythm but never taught.
- **Current State**: The time display shows phase but nothing explains that Habits trigger at day start, or that Night is for planning.
- **Recommendation**: Day 1 should include explicit phase explanation: "During the Day, buildings work automatically. During the Night, time pauses - plan your next moves!"

### Medium Priority Recommendations

**10. Building Descriptions Use Jargon Without Definition**
- **Problem**: Building tooltips reference mechanics that haven't been introduced.
- **Example**: "Memory Processor: Transforms Nostalgia into Joy when Calm is present, or into Grief when Tension is present." This describes conditional processing that a new player cannot parse.
- **Recommendation**: Add a glossary system where keywords are clickable. Hovering "Calm" shows its definition and current amount.

**11. Habituation System Invisible**
- **Problem**: Worker habituation (1.0 -> 0.5 -> 0.25 -> 0.1 -> 0 attention cost) is a key progression mechanic but has no UI visibility.
- **Current State**: How-to-play mentions habituation levels but the game doesn't show current habituation per worker.
- **Recommendation**: Show habituation progress bar on worker selection. Celebrate when workers reach new habituation levels.

**12. Adjacency System Requires Trial and Error**
- **Problem**: The how-to-play lists specific synergies (Mourning Chapel + Memory Well: +20%) but players must memorize these or experiment.
- **Current State**: Selected buildings show green/red lines but not the actual bonus percentages.
- **Recommendation**: Show adjacency bonuses numerically on selection: "+20% from Memory Well". Better: show all potential synergies in building tooltip before placement.

**13. Discovery System Not Previewed**
- **Problem**: Building discovery (choose 1 of 3 new buildings) is a roguelike reward but nothing explains what unlocking means or what buildings might be available.
- **Current State**: Discovery popup appears after Day 2 with 40% chance. Shows building names and descriptions but no guidance on strategic value.
- **Recommendation**: Early discovery should explicitly state: "These buildings are advanced. You won't see them every run. Choose based on your current needs."

**14. End Screen Provides Statistics, Not Learning**
- **Problem**: Death/end screen shows stats (buildings built, workers, resources) but not insights about what could improve.
- **Current State**: `_format_stats` shows counts only.
- **Impact**: Repeat failures teach nothing.
- **Recommendation**: Add contextual tips: "Your Anxiety peaked at Day 12. Consider building an Anxiety Diffuser earlier next time."

### Low Priority / Polish

**15. Weather System Adds Hidden Complexity**
- The emotional weather system (storm, fog, clear) affects processing speed and generation but has no tutorial explanation. Consider disabling weather effects for runs 1-3 or adding a weather forecast UI.

**16. Aura Visualization Could Be Clearer**
- Calm aura, Tension aura, and Wisdom aura are mentioned in how-to-play but their visual representation (blue/red/purple circles) may blend together. Consider distinct visual languages per aura type.

**17. Building Behavior Icons**
- Toolbar buttons show text only. Adding small icons (gear for processor, clock for habit, shield for coping) would improve at-a-glance scanning.

**18. Speed Controls Unexplained**
- 1x/2x/3x speed buttons exist but new players may not realize they can slow down overwhelming moments.

**19. Resource Color Consistency**
- Positive resources are green-tinted in HUD, negative are red-tinted. This convention should be reinforced in building descriptions and resource item visuals.

### Strengths to Preserve

**1. Mental Health Metaphor is Powerful**
The core thesis - "mental health emerges from the interplay of thoughts, feelings, and behaviors" - translates elegantly into city-builder mechanics. Processing Grief into Wisdom, habituation freeing attention, negative spirals from ignored Worry. This resonates.

**2. No Hard Lose State**
The design decision to have multiple ending tiers rather than game-over is excellent for FTUE. Players can fail forward and still reach narrative closure.

**3. Event Choices Have Meaningful Trade-offs**
Events like "Intrusive Thought" offering "Acknowledge and release" vs "Push it away" with different resource outcomes teaches the CBT framework organically.

**4. Ending Text is Compassionate**
The struggling ending ("Sometimes the weight is too much to bear alone... Be gentle with yourself.") models healthy self-talk and removes shame from poor performance.

**5. Adjacency System Creates Spatial Puzzle**
The synergy/conflict mechanics encourage thoughtful city planning and emergent player-defined districts, even without formal district labels.

**6. Building Diversity Supports Multiple Playstyles**
The building roster supports various strategies: aggressive processing, habituation-focused efficiency, coping-heavy reactive play. This variety is good for replayability once players understand the systems.

---

## Prioritized TODO List

### Critical (Block progression/comprehension)
1. **Gate building toolbar** - Start with 5 buildings, unlock categories progressively over days 1-10
2. **Implement forced first-action tutorial** - Guided sequence for: build road, spawn worker, assign transport, watch processing
3. **Add resource danger threshold warnings** - Visual indicators when Worry > 2, Anxiety > 7, etc.
4. **Add placement preview for adjacency effects** - Show synergy/conflict lines BEFORE placing

### High Priority (Significant confusion likely)
5. **Simplify starter buildings** - Replace Exercise Yard with simple Processor on Day 1
6. **Add Wellbeing breakdown panel** - Clickable to show formula components
7. **Add guided worker assignment tutorial** - UI highlights showing click sequence
8. **Add event warning system** - "Day 4: Something challenging approaches" toast
9. **Explain day/night cycle** - Day 1 popup explaining phase rhythm

### Medium Priority (Suboptimal but functional)
10. **Add keyword glossary system** - Hoverable terms in tooltips
11. **Show habituation progress on workers** - Visual progress bar
12. **Show numerical adjacency bonuses** - "+20% speed" on selection panel
13. **Improve discovery popup guidance** - Strategic tips for new players
14. **Add learning tips to end screen** - Contextual advice based on run data

### Low Priority (Polish)
15. Disable weather system for first 3 runs
16. Improve aura visual distinction
17. Add behavior icons to building buttons
18. Add speed control tutorial
19. Ensure consistent color language throughout
