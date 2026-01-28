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
