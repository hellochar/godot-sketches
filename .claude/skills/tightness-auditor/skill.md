---
name: tightness-auditor
description: Audit game mechanics for cause-and-effect clarity—identify feedback gaps, ambiguous systems, and recommend improvements
---

# Tightness Auditor

Audit game mechanics for "tightness" - the clarity of cause-and-effect relationships. Identify feedback gaps, ambiguous systems, and places where players can't form accurate mental models.

## When to Use This Skill

Use this skill when asked to:
- Review why a mechanic feels "floaty" or unresponsive
- Identify why players aren't learning a system
- Audit feedback systems for gaps
- Improve "game feel" and responsiveness
- Debug player confusion about how things work

---

## What is Tightness?

**Tight** = Clear, immediate, unambiguous cause-and-effect
**Loose** = Obscured, delayed, or confusing cause-and-effect

```
TIGHTNESS SPECTRUM
==================

TIGHTEST                                                  LOOSEST
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Binary states      Numbers 1-5      Percentages      Hidden stats
│  Immediate feedback Delayed feedback Deferred feedback No feedback
│  One action=one result Multiple factors Complex formulas Black box
│  Visual confirmation Text confirmation No confirmation  ???
│                                                              │
│  "I pressed jump,    "I dealt damage,   "Something       "I have no
│   I jumped"          but how much?"     happened maybe"   idea"
```

### Why Tightness Matters

Players learn through feedback loops. If they can't form accurate mental models:
- They feel frustrated, not challenged
- They blame the game, not themselves
- They can't improve because they don't know what to improve
- They quit

**Key insight**: "Feedback failures are the most common error in new designs."

---

## The Tightness Hierarchy

Core mechanics need to be tightest. Outer layers can be looser.

```
TIGHTNESS HIERARCHY
===================

                    ┌─────────────────┐
                    │   META SYSTEMS  │  Can be looser
                    │  (progression,  │  (long-term, complex)
                    │   economy)      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  INTERMEDIATE   │  Should be tight
                    │  (combos, builds│  (clear choices)
                    │   resources)    │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ CORE MECHANICS  │  MUST be tightest
                    │ (movement, basic│  (instant, obvious)
                    │  actions)       │
                    └─────────────────┘
```

---

## Audit Process

### Step 1: Inventory Mechanics

List all mechanics to audit:

```
MECHANIC INVENTORY
==================

Mechanic: [Name]
  Layer: [Core / Intermediate / Meta]
  Action: [what player does]
  Expected Result: [what should happen]
  Frequency: [how often used]
  Critical Path: [Yes/No - is this required to progress?]
```

### Step 2: Audit Each Mechanic

For each mechanic, evaluate these tightness factors:

