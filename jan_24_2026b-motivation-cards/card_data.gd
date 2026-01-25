class_name CardData
extends RefCounted

enum Tag { HEALTH, SOCIAL, ROUTINE, EFFORT, RISK, CREATIVITY }

const TAG_NAMES := {
  Tag.HEALTH: "Health",
  Tag.SOCIAL: "Social",
  Tag.ROUTINE: "Routine",
  Tag.EFFORT: "Effort",
  Tag.RISK: "Risk",
  Tag.CREATIVITY: "Creativity",
}

const TAG_COLORS := {
  Tag.HEALTH: Color(0.2, 0.8, 0.3),
  Tag.SOCIAL: Color(0.3, 0.5, 0.9),
  Tag.ROUTINE: Color(0.6, 0.5, 0.4),
  Tag.EFFORT: Color(0.9, 0.5, 0.2),
  Tag.RISK: Color(0.9, 0.2, 0.3),
  Tag.CREATIVITY: Color(0.8, 0.3, 0.8),
}


class ActionData:
  var title: String
  var motivation_cost: int
  var tags: Array
  var success_chance: float
  var success_consequences: Array
  var failure_consequences: Array

  func _init(p_title: String, p_cost: int, p_tags: Array, p_success: float) -> void:
    title = p_title
    motivation_cost = p_cost
    tags = p_tags
    success_chance = p_success
    success_consequences = []
    failure_consequences = []


class MotivationCard:
  var title: String
  var tag_modifiers: Dictionary
  var is_temporary: bool

  func _init(p_title: String, p_modifiers: Dictionary, p_temp: bool = false) -> void:
    title = p_title
    tag_modifiers = p_modifiers
    is_temporary = p_temp

  func get_motivation_for_tags(action_tags: Array) -> int:
    var total := 0
    for tag in action_tags:
      if tag_modifiers.has(tag):
        total += tag_modifiers[tag]
    return total

  func format_modifiers() -> String:
    var parts: Array = []
    for tag in tag_modifiers:
      var val: int = tag_modifiers[tag]
      var sign_str := "+" if val >= 0 else ""
      parts.append("%s%d %s" % [sign_str, val, TAG_NAMES[tag]])
    return "\n".join(parts)


class ValueCard:
  var title: String
  var tag_scores: Dictionary

  func _init(p_title: String, p_scores: Dictionary) -> void:
    title = p_title
    tag_scores = p_scores

  func get_score_for_tags(action_tags: Array) -> int:
    var total := 0
    for tag in action_tags:
      if tag_scores.has(tag):
        total += tag_scores[tag]
    return total


class WorldModifier:
  var title: String
  var tag_modifiers: Dictionary

  func _init(p_title: String, p_modifiers: Dictionary) -> void:
    title = p_title
    tag_modifiers = p_modifiers

  func get_motivation_for_tags(action_tags: Array) -> int:
    var total := 0
    for tag in action_tags:
      if tag_modifiers.has(tag):
        total += tag_modifiers[tag]
    return total


class Consequence:
  enum Type { ADD_MOTIVATION, REMOVE_MOTIVATION, ADD_VALUE, MODIFY_WILLPOWER, ADD_TEMP_MOTIVATION }
  var type: Type
  var card: Variant
  var value: int

  func _init(p_type: Type, p_card: Variant = null, p_value: int = 0) -> void:
    type = p_type
    card = p_card
    value = p_value
