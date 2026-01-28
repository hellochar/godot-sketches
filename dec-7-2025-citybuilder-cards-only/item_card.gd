extends PanelContainer
class_name ItemCard

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %Name
@onready var tier_label: Label = %Tier
@onready var tags_label: Label = %Tags
@onready var description_label: Label = %Description
@onready var amount_label: Label = %Amount
@onready var use_button: Button = %UseButton
@onready var pickup_button: Button = %PickupButton

var item: Item
var amount: int = 0
var source_inventory: World.Inventory
var pickup_target: World.Inventory

func _get_drag_data(_pos: Vector2) -> Variant:
  if not item or not source_inventory:
    return null
  var preview = duplicate(0)
  preview.modulate.a = 0.7
  set_drag_preview(preview)
  return {"item": item, "amount": amount, "source": source_inventory}

func _ready() -> void:
  use_button.pressed.connect(_on_use_pressed)
  pickup_button.pressed.connect(_on_pickup_pressed)

func set_item(new_item: Item, new_amount: int = 0) -> void:
  item = new_item
  amount = new_amount
  refresh()

func _on_use_pressed() -> void:
  if item and item.usable:
    item.use(source_inventory, amount)

func _on_pickup_pressed() -> void:
  if item and source_inventory and pickup_target:
    pickup_target.take_from(source_inventory, item, amount)

func _process(delta: float) -> void:
  refresh()

func refresh() -> void:
  if not item:
    return
  
  name_label.text = item.name + ("" if amount <= 1 else " x%d" % amount)
  
  var tier_text = ""
  match item.tier:
    Item.ETier.Basic:
      tier_text = "Basic"
    Item.ETier.Advanced:
      tier_text = "Advanced"
    Item.ETier.Futuristic:
      tier_text = "Futuristic"
  tier_label.text = tier_text
  
  var tags_text = ""
  for tag in item.tags:
    match tag:
      Item.ETag.Structure:
        tags_text += "Structure "
  tags_label.text = tags_text.strip_edges()
  
  description_label.text = item.description
  
  # if amount > 1:
  #   amount_label.text = "x%d" % amount
  #   amount_label.show()
  # else:
  amount_label.hide()
  
  if item.icon:
    icon_rect.texture = item.icon
    icon_rect.show()
  else:
    icon_rect.hide()

  use_button.visible = item.usable
  pickup_button.visible = pickup_target != null and item.pickupable
