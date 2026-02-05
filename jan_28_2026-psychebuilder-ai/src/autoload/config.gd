class_name Config
extends Node

static var instance: Config
func _init(): instance = self

@export_group("Time")
@export var day_duration_seconds: float = 50.0
@export var night_duration_seconds: float = 8.0
@export var total_days: int = 20

@export_group("Energy")
@export var starting_energy: int = 8
@export var max_energy: int = 20
@export var energy_regen_per_day: int = 4

@export_group("Attention")
@export var base_attention_pool: int = 10
@export var habituation_thresholds: Array[int] = [3, 10, 25, 45]
@export var habituation_costs: Array[float] = [1.0, 0.5, 0.25, 0.1, 0.0]

@export_group("Wellbeing Formula")
@export var positive_emotion_weight: float = 2.0
@export var negative_emotion_weight: float = 1.5
@export var derived_resource_weight: float = 3.0
@export var unprocessed_negative_weight: float = 2.0
@export var habit_building_weight: float = 1.0
@export var adjacency_synergy_weight: float = 0.5
@export var wellbeing_normalizer: float = 50.0

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

@export_group("Harmony Bonus")
@export var harmony_pairs: Dictionary = {
  "memory_well": ["memory_processor", "mourning_chapel"],
  "wound": ["mourning_chapel"],
  "worry_loop": ["anxiety_diffuser", "grounding_station"],
  "rumination_spiral": ["reflection_pool", "grounding_station"],
  "inner_critic": ["reflection_pool"],
  "comfort_hearth": ["morning_routine", "exercise_yard"],
  "morning_routine": ["exercise_yard", "comfort_hearth"],
}
@export var harmony_speed_bonus: float = 0.2
@export var harmony_output_bonus: int = 1
@export var harmony_mutual_bonus: float = 0.15

@export_group("Flow State")
@export var flow_attention_threshold: float = 0.3
@export var flow_active_buildings_required: int = 3
@export var flow_buildup_rate: float = 0.1
@export var flow_decay_rate: float = 0.2
@export var flow_max_level: float = 1.0
@export var flow_speed_bonus_at_max: float = 0.4
@export var flow_insight_chance_per_second: float = 0.02
@export var flow_insight_amount: int = 1

@export_group("Resource Purity")
@export var purity_initial_level: float = 1.0
@export var purity_decay_rate: float = 0.02
@export var purity_transfer_loss: float = 0.1
@export var purity_min_level: float = 0.3
@export var purity_diluted_threshold: float = 0.4
@export var purity_diluted_penalty: float = 0.15
@export var purity_output_bonus_threshold: float = 0.8
@export var purity_output_bonus_amount: int = 1
@export var purity_speed_bonus_at_pure: float = 0.2
@export var purity_refine_threshold: float = 0.5
@export var purity_refine_gain: float = 0.15
@export var purity_awakened_refine_bonus: float = 0.1

@export_group("Harmony Attunement")
@export var attunement_gain_rate: float = 0.01
@export var attunement_max_level: float = 1.0
@export var attunement_threshold: float = 0.8
@export var attunement_decay_on_break: float = 0.5
@export var attunement_speed_bonus: float = 0.3
@export var attunement_output_bonus: int = 1
@export var attunement_storage_bonus: int = 3
@export var attunement_synergy_bonuses: Dictionary = {
  "memory_well+memory_processor": {"output_type": "insight", "chance": 0.15},
  "wound+mourning_chapel": {"tension_reduction": 1},
  "worry_loop+grounding_station": {"calm_bonus": 1},
  "comfort_hearth+morning_routine": {"energy_bonus": 1},
}

@export_group("Emotional Weather")
@export var weather_enable_day: int = 5
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

@export_group("Building Fragility")
@export var fragility_gain_per_negative: float = 0.05
@export var fragility_max_level: float = 1.0
@export var fragility_crack_threshold: float = 0.7
@export var fragility_leak_interval: float = 4.0
@export var fragility_leak_amount: int = 1
@export var fragility_heal_rate: float = 0.03
@export var fragility_calm_heal_bonus: float = 0.02
@export var fragility_calm_heal_radius: int = 2
@export var fragility_speed_penalty_at_max: float = 0.3
@export var fragility_negative_emotions: Array[String] = ["grief", "anxiety", "tension", "worry", "doubt"]

