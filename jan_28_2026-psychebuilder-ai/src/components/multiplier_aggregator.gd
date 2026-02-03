class_name MultiplierAggregator
extends RefCounted

enum Type {
  SPEED,
  OUTPUT,
  GENERATION,
  STORAGE
}

var _multipliers: Dictionary = {}

func _init() -> void:
  for type in Type.values():
    _multipliers[type] = []

func add(type: Type, source: String, value: float) -> void:
  if value == 1.0:
    return
  _multipliers[type].append({"source": source, "value": value})

func clear() -> void:
  for type in Type.values():
    _multipliers[type].clear()

func get_combined(type: Type) -> float:
  var result = 1.0
  for entry in _multipliers[type]:
    result *= entry["value"]
  return result

func get_breakdown(type: Type) -> Array:
  return _multipliers[type].duplicate()

func has_entries(type: Type) -> bool:
  return _multipliers[type].size() > 0
