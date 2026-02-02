extends Node2D

signal job_cycle_completed

@onready var config: Node = get_node("/root/Config")
@onready var game_state: Node = get_node("/root/GameState")

enum State { IDLE, MOVING_TO_PICKUP, PICKING_UP, CARRYING, MOVING_TO_DROPOFF, DROPPING_OFF }

var state: State = State.IDLE
var current_path: Array[Vector2i] = []
var path_index: int = 0
var grid: Node  # GridSystem

# Job info
var job_type: String = ""  # "transport", "operate"
var source_building: Node = null
var dest_building: Node = null
var resource_type: String = ""
var carried_amount: int = 0

@export_group("Movement")
@export var move_speed: float = 100.0
var target_position: Vector2

var joy_boost_timer: float = 0.0
var current_speed_multiplier: float = 1.0

var job_id: String = ""
var completions: int = 0

var is_selected: bool = false
@export_group("Appearance")
@export var base_modulate: Color = Color(1, 0.95, 0.7, 1)
@export var selected_modulate: Color = Color(0.5, 1.0, 0.5, 1)
@export var selected_scale: float = 1.3
@export var carrying_modulate: Color = Color(1.2, 1.1, 0.8, 1)
@export var mote_texture_size: int = 24

@export_group("Contamination Colors")
@export var negative_contamination_color: Color = Color(0.6, 0.5, 0.7, 1)
@export var positive_contamination_color: Color = Color(1.0, 1.0, 0.6, 1)
@export var negative_color_blend: float = 0.5
@export var positive_color_blend: float = 0.3

var emotional_residue: Dictionary = {}

var focus_imprints: Dictionary = {}
var dominant_focus: String = ""

# Visual
@onready var sprite: Sprite2D = %Sprite2D

static var mote_texture: ImageTexture

func _ready() -> void:
  if not mote_texture:
    mote_texture = _create_mote_texture_with_size(mote_texture_size)
  sprite.texture = mote_texture
  modulate = base_modulate

func _create_mote_texture_with_size(tex_size: int) -> ImageTexture:
  var image = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
  var center = Vector2(tex_size / 2.0, tex_size / 2.0)
  var radius = tex_size / 2.0 - 2

  for x in range(tex_size):
    for y in range(tex_size):
      var dist = Vector2(x, y).distance_to(center)
      if dist <= radius:
        var alpha = 1.0 - (dist / radius) * 0.5
        var brightness = 1.0 - (dist / radius) * 0.3
        image.set_pixel(x, y, Color(brightness, brightness, brightness, alpha))
      else:
        image.set_pixel(x, y, Color(0, 0, 0, 0))

  return ImageTexture.create_from_image(image)

func setup(p_grid: Node) -> void:
  grid = p_grid

func assign_transport_job(p_source: Node, p_dest: Node, p_resource_type: String) -> bool:
  if not grid:
    return false

  source_building = p_source
  dest_building = p_dest
  resource_type = p_resource_type
  job_type = "transport"
  job_id = "transport_%s_%s_%s" % [p_source.building_id, p_dest.building_id, p_resource_type]

  state = State.MOVING_TO_PICKUP
  _pathfind_to_building(source_building)

  return current_path.size() > 0

func assign_operate_job(building: Node) -> bool:
  if not grid:
    return false

  dest_building = building
  job_type = "operate"
  job_id = "operate_%s" % building.building_id

  state = State.MOVING_TO_DROPOFF
  _pathfind_to_building(building)

  if current_path.size() > 0:
    return true

  # Already adjacent to building
  _arrive_at_operate()
  return true

func _pathfind_to_building(building: Node) -> void:
  var building_coord = building.grid_coord
  var my_coord = grid.world_to_grid(position)

  # Find adjacent road tile to building
  var adjacent_roads: Array[Vector2i] = []
  var building_size = building.size

  for x in range(-1, building_size.x + 1):
    for y in range(-1, building_size.y + 1):
      if x >= 0 and x < building_size.x and y >= 0 and y < building_size.y:
        continue  # Skip building tiles themselves
      var check = building_coord + Vector2i(x, y)
      if grid.is_valid_coord(check) and grid.is_road_at(check):
        adjacent_roads.append(check)

  if adjacent_roads.is_empty():
    current_path = []
    return

  # Find path to nearest adjacent road
  var best_path: Array[Vector2i] = []
  var best_length = INF

  for target in adjacent_roads:
    var path = grid.find_path(my_coord, target, func(coord): return grid.is_road_at(coord))
    if path.size() > 0 and path.size() < best_length:
      best_length = path.size()
      best_path = path

  current_path = best_path
  path_index = 0

  if current_path.size() > 0:
    target_position = grid.grid_to_world(current_path[0])

