extends RichTextLabel
class_name StructureInstance

var type: Structure
var inventory: World.Inventory = World.Inventory.new(5)
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
  else:
    take(World.main.inventory)
  render()

func take(source: World.Inventory) -> void:
  for res in type.ingredients.keys():
    var needed = type.ingredients[res] - inventory.dict.get(res, 0)
    if needed > 0:
      var available = source.dict.get(res, 0)
      var to_transfer = min(needed, available)
      if to_transfer > 0:
        source.remove(res, to_transfer)
        inventory.add(res, to_transfer)

func can_produce() -> bool:
  for res in type.ingredients.keys():
    if inventory.dict.get(res, 0) < type.ingredients[res]:
      return false
  return true

func produce() -> void:
  for res in type.ingredients.keys():
    inventory.remove(res, type.ingredients[res])
  for res in type.production.keys():
    World.main.inventory.add(res, type.production[res])
