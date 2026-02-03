---
name: roguelike-ftue
description: Evaluate first-time user experience (FTUE) and onboarding for roguelike deckbuilders. Use when reviewing tutorials, starter decks, unlock sequences, tooltip design, or information architecture. Triggers on requests to audit new player experience, analyze onboarding flow, or improve teaching/discovery mechanics.
---

# FTUE & Progression Evaluation Skill for Roguelike Deckbuilders

## Purpose

This skill provides a framework for critically evaluating the first-time user experience (FTUE) and progression mechanics of roguelike deckbuilder games. It should be applied to game design documents, prototypes, or existing implementations to identify gaps, blind spots, and opportunities for improvement.

## When to Use This Skill

Apply this skill when:
- Reviewing a game's tutorial or onboarding flow
- Evaluating starter deck/content design
- Analyzing unlock and progression systems
- Assessing information architecture and tooltip design
- Preparing for playtesting with new players
- Auditing an existing game for FTUE improvements

---

## Evaluation Framework

### 1. Familiarity Scaffolding Analysis

**Core Question:** What pre-existing knowledge can players leverage, and where does the game fight against player intuitions?

**Evaluate:**
- [ ] What real-world or genre conventions does the game build on? (poker, TCGs, chess, etc.)
- [ ] Are these conventions helping or creating false expectations?
- [ ] Where might TCG players assume wrong things? (deck size, card hoarding, mana curves)
- [ ] Where might roguelike players assume wrong things? (permadeath finality, resource hoarding)
- [ ] What's genuinely novel that requires explicit teaching?

**Red Flags:**
- Novel mechanics with no analogous reference point
- Familiar-looking systems that work differently than expected (without clear signaling)
- Assuming genre literacy that casual players lack

**Recommendation Template:**
> Players familiar with [X] will expect [Y behavior], but your system actually requires [Z]. Consider: [adding explicit contrast / tutorial moment / visual distinction / early failure that teaches the difference].

---

### 2. Starter Content Audit

**Core Question:** Does the initial experience teach the core loop with minimal cognitive load while remaining engaging?

**Evaluate the Starter Deck/Loadout:**
- [ ] Can a player win early encounters using only starter content?
- [ ] Does each starter element teach exactly one concept?
- [ ] Are there any keywords or mechanics in starter content that require explanation?
- [ ] Does starter content hint at synergies without requiring them?
- [ ] Is the starter deliberately weak enough to motivate upgrades?

**Evaluate the First Run:**
- [ ] What's the minimum a player must understand to complete their first encounter?
- [ ] How many decision points exist before the first meaningful choice?
- [ ] Is the first run representative of the full experience, or a controlled subset?
- [ ] Can players fail the first run? Should they be able to?
- [ ] What does the player learn from their first death?

**Red Flags:**
- Starter content that can't win without advanced play
- Complex keywords in starting cards
- First run identical in complexity to run 100
- First death that feels random or unexplained

**Recommendation Template:**
> The starter [deck/character/loadout] currently includes [complex element]. Consider replacing with [simpler alternative] that teaches [specific concept] without requiring understanding of [dependent system].

---

### 3. Complexity Gating Assessment

**Core Question:** How does the game control when players encounter new complexity?

**Evaluate Unlock Sequences:**
- [ ] What's locked at the start vs. available immediately?
- [ ] Does unlock order match learning order? (simple → complex)
- [ ] How many runs before each major unlock?
- [ ] Can players skip ahead or must they progress linearly?
- [ ] Do unlocks feel like rewards or arbitrary gates?

**Evaluate Difficulty Progression:**
- [ ] Is there an explicit "easy mode" for learning?
- [ ] How does difficulty scale? (enemy stats, new mechanics, reduced resources)
- [ ] Can players choose their difficulty, or is it forced?
- [ ] Is the base difficulty tuned for new players or veterans?

**Complexity Layering Checklist:**
| Layer | When Introduced | What It Teaches |
|-------|-----------------|-----------------|
| Core loop | Run 1 | [Basic win condition] |
| Layer 2 | After X | [Second system] |
| Layer 3 | After Y | [Third system] |
| Full complexity | After Z | [All systems active] |

**Red Flags:**
- All content available immediately
- Unlocks that add complexity without teaching it
- No difficulty options for struggling players
- Expert-tuned base difficulty

**Recommendation Template:**
> [Mechanic X] is currently available from run 1, but depends on understanding [Y] and [Z]. Consider gating it behind [unlock condition] that ensures players have encountered [prerequisite concepts] first.

---

### 4. Information Architecture Review

**Core Question:** Can players access the information they need, when they need it, without being overwhelmed?

**Evaluate Tooltip Design:**
- [ ] Do all keywords have explanations?
- [ ] Do tooltips cascade (keywords within tooltips are also explained)?
- [ ] Is basic info visible at a glance, with detail on hover/click?
- [ ] Are numbers shown or hidden? (damage, percentages, exact values)
- [ ] Can players inspect enemy/opponent information?

**Evaluate Consequence Visibility:**
- [ ] Can players see outcomes before committing to actions?
- [ ] Are enemy intentions/actions telegraphed?
- [ ] Is there an undo or confirmation for significant choices?
- [ ] After a loss, is it clear what went wrong?

**Evaluate Progressive Disclosure:**
- [ ] What information is hidden from new players?
- [ ] When/how is hidden information revealed?
- [ ] Is there an in-game reference (glossary, bestiary, card library)?
- [ ] Can experienced players access advanced stats/data?