```
TIGHTNESS AUDIT: [Mechanic Name]
================================

RESPONSE TIME
─────────────
How quickly does the game respond to player input?

[ ] Instant (< 50ms) - TIGHT
[ ] Quick (50-150ms) - ACCEPTABLE
[ ] Noticeable (150-300ms) - LOOSE
[ ] Delayed (> 300ms) - PROBLEM

Actual response time: [estimate]
Acceptable for this mechanic: [Yes/No]
Notes: [buffering, animation priority, network lag]

FEEDBACK CHANNELS
─────────────────
What feedback confirms the action occurred?

Visual feedback:
  [ ] Direct (animation, state change)
  [ ] Indirect (UI update, particle effect)
  [ ] Absent

Audio feedback:
  [ ] Direct (action sound)
  [ ] Indirect (UI sound, ambient change)
  [ ] Absent

Haptic feedback:
  [ ] Present (rumble, shake)
  [ ] Absent
  [ ] N/A (no controller support)

Numerical feedback:
  [ ] Shown (damage numbers, resource change)
  [ ] Hidden (must calculate)
  [ ] N/A

Feedback gap identified: [Yes/No]
Missing channels: [list]

STATE CLARITY
─────────────
Can the player tell what state they're in?

[ ] Binary states (on/off, alive/dead) - TIGHTEST
[ ] Small discrete numbers (1, 2, 3, 4) - TIGHT
[ ] Larger numbers with meaning (10/50 HP) - ACCEPTABLE
[ ] Percentages or ratios - LOOSE
[ ] Hidden or complex formula - LOOSEST

Current clarity: [description]
Could be simplified to: [suggestion]

CAUSE-EFFECT CLARITY
────────────────────
Can the player trace outcome back to their action?

[ ] One action = one clear outcome - TIGHT
[ ] One action = predictable outcome with variation - ACCEPTABLE
[ ] Multiple factors combine - LOOSE
[ ] Outcome seems random or unconnected - BROKEN

Confounding factors:
- [list things that obscure the cause-effect chain]

Attribution problem: [Can player know WHY something happened?]

INPUT CLARITY
─────────────
Does the player know what inputs are available?

[ ] Obvious/afforded (visible buttons, clear UI) - TIGHT
[ ] Discoverable (tutorial, hints) - ACCEPTABLE
[ ] Hidden (must experiment or read docs) - LOOSE
[ ] Unintuitive (conflicts with expectations) - PROBLEM

Input discoverability: [assessment]
Input consistency: [does it always work the same way?]

OUTCOME PREDICTABILITY
──────────────────────
Before acting, can the player predict the outcome?

[ ] Fully predictable (deterministic) - TIGHTEST
[ ] Predictable with known variance (dice roll) - TIGHT
[ ] Predictable given hidden information - LOOSE
[ ] Unpredictable (feels random) - LOOSEST

Prediction accuracy: [how often are player expectations correct?]
Surprise sources: [what makes outcomes unexpected?]
```

### Step 3: Score and Prioritize

```
TIGHTNESS SCORECARD: [Mechanic Name]
====================================

                        Score   Weight   Weighted
Response Time:          [1-5]   x [1-3]  = [score]
Feedback Channels:      [1-5]   x [1-3]  = [score]
State Clarity:          [1-5]   x [1-3]  = [score]
Cause-Effect Clarity:   [1-5]   x [1-3]  = [score]
Input Clarity:          [1-5]   x [1-3]  = [score]
Outcome Predictability: [1-5]   x [1-3]  = [score]
                                         ─────────
                        TOTAL:           [X] / [max]

TIGHTNESS RATING: [Tight / Acceptable / Loose / Broken]

Weight guide:
  3 = Core mechanic (movement, primary action)
  2 = Intermediate (combat, resource management)
  1 = Meta (progression, economy)
```

---

## Common Tightness Problems

### Problem Patterns and Fixes

| Problem | Symptom | Fix |
|---------|---------|-----|
| **Missing audio** | Actions feel "dead" | Add sound for every action |
| **Delayed response** | Feels laggy | Reduce input delay, add anticipation animations |
| **Hidden outcomes** | Player guesses | Show damage numbers, state changes |
| **Complex formulas** | "Why did that happen?" | Simplify or explain in UI |
| **Multiple factors** | Can't attribute outcome | Isolate effects, show breakdown |
| **Ambiguous states** | "Am I doing this right?" | Add clear state indicators |
| **Inconsistent input** | "This worked before!" | Remove situational exceptions |
| **Invisible progress** | "Is this working?" | Add progress feedback |

### Red Flags by Layer

**Core Mechanics Red Flags**
- Any response time > 100ms
- Missing visual OR audio feedback
- Non-deterministic outcomes for same input
- Player must read docs to know inputs

**Intermediate System Red Flags**
- Outcomes determined by 3+ hidden factors
- No way to see current state before acting
- Results require mental math to understand
- Effects happen "sometime later"

**Meta System Red Flags**
- Progress invisible until threshold reached
- Can't predict if current action helps goal
- System only explainable via external wiki
- Player can't form strategy (just guessing)

---

## Output Format

When auditing a game/mechanic, provide:

### 1. Tightness Summary

```
TIGHTNESS AUDIT SUMMARY
=======================

Game/System: [name]
Mechanics Audited: [count]

OVERALL TIGHTNESS: [Tight / Acceptable / Loose / Broken]

By Layer:
  Core Mechanics:      [████████░░] 80% Tight
  Intermediate:        [██████░░░░] 60% Acceptable
  Meta Systems:        [████░░░░░░] 40% Loose (acceptable for meta)
```

