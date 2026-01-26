class_name MotivationCardResource
extends Resource

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")

enum ConditionType {
  NONE,
  MIN_CARDS_OF_TAG,
  MAX_CARDS_OF_TAG,
  ACTION_HAS_MIN_TAGS,
  ONLY_CARD_OF_TAG,
  ACTION_HAS_TAG,
  LOW_ACTION_COST,
  SUCCEEDED_YESTERDAY,
  HIGH_ACTION_COST,
  LOW_SUCCESS_CHANCE,
  DISCARDED_THIS_TURN,
  REPEATED_ACTION,
  LOW_WILLPOWER,
  FAILED_YESTERDAY,
  ACTION_HAS_BOTH_TAGS,
}

enum SpecialEffect {
  NONE,
  DOUBLE_TAG_ZERO_OTHER,
  RESTORE_WILLPOWER_ON_FAIL,
  BONUS_FOR_NEW_ACTIONS,
  STREAK_SCALING,
  EXTRA_DRAW_FOR_TAG,
  RESTORE_WILLPOWER_ON_SUCCESS,
  EXTRA_DRAW_ON_SUCCESS,
  MOMENTUM_SCALING,
  DISCARD_SCALING,
  AMPLIFY_ALL,
  EXHAUST_BONUS,
  DRAIN_WILLPOWER_ON_SUCCESS,
  REDUCE_MAX_WILLPOWER,
  NEGATE_NEGATIVES,
  INVERT_NEGATIVES,
  BONUS_PER_NEGATIVE_CARD,
  SCORE_BONUS,
  EXTRA_DISCARD,
  DISCARD_DRAW_BONUS,
}

@export var title: String
@export var is_temporary: bool = false

@export_group("Tag Modifiers")
@export var health_modifier: int = 0
@export var social_modifier: int = 0
@export var routine_modifier: int = 0
@export var effort_modifier: int = 0
@export var risk_modifier: int = 0
@export var creativity_modifier: int = 0

@export_group("Conditional Effect")
@export var condition_type: ConditionType = ConditionType.NONE
@export var condition_tag: CardData.Tag = CardData.Tag.HEALTH
@export var condition_secondary_tag: CardData.Tag = CardData.Tag.HEALTH
@export var condition_threshold: int = 0
@export var bonus_multiplier: float = 2.0

@export_group("Special Effect")
@export var special_effect: SpecialEffect = SpecialEffect.NONE
@export var special_target_tag: CardData.Tag = CardData.Tag.CREATIVITY
@export var special_value: int = 0


func get_modifier(tag: CardData.Tag) -> int:
  match tag:
    CardData.Tag.HEALTH: return health_modifier
    CardData.Tag.SOCIAL: return social_modifier
    CardData.Tag.ROUTINE: return routine_modifier
    CardData.Tag.EFFORT: return effort_modifier
    CardData.Tag.RISK: return risk_modifier
    CardData.Tag.CREATIVITY: return creativity_modifier
  return 0


func get_motivation_for_tags(action_tags: Array, context: Dictionary = {}) -> int:
  var total := 0
  if special_effect == SpecialEffect.DOUBLE_TAG_ZERO_OTHER:
    if special_target_tag in action_tags:
      total = get_modifier(special_target_tag) * 2
  else:
    for tag in action_tags:
      total += get_modifier(tag)

  if condition_type != ConditionType.NONE:
    if check_condition(context):
      total = int(total * bonus_multiplier)

  return total


func check_condition(context: Dictionary) -> bool:
  match condition_type:
    ConditionType.NONE:
      return true
    ConditionType.MIN_CARDS_OF_TAG:
      var count: int = context.get("tag_counts", {}).get(condition_tag, 0)
      return count >= condition_threshold
    ConditionType.MAX_CARDS_OF_TAG:
      var count: int = context.get("tag_counts", {}).get(condition_tag, 0)
      return count <= condition_threshold
    ConditionType.ACTION_HAS_MIN_TAGS:
      var tag_count: int = context.get("action_tag_count", 0)
      return tag_count >= condition_threshold
    ConditionType.ONLY_CARD_OF_TAG:
      var count: int = context.get("tag_counts", {}).get(condition_tag, 0)
      return count == 1
    ConditionType.ACTION_HAS_TAG:
      var action_tags: Array = context.get("action_tags", [])
      return condition_tag in action_tags
    ConditionType.LOW_ACTION_COST:
      var cost: int = context.get("action_cost", 999)
      return cost < condition_threshold
    ConditionType.SUCCEEDED_YESTERDAY:
      return context.get("succeeded_yesterday", false)
    ConditionType.HIGH_ACTION_COST:
      var cost: int = context.get("action_cost", 0)
      return cost > condition_threshold
    ConditionType.LOW_SUCCESS_CHANCE:
      var chance: float = context.get("success_chance", 1.0)
      return chance < (condition_threshold / 100.0)
    ConditionType.DISCARDED_THIS_TURN:
      var discards: int = context.get("discards_this_turn", 0)
      return discards >= condition_threshold
    ConditionType.REPEATED_ACTION:
      var action_title: String = context.get("action_title", "")
      var last_success: String = context.get("last_successful_action_title", "")
      return action_title == last_success and not action_title.is_empty()
    ConditionType.LOW_WILLPOWER:
      var willpower: int = context.get("willpower", 100)
      return willpower <= condition_threshold
    ConditionType.FAILED_YESTERDAY:
      return context.get("failed_yesterday", false)
    ConditionType.ACTION_HAS_BOTH_TAGS:
      var action_tags: Array = context.get("action_tags", [])
      return condition_tag in action_tags and condition_secondary_tag in action_tags
  return false


