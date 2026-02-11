extends DirectionalLight3D

@export var seconds_per_day: float = 180.0
@export var rotation_axis: Vector3 = Vector3(0, 0, 1)

func _process(delta: float) -> void:
  var rotation_speed = 360.0 / seconds_per_day
  rotate_object_local(rotation_axis, deg_to_rad(rotation_speed * delta))