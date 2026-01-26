class_name ValueCardResource
extends Resource

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")

@export var title: String

@export_group("Tag Scores")
@export var health_score: int = 0
@export var social_score: int = 0
@export var routine_score: int = 0
@export var effort_score: int = 0
@export var risk_score: int = 0
@export var creativity_score: int = 0


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
