class_name DefaultTooltipContent
extends PanelContainer

@export var title: String = "":
  set(v):
    title = v
    if is_node_ready():
      %TitleLabel.text = v

@export var description: String = "":
  set(v):
    description = v
    if is_node_ready():
      %DescLabel.text = v
      %DescLabel.visible = v != ""


func _ready() -> void:
  %TitleLabel.text = title
  %DescLabel.text = description
  %DescLabel.visible = description != ""
