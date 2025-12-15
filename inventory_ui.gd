extends VBoxContainer
class_name InventoryUI

@onready var title_label: Label = %Title
@onready var cards_container: GridContainer = %CardsContainer

const ITEM_CARD = preload("res://item_card.tscn")

var inventory: World.Inventory

var needs_refresh: bool = false

func set_inventory(inv: World.Inventory) -> void:
  inventory = inv
  if title_label:
    title_label.text = inventory.name
  inv.on_changed.connect(func() -> void:
    needs_refresh = true
  )
  refresh()

func _process(_delta: float) -> void:
  if needs_refresh:
    refresh()

func refresh() -> void:
  needs_refresh = false
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
