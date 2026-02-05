extends Node

signal tutorial_hint_requested(hint_text: String)
signal starting_setup_complete()
signal discovery_available(options: Array)


var building_system: Node
var resource_system: Node
var grid: Node

var worry_generation_timer: float = 0.0

func setup(p_building_system: Node, p_resource_system: Node, p_grid: Node) -> void:
  building_system = p_building_system
  resource_system = p_resource_system
  grid = p_grid

func initialize_game() -> void:
  _apply_archetype_modifiers()
  _place_starting_buildings()
  _spawn_starting_resources()
  starting_setup_complete.emit()

func _apply_archetype_modifiers() -> void:
  GameState.instance.apply_archetype_modifiers(
    Config.instance.archetype_productivity_bonus,
    Config.instance.archetype_rest_penalty
  )

func _place_starting_buildings() -> void:
  for building_data in Config.instance.starting_buildings:
    var building_id = building_data.get("id", "")
    var coord = building_data.get("coord", Vector2i(0, 0))

    if building_id == "" or not grid.is_valid_coord(coord):
      continue

    var old_energy = GameState.instance.current_energy
    GameState.instance.current_energy = 999

    building_system.place_building(building_id, coord)

    GameState.instance.current_energy = old_energy

func _spawn_starting_resources() -> void:
  for resource_type in Config.instance.starting_resources:
    var amount = Config.instance.starting_resources[resource_type]
    if amount <= 0:
      continue

    for building in GameState.instance.active_buildings:
      if building.storage_capacity > 0:
        var added = building.add_to_storage(resource_type, amount)
        if added > 0:
          GameState.instance.update_resource_total(resource_type, added)
          amount -= added
          if amount <= 0:
            break

func _process(delta: float) -> void:
  _update_worry_generation(delta)

func _update_worry_generation(delta: float) -> void:
  if GameState.instance.current_phase != "day":
    return

  worry_generation_timer += delta * GameState.instance.game_speed
  if worry_generation_timer >= Config.instance.archetype_worry_generation_interval:
    worry_generation_timer = 0.0
    _generate_archetype_worry()

func _generate_archetype_worry() -> void:
  for building in GameState.instance.active_buildings:
    if building.storage_capacity > 0 and building.has_space_for("worry", Config.instance.archetype_worry_generation_amount):
      building.add_to_storage("worry", Config.instance.archetype_worry_generation_amount)
      GameState.instance.update_resource_total("worry", Config.instance.archetype_worry_generation_amount)
      return

func check_tutorial_hint(day_number: int) -> void:
  if not Config.instance.tutorial_enabled:
    return

  match day_number:
    1:
      _show_hint_if_new("day_1_roads", Config.instance.hint_day_1_roads)
      _show_hint_if_new("day_1_phases", Config.instance.hint_day_1_phases)
    2:
      _show_hint_if_new("day_2_buildings", Config.instance.hint_day_2_buildings)
      _show_hint_if_new("day_2_speed", Config.instance.hint_day_2_speed)
      _show_hint_if_new("hint_wellbeing", Config.instance.hint_wellbeing)
    3:
      _show_hint_if_new("day_3_workers", Config.instance.hint_day_3_workers)
    4:
      _show_hint_if_new("day_4_events", Config.instance.hint_day_4_events)
    5:
      _show_hint_if_new("day_5_unlocks", Config.instance.hint_day_5_unlocks)
      _show_hint_if_new("day_5_weather", Config.instance.hint_day_5_weather)
      _show_hint_if_new("hint_resource_danger", Config.instance.hint_resource_danger)

func _show_hint_if_new(hint_id: String, hint_text: String) -> void:
  if GameState.instance.has_hint_shown(hint_id):
    return

  GameState.instance.mark_hint_shown(hint_id)
  tutorial_hint_requested.emit(hint_text)

func get_ending_title(tier: String) -> String:
  match tier:
    "flourishing":
      return Config.instance.ending_flourishing_title
    "growing":
      return Config.instance.ending_growing_title
    "surviving":
      return Config.instance.ending_surviving_title
    "struggling":
      return Config.instance.ending_struggling_title
  return tier.capitalize()

func get_ending_text(tier: String) -> String:
  match tier:
    "flourishing":
      return Config.instance.ending_flourishing_text
    "growing":
      return Config.instance.ending_growing_text
    "surviving":
      return Config.instance.ending_surviving_text
    "struggling":
      return Config.instance.ending_struggling_text
  return ""

func check_discovery(day_number: int) -> void:
  if day_number < Config.instance.discovery_min_day:
    return

  if randf() > Config.instance.discovery_chance:
    return

  var available = building_system.get_discoverable_buildings()
  if available.size() == 0:
    return

  available.shuffle()
  var options = available.slice(0, mini(Config.instance.discovery_options_count, available.size()))

  if options.size() > 0:
    discovery_available.emit(options)

func apply_discovery(building_id: String) -> void:
  GameState.instance.add_discovered_building(building_id)
  building_system.unlock_building(building_id)
  EventBus.instance.building_discovered.emit(building_id)
