@tool
extends GPUParticles2D

@export var radius: float = 200
@export var frequency: float = 1 # turns per second

func _process(delta: float) -> void:
  var angle = Time.get_ticks_msec() / 1000.0 * TAU * frequency
  global_position = Vector2.from_angle(angle) * radius
