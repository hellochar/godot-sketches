extends Sprite2D

@export var points: int = 0

func _ready() -> void:
  pass

func _process(_delta: float) -> void:
  pass

func _on_interactable_area_entered(area: Area2D) -> void:
  points += 1
  # area.get_parent().queue_free()
  Utils.floating_text(global_position, "+1", Color.GREEN, Vector2(0, -40), 1.0)
