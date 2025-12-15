extends PanelContainer
class_name ItemCard

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %Name
@onready var tier_label: Label = %Tier
@onready var tags_label: Label = %Tags
@onready var description_label: Label = %Description
@onready var amount_label: Label = %Amount

var item: Item
var amount: int = 0

func set_item(new_item: Item, new_amount: int = 0) -> void:
  item = new_item
  amount = new_amount
  refresh()

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
