extends Control
class_name World

# you have a bunch of t1 resources
# you have producers that construct such resources
# you have converters that convert resources into others
# structures can target other structures

static var main: World

var inventory: Inventory = Inventory.new()

func _enter_tree() -> void:
  main = self

func _ready() -> void:
  # add three basic random resources
  inventory.cap = 30
  var basic_resources = ItemLibrary.get_by_tier(Item.ETier.Basic)
  for i in range(3):
    var res = basic_resources.pick_random()
    inventory.add(res, 10)

  inventory.add(Structure.generate_random_producer(), 1)
  inventory.add(Structure.generate_random_producer(), 1)

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

func _spawn_structure_instance(structure: Structure) -> void:
  var instance = StructureInstance.new()
  instance.type = structure
  %StructuresContainer.add_child(instance)

class Inventory:
  var dict: Dictionary[Item, int] = {} # Resource and its amount
  var cap: int

  func _to_string() -> String:
    var out := "Inventory (cap %d):\n" % cap
    for res in dict.keys():
      out += "%s (x%d)\n" % [res.name, dict[res]]
    return out
  
  func _process(delta):
    for res in dict.keys():
      res._process(dict[res], delta)

  func add(res: Item, amount: int) -> void:
    dict[res] = clamp(dict.get(res, 0) + amount, 0, cap)
  
  func add_all(other: Inventory) -> void:
    for res in other.dict.keys():
      add(res, other.dict[res])
  
  func clear() -> void:
    dict.clear()
  
  func remove(res: Item, amount: int) -> void:
    dict[res] = clamp(dict.get(res, 0) - amount, 0, cap)

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

class StructureInstance extends RichTextLabel:
  var type: Structure
  var inventory: Inventory = Inventory.new()
  var production_timer: float = 0.0

  func render() -> void:
    text = "[b]%s[/b]\n" % type.name
    text += "%s\n" % type.description
    text += inventory.to_string()
    text += "Production progress: %.2f / %.2f\n" % [production_timer, type.production_time]

  func _process(delta: float) -> void:
    if can_produce():
      production_timer += delta
      if production_timer >= type.production_time:
        produce()
        production_timer = 0.0
    render()
  
  func take(source: StructureInstance) -> void:
    # take whatever inputs we're missing
    for res in type.ingredients.keys():
      var needed = type.ingredients[res] - inventory.dict.get(res, 0)
      if needed > 0:
        var available = source.inventory.dict.get(res, 0)
        var to_transfer = min(needed, available)
        if to_transfer > 0:
          source.inventory.remove(res, to_transfer)
          inventory.add(res, to_transfer)

  func can_produce() -> bool:
    for res in type.ingredients.keys():
      if inventory.get_amount(res) < type.ingredients[res]:
        return false
    return true

  func produce() -> void:
    for res in type.ingredients.keys():
      inventory.remove_resource(res, type.ingredients[res])
    for res in type.production.keys():
      inventory.add_resource(res, type.production[res])