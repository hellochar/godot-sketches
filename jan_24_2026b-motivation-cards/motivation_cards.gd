extends Control

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")
const GameState = preload("res://jan_24_2026b-motivation-cards/game_state.gd")
const StarterDeckResourceScript = preload("res://jan_24_2026b-motivation-cards/starter_deck_resource.gd")

@export_group("Game Settings")
@export var cards_per_draw: int = 5
@export_range(0.0, 1.0) var world_modifier_chance: float = 0.5
@export var starting_willpower: int = 100

@export_group("Card Visuals")
@export var action_button_size: Vector2 = Vector2(200, 120)
@export var motivation_card_size: Vector2 = Vector2(140, 100)
@export var card_corner_radius: int = 8
@export var tag_corner_radius: int = 4
@export var card_margin: int = 10
@export var tag_margin_h: int = 8
@export var tag_margin_v: int = 4

@export_group("Colors")
@export var neutral_card_color: Color = Color(0.3, 0.3, 0.35)
@export var positive_card_color: Color = Color(0.2, 0.4, 0.25)
@export var negative_card_color: Color = Color(0.4, 0.2, 0.2)
@export var success_color: Color = Color(0.5, 1.0, 0.5)
@export var failure_color: Color = Color(1.0, 0.5, 0.5)
@export var button_normal_color: Color = Color(0.2, 0.25, 0.3)
@export var button_hover_color: Color = Color(0.25, 0.3, 0.35)

@export_group("Data")
@export var starter_deck: Resource

@onready var day_label: Label = %DayLabel
@onready var score_label: Label = %ScoreLabel
@onready var willpower_label: Label = %WillpowerLabel

@onready var action_selection_screen: VBoxContainer = %ActionSelectionScreen
@onready var action_grid: GridContainer = %ActionGrid
@onready var mood_cards_container: HBoxContainer = %MoodCardsContainer
@onready var mood_world_label: Label = %MoodWorldLabel

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
  if starter_deck:
    game_state.load_from_deck(starter_deck)
  game_state.willpower = starting_willpower
  game_state.willpower_max = starting_willpower
  _connect_signals()
  _start_new_turn()
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
  _display_mood_cards()
  _display_mood_world_modifier()


func _populate_action_grid() -> void:
  for child in action_grid.get_children():
    child.queue_free()

  for action in game_state.available_actions:
    var btn := _create_action_button(action)
    action_grid.add_child(btn)


func _create_action_button(action) -> Button:
  var btn := Button.new()
  btn.custom_minimum_size = action_button_size

  var style := StyleBoxFlat.new()
  style.bg_color = button_normal_color
  style.corner_radius_top_left = card_corner_radius
  style.corner_radius_top_right = card_corner_radius
  style.corner_radius_bottom_left = card_corner_radius
  style.corner_radius_bottom_right = card_corner_radius
  style.content_margin_left = card_margin
  style.content_margin_right = card_margin
  style.content_margin_top = card_margin
  style.content_margin_bottom = card_margin
  btn.add_theme_stylebox_override("normal", style)

  var hover_style := style.duplicate()
  hover_style.bg_color = button_hover_color
  btn.add_theme_stylebox_override("hover", hover_style)

  var tags_str := _format_tags(action.tags)
  if action.success_chance >= 1.0:
    btn.text = "%s\nCost: %d\n%s" % [action.title, action.motivation_cost, tags_str]
  else:
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
  if current_action.success_chance >= 1.0:
    success_label.text = ""
  else:
    success_label.text = "Success: %d%%" % int(current_action.success_chance * 100)

  _populate_tags()
  _display_drawn_cards()
  _display_world_modifier()
  _calculate_motivation()
  _update_willpower_slider()


func _start_new_turn() -> void:
  drawn_cards = game_state.draw_motivation_cards(cards_per_draw)
  if randf() < world_modifier_chance:
    current_world_modifier = game_state.get_random_world_modifier()
  else:
    current_world_modifier = null
  _show_action_selection()


