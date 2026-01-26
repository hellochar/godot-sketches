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

Committed: `fb7760d` - "Add discard-to-redraw deck manipulation mechanic"

---

## Loop 2: Build-Around Cards & Engine Strengthening

### Step 1: Analysis

**Gap: Weak Build-Arounds**

Per emergent-game-design skill:
> "Layer 3 - Build-arounds: Elements that define entire strategies. These are intentionally parasitic—they demand the player warp their deck around them."
> "Only 5 engine cards out of 50."
> "Current 'Build-Arounds' Are Weak"

**Problem:**
- Flow State is uncontrollable (can't choose draws)
- Streak Keeper breaks on random failures
- No cards that say "build your ENTIRE deck around me"

**Design Goals:**
1. Create cards that change deck-building priority drastically
2. Add self-reinforcing engines that compound
3. Make "all-in" strategies viable and exciting

### Step 2: Implementation Plan

1. Track `total_successes_this_week` and `last_successful_action_title` in game_state
2. Add new condition type: `REPEATED_SUCCESS` (same action as yesterday)
3. Add new special effects:
   - `MOMENTUM_SCALING` (+X per total success this week)
   - `DISCARD_SCALING` (+X per discard this turn)
   - `AMPLIFY_ALL` (double all positive/negative modifiers from other cards)
   - `EXHAUST_BONUS` (remove this card from deck for massive bonus)
4. Create 6 build-around cards:
   - Singularity (mono-tag payoff)
   - Momentum Engine (success stacking)
   - Glass Cannon (amplifier)
   - Discard Master (discard engine payoff)
   - Repeat Expert (consistency payoff)
   - Desperation Play (exhaust for burst)

### Step 3: Execution

**Files Modified:**

- `game_state.gd` - Added tracking variables:
  - `total_successes_this_week: int = 0`
  - `last_successful_action_title: String = ""`

- `motivation_card_resource.gd` - Added new mechanics:
  - ConditionType.REPEATED_ACTION (checks if same action as last success)
  - SpecialEffect.MOMENTUM_SCALING (+X per total success this week)
  - SpecialEffect.DISCARD_SCALING (+X per discard this turn)
  - SpecialEffect.AMPLIFY_ALL (doubles all other card modifiers)
  - SpecialEffect.EXHAUST_BONUS (huge bonus, removes card from deck)

- `motivation_cards.gd` - Implemented new special effects:
  - Context now includes `action_title`, `total_successes_this_week`, `last_successful_action_title`
  - `_get_special_effect_bonus()` handles new scaling effects
  - `_handle_exhaust_cards()` removes exhausted cards after success
  - Tracks total successes and last successful action

**Build-Around Cards Created:**
1. `momentum_engine.tres` - +5 Effort, +5 per success this week. Snowballs over time.
2. `glass_cannon.tres` - Double all other modifiers. High risk/reward amplifier.
3. `discard_master.tres` - +15 per discard this turn. Rewards aggressive discarding.
4. `repeat_expert.tres` - +10 all tags, 3x if same action as last success. Rewards consistency.
5. `desperation_play.tres` - Exhaust: +100, then removed from deck. Emergency burst.
6. `focused_specialist.tres` - +15 all tags, 2x if action has only 1 tag. Rewards simple actions.

**Added to starter_deck.tres** - All 6 cards registered with ExtResource IDs 139-144.

### Step 4: Commit

Committed: `69aa74b` - "Add build-around cards and engine-strengthening mechanics"

---

## Loop 3: Converter Cards & Resource Tension

### Step 1: Analysis

**Gap: No Converters / Resource Tension**

Per emergent-game-design skill:
> "Converters: Transform one resource into another."
> "No free lunches: Powerful effects should cost multiple resource types."

**Current Problem:**
- Cards either help or hurt, no trade-offs
- No "pay X for Y" decisions
- Willpower is the only manipulable resource
- No way to convert desperation into power

**Design Goals:**
1. Create cards that trade one resource for another
2. Add "when desperate" bonuses (low willpower = high reward)
3. Create meaningful "pay now vs pay later" decisions

### Step 2: Implementation Plan

1. Add new condition: `LOW_WILLPOWER` (triggers when willpower below threshold)
2. Add new special effects:
   - `DRAIN_WILLPOWER_ON_SUCCESS` (costs willpower when you win)
   - `REDUCE_MAX_WILLPOWER` (permanent cost for power)
3. Create 5 converter cards:
   - Desperation Surge (huge bonus when willpower low)
   - Borrowed Energy (strong bonus, drains willpower on success)
   - Burnout Burst (massive power, reduces max willpower)
   - Last Resort (+80, but only when very low willpower)
   - Trade Tomorrow (+40 with permanent max willpower cost)

### Step 3: Execution

**Files Modified:**

- `motivation_card_resource.gd` - Added new mechanics:
  - ConditionType.LOW_WILLPOWER (triggers when willpower <= threshold)
  - SpecialEffect.DRAIN_WILLPOWER_ON_SUCCESS (costs willpower when you win)
  - SpecialEffect.REDUCE_MAX_WILLPOWER (permanent max willpower reduction)

- `motivation_cards.gd` - Implemented converter effects:
  - Context now includes `willpower` for LOW_WILLPOWER condition
  - `_handle_success_special_effects()` handles draining and max reduction
  - Max willpower can't go below 30 (prevents soft-lock)

**Converter Cards Created:**
1. `desperation_surge.tres` - +20 all tags, 2x when willpower <= 30. Rewards playing desperate.
2. `borrowed_energy.tres` - +25 Effort/Health, but -15 willpower on success. Trade tomorrow for today.
3. `burnout_burst.tres` - +40 Effort/Creativity, but -10 max willpower permanently. High power, high cost.
4. `last_resort.tres` - +40 all tags when willpower <= 15. Emergency power spike.
5. `trade_tomorrow.tres` - +30 Routine/Effort, -5 max willpower. Lighter cost version.

**Added to starter_deck.tres** - All 5 cards registered with ExtResource IDs 145-149.

### Step 4: Commit

