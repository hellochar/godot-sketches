extends Node

# Time state
var current_day: int = 1
var current_phase: String = "night"  # "day" or "night"
var phase_time: float = 0.0
var game_speed: float = 1.0
var is_paused: bool = false

# Energy state
var current_energy: int = 10
var max_energy: int = 20

# Attention state
var attention_used: float = 0.0
var attention_available: float = 10.0

# Wellbeing
var wellbeing: float = 35.0

# Tracking collections
var active_buildings: Array[Node] = []
var active_workers: Array[Node] = []
var active_resources: Array[Node] = []

# Resource totals cache (resource_type_id -> total amount)
var resource_totals: Dictionary = {}

# Habituation tracking (job_id -> completions)
var habituation_progress: Dictionary = {}

func _ready() -> void:
  reset_to_defaults()

func reset_to_defaults() -> void:
  current_day = 1
  current_phase = "night"
  phase_time = 0.0
  game_speed = 1.0
  is_paused = false

  current_energy = get_node("/root/Config").starting_energy
  max_energy = get_node("/root/Config").max_energy
  attention_available = get_node("/root/Config").base_attention_pool
  attention_used = 0.0
  wellbeing = 35.0

  active_buildings.clear()
  active_workers.clear()
  active_resources.clear()
  resource_totals.clear()
  habituation_progress.clear()

func spend_energy(amount: int) -> bool:
  if current_energy < amount:
    return false
  var old = current_energy
  current_energy -= amount
  get_node("/root/EventBus").energy_changed.emit(old, current_energy)
  return true

func add_energy(amount: int) -> void:
  var old = current_energy
  current_energy = mini(current_energy + amount, max_energy)
  if old != current_energy:
    get_node("/root/EventBus").energy_changed.emit(old, current_energy)

func use_attention(amount: float) -> bool:
  if attention_used + amount > attention_available:
    return false
  attention_used += amount
  get_node("/root/EventBus").attention_changed.emit(attention_used, attention_available)
  return true

func free_attention(amount: float) -> void:
  attention_used = maxf(0.0, attention_used - amount)
  get_node("/root/EventBus").attention_changed.emit(attention_used, attention_available)

func update_resource_total(resource_type: String, delta: int) -> void:
  if not resource_totals.has(resource_type):
    resource_totals[resource_type] = 0
  resource_totals[resource_type] += delta
  get_node("/root/EventBus").resource_total_changed.emit(resource_type, resource_totals[resource_type])

func get_resource_total(resource_type: String) -> int:
  return resource_totals.get(resource_type, 0)

func set_wellbeing(value: float) -> void:
  var old = wellbeing
  wellbeing = clampf(value, 0.0, 100.0)
  if old != wellbeing:
    get_node("/root/EventBus").wellbeing_changed.emit(old, wellbeing)

func get_habituation_level(job_id: String) -> int:
  var completions = habituation_progress.get(job_id, 0)
  var thresholds = get_node("/root/Config").habituation_thresholds
  for i in range(thresholds.size() - 1, -1, -1):
    if completions >= thresholds[i]:
      return i + 1
  return 0

func get_attention_cost(job_id: String) -> float:
  var level = get_habituation_level(job_id)
  return get_node("/root/Config").habituation_costs[level]

func increment_habituation(job_id: String) -> void:
  if not habituation_progress.has(job_id):
    habituation_progress[job_id] = 0
  habituation_progress[job_id] += 1

func on_day_start() -> void:
  var config = get_node("/root/Config")
  add_energy(config.energy_regen_per_day)

  for building in active_buildings:
    if building.has_method("trigger_habit"):
      building.trigger_habit()
