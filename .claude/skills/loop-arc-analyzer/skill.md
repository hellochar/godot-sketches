---
name: loop-arc-analyzer
description: Categorize game content as loops or arcs using Daniel Cook's framework—calculate replayability ratio, match content structure to business model, and identify filler
---

# Loop-Arc Analyzer

Categorize game content as loops (repeatable skill-based gameplay) or arcs (consumable one-time content) using Daniel Cook's framework. Calculate replayability, match to business models, and identify what's core vs filler.

## When to Use This Skill

Use this skill when asked to:
- Analyze a game's content structure for replayability
- Determine if content matches the intended business model
- Identify what content is "filler" vs "core"
- Plan content investment for a new game
- Understand why a game feels thin or endless

---

## Loops vs Arcs

### Definitions

| Concept | Loop | Arc |
|---------|------|-----|
| **Core idea** | Repeatable, skill-based | Consumable, one-time |
| **Player experience** | Mastery over time | Discovery, then done |
| **Value source** | Getting better | Seeing what's next |
| **Replayability** | Infinite (in theory) | Zero (once consumed) |
| **Content cost** | High upfront, low marginal | Linear with playtime |

### The Spectrum

```
Pure Loops                                              Pure Arcs
◄──────────────────────────────────────────────────────────────────►
    │           │              │              │              │
  Chess      Roguelikes    Zelda/Metroid   Walking Sims   Visual Novels
  MOBAs      Souls-likes   Open World RPGs  Adventure      Interactive
  Tetris     Shooters      Action RPGs      Games          Movies
```

### Examples

**Pure Loops**
- Chess: Same rules, infinite games, mastery takes years
- Tetris: Same mechanics, procedural challenge
- Competitive multiplayer: Human opponents provide variety

**Pure Arcs**
- Walking simulators: Explore once, story consumed
- Puzzle games with solutions: Solve once, done
- Narrative adventures: Experience the story, no replay

**Hybrids**
- Zelda: Loop combat + Arc dungeons/story
- Dark Souls: Loop combat mastery + Arc world discovery
- Open world RPGs: Loop combat/gathering + Arc quests/story

---

## Analysis Process

### Step 1: Content Inventory

List all content types in the game:

```
CONTENT INVENTORY
=================

Content Type: [Name]
  Category: [Gameplay / Narrative / Progression / Social / Meta]
  Quantity: [count or "procedural"]
  Player Hours: [estimated time to consume/master]
  Loop or Arc: [to be determined]
```

### Step 2: Classify Each Content Type

For each content type, answer these questions:

```
CONTENT CLASSIFICATION: [Name]
==============================

1. Can this be repeated for value?
   [ ] Yes, player gains skill/mastery → LOOP
   [ ] Yes, but diminishing returns → WEAK LOOP
   [ ] No, consumed once → ARC

2. What provides the value?
   [ ] Player getting better at something → LOOP
   [ ] Discovering new content → ARC
   [ ] Both equally → HYBRID

3. How does difficulty/challenge work?
   [ ] Scales with player skill → LOOP
   [ ] Fixed, one-time challenge → ARC
   [ ] Procedurally varies → LOOP

4. What's the content cost model?
   [ ] Create system once, infinite plays → LOOP
   [ ] Linear: more hours = more content needed → ARC

VERDICT: [LOOP / ARC / HYBRID]
REPLAYABILITY: [None / Low / Medium / High / Infinite]
```

### Step 3: Calculate Ratios

```
CONTENT RATIO ANALYSIS
======================

Total estimated player hours: [X]

LOOP CONTENT
------------
[Content A]: [hours] (loop)
[Content B]: [hours] (loop)
Loop subtotal: [hours]
Loop percentage: [X]%

ARC CONTENT
-----------
[Content C]: [hours] (arc)
[Content D]: [hours] (arc)
Arc subtotal: [hours]
Arc percentage: [X]%

REPLAYABILITY RATIO: [Loop hours] / [Total hours] = [X]%
```

### Step 4: Match to Business Model

| Business Model | Ideal Loop/Arc Ratio | Rationale |
|---------------|----------------------|-----------|
| **Premium (one-time purchase)** | 30-50% loops | Arcs justify purchase, loops extend value |
| **Live Service** | 70-90% loops | Loops retain players between content drops |
| **Subscription** | 60-80% loops | Need consistent engagement, arcs for events |
| **Free-to-Play** | 80%+ loops | Must retain without content budget per player |
| **Arcade/Session** | 90%+ loops | Each session must be complete |
| **Narrative Focus** | 10-30% loops | Story is the product, loops are mechanics |

```
BUSINESS MODEL FIT
==================

Intended model: [model]
Ideal ratio: [X]% loops
Actual ratio: [Y]% loops
Gap: [difference]

FIT ASSESSMENT: [Good / Moderate / Poor]
```

---

## Identifying Filler vs Core

### Core Content
- Directly tied to the game's value proposition
- Players would miss it if removed
- Loops: the "main game" players return for
- Arcs: the memorable moments, story beats, discoveries

### Filler Content
- Exists to extend playtime without adding value
- Players tolerate it rather than enjoy it
- "Padding" that dilutes the experience
- Often: fetch quests, arbitrary requirements, travel time

