extends Control

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")
const GameState = preload("res://jan_24_2026b-motivation-cards/game_state.gd")

@onready var day_label: Label = %DayLabel
@onready var score_label: Label = %ScoreLabel
@onready var willpower_label: Label = %WillpowerLabel

@onready var action_selection_screen: VBoxContainer = %ActionSelectionScreen
@onready var action_grid: GridContainer = %ActionGrid

@onready var motivation_phase_screen: VBoxContainer = %MotivationPhaseScreen
@onready var action_title: Label = %ActionTitle
@onready var cost_label: Label = %CostLabel
@onready var success_label: Label = %SuccessLabel
@onready var tags_container: HBoxContainer = %TagsContainer
@onready var drawn_cards_container: HBoxContainer = %DrawnCardsContainer
@onready var world_modifier_label: Label = %WorldModifierLabel
@onready var total_motivation_label: Label = %TotalMotivation
@onready var gap_label: Label = %GapLabel
@onready var willpower_slider: HSlider = %WillpowerSlider
@onready var willpower_spend_value: Label = %WillpowerSpendValue
@onready var back_button: Button = %BackButton
@onready var attempt_button: Button = %AttemptButton

@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_title: Label = %ResultTitle
@onready var result_details: Label = %ResultDetails
@onready var continue_button: Button = %ContinueButton

var game_state
var current_action
var drawn_cards: Array = []
var current_world_modifier
var total_motivation: int = 0


func _ready() -> void:
  game_state = GameState.new()
  _connect_signals()
  _show_action_selection()
  _update_top_bar()


func _connect_signals() -> void:
  back_button.pressed.connect(_on_back_pressed)
  attempt_button.pressed.connect(_on_attempt_pressed)
  continue_button.pressed.connect(_on_continue_pressed)
  willpower_slider.value_changed.connect(_on_willpower_slider_changed)


func _update_top_bar() -> void:
  day_label.text = "Day %d" % game_state.current_day
  score_label.text = "Score: %d" % game_state.score
  willpower_label.text = "Willpower: %d/%d" % [game_state.willpower, game_state.willpower_max]


func _show_action_selection() -> void:
  action_selection_screen.visible = true
  motivation_phase_screen.visible = false
  result_panel.visible = false
  _populate_action_grid()


func _populate_action_grid() -> void:
  for child in action_grid.get_children():
    child.queue_free()

  for action in game_state.available_actions:
    var btn := _create_action_button(action)
    action_grid.add_child(btn)


func _create_action_button(action) -> Button:
  var btn := Button.new()
  btn.custom_minimum_size = Vector2(200, 120)

  var style := StyleBoxFlat.new()
  style.bg_color = Color(0.2, 0.25, 0.3)
  style.corner_radius_top_left = 8
  style.corner_radius_top_right = 8
  style.corner_radius_bottom_left = 8
  style.corner_radius_bottom_right = 8
  style.content_margin_left = 10
  style.content_margin_right = 10
  style.content_margin_top = 10
  style.content_margin_bottom = 10
  btn.add_theme_stylebox_override("normal", style)

  var hover_style := style.duplicate()
  hover_style.bg_color = Color(0.25, 0.3, 0.35)
  btn.add_theme_stylebox_override("hover", hover_style)

  var tags_str := _format_tags(action.tags)
  btn.text = "%s\nCost: %d | %d%%\n%s" % [action.title, action.motivation_cost, int(action.success_chance * 100), tags_str]
  btn.pressed.connect(func() -> void: _select_action(action))
  return btn


func _format_tags(tags: Array) -> String:
  var parts: Array = []
  for tag in tags:
    parts.append(CardData.TAG_NAMES[tag])
  return ", ".join(parts)


func _select_action(action) -> void:
  current_action = action
  _show_motivation_phase()


func _show_motivation_phase() -> void:
  action_selection_screen.visible = false
  motivation_phase_screen.visible = true
  result_panel.visible = false

  action_title.text = current_action.title
  cost_label.text = "Cost: %d" % current_action.motivation_cost
  success_label.text = "Success: %d%%" % int(current_action.success_chance * 100)

  _populate_tags()
  _draw_motivation_cards()
  _apply_world_modifier()
  _calculate_motivation()
  _update_willpower_slider()


func _populate_tags() -> void:
  for child in tags_container.get_children():
    child.queue_free()

  for tag in current_action.tags:
    var tag_label := Label.new()
    tag_label.text = CardData.TAG_NAMES[tag]

    var style := StyleBoxFlat.new()
    style.bg_color = CardData.TAG_COLORS[tag]
    style.corner_radius_top_left = 4
    style.corner_radius_top_right = 4
    style.corner_radius_bottom_left = 4
    style.corner_radius_bottom_right = 4
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 4
    style.content_margin_bottom = 4

    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", style)
    panel.add_child(tag_label)
    tags_container.add_child(panel)


