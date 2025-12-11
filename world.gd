extends Control
class_name World

# you have a bunch of t1 resources
# you have producers that construct such resources
# you have converters that convert resources into others
# structures can target other structures

class Inventory:
  var resources: Dictionary[Res, int] = {} # Resource and its amount
  var cap: int

  func add(res: Res, amount: int) -> void:
    resources[res] = clamp(resources.get(res, 0) + amount, 0, cap)
  
  func add_all(other: Inventory) -> void:
    for res in other.resources.keys():
      add(res, other.resources[res])
  
  func clear() -> void:
    resources.clear()
  
  func remove(res: Res, amount: int) -> void:
    resources[res] = clamp(resources.get(res, 0) - amount, 0, cap)

  func _get(property: StringName) -> Variant:
    var res = ResLibrary.get_by_name(property)
    if res:
      return resources[res]
    return 0
  
  func _get_property_list() -> Array[Dictionary]:
    var plist: Array[Dictionary] = []
    for res in ResLibrary.get_all():
      plist.append({
        "name": res.name,
        "type": "int",
        "usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
      })
    return plist

class Structure extends Res:
  @export var input_resources: Dictionary[Res, int] # Resource and amount required
  @export var output_resources: Dictionary[Res, int] # Resource and amount produced
  @export var production_time: float # time in seconds to produce output

class StructureInstance extends Control:
  var type: Structure
  var inventory: Inventory = Inventory.new()
  var production_timer: float = 0.0

  func process(delta: float) -> void:
    if can_produce():
      production_timer += delta
      if production_timer >= type.production_time:
        produce()
        production_timer = 0.0

  func can_produce() -> bool:
    for res in type.input_resources.keys():
      if inventory.get_amount(res) < type.input_resources[res]:
        return false
    return true

  func produce() -> void:
    for res in type.input_resources.keys():
      inventory.remove_resource(res, type.input_resources[res])
    for res in type.output_resources.keys():
      inventory.add_resource(res, type.output_resources[res])