```
FILLER IDENTIFICATION
=====================

For each content type, rate:

Enjoyment: [1-5] (do players like this?)
Necessity: [1-5] (does the game need this?)
Uniqueness: [1-5] (is this distinct from other content?)

FILLER SCORE = (Necessity - Enjoyment)

> 2: Likely filler, consider cutting
1-2: Borderline, consider improving
< 1: Core content, protect and polish
```

---

## Output Format

When analyzing a game, provide:

### 1. Content Breakdown Table

| Content Type | Hours | Classification | Replayability | Core/Filler |
|-------------|-------|----------------|---------------|-------------|
| Combat system | 20+ | Loop | Infinite | Core |
| Main story quests | 15 | Arc | None | Core |
| Side quests | 10 | Arc | None | Filler |
| Crafting | 5 | Weak Loop | Medium | Core |
| Collectibles | 3 | Arc | None | Filler |

### 2. Ratio Summary

```
CONTENT STRUCTURE
=================

Loop Content:    25 hours  (50%)
Arc Content:     25 hours  (50%)
Hybrid Content:   5 hours  (10%)

Replayability Ratio: 55%

Core Content:    40 hours  (80%)
Filler Content:  10 hours  (20%)
```

### 3. Visual Breakdown

```
CONTENT COMPOSITION
===================

[██████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░] 50% Loops
[░░░░░░░░░░░░░░░░░░░░░░░░░░██████████████████████████] 50% Arcs

[████████████████████████████████████████░░░░░░░░░░] 80% Core
[░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██████████] 20% Filler
```

### 4. Business Model Fit

```
BUSINESS MODEL ANALYSIS
=======================

Current structure: 50% loops / 50% arcs

FIT BY MODEL:
  Premium:      ████████░░ Good fit (ideal 30-50%)
  Live Service: ████░░░░░░ Poor fit (needs 70%+ loops)
  F2P:          ███░░░░░░░ Poor fit (needs 80%+ loops)
  Narrative:    ██████░░░░ Moderate (could have fewer loops)

RECOMMENDATION: Best suited for premium release.
If targeting live service, need more loop content.
```

### 5. Recommendations

```
CONTENT STRATEGY RECOMMENDATIONS
================================

TO INCREASE LOOPS:
- Add procedural dungeon system (converts static dungeons to loops)
- Introduce competitive/ranked mode
- Add daily challenges with rotating modifiers
- Create endless/survival mode

TO IMPROVE ARCS:
- Cut filler side quests, invest in fewer high-quality arcs
- Add branching choices for replay value
- Create memorable setpieces at pacing valleys

TO REDUCE FILLER:
- Remove collectibles or tie to meaningful rewards
- Consolidate fetch quests into multi-step arcs
- Reduce travel time with fast travel unlocks
```

---

## Example Analysis: Action RPG

```
GAME: Fantasy Action RPG (40 hours)

CONTENT INVENTORY
=================

Combat System
  Category: Gameplay
  Hours: Infinite (core loop)
  Classification: LOOP
  Analysis: Skill-based, enemy variety, build diversity
  Replayability: High
  Verdict: CORE LOOP

Main Story (20 quests)
  Category: Narrative
  Hours: 12
  Classification: ARC
  Analysis: Linear narrative, consumed once
  Replayability: None
  Verdict: CORE ARC

Side Quests (50 quests)
  Category: Narrative/Gameplay
  Hours: 15
  Classification: ARC
  Analysis: Mostly fetch/kill, weak stories
  Filler Score: +2 (Necessity 3, Enjoyment 1)
  Verdict: FILLER ARC

Crafting System
  Category: Progression
  Hours: 8
  Classification: WEAK LOOP
  Analysis: Recipes learned once, gathering repeats
  Replayability: Medium (gathering loops, crafting arcs)
  Verdict: HYBRID

Boss Fights (10 bosses)
  Category: Gameplay
  Hours: 3
  Classification: HYBRID
  Analysis: Learned once (arc), but repeatable for mastery/farming
  Replayability: Medium
  Verdict: CORE HYBRID

Exploration/Collectibles
  Category: Progression
  Hours: 5
  Classification: ARC
  Analysis: Found once, minimal reward
  Filler Score: +3 (Necessity 1, Enjoyment 1)
  Verdict: FILLER ARC

RATIO CALCULATION
=================

Loop content: Combat (20h equivalent value)
Arc content: Story (12h) + Side quests (15h) + Exploration (5h) = 32h
Hybrid: Crafting (4h loop, 4h arc) + Bosses (1.5h loop, 1.5h arc) = 5.5h each

Total: ~57 hours first playthrough

Loop percentage: 25.5 / 57 = 45%
Arc percentage: 37.5 / 57 = 55%

BUSINESS MODEL FIT
==================

Current: 45% loops / 55% arcs
Ideal for premium: 30-50% loops ✓ GOOD FIT
Ideal for live service: 70%+ loops ✗ POOR FIT

RECOMMENDATIONS
===============

If staying premium:
  - Cut 10 weakest side quests (save 5 hours dev time)
  - Invest in 2 more memorable boss fights
  - This is appropriately structured

If pivoting to live service:
  - Add endless dungeon mode
  - Add PvP or co-op modes
  - Create seasonal content framework
  - Reduce side quest investment, increase system depth
```

---

## Reference

Based on Daniel Cook's framework:
- [Loops and Arcs](https://lostgarden.com/2012/04/30/loops-and-arcs/)
