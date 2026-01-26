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

Committed: `754b58f` - "Add converter cards with resource tension mechanics"

---

## Loop 4: Counter Cards & Negative Rework

### Step 1: Analysis

**Gap: Negative Cards Are Just Bad**

Per emergent-game-design skill:
> "Lazy Afternoon: Pure negative (-20 Effort). Add upside."
> "Playing It Safe: Anti-synergy without payoff."
> "Missing Card Types: Counters - 'Negate a negative modifier'"

**Current Problem:**
- ~10 cards have purely negative effects
- No way to turn negatives into positives
- Drawing bad cards feels bad with no counterplay

**Design Goals:**
1. Create cards that negate or invert negative modifiers
2. Add synergy with negative cards (lenticular: bad cards become good)
3. Make "negative" cards interesting build-arounds

### Step 2: Implementation Plan

1. Add new special effect: `NEGATE_NEGATIVES` (all negative modifiers become 0)
2. Add new special effect: `INVERT_NEGATIVES` (negative modifiers become positive)
3. Create 4 counter/synergy cards:
   - Optimistic Lens (negate all negatives)
   - Silver Lining (invert negatives to positives)
   - Contrarian (bonus for each negative card in hand)
   - Resilience (if any negative modifier, bonus to all)

### Step 3: Execution

**Files Modified:**

- `motivation_card_resource.gd` - Added new special effects:
  - NEGATE_NEGATIVES (all negative modifiers become 0)
  - INVERT_NEGATIVES (negative modifiers become positive)
  - BONUS_PER_NEGATIVE_CARD (+X per negative card in hand)

- `motivation_cards.gd` - Implemented counter mechanics:
  - `_get_motivation_for_action()` now checks for negate/invert effects
  - Applied to individual card contributions before totaling
  - `_get_special_effect_bonus()` calculates bonus per negative card

**Counter Cards Created:**
1. `optimistic_lens.tres` - Negates all negative modifiers. Pure counter card.
2. `silver_lining.tres` - Inverts negatives to positives. Turns -20 into +20.
3. `contrarian.tres` - +15 per negative card in hand. Rewards bad draws.
4. `resilient_spirit.tres` - +10 all tags, +10 per negative card. Bridge counter.

**Added to starter_deck.tres** - All 4 cards registered with ExtResource IDs 150-153.

### Step 4: Commit

Committed: `156e086` - "Add counter cards that interact with negative modifiers"

---

## Loop 5: World Modifier Expansion

### Step 1: Analysis

**Gap: Underutilized World Modifiers**

Current state: Only 4 world modifiers exist. They appear randomly and provide simple tag bonuses. This is a missed opportunity for environmental storytelling and strategic variety.

**Design Goals:**
1. Triple the world modifier pool (4 → 12)
2. Add conditional world modifiers (interact with card state)
3. Create modifiers that synergize with specific archetypes

### Step 2: Implementation Plan

Add 8 new world modifiers across different themes:
- Social: "Friend visiting", "Group event nearby"
- Health: "Gym is empty", "Slept poorly"
- Creativity: "Inspiring article", "Creative block"
- Risk: "Opportunity knocking", "Deadline pressure"

### Step 3: Execution

**World Modifiers Created:**
1. `friend_visiting.tres` - +20 Social, -10 Routine (social disrupts schedule)
2. `group_event.tres` - +15 Social, +10 Risk (networking opportunity)
3. `gym_empty.tres` - +15 Health, +10 Effort (ideal workout conditions)
4. `slept_poorly.tres` - -15 Effort, -10 Health, +5 Creativity (tired but dreamy)
5. `inspiring_article.tres` - +15 Creativity, +10 Effort (motivated to create)
6. `creative_block.tres` - -20 Creativity, +10 Routine (stuck, fall back on habits)
7. `opportunity_knocking.tres` - +20 Risk, +10 Effort (chance to seize)
8. `deadline_pressure.tres` - +20 Effort, +15 Routine, -15 Social (crunch time)

**Added to starter_deck.tres** - All 8 modifiers registered with ExtResource IDs 154-161.

World modifier pool tripled: 4 → 12.

### Step 4: Commit

Committed: `faf7809` - "Expand world modifiers pool from 4 to 12"

---

## Loop 6: Temporary Event Cards

### Step 1: Analysis

**Gap: Static Deck Composition**

Per emergent-game-design skill:
> "Deck evolution is dilution without direction"

Current problem: Cards added from actions stay forever, diluting the deck. The `is_temporary` flag exists but isn't used.

**Design Goals:**
1. Create cards that only last one day (auto-remove at end of turn)
2. Add powerful temporary cards as action rewards
3. Create event-like cards that shake up strategy for one day

### Step 2: Implementation Plan

Create 6 temporary motivation cards (high power, one-day duration):
- "Caffeine Rush" - Big Effort boost, temporary
- "Social Buzz" - High Social after meetup
- "Flow Moment" - Extreme Creativity spike
- "Adrenaline High" - Risk bonus after challenge
- "Clarity Flash" - All tags bonus, fleeting
- "Victory Lap" - Huge bonus after big success

### Step 3: Execution

**Temporary Cards Created:**
1. `caffeine_rush.tres` - +30 Effort, +15 Routine, -10 Health. Auto-removes at day end.
2. `social_buzz.tres` - +35 Social, +15 Creativity. Party energy fades.
3. `flow_moment.tres` - +40 Creativity, +15 Effort. Brief creative peak.
4. `adrenaline_high.tres` - +30 Risk, +20 Health. Post-challenge high.
5. `clarity_flash.tres` - +15 all tags. Moment of perfect clarity.
6. `victory_lap.tres` - +25 all tags. Celebration energy.

