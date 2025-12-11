extends Item
class_name Grass

const FOOD = preload("res://items/basic/food.tres")
func tick(inventory: World.Inventory, grass: int, ticks: int) -> Dictionary[Item, int]:
  # every 5 grass produces one food
  # every 5 grass produces one grass
  var changes: Dictionary[Item, int] = {}
  var food_produced = int((grass * ticks) / 5.0)
  var grass_produced = int((grass * ticks) / 5.0)
  if food_produced > 0:
    changes[FOOD] = food_produced
    print ("%d Grass produced %d food and grass" % [grass, food_produced])
  if grass_produced > 0:
    changes[self as Item] = grass_produced
  return changes