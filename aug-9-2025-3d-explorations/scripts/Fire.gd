extends Node2D

signal intensity_changed(intensity, fuel)

@export var base_scale: float = 1.0
var intensity: float = 1.0
var fuel: float = 10.0

func _ready():
	var mm = get_node("/root/MultiplayerManager")
	mm.fire_state_changed.connect(_on_fire_state)
	_on_fire_state(mm.fire_intensity, mm.fire_fuel)

func _on_fire_state(new_intensity: float, new_fuel: float):
	intensity = new_intensity
	fuel = new_fuel
	scale = Vector2.ONE * (base_scale + intensity * 0.3)
	emit_signal("intensity_changed", intensity, fuel)

func feed_log():
	var mm = get_node("/root/MultiplayerManager")
	mm.feed_fire(3.0)
