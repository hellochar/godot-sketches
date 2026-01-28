extends RichTextLabel
class_name StructureInstance

var type: Structure
var production_timer: int = 0
var workers_assigned: int = 0

var is_working: bool:
  get:
    return workers_assigned >= type.workers_needed

var inventory: World.Inventory:
  get:
    return World.main.inventory

func render() -> void:
  text = "%s " % type.description
  if !is_working:
    text += "[color=red]Need %d workers[/color]" % (type.workers_needed - workers_assigned)
  elif !can_produce():
    var missing: Array[String] = []
    for res in type.ingredients.keys():
      var have = inventory.dict.get(res, 0)
      var need = type.ingredients[res]
      if have < need:
        missing.append("%d %s" % [need - have, res.name])
    text += "[color=red]Need %s[/color]" % ", ".join(missing)
  else:
    text += "[color=green]Producing...[/color]"
    if type.production_time > 1:
      text += " %d / %d" % [production_timer, type.production_time]

func _process(_delta: float) -> void:
  render()

func tick(ticks: int) -> void:
  if is_working and can_produce():
    production_timer += ticks
    if production_timer >= type.production_time:
      produce()
      production_timer = 0

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
