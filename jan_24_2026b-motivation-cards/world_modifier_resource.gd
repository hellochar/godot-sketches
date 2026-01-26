class_name WorldModifierResource
extends Resource

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")

@export var title: String

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
