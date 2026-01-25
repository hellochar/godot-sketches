# Motivation-Driven Action Prototype

## Conversation Summary (Context for New Agents)
This document summarizes the entire discussion to date so an AI agent with no
prior context can begin implementation.

- The core concept is **motivation as activation energy**: every action has a
  motivation cost that must be met using internal motivations plus optional
  willpower spend.
- The player has a **finite willpower pool** (daily) that can be spent to cover
  motivation gaps. Willpower is a universal resource.
- **Motivations are cards** (feelings, thoughts, memories, predictions, senses,
  and other internal drivers). There can be synergies between cards, and cards
  can be positive or negative.
- **External world factors** (e.g., “It’s raining”) are not part of the player’s
  internal deck. They are world modifiers applied to the current action.
- Actions should not have hard-coded scores. **Scoring comes from value cards**
  that represent what the player cares about (e.g., “I value health”).
- There are **no tiers** in the MVP: each action is success/failure only.
- **Success chance** is a separate mechanic from motivation (skill-based roll).
- The game should feel **realistic**, with a **humorous and uplifting tone**, but
  with real emotional stakes.
- The player **chooses actions** most of the time, though events can force an
  action. This choice is the player’s main agency.
- Deck evolution is **spontaneous rather than chosen**: actions yield new cards
  from consequence lists instead of “pick one of three” rewards. This better
  reflects how people gain or lose traits/feelings without explicit choice.
- **Card removal** is allowed to prevent deck bloat and represent growth.
- There is interest in richer secondary/tertiary resources later, but MVP should
  stay simple to prototype quickly.

## Goals
- Keep the loop **dead simple and playable** while validating the core idea:
  - Actions require motivation.
  - Motivation comes from internal psyche cards plus external world modifiers.
  - Success/failure has consequences.
  - Scoring is determined by the player’s values, not the action itself.

## Core Loop (Minimal)
1. **Action appears** (player chooses, or an event forces it).
2. **World modifiers apply** (external events like weather, interruptions).
3. **Draw psyche motivations** (internal deck).
4. **Meet activation energy** (motivation threshold + optional willpower spend).
5. **Resolve success roll** (success or failure).
6. **Apply consequences** (success/failure lists).
7. **Score** based on value cards.
8. **Deck evolves** (gain/lose cards).

## Systems Overview

### Actions
Actions define:
- **Motivation cost** (activation energy).
- **Tags** (e.g., Health, Social, Routine, Effort, Risk, Creativity).
- **Success chance** (skill roll).
- **Consequences** (separate success/failure outcomes).

**Example**
```
Go for a Morning Run
Cost: 75
Tags: Health, Effort, Routine
Success: 80%
On Success: apply success consequence list
On Failure: apply failure consequence list
```

### Motivation (Psyche) Cards
Internal, controllable deck. Provide **motivation** based on action tags.

**Examples**
- “I value health” → +25 if Health.
- “I avoid discomfort” → -15 if Effort.
- “I seek routine” → +15 if Routine.

These cards **do not** directly score; they help you act.

### Value Cards (Scoring)
Separate set from motivations. These determine **why** an action matters.

**Examples**
- “I care about health” → +10 score if Health.
- “Community matters” → +10 score if Social.
- “Reminds me of my father” → +15 score if Routine + Memory tag.

Actions themselves **do not** contain fixed score values. Scoring is purely
based on the player’s value cards when an action succeeds (or optionally when
it fails, depending on consequence rules).

### World Modifiers (External)
External conditions are **not** in the psyche deck. They are drawn or applied
per action, reflecting the world’s impact.

**Examples**
- “It’s raining” → -10 to Effort actions.
- “Friend texts you” → +10 to Social actions.

### Willpower
Universal resource that can be spent to cover motivation gaps.

## Consequences
Actions have **success** and **failure** consequence lists.
Consequences can:
- Add or remove cards.
- Trigger temporary cards (1 day).
- Modify future success chances.
- Adjust willpower.
- Affect scoring through new value cards.

This creates a flexible framework: success/failure can both be meaningful,
emotional, and mechanically impactful.

## Card Gains (Non-Choice by Default)
To reflect how feelings and traits are often discovered rather than selected:
- Actions generate cards **spontaneously** from their consequence lists.
- The player’s agency comes from **which actions they choose**, not from
  picking reward cards.

If more control is needed later, add a soft “decline” option or identity slot
management rather than full card choice.

## Card Removal
Allow removing cards to avoid runaway deck bloat and to represent growth.
Removal can be:
- Directly triggered by consequences.
- Earned through specific actions or events.

## Prototype Defaults (Fast Build)
- **Tag set:** Health, Social, Routine, Effort, Risk, Creativity.
- **Motivation draw:** 5 cards per action.
- **World modifiers:** 0–2 cards per action.
- **Willpower:** daily pool (refill per day).
- **Deck sizes:** ~15–20 motivations, ~5–8 values.

## Open Questions (Optional, Later)
- Should failures still generate score if the player’s values align?
- How often should values evolve (rare vs. frequent)?
- Do identity slots add clarity or unnecessary complexity for the MVP?
