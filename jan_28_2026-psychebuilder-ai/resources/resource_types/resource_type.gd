extends Resource

@export var id: String
@export var display_name: String
@export var description: String = ""
@export var icon: Texture2D
@export var color: Color = Color.WHITE
@export var tags: Array[String] = []
@export var decay_rate: float = 0.0  # per day, 0 = no decay, 1 = fully decays
@export var stack_size: int = 10
@export var spawn_amount: int = 1

@export_group("Danger Thresholds")
@export var danger_threshold: int = 0  # 0 = no danger warning
@export var danger_warning: String = ""

func has_tag(tag: String) -> bool:
  return tags.has(tag)

func is_positive_emotion() -> bool:
  return has_tag("emotion.positive")

func is_negative_emotion() -> bool:
  return has_tag("emotion.negative")

func is_emotion() -> bool:
  return is_positive_emotion() or is_negative_emotion() or has_tag("emotion.neutral")

func is_derived() -> bool:
  return has_tag("derived")

func is_transient() -> bool:
  return has_tag("transient")

func is_persistent() -> bool:
  return has_tag("persistent")
