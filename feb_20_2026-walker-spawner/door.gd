extends Sprite2D

func _ready() -> void:
  pass

func _process(_delta: float) -> void:
  pass

func _on_interactable_area_entered(area: Area2D) -> void:
  area.get_parent().queue_free()