@export_group("Emotional Stagnation")
@export var stagnation_time_threshold: float = 20.0
@export var stagnation_max_level: float = 1.0
@export var stagnation_gain_rate: float = 0.02
@export var stagnation_process_penalty: float = 0.25
@export var stagnation_decay_interval: float = 15.0
@export var stagnation_decay_chance: float = 0.2
@export var stagnation_fresh_bonus: float = 0.2
@export var stagnation_fresh_threshold: float = 5.0
@export var stagnation_decay_transforms: Dictionary = {
  "grief": "despair",
  "anxiety": "panic",
  "joy": "nostalgia",
  "calm": "numbness",
  "worry": "dread",
}
@export var stagnation_severe_emotions: Array[String] = ["despair", "panic", "dread", "numbness"]

@export_group("Attention Echoes")
@export var attention_echo_stagnation_threshold: float = 0.5
@export var attention_echo_base_refund: float = 0.5
@export var attention_echo_max_refund: float = 2.0
@export var attention_echo_stagnation_multiplier: float = 1.5
@export var attention_echo_cooldown: float = 10.0
@export var attention_echo_awakened_bonus: float = 0.3

@export_group("Overflow Transmutation")
@export var transmutation_chance: float = 0.3
@export var transmutation_radius: int = 2
@export var transmutation_threshold: int = 3
@export var transmutation_recipes: Dictionary = {
  "joy+grief": "nostalgia",
  "anxiety+calm": "tension",
  "grief+wisdom": "insight",
  "calm+anxiety": "suppression_field",
  "worry+joy": "calm",
  "doubt+insight": "wisdom",
}
@export var transmutation_suppression_duration: float = 8.0
@export var transmutation_suppression_radius: int = 2
@export var transmutation_suppression_strength: float = 0.5

@export_group("Building Mastery")
@export var mastery_thresholds: Array[int] = [10, 30, 60, 100]
@export var mastery_speed_bonus_per_level: float = 0.1
@export var mastery_output_bonus_at_max: int = 1
@export var mastery_max_level: int = 4
@export var mastery_decay_rate: float = 0.001
@export var mastery_cross_penalty: float = 0.05
@export var mastery_specialization_threshold: float = 0.7

@export_group("Resource Velocity")
@export var velocity_sample_window: float = 10.0
@export var velocity_high_threshold: float = 2.0
@export var velocity_low_threshold: float = 0.3
@export var velocity_high_speed_bonus: float = 0.25
@export var velocity_low_speed_penalty: float = 0.15
@export var velocity_sustained_threshold: float = 5.0
@export var velocity_burst_bonus: float = 0.1
@export var velocity_momentum_gain: float = 0.05
@export var velocity_momentum_decay: float = 0.02
@export var velocity_momentum_max: float = 1.0

@export_group("Wellbeing")
@export var starting_wellbeing: float = 35.0
@export var wellbeing_struggling_threshold: float = 20.0
@export var wellbeing_stable_threshold: float = 40.0
@export var wellbeing_thriving_threshold: float = 60.0
@export var wellbeing_flourishing_threshold: float = 80.0
@export var wellbeing_struggling_negative_gen_bonus: float = 0.25
@export var wellbeing_struggling_processing_penalty: float = 0.2
@export var wellbeing_stable_processing_bonus: float = 0.1
@export var wellbeing_thriving_positive_gen_bonus: float = 0.2
@export var wellbeing_thriving_energy_regen_bonus: int = 1
@export var wellbeing_flourishing_insight_chance: float = 0.02
@export var wellbeing_flourishing_all_bonus: float = 0.15

@export_group("Worker Fatigue")
@export var worker_fatigue_gain_per_cycle: float = 0.08
@export var worker_fatigue_max_level: float = 1.0
@export var worker_fatigue_speed_penalty_at_max: float = 0.4
@export var worker_fatigue_drop_chance_threshold: float = 0.7
@export var worker_fatigue_drop_chance_per_tick: float = 0.01
@export var worker_fatigue_night_recovery_rate: float = 0.5
@export var worker_fatigue_joy_recovery_bonus: float = 0.02
@export var worker_fatigue_calm_recovery_bonus: float = 0.01
@export var worker_fatigue_onset_threshold: float = 0.3

@export_group("Emotional Synchronization")
@export var sync_chain_window: float = 3.0
@export var sync_chain_min_buildings: int = 2
@export var sync_chain_bonus_per_building: float = 0.15
@export var sync_chain_max_bonus: float = 0.6
@export var sync_chain_insight_chance: float = 0.1
@export var sync_chain_insight_amount: int = 1
@export var sync_chain_duration: float = 5.0

@export_group("Legacy Imprints")
@export var legacy_mastery_threshold: int = 3
@export var legacy_awakening_required: bool = true
@export var legacy_time_required: float = 60.0
@export var legacy_speed_bonus: float = 0.2
@export var legacy_output_bonus: int = 1
@export var legacy_resilience_factor: float = 0.5
@export var legacy_decay_protection: float = 0.3

