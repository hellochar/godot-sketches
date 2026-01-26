class_name ValueCardResource
extends Resource

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")

enum AbilityType {
  NONE,
  EXTRA_DRAW,
  RESTORE_WILLPOWER,
  DOUBLE_NEXT_SCORE,
  REROLL_HAND,
  BONUS_MOTIVATION,
}

@export var title: String

@export_group("Tag Scores")
@export var health_score: int = 0
@export var social_score: int = 0
@export var routine_score: int = 0
@export var effort_score: int = 0
@export var risk_score: int = 0
@export var creativity_score: int = 0

@export_group("Ability")
@export var ability_type: AbilityType = AbilityType.NONE
@export var ability_value: int = 0


func get_score(tag: CardData.Tag) -> int:
  match tag:
    CardData.Tag.HEALTH: return health_score
    CardData.Tag.SOCIAL: return social_score
    CardData.Tag.ROUTINE: return routine_score
    CardData.Tag.EFFORT: return effort_score
    CardData.Tag.RISK: return risk_score
    CardData.Tag.CREATIVITY: return creativity_score
  return 0


func get_score_for_tags(action_tags: Array) -> int:
  var total := 0
  for tag in action_tags:
    total += get_score(tag)
  return total


func get_ability_description() -> String:
  match ability_type:
    AbilityType.EXTRA_DRAW:
      return "Draw %d extra cards" % ability_value
    AbilityType.RESTORE_WILLPOWER:
      return "Restore %d willpower" % ability_value
    AbilityType.DOUBLE_NEXT_SCORE:
      return "Double next action's score"
    AbilityType.REROLL_HAND:
      return "Discard hand, draw %d new cards" % ability_value
    AbilityType.BONUS_MOTIVATION:
      return "+%d to all tags this action" % ability_value
  return ""


func has_ability() -> bool:
  return ability_type != AbilityType.NONE


func get_score_description(separator: String = ", ") -> String:
  var parts: Array = []
  if health_score > 0:
    parts.append("+%d Health" % health_score)
  if social_score > 0:
    parts.append("+%d Social" % social_score)
  if routine_score > 0:
    parts.append("+%d Routine" % routine_score)
  if effort_score > 0:
    parts.append("+%d Effort" % effort_score)
  if risk_score > 0:
    parts.append("+%d Risk" % risk_score)
  if creativity_score > 0:
    parts.append("+%d Creativity" % creativity_score)
  return separator.join(parts) if not parts.is_empty() else "No bonuses"


func get_ability_text() -> String:
  return get_ability_description()
