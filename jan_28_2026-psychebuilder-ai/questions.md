# Design Questions

## Game Mechanics

### Resource Physicality
Q: The spec says resources are "physical items that exist in the game world" and must be transported. But for a city-builder metaphor of the mind, does this make sense?
- Having to manually route Grief to a Mourning Chapel might feel like busywork
- Alternative: Resources could auto-flow to connected buildings, with roads determining throughput
- Which feels better for the "attention is limited" metaphor?

### Storage vs Processing Flow
Q: Should resources sit in storage waiting to be processed, or should they flow automatically to available processors?
- Factorio-style: explicit routing, satisfaction from optimization
- Anno-style: auto-distribution with capacity limits
- The spec mentions workers carrying resources - is this necessary micro-management or meaningful choice?

### Worker Assignment Granularity
Q: The habituation system tracks per-job completions. But what counts as a "job"?
- Is "carry grief from anywhere to Mourning Chapel" one job?
- Is "carry grief from Memory Well specifically to Mourning Chapel" a different job?
- This affects how quickly habits form and how much micro-management is needed

### Negative Emotion Pressure
Q: How threatening should negative emotions be?
- Too passive: player ignores them, no tension
- Too aggressive: feels punishing, not therapeutic
- The spec says no hard lose state, but what creates urgency?

### Day/Night Usefulness
Q: During night/planning phase, what should players actually do?
- Just place buildings?
- Review metrics?
- Make strategic decisions about next day?
- Risk: night phase becomes "press button to skip"

## Visual Design

### Resource Representation
Q: Resources as colored circles is placeholder. Final form options:
- Orbs of light (Inside Out style)
- Abstract geometric shapes
- Symbolic icons (heart for love, cloud for worry)
- Which conveys the psychological metaphor best?

### Building Aesthetics
Q: Buildings could be:
- Neural/organic (neurons, synapses)
- Architectural (temples, gardens, workshops)
- Abstract (glowing structures)
- Mixed (organic architecture)

## Scope Concerns

### Building Count
Q: Spec lists 50 buildings. For prototype, which subset is essential?
- Minimum viable: 1 generator, 1 processor, 1 storage, 1 habit, road
- Recommended prototype: ~10-15 buildings covering each behavior type
- Which specific buildings best demonstrate the core loop?

### Event Complexity
Q: Events with choices and completion conditions add significant complexity.
- Start simple: events just spawn resources?
- Or: choices are essential to the "mind making decisions" theme?

---

## Questions from Implementation (Phases 10-18)

### Event Balance
Q: How overwhelming should inciting incidents be?
- Current tuning reduced spawn amounts by ~20-25% from original spec
- Completion conditions loosened to be more achievable
- Should events feel like "crises to survive" or "challenges to grow from"?
- The therapeutic framing suggests the latter, but tension is needed for engagement

### Adjacency Discovery
Q: How should players discover adjacency synergies/conflicts?
- Currently: lines appear when building is selected
- Alternative: tooltips explain synergies before placement
- Alternative: dedicated "adjacency guide" UI panel
- Risk: players ignore it and miss a core mechanic

### Discovery System Frequency
Q: Current settings: 40% chance each night after day 2, offering 3 buildings
- Is this too frequent? Player might unlock everything quickly
- Is this too rare? Player might feel stuck with limited options
- Should discoveries be guaranteed after inciting incidents?

### Tutorial Depth
Q: Current tutorial is 3 text hints on days 1-3
- Day 1: Roads, Day 2: Buildings, Day 3: Workers
- Is this enough for new players to understand the core loop?
- Should there be a dedicated tutorial level before the main game?
- Risk of over-tutorialization vs confusion

### Wellbeing Formula Visibility
Q: The wellbeing calculation is complex (6+ weighted factors)
- Should players see the exact formula?
- Should there be a breakdown showing what's contributing positively/negatively?
- Currently it's a single number - is that sufficient feedback?

### Event Completion Tracking
Q: Events with completion conditions persist until resolved
- What if player can't complete them? (e.g., lacks processing buildings)
- Should there be a timeout or failure state?
- Should incomplete events carry over to affect the ending?

### Starting Resources Location
Q: Starting resources (5 Calm, 3 Tension, 2 Worry) are placed in first storage building
- Should they spawn as floating items instead?
- Should they be distributed across multiple buildings?
- Does starting with resources in storage teach the wrong lesson about the game flow?

### Global Effect Building Strategy
Q: Global effect buildings are powerful but late-game
- Currently unlocked through discovery or insight thresholds
- Should some be available earlier to define playstyle?
- Risk: early global effects might be too dominant

### Resource Decay vs Persistence
Q: Some resources decay quickly (transient), others persist
- Current decay happens daily based on decay_rate
- Should decay be more visible to players?
- Should there be warning when valuable resources are about to decay?

### Night Phase Interactivity
Q: Night phase currently has:
- Discovery popups (40% chance)
- Dream recombinations (configurable)
- Worker fatigue recovery
- Is this enough meaningful activity or still "press button to skip"?

### Multiple Playthrough Variety
Q: Roguelike variety comes from:
- Random inciting incident selection
- Random minor events
- Random building discoveries
- Is this enough variety for replay value?
- Should there be different starting archetypes with distinct palettes?

### Processor Input Flexibility
Q: Some processors need specific resource combinations (e.g., Reflection Pool needs Worry + Doubt)
- What if player only has one of the inputs?
- Should there be single-input alternatives for common scenarios?
- Risk: too many building options = analysis paralysis