func _draw_motivation_cards() -> void:
  drawn_cards = game_state.draw_motivation_cards(5)

  for child in drawn_cards_container.get_children():
    child.queue_free()

  for card in drawn_cards:
    var card_panel := _create_motivation_card_display(card)
    drawn_cards_container.add_child(card_panel)


func _create_motivation_card_display(card) -> PanelContainer:
  var panel := PanelContainer.new()
  panel.custom_minimum_size = Vector2(140, 100)

  var motivation_value: int = card.get_motivation_for_tags(current_action.tags)
  var bg_color := Color(0.3, 0.3, 0.35)
  if motivation_value > 0:
    bg_color = Color(0.2, 0.4, 0.25)
  elif motivation_value < 0:
    bg_color = Color(0.4, 0.2, 0.2)

  var style := StyleBoxFlat.new()
  style.bg_color = bg_color
  style.corner_radius_top_left = 6
  style.corner_radius_top_right = 6
  style.corner_radius_bottom_left = 6
  style.corner_radius_bottom_right = 6
  style.content_margin_left = 8
  style.content_margin_right = 8
  style.content_margin_top = 8
  style.content_margin_bottom = 8
  panel.add_theme_stylebox_override("panel", style)

  var vbox := VBoxContainer.new()
  vbox.add_theme_constant_override("separation", 4)

  var title_label := Label.new()
  title_label.text = card.title
  title_label.add_theme_font_size_override("font_size", 14)
  title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
  vbox.add_child(title_label)

  var mod_label := Label.new()
  mod_label.text = card.format_modifiers()
  mod_label.add_theme_font_size_override("font_size", 12)
  vbox.add_child(mod_label)

  if motivation_value != 0:
    var contrib_label := Label.new()
    var sign_str := "+" if motivation_value > 0 else ""
    contrib_label.text = "→ %s%d" % [sign_str, motivation_value]
    contrib_label.add_theme_font_size_override("font_size", 16)
    if motivation_value > 0:
      contrib_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
    else:
      contrib_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
    vbox.add_child(contrib_label)

  panel.add_child(vbox)
  return panel


func _apply_world_modifier() -> void:
  if randf() < 0.5:
    current_world_modifier = game_state.get_random_world_modifier()
    if current_world_modifier:
      var mod_value: int = current_world_modifier.get_motivation_for_tags(current_action.tags)
      if mod_value != 0:
        var sign_str := "+" if mod_value > 0 else ""
        world_modifier_label.text = "World: %s (%s%d)" % [current_world_modifier.title, sign_str, mod_value]
      else:
        world_modifier_label.text = "World: %s (no effect)" % current_world_modifier.title
    else:
      world_modifier_label.text = ""
  else:
    current_world_modifier = null
    world_modifier_label.text = ""


func _calculate_motivation() -> void:
  total_motivation = 0
  for card in drawn_cards:
    total_motivation += card.get_motivation_for_tags(current_action.tags)

  if current_world_modifier:
    total_motivation += current_world_modifier.get_motivation_for_tags(current_action.tags)

  total_motivation_label.text = "Total Motivation: %d / %d" % [total_motivation, current_action.motivation_cost]

  var gap := maxi(0, current_action.motivation_cost - total_motivation)
  gap_label.text = "Gap: %d" % gap


func _update_willpower_slider() -> void:
  var gap := maxi(0, current_action.motivation_cost - total_motivation)
  willpower_slider.min_value = 0
  willpower_slider.max_value = mini(game_state.willpower, gap + 20)
  willpower_slider.value = mini(gap, game_state.willpower)
  _on_willpower_slider_changed(willpower_slider.value)


func _on_willpower_slider_changed(value: float) -> void:
  willpower_spend_value.text = str(int(value))
  var effective_motivation := total_motivation + int(value)
  var can_attempt: bool = effective_motivation >= current_action.motivation_cost
  attempt_button.disabled = not can_attempt
  if can_attempt:
    attempt_button.text = "Attempt Action"
  else:
    attempt_button.text = "Need %d more" % (current_action.motivation_cost - effective_motivation)


func _on_back_pressed() -> void:
  _show_action_selection()


func _on_attempt_pressed() -> void:
  var willpower_spent := int(willpower_slider.value)
  game_state.spend_willpower(willpower_spent)

  var success: bool = randf() < current_action.success_chance
  _show_result(success)


func _show_result(success: bool) -> void:
  motivation_phase_screen.visible = false
  result_panel.visible = true

  var score_gained := 0
  if success:
    for value_card in game_state.value_cards:
      score_gained += value_card.get_score_for_tags(current_action.tags)
    game_state.add_score(score_gained)

    result_title.text = "Success!"
    result_title.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
    if score_gained > 0:
      result_details.text = "You gained %d points!\nThis aligns with your values." % score_gained
    else:
      result_details.text = "Action completed, but it didn't align with your values."
  else:
    result_title.text = "Failed..."
    result_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
    result_details.text = "The action didn't succeed this time.\nBetter luck next time."

  _update_top_bar()


func _on_continue_pressed() -> void:
  _show_action_selection()
