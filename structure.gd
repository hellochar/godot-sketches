extends Item
class_name Structure

@export var ingredients: Dictionary[Item, int] = {}
@export var production: Dictionary[Item, int] = {}
@export var production_time: float = 0

static func generate_random_producer() -> Structure:
  var structure = Structure.new()
  var rand_basic: Item = ItemLibrary.get_by_tier(Item.ETier.Basic).pick_random()
  structure.production[rand_basic] = randi_range(3, 5)
  structure.production_time = randf_range(5, 10)
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
    structure.ingredients[res] = randi_range(1, 2)
    sum_ingredients += structure.ingredients[res]
  var rand_advanced: Item = ItemLibrary.get_by_tier(in_tier).pick_random()
  structure.production[rand_advanced] = sum_ingredients - 1
  structure.production_time = randf_range(10, 15)
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
    structure.ingredients[res] = randi_range(3, 5)
  var rand_futuristic: Item = ItemLibrary.get_by_tier(upgraded_tier).pick_random()
  structure.production[rand_futuristic] = 1
  structure.production_time = randf_range(15, 20)
  structure.description = structure.describe()
  structure.tier = base_tier
  structure.tags.push_back(Item.ETag.Structure)
  return structure

func describe() -> String:
  var out := ""
  if ingredients.size() > 0:
    out += "Transformer: "
    for res in ingredients.keys():
      out += "%s x%d, " % [res.name, ingredients[res]]
    out = out.substr(0, out.length() - 2)
    out += " -> "
  else:
    out += "Producer: "
  
  out += ", ".join(production.keys().map(func(r): return "%s x%d" % [r.name, production[r]]))
  return out
