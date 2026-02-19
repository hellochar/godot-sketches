extends Node2D

const BuildingDefs = preload("res://jan_28_2026-psychebuilder-ai/src/data/building_definitions.gd")
const AdjacencyRules = preload("res://jan_28_2026-psychebuilder-ai/src/data/adjacency_rules.gd")


enum Status {
  IDLE,
  PROCESSING,
  WAITING_INPUT,
  WAITING_WORKER,
  STORAGE_FULL,
  GENERATING,
  COPING_READY,
  COPING_COOLDOWN,
}

@export_group("Status Display")
@export var status_icons: Dictionary = {
  Status.IDLE: "...",
  Status.PROCESSING: "⚙",
  Status.WAITING_INPUT: "📥",
  Status.WAITING_WORKER: "👤",
  Status.STORAGE_FULL: "📦",
  Status.GENERATING: "✨",
  Status.COPING_READY: "💡",
  Status.COPING_COOLDOWN: "⏳",
}
var status_colors: Dictionary = {
  Status.IDLE: Color(0.5, 0.5, 0.5),
  Status.PROCESSING: Color(0.2, 0.8, 0.2),
  Status.WAITING_INPUT: Color(0.9, 0.6, 0.2),
  Status.WAITING_WORKER: Color(0.8, 0.4, 0.8),
  Status.STORAGE_FULL: Color(0.8, 0.2, 0.2),
  Status.GENERATING: Color(0.2, 0.6, 0.9),
  Status.COPING_READY: Color(0.9, 0.9, 0.2),
  Status.COPING_COOLDOWN: Color(0.4, 0.4, 0.6),
}

var current_status: Status = Status.IDLE

var building_id: String
var definition: Dictionary
var grid_coord: Vector2i
var size: Vector2i = Vector2i(1, 1)
var grid: Node

# Connection
var road_connected: bool = false

# Storage
var storage: Dictionary = {}  # resource_id -> amount
var storage_capacity: int = 0

# Processing state (delegated to ProcessorComponent)
var processing_active: bool:
  get:
    var comp := get_component("processor") as ProcessorComponent
    return comp.processing_active if comp else false

var process_timer: float:
  get:
    var comp := get_component("processor") as ProcessorComponent
    return comp.process_timer if comp else 0.0

var assigned_worker: Node = null

# Coping state (delegated to CopingComponent)
var coping_cooldown_timer: float:
  get:
    var comp := get_component("coping") as CopingComponent
    return comp.coping_cooldown_timer if comp else 0.0

# Anxiety spreading state
var anxiety_spread_timer: float = 0.0

# Worry compounding state
var worry_compounding_timer: float = 0.0

# Doubt generation state
var doubt_generation_timer: float = 0.0

# Nostalgia crystallization state
var nostalgia_age_tracker: Dictionary = {}

# Resonance state (delegated to ResonanceComponent)
var is_in_positive_resonance: bool:
  get:
    var comp := get_component("resonance") as ResonanceComponent
    return comp.is_in_positive_resonance if comp else false

var is_in_negative_resonance: bool:
  get:
    var comp := get_component("resonance") as ResonanceComponent
    return comp.is_in_negative_resonance if comp else false

# Saturation state (delegated to SaturationComponent)

# Road emotional memory state
var road_traffic_memory: Dictionary = {}
var road_dominant_emotion: String = ""
var road_imprinted: bool = false

# Cascade boost state
var cascade_boost_timer: float = 0.0
var cascade_boost_active: bool = false

# Awakening state (delegated to AwakeningComponent)
var awakening_experience: int:
  get:
    var comp := get_component("awakening") as AwakeningComponent
    return comp.awakening_experience if comp else 0

var is_awakened: bool:
  get:
    var comp := get_component("awakening") as AwakeningComponent
    return comp.is_awakened if comp else false

# Fatigue state (delegated to FatigueComponent)
var fatigue_level: float:
  get:
    var comp := get_component("fatigue") as FatigueComponent
    return comp.fatigue_level if comp else 0.0

# Harmony state (delegated to HarmonyComponent)
var harmony_partners: Array[Node]:
  get:
    var comp := get_component("harmony") as HarmonyComponent
    return comp.harmony_partners if comp else []

var is_in_harmony: bool:
  get:
    var comp := get_component("harmony") as HarmonyComponent
    return comp.is_in_harmony if comp else false

# Resource purity state (resource_id -> purity level 0.0-1.0)
var storage_purity: Dictionary = {}

# Attunement state (delegated to AttunementComponent)
var attuned_partners: Array[Node]:
  get:
    var comp := get_component("attunement") as AttunementComponent
    return comp.attuned_partners if comp else ([] as Array[Node])

# Fragility state (delegated to FragilityComponent)
var fragility_level: float:
  get:
    var comp := get_component("fragility") as FragilityComponent
    return comp.fragility_level if comp else 0.0

var is_cracked: bool:
  get:
    var comp := get_component("fragility") as FragilityComponent
    return comp.is_cracked if comp else false

# Stagnation state (shared — components read/write directly)
var resource_age_data: Dictionary = {}

# Attention echo state
var attention_echo_cooldown_timer: float = 0.0

# Mastery state (delegated to MasteryComponent)
var mastery_processed: Dictionary:
  get:
    var comp := get_component("mastery") as MasteryComponent
    return comp.mastery_processed if comp else {}

var mastery_levels: Dictionary:
  get:
    var comp := get_component("mastery") as MasteryComponent
    return comp.mastery_levels if comp else {}

var dominant_mastery: String:
  get:
    var comp := get_component("mastery") as MasteryComponent
    return comp.dominant_mastery if comp else ""

var is_specialized: bool:
  get:
    var comp := get_component("mastery") as MasteryComponent
    return comp.is_specialized if comp else false

# Velocity state (delegated to VelocityComponent)
var velocity_momentum: float:
  get:
    var comp := get_component("velocity") as VelocityComponent
    return comp.velocity_momentum if comp else 0.0

# Legacy state (delegated to LegacyComponent)
var is_legacy: bool:
  get:
    var comp := get_component("legacy") as LegacyComponent
    return comp.is_legacy if comp else false

var adjacency_effects: Dictionary = {}
var adjacency_efficiency_multiplier: float = 1.0
var adjacency_output_bonus: int = 0
var adjacency_transport_bonus: float = 0.0
var adjacent_neighbors: Array[Node] = []

var _components: Dictionary = {}

var is_selected: bool = false
var _selection_tween: Tween = null

@export_group("Visual")
@export var disconnected_darken_factor: float = 0.4
@export var selection_glow_color: Color = Color(1.0, 0.9, 0.4, 0.6)
@export var selection_pulse_min: float = 0.4
@export var selection_pulse_max: float = 0.8

@onready var sprite: ColorRect = %ColorRect
@onready var glow_rect: ColorRect = %GlowRect
@onready var label: Label = %Label
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var status_indicator: Label = %StatusIndicator
@onready var disconnected_warning: Label = %DisconnectedWarning
@onready var worker_hint: Label = %WorkerHint
@onready var crack_overlay: Label = %CrackOverlay
@onready var awakened_badge: Label = %AwakenedBadge

var has_ever_had_worker: bool = false

func _ready() -> void:
  if definition:
    _update_visuals()
  EventBus.instance.building_placed.connect(_on_building_placed)
  EventBus.instance.building_removed.connect(_on_building_removed)

func _exit_tree() -> void:
  if EventBus.instance.building_placed.is_connected(_on_building_placed):
    EventBus.instance.building_placed.disconnect(_on_building_placed)
  if EventBus.instance.building_removed.is_connected(_on_building_removed):
    EventBus.instance.building_removed.disconnect(_on_building_removed)