@export_group("Events")
@export var random_event_chance: float = 0.3
@export var inciting_incident_day: int = 5
@export var allow_repeat_events: bool = true
@export var event_completion_check_interval: float = 5.0

@export_group("Discovery System")
@export var discovery_chance: float = 0.4
@export var discovery_options_count: int = 3
@export var discovery_min_day: int = 2

@export_group("Starting Conditions - Striver Archetype")
@export var starting_buildings: Array[Dictionary] = [
  {"id": "memory_well", "coord": Vector2i(10, 10)},
  {"id": "emotional_reservoir", "coord": Vector2i(14, 10)},
  {"id": "mourning_chapel", "coord": Vector2i(10, 14)},
  {"id": "road", "coord": Vector2i(12, 10)},
  {"id": "road", "coord": Vector2i(12, 11)},
  {"id": "road", "coord": Vector2i(12, 12)},
  {"id": "road", "coord": Vector2i(12, 13)},
  {"id": "road", "coord": Vector2i(12, 14)},
]
@export var starting_resources: Dictionary = {
  "calm": 5,
  "tension": 3,
  "worry": 2,
}
@export var archetype_productivity_bonus: float = 0.1
@export var archetype_rest_penalty: float = 0.1
@export var archetype_worry_generation_interval: float = 30.0
@export var archetype_worry_generation_amount: int = 1

@export_group("Tutorial Hints")
@export var tutorial_enabled: bool = true
@export var hint_day_1_roads: String = "Tip: Roads connect your buildings. Workers travel along roads to transport resources between buildings."
@export var hint_day_1_phases: String = "During the Day, buildings work automatically. During the Night, time pauses - plan your next moves!"
@export var hint_day_2_buildings: String = "Tip: Click a building in the toolbar at the bottom, then click on the grid to place it. Each building has different functions."
@export var hint_day_2_speed: String = "Use the 1x/2x/3x buttons to control game speed. Slow down when things get overwhelming!"
@export var hint_day_3_workers: String = "Tip: To assign a worker: (1) Click a building with resources, (2) Click 'Assign', (3) Click a destination building. Workers transport resources automatically."
@export var hint_day_4_events: String = "Challenging events may arrive soon. Build some processing capacity to handle the emotions they bring."
@export var hint_day_5_unlocks: String = "New buildings are now available! Check the toolbar for more options to build your emotional toolkit."
@export var hint_day_5_weather: String = "Weather patterns now affect your buildings. Joy brings Clear Skies (bonuses), while Anxiety can cause Storms (penalties)."
@export var hint_wellbeing: String = "Click the Wellbeing display on the right to see a breakdown of what's affecting your score."
@export var hint_resource_danger: String = "Warning: Some negative emotions have dangerous effects when they accumulate. Watch for red resource labels!"
@export var hint_first_worker_assignment: String = "Worker Assignment Tutorial:\n1. You clicked 'Assign' on a building with resources\n2. Use scroll wheel to select which resource to transport\n3. Click a destination building to complete the assignment\n4. The worker will automatically move resources between buildings"
@export var hint_first_building_placement: String = "Building Placement Tutorial:\n1. You selected a building from the toolbar\n2. Green tiles are valid placement locations\n3. Click to place, or right-click to cancel\n4. Buildings need road connections to function properly"

@export_group("Ending Text")
@export var ending_flourishing_title: String = "Flourishing"
@export var ending_flourishing_text: String = "Through careful attention to your inner world, you've built something beautiful. Your habits sustain you, your emotions flow freely, and wisdom guides your path. This is what growth looks like."
@export var ending_growing_title: String = "Growing"
@export var ending_growing_text: String = "The mind weathered the storm and emerged stronger. While challenges remain, you've laid foundations that will serve you well. Keep building."
@export var ending_surviving_title: String = "Surviving"
@export var ending_surviving_text: String = "It was hard. Really hard. But you made it through. Sometimes that's enough. Tomorrow is another chance to build something better."
@export var ending_struggling_title: String = "Struggling"
@export var ending_struggling_text: String = "Sometimes the weight is too much to bear alone. The path forward isn't always clear, but every small step matters. Be gentle with yourself."

@export_group("Adjacency Visualization")
@export var adjacency_synergy_color: Color = Color(0.3, 0.9, 0.3, 0.6)
@export var adjacency_conflict_color: Color = Color(0.9, 0.3, 0.3, 0.6)
@export var adjacency_neutral_color: Color = Color(0.7, 0.7, 0.3, 0.4)
@export var adjacency_line_width: float = 3.0
