extends Item
class_name Livestock

const FOOD = preload("res://dec-7-2025/items/basic/food.tres")
# if out of food, kill one of itself to make 5 food
func tick(inventory: World.Inventory, _livestock: int, _ticks: int) -> Dictionary[Item, int]:
  var changes: Dictionary[Item, int] = {}
  if inventory.num(FOOD) == 0:
    changes[self as Item] = -1
    changes[FOOD] = 5
    print ("Slaughtered 1 livestock for 5 food")
  return changes