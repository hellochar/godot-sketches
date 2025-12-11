extends Control
class_name World

# you have a bunch of t1 resources
# you have producers that construct such resources
# you have converters that convert resources into others
# structures can target other structures

static var main: World

var inventory: Inventory = Inventory.new(30)

func _enter_tree() -> void:
  main = self

func _ready() -> void:
  # add three basic random resources
  var basic_resources = ItemLibrary.get_by_tier(Item.ETier.Basic)
  for i in range(3):
    var res = basic_resources.pick_random()
    inventory.add(res, 10)

  inventory.add(Structure.generate_random_producer(), 1)
  inventory.add(Structure.generate_random_producer(), 1)
  inventory.add(Structure.generate_random_transformer_sametier(Item.ETier.Basic), 1)
  inventory.add(Structure.generate_random_upgrader(Item.ETier.Basic, Item.ETier.Advanced), 1)
  inventory.add(Structure.generate_random_upgrader(Item.ETier.Advanced, Item.ETier.Futuristic), 1)

func _process(delta: float) -> void:
  inventory._process(delta)
  %MainInventory.text = inventory._to_string()

func _input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo:
    if event.keycode == KEY_1:
      # Debug: place first structure in inventory
      var structures = []
      for item in inventory.dict.keys():
        if item is Structure:
          structures.append(item)
      if structures.size() > 0:
        place(structures[0])

func place(structure: Structure) -> void:
  if inventory.dict.get(structure, 0) > 0:
    inventory.remove(structure, 1)
    _spawn_structure_instance(structure)

const STRUCTURE_INSTANCE = preload("res://structure_instance.tscn")
func _spawn_structure_instance(structure: Structure) -> void:
  var instance := STRUCTURE_INSTANCE.instantiate()
  instance.type = structure
  %StructuresContainer.add_child(instance)

class Inventory:
  var dict: Dictionary[Item, int] = {} # Resource and its amount
  var cap: int

  func _init(_cap: int) -> void:
    cap = _cap

  func _to_string() -> String:
    var out := "Inventory (cap %d):\n" % cap
    for res in dict.keys():
      out += "x%d %s\n" % [dict[res], res.name]
    return out
  
  func _process(delta):
    for res in dict.keys():
      res._process(self, dict[res], delta)

  func add(res: Item, amount: int) -> void:
    dict[res] = clamp(dict.get(res, 0) + amount, 0, cap)
    if dict[res] == 0:
      dict.erase(res)
  
  func add_all(other: Inventory) -> void:
    for res in other.dict.keys():
      add(res, other.dict[res])
  
  func clear() -> void:
    dict.clear()
  
  func remove(res: Item, amount: int) -> void:
    add(res, -amount)

  func _get(property: StringName) -> Variant:
    var res = ItemLibrary.get_by_name(property)
    if res:
      return dict[res]
    return 0
  
  func _get_property_list() -> Array[Dictionary]:
    var plist: Array[Dictionary] = []
    for res in ItemLibrary.get_all():
      plist.append({
        "name": res.name,
        "type": "int",
        "usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
      })
    return plist