func _process(delta: float) -> void:
  _update_joy_speed_boost(delta)
  _process_contamination(delta)

  match state:
    State.IDLE:
      pass
    State.MOVING_TO_PICKUP, State.MOVING_TO_DROPOFF:
      _process_movement(delta)
    State.PICKING_UP:
      _process_pickup()
    State.DROPPING_OFF:
      _process_dropoff()
    State.CARRYING:
      _process_movement(delta)

func _process_movement(delta: float) -> void:
  if current_path.is_empty():
    _arrive_at_destination()
    return

  var move_dir = (target_position - position).normalized()
  var distance = position.distance_to(target_position)
  var contamination_modifier = _get_contamination_speed_modifier()
  var focus_modifier = get_focus_speed_multiplier()
  var move_amount = move_speed * current_speed_multiplier * contamination_modifier * focus_modifier * delta

  if move_amount >= distance:
    position = target_position
    path_index += 1

    if path_index >= current_path.size():
      _arrive_at_destination()
    else:
      target_position = grid.grid_to_world(current_path[path_index])
  else:
    position += move_dir * move_amount

func _update_joy_speed_boost(delta: float) -> void:
  var carrying_joy = state == State.CARRYING and resource_type == "joy" and carried_amount > 0

  if carrying_joy:
    current_speed_multiplier = 1.0 + config.joy_carry_speed_bonus
    joy_boost_timer = config.joy_boost_duration
    return

  var near_joy_building = false
  for building in game_state.active_buildings:
    if building.storage.get("joy", 0) > 0:
      var dist = position.distance_to(building.position)
      if dist <= config.joy_proximity_radius:
        near_joy_building = true
        break

  if near_joy_building:
    joy_boost_timer = config.joy_boost_duration
    current_speed_multiplier = 1.0 + config.joy_proximity_speed_bonus
    return

  if joy_boost_timer > 0:
    joy_boost_timer -= delta
    if joy_boost_timer <= 0:
      current_speed_multiplier = 1.0
  else:
    current_speed_multiplier = 1.0

func _arrive_at_destination() -> void:
  current_path = []
  path_index = 0

  match state:
    State.MOVING_TO_PICKUP:
      state = State.PICKING_UP
    State.MOVING_TO_DROPOFF:
      if job_type == "transport":
        state = State.DROPPING_OFF
      else:
        _arrive_at_operate()
    State.CARRYING:
      state = State.DROPPING_OFF

func _process_pickup() -> void:
  if not source_building or resource_type == "":
    state = State.IDLE
    return

  var available = source_building.get_storage_amount(resource_type)
  if available > 0:
    carried_amount = source_building.remove_from_storage(resource_type, mini(available, 5))
    state = State.CARRYING
    _pathfind_to_building(dest_building)

    modulate = carrying_modulate
  else:
    pass

func _process_dropoff() -> void:
  if not dest_building:
    state = State.IDLE
    return

  if carried_amount > 0:
    var overflow = dest_building.add_to_storage(resource_type, carried_amount)
    carried_amount = overflow

  if carried_amount == 0:
    _update_selection_visual()
    _update_focus_imprint()
    job_cycle_completed.emit()

    # Loop back to pickup
    state = State.MOVING_TO_PICKUP
    _pathfind_to_building(source_building)
  else:
    # Destination full - return resources to source
    _return_resources_to_source()

func _arrive_at_operate() -> void:
  if dest_building:
    dest_building.assign_worker(self)
  state = State.IDLE

func _return_resources_to_source() -> void:
  if not source_building or carried_amount == 0:
    state = State.IDLE
    return

  var overflow = source_building.add_to_storage(resource_type, carried_amount)
  carried_amount = overflow

  if carried_amount == 0:
    _update_selection_visual()
    # Try picking up again
    state = State.MOVING_TO_PICKUP
    _pathfind_to_building(source_building)
  else:
    # Both source and dest full - drop resources and go idle
    carried_amount = 0
    _update_selection_visual()
    state = State.IDLE

