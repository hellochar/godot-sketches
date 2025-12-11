extends VBoxContainer
class_name InventoryUI

@onready var title_label: Label = %Title
@onready var cards_container: GridContainer = %CardsContainer

const ITEM_CARD = preload("res://item_card.tscn")

var inventory: World.Inventory

func set_inventory(inv: World.Inventory) -> void:
  inventory = inv
  if title_label:
    title_label.text = inventory.name
  refresh()

func refresh() -> void:
  if not cards_container:
    return
  
  for child in cards_container.get_children():
    child.queue_free()
  
  if not inventory:
    return
  
  for item in inventory.dict.keys():
    var card = ITEM_CARD.instantiate()
    cards_container.add_child(card)
    card.set_item(item, inventory.dict[item])
