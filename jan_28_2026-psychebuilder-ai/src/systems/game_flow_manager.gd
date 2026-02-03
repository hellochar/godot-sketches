extends Node

signal tutorial_hint_requested(hint_text: String)
signal starting_setup_complete()
signal discovery_available(options: Array)

@onready var game_state: Node = get_node("/root/GameState")
@onready var event_bus: Node = get_node("/root/EventBus")
@onready var config: Node = get_node("/root/Config")

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
  game_state.apply_archetype_modifiers(
    config.archetype_productivity_bonus,
    config.archetype_rest_penalty
  )

func _place_starting_buildings() -> void:
  for building_data in config.starting_buildings:
    var building_id = building_data.get("id", "")
    var coord = building_data.get("coord", Vector2i(0, 0))

    if building_id == "" or not grid.is_valid_coord(coord):
      continue

    var old_energy = game_state.current_energy
    game_state.current_energy = 999

    building_system.place_building(building_id, coord)

    game_state.current_energy = old_energy

func _spawn_starting_resources() -> void:
  for resource_type in config.starting_resources:
    var amount = config.starting_resources[resource_type]
    if amount <= 0:
      continue

    for building in game_state.active_buildings:
      if building.storage_capacity > 0:
        var added = building.add_to_storage(resource_type, amount)
        if added > 0:
          game_state.update_resource_total(resource_type, added)
          amount -= added
          if amount <= 0:
            break

func _process(delta: float) -> void:
  _update_worry_generation(delta)

func _update_worry_generation(delta: float) -> void:
  if game_state.current_phase != "day":
    return

  worry_generation_timer += delta * game_state.game_speed
  if worry_generation_timer >= config.archetype_worry_generation_interval:
    worry_generation_timer = 0.0
    _generate_archetype_worry()

func _generate_archetype_worry() -> void:
  for building in game_state.active_buildings:
    if building.storage_capacity > 0 and building.has_space_for("worry", config.archetype_worry_generation_amount):
      building.add_to_storage("worry", config.archetype_worry_generation_amount)
      game_state.update_resource_total("worry", config.archetype_worry_generation_amount)
      return

func check_tutorial_hint(day_number: int) -> void:
  if not config.tutorial_enabled:
    return

  match day_number:
    1:
      _show_hint_if_new("day_1_roads", config.hint_day_1_roads)
    2:
      _show_hint_if_new("day_2_buildings", config.hint_day_2_buildings)
    3:
      _show_hint_if_new("day_3_workers", config.hint_day_3_workers)

func _show_hint_if_new(hint_id: String, hint_text: String) -> void:
  if game_state.has_hint_shown(hint_id):
    return

  game_state.mark_hint_shown(hint_id)
  tutorial_hint_requested.emit(hint_text)

func get_ending_title(tier: String) -> String:
  match tier:
    "flourishing":
      return config.ending_flourishing_title
    "growing":
      return config.ending_growing_title
    "surviving":
      return config.ending_surviving_title
    "struggling":
      return config.ending_struggling_title
  return tier.capitalize()

func get_ending_text(tier: String) -> String:
  match tier:
    "flourishing":
      return config.ending_flourishing_text
    "growing":
      return config.ending_growing_text
    "surviving":
      return config.ending_surviving_text
    "struggling":
      return config.ending_struggling_text
  return ""

func check_discovery(day_number: int) -> void:
  if day_number < config.discovery_min_day:
    return

  if randf() > config.discovery_chance:
    return

  var available = building_system.get_discoverable_buildings()
  if available.size() == 0:
    return

  available.shuffle()
  var options = available.slice(0, mini(config.discovery_options_count, available.size()))

  if options.size() > 0:
    discovery_available.emit(options)

func apply_discovery(building_id: String) -> void:
  game_state.add_discovered_building(building_id)
  building_system.unlock_building(building_id)
  event_bus.building_discovered.emit(building_id)
