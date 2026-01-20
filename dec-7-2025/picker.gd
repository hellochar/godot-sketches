extends Control
class_name Picker

signal item_selected(item: Item, amount: int)

var inventory: World.Inventory
var skippable: bool = true
@onready var container: BoxContainer = %Container
@onready var skip_button: Button = %SkipButton

func set_inventory(inv: World.Inventory, _skippable: bool = true) -> void:
  inventory = inv
  self.skippable = _skippable
  refresh()

func refresh() -> void:
  for child in container.get_children():
    child.queue_free()
  
  if not inventory:
    return
  
  for item in inventory.dict.keys():
    var button = Button.new()
    button.custom_minimum_size = Vector2(150, 40)
    var amount = inventory.dict[item]
    if amount <= 1:
      button.text = item.name + " " + item.description
    else:
      button.text = "%s (x%d)" % [item.name + " " + item.description, amount]
    button.pressed.connect(func(): _on_item_clicked(item, amount))
    container.add_child(button)
  
  if skippable:
    skip_button.pressed.connect(func(): _on_item_clicked(null, 0))
    skip_button.show()
  else:
    skip_button.hide()

func _on_item_clicked(item: Item, amount: int) -> void:
  item_selected.emit(item, amount)
