extends Item
class_name Grass

const FOOD = preload("res://dec-7-2025-citybuilder-cards-only/items/basic/food.tres")
func tick(_inventory: World.Inventory, grass: int, ticks: int) -> Dictionary[Item, int]:
  # every 10 grass produces one grass
  var changes: Dictionary[Item, int] = {}
  var food_produced = 0 # int((grass * ticks) / 10.0)
  var grass_produced = int((grass * ticks) / 10.0)
  if food_produced > 0:
    changes[FOOD] = food_produced
  if grass_produced > 0:
    changes[self as Item] = grass_produced
  # print ("%d Grass produced %d food and grass" % [grass, food_produced])
  return changes