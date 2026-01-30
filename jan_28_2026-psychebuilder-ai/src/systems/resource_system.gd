extends Node

const ResourceItemScene = preload("res://jan_28_2026-psychebuilder-ai/src/entities/resource_item.tscn")

var resource_types: Dictionary = {}  # id -> ResourceType
var active_resources: Array[Node] = []
var resources_layer: Node2D
var resource_totals: Dictionary = {}  # id -> amount

func _ready() -> void:
  _load_resource_types()

func _load_resource_types() -> void:
  var dir = DirAccess.open("res://jan_28_2026-psychebuilder-ai/resources/resource_types/")
  if dir:
    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
      if file_name.ends_with(".tres"):
        var res = load("res://jan_28_2026-psychebuilder-ai/resources/resource_types/" + file_name)
        if res and res.get("id"):
          resource_types[res.id] = res
      file_name = dir.get_next()

func set_resources_layer(layer: Node2D) -> void:
  resources_layer = layer

func get_resource_type(id: String) -> Resource:
  return resource_types.get(id, null)

func spawn_resource(type_id: String, world_position: Vector2, amount: int = 1) -> Node:
  var res_type = get_resource_type(type_id)
  if not res_type:
    push_error("Unknown resource type: " + type_id)
    return null

  var item = ResourceItemScene.instantiate()
  item.initialize(res_type, amount)
  item.position = world_position

  if resources_layer:
    resources_layer.add_child(item)
  else:
    add_child(item)

  active_resources.append(item)
  _update_total(type_id, amount)
  get_node("/root/EventBus").resource_spawned.emit(type_id, world_position, amount)

  return item

func _update_total(type_id: String, delta: int) -> void:
  if not resource_totals.has(type_id):
    resource_totals[type_id] = 0
  resource_totals[type_id] += delta
  get_node("/root/EventBus").resource_total_changed.emit(type_id, resource_totals[type_id])

func remove_resource(item: Node) -> void:
  if item in active_resources:
    var type_id = item.get_resource_id()
    var amount = item.amount
    active_resources.erase(item)
    item.queue_free()
    _update_total(type_id, -amount)

func process_decay() -> void:
  var to_remove: Array[Node] = []

  for item in active_resources:
    if item.is_carried():
      continue

    var decayed = item.decay()
    if decayed > 0:
      get_node("/root/EventBus").resource_decayed.emit(item.get_resource_id(), decayed)
      _update_total(item.get_resource_id(), -decayed)

    if item.is_depleted():
      to_remove.append(item)

  for item in to_remove:
    remove_resource(item)

func get_total(type_id: String) -> int:
  return resource_totals.get(type_id, 0)

func get_all_resource_types() -> Array:
  return resource_types.values()

func get_resources_at(world_position: Vector2, radius: float = 32.0) -> Array[Node]:
  var result: Array[Node] = []
  for item in active_resources:
    if item.position.distance_to(world_position) <= radius:
      result.append(item)
  return result

func get_nearest_resource(world_position: Vector2, type_id: String = "") -> Node:
  var nearest: Node = null
  var nearest_dist = INF

  for item in active_resources:
    if type_id != "" and item.get_resource_id() != type_id:
      continue
    if item.is_carried():
      continue

    var dist = item.position.distance_to(world_position)
    if dist < nearest_dist:
      nearest_dist = dist
      nearest = item

  return nearest
