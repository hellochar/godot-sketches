---
name: emergent-game-design
description: Design game mechanics that produce strategic depth through modular atomic operations—enabling lenticular elements, synergy webs, and complexity layering
---

# Emergent Game Design Skill

Design game mechanics and content that produce strategic depth, mastery curves, and "aha!" moments through modular composition—not complex individual elements.

## Core Insight

**Constrained atomic mechanics combined through modular composition generate emergent complexity without requiring complex individual pieces.**

A new player reads "Deal 6 damage" and understands immediately. That same player, 50 hours later, recognizes the card as a Strength multiplier, an exhaust trigger, a combo enabler, and a relic proc—without a single word changing. The depth lives in the interactions, not the text.

This principle applies beyond cards to any game with combinable elements: skills, items, units, abilities, buildings, upgrades, or status effects.

Explore every corner of the design space (from straightforward to exotic) without bloating individual cards with text or complex keywords. Each piece of content is an easy-to-grasp unit, and it’s the player’s assembly of these units that yields strategic depth.

Cards often solve one problem while introducing another, or only partially solve it.

---

## The Atomic Vocabulary

Every element in your game should combine pieces from a small set of **atomic operations**. Aim for 12-20 atoms total. More creates cognitive overload; fewer limits design space.

### Categories of Atoms

**Output atoms** (what the element produces):
- Direct value (damage, healing, currency, points)
- Scaling value (multipliers, percentages, "per X" effects)
- State changes (buffs, debuffs, status effects)
- Resource generation (draw, energy, mana, actions)

**Input atoms** (what the element consumes or requires):
- Resource costs (energy, HP, cards, time)
- Conditional triggers ("if enemy has X", "when you Y")
- Positioning requirements (adjacent, in zone, targeting)
- Timing windows (start of turn, on death, after X)

**Modifier atoms** (how the element behaves):
- Persistence (one-shot, duration, permanent)
- Targeting (self, single, AOE, random)
- Quantity (single, multi-hit, scaling count)
- Deck/pool manipulation (add, remove, transform, reorder)

### Design Rule: One Atom Per Tier

- **Starter/Basic elements**: 1 atom. "Deal 6 damage." "Gain 5 block."
- **Common elements**: 1-2 atoms. "Deal 6 damage. Draw 1 card."
- **Uncommon elements**: 2-3 atoms with light conditions. "Deal damage equal to your block."
- **Rare elements**: 2-4 atoms with build-defining implications. "All skills cost 0. Exhaust after playing."

Never pile unrelated atoms. "Deal 8 damage, gain 12 block, draw 2, heal 5" is bad design—it's just generically good, not synergistically interesting.

---

## Lenticular Design

Lenticular cards show different pictures depending on viewing angle. Lenticular game elements reveal different strategic depths based on player skill.

### How to Create Lenticular Elements

**Surface reading**: The literal text. A beginner can understand and use it effectively at face value.

**Intermediate reading**: Interaction with the current game state. "This is good when I have Strength." "This combos with my poison cards."

**Expert reading**: Deck/build composition implications. "This enables the infinite loop if I find the other piece." "This changes my entire draft priority."

### Example Progression

Element: "When you lose HP from a card, gain 1 Strength."

- **Novice sees**: Weird card, I don't want to hurt myself
- **Intermediate sees**: Oh, this combos with Offering (pay 6 HP, draw 3)
- **Expert sees**: This is a build-around. I now draft every self-damage card and this becomes my primary scaling engine

The card text never changes. The player's perception evolves.

### Lenticular Design Checklist

- [ ] Is there an obvious, correct use for beginners?
- [ ] Does it interact with 3+ other elements in non-obvious ways?
- [ ] Does it change draft/selection priorities for experts?
- [ ] Can experts "see" something beginners cannot?

---

## Complexity Layering

Introduce mechanics in deliberate sequence so players encounter sophistication only after mastering fundamentals.

### The Complexity Ladder

**Layer 0 - Vocabulary**: Basic actions that define the game's verbs. Damage, block, draw, energy. These are boring by design—their job is establishing grammar.

**Layer 1 - Combinations**: Two basics fused. Damage + draw. Block + buff. These teach that elements can do multiple things.

**Layer 2 - Conditions**: Effects that depend on game state. "If enemy is poisoned, deal double." "Gain block equal to cards in hand." Players learn to read the board.

**Layer 3 - Build-arounds**: Elements that define entire strategies. "All skills cost 0 but exhaust." These are intentionally parasitic—they demand the player warp their deck around them.

**Layer 4 - Emergent infinites**: Combinations of Layer 3 elements that create degenerate loops. These should be difficult to assemble but feel earned when achieved.

### Implementation Patterns

**For roguelikes/deckbuilders**: Gate complexity through rarity. Commons = Layer 1. Rares = Layer 3.

**For RPGs/progression games**: Gate through unlocks or character advancement. Early game = Layer 0-1. Endgame builds = Layer 3-4.

