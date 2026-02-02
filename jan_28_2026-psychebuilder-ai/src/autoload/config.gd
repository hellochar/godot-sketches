extends Node

@export_group("Time")
@export var day_duration_seconds: float = 45.0
@export var night_duration_seconds: float = 10.0
@export var total_days: int = 20

@export_group("Energy")
@export var starting_energy: int = 10
@export var max_energy: int = 20
@export var energy_regen_per_day: int = 3

@export_group("Attention")
@export var base_attention_pool: int = 10
@export var habituation_thresholds: Array[int] = [5, 15, 30, 50]
@export var habituation_costs: Array[float] = [1.0, 0.5, 0.25, 0.1, 0.0]

@export_group("Wellbeing")
@export var positive_emotion_weight: float = 2.0
@export var negative_emotion_weight: float = 1.5
@export var habit_building_weight: float = 1.0

@export_group("Endings")
@export var flourishing_threshold: int = 80
@export var growing_threshold: int = 50
@export var surviving_threshold: int = 20

@export_group("Grid")
@export var grid_size: Vector2i = Vector2i(50, 50)
@export var tile_size: int = 64

@export_group("Anxiety Spreading")
@export var anxiety_overflow_threshold: int = 8
@export var anxiety_spread_amount: int = 1
@export var anxiety_spread_interval: float = 5.0

@export_group("Grief Slowdown")
@export var grief_slowdown_threshold: int = 3
@export var grief_slowdown_factor: float = 0.15
@export var grief_max_slowdown: float = 0.7

@export_group("Habit Adjacency")
@export var habit_adjacency_bonus: float = 0.25
@export var habit_max_adjacency_multiplier: float = 2.0

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

# Tension Accumulation
@export_group("Tension Accumulation")
@export var tension_from_processing: int = 1
@export var tension_slowdown_threshold: int = 5
@export var tension_slowdown_factor: float = 0.1
@export var tension_max_slowdown: float = 0.5
@export var tension_aura_radius: int = 2
@export var cathartic_release_calm_per_tension: float = 0.5
@export var cathartic_release_insight_chance: float = 0.2

# Wisdom Efficiency Aura
@export_group("Wisdom Efficiency")
@export var wisdom_efficiency_threshold: int = 2
@export var wisdom_efficiency_bonus_per_unit: float = 0.1
@export var wisdom_max_efficiency_bonus: float = 0.5
@export var wisdom_aura_radius: int = 2

# Worry Compounding
@export_group("Worry Compounding")
@export var worry_compounding_threshold: int = 3
@export var worry_compounding_interval: float = 8.0
@export var worry_compounding_amount: int = 1
@export var worry_compounding_max: int = 15

# Doubt Propagation
@export_group("Doubt Propagation")
@export var doubt_generation_interval: float = 10.0
@export var doubt_from_waiting: int = 1
@export var doubt_from_disconnected: int = 1
@export var doubt_spread_radius: int = 2
@export var doubt_efficiency_penalty: float = 0.1
@export var doubt_max_efficiency_penalty: float = 0.4
@export var doubt_insight_combine_threshold: int = 2
@export var wisdom_from_answered_doubt: int = 1

# Nostalgia Crystallization
@export_group("Nostalgia Crystallization")
@export var nostalgia_crystallization_time: float = 30.0
@export var nostalgia_crystallization_calm_threshold: int = 3
@export var nostalgia_crystallization_negative_threshold: int = 3
@export var nostalgia_crystallization_radius: int = 2
@export var nostalgia_crystallization_amount: int = 1

# Emotional Resonance
@export_group("Emotional Resonance")
@export var resonance_min_buildings: int = 3
@export var resonance_resource_threshold: int = 3
@export var resonance_radius: int = 3
@export var resonance_positive_speed_bonus: float = 0.25
@export var resonance_negative_amplification_interval: float = 8.0
@export var resonance_negative_amplification_amount: int = 1
@export var resonance_positive_resources: Array[String] = ["joy", "calm", "insight", "wisdom"]
@export var resonance_negative_resources: Array[String] = ["anxiety", "grief", "doubt", "worry"]

# Worker Focus Imprint
@export_group("Worker Focus Imprint")
@export var focus_imprint_gain_per_cycle: float = 0.05
@export var focus_imprint_max_level: float = 1.0
@export var focus_efficiency_bonus_at_max: float = 0.5
@export var focus_unfamiliar_penalty: float = 0.3
@export var focus_decay_rate: float = 0.01
@export var focus_transfer_threshold: int = 10

# Building Saturation
@export_group("Building Saturation")
@export var saturation_threshold: float = 0.8
@export var saturation_time_required: float = 15.0
@export var saturation_joy_spread_rate: float = 1.0
@export var saturation_joy_numbness_factor: float = 0.5
@export var saturation_calm_aura_multiplier: float = 2.0
@export var saturation_grief_wisdom_rate: float = 0.2
@export var saturation_anxiety_panic_chance: float = 0.1
@export var saturation_anxiety_panic_spread: int = 3
@export var saturation_wisdom_efficiency_bonus: float = 0.3