func get_condition_text() -> String:
  match condition_type:
    ConditionType.NONE:
      return ""
    ConditionType.MIN_CARDS_OF_TAG:
      return "If %d+ %s cards" % [condition_threshold, CardData.TAG_NAMES[condition_tag]]
    ConditionType.MAX_CARDS_OF_TAG:
      return "If %d or fewer %s cards" % [condition_threshold, CardData.TAG_NAMES[condition_tag]]
    ConditionType.ACTION_HAS_MIN_TAGS:
      return "If action has %d+ tags" % condition_threshold
    ConditionType.ONLY_CARD_OF_TAG:
      return "If only %s card" % CardData.TAG_NAMES[condition_tag]
    ConditionType.ACTION_HAS_TAG:
      return "If %s action" % CardData.TAG_NAMES[condition_tag]
    ConditionType.LOW_ACTION_COST:
      return "If cost < %d" % condition_threshold
    ConditionType.SUCCEEDED_YESTERDAY:
      return "If succeeded yesterday"
    ConditionType.HIGH_ACTION_COST:
      return "If cost > %d" % condition_threshold
    ConditionType.LOW_SUCCESS_CHANCE:
      return "If success < %d%%" % condition_threshold
    ConditionType.DISCARDED_THIS_TURN:
      if condition_threshold <= 1:
        return "If discarded this turn"
      return "If discarded %d+ this turn" % condition_threshold
    ConditionType.REPEATED_ACTION:
      return "If same action as last success"
    ConditionType.LOW_WILLPOWER:
      return "If willpower <= %d" % condition_threshold
    ConditionType.FAILED_YESTERDAY:
      return "If failed yesterday"
    ConditionType.ACTION_HAS_BOTH_TAGS:
      return "If %s + %s action" % [CardData.TAG_NAMES[condition_tag], CardData.TAG_NAMES[condition_secondary_tag]]
  return ""


func get_special_effect_text() -> String:
  match special_effect:
    SpecialEffect.NONE:
      return ""
    SpecialEffect.DOUBLE_TAG_ZERO_OTHER:
      return "2x %s, 0 others" % CardData.TAG_NAMES[special_target_tag]
    SpecialEffect.RESTORE_WILLPOWER_ON_FAIL:
      return "+%d willpower on fail" % special_value
    SpecialEffect.BONUS_FOR_NEW_ACTIONS:
      return "+%d for new actions" % special_value
    SpecialEffect.STREAK_SCALING:
      return "+%d per success streak" % special_value
    SpecialEffect.EXTRA_DRAW_FOR_TAG:
      return "+1 draw if %s action" % CardData.TAG_NAMES[special_target_tag]
    SpecialEffect.RESTORE_WILLPOWER_ON_SUCCESS:
      return "+%d willpower on success" % special_value
    SpecialEffect.EXTRA_DRAW_ON_SUCCESS:
      return "+1 draw on success"
    SpecialEffect.MOMENTUM_SCALING:
      return "+%d per success this week" % special_value
    SpecialEffect.DISCARD_SCALING:
      return "+%d per discard this turn" % special_value
    SpecialEffect.AMPLIFY_ALL:
      return "Double all other modifiers"
    SpecialEffect.EXHAUST_BONUS:
      return "Exhaust: +%d, removes card" % special_value
    SpecialEffect.DRAIN_WILLPOWER_ON_SUCCESS:
      return "-%d willpower on success" % special_value
    SpecialEffect.REDUCE_MAX_WILLPOWER:
      return "-%d max willpower on success" % special_value
    SpecialEffect.NEGATE_NEGATIVES:
      return "Negate all negative modifiers"
    SpecialEffect.INVERT_NEGATIVES:
      return "Invert negatives to positives"
    SpecialEffect.BONUS_PER_NEGATIVE_CARD:
      return "+%d per negative card in hand" % special_value
    SpecialEffect.SCORE_BONUS:
      return "+%d score on success" % special_value
    SpecialEffect.EXTRA_DISCARD:
      return "+%d discards this turn" % special_value
    SpecialEffect.DISCARD_DRAW_BONUS:
      return "Draw %d extra when discarding" % special_value
  return ""


func format_modifiers() -> String:
  var parts: Array = []
  if health_modifier != 0:
    parts.append("%s%d Health" % ["+" if health_modifier > 0 else "", health_modifier])
  if social_modifier != 0:
    parts.append("%s%d Social" % ["+" if social_modifier > 0 else "", social_modifier])
  if routine_modifier != 0:
    parts.append("%s%d Routine" % ["+" if routine_modifier > 0 else "", routine_modifier])
  if effort_modifier != 0:
    parts.append("%s%d Effort" % ["+" if effort_modifier > 0 else "", effort_modifier])
  if risk_modifier != 0:
    parts.append("%s%d Risk" % ["+" if risk_modifier > 0 else "", risk_modifier])
  if creativity_modifier != 0:
    parts.append("%s%d Creativity" % ["+" if creativity_modifier > 0 else "", creativity_modifier])
  return "\n".join(parts)
