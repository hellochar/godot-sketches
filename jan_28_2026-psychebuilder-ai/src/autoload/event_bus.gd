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