**Actions Updated with Temporary Rewards:**
- `go_gym.tres` → rewards caffeine_rush
- `attend_meetup.tres` → rewards social_buzz
- `cold_shower.tres` → rewards adrenaline_high
- `meditate.tres` → rewards clarity_flash
- `creative_project.tres` → added flow_moment
- `run_5k.tres` → added victory_lap

### Step 4: Commit

Committed: `36e0280` - "Add temporary event cards as action rewards"

---

## Loop 7: Value Card Activation

### Step 1: Analysis

**Gap: Passive Value Cards**

Per emergent-game-design skill:
> "Value cards don't create decisions during play. They're just a passive multiplier."
> "Alternative Design: Value cards could grant special abilities"

Current problem: Value cards are selected at start, then never interacted with again. No player agency during gameplay.

**Design Goals:**
1. Add one-time activatable abilities to value cards
2. Create meaningful "save for the right moment" decisions
3. Abilities refresh weekly to encourage strategic timing

### Step 2: Implementation Plan

1. Add AbilityType enum to ValueCardResource:
   - NONE, EXTRA_DRAW, RESTORE_WILLPOWER, DOUBLE_NEXT_SCORE, REROLL_HAND, BONUS_MOTIVATION
2. Track used abilities in motivation_cards.gd
3. Show ability buttons on value cards during action selection
4. Implement ability effects when activated
5. Add abilities to 6 core archetype value cards

### Step 3: Execution

**Files Modified:**

- `value_card_resource.gd` - Added ability system:
  - AbilityType enum with 6 ability types
  - `ability_type` and `ability_value` export vars
  - `get_ability_description()` and `has_ability()` helpers

- `motivation_cards.gd` - Implemented ability activation:
  - Added `value_card_abilities_used`, `value_card_bonus_motivation`, `double_next_score` vars
  - `_create_value_card_display()` now shows ability buttons
  - `_activate_value_card_ability()` handles all ability effects
  - Abilities reset at week start (day 1, 8, etc.)
  - Score doubling applied when `double_next_score` is active

**Value Cards Updated with Abilities:**
1. `fitness_fanatic.tres` - Restore 20 willpower
2. `social_networker.tres` - Draw 2 extra cards
3. `workaholic.tres` - +30 to all tags this action
4. `daredevil.tres` - Double next action's score
5. `artist_at_heart.tres` - Reroll hand (draw 6 new cards)
6. `creature_of_habit.tres` - Restore 25 willpower

### Step 4: Commit

Committed: `3a0cbca` - "Add activatable abilities to value cards"

---

## Loop 8: Card Removal Mechanic

### Step 1: Analysis

**Gap: Deck Dilution Without Direction**

Per emergent-game-design skill:
> "Deck evolution is dilution without direction"
> "No way to remove cards"
> "What Good Deck Evolution Looks Like: Choice on gain, Removal, Upgrade, Transform"

Current problem: Deck grows with every successful action but there's no way to trim it. Player can't shape their deck toward an archetype.

**Design Goals:**
1. Allow card removal after successful actions
2. Only show option when deck is large enough (>5 cards)
3. Make removal optional (player can skip)

### Step 2: Implementation Plan

1. Add CardRemovalPanel with scrollable card display
2. Add "Forget a Card" button to result panel (only on success)
3. Display all deck cards for selection
4. Player clicks card to remove it, or "Keep All" to skip
5. Continue to next day after selection

### Step 3: Execution

**Files Modified:**

- `motivation_cards.tscn` - Added card removal UI:
  - CardRemovalPanel with title, hint, and scroll container
  - CardRemovalContainer (HBoxContainer) for card display
  - SkipRemovalButton ("Keep All")
  - ForgetCardButton in result panel (moved ContinueButton to ResultButtons HBox)

- `motivation_cards.gd` - Implemented card removal:
  - Added @onready refs for new UI nodes
  - Connected forget_card_button and skip_removal_button signals
  - `_on_forget_card_pressed()` fades to removal panel
  - `_show_card_removal()` displays all deck cards
  - `_create_removal_card_display()` makes clickable card UI
  - `_remove_card_from_deck()` removes selected card
  - `_on_skip_removal_pressed()` skips removal
  - Only shows forget button when deck.size() > 5

### Step 4: Commit

Committed: `919237e` - "Add card removal mechanic after successful actions"

---

## Loop 9: Momentum System

### Step 1: Analysis

**Gap: Single Resource (Willpower Only)**

Per emergent-game-design skill:
> "Only willpower creates decisions. Motivation isn't a resource you manage."
> "Add at least one of: Momentum - Carries over between days"

Current problem: No carry-over effects between days beyond deck changes. Each day is isolated.

**Design Goals:**
1. Add Momentum as a secondary resource
2. Gained on success, lost on failure
3. Provides scaling motivation bonus
4. Resets weekly, not daily

### Step 2: Implementation Plan

1. Add `momentum` variable to game_state.gd
2. Increase on success, decrease on failure (min 0, max 10)
3. Add momentum bonus to motivation calculation (+3 per momentum)
4. Display momentum in UI near willpower
5. Reset momentum at week start

### Step 3: Execution

**Files Modified:**

- `game_state.gd` - Added momentum system:
  - `momentum: int = 0` variable
  - `MOMENTUM_MAX: int = 10` constant
  - `MOMENTUM_BONUS_PER: int = 3` constant (+3 motivation per momentum)

- `motivation_cards.tscn` - Added MomentumLabel to TopBar with gold color

- `motivation_cards.gd` - Implemented momentum mechanics:
  - Added @onready for momentum_label
  - `_get_motivation_for_action()` includes momentum bonus
  - `_show_result()` increases momentum on success, decreases on failure
  - `_update_top_bar()` displays momentum and its bonus
  - Momentum resets at week start (day 1, 8, 15, etc.)

### Step 4: Commit

