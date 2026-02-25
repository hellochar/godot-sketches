extends Sprite2D

@export var to_turn_into: PackedScene

func _on_interactable_area_entered(area: Area2D) -> void:
  var old := area.get_parent() as Walker
  # don't convert walkers that are already of the same type
  if !old or old.scene_file_path == to_turn_into.resource_path:
    return
  var instance := to_turn_into.instantiate()
  instance.global_position = old.global_position
  var walker := instance as Walker
  if walker:
    walker.forward = old.forward
  get_parent().call_deferred("add_child", instance)
  old.die()