func _add_component(component_name: String, component: Node) -> void:
  _components[component_name] = component
  add_child(component)

func get_component(component_name: String) -> Node:
  return _components.get(component_name)

func has_component(component_name: String) -> bool:
  return _components.has(component_name)

func get_components() -> Array:
  return _components.values()

func notify_resource_added(resource_id: String, amount: int) -> void:
  for component in _components.values():
    if component.has_method("on_resource_added"):
      component.on_resource_added(resource_id, amount)

func _setup_components() -> void:
  var behaviors = definition.get("behaviors", [])

  if definition.get("storage_capacity", 0) > 0:
    var storage_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/storage_component.gd").new()
    _add_component("storage", storage_comp)

  if BuildingDefs.Behavior.GENERATOR in behaviors:
    var generator_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/generator_component.gd").new()
    _add_component("generator", generator_comp)

  if BuildingDefs.Behavior.PROCESSOR in behaviors:
    var processor_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/processor_component.gd").new()
    _add_component("processor", processor_comp)

  if BuildingDefs.Behavior.COPING in behaviors:
    var coping_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/coping_component.gd").new()
    _add_component("coping", coping_comp)

  if BuildingDefs.Behavior.HABIT in behaviors:
    var habit_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/habit_component.gd").new()
    _add_component("habit", habit_comp)

  if BuildingDefs.Behavior.INFRASTRUCTURE in behaviors:
    var infra_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/infrastructure_component.gd").new()
    _add_component("infrastructure", infra_comp)

  if definition.get("storage_capacity", 0) > 0:
    var resonance_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/resonance_component.gd").new()
    _add_component("resonance", resonance_comp)
    var saturation_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/saturation_component.gd").new()
    _add_component("saturation", saturation_comp)

  if BuildingDefs.Behavior.PROCESSOR in behaviors:
    var harmony_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/harmony_component.gd").new()
    _add_component("harmony", harmony_comp)
    var attunement_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/attunement_component.gd").new()
    _add_component("attunement", attunement_comp)
    var echo_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/emotional_echo_component.gd").new()
    _add_component("emotional_echo", echo_comp)
    var fatigue_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/fatigue_component.gd").new()
    _add_component("fatigue", fatigue_comp)
    var mastery_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/mastery_component.gd").new()
    _add_component("mastery", mastery_comp)
    var velocity_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/velocity_component.gd").new()
    _add_component("velocity", velocity_comp)
    var momentum_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/momentum_component.gd").new()
    _add_component("momentum", momentum_comp)
    var legacy_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/legacy_component.gd").new()
    _add_component("legacy", legacy_comp)
    var awakening_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/awakening_component.gd").new()
    _add_component("awakening", awakening_comp)
    var fragility_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/fragility_component.gd").new()
    _add_component("fragility", fragility_comp)
    var network_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/network_component.gd").new()
    _add_component("network", network_comp)

  if definition.get("storage_capacity", 0) > 0:
    var purity_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/purity_component.gd").new()
    _add_component("purity", purity_comp)
    var stagnation_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/stagnation_component.gd").new()
    _add_component("stagnation", stagnation_comp)

  var adjacency_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/adjacency_component.gd").new()
  _add_component("adjacency", adjacency_comp)

  var suppression_comp = preload("res://jan_28_2026-psychebuilder-ai/src/components/suppression_component.gd").new()
  _add_component("suppression", suppression_comp)

  for component in _components.values():
    if component.has_method("_init_component"):
      component._init_component(self)
    if component.has_method("on_initialize"):
      component.on_initialize()

func initialize(p_building_id: String, p_grid_coord: Vector2i, p_grid: Node = null) -> void:
  building_id = p_building_id
  grid_coord = p_grid_coord
  grid = p_grid
  definition = BuildingDefs.get_definition(building_id)

  if definition.is_empty():
    push_error("Unknown building: " + building_id)
    return

  size = definition.get("size", Vector2i(1, 1))
  storage_capacity = definition.get("storage_capacity", 0)
  _update_connection()
  _setup_components()

  if is_inside_tree():
    _update_visuals()

func _update_visuals() -> void:
  var ts = grid.tile_size if grid else 64
  var pixel_size = Vector2(size) * ts

  sprite.size = pixel_size
  _update_connection_visual()
  _update_shader_material()

  if glow_rect:
    glow_rect.position = Vector2(-4, -4)
    glow_rect.size = pixel_size + Vector2(8, 8)
    if not is_selected:
      var base_color = definition.get("color", Color.WHITE)
      glow_rect.color = Color(base_color.r, base_color.g, base_color.b, 0.12)

  label.size = pixel_size
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  _update_storage_display()

  progress_bar.size.x = pixel_size.x
  progress_bar.visible = false

  _update_status_visual()

func set_selected(selected: bool) -> void:
  if is_selected == selected:
    return
  is_selected = selected

  if _selection_tween:
    _selection_tween.kill()
    _selection_tween = null

  if selected:
    glow_rect.color = selection_glow_color
    _selection_tween = create_tween().set_loops()
    _selection_tween.tween_property(glow_rect, "color:a", selection_pulse_max, 0.5)
    _selection_tween.tween_property(glow_rect, "color:a", selection_pulse_min, 0.5)
  else:
    var base_color = definition.get("color", Color.WHITE)
    glow_rect.color = Color(base_color.r, base_color.g, base_color.b, 0.12)

func _update_shader_material() -> void:
  if not sprite.material:
    return
  var base_color = definition.get("color", Color.WHITE)
  sprite.material.set_shader_parameter("base_color", base_color)
  var is_proc = current_status == Status.PROCESSING or current_status == Status.GENERATING
  sprite.material.set_shader_parameter("is_processing", 1.0 if is_proc else 0.0)

func _update_connection() -> void:
  if not grid:
    road_connected = true
    return

  if is_road():
    road_connected = true
    return

  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check) and grid.is_road_at(check):
        road_connected = true
        return

  road_connected = false

func _update_connection_visual() -> void:
  var base_color = definition.get("color", Color.WHITE)
  var is_disconnected = not road_connected and not is_road()
  if is_disconnected:
    sprite.color = base_color.lerp(Color(0.8, 0.2, 0.2), 0.5)
    disconnected_warning.visible = true
  elif is_legacy:
    sprite.color = base_color.lerp(Color(1.0, 0.85, 0.4), 0.5)
    disconnected_warning.visible = false
  elif attuned_partners.size() > 0:
    sprite.color = base_color.lerp(Color(1.0, 0.9, 0.5), 0.4)
    disconnected_warning.visible = false
  elif is_in_harmony:
    sprite.color = base_color.lerp(Color(0.9, 0.95, 0.7), 0.3)
    disconnected_warning.visible = false
  else:
    sprite.color = base_color
    disconnected_warning.visible = false

