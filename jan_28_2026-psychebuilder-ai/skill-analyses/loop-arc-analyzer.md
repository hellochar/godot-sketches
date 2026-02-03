# Loop-Arc Analysis: PsycheBuilder

## Game Summary

PsycheBuilder is a city-builder metaphor for mental health where players place buildings that generate/process emotional resources, assign workers to transport resources, and manage energy/attention pools over a 20-day run. Events challenge players with emotional waves, and the goal is maximizing wellbeing.

---

## CONTENT INVENTORY

### Content Type: Core Building/Resource Loop
- **Category:** Gameplay
- **Quantity:** ~55 buildings, ~30 resource types
- **Player Hours:** Infinite (core loop repeats throughout 20-day run, ~17-25 min per run)
- **Loop or Arc:** LOOP

### Content Type: Worker Assignment & Habituation
- **Category:** Gameplay/Progression
- **Quantity:** 5 habituation tiers (New -> Automatic)
- **Player Hours:** Per-run progression (~20 min)
- **Loop or Arc:** WEAK LOOP (hybrid)

### Content Type: Day/Night Cycle (20 days)
- **Category:** Structure
- **Quantity:** 20 days per run (50s day + 8s night each)
- **Player Hours:** ~20 min per run
- **Loop or Arc:** LOOP (structure for repeating content)

### Content Type: Inciting Incidents
- **Category:** Narrative/Challenge
- **Quantity:** 7 unique incidents (the_rejection, the_loss, the_failure, the_overwhelm, the_betrayal, the_change)
- **Player Hours:** ~3-5 min each (processing time), consumed once per type
- **Loop or Arc:** ARC (one per run, variety across runs)

### Content Type: Minor Events
- **Category:** Narrative/Gameplay
- **Quantity:** 14 minor events
- **Player Hours:** ~30 seconds each, random recurrence
- **Loop or Arc:** WEAK LOOP (can repeat across runs)

### Content Type: Building Unlocks
- **Category:** Progression
- **Quantity:** ~30 unlockable buildings
- **Player Hours:** Discovered during runs
- **Loop or Arc:** ARC (unlock once, though discovery is procedural)

### Content Type: Endings
- **Category:** Narrative
- **Quantity:** 4 endings (Flourishing, Growing, Surviving, Struggling)
- **Player Hours:** ~1 min reading
- **Loop or Arc:** ARC (consumed per threshold)

### Content Type: Emergent Systems
- **Category:** Gameplay/Meta
- **Quantity:** 25+ interacting systems (emotional weather, breakthroughs, mastery, saturation, etc.)
- **Player Hours:** Continuous during play
- **Loop or Arc:** LOOP (create emergent variety)

---

## CONTENT CLASSIFICATION

### Building/Resource System
```
1. Can this be repeated for value?
   [X] Yes, player gains skill/mastery -> LOOP
   
2. What provides the value?
   [X] Player getting better at something -> LOOP
   
3. How does difficulty/challenge work?
   [X] Procedurally varies -> LOOP (events inject different challenges)
   
4. What's the content cost model?
   [X] Create system once, infinite plays -> LOOP

VERDICT: LOOP
REPLAYABILITY: High
```

### Worker Habituation System
```
1. Can this be repeated for value?
   [X] Yes, but diminishing returns -> WEAK LOOP
   
2. What provides the value?
   [X] Both equally -> HYBRID (mastery AND completion thresholds)
   
3. How does difficulty/challenge work?
   [X] Scales with player skill -> LOOP
   
4. What's the content cost model?
   [X] Create system once, infinite plays -> LOOP

VERDICT: HYBRID (resets each run, mastery across runs)
REPLAYABILITY: Medium-High
```

### Inciting Incidents
```
1. Can this be repeated for value?
   [X] Yes, but diminishing returns -> WEAK LOOP
   
2. What provides the value?
   [X] Discovering new content -> ARC (first encounter)
   [X] Player getting better at handling -> LOOP (subsequent runs)
   
3. How does difficulty/challenge work?
   [X] Fixed, one-time challenge -> ARC (discovery)
   [X] Scales with player skill -> LOOP (mastery)
   
4. What's the content cost model?
   [X] Linear with playtime -> ARC (7 incidents = 7 "fresh" experiences)

VERDICT: HYBRID (strong arc on first encounter, weak loop after)
REPLAYABILITY: Medium (7 variants provide ~7 fresh runs)
```

### Minor Events
```
1. Can this be repeated for value?
   [X] Yes, but diminishing returns -> WEAK LOOP
   
2. What provides the value?
   [X] Both equally -> HYBRID
   
3. How does difficulty/challenge work?
   [X] Procedurally varies -> LOOP
   
4. What's the content cost model?
   [X] Create system once, infinite plays -> LOOP

VERDICT: WEAK LOOP
REPLAYABILITY: Medium
```

### Endings
```
1. Can this be repeated for value?
   [X] No, consumed once -> ARC
   
2. What provides the value?
   [X] Discovering new content -> ARC
   
3. How does difficulty/challenge work?
   [X] Fixed, one-time challenge -> ARC
   
4. What's the content cost model?
   [X] Linear with playtime -> ARC

VERDICT: ARC
REPLAYABILITY: Low (4 endings, then seen all)
```

