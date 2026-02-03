class_name NetworkComponent
extends BuildingComponent

var support_network: Array[Node] = []
var support_network_transfer_timer: float = 0.0

func on_process(delta: float) -> void:
  _process_support_network()
  _process_network_load_sharing(delta)

func _process_support_network() -> void:
  if not building.has_behavior(building.BuildingDefs.Behavior.PROCESSOR):
    support_network.clear()
    return

  if not grid:
    support_network.clear()
    return

  support_network = _find_connected_buildings_of_same_type()

func _find_connected_buildings_of_same_type() -> Array[Node]:
  var result: Array[Node] = []
  var visited: Dictionary = {}
  var to_visit: Array[Vector2i] = []

  for x in range(-1, building.size.x + 1):
    for y in range(-1, building.size.y + 1):
      if x >= 0 and x < building.size.x and y >= 0 and y < building.size.y:
        continue
      var check = building.grid_coord + Vector2i(x, y)
      if grid.is_valid_coord(check) and grid.is_road_at(check):
        to_visit.append(check)
        visited[check] = true

  while to_visit.size() > 0:
    var current = to_visit.pop_front()
    var occupant = grid.get_occupant(current)

    if occupant and occupant != building and occupant.building_id == building.building_id:
      if occupant not in result:
        result.append(occupant)

    if grid.is_road_at(current):
      for neighbor in grid.get_neighbors(current):
        if not visited.has(neighbor):
          visited[neighbor] = true
          to_visit.append(neighbor)

  return result

func _process_network_load_sharing(delta: float) -> void:
  if support_network.size() < config.support_network_min_size:
    return

  var effective_capacity = building.get_effective_storage_capacity()
  if effective_capacity <= 0:
    return

  var fill_ratio = float(building._get_total_stored()) / float(effective_capacity)
  if fill_ratio < config.support_network_load_share_threshold:
    support_network_transfer_timer = 0.0
    return

  support_network_transfer_timer += delta
  if support_network_transfer_timer < config.support_network_transfer_interval:
    return

  support_network_transfer_timer = 0.0

  var best_target: Node = null
  var lowest_fill: float = 1.0

  for member in support_network:
    var member_capacity = member.get_effective_storage_capacity()
    if member_capacity <= 0:
      continue
    var member_fill = float(member._get_total_stored()) / float(member_capacity)
    if member_fill < lowest_fill:
      lowest_fill = member_fill
      best_target = member

  if best_target and lowest_fill < fill_ratio - 0.1:
    for resource_id in building.storage:
      if building.storage[resource_id] > 0:
        var to_transfer = mini(building.storage[resource_id], config.support_network_transfer_amount)
        var removed = building.remove_from_storage(resource_id, to_transfer)
        if removed > 0:
          best_target.add_to_storage(resource_id, removed)
          break

func get_speed_multiplier() -> float:
  if support_network.size() < config.support_network_min_size:
    return 1.0
  var bonus = support_network.size() * config.support_network_efficiency_per_member
  bonus = minf(bonus, config.support_network_max_efficiency_bonus)
  return 1.0 + bonus

func get_network_size() -> int:
  return support_network.size()