func _update_storage_display() -> void:
  var name_text = definition.get("name", building_id)
  var status_indicators = ""
  if attuned_partners.size() > 0:
    status_indicators += "A"
  if is_specialized:
    status_indicators += "M"
  if velocity_momentum >= 0.5:
    status_indicators += "V"
  if is_legacy:
    status_indicators += "L"
  if _is_in_any_sync_chain():
    status_indicators += "S"
  if status_indicators != "":
    name_text += " [%s]" % status_indicators
  if storage_capacity > 0:
    var _total = _get_total_stored()
    var storage_text = ""
    for res_id in storage:
      if storage[res_id] > 0:
        var purity = storage_purity.get(res_id, Config.instance.purity_initial_level)
        var mastery_level = get_mastery_level(res_id)
        var stagnation_data = resource_age_data.get(res_id, {})
        var stagnation_level = stagnation_data.get("stagnation", 0.0)
        var indicator = ""
        if purity >= Config.instance.purity_output_bonus_threshold:
          indicator += "*"
        elif purity <= Config.instance.purity_min_level + 0.1:
          indicator += "~"
        if mastery_level >= Config.instance.mastery_max_level:
          indicator += "!"
        elif mastery_level > 0:
          indicator += "+" + str(mastery_level)
        if stagnation_level >= 0.5:
          indicator += " (stale)"
        storage_text += "\n%s: %d%s" % [res_id, storage[res_id], indicator]
    if storage_text == "":
      storage_text = "\n(empty)"
    label.text = name_text + storage_text
  else:
    label.text = name_text

func _process(delta: float) -> void:
  if not definition:
    return

  for component in _components.values():
    if component.has_method("on_process"):
      component.on_process(delta)

  _update_storage_display()
  _process_anxiety_spreading(delta)
  _process_worry_compounding(delta)
  _process_doubt_generation(delta)
  _process_doubt_insight_combination()
  _process_nostalgia_crystallization(delta)
  _process_cascade_boost(delta)
  _process_attention_echo_cooldown(delta)
  _update_status()
  _update_status_visual()

func _show_processing_feedback(produced: Dictionary) -> void:
  if produced.is_empty():
    return
  var parts: Array[String] = []
  for res_id in produced:
    parts.append("+%d %s" % [produced[res_id], res_id.capitalize()])
  var text := ", ".join(parts)
  var center := position + sprite.size * 0.5
  _spawn_feedback_text(center, text, Color(0.5, 1.0, 0.5))
  var tween := create_tween()
  tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.05)
  tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func _spawn_feedback_text(world_pos: Vector2, text: String, color: Color) -> void:
  var feedback := Label.new()
  feedback.text = text
  feedback.position = world_pos - Vector2(50, 10)
  feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  feedback.add_theme_font_size_override("font_size", 11)
  feedback.add_theme_color_override("font_color", color)
  feedback.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
  feedback.add_theme_constant_override("outline_size", 2)
  get_parent().add_child(feedback)
  var tween := create_tween().set_parallel(true)
  tween.tween_property(feedback, "position:y", world_pos.y - 50, 1.5)
  tween.tween_property(feedback, "modulate:a", 0.0, 1.5).set_delay(0.3)
  tween.chain().tween_callback(feedback.queue_free)

func _track_output_resource(resource_id: String, amount: int) -> void:
  if resource_id == "wisdom":
    GameState.instance.track_wisdom_generated(amount)
  elif resource_id == "insight":
    GameState.instance.track_insight_generated(amount)

func _complete_processing_effects() -> void:
  var inputs: Dictionary = definition.get("input", {})
  var processed_negative := false
  var processed_negative_types: Array[String] = []
  for input_resource in inputs:
    if input_resource == "grief":
      GameState.instance.track_grief_processed(inputs[input_resource])
      processed_negative = true
      processed_negative_types.append("grief")
    elif input_resource == "anxiety":
      GameState.instance.track_anxiety_processed(inputs[input_resource])
      processed_negative = true
      processed_negative_types.append("anxiety")
    elif input_resource in Config.instance.breakthrough_negative_types:
      processed_negative_types.append(input_resource)

  for neg_type in processed_negative_types:
    GameState.instance.record_negative_processed(neg_type, inputs.get(neg_type, 1))

  if processed_negative:
    _output_resource("tension", Config.instance.tension_from_processing)

  _try_attention_echo_refund(inputs)

  for input_resource in inputs:
    GameState.instance.record_processing_event(self, input_resource)

  for input_resource in inputs:
    if is_resource_fresh(input_resource):
      EventBus.instance.fresh_resource_bonus.emit(self, input_resource)
    reset_resource_age(input_resource)

  var produced: Dictionary = {}
  for component in _components.values():
    component.on_processing_complete(inputs, produced)

  var total_bonus := 0
  for component in _components.values():
    total_bonus += component.get_output_bonus()
  total_bonus += get_adjacency_output_bonus()

  var spillover := get_adjacency_spillover()
  for spillover_resource in spillover:
    _output_resource(spillover_resource, spillover[spillover_resource])

  var attunement_comp := get_component("attunement") as AttunementComponent
  if attunement_comp:
    var synergy := attunement_comp.try_synergy()
    if synergy.get("triggered", false):
      if synergy.has("output_type"):
        _output_resource(synergy["output_type"], synergy.get("amount", 1))
      if synergy.has("calm_bonus"):
        _output_resource("calm", synergy["calm_bonus"])
      if synergy.has("energy_bonus"):
        GameState.instance.add_energy(synergy["energy_bonus"])

  var conditional_outputs: Dictionary = definition.get("conditional_outputs", {})
  if not conditional_outputs.is_empty():
    for condition_resource in conditional_outputs:
      if storage.get(condition_resource, 0) > 0:
        var output_data := conditional_outputs[condition_resource] as Dictionary
        var amount: int = int(output_data["amount"]) + total_bonus
        _track_output_resource(output_data["output"], amount)
        _cascade_output_resource(output_data["output"], amount)
        produced[output_data["output"]] = amount
        _show_processing_feedback(produced)
        return

  var outputs: Dictionary = definition.get("output", {})
  for resource_id in outputs:
    var amount: int = int(outputs[resource_id]) + total_bonus
    _track_output_resource(resource_id, amount)
    _cascade_output_resource(resource_id, amount)
    produced[resource_id] = amount
  _show_processing_feedback(produced)

func _get_recipe_key(inputs: Dictionary) -> String:
  var sorted_keys = inputs.keys()
  sorted_keys.sort()
  var parts: Array[String] = []
  for key in sorted_keys:
    parts.append("%s:%d" % [key, inputs[key]])
  return ":".join(parts)

func _process_anxiety_spreading(delta: float) -> void:
  if not has_behavior(BuildingDefs.Behavior.STORAGE):
    return

  var anxiety_amount = storage.get("anxiety", 0)
  if anxiety_amount < Config.instance.anxiety_overflow_threshold:
    return

  anxiety_spread_timer += delta
  if anxiety_spread_timer < Config.instance.anxiety_spread_interval:
    return

  anxiety_spread_timer = 0.0
  _spread_anxiety_to_neighbors()

func _spread_anxiety_to_neighbors() -> void:
  if not grid:
    return

  var spread_amount = Config.instance.anxiety_spread_amount
  var all_adjacent_coords: Array[Vector2i] = []

  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        all_adjacent_coords.append(check)

  var spread_targets: Array[Node] = []
  for coord in all_adjacent_coords:
    var occupant = grid.get_occupant(coord)
    if occupant and occupant != self and occupant.has_method("add_to_storage"):
      if occupant not in spread_targets:
        spread_targets.append(occupant)

  for target in spread_targets:
    if target.storage_capacity > 0:
      var removed = remove_from_storage("anxiety", spread_amount)
      if removed > 0:
        target.add_to_storage("anxiety", removed)
        break

func _evaluate_trigger(trigger: String) -> bool:
  if trigger.is_empty():
    return false

  var parts = trigger.split(" ", false)
  if parts.size() != 3:
    return false

  var resource_id = parts[0]
  var operator = parts[1]
  var threshold = parts[2].to_int()

  var current_value = 0
  for building in GameState.instance.active_buildings:
    current_value += building.storage.get(resource_id, 0)

  match operator:
    ">":
      return current_value > threshold
    ">=":
      return current_value >= threshold
    "<":
      return current_value < threshold
    "<=":
      return current_value <= threshold
    "==":
      return current_value == threshold
    _:
      return false

