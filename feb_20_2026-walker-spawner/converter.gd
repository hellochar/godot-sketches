extends Sprite2D

@export var to_turn_into: PackedScene

func _on_interactable_area_entered(area: Area2D) -> void:
  var old := area.get_parent() as Walker
	# convert the entered walker into the to_turn_into
  var instance := to_turn_into.instantiate()
  instance.global_position = old.global_position
  var walker := instance as Walker
  if walker:
    instance.forward = old.forward
  get_parent().call_deferred("add_child", instance)
  area.get_parent().call_deferred("queue_free")
