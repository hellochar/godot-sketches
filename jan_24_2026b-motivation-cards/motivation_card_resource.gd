class_name MotivationCardResource
extends Resource

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")

@export var title: String
@export var is_temporary: bool = false

@export_group("Tag Modifiers")
@export var health_modifier: int = 0
@export var social_modifier: int = 0
@export var routine_modifier: int = 0
@export var effort_modifier: int = 0
@export var risk_modifier: int = 0
@export var creativity_modifier: int = 0


func get_modifier(tag: CardData.Tag) -> int:
  match tag:
    CardData.Tag.HEALTH: return health_modifier
    CardData.Tag.SOCIAL: return social_modifier
    CardData.Tag.ROUTINE: return routine_modifier
    CardData.Tag.EFFORT: return effort_modifier
    CardData.Tag.RISK: return risk_modifier
    CardData.Tag.CREATIVITY: return creativity_modifier
  return 0


func get_motivation_for_tags(action_tags: Array) -> int:
  var total := 0
  for tag in action_tags:
    total += get_modifier(tag)
  return total


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