func has_behavior(behavior: int) -> bool:
  var behaviors = definition.get("behaviors", [])
  return behavior in behaviors

func _has_inputs(inputs: Dictionary) -> bool:
  for resource_id in inputs:
    if storage.get(resource_id, 0) < inputs[resource_id]:
      return false
  return true

func _consume_inputs(inputs: Dictionary) -> void:
  for resource_id in inputs:
    storage[resource_id] = storage.get(resource_id, 0) - inputs[resource_id]

func _output_resource(resource_id: String, amount: int, purity: float = -1.0) -> void:
  var effective_capacity = get_effective_storage_capacity()
  var space = effective_capacity - _get_total_stored()
  var to_store = mini(amount, space)
  var output_purity = purity if purity >= 0.0 else Config.instance.purity_initial_level

  if to_store > 0:
    var existing = storage.get(resource_id, 0)
    var existing_purity = storage_purity.get(resource_id, Config.instance.purity_initial_level)
    if existing > 0:
      var total = existing + to_store
      storage_purity[resource_id] = (existing_purity * existing + output_purity * to_store) / total
    else:
      storage_purity[resource_id] = output_purity
    storage[resource_id] = existing + to_store

  var overflow = amount - to_store
  if overflow > 0:
    var transmuted = _try_overflow_transmutation(resource_id, overflow)
    var remaining_overflow = overflow - transmuted
    if remaining_overflow > 0:
      var tile_size = Config.instance.tile_size if Config.instance else (grid.tile_size if grid else 64)
      var spawn_pos = position + Vector2(size) * tile_size * 0.5 + Vector2(randf_range(-16, 16), randf_range(-16, 16))
      EventBus.instance.resource_overflow.emit(resource_id, remaining_overflow, self, spawn_pos)

func _cascade_output_resource(resource_id: String, amount: int) -> void:
  var remaining = _try_cascade_output(resource_id, amount)
  if remaining > 0:
    _output_resource(resource_id, remaining)

func _get_total_stored() -> int:
  var total = 0
  for resource_id in storage:
    total += storage[resource_id]
  return total

func get_effective_storage_capacity() -> int:
  var bonus = get_attunement_storage_bonus()
  for component in _components.values():
    bonus += component.get_storage_bonus()
  return storage_capacity + bonus

func add_to_storage(resource_id: String, amount: int, purity: float = -1.0) -> int:
  var effective_capacity = get_effective_storage_capacity()
  var space = effective_capacity - _get_total_stored()
  var to_add = mini(amount, space)
  var existing = storage.get(resource_id, 0)
  var existing_purity = storage_purity.get(resource_id, Config.instance.purity_initial_level)
  var incoming_purity = purity if purity >= 0.0 else Config.instance.purity_initial_level
  incoming_purity = maxf(incoming_purity - Config.instance.purity_transfer_loss, Config.instance.purity_min_level)
  if existing > 0 and to_add > 0:
    var total = existing + to_add
    storage_purity[resource_id] = (existing_purity * existing + incoming_purity * to_add) / total
  elif to_add > 0:
    storage_purity[resource_id] = incoming_purity
  storage[resource_id] = existing + to_add
  return amount - to_add

func remove_from_storage(resource_id: String, amount: int) -> int:
  var available = storage.get(resource_id, 0)
  var to_remove = mini(amount, available)
  storage[resource_id] = available - to_remove
  if storage[resource_id] <= 0:
    storage_purity.erase(resource_id)
  return to_remove

func get_storage_purity(resource_id: String) -> float:
  return storage_purity.get(resource_id, Config.instance.purity_initial_level)

func get_storage_amount(resource_id: String) -> int:
  return storage.get(resource_id, 0)

func has_space_for(resource_id: String, amount: int) -> bool:
  var effective_capacity = get_effective_storage_capacity()
  var space = effective_capacity - _get_total_stored()
  return space >= amount

func assign_worker(worker: Node) -> void:
  assigned_worker = worker
  has_ever_had_worker = true

func unassign_worker() -> void:
  assigned_worker = null

func is_road() -> bool:
  return has_component("infrastructure") or has_behavior(BuildingDefs.Behavior.INFRASTRUCTURE)

func trigger_habit() -> void:
  var habit_comp = get_component("habit")
  if habit_comp:
    habit_comp.trigger()
    return

  if not has_behavior(BuildingDefs.Behavior.HABIT):
    return

  var consumes = definition.get("habit_consumes", {})
  var energy_cost = consumes.get("energy", 0)
  if energy_cost > 0:
    if not GameState.instance.spend_energy(energy_cost):
      return

  var adjacency_multiplier = _get_habit_adjacency_multiplier()
  var weather_modifier = GameState.instance.get_weather_habit_modifier()
  var belief_modifier = GameState.instance.get_belief_habit_modifier()
  var total_multiplier = adjacency_multiplier * weather_modifier * belief_modifier

  if building_id == "exercise_yard":
    var release_result = _perform_cathartic_release()
    if release_result.calm_generated > 0:
      _output_resource("calm", release_result.calm_generated)
    if release_result.insight_generated > 0:
      _output_resource("insight", release_result.insight_generated)
      GameState.instance.track_insight_generated(release_result.insight_generated)

  var generates = definition.get("habit_generates", {})
  for resource_id in generates:
    var amount = int(generates[resource_id] * total_multiplier)
    _output_resource(resource_id, amount)

  var reduces = definition.get("habit_reduces", {})
  for resource_id in reduces:
    var to_reduce = int(reduces[resource_id] * total_multiplier)
    var removed = remove_from_storage(resource_id, to_reduce)
    var remaining = to_reduce - removed
    if remaining > 0:
      GameState.instance.update_resource_total(resource_id, -remaining)

  var energy_bonus = definition.get("habit_energy_bonus", 0)
  if energy_bonus > 0:
    var bonus_amount = int(energy_bonus * total_multiplier)
    GameState.instance.add_energy(bonus_amount)

  var habit_parts: Array[String] = []
  for resource_id in generates:
    var amount = int(generates[resource_id] * total_multiplier)
    if amount > 0:
      habit_parts.append("+%d %s" % [amount, resource_id.capitalize()])
  if energy_bonus > 0:
    habit_parts.append("+%d Energy" % int(energy_bonus * total_multiplier))
  if habit_parts.size() > 0:
    var center := position + sprite.size * 0.5
    _spawn_feedback_text(center, ", ".join(habit_parts), Color(0.5, 0.9, 0.8))

func _update_status() -> void:
  if is_road():
    current_status = Status.IDLE
    return

  if _is_storage_full():
    current_status = Status.STORAGE_FULL
    return

  if has_behavior(BuildingDefs.Behavior.PROCESSOR):
    if processing_active:
      current_status = Status.PROCESSING
      return
    if definition.get("requires_worker", false) and not assigned_worker:
      current_status = Status.WAITING_WORKER
      return
    var inputs = definition.get("input", {})
    if not inputs.is_empty() and not _has_inputs(inputs):
      current_status = Status.WAITING_INPUT
      return

  if has_behavior(BuildingDefs.Behavior.COPING):
    if coping_cooldown_timer > 0:
      current_status = Status.COPING_COOLDOWN
      return
    var trigger = definition.get("coping_trigger", "")
    if _evaluate_trigger(trigger):
      current_status = Status.COPING_READY
      return

  if has_behavior(BuildingDefs.Behavior.GENERATOR):
    current_status = Status.GENERATING
    return

  current_status = Status.IDLE

