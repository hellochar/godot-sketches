extends CanvasLayer

@export var player: CharacterBody2D

@onready var plants_label: Label = $PlantsLabel

func _process(_delta: float) -> void:
	if player:
		plants_label.text = "Plants: %d" % player.plants
