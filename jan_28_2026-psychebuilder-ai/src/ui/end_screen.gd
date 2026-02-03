extends Control

signal play_again_pressed()
signal main_menu_pressed()

@export_group("Layout")
@export var panel_width: float = 450.0
@export var panel_margin: int = 30
@export var spacing: int = 16

@export_group("Fonts")
@export var title_font_size: int = 32
@export var tier_font_size: int = 40
@export var description_font_size: int = 14
@export var stats_font_size: int = 13
@export var wellbeing_font_size: int = 24

@export_group("Colors")
@export var overlay_color: Color = Color(0, 0, 0, 0.8)
@export var flourishing_color: Color = Color(0.2, 0.9, 0.4)
@export var growing_color: Color = Color(0.5, 0.8, 0.3)
@export var surviving_color: Color = Color(0.9, 0.7, 0.2)
@export var struggling_color: Color = Color(0.9, 0.3, 0.3)

var game_flow_manager: Node
var game_state: Node

func setup(p_game_flow_manager: Node, p_game_state: Node) -> void:
  game_flow_manager = p_game_flow_manager
  game_state = p_game_state

func show_ending(ending_tier: String, final_wellbeing: float, stats: Dictionary) -> void:
  visible = true
  _build_ui(ending_tier, final_wellbeing, stats)

func _build_ui(ending_tier: String, final_wellbeing: float, stats: Dictionary) -> void:
  for child in get_children():
    child.queue_free()

  var overlay = ColorRect.new()
  overlay.color = overlay_color
  overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
  overlay.mouse_filter = Control.MOUSE_FILTER_STOP
  add_child(overlay)

  var center = CenterContainer.new()
  center.set_anchors_preset(Control.PRESET_FULL_RECT)
  overlay.add_child(center)

  var panel = PanelContainer.new()
  panel.custom_minimum_size.x = panel_width
  center.add_child(panel)

  var margin = MarginContainer.new()
  margin.add_theme_constant_override("margin_left", panel_margin)
  margin.add_theme_constant_override("margin_right", panel_margin)
  margin.add_theme_constant_override("margin_top", panel_margin)
  margin.add_theme_constant_override("margin_bottom", panel_margin)
  panel.add_child(margin)

  var vbox = VBoxContainer.new()
  vbox.add_theme_constant_override("separation", spacing)
  margin.add_child(vbox)

  var title = Label.new()
  title.text = "Game Complete"
  title.add_theme_font_size_override("font_size", title_font_size)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(title)

  var tier_label = Label.new()
  tier_label.text = game_flow_manager.get_ending_title(ending_tier)
  tier_label.add_theme_font_size_override("font_size", tier_font_size)
  tier_label.add_theme_color_override("font_color", _get_tier_color(ending_tier))
  tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(tier_label)

  var sep1 = HSeparator.new()
  vbox.add_child(sep1)

  var desc = Label.new()
  desc.text = game_flow_manager.get_ending_text(ending_tier)
  desc.add_theme_font_size_override("font_size", description_font_size)
  desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(desc)

  var sep2 = HSeparator.new()
  vbox.add_child(sep2)

  var wellbeing_label = Label.new()
  wellbeing_label.text = "Final Wellbeing: %d" % int(final_wellbeing)
  wellbeing_label.add_theme_font_size_override("font_size", wellbeing_font_size)
  wellbeing_label.add_theme_color_override("font_color", _get_wellbeing_color(final_wellbeing))
  wellbeing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(wellbeing_label)

  var stats_label = Label.new()
  stats_label.text = _format_stats(stats)
  stats_label.add_theme_font_size_override("font_size", stats_font_size)
  stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  vbox.add_child(stats_label)

  var tips = _generate_tips(stats, final_wellbeing)
  if tips.size() > 0:
    var tips_sep = HSeparator.new()
    vbox.add_child(tips_sep)

    var tips_header = Label.new()
    tips_header.text = "Tips for Next Run:"
    tips_header.add_theme_font_size_override("font_size", 14)
    tips_header.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9))
    tips_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(tips_header)

    var tips_label = Label.new()
    var tip_lines: Array[String] = []
    for tip in tips.slice(0, 3):
      tip_lines.append("• " + tip)
    tips_label.text = "\n".join(tip_lines)
    tips_label.add_theme_font_size_override("font_size", 12)
    tips_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tips_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    vbox.add_child(tips_label)

  var sep3 = HSeparator.new()
  vbox.add_child(sep3)

  var button_box = HBoxContainer.new()
  button_box.add_theme_constant_override("separation", 20)
  button_box.alignment = BoxContainer.ALIGNMENT_CENTER
  vbox.add_child(button_box)

  var play_again_btn = Button.new()
  play_again_btn.text = "Play Again"
  play_again_btn.custom_minimum_size = Vector2(120, 40)
  play_again_btn.pressed.connect(_on_play_again)
  button_box.add_child(play_again_btn)

  var main_menu_btn = Button.new()
  main_menu_btn.text = "Main Menu"
  main_menu_btn.custom_minimum_size = Vector2(120, 40)
  main_menu_btn.pressed.connect(_on_main_menu)
  button_box.add_child(main_menu_btn)

func _get_tier_color(tier: String) -> Color:
  match tier:
    "flourishing":
      return flourishing_color
    "growing":
      return growing_color
    "surviving":
      return surviving_color
    "struggling":
      return struggling_color
  return Color.WHITE

func _get_wellbeing_color(value: float) -> Color:
  if value >= 80:
    return flourishing_color
  elif value >= 50:
    return growing_color
  elif value >= 20:
    return surviving_color
  else:
    return struggling_color

func _format_stats(stats: Dictionary) -> String:
  var lines: Array[String] = []
  lines.append("Days Completed: %d" % stats.get("days", 0))
  lines.append("Buildings: %d" % stats.get("buildings", 0))
  lines.append("Workers: %d" % stats.get("workers", 0))
  lines.append("Positive Resources: %d" % stats.get("positive_resources", 0))
  lines.append("Negative Resources: %d" % stats.get("negative_resources", 0))

  var beliefs = stats.get("beliefs", [])
  if beliefs.size() > 0:
    lines.append("")
    lines.append("Beliefs Unlocked: %d" % beliefs.size())

  return "\n".join(lines)

func _generate_tips(stats: Dictionary, final_wellbeing: float) -> Array[String]:
  var tips: Array[String] = []

  var negative = stats.get("negative_resources", 0)
  var positive = stats.get("positive_resources", 0)
  var buildings = stats.get("buildings", 0)
  var workers = stats.get("workers", 0)

  if negative > positive * 2:
    tips.append("Build more Processors (like Mourning Chapel or Anxiety Diffuser) to convert negative emotions")
  if workers < 3:
    tips.append("More workers help transport resources faster between buildings")
  if buildings < 6:
    tips.append("Try placing more buildings to increase your emotional toolkit")
  if final_wellbeing < 40:
    tips.append("Focus on processing grief and anxiety early - they drag down wellbeing")
  if positive < 5:
    tips.append("Generators like Comfort Hearth produce positive resources passively")

  return tips

func _on_play_again() -> void:
  play_again_pressed.emit()

func _on_main_menu() -> void:
  main_menu_pressed.emit()
