extends Node

signal day_started(day_number: int)
signal night_started(day_number: int)
signal phase_changed(is_day: bool)

enum Phase { DAY, NIGHT }

@onready var game_state: Node = get_node("/root/GameState")
@onready var event_bus: Node = get_node("/root/EventBus")
@onready var config: Node = get_node("/root/Config")

var current_day: int = 1
var current_phase: Phase = Phase.DAY
var phase_time: float = 0.0
var paused: bool = false
var speed_multiplier: float = 1.0

var day_duration: float
var night_duration: float
var total_days: int
var energy_regen_per_day: int

@export_group("Speed Limits")
@export var min_speed: float = 0.5
@export var max_speed: float = 3.0

func setup(p_day_duration: float, p_night_duration: float, p_total_days: int, p_energy_regen: int) -> void:
  day_duration = p_day_duration
  night_duration = p_night_duration
  total_days = p_total_days
  energy_regen_per_day = p_energy_regen

func _process(delta: float) -> void:
  if paused:
    return

  phase_time += delta * speed_multiplier

  match current_phase:
    Phase.DAY:
      if current_day >= config.weather_enable_day:
        game_state.update_weather_momentum(delta * speed_multiplier)
      game_state.update_breakthrough_timers(delta * speed_multiplier)
      game_state.update_flow_state(delta * speed_multiplier)
      game_state.update_flourishing_insight(delta * speed_multiplier)
      game_state.update_sync_chain_timers(delta * speed_multiplier)
      if phase_time >= day_duration:
        _transition_to_night()
    Phase.NIGHT:
      pass

func _transition_to_night() -> void:
  current_phase = Phase.NIGHT
  phase_time = 0.0
  game_state.current_phase = "night"
  game_state.phase_time = 0.0
  game_state.on_day_end()
  _process_dream_recombinations()
  _recover_worker_fatigue()
  night_started.emit(current_day)
  phase_changed.emit(false)
  event_bus.night_started.emit(current_day)

func _transition_to_day() -> void:
  current_day += 1
  current_phase = Phase.DAY
  phase_time = 0.0
  game_state.current_day = current_day
  game_state.current_phase = "day"
  game_state.phase_time = 0.0

  if current_day > total_days:
    _end_game()
    return

  day_started.emit(current_day)
  phase_changed.emit(true)
  event_bus.day_started.emit(current_day)
  _trigger_day_start_effects()

func _trigger_day_start_effects() -> void:
  var gs = game_state
  if gs:
    gs.on_day_start(energy_regen_per_day)

func end_night() -> void:
  if current_phase == Phase.NIGHT:
    _transition_to_day()

func set_paused(p: bool) -> void:
  paused = p
  game_state.is_paused = p

func set_speed(multiplier: float) -> void:
  speed_multiplier = clampf(multiplier, min_speed, max_speed)

func get_phase_progress() -> float:
  match current_phase:
    Phase.DAY:
      return phase_time / day_duration
    Phase.NIGHT:
      return phase_time / night_duration
  return 0.0

func is_day() -> bool:
  return current_phase == Phase.DAY

func is_night() -> bool:
  return current_phase == Phase.NIGHT

func _process_dream_recombinations() -> void:
  var recipes = config.dream_recipes
  for building in game_state.active_buildings:
    if building.storage_capacity <= 0:
      continue

    for recipe_key in recipes:
      if randf() > config.dream_recombination_chance:
        continue

      var parts = recipe_key.split("+")
      var resource_a = parts[0]
      var resource_b = parts[1]
      var output = recipes[recipe_key]

      var amount_a = building.storage.get(resource_a, 0)
      var amount_b = building.storage.get(resource_b, 0)

      if amount_a > 0 and amount_b > 0:
        var transform_amount = mini(amount_a, amount_b)
        building.remove_from_storage(resource_a, transform_amount)
        building.remove_from_storage(resource_b, transform_amount)
        building.add_to_storage(output, transform_amount)
        break

func _recover_worker_fatigue() -> void:
  for worker in game_state.active_workers:
    if worker.has_method("recover_fatigue_at_night"):
      worker.recover_fatigue_at_night()

func _end_game() -> void:
  paused = true
  game_state.is_paused = true
  var ending_tier = _calculate_ending_tier()
  event_bus.game_ended.emit(ending_tier)

func _calculate_ending_tier() -> String:
  var wb = game_state.wellbeing
  if wb >= config.flourishing_threshold:
    return "flourishing"
  elif wb >= config.growing_threshold:
    return "growing"
  elif wb >= config.surviving_threshold:
    return "surviving"
  else:
    return "struggling"