**For strategy games**: Gate through tech trees or unit tiers. Starting units = Layer 1. Late-game units = Layer 3.

---

## The Synergy Web

Good games have overlapping archetypes, not isolated build paths. Elements should belong to multiple synergy clusters.

### Archetype Construction

Define 4-6 archetypes per "character" or faction. Each archetype has:

1. **Core mechanic**: The central thing the archetype does (poison, strength stacking, orbs)
2. **Enablers**: Elements that generate the core resource or state
3. **Payoffs**: Elements that become powerful when the archetype is online
4. **Bridges**: Elements that belong to 2+ archetypes, creating draft flexibility

### The 30-50-20 Rule

For any element pool:
- **30% dedicated archetype cards**: Only good in their specific build
- **50% bridge cards**: Support multiple strategies
- **20% generic value**: Good in any deck, prevents complete archetype whiffs

### Preventing Solved Strategies

Synergy webs prevent "always build X" problems:

- Ensure no archetype is strictly superior—each should have different matchup profiles
- Make key enablers uncommon enough that players can't rely on finding them
- Include "pivot" elements that reward abandoning a failing archetype mid-run
- Let random elements (relics, events, bosses) invalidate or supercharge specific builds

---

## Engine Building Patterns

Engines are elements that generate recurring value without being replayed. They create the "Rube Goldberg machine" satisfaction.

### Engine Taxonomy

**Passive generators**: Produce value every turn/tick automatically.
- "+2 Strength at start of each turn"
- "Whenever you play a skill, draw a card"

**Triggered generators**: Produce value when conditions are met.
- "Whenever a card is exhausted, gain 3 block"
- "When you enter this stance, draw 2 cards"

**Converters**: Transform one resource into another.
- "Lose 6 HP to gain 2 energy and draw 3 cards"
- "Discard a card to gain 1 energy"

**Multipliers**: Increase the value of other elements.
- "Your attacks deal double damage" (stance)
- "Strength is applied 3x to this attack"

### Engine Math

Engines should feel increasingly powerful but remain bounded:

**Linear scaling**: +2 per turn. Reliable, predictable, never broken.

**Quadratic scaling**: Doubling effects (2→4→8→16). Exciting but needs caps or high costs.

**Exponential scaling**: Self-replicating (1→2→4→8 copies). Reserve for "you've won" situations or give harsh downsides.

### The Compounding Question

For every engine element, ask: "What happens if the player stacks 3 of these?"

- If it's still interesting: Good design.
- If it trivializes the game: Add diminishing returns or mutual exclusivity.
- If it does nothing extra: Make copies matter (count-based effects).

---

## Resource Manipulation

Resources create decisions. Every game needs at least 3 manipulable resources to prevent "always do the obviously best thing."

### Common Resource Types

**Action resources**: What you can do per turn (energy, mana, action points, cards in hand)

**Health resources**: Risk vs. reward (HP, shields, armor, lives)

**Scaling resources**: Compound over time (strength, multipliers, stacks, levels)

**Tempo resources**: Control pacing (card draw, deck cycling, cooldown reduction)

**Board resources**: Spatial or state control (position, orb slots, summons, territory)

### Resource Tension Principles

**No free lunches**: Powerful effects should cost multiple resource types. "+10 Strength" should cost energy AND cards AND maybe HP.

**Convertibility**: Let players trade resources. "Lose HP to gain energy" creates interesting risk calculations.

**Scarcity variance**: Some resources should be abundant (basic actions), others scarce (build-defining effects). The ratio creates meaningful choices.

**Timing costs**: "Pay now vs. pay later" is itself a resource. Ethereal effects (use it or lose it), delayed costs (shuffle a negative card into deck), and setup requirements all use time as currency.

---

## Keyword Abstraction

Keywords compress complex rules into scannable terms. They are the game's vocabulary—design them carefully.

### Keyword Design Rules

**Rule of 7**: Most players can hold ~7 keywords in memory. Prioritize the most-used mechanics.

**Self-explanatory naming**: "Exhaust" implies removal. "Innate" implies starting. "Ethereal" implies impermanence. Don't name a poison mechanic "Sparkle."

**Consistent behavior**: A keyword must ALWAYS mean the same thing. No "Exhaust (but only sometimes)" variants.

**Hover-to-learn**: Keywords can be complex if players can inspect them. The keyword itself should be short; the explanation can be a tooltip.

### Compression Examples

**Without keyword**: "This card is removed from your deck for the rest of combat when played."

**With keyword**: "Exhaust."

**Savings**: 14 words → 1 word. Repeat across 50 cards and you've saved players from reading 650 unnecessary words.

### When NOT to Keyword

