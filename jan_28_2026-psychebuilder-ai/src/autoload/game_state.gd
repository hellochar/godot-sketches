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

enum Belief {
  HANDLE_DIFFICULTY,
  JOY_RESILIENT,
  CALM_FOUNDATION,
  GROWTH_ADVERSITY,
  MINDFUL_AWARENESS
}

var belief_progress: Dictionary = {}
var active_beliefs: Array[Belief] = []
var total_grief_processed: int = 0
var total_anxiety_processed: int = 0
var days_with_joy_above_threshold: int = 0
var days_with_calm_above_threshold: int = 0
var total_wisdom_generated: int = 0
var total_insight_generated: int = 0

enum WeatherState {
  NEUTRAL,
  CLEAR_SKIES,
  OVERCAST,
  FOG,
  STORM,
  STILLNESS
}

var current_weather: WeatherState = WeatherState.NEUTRAL
var weather_momentum: Dictionary = {
  "joy": 0.0,
  "calm": 0.0,
  "grief": 0.0,
  "anxiety": 0.0,
  "wisdom": 0.0
}

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

  belief_progress.clear()
  active_beliefs.clear()
  total_grief_processed = 0
  total_anxiety_processed = 0
  days_with_joy_above_threshold = 0
  days_with_calm_above_threshold = 0
  total_wisdom_generated = 0
  total_insight_generated = 0

  current_weather = WeatherState.NEUTRAL
  weather_momentum = {
    "joy": 0.0,
    "calm": 0.0,
    "grief": 0.0,
    "anxiety": 0.0,
    "wisdom": 0.0
  }

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
  var cfg = get_node("/root/Config")
  add_energy(cfg.energy_regen_per_day)

  for building in active_buildings:
    if building.has_method("trigger_habit"):
      building.trigger_habit()

func on_day_end() -> void:
  var cfg = get_node("/root/Config")
  var event_bus = get_node("/root/EventBus")

  if get_resource_total("joy") >= cfg.belief_joy_threshold:
    days_with_joy_above_threshold += 1
  if get_resource_total("calm") >= cfg.belief_calm_threshold:
    days_with_calm_above_threshold += 1

  _check_belief_unlock(Belief.HANDLE_DIFFICULTY, total_grief_processed >= cfg.belief_grief_required, event_bus)
  _check_belief_unlock(Belief.JOY_RESILIENT, days_with_joy_above_threshold >= cfg.belief_joy_days_required, event_bus)
  _check_belief_unlock(Belief.CALM_FOUNDATION, days_with_calm_above_threshold >= cfg.belief_calm_days_required, event_bus)
  _check_belief_unlock(Belief.GROWTH_ADVERSITY, total_wisdom_generated >= cfg.belief_wisdom_required, event_bus)
  _check_belief_unlock(Belief.MINDFUL_AWARENESS, total_insight_generated >= cfg.belief_insight_required, event_bus)

func _check_belief_unlock(belief: Belief, condition: bool, event_bus: Node) -> void:
  if belief in active_beliefs:
    return
  if condition:
    active_beliefs.append(belief)
    event_bus.belief_unlocked.emit(belief)

func has_belief(belief: Belief) -> bool:
  return belief in active_beliefs

func track_grief_processed(amount: int) -> void:
  total_grief_processed += amount

func track_anxiety_processed(amount: int) -> void:
  total_anxiety_processed += amount

func track_wisdom_generated(amount: int) -> void:
  total_wisdom_generated += amount

func track_insight_generated(amount: int) -> void:
  total_insight_generated += amount

func update_weather_momentum(delta: float) -> void:
  var cfg = get_node("/root/Config")

  for emotion in weather_momentum:
    var target = float(get_resource_total(emotion)) / cfg.weather_resource_scale
    var current = weather_momentum[emotion]
    weather_momentum[emotion] = lerpf(current, target, cfg.weather_momentum_lerp * delta)

  _determine_weather()