**Red Flags:**
- Undefined keywords or symbols
- Hidden mechanics that affect outcomes
- No preview of action consequences
- Death screens that only show "You Died"

**Recommendation Template:**
> Players cannot currently see [information X] before [decision Y]. This creates a situation where failure feels arbitrary. Consider adding [preview/tooltip/indicator] that shows [specific consequence].

---

### 5. Invisible Tutorial Techniques Audit

**Core Question:** Where can explicit tutorials be replaced with designed experiences?

**Five Methods Checklist:**

**Affordances** (visual cues indicating function)
- [ ] Do interactive elements look interactive?
- [ ] Do similar functions have consistent visual language?
- [ ] Can players identify card types/rarities at a glance?

**Skill Gates** (progress blocked until skill demonstrated)
- [ ] Are there encounters designed to test specific skills?
- [ ] Do early challenges have intentional "right answers"?
- [ ] Is the first boss a skill check for core mechanics?

**Demonstrative Method** (see before do)
- [ ] Do enemies use mechanics before players get access to them?
- [ ] Are there scripted moments showing advanced techniques?
- [ ] Can players observe AI/examples before making choices?

**Trial and Error** (designed failure with quick recovery)
- [ ] How long from death to next attempt?
- [ ] Is there meaningful information gained from each death?
- [ ] Are early failures low-cost?

**Context-Sensitive Help** (appears only when needed)
- [ ] Does help appear on first encounter with new elements?
- [ ] Does help disappear once players demonstrate understanding?
- [ ] Can help be re-accessed if needed?

**Red Flags:**
- Front-loaded text tutorials
- Unskippable explanations for experienced players
- No designed teaching moments in level/encounter design
- Long runs between learning opportunities

**Recommendation Template:**
> The [mechanic] is currently taught via [text popup/tutorial screen]. Consider replacing with [designed encounter/skill gate/demonstration] where players discover [concept] through [specific experience].

---

### 6. Failure State Analysis

**Core Question:** Does death inform or frustrate?

**Evaluate Death Experience:**
- [ ] What information is shown on the death screen?
- [ ] Is there any meta-progression from failed runs?
- [ ] How quickly can players start a new run?
- [ ] Does the game acknowledge/explain what went wrong?
- [ ] Is there variety in how runs can fail?

**Evaluate Learning From Failure:**
- [ ] Can players identify the decision that doomed them?
- [ ] Was the failure telegraphed in advance?
- [ ] Does the game offer hints for improvement?
- [ ] Are there "eureka" moments possible from analyzing failure?

**Red Flags:**
- Death screens with only statistics, no insight
- Long reload times between attempts
- Failures that feel random or unavoidable
- No meta-progression to soften repeated failure

**Recommendation Template:**
> When players die to [situation X], they currently see [death screen content]. Consider adding [specific information/hint/analysis] that helps them understand [what they could do differently].

---

## Evaluation Process

### Step 1: Gather Materials
- Design documents describing intended player journey
- Current tutorial/onboarding implementation
- Starter deck/content specifications
- Unlock and progression trees
- Any existing playtest feedback

### Step 2: Play Through as a Novice
Attempt to experience the game as a complete newcomer would:
- What's confusing in the first 5 minutes?
- What's the first decision point?
- When does the first death occur?
- What information was missing when you needed it?

### Step 3: Apply Each Framework Section
Work through each of the 6 evaluation areas systematically, checking items and noting issues.

### Step 4: Prioritize Findings
Rank issues by:
1. **Critical**: Players cannot progress or understand core loop
2. **High**: Significant confusion or frustration likely
3. **Medium**: Suboptimal but functional
4. **Low**: Polish and optimization

### Step 5: Generate Recommendations
For each issue, provide:
- Specific problem description
- Reference to successful solutions in other games
- Concrete implementation suggestion
- Expected impact on player experience

---

## Reference: Successful Patterns from Genre Leaders

### Slay the Spire
- Enemy intent icons show exact planned damage
- Cascading tooltips define all keywords
- Character unlocks gate complexity progression
- Ironclad's 80 HP + healing relic maximizes forgiveness

### Balatro
- Poker mechanics as universal scaffolding
- Stakes as sequential difficulty lessons
- First run forced to tutorial seed
- Minimal explicit tutorial, maximum discovery

### Monster Train
- Damage previews show combat resolution before commitment
- Undo button allows experimentation
- Covenant 0 as explicit easy mode
- All content available, difficulty scaled separately

### Inscryption
- Symbol-based design over text
- Forced failure as narrative progression
- Diegetic teaching through in-world character
- Mystery motivates close attention

### Hades
- Death as narrative progression
- God Mode removes difficulty barrier to story
- Character dialogue acknowledges failures
- Mirror upgrades teach meta-progression visibly

---

## Output Format

When applying this skill, produce a structured evaluation with:

```
## FTUE & Progression Evaluation: [Game Name]

### Executive Summary
[2-3 sentence overall assessment]

### Critical Issues
[Issues that block player progression or comprehension]

### High Priority Recommendations
[Significant improvements with clear implementation paths]

### Medium Priority Recommendations
[Optimizations that would improve experience]

### Low Priority / Polish
[Nice-to-haves for later iteration]

### Strengths to Preserve
[What's working well that shouldn't be changed]
```