### 2. Mechanic-by-Mechanic Results

```
DETAILED AUDIT
==============

CORE MECHANICS
──────────────

✓ Movement [TIGHT - 45/50]
  + Instant response
  + Clear audio/visual feedback
  + Deterministic
  - Minor: No haptic feedback

✗ Jump [LOOSE - 28/50]
  + Visual feedback present
  - Delayed response (150ms input buffer)
  - Variable height unclear
  - No audio for landing

INTERMEDIATE SYSTEMS
────────────────────

~ Combat [ACCEPTABLE - 35/50]
  + Damage numbers shown
  + Hit feedback satisfying
  - Damage formula opaque
  - Crit chance hidden
```

### 3. Priority Fixes

```
RECOMMENDED FIXES
=================

CRITICAL (breaking player learning):
1. [Mechanic] - [specific problem]
   Fix: [specific solution]
   Effort: [Low/Medium/High]
   Impact: [description of improvement]

HIGH (degrading game feel):
2. [Mechanic] - [specific problem]
   Fix: [specific solution]
   Effort: [Low/Medium/High]

MEDIUM (polish):
3. [Mechanic] - [specific problem]
   Fix: [specific solution]
   Effort: [Low/Medium/High]
```

### 4. Quick Wins

```
QUICK WINS (Low effort, high impact)
====================================

1. Add [audio/visual] feedback to [action]
   - Currently: [no feedback]
   - Add: [specific feedback]
   - Effort: 1-2 hours

2. Show [hidden stat] when [condition]
   - Currently: player guesses
   - Add: [UI element]
   - Effort: 2-4 hours

3. Reduce [delay] by [amount]
   - Currently: [X]ms
   - Target: [Y]ms
   - Effort: [time]
```

---

## Example Audit

```
TIGHTNESS AUDIT: Platformer Jump Mechanic
=========================================

MECHANIC: Variable Height Jump
Layer: Core (Critical Path: Yes)

RESPONSE TIME: 3/5 (ACCEPTABLE)
  Input to jump start: 50ms (instant) ✓
  Jump height determined by: hold duration
  Issue: Release timing affects height, but no visual cue

FEEDBACK CHANNELS: 2/5 (LOOSE)
  Visual: Character animates ✓
  Audio: Jump sound on takeoff ✓
  Audio: NO landing sound ✗
  Visual: NO height indicator ✗
  Haptic: None (could add controller rumble)

STATE CLARITY: 2/5 (LOOSE)
  Player cannot see:
  - Current jump charge
  - Maximum height achievable
  - When to release for desired height
  All timing is "feel" based with no visual aid

CAUSE-EFFECT CLARITY: 3/5 (ACCEPTABLE)
  Clear: Press = jump, hold = higher
  Unclear: Exact relationship between hold time and height
  Confounding: Ground type affects jump? (if yes, not shown)

INPUT CLARITY: 4/5 (TIGHT)
  Jump button is obvious
  Variable height is discoverable
  Consistent behavior

OUTCOME PREDICTABILITY: 2/5 (LOOSE)
  Player can't predict exact landing spot
  Must overshoot and correct
  Veterans develop feel, but new players flounder

TOTAL SCORE: 16/30 (LOOSE)

FIXES RECOMMENDED:

1. [CRITICAL] Add jump height indicator
   - Show arc preview while holding jump
   - Or: show charge meter filling
   - Effort: Medium (UI + polish)

2. [HIGH] Add landing sound/feedback
   - Audio cue on ground contact
   - Screen shake on hard landings
   - Effort: Low (audio + minor code)

3. [MEDIUM] Simplify jump curve
   - Current: Continuous variable height
   - Consider: 2-3 discrete heights (tap/short/long)
   - Effort: Medium (rebalance levels)

4. [POLISH] Add coyote time + input buffer
   - Currently: Strict timing
   - Add: 100ms grace period
   - Effort: Low (code only)
```

