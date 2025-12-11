extends Item
class_name Structure

@export var ingredients: Dictionary[Item, int] = {}
@export var production: Dictionary[Item, int] = {}
@export var production_time: int = 0
@export var workers_needed: int = 1

static func generate_random_producer() -> Structure:
  var structure = Structure.new()
  var rand_basic: Item = ItemLibrary.get_by_tier(Item.ETier.Basic).pick_random()
  structure.production[rand_basic] = 1 # randi_range(1, 3)
  structure.production_time = 1 # randi_range(1, 3)
  structure.workers_needed = 1
  structure.autoset_name_override()
  structure.description = structure.describe()
  structure.tier = Item.ETier.Basic
  structure.tags.push_back(Item.ETag.Structure)
  return structure

static func generate_random_transformer_sametier(in_tier: Item.ETier) -> Structure:
  var structure = Structure.new()
  var inputs = ItemLibrary.get_by_tier(in_tier)
  inputs.shuffle()
  var rand_basic_inputs: Array[Item] = inputs.slice(0, 2)
  var sum_ingredients = 0
  for res in rand_basic_inputs:
    structure.ingredients[res] = 1 # randi_range(1, 2)
    sum_ingredients += structure.ingredients[res]
  var rand_advanced: Item = ItemLibrary.get_by_tier(in_tier).pick_random()
  structure.production[rand_advanced] = 1
  structure.production_time = 1 # randi_range(2, 4)
  structure.workers_needed = 2 # randi_range(1, 2)
  structure.autoset_name_override()
  structure.description = structure.describe()
  structure.tier = in_tier
  structure.tags.push_back(Item.ETag.Structure)
  return structure

static func generate_random_upgrader(base_tier: Item.ETier, upgraded_tier: Item.ETier) -> Structure:
  var structure = Structure.new()
  var inputs = ItemLibrary.get_by_tier(base_tier)
  inputs.shuffle()
  var rand_advanced_inputs: Array[Item] = inputs.slice(0, 2)
  for res in rand_advanced_inputs:
    structure.ingredients[res] = 2 # randi_range(3, 5)
  var rand_futuristic: Item = ItemLibrary.get_by_tier(upgraded_tier).pick_random()
  structure.production[rand_futuristic] = 1
  structure.production_time = 1 # randi_range(7, 10)
  structure.workers_needed = 5 # randi_range(2, 3)
  structure.autoset_name_override()
  structure.description = structure.describe()
  structure.tier = base_tier
  structure.tags.push_back(Item.ETag.Structure)
  return structure

func autoset_name_override() -> void:
  if ingredients.size() > 0:
    name_override = "Transformer"
  else:
    name_override = "Producer"

func describe() -> String:
  var out := ""
  if ingredients.size() > 0:
    out += "Converts "
    for res in ingredients.keys():
      out += "%d %s, " % [ingredients[res], res.name]
    out = out.substr(0, out.length() - 2)
    out += " into "
  else:
    out += "+"
  
  out += ", ".join(production.keys().map(func(r): return "%d %s" % [production[r], r.name]))
  if production_time > 1:
    out += " every %d turns" % production_time
  if workers_needed > 1:
    out += " (needs %d workers)" % workers_needed
  return out