### Building Unlocks/Discovery
```
1. Can this be repeated for value?
   [X] No, consumed once -> ARC (unlock)
   [X] Yes, procedurally varies -> LOOP (discovery selection)
   
2. What provides the value?
   [X] Discovering new content -> ARC
   
3. How does difficulty/challenge work?
   [X] Fixed, one-time challenge -> ARC
   
4. What's the content cost model?
   [X] Linear with playtime -> ARC

VERDICT: ARC
REPLAYABILITY: None (once unlocked, done)
```

### Emergent Systems (Weather, Breakthroughs, Mastery, etc.)
```
1. Can this be repeated for value?
   [X] Yes, player gains skill/mastery -> LOOP
   
2. What provides the value?
   [X] Player getting better at something -> LOOP
   
3. How does difficulty/challenge work?
   [X] Procedurally varies -> LOOP
   
4. What's the content cost model?
   [X] Create system once, infinite plays -> LOOP

VERDICT: LOOP
REPLAYABILITY: High
```

---

## RATIO CALCULATION

### Total Estimated Player Hours (First Playthrough)
- Single run: ~20 minutes
- Full content discovery: ~10 runs (~3.5 hours)
- Mastery plateau: ~20-30 runs (~7-10 hours)

### LOOP CONTENT
| Content | Hours (per run) | Loop Quality |
|---------|-----------------|--------------|
| Building/Resource System | 15 min | Strong Loop |
| Worker Habituation | 5 min | Weak Loop |
| Minor Events | 3 min | Weak Loop |
| Emergent Systems | 5 min | Strong Loop |
| **Loop subtotal** | **~28 min/run** | |

### ARC CONTENT  
| Content | Hours (total) | Arc Quality |
|---------|---------------|-------------|
| Inciting Incidents (7) | 35 min total | Strong Arc (first) / Weak Loop (repeat) |
| Building Unlocks | 3 hours | Strong Arc |
| Endings (4) | 10 min | Strong Arc |
| **Arc subtotal** | **~4 hours** | |

### HYBRID CONTENT
| Content | Hours | Hybrid Quality |
|---------|-------|----------------|
| Inciting Incidents (mastery) | Ongoing | Loop after Arc consumed |
| Habituation progression | Ongoing | Loop with Arc thresholds |

---

## CONTENT RATIO ANALYSIS

```
CONTENT STRUCTURE
=================

Per-Run Breakdown (20 min run):
  Loop Content:    ~14 min  (70%)
  Arc Content:     ~3 min   (15%)  [events/choices on first encounter]
  Hybrid Content:  ~3 min   (15%)

Full Experience (until content exhausted ~4 hours):
  Loop Content:    ~3 hours (75%)
  Arc Content:     ~1 hour  (25%)

REPLAYABILITY RATIO: 70-75%
```

```
CONTENT COMPOSITION
===================

[██████████████████████████████████████░░░░░░░░░░░░] 75% Loops
[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████████████] 25% Arcs

[██████████████████████████████████████████████████] 95% Core
[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░█] 5% Filler
```

---

## FILLER IDENTIFICATION

| Content Type | Enjoyment | Necessity | Uniqueness | Filler Score |
|--------------|-----------|-----------|------------|--------------|
| Building System | 4 | 5 | 5 | -1 (Core) |
| Worker Transport | 3 | 5 | 4 | 0 (Core) |
| Events | 4 | 4 | 4 | 0 (Core) |
| Habituation | 3 | 4 | 4 | 0 (Core) |
| Day/Night Cycle | 3 | 4 | 3 | 1 (Borderline) |
| Building Unlocks | 4 | 3 | 3 | -1 (Core) |
| Emergent Systems | 4 | 3 | 5 | -1 (Core) |
| Endings | 3 | 3 | 3 | 0 (Core) |
| Night Phase Waiting | 2 | 3 | 2 | 1 (Borderline) |

**Verdict:** Very little filler. Night phase (8 seconds of pause) could feel like waiting but is brief. The game is dense with meaningful systems.

---

## BUSINESS MODEL FIT

| Business Model | Ideal Loop/Arc Ratio | Current Ratio | Fit |
|---------------|----------------------|---------------|-----|
| **Premium (one-time purchase)** | 30-50% loops | 75% | Moderate |
| **Live Service** | 70-90% loops | 75% | Good fit |
| **Free-to-Play** | 80%+ loops | 75% | Moderate |
| **Arcade/Session** | 90%+ loops | 75% | Moderate |
| **Narrative Focus** | 10-30% loops | 75% | Poor fit |

```
BUSINESS MODEL ANALYSIS
=======================

Current structure: 75% loops / 25% arcs

FIT BY MODEL:
  Premium:      ██████░░░░ Moderate (has more loops than typical premium)
  Live Service: ████████░░ Good fit (ideal 70-90% loops)
  F2P:          ███████░░░ Moderate (needs 80%+ loops)
  Narrative:    ███░░░░░░░ Poor fit (too many loops)
  Arcade:       ███████░░░ Good fit (short sessions, repeatable)

RECOMMENDATION: Best suited for premium roguelike release with potential for
                live service content drops (new events, buildings, archetypes).
```