func _display_mood_cards() -> void:
  for child in mood_cards_container.get_children():
    child.queue_free()

  for card in drawn_cards:
    var card_panel := _create_mood_card_display(card)
    mood_cards_container.add_child(card_panel)


func _create_mood_card_display(card) -> PanelContainer:
  var panel := PanelContainer.new()
  panel.custom_minimum_size = motivation_card_size

  var style := StyleBoxFlat.new()
  style.bg_color = neutral_card_color
  style.corner_radius_top_left = card_corner_radius
  style.corner_radius_top_right = card_corner_radius
  style.corner_radius_bottom_left = card_corner_radius
  style.corner_radius_bottom_right = card_corner_radius
  style.content_margin_left = card_margin
  style.content_margin_right = card_margin
  style.content_margin_top = card_margin
  style.content_margin_bottom = card_margin
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

  panel.add_child(vbox)
  return panel


func _display_mood_world_modifier() -> void:
  if current_world_modifier:
    mood_world_label.text = "World: %s" % current_world_modifier.title
  else:
    mood_world_label.text = ""


func _populate_tags() -> void:
  for child in tags_container.get_children():
    child.queue_free()

  for tag in current_action.tags:
    var tag_label := Label.new()
    tag_label.text = CardData.TAG_NAMES[tag]

    var style := StyleBoxFlat.new()
    style.bg_color = CardData.TAG_COLORS[tag]
    style.corner_radius_top_left = tag_corner_radius
    style.corner_radius_top_right = tag_corner_radius
    style.corner_radius_bottom_left = tag_corner_radius
    style.corner_radius_bottom_right = tag_corner_radius
    style.content_margin_left = tag_margin_h
    style.content_margin_right = tag_margin_h
    style.content_margin_top = tag_margin_v
    style.content_margin_bottom = tag_margin_v

    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", style)
    panel.add_child(tag_label)
    tags_container.add_child(panel)


func _display_drawn_cards() -> void:
  for child in drawn_cards_container.get_children():
    child.queue_free()

  for card in drawn_cards:
    var card_panel := _create_motivation_card_display(card)
    drawn_cards_container.add_child(card_panel)


func _create_motivation_card_display(card) -> PanelContainer:
  var panel := PanelContainer.new()
  panel.custom_minimum_size = motivation_card_size

  var motivation_value: int = card.get_motivation_for_tags(current_action.tags)
  var bg_color := neutral_card_color
  if motivation_value > 0:
    bg_color = positive_card_color
  elif motivation_value < 0:
    bg_color = negative_card_color

  var style := StyleBoxFlat.new()
  style.bg_color = bg_color
  style.corner_radius_top_left = card_corner_radius
  style.corner_radius_top_right = card_corner_radius
  style.corner_radius_bottom_left = card_corner_radius
  style.corner_radius_bottom_right = card_corner_radius
  style.content_margin_left = card_margin
  style.content_margin_right = card_margin
  style.content_margin_top = card_margin
  style.content_margin_bottom = card_margin
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
      contrib_label.add_theme_color_override("font_color", success_color)
    else:
      contrib_label.add_theme_color_override("font_color", failure_color)
    vbox.add_child(contrib_label)

  panel.add_child(vbox)
  return panel


func _display_world_modifier() -> void:
  if current_world_modifier:
    var mod_value: int = current_world_modifier.get_motivation_for_tags(current_action.tags)
    if mod_value != 0:
      var sign_str := "+" if mod_value > 0 else ""
      world_modifier_label.text = "World: %s (%s%d)" % [current_world_modifier.title, sign_str, mod_value]
    else:
      world_modifier_label.text = "World: %s (no effect)" % current_world_modifier.title
  else:
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
    result_title.add_theme_color_override("font_color", success_color)
    if score_gained > 0:
      result_details.text = "You gained %d points!\nThis aligns with your values." % score_gained
    else:
      result_details.text = "Action completed, but it didn't align with your values."
  else:
    result_title.text = "Failed..."
    result_title.add_theme_color_override("font_color", failure_color)
    result_details.text = "The action didn't succeed this time.\nBetter luck next time."

  _update_top_bar()


func _on_continue_pressed() -> void:
  _start_new_turn()
