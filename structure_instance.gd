extends RichTextLabel
class_name StructureInstance

var type: Structure
# var inventory: World.Inventory = World.Inventory.new(5)
var production_timer: int = 0 # in ticks

var inventory: World.Inventory:
  get:
    return World.main.inventory

func render() -> void:
  text = "%s\n" % type.description
  # text += inventory.to_string()
  if !can_produce():
    text += "[color=red]Waiting for ingredients...[/color]\n"
  else:
    text += "[color=green]Producing...[/color] %d / %d\n" % [production_timer, type.production_time]

func _process(delta: float) -> void:
  render()

func tick(ticks: int) -> void:
  if can_produce():
    production_timer += ticks
    if production_timer >= type.production_time:
      produce()
      production_timer = 0
  # else:
  #   take(World.main.inventory)

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
