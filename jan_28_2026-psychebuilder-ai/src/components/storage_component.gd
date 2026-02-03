class_name StorageComponent
extends BuildingComponent

func on_initialize() -> void:
  pass

func get_total_stored() -> int:
  var total = 0
  for resource_id in building.storage:
    total += building.storage[resource_id]
  return total

func get_effective_capacity() -> int:
  var bonus = 0
  for component in building.get_components():
    bonus += component.get_storage_bonus()
  return building.storage_capacity + bonus

func is_full() -> bool:
  if get_effective_capacity() <= 0:
    return false
  return get_total_stored() >= get_effective_capacity()

func has_space_for(_resource_id: String, amount: int) -> bool:
  var space = get_effective_capacity() - get_total_stored()
  return space >= amount

func add(resource_id: String, amount: int, purity: float = -1.0) -> int:
  var effective_capacity = get_effective_capacity()
  var space = effective_capacity - get_total_stored()
  var to_add = mini(amount, space)

  var existing = building.storage.get(resource_id, 0)
  var existing_purity = building.storage_purity.get(resource_id, config.purity_initial_level)
  var incoming_purity = purity if purity >= 0.0 else config.purity_initial_level
  incoming_purity = maxf(incoming_purity - config.purity_transfer_loss, config.purity_min_level)

  if existing > 0 and to_add > 0:
    var total = existing + to_add
    building.storage_purity[resource_id] = (existing_purity * existing + incoming_purity * to_add) / total
  elif to_add > 0:
    building.storage_purity[resource_id] = incoming_purity

  building.storage[resource_id] = existing + to_add

  if to_add > 0:
    building.notify_resource_added(resource_id, to_add)

  return amount - to_add

func remove(resource_id: String, amount: int) -> int:
  var available = building.storage.get(resource_id, 0)
  var to_remove = mini(amount, available)
  building.storage[resource_id] = available - to_remove
  if building.storage[resource_id] <= 0:
    building.storage_purity.erase(resource_id)
  return to_remove

func get_amount(resource_id: String) -> int:
  return building.storage.get(resource_id, 0)

func get_purity(resource_id: String) -> float:
  return building.storage_purity.get(resource_id, config.purity_initial_level)
