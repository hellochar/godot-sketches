# Code + Architecture Review: jan_24_2026b-motivation-cards

Scope
- Focused on game logic + UI flow in `motivation_cards.gd`, state in `game_state.gd`, and data models in `card_data.gd` plus resource scripts.
- Light sample of data files to confirm wiring: `data/actions/morning_run.tres`, `data/motivation_cards/well_rested.tres`, `data/value_cards/care_health.tres`, `data/world_modifiers/raining.tres`.
- Did not load large data sets (e.g., full `starter_deck.tres`, `overnight-log.md`).

Findings (ordered by severity)
1) High: motivation math diverges between preview/attempt paths.
   - `_get_motivation_for_action` applies NEGATE/INVERT, momentum, and `value_card_bonus_motivation`, but `_calculate_motivation` (which drives `total_motivation` and willpower spend) does not. This can overcharge willpower and show inconsistent totals vs action selection. This also means NEGATE/INVERT effects only influence sorting/preview, not actual outcomes.
   - References: `motivation_cards.gd:370-395`, `motivation_cards.gd:751-760`, `motivation_cards.gd:775-809`.

2) High: special effect DOUBLE_TAG_ZERO_OTHER is defined but never implemented.
   - `MotivationCardResource.SpecialEffect.DOUBLE_TAG_ZERO_OTHER` is declared and surfaced in UI text, but the rules engine never applies it in either `_get_motivation_for_action` or `_get_special_effect_bonus`.
   - References: `motivation_cards.gd:408-446`, `motivation_card_resource.gd:8-33`.

3) Medium: `total_successes_this_week` never resets, so weekly scaling grows forever.
   - It is incremented on each success and used in `MOMENTUM_SCALING`, but there is no reset when a new week starts (only momentum and ability usage reset). This makes “per success this week” effectively lifetime.
   - References: `game_state.gd:23`, `motivation_cards.gd:505-517`, `motivation_cards.gd:427`, `motivation_cards.gd:1072`.

4) Medium: discard redraw can return duplicates from the current hand or just-discarded card.
   - `draw_motivation_cards` samples from the full deck without excluding current hand; `_discard_card` uses it without deduping (unlike EXTRA_DRAW). This can feel like discarding had no effect.
   - References: `game_state.gd:66-74`, `motivation_cards.gd:868-892`.

5) Low: Unicode arrow characters may render inconsistently across fonts/exports.
   - UI uses the Unicode arrow (U+2192) in card contribution labels and summary text; if fonts/encodings are limited, it may display as mojibake. Consider ASCII `->` or ensure the font supports it.
   - References: `motivation_cards.gd:734`, `motivation_cards.gd:941`, `motivation_cards.gd:1260`.

6) Low: parallel data models increase maintenance risk.
   - `card_data.gd` defines Action/Motivation/Value/World classes and GameState has `_create_starter_*`, but runtime uses Resource-based data via `StarterDeckResource`. This split can drift and makes it unclear which model is authoritative.
   - References: `card_data.gd:20-92`, `game_state.gd:41-120`, `motivation_cards.gd:1-8`.

Architecture notes
- `motivation_cards.gd` (~1400 lines) blends UI, animation, audio, and rules. Consider moving scoring, discard logic, and special-effect resolution into a dedicated rules module/service, then have UI observe state changes via signals. This will also make it easier to unit test scoring.
- Consider type-annotating arrays (e.g., `Array[MotivationCardResource]`) and using IDs instead of titles for tracking (e.g., `value_card_abilities_used`) to avoid collisions if titles change.

Questions / assumptions
- Should NEGATE/INVERT and other special effects affect actual attempt resolution (not just preview/sort)? If yes, `_calculate_motivation` likely needs to share the same logic as `_get_motivation_for_action`.
- Is drawing “from the full deck every time” intended, or should discards redraw without replacement from the current hand?
- Is `total_successes_this_week` meant to be weekly? If not, renaming would clarify intent.

Testing gaps
- No automated coverage for scoring, discards, or special effects. A few unit-style tests for `_get_motivation_for_action` and `_calculate_motivation` would catch the highest-risk regressions.
