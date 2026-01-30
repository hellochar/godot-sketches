extends Node

# Time
@export var day_duration_seconds: float = 45.0
@export var total_days: int = 20

# Energy
@export var starting_energy: int = 10
@export var max_energy: int = 20
@export var energy_regen_per_day: int = 3

# Attention
@export var base_attention_pool: int = 10
@export var habituation_thresholds: Array[int] = [5, 15, 30, 50]
@export var habituation_costs: Array[float] = [1.0, 0.5, 0.25, 0.1, 0.0]

# Events
@export var inciting_incident_day: int = 5
@export var random_event_chance: float = 0.3

# Wellbeing
@export var positive_emotion_weight: float = 2.0
@export var derived_resource_weight: float = 3.0
@export var negative_emotion_weight: float = 1.5
@export var unprocessed_negative_weight: float = 2.0
@export var habit_building_weight: float = 1.0
@export var adjacency_synergy_weight: float = 0.5
@export var wellbeing_normalizer: float = 50.0

# Endings
@export var flourishing_threshold: int = 80
@export var growing_threshold: int = 50
@export var surviving_threshold: int = 20

# Grid
@export var grid_size: Vector2i = Vector2i(50, 50)
@export var tile_size: int = 64
