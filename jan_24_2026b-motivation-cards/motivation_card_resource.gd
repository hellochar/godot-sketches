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
}

enum SpecialEffect {
  NONE,
  DOUBLE_TAG_ZERO_OTHER,
  RESTORE_WILLPOWER_ON_FAIL,
  BONUS_FOR_NEW_ACTIONS,
  STREAK_SCALING,
  EXTRA_DRAW_FOR_TAG,
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