- Mechanics that appear on <5 elements (just write it out)
- Effects that vary slightly each time (keywords demand consistency)
- Core actions that need emphasis (don't hide "Deal 20 damage" behind a keyword)

---

## Text Brevity

Short text creates readable elements. Readable elements enable strategic thinking instead of parsing.

### Word Count Targets

- **Basic elements**: 3-10 words
- **Standard elements**: 10-25 words
- **Complex elements**: 25-40 words
- **If exceeding 40 words**: Split into multiple elements or create a keyword

### Brevity Techniques

**Lead with the main effect**: "Deal 12 damage. If enemy is Poisoned, apply 4 Weak."

**Use numerals, not words**: "Deal 8 damage" not "Deal eight damage"

**Cut filler words**: "Gain 5 Block" not "You gain 5 points of Block"

**Imply targeting**: If it's obvious, don't state it. "Deal 6 damage" implies "to the enemy."

**Trust players to read keywords**: Don't re-explain them in card text.

### The Screenshot Test

Can a player screenshot an element and understand it without context? If no, simplify.

---

## Balancing Through Constraints

Perfect balance is impossible. Instead, create **constraint patterns** that prevent any single element from dominating.

### The Anti-Combo Constraints

**No triple-threat cards**: Never combine "high damage + high defense + card advantage" on one element. One element should solve one problem well, not all problems.

**Mutual exclusivity**: If two effects would be broken together, make them compete for the same slot/resource/timing.

**Diminishing returns**: Stacking the same buff 5x should be less than 5x as good as stacking it once.

**Counter-synergies**: If Archetype A is too strong, design elements for Archetype B that specifically punish A's strategy.

### Rarity as Balance Lever

- **Common/Basic**: Slightly below power curve. Safe, never wrong, never exciting.
- **Uncommon**: At power curve. Reliably good, won't define a run alone.
- **Rare**: Above power curve IF conditions are met. Build-arounds that reward commitment.

### The Playtest Question

"Is this element always correct to take, regardless of context?"

- If yes: Nerf it or add a meaningful downside.
- If situationally yes: Good design.
- If never: Buff it or recontextualize.

---

## Practical Workflow

### Step 1: Define Your Atoms (Day 1-2)

List every atomic operation your game will support. Group them by category. If your list exceeds 20 atoms, merge or cut. If it's under 10, you may lack design space.

### Step 2: Build the Vocabulary Layer (Week 1)

Create 8-12 basic elements that each use exactly 1 atom. These teach the game's language. They should be slightly weak—players will eventually remove or replace them.

### Step 3: Design Archetypes (Week 1-2)

Define 4-6 archetypes. For each, identify:
- The core mechanic
- 2-3 enablers
- 2-3 payoffs
- 1-2 bridges to other archetypes

Map the synergy web. Ensure at least 30% of elements belong to multiple archetypes.

### Step 4: Fill the Complexity Ladder (Week 2-3)

Distribute elements across complexity layers:
- Layer 0: 10-15% (starters, basics)
- Layer 1: 40-50% (commons, early unlocks)
- Layer 2: 25-35% (uncommons, mid-game)
- Layer 3: 10-15% (rares, build-definers)

### Step 5: Playtest Degenerate Cases (Ongoing)

Actively try to break the game:
- Stack every scaling effect
- Build "all-in" on each archetype
- Look for infinite loops
- Find the "always correct" picks

If something is too consistent, add variance or counters. If something never works, buff it or cut it.

### Step 6: Compress and Polish (Final Pass)

- Keyword any mechanic appearing 5+ times
- Cut every unnecessary word
- Ensure visual/shape language communicates type
- Verify the screenshot test passes for all elements

---

## Quick Reference Checklist

### For Every Element

- [ ] Uses 1-4 atoms maximum (based on tier)
- [ ] Has lenticular depth (different value at different skill levels)
- [ ] Fits into at least one archetype (ideally 1-3)
- [ ] Has clear counterplay or situational weakness
- [ ] Text is under 40 words
- [ ] Passes the screenshot test

### For the Whole System

- [ ] 12-20 total atomic mechanics
- [ ] 4-6 archetypes with overlapping synergies
- [ ] 30-50-20 distribution (dedicated/bridge/generic)
- [ ] No "always correct" picks
- [ ] Complexity properly gated
- [ ] At least 3 manipulable resource types
- [ ] Keyword list under 10 terms

### Red Flags

- ❌ Element does too many unrelated things
- ❌ One strategy dominates all others
- ❌ Players can't understand an element in 5 seconds
- ❌ Stacking an effect 3x trivializes the game
- ❌ An archetype has no losing matchups
- ❌ New players are overwhelmed by complexity
- ❌ Veterans have "solved" the optimal path

---

## Further Study

- **Slay the Spire** (MegaCrit): The canonical example of modular card design
- **GDC Talk**: "Slay the Spire: Metrics Driven Design and Balance" by Anthony Giovannetti
- **Dominion** (Donald X. Vaccarino): Original deckbuilder that pioneered kingdom randomization
- **Magic: The Gathering**: 30 years of keyword evolution and archetype design
- **Into the Breach**: Deterministic tactics where every piece has exactly one job
- **Hades**: Boon synergies as an action-game implementation of these principles