extends Node2D

@onready var multi_mesh_instance: MultiMeshInstance2D = %MultiMeshInstance2D


func _ready() -> void:
  var mm := multi_mesh_instance.multimesh
  mm.instance_count = 100

  for i in mm.instance_count:
    var t := Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2.ZERO)
    t.origin = Vector2(randf_range(-200, 200), randf_range(-200, 200))
    mm.set_instance_transform_2d(i, t)


func _process(_delta: float) -> void:
  pass