# Road Emotional Memory
@export_group("Road Emotional Memory")
@export var road_memory_threshold: int = 10
@export var road_memory_decay_rate: float = 0.1
@export var road_imprint_speed_bonus: float = 0.25
@export var road_imprint_speed_penalty: float = 0.15
@export var road_memory_gain_per_pass: float = 1.0
@export var road_positive_emotions: Array[String] = ["joy", "calm", "insight", "wisdom"]
@export var road_negative_emotions: Array[String] = ["anxiety", "grief", "doubt", "worry"]

# Processing Cascade
@export_group("Processing Cascade")
@export var cascade_direct_storage: bool = true
@export var cascade_processor_transfer: int = 1
@export var cascade_generator_boost_duration: float = 3.0
@export var cascade_generator_boost_amount: float = 0.5

@export_group("Core Beliefs")
@export var belief_grief_required: int = 20
@export var belief_joy_threshold: int = 10
@export var belief_joy_days_required: int = 5
@export var belief_calm_threshold: int = 8
@export var belief_calm_days_required: int = 5
@export var belief_wisdom_required: int = 15
@export var belief_insight_required: int = 12
@export var belief_handle_difficulty_bonus: float = 0.2
@export var belief_joy_resilient_bonus: float = 0.15
@export var belief_calm_foundation_bonus: float = 0.15
@export var belief_growth_adversity_bonus: float = 0.2
@export var belief_mindful_awareness_bonus: float = 0.1

@export_group("Emotional Momentum")
@export var momentum_gain_per_cycle: float = 0.15
@export var momentum_max_level: float = 1.0
@export var momentum_speed_bonus_at_max: float = 0.5
@export var momentum_decay_on_break: float = 0.5
@export var momentum_starvation_timeout: float = 5.0
@export var momentum_break_penalty_duration: float = 3.0
@export var momentum_break_penalty_amount: float = 0.2

@export_group("Support Network")
@export var support_network_min_size: int = 2
@export var support_network_efficiency_per_member: float = 0.1
@export var support_network_max_efficiency_bonus: float = 0.4
@export var support_network_load_share_threshold: float = 0.9
@export var support_network_transfer_amount: int = 2
@export var support_network_transfer_interval: float = 3.0

@export_group("Building Awakening")
@export var awakening_experience_per_process: int = 1
@export var awakening_threshold: int = 20
@export var awakening_speed_bonus: float = 0.5
@export var awakening_output_bonus: int = 1
@export var awakening_storage_bonus: int = 5
@export var awakening_generator_rate_bonus: float = 0.25

@export_group("Emotional Breakthrough")
@export var breakthrough_window_duration: float = 8.0
@export var breakthrough_types_required: int = 3
@export var breakthrough_process_amount_required: int = 2
@export var breakthrough_insight_reward: int = 3
@export var breakthrough_wisdom_reward: int = 2
@export var breakthrough_conversion_rate: float = 0.5
@export var breakthrough_speed_buff_duration: float = 10.0
@export var breakthrough_speed_buff_amount: float = 0.3
@export var breakthrough_cooldown: float = 30.0
@export var breakthrough_negative_types: Array[String] = ["grief", "anxiety", "tension", "worry", "doubt"]

@export_group("Building Fatigue")
@export var fatigue_gain_per_process: float = 0.1
@export var fatigue_max_level: float = 1.0
@export var fatigue_recovery_rate: float = 0.05
@export var fatigue_calm_recovery_bonus: float = 0.02
@export var fatigue_calm_radius: int = 2
@export var fatigue_speed_penalty_at_max: float = 0.4
@export var fatigue_onset_threshold: float = 0.3

@export_group("Emotional Echo")
@export var echo_gain_per_process: float = 0.2
@export var echo_max_level: float = 1.0
@export var echo_decay_rate: float = 0.02
@export var echo_same_type_bonus: float = 0.3
@export var echo_different_type_penalty: float = 0.15
@export var echo_threshold: float = 0.3

@export_group("Emotional Weather")
@export var weather_resource_scale: float = 20.0
@export var weather_momentum_lerp: float = 0.5
@export var weather_storm_threshold: float = 1.5
@export var weather_overcast_threshold: float = 1.0
@export var weather_fog_threshold: float = 1.2
@export var weather_stillness_threshold: float = 1.2
@export var weather_clear_threshold: float = 1.0
@export var weather_clear_processing_bonus: float = 0.15
@export var weather_clear_joy_gen_bonus: float = 0.2
@export var weather_clear_habit_bonus: float = 0.1
@export var weather_storm_processing_penalty: float = 0.25
@export var weather_storm_negative_gen_bonus: float = 0.3
@export var weather_storm_habit_penalty: float = 0.2
@export var weather_overcast_grief_gen_bonus: float = 0.15
@export var weather_fog_processing_penalty: float = 0.1
@export var weather_stillness_processing_bonus: float = 0.1
@export var weather_stillness_habit_bonus: float = 0.15