func unassign() -> void:
  if dest_building and job_type == "operate":
    dest_building.unassign_worker()
  job_type = ""
  source_building = null
  dest_building = null
  resource_type = ""
  carried_amount = 0
  state = State.IDLE
  current_path = []

func get_job_id() -> String:
  return job_id

func get_completions() -> int:
  return completions

func set_selected(selected: bool) -> void:
  is_selected = selected
  _update_selection_visual()

func _update_selection_visual() -> void:
  if is_selected:
    modulate = selected_modulate
    scale = Vector2(selected_scale, selected_scale)
  else:
    modulate = _get_contamination_modulate()
    scale = Vector2(1.0, 1.0)

func _get_contamination_speed_modifier() -> float:
  var negative_total = emotional_residue.get("anxiety", 0.0) + emotional_residue.get("grief", 0.0)
  var positive_total = emotional_residue.get("joy", 0.0) + emotional_residue.get("calm", 0.0)

  var negative_factor = minf(negative_total / config.contamination_max_level, 1.0)
  var positive_factor = minf(positive_total / config.contamination_max_level, 1.0)

  var slowdown = negative_factor * config.contamination_speed_negative
  var speedup = positive_factor * config.contamination_speed_positive

  return 1.0 - slowdown + speedup

func _absorb_emotion(emotion: String, amount: float) -> void:
  var absorbed = amount * config.contamination_absorb_rate
  var current = emotional_residue.get(emotion, 0.0)
  emotional_residue[emotion] = minf(current + absorbed, config.contamination_max_level)

func _decay_emotions(delta: float) -> void:
  var decay = config.contamination_decay_rate * delta
  for emotion in emotional_residue.keys():
    emotional_residue[emotion] = maxf(0.0, emotional_residue[emotion] - decay)

func _process_contamination(delta: float) -> void:
  _decay_emotions(delta)

  for building in game_state.active_buildings:
    var dist = position.distance_to(building.position)
    if dist <= config.joy_proximity_radius:
      for emotion in ["anxiety", "grief", "joy", "calm"]:
        var amount = building.storage.get(emotion, 0)
        if amount > 0:
          _absorb_emotion(emotion, amount * delta)

  if not is_selected:
    modulate = _get_contamination_modulate()

func _get_contamination_modulate() -> Color:
  var negative_total = emotional_residue.get("anxiety", 0.0) + emotional_residue.get("grief", 0.0)
  var positive_total = emotional_residue.get("joy", 0.0) + emotional_residue.get("calm", 0.0)

  var negative_factor = minf(negative_total / config.contamination_max_level, 1.0)
  var positive_factor = minf(positive_total / config.contamination_max_level, 1.0)

  var result = base_modulate
  if negative_factor > positive_factor:
    result = base_modulate.lerp(negative_contamination_color, negative_factor * negative_color_blend)
  elif positive_factor > negative_factor:
    result = base_modulate.lerp(positive_contamination_color, positive_factor * positive_color_blend)

  return result

func _update_focus_imprint() -> void:
  if job_id == "":
    return

  var current_level = focus_imprints.get(job_id, 0.0)
  var new_level = minf(current_level + config.focus_imprint_gain_per_cycle, config.focus_imprint_max_level)
  focus_imprints[job_id] = new_level

  for other_job in focus_imprints:
    if other_job != job_id:
      focus_imprints[other_job] = maxf(0.0, focus_imprints[other_job] - config.focus_decay_rate)

  var max_focus = 0.0
  for fj in focus_imprints:
    if focus_imprints[fj] > max_focus:
      max_focus = focus_imprints[fj]
      dominant_focus = fj

func get_focus_speed_multiplier() -> float:
  if job_id == "":
    return 1.0

  var current_focus = focus_imprints.get(job_id, 0.0)
  var focus_ratio = current_focus / config.focus_imprint_max_level

  if dominant_focus != "" and dominant_focus != job_id:
    var dominant_level = focus_imprints.get(dominant_focus, 0.0)
    if dominant_level > float(config.focus_transfer_threshold) * config.focus_imprint_gain_per_cycle:
      return 1.0 - config.focus_unfamiliar_penalty * (1.0 - focus_ratio)

  return 1.0 + config.focus_efficiency_bonus_at_max * focus_ratio
