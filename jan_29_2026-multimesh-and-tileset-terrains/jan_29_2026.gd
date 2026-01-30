@tool
extends Node2D

@onready var multi_mesh_instance: MultiMeshInstance2D = %MultiMeshInstance2D
@export var player_node: Node2D

@export var set_instances: bool:
  set(value):
    make_instances()

func _ready() -> void:
  if multi_mesh_instance.multimesh.instance_count == 0:
    make_instances()

func make_instances() -> void:
  var mm := multi_mesh_instance.multimesh
  mm.instance_count = 200

  for i in mm.instance_count:
    var t := Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2.ZERO)
    t.origin = Vector2(randf_range(-100, 100), randf_range(-100, 100))
    mm.set_instance_transform_2d(i, t)


func _process(_delta: float) -> void:
  if Engine.is_editor_hint():
    return
  var shader_material := multi_mesh_instance.material as ShaderMaterial
  if shader_material and player_node:
    shader_material.set_shader_parameter("player_position", player_node.global_position)