func _update_status_visual() -> void:
  status_indicator.text = status_icons.get(current_status, "...")
  worker_hint.visible = current_status == Status.WAITING_WORKER and not has_ever_had_worker

  var is_processor = has_behavior(BuildingDefs.Behavior.PROCESSOR)
  var is_coping = has_behavior(BuildingDefs.Behavior.COPING)

  if is_processor and processing_active:
    progress_bar.visible = true
    var total_time = definition.get("process_time", 1.0)
    var progress = 1.0 - (process_timer / total_time)
    progress_bar.value = progress * 100.0
  elif is_coping and coping_cooldown_timer > 0:
    progress_bar.visible = true
    var total_cooldown = definition.get("coping_cooldown", 30.0)
    var progress = 1.0 - (coping_cooldown_timer / total_cooldown)
    progress_bar.value = progress * 100.0
  else:
    progress_bar.visible = false

  if crack_overlay:
    var show_cracks = fragility_level >= Config.instance.fragility_crack_threshold
    crack_overlay.visible = show_cracks
    if show_cracks:
      var crack_alpha = lerpf(0.4, 1.0, (fragility_level - Config.instance.fragility_crack_threshold) / (1.0 - Config.instance.fragility_crack_threshold))
      crack_overlay.modulate.a = crack_alpha

  if awakened_badge:
    awakened_badge.visible = is_awakened

func _is_storage_full() -> bool:
  var effective_capacity = get_effective_storage_capacity()
  if effective_capacity <= 0:
    return false
  return _get_total_stored() >= effective_capacity

func _get_grief_speed_multiplier() -> float:
  var grief_amount = storage.get("grief", 0)
  if grief_amount < Config.instance.grief_slowdown_threshold:
    return 1.0
  var excess_grief = grief_amount - Config.instance.grief_slowdown_threshold
  var slowdown = excess_grief * Config.instance.grief_slowdown_factor
  slowdown = minf(slowdown, Config.instance.grief_max_slowdown)
  return 1.0 - slowdown

func _count_adjacent_habits() -> int:
  if not grid:
    return 0
  var count = 0
  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("has_behavior"):
          if occupant.has_behavior(BuildingDefs.Behavior.HABIT):
            count += 1
  return count

func _get_habit_adjacency_multiplier() -> float:
  var adjacent_count = _count_adjacent_habits()
  if adjacent_count == 0:
    return 1.0
  var bonus = adjacent_count * Config.instance.habit_adjacency_bonus
  return minf(1.0 + bonus, Config.instance.habit_max_adjacency_multiplier)

func _get_calm_aura_suppression() -> float:
  var base_suppression = 0.0

  if is_affected_by_suppression_field():
    base_suppression = Config.instance.transmutation_suppression_strength

  if not grid:
    return base_suppression

  var total_calm = 0
  var radius = Config.instance.calm_aura_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          var calm_amount = occupant.get_storage_amount("calm")
          var saturation_mult = 1.0
          if occupant.has_method("get_calm_saturation_multiplier"):
            saturation_mult = occupant.get_calm_saturation_multiplier()
          total_calm += int(calm_amount * saturation_mult)

  if total_calm < Config.instance.calm_aura_threshold:
    return base_suppression

  var excess_calm = total_calm - Config.instance.calm_aura_threshold
  var calm_suppression = excess_calm * Config.instance.calm_aura_suppression
  calm_suppression = minf(calm_suppression, Config.instance.calm_aura_max_suppression)

  return minf(base_suppression + calm_suppression, Config.instance.calm_aura_max_suppression)

func _get_nearby_tension() -> int:
  if not grid:
    return 0

  var total_tension = 0
  var radius = Config.instance.tension_aura_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_tension += occupant.get_storage_amount("tension")

  return total_tension

func _get_tension_speed_multiplier() -> float:
  var tension_amount = _get_nearby_tension() + storage.get("tension", 0)
  if tension_amount < Config.instance.tension_slowdown_threshold:
    return 1.0
  var excess_tension = tension_amount - Config.instance.tension_slowdown_threshold
  var slowdown = excess_tension * Config.instance.tension_slowdown_factor
  slowdown = minf(slowdown, Config.instance.tension_max_slowdown)
  return 1.0 - slowdown

func _get_nearby_wisdom() -> int:
  if not grid:
    return 0

  var total_wisdom = 0
  var radius = Config.instance.wisdom_aura_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_wisdom += occupant.get_storage_amount("wisdom")

  return total_wisdom

func _get_wisdom_efficiency_multiplier() -> float:
  var wisdom_amount = _get_nearby_wisdom() + storage.get("wisdom", 0)
  var saturation_bonus = get_wisdom_saturation_bonus()
  if wisdom_amount < Config.instance.wisdom_efficiency_threshold:
    return 1.0 + saturation_bonus
  var excess_wisdom = wisdom_amount - Config.instance.wisdom_efficiency_threshold
  var bonus = excess_wisdom * Config.instance.wisdom_efficiency_bonus_per_unit
  bonus = minf(bonus, Config.instance.wisdom_max_efficiency_bonus)
  return 1.0 + bonus + saturation_bonus

func _perform_cathartic_release() -> Dictionary:
  var tension_removed = remove_from_storage("tension", storage.get("tension", 0))
  var calm_generated = int(tension_removed * Config.instance.cathartic_release_calm_per_tension)
  var insight_generated = 0

  if tension_removed > 0 and randf() < Config.instance.cathartic_release_insight_chance:
    insight_generated = 1

  return {
    "tension_removed": tension_removed,
    "calm_generated": calm_generated,
    "insight_generated": insight_generated
  }

func _process_worry_compounding(delta: float) -> void:
  if storage_capacity <= 0:
    return

  var worry_amount = storage.get("worry", 0)
  if worry_amount < Config.instance.worry_compounding_threshold:
    worry_compounding_timer = 0.0
    return

  if worry_amount >= Config.instance.worry_compounding_max:
    return

  worry_compounding_timer += delta
  if worry_compounding_timer >= Config.instance.worry_compounding_interval:
    worry_compounding_timer = 0.0
    _output_resource("worry", Config.instance.worry_compounding_amount)

func _process_doubt_generation(delta: float) -> void:
  if storage_capacity <= 0:
    return

  var should_generate = false
  if not road_connected and not is_road():
    should_generate = true
  if current_status == Status.WAITING_INPUT or current_status == Status.WAITING_WORKER:
    should_generate = true

  if not should_generate:
    doubt_generation_timer = 0.0
    return

  doubt_generation_timer += delta
  if doubt_generation_timer >= Config.instance.doubt_generation_interval:
    doubt_generation_timer = 0.0
    var amount = 0
    if not road_connected and not is_road():
      amount += Config.instance.doubt_from_disconnected
    if current_status == Status.WAITING_INPUT or current_status == Status.WAITING_WORKER:
      amount += Config.instance.doubt_from_waiting
    if amount > 0:
      _output_resource("doubt", amount)

func _process_doubt_insight_combination() -> void:
  if storage_capacity <= 0:
    return

  var doubt_amount = storage.get("doubt", 0)
  var insight_amount = storage.get("insight", 0)

  if doubt_amount >= Config.instance.doubt_insight_combine_threshold and insight_amount >= Config.instance.doubt_insight_combine_threshold:
    remove_from_storage("doubt", Config.instance.doubt_insight_combine_threshold)
    remove_from_storage("insight", Config.instance.doubt_insight_combine_threshold)
    _output_resource("wisdom", Config.instance.wisdom_from_answered_doubt)

