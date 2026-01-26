# Overnight Autonomous Development Log

## Instructions (for context compaction)
**CRITICAL**: Autonomously iterate 20 times through this loop:
1. Analyze game with emergent-game-design skill
2. Build implementation plan (no questions, decide autonomously)
3. Execute plan - make content and add features
4. Commit changes

Log everything to this file. Currently on: **Loop 1, Step 1 (Analysis)**

---

## Loop 1: Deck Manipulation System

### Step 1: Analysis

**Current State Assessment:**
- 62 motivation cards (50 original + 12 bridge cards)
- 6 tag system: Health, Social, Routine, Effort, Risk, Creativity
- Bridge card ratio improved to ~30%
- 5 special effects, 10 condition types

**Critical Gap Identified: No Deck Manipulation**

Per emergent-game-design skill:
> "Motivation isn't a resource you manage—it's just revealed. Score has no trade-offs."
> "No deck manipulation (discard, scry, tutor)"

The player draws 5 cards with zero agency over what appears. This eliminates:
- Strategic hand-shaping
- Risk/reward decisions around card management
- Skill expression through deck knowledge
- "Engine building" satisfaction

**Atoms Missing:**
- Discard (sacrifice card for benefit)
- Mulligan (redraw with penalty)
- Scry (look at upcoming cards)
- Retain (keep card between turns)

**Decision:** Implement discard-to-redraw mechanic as foundational deck manipulation.

### Step 2: Implementation Plan

1. Add UI button "Discard & Redraw" to motivation phase
2. Implement discard mechanic: spend 1 card from hand to draw 1 new card
3. Limit to 2 discards per turn (prevents infinite cycling)
4. Add visual feedback for discarded cards
5. Create 3 "discard synergy" cards that reward discarding

### Step 3: Execution

**Files Modified:**
- `motivation_cards.gd` - Added discard mechanic with click-to-discard UI
  - `max_discards_per_turn: int = 2` (exported)
  - `discards_this_turn` tracking variable
  - `_discard_card()` function handles removal and redraw
  - `_update_discard_label()` shows remaining discards
  - Cards now clickable during motivation phase
  - Context now includes `discards_this_turn` for condition checks

- `motivation_cards.tscn` - Added DiscardLabel node for UI feedback

- `motivation_card_resource.gd` - Added DISCARDED_THIS_TURN condition type
  - Checks if player has discarded X+ cards this turn
  - Supports threshold (1 = "if discarded", 2+ = "if discarded X+ times")

**Discard Synergy Cards Created:**
1. `fresh_perspective.tres` - +10 Creativity, +10 Risk. 2x if discarded this turn.
2. `restless_energy.tres` - +15 Effort. 2x if discarded, +1 draw on success.
3. `adaptable_spirit.tres` - +8 to all tags. 2x if discarded this turn.

**Added to starter_deck.tres** - All 3 cards registered with ExtResource IDs 136-138.

### Step 4: Commit

