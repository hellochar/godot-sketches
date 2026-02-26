extends Node3D

@onready var grass_material: ShaderMaterial = %grass_multi.multimesh.mesh.surface_get_material(0)
@onready var character: CharacterBody3D = %CharacterBody3D

func _process(_delta: float) -> void:
  grass_material.set_shader_parameter("player_world_position", character.global_position)