func _determine_weather() -> void:
  var cfg = get_node("/root/Config")
  var event_bus = get_node("/root/EventBus")
  var old_weather = current_weather

  var joy_mom = weather_momentum.get("joy", 0.0)
  var calm_mom = weather_momentum.get("calm", 0.0)
  var grief_mom = weather_momentum.get("grief", 0.0)
  var anxiety_mom = weather_momentum.get("anxiety", 0.0)
  var wisdom_mom = weather_momentum.get("wisdom", 0.0)

  var positive_total = joy_mom + calm_mom
  var negative_total = grief_mom + anxiety_mom

  if anxiety_mom >= cfg.weather_storm_threshold:
    current_weather = WeatherState.STORM
  elif grief_mom >= cfg.weather_overcast_threshold and grief_mom > positive_total:
    current_weather = WeatherState.OVERCAST
  elif wisdom_mom >= cfg.weather_fog_threshold and wisdom_mom > negative_total:
    current_weather = WeatherState.FOG
  elif calm_mom >= cfg.weather_stillness_threshold and calm_mom > negative_total:
    current_weather = WeatherState.STILLNESS
  elif joy_mom >= cfg.weather_clear_threshold and joy_mom > negative_total:
    current_weather = WeatherState.CLEAR_SKIES
  else:
    current_weather = WeatherState.NEUTRAL

  if old_weather != current_weather:
    event_bus.weather_changed.emit(old_weather, current_weather)

func get_weather_processing_modifier() -> float:
  var cfg = get_node("/root/Config")
  match current_weather:
    WeatherState.CLEAR_SKIES:
      return 1.0 + cfg.weather_clear_processing_bonus
    WeatherState.STORM:
      return 1.0 - cfg.weather_storm_processing_penalty
    WeatherState.FOG:
      return 1.0 - cfg.weather_fog_processing_penalty
    WeatherState.STILLNESS:
      return 1.0 + cfg.weather_stillness_processing_bonus
    _:
      return 1.0

func get_weather_generation_modifier() -> float:
  var cfg = get_node("/root/Config")
  match current_weather:
    WeatherState.STORM:
      return 1.0 + cfg.weather_storm_negative_gen_bonus
    WeatherState.OVERCAST:
      return 1.0 + cfg.weather_overcast_grief_gen_bonus
    WeatherState.CLEAR_SKIES:
      return 1.0 + cfg.weather_clear_joy_gen_bonus
    _:
      return 1.0

func get_weather_habit_modifier() -> float:
  var cfg = get_node("/root/Config")
  match current_weather:
    WeatherState.CLEAR_SKIES:
      return 1.0 + cfg.weather_clear_habit_bonus
    WeatherState.STORM:
      return 1.0 - cfg.weather_storm_habit_penalty
    WeatherState.STILLNESS:
      return 1.0 + cfg.weather_stillness_habit_bonus
    _:
      return 1.0

func get_belief_processing_modifier() -> float:
  var cfg = get_node("/root/Config")
  var modifier = 1.0
  if has_belief(Belief.HANDLE_DIFFICULTY):
    modifier *= 1.0 + cfg.belief_handle_difficulty_bonus
  if has_belief(Belief.CALM_FOUNDATION):
    modifier *= 1.0 + cfg.belief_calm_foundation_bonus
  return modifier

func get_belief_generation_modifier() -> float:
  var cfg = get_node("/root/Config")
  var modifier = 1.0
  if has_belief(Belief.JOY_RESILIENT):
    modifier *= 1.0 + cfg.belief_joy_resilient_bonus
  return modifier

func get_belief_habit_modifier() -> float:
  var cfg = get_node("/root/Config")
  var modifier = 1.0
  if has_belief(Belief.GROWTH_ADVERSITY):
    modifier *= 1.0 + cfg.belief_growth_adversity_bonus
  if has_belief(Belief.MINDFUL_AWARENESS):
    modifier *= 1.0 + cfg.belief_mindful_awareness_bonus
  return modifier
