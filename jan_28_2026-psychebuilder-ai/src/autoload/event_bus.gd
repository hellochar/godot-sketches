extends Node

# Resource signals
signal resource_spawned(resource_type: String, location: Vector2, amount: int)
signal resource_processed(input_type: String, output_type: String, building: Node)
signal resource_decayed(resource_type: String, amount: int)
signal resource_total_changed(resource_type: String, new_total: int)
signal resource_overflow(resource_type: String, amount: int, building: Node, world_position: Vector2)

# Building signals
signal building_placed(building: Node, coord: Vector2i)
signal building_removed(building: Node, coord: Vector2i)
signal building_activated(building: Node)
signal building_deactivated(building: Node)

# Worker signals
signal worker_assigned(worker: Node, job_type: String, target: Node)
signal worker_unassigned(worker: Node)
signal worker_job_completed(worker: Node, job_type: String)
signal habituation_increased(worker: Node, job_id: String, new_level: int)

# Time signals
signal day_started(day_number: int)
signal night_started(day_number: int)
signal phase_changed(phase: String)
signal tick()

# Event signals
signal event_triggered(event_id: String)
signal event_choice_made(event_id: String, choice_index: int)
signal event_completed(event_id: String)

# Metrics signals
signal wellbeing_changed(old_value: float, new_value: float)
signal energy_changed(old_value: int, new_value: int)
signal attention_changed(used: float, available: float)

# Game flow signals
signal game_started()
signal game_ended(ending_tier: String)

# Nostalgia crystallization signals
signal nostalgia_crystallized(building: Node, output_type: String, amount: int)

# Resonance signals
signal resonance_formed(resource_type: String, buildings: Array, is_positive: bool)
signal resonance_amplification(building: Node, resource_type: String, amount: int)

# Belief signals
signal belief_unlocked(belief: int)
signal belief_progress_updated(belief: int, progress: float)

# Weather signals
signal weather_changed(old_weather: int, new_weather: int)

# Awakening signals
signal building_awakened(building: Node)

# Breakthrough signals
signal breakthrough_triggered(insight_reward: int, wisdom_reward: int)

# Fatigue signals
signal building_fatigued(building: Node, fatigue_level: float)
signal building_rested(building: Node)

# Emotional echo signals
signal echo_formed(building: Node, emotion_type: String, echo_level: float)
signal echo_specialty_bonus(building: Node, emotion_type: String)

# Harmony signals
signal harmony_formed(building: Node, partners: Array)
signal harmony_bonus_applied(building: Node, output_bonus: int)

# Flow state signals
signal flow_state_entered(level: float)
signal flow_state_exited()
signal flow_insight_generated(amount: int)

# Purity signals
signal resource_purity_degraded(building: Node, resource_type: String, new_purity: float)
signal pure_resource_processed(building: Node, resource_type: String, bonus: int)
signal resource_refined(building: Node, resource_type: String, new_purity: float)

# Attunement signals
signal attunement_progress(building: Node, partner: Node, level: float)
signal attunement_achieved(building: Node, partner: Node)
signal attunement_broken(building: Node, partner: Node)
signal attunement_synergy_triggered(building: Node, partner: Node, bonus_type: String)

# Fragility signals
signal building_cracked(building: Node, fragility_level: float)
signal building_leaked(building: Node, resource_type: String, target: Node)
signal building_healed(building: Node, new_fragility: float)

# Stagnation signals
signal resource_stagnated(building: Node, resource_type: String, stagnation_level: float)
signal resource_decayed_to_severe(building: Node, old_type: String, new_type: String)
signal fresh_resource_bonus(building: Node, resource_type: String)

signal attention_echo_refund(building: Node, stagnation_level: float, refund_amount: float)
signal overflow_transmuted(building: Node, from_type: String, to_type: String, amount: int)
signal suppression_field_created(building: Node, position: Vector2, radius: int, duration: float)

signal mastery_level_gained(building: Node, resource_type: String, new_level: int)
signal mastery_specialization_achieved(building: Node, resource_type: String)
signal velocity_burst_triggered(building: Node, velocity: float)
signal velocity_momentum_changed(building: Node, momentum: float)