func _get_doubt_efficiency_multiplier() -> float:
  var doubt_amount = _get_nearby_doubt() + storage.get("doubt", 0)
  if doubt_amount <= 0:
    return 1.0
  var penalty = doubt_amount * Config.instance.doubt_efficiency_penalty
  penalty = minf(penalty, Config.instance.doubt_max_efficiency_penalty)
  return 1.0 - penalty

func _get_nearby_doubt() -> int:
  if not grid:
    return 0

  var total_doubt = 0
  var radius = Config.instance.doubt_spread_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total_doubt += occupant.get_storage_amount("doubt")

  return total_doubt

func _process_nostalgia_crystallization(delta: float) -> void:
  if storage_capacity <= 0:
    return

  var nostalgia_amount = storage.get("nostalgia", 0)
  if nostalgia_amount <= 0:
    nostalgia_age_tracker.clear()
    return

  var tracked_count = nostalgia_age_tracker.size()
  while tracked_count < nostalgia_amount:
    var batch_id = "batch_%d_%d" % [Time.get_ticks_msec(), tracked_count]
    nostalgia_age_tracker[batch_id] = 0.0
    tracked_count += 1

  var crystallized_count = 0
  var to_remove: Array[String] = []
  for batch_id in nostalgia_age_tracker:
    nostalgia_age_tracker[batch_id] += delta
    if nostalgia_age_tracker[batch_id] >= Config.instance.nostalgia_crystallization_time:
      crystallized_count += 1
      to_remove.append(batch_id)

  if crystallized_count <= 0:
    return

  var amount_to_crystallize = mini(crystallized_count, nostalgia_amount)
  remove_from_storage("nostalgia", amount_to_crystallize)

  var removed_count = 0
  for batch_id in to_remove:
    nostalgia_age_tracker.erase(batch_id)
    removed_count += 1
    if removed_count >= amount_to_crystallize:
      break

  var nearby_calm = _count_nearby_resource("calm")
  var nearby_negative = _count_nearby_resource("anxiety") + _count_nearby_resource("tension") + _count_nearby_resource("grief")

  var output_type: String
  var output_amount = amount_to_crystallize * Config.instance.nostalgia_crystallization_amount

  if nearby_calm >= Config.instance.nostalgia_crystallization_calm_threshold and nearby_calm > nearby_negative:
    output_type = "joy"
  elif nearby_negative >= Config.instance.nostalgia_crystallization_negative_threshold:
    output_type = "grief"
  else:
    output_type = "joy" if randf() < 0.5 else "grief"

  _output_resource(output_type, output_amount)
  EventBus.instance.nostalgia_crystallized.emit(self, output_type, output_amount)

func _count_nearby_resource(resource_id: String) -> int:
  var total = storage.get(resource_id, 0)
  if not grid:
    return total

  var radius = Config.instance.nostalgia_crystallization_radius

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          total += occupant.get_storage_amount(resource_id)

  return total

func _get_adjacent_buildings() -> Array[Node]:
  var result: Array[Node] = []
  if not grid:
    return result

  for x in range(-1, size.x + 1):
    for y in range(-1, size.y + 1):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("add_to_storage"):
          if occupant not in result:
            result.append(occupant)

  return result

func get_calm_saturation_multiplier() -> float:
  var comp := get_component("saturation") as SaturationComponent
  if comp and comp.saturation_state == SaturationComponent.State.CALM_SATURATED:
    return Config.instance.saturation_calm_aura_multiplier
  return 1.0

func get_wisdom_saturation_bonus() -> float:
  var comp := get_component("saturation") as SaturationComponent
  if comp and comp.saturation_state == SaturationComponent.State.WISDOM_SATURATED:
    return Config.instance.saturation_wisdom_efficiency_bonus
  return 0.0

func get_joy_numbness_factor() -> float:
  var comp := get_component("saturation") as SaturationComponent
  return 1.0 - (comp.joy_numbness_level if comp else 0.0)

func record_road_traffic(emotion: String, amount: float) -> void:
  if not is_road():
    return

  var gain = Config.instance.road_memory_gain_per_pass * amount
  road_traffic_memory[emotion] = road_traffic_memory.get(emotion, 0.0) + gain
  _update_road_dominant_emotion()
  _update_road_visual()

func get_road_speed_modifier() -> float:
  if not road_imprinted:
    return 1.0

  if road_dominant_emotion in Config.instance.road_positive_emotions:
    return 1.0 + Config.instance.road_imprint_speed_bonus
  elif road_dominant_emotion in Config.instance.road_negative_emotions:
    return 1.0 - Config.instance.road_imprint_speed_penalty

  return 1.0

func _update_road_dominant_emotion() -> void:
  var max_value = 0.0
  var dominant = ""

  for emotion in road_traffic_memory:
    if road_traffic_memory[emotion] > max_value:
      max_value = road_traffic_memory[emotion]
      dominant = emotion

  road_dominant_emotion = dominant
  road_imprinted = max_value >= Config.instance.road_memory_threshold

func _update_road_visual() -> void:
  if not is_road():
    return

  var base_color = definition.get("color", Color.WHITE)

  if not road_imprinted:
    sprite.color = base_color
    return

  var emotion_color = base_color
  if road_dominant_emotion in Config.instance.road_positive_emotions:
    emotion_color = Color(0.6, 0.8, 0.6)
  elif road_dominant_emotion in Config.instance.road_negative_emotions:
    emotion_color = Color(0.7, 0.5, 0.6)

  sprite.color = base_color.lerp(emotion_color, 0.4)

func _process_cascade_boost(delta: float) -> void:
  if not cascade_boost_active:
    return

  cascade_boost_timer -= delta
  if cascade_boost_timer <= 0:
    cascade_boost_active = false
    cascade_boost_timer = 0.0

func trigger_cascade_boost(resource_id: String) -> void:
  if not has_behavior(BuildingDefs.Behavior.GENERATOR):
    return

  var generates = definition.get("generates", "")
  if generates == resource_id:
    cascade_boost_active = true
    cascade_boost_timer = Config.instance.cascade_generator_boost_duration

func _try_cascade_output(resource_id: String, amount: int) -> int:
  if not grid:
    return amount

  var remaining = amount
  var neighbors = _get_adjacent_buildings()

  for neighbor in neighbors:
    if remaining <= 0:
      break

    if Config.instance.cascade_direct_storage and neighbor.has_behavior(BuildingDefs.Behavior.STORAGE):
      var overflow = neighbor.add_to_storage(resource_id, remaining)
      remaining = overflow

    if remaining > 0 and neighbor.has_behavior(BuildingDefs.Behavior.PROCESSOR):
      var inputs = neighbor.definition.get("input", {})
      if resource_id in inputs:
        var transfer = mini(remaining, Config.instance.cascade_processor_transfer)
        var overflow = neighbor.add_to_storage(resource_id, transfer)
        remaining -= (transfer - overflow)

    if neighbor.has_behavior(BuildingDefs.Behavior.GENERATOR):
      neighbor.trigger_cascade_boost(resource_id)

  return remaining

func get_attunement_storage_bonus() -> int:
  var comp := get_component("attunement") as AttunementComponent
  return comp.get_storage_bonus() if comp else 0

func reset_resource_age(resource_id: String) -> void:
  if resource_age_data.has(resource_id):
    resource_age_data[resource_id] = {"age": 0.0, "stagnation": 0.0}

func get_resource_stagnation(resource_id: String) -> float:
  if not resource_age_data.has(resource_id):
    return 0.0
  return resource_age_data[resource_id].get("stagnation", 0.0)

