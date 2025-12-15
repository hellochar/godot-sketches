extends VBoxContainer
class_name InventoryUI

@onready var title_label: Label = %Title
@onready var cards_container: FlowContainer = %CardsContainer

const ITEM_CARD = preload("res://item_card.tscn")

var inventory: World.Inventory
var needs_refresh: bool = false

@export var accept_drops: bool = true
@export var allow_drag: bool = true
var drop_filter: Callable

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
    card.source_inventory = inventory if allow_drag else null

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
  if not accept_drops or not inventory:
    return false
  if data is not Dictionary or not data.has("item"):
    return false
  if data.get("source") == inventory:
    return false
  if drop_filter.is_valid() and not drop_filter.call(data.get("item"), data.get("source")):
    return false
  return true

func _drop_data(_pos: Vector2, data: Variant) -> void:
  var item: Item = data.get("item")
  var amount: int = data.get("amount")
  var source: World.Inventory = data.get("source")
  inventory.take_from(source, item, amount)
