class_name ActionResource
extends Resource

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")

@export var title: String
@export var motivation_cost: int = 50
@export var tags: Array[CardData.Tag] = []
@export_range(0.0, 1.0, 0.05) var success_chance: float = 0.8