func is_resource_fresh(resource_id: String) -> bool:
  if not resource_age_data.has(resource_id):
    return true
  return resource_age_data[resource_id].get("age", 0.0) < Config.instance.stagnation_fresh_threshold

func _process_attention_echo_cooldown(delta: float) -> void:
  if attention_echo_cooldown_timer > 0:
    attention_echo_cooldown_timer -= delta

func _try_attention_echo_refund(inputs: Dictionary) -> void:
  if attention_echo_cooldown_timer > 0:
    return

  var max_stagnation = 0.0
  for resource_id in inputs:
    var stagnation = get_resource_stagnation(resource_id)
    if stagnation > max_stagnation:
      max_stagnation = stagnation

  if max_stagnation < Config.instance.attention_echo_stagnation_threshold:
    return

  var stagnation_factor = (max_stagnation - Config.instance.attention_echo_stagnation_threshold) / (Config.instance.stagnation_max_level - Config.instance.attention_echo_stagnation_threshold)
  var refund = Config.instance.attention_echo_base_refund + stagnation_factor * Config.instance.attention_echo_stagnation_multiplier

  if is_awakened:
    refund *= (1.0 + Config.instance.attention_echo_awakened_bonus)

  refund = minf(refund, Config.instance.attention_echo_max_refund)

  GameState.instance.free_attention(refund)
  attention_echo_cooldown_timer = Config.instance.attention_echo_cooldown
  EventBus.instance.attention_echo_refund.emit(self, max_stagnation, refund)

func _try_overflow_transmutation(resource_id: String, overflow_amount: int) -> int:
  if randf() > Config.instance.transmutation_chance:
    return 0

  var nearby_resources = _scan_nearby_resources_for_transmutation()
  var transmuted_amount = 0

  for recipe_key in Config.instance.transmutation_recipes:
    var parts = recipe_key.split("+")
    if parts.size() != 2:
      continue

    var overflow_type = parts[0]
    var catalyst_type = parts[1]

    if resource_id != overflow_type:
      continue

    var catalyst_amount = nearby_resources.get(catalyst_type, 0)
    if catalyst_amount < Config.instance.transmutation_threshold:
      continue

    var result_type = Config.instance.transmutation_recipes[recipe_key]
    var transmute_count = mini(overflow_amount - transmuted_amount, catalyst_amount / Config.instance.transmutation_threshold)

    if transmute_count <= 0:
      continue

    if result_type == "suppression_field":
      _create_suppression_field()
      transmuted_amount += transmute_count
      EventBus.instance.overflow_transmuted.emit(self, resource_id, "suppression_field", transmute_count)
    else:
      _output_transmuted_resource(result_type, transmute_count)
      transmuted_amount += transmute_count
      EventBus.instance.overflow_transmuted.emit(self, resource_id, result_type, transmute_count)

    break

  return transmuted_amount

func _scan_nearby_resources_for_transmutation() -> Dictionary:
  var result: Dictionary = {}
  var radius = Config.instance.transmutation_radius

  var sat_comp := get_component("saturation") as SaturationComponent
  var sat_resource := sat_comp.saturation_resource if sat_comp else ""
  if sat_resource != "":
    result[sat_resource] = storage.get(sat_resource, 0)

  for resource_id in storage:
    result[resource_id] = result.get(resource_id, 0) + storage.get(resource_id, 0)

  if not grid:
    return result

  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_storage_amount"):
          for resource_id in ["joy", "grief", "calm", "anxiety", "wisdom", "insight", "worry", "doubt"]:
            var amount = occupant.get_storage_amount(resource_id)
            if amount > 0:
              result[resource_id] = result.get(resource_id, 0) + amount

  return result

func _output_transmuted_resource(resource_id: String, amount: int) -> void:
  var neighbors = _get_adjacent_buildings()
  for neighbor in neighbors:
    if neighbor.storage_capacity > 0:
      var overflow = neighbor.add_to_storage(resource_id, amount)
      if overflow < amount:
        return

  var tile_size = Config.instance.tile_size
  var spawn_pos = position + Vector2(size) * tile_size * 0.5 + Vector2(randf_range(-16, 16), randf_range(-16, 16))
  EventBus.instance.resource_overflow.emit(resource_id, amount, self, spawn_pos)

func _create_suppression_field() -> void:
  var comp := get_component("suppression") as SuppressionComponent
  if comp:
    comp.create_suppression_field()

func get_suppression_field_strength() -> float:
  var comp := get_component("suppression") as SuppressionComponent
  return comp.get_suppression_field_strength() if comp else 0.0

func is_affected_by_suppression_field() -> bool:
  if not grid:
    return false

  var radius = Config.instance.transmutation_suppression_radius
  for x in range(-radius, size.x + radius):
    for y in range(-radius, size.y + radius):
      var check = grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check):
        var occupant = grid.get_occupant(check)
        if occupant and occupant != self and occupant.has_method("get_suppression_field_strength"):
          if occupant.get_suppression_field_strength() > 0:
            return true
  return false

func get_mastery_level(resource_id: String) -> int:
  var comp := get_component("mastery") as MasteryComponent
  return comp.get_level(resource_id) if comp else 0

func get_speed_multiplier_breakdown() -> Dictionary:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return {}

  var _awakening := get_component("awakening") as AwakeningComponent
  var _fatigue := get_component("fatigue") as FatigueComponent
  var _fragility := get_component("fragility") as FragilityComponent
  var _harmony := get_component("harmony") as HarmonyComponent
  var _resonance := get_component("resonance") as ResonanceComponent
  var _attunement := get_component("attunement") as AttunementComponent
  var _purity := get_component("purity")
  var _stagnation := get_component("stagnation")
  var _echo := get_component("emotional_echo") as EmotionalEchoComponent
  var _momentum := get_component("momentum") as MomentumComponent
  var _velocity := get_component("velocity") as VelocityComponent
  var _mastery := get_component("mastery") as MasteryComponent
  var _legacy := get_component("legacy") as LegacyComponent
  var _network := get_component("network") as NetworkComponent

  var categories: Dictionary = {}

  categories["building_state"] = {
    "awakened": _awakening.get_speed_multiplier() if _awakening else 1.0,
    "fatigue": _fatigue.get_speed_multiplier() if _fatigue else 1.0,
    "fragility": _fragility.get_speed_multiplier() if _fragility else 1.0,
  }

  categories["environment"] = {
    "weather": GameState.instance.get_weather_processing_modifier(),
    "wellbeing": GameState.instance.get_wellbeing_processing_modifier(),
    "breakthrough": GameState.instance.get_breakthrough_speed_modifier(),
    "grief": _get_grief_speed_multiplier(),
    "tension": _get_tension_speed_multiplier(),
  }

  categories["synergy"] = {
    "harmony": _harmony.get_speed_multiplier() if _harmony else 1.0,
    "resonance": _resonance.get_speed_multiplier() if _resonance else 1.0,
    "attunement": _attunement.get_speed_multiplier() if _attunement else 1.0,
    "adjacency": get_adjacency_efficiency_multiplier(),
    "sync_chain": _get_sync_chain_speed_multiplier(),
  }

  categories["resource"] = {
    "purity": _purity.get_speed_multiplier() if _purity else 1.0,
    "stagnation": _stagnation.get_speed_multiplier() if _stagnation else 1.0,
    "wisdom": _get_wisdom_efficiency_multiplier(),
    "echo": _echo.get_speed_multiplier() if _echo else 1.0,
  }

  categories["momentum"] = {
    "flow": GameState.instance.get_flow_state_multiplier(),
    "momentum": _momentum.get_speed_multiplier() if _momentum else 1.0,
    "velocity": _velocity.get_speed_multiplier() if _velocity else 1.0,
    "mastery": _mastery.get_speed_multiplier() if _mastery else 1.0,
    "legacy": _legacy.get_speed_multiplier() if _legacy else 1.0,
    "support": _network.get_speed_multiplier() if _network else 1.0,
  }

  var total := 1.0
  for category in categories:
    for mod_name in categories[category]:
      total *= categories[category][mod_name]

  return {"total": total, "categories": categories}

