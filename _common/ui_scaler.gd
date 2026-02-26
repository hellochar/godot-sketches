class_name UIScaler
extends SubViewportContainer

@export var ui_scale: float = 1.5:
  set(v):
    ui_scale = v
    _update_scale()

@onready var _viewport: SubViewport = $SubViewport


func _ready() -> void:
  stretch = true
  _viewport.size_2d_override_stretch = true
  resized.connect(_update_scale)
  _update_scale()


func _update_scale() -> void:
  if not is_inside_tree():
    return
  _viewport.size_2d_override = Vector2i(size / ui_scale)
