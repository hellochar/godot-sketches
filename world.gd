extends Control
class_name World

# you have a bunch of t1 resources
# you have producers that construct such resources
# you have converters that convert resources into others
# structures can target other structures

static var main: World

var inventory: Inventory = Inventory.new(30, "Inventory")
var blueprints: Inventory = Inventory.new(1, "Blueprints")
var board: Array[StructureInstance] = []
var turn_count: int = 0
var reward_inventory: Inventory = Inventory.new(30, "Rewards")

func _enter_tree() -> void:
  main = self

func _ready() -> void:
  # # add three basic random resources
  # var basic_resources = ItemLibrary.get_by_tier(Item.ETier.Basic)
  # for i in range(3):
  #   var res = basic_resources.pick_random()
  #   inventory.add(res, 10)

  inventory.add(preload("res://items/basic/peasants.tres"), 10)
  inventory.add(preload("res://items/basic/food.tres"), 10)
  inventory.add(preload("res://items/basic/hut.tres"), 3)
  inventory.add(preload("res://items/basic/livestock.tres"), 3)

  blueprints.prefix = true
  blueprints.add(Structure.generate_random_producer(), 1)
  blueprints.add(Structure.generate_random_producer(), 1)
  blueprints.add(Structure.generate_random_transformer_sametier(Item.ETier.Basic), 1)
  blueprints.add(Structure.generate_random_upgrader(Item.ETier.Basic, Item.ETier.Advanced), 1)
  blueprints.add(Structure.generate_random_upgrader(Item.ETier.Advanced, Item.ETier.Futuristic), 1)

  _process(0)

func tick(ticks: int) -> void:
  inventory.tick(ticks)
  for structure_instance in board:
    structure_instance.tick(ticks)
  
  turn_count += ticks
  # if turn_count % 5 == 0:
  #   create_reward()

func _process(delta: float) -> void:
  %MainInventory.text = inventory._to_string()
  %Blueprints.text = blueprints._to_string()

func _input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo:
    if event.keycode >= KEY_1 and event.keycode <= KEY_9:
      var index = event.keycode - KEY_1
      if index >= blueprints.dict.size():
        return
      var structure: Structure = blueprints.dict.keys()[index] as Structure
      print ("Placing %s" % structure.name)
      place(structure.duplicate())
    if event.keycode == KEY_B:
      var basic_resources = ItemLibrary.get_by_tier(Item.ETier.Basic)
      var res = basic_resources.pick_random()
      inventory.add(res, 10)
    if event.keycode == KEY_R:
      get_tree().reload_current_scene()
    if event.keycode == KEY_Z:
      create_reward()
    if event.keycode == KEY_SPACE:
      tick(1)

const STRUCTURE_INSTANCE = preload("res://structure_instance.tscn")
const PICKER_SCENE = preload("res://picker.tscn")

func place(structure: Structure) -> void:
  var instance := STRUCTURE_INSTANCE.instantiate()
  instance.type = structure
  %StructuresContainer.add_child(instance)
  board.append(instance)

func create_reward() -> void:
  reward_inventory.dict.clear()
  
  for i in range(3):
    var reward_type = randi() % 3
    var reward: Item
    if reward_type == 0:
      reward = Structure.generate_random_producer()
      reward_inventory.add(reward, 1)
    elif reward_type == 1:
      reward = Structure.generate_random_transformer_sametier(Item.ETier.Basic)
      reward_inventory.add(reward, 1)
    else:
      reward = ItemLibrary.get_by_tier(Item.ETier.Basic).pick_random()
      reward_inventory.add(reward, 10)
  
  var picker = PICKER_SCENE.instantiate()
  add_child(picker)
  picker.set_inventory(reward_inventory)
  picker.item_selected.connect(_on_reward_selected.bind(picker))

func _on_reward_selected(item: Item, amount: int, picker: Node) -> void:
  if item is Structure:
    blueprints.add(item, amount)
  else:
    inventory.add(item, amount)
  picker.queue_free()

static func dict_add_all(me: Dictionary, other: Dictionary) -> void:
  for key in other.keys():
    me[key] = me.get(key, 0) + other[key]

static func dict_trim_zero(me: Dictionary) -> void:
  var keys_to_remove: Array = []
  for key in me.keys():
    if me[key] == 0:
      keys_to_remove.append(key)
  for key in keys_to_remove:
    me.erase(key)

class Inventory:
  var name: String = "Inventory"
  var dict: Dictionary[Item, int] = {} # Resource and its amount
  var cap: int
  var prefix: bool = false

  func _init(_cap: int, _name: String = "Inventory") -> void:
    cap = _cap
    name = _name

  func _to_string() -> String:
    var out := name
    if cap > 1:
      out += " (cap %d)" % cap
    out += "\n"
    var index = 1
    for item in dict.keys():
      var line: String = "%d - " % index if prefix else ""
      index += 1
      if cap > 1:
        line += "x%d %s\n" % [dict[item], item.name]
      else:
        line += "%s\n" % item.name
      out += line
    return out
  
  func tick(ticks: int):
    var total_diff: Dictionary[Item, int] = {}
    for item: Item in dict.keys():
      var diff := item.tick(self, dict[item], ticks)
      World.dict_add_all(total_diff, diff)
    add_all(total_diff)

  func add(item: Item, amount: int) -> void:
    dict[item] = clamp(num(item) + amount, 0, cap)
    if dict[item] == 0:
      dict.erase(item)
  
  func add_all(other: Variant) -> void:
    var other_dict: Dictionary[Item, int]
    if other is Dictionary:
      other_dict = other
    if other is Inventory:
      other_dict = other.dict
    for item in other_dict.keys():
      add(item, other_dict[item])
  
  func num(item: Item) -> int:
    return dict.get(item, 0)
  
  func clear() -> void:
    dict.clear()
  
  func remove(item: Item, amount: int) -> void:
    add(item, -amount)

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
