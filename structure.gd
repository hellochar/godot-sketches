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
  
  out += ", ".join(production.keys().map(func(r): return r.name))
  return out
