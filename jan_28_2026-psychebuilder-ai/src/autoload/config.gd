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

# Wellbeing
@export var positive_emotion_weight: float = 2.0
@export var negative_emotion_weight: float = 1.5
@export var habit_building_weight: float = 1.0

# Endings
@export var flourishing_threshold: int = 80
@export var growing_threshold: int = 50
@export var surviving_threshold: int = 20

# Grid
@export var grid_size: Vector2i = Vector2i(50, 50)
@export var tile_size: int = 64

# Anxiety Spreading
@export var anxiety_overflow_threshold: int = 8
@export var anxiety_spread_amount: int = 1
@export var anxiety_spread_interval: float = 5.0

# Grief Slowdown
@export var grief_slowdown_threshold: int = 3
@export var grief_slowdown_factor: float = 0.15
@export var grief_max_slowdown: float = 0.7

# Habit Adjacency
@export var habit_adjacency_bonus: float = 0.25
@export var habit_max_adjacency_multiplier: float = 2.0

# Joy Speed Boost
@export_group("Joy Speed Boost")
@export var joy_carry_speed_bonus: float = 0.5
@export var joy_proximity_speed_bonus: float = 0.3
@export var joy_proximity_radius: float = 96.0
@export var joy_boost_duration: float = 3.0

# Dream Recombination
@export_group("Dream Recombination")
@export var dream_recombination_chance: float = 0.4
@export var dream_recipes: Dictionary = {
  "joy+grief": "nostalgia",
  "calm+wisdom": "insight",
  "nostalgia+calm": "joy",
  "grief+wisdom": "calm",
  "anxiety+joy": "calm",
}

# Calm Aura
@export_group("Calm Aura")
@export var calm_aura_radius: int = 2
@export var calm_aura_threshold: int = 3
@export var calm_aura_suppression: float = 0.15
@export var calm_aura_max_suppression: float = 0.6

# Worker Emotional Contamination
@export_group("Worker Contamination")
@export var contamination_absorb_rate: float = 0.1
@export var contamination_deposit_rate: float = 0.05
@export var contamination_decay_rate: float = 0.02
@export var contamination_speed_negative: float = 0.2
@export var contamination_speed_positive: float = 0.15
@export var contamination_max_level: float = 5.0