---

## DEEP ANALYSIS: What Makes Loops Work Here

### Strong Loop Elements

1. **Resource Economy Loop** (Every 1-10 seconds)
   - Generate -> Transport -> Process -> Store -> Transform
   - Infinite variation from building placement decisions
   - Clear feedback on efficiency

2. **Spatial Optimization Loop** (Every placement)
   - Adjacency bonuses reward thoughtful layout
   - Road networks create pathing puzzles
   - Building connections create emergent efficiency

3. **Crisis Management Loop** (Event-driven)
   - Negative resources spawn, must be processed
   - Coping buildings activate reactively
   - Creates engaging pressure cycles

4. **Attention Budget Loop** (Per assignment)
   - Limited workers, must optimize
   - Habituation rewards commitment
   - Trade-offs create meaningful choices

### Weak Loop Elements (Opportunities)

1. **Habituation** - Currently resets each run. Could persist as meta-progression.

2. **Building Discovery** - Currently random offering. Could add roguelike "synergy hunting" where combinations unlock.

3. **Event Handling** - After seeing all 7 incidents, becomes routine. Could add more incidents or dynamic event generation.

---

## RECOMMENDATIONS

### TO INCREASE LOOP VALUE (for extended play)

```
CONTENT STRATEGY RECOMMENDATIONS
================================

ADD PROCEDURAL CHALLENGE MODES:
- [ ] Endless mode after day 20 (escalating event intensity)
- [ ] Daily challenge seed (same start state, leaderboard)
- [ ] Challenge modifiers (no coping buildings, double anxiety, etc.)

ADD SYSTEM DEPTH:
- [ ] Multiple archetypes with distinct starting conditions
- [ ] Building upgrade tiers (awakened buildings have different behaviors)
- [ ] Resource purity/quality system (already in config, not visible)

ADD META-PROGRESSION:
- [ ] Persistent habituation unlocks across runs
- [ ] Achievement-based starting bonuses
- [ ] Unlock new inciting incidents through play
```

### TO IMPROVE ARC VALUE (for first 5 runs)

```
IMPROVE FIRST-RUN EXPERIENCE:
- [ ] Stronger narrative framing for inciting incidents
- [ ] More distinct event choices with lasting consequences
- [ ] Building unlock celebrations (show what you earned)

ADD MORE ARCS:
- [ ] Character/archetype backstories
- [ ] Event chains (failure -> recovery arc over multiple days)
- [ ] Special endings for specific achievements (not just wellbeing thresholds)
```

### TO REDUCE POTENTIAL FILLER

```
STREAMLINE:
- [ ] Auto-assign idle workers option
- [ ] Fast-forward through night phase
- [ ] Templates for common building patterns

CURRENT FILLER RISK:
- Night phase (8s) could feel like waiting if player has no decisions
- Worker pathfinding visualization could get tedious after hours
- Tutorial hints (already tracked for dismissal, good)
```

---

## TODO LIST FOR IMPROVEMENTS

### High Priority (Improves replayability)

1. **Add 3+ more inciting incidents** - Current 7 means only 7 "fresh" runs
2. **Implement endless/challenge mode** - Converts arc structure to loop
3. **Add archetype variety** - Different starting palettes change strategy significantly
4. **Make event outcomes more varied** - Same event should play differently based on city state

### Medium Priority (Extends engagement)

5. **Add meta-progression** - Building unlocks persist, attention bonuses unlock
6. **Add procedural event generation** - Combine resource types into dynamic events
7. **Add building synergy discovery** - Finding powerful combos becomes its own loop
8. **Add daily/weekly challenges** - External variety source

### Lower Priority (Polish)

9. **Streamline night phase** - Skip button or auto-advance option
10. **Add replay viewer** - Watch best runs, share seeds
11. **Add stats tracking** - Resources processed total, buildings built, etc.
12. **Add achievement system** - Specific build challenges

---

## CONCLUSION

**PsycheBuilder has excellent loop-to-arc balance for a roguelike city-builder.** The 75% loop content ensures high replayability, while the 25% arc content (events, unlocks, endings) provides motivation for the first 5-10 runs.

**Current Strengths:**
- Deep interlocking systems create emergent complexity (25+ systems in config)
- Short run length (~20 min) enables "one more run" engagement
- Event system provides narrative arc without dominating gameplay
- Building variety (55 buildings) supports multiple strategies

**Primary Gap:**
- **Arc content exhaustion around run 10-15** - After seeing all inciting incidents and unlocking buildings, the "discovery" motivation fades
- **No meta-progression** - Each run is independent, limiting long-term engagement hooks

**Recommended Focus:**
1. Add 3+ more inciting incidents to extend fresh content
2. Implement challenge modifiers or endless mode for players who want pure loops
3. Consider light meta-progression (habituation persistence, achievement unlocks) for long-term players

The game is well-positioned for **premium release with optional DLC content packs** (new archetypes, event sets, building themes) or as a **roguelike with seasonal content updates**.