func get_velocity() -> float:
  var comp := get_component("velocity") as VelocityComponent
  return comp.get_velocity() if comp else 0.0

func _get_sync_chain_speed_multiplier() -> float:
  if not has_behavior(BuildingDefs.Behavior.PROCESSOR):
    return 1.0

  var max_bonus = 0.0
  var inputs = definition.get("input", {})
  for input_resource in inputs:
    var bonus = GameState.instance.get_sync_chain_bonus(self, input_resource)
    if bonus > max_bonus:
      max_bonus = bonus

  return 1.0 + max_bonus

func _is_in_any_sync_chain() -> bool:
  var inputs = definition.get("input", {})
  for input_resource in inputs:
    if GameState.instance.is_in_sync_chain(self, input_resource):
      return true
  return false

func is_legacy_building() -> bool:
  return is_legacy

func get_legacy_timer_progress() -> float:
  var comp := get_component("legacy") as LegacyComponent
  return comp.get_timer_progress() if comp else 0.0

func _on_building_placed(placed_building: Node, _coord: Vector2i) -> void:
  if has_component("adjacency"):
    return
  if placed_building == self:
    recalculate_adjacency()
  elif _is_within_adjacency_radius(placed_building):
    recalculate_adjacency()

func _on_building_removed(removed_building: Node, _coord: Vector2i) -> void:
  if has_component("adjacency"):
    return
  if removed_building == self:
    return
  if removed_building in adjacent_neighbors:
    recalculate_adjacency()

func _is_within_adjacency_radius(other: Node) -> bool:
  if not other or not is_instance_valid(other):
    return false
  if not other.has_method("get_storage_amount"):
    return false
  var other_coord = other.grid_coord if other.has_method("get_storage_amount") else Vector2i(-999, -999)
  var other_size = other.size if "size" in other else Vector2i(1, 1)
  for x in range(size.x):
    for y in range(size.y):
      var my_cell = grid_coord + Vector2i(x, y)
      for ox in range(other_size.x):
        for oy in range(other_size.y):
          var other_cell = other_coord + Vector2i(ox, oy)
          var dist = absi(my_cell.x - other_cell.x) + absi(my_cell.y - other_cell.y)
          if dist <= AdjacencyRules.ADJACENCY_RADIUS:
            return true
  return false

func get_buildings_in_adjacency_radius() -> Array[Node]:
  var result: Array[Node] = []
  if not grid:
    return result
  var checked_buildings: Dictionary = {}
  for x in range(-AdjacencyRules.ADJACENCY_RADIUS, size.x + AdjacencyRules.ADJACENCY_RADIUS):
    for y in range(-AdjacencyRules.ADJACENCY_RADIUS, size.y + AdjacencyRules.ADJACENCY_RADIUS):
      if x >= 0 and x < size.x and y >= 0 and y < size.y:
        continue
      var check = grid_coord + Vector2i(x, y)
      if not grid.is_valid_coord(check):
        continue
      var occupant = grid.get_occupant(check)
      if not occupant or occupant == self:
        continue
      if not occupant.has_method("get_storage_amount"):
        continue
      var occupant_id = occupant.get_instance_id()
      if checked_buildings.has(occupant_id):
        continue
      if _is_within_adjacency_radius(occupant):
        checked_buildings[occupant_id] = true
        result.append(occupant)
  return result

func recalculate_adjacency() -> void:
  if has_component("adjacency"):
    get_component("adjacency").recalculate_adjacency()
    return
  adjacency_effects.clear()
  adjacency_efficiency_multiplier = 1.0
  adjacency_output_bonus = 0
  adjacency_transport_bonus = 0.0
  adjacent_neighbors = get_buildings_in_adjacency_radius()

  var same_type_count = 0

  for neighbor in adjacent_neighbors:
    var neighbor_id = neighbor.building_id if "building_id" in neighbor else ""
    if neighbor_id == "":
      continue

    if neighbor_id == building_id and has_behavior(BuildingDefs.Behavior.GENERATOR):
      same_type_count += 1

    var effect = AdjacencyRules.get_adjacency_effect(building_id, neighbor_id)
    if effect.is_empty():
      continue

    adjacency_effects[neighbor_id] = effect

    if effect.has("efficiency"):
      adjacency_efficiency_multiplier *= effect["efficiency"]

    if effect.has("output_bonus"):
      adjacency_output_bonus += effect["output_bonus"]

    if effect.has("output_penalty"):
      adjacency_output_bonus += effect["output_penalty"]

    if effect.has("transport_bonus"):
      adjacency_transport_bonus += effect["transport_bonus"]

    var effect_type = effect.get("type", -1)
    if effect_type == AdjacencyRules.EffectType.SYNERGY:
      EventBus.instance.adjacency_synergy_formed.emit(self, neighbor, effect)
    elif effect_type == AdjacencyRules.EffectType.CONFLICT:
      EventBus.instance.adjacency_conflict_formed.emit(self, neighbor, effect)

  if same_type_count > 0 and has_behavior(BuildingDefs.Behavior.GENERATOR):
    var stacking_mult = AdjacencyRules.get_stacking_multiplier(building_id, same_type_count + 1)
    adjacency_efficiency_multiplier *= stacking_mult

  EventBus.instance.adjacency_changed.emit(self)

func get_adjacency_efficiency_multiplier() -> float:
  return adjacency_efficiency_multiplier

func get_adjacency_output_bonus() -> int:
  return adjacency_output_bonus

func get_adjacency_transport_bonus() -> float:
  return adjacency_transport_bonus

func get_adjacency_spillover() -> Dictionary:
  var spillover: Dictionary = {}
  for neighbor_id in adjacency_effects:
    var effect = adjacency_effects[neighbor_id]
    if effect.has("spillover"):
      for resource_id in effect["spillover"]:
        spillover[resource_id] = spillover.get(resource_id, 0) + effect["spillover"][resource_id]
  return spillover

func get_adjacent_building_ids() -> Array[String]:
  var result: Array[String] = []
  for neighbor in adjacent_neighbors:
    if "building_id" in neighbor:
      result.append(neighbor.building_id)
  return result

func has_adjacency_synergy() -> bool:
  for neighbor_id in adjacency_effects:
    var effect = adjacency_effects[neighbor_id]
    if effect.get("type", -1) == AdjacencyRules.EffectType.SYNERGY:
      return true
  return false

func has_adjacency_conflict() -> bool:
  for neighbor_id in adjacency_effects:
    var effect = adjacency_effects[neighbor_id]
    if effect.get("type", -1) == AdjacencyRules.EffectType.CONFLICT:
      return true
  return false

func get_adjacency_descriptions() -> Array[Dictionary]:
  var result: Array[Dictionary] = []
  for neighbor_id in adjacency_effects:
    var effect = adjacency_effects[neighbor_id]
    result.append({
      "neighbor": neighbor_id,
      "type": effect.get("type", AdjacencyRules.EffectType.NEUTRAL),
      "description": effect.get("description", ""),
      "efficiency": effect.get("efficiency", 1.0),
      "output_bonus": effect.get("output_bonus", 0)
    })
  return result
