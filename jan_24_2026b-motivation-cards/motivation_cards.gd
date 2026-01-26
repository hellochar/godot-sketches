extends Control

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")
const GameState = preload("res://jan_24_2026b-motivation-cards/game_state.gd")
const StarterDeckResourceScript = preload("res://jan_24_2026b-motivation-cards/starter_deck_resource.gd")

@export_group("Game Settings")
@export var cards_per_draw: int = 5
@export_range(0.0, 1.0) var world_modifier_chance: float = 0.5
@export var starting_willpower: int = 100
@export var max_days: int = 7
@export var card_reveal_delay: float = 0.15
@export var willpower_burnout_threshold: int = 50

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

@export_group("Audio")
@export var card_reveal_sound: AudioStream
@export var attempt_sound: AudioStream
@export var success_sound: AudioStream
@export var failure_sound: AudioStream

@onready var day_label: Label = %DayLabel
@onready var score_label: Label = %ScoreLabel
@onready var willpower_bar: ProgressBar = %WillpowerBar
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
@onready var willpower_cost_label: Label = %WillpowerCostLabel
@onready var back_button: Button = %BackButton
@onready var attempt_button: Button = %AttemptButton

@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_title: Label = %ResultTitle
@onready var result_details: Label = %ResultDetails
@onready var continue_button: Button = %ContinueButton

@onready var end_game_panel: PanelContainer = %EndGamePanel
@onready var end_title: Label = %EndTitle
@onready var final_score_label: Label = %FinalScore
@onready var actions_summary: Label = %ActionsSummary
@onready var play_again_button: Button = %PlayAgainButton
@onready var audio_player: AudioStreamPlayer = %AudioPlayer

var game_state
var current_action
var drawn_cards: Array = []
var current_world_modifier
var total_motivation: int = 0
var actions_taken: Array = []
var willpower_spent_today: int = 0


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
  play_again_button.pressed.connect(_on_play_again_pressed)


func _play_sound(sound: AudioStream) -> void:
  if sound and audio_player:
    audio_player.stream = sound
    audio_player.play()


func _update_top_bar() -> void:
  day_label.text = "Day %d of %d" % [game_state.current_day, max_days]
  score_label.text = "Score: %d" % game_state.score
  willpower_bar.max_value = game_state.willpower_max
  willpower_bar.value = game_state.willpower
  willpower_label.text = "%d/%d" % [game_state.willpower, game_state.willpower_max]


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

  var sorted_actions: Array = game_state.available_actions.duplicate()
  sorted_actions.sort_custom(func(a, b) -> bool:
    var a_wp := maxi(0, a.motivation_cost - _get_motivation_for_action(a))
    var b_wp := maxi(0, b.motivation_cost - _get_motivation_for_action(b))
    return a_wp < b_wp
  )

  for action in sorted_actions:
    var btn := _create_action_button(action)
    action_grid.add_child(btn)


func _create_action_button(action) -> Button:
  var btn := Button.new()
  btn.custom_minimum_size = action_button_size

  var motivation := _get_motivation_for_action(action)
  var willpower_needed := maxi(0, action.motivation_cost - motivation)

  var bg_color := button_normal_color
  if willpower_needed == 0:
    bg_color = positive_card_color
  elif willpower_needed > game_state.willpower:
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
  btn.add_theme_stylebox_override("normal", style)

  var hover_style := style.duplicate()
  hover_style.bg_color = bg_color.lightened(0.1)
  btn.add_theme_stylebox_override("hover", hover_style)

  var tags_str := _format_tags(action.tags)
  var willpower_str := "Willpower: %d" % willpower_needed if willpower_needed > 0 else "No willpower needed"
  if action.success_chance >= 1.0:
    btn.text = "%s\n%s\n%s" % [action.title, willpower_str, tags_str]
  else:
    btn.text = "%s\n%s | %d%%\n%s" % [action.title, willpower_str, int(action.success_chance * 100), tags_str]
  btn.pressed.connect(func() -> void: _select_action(action))
  return btn


func _get_motivation_for_action(action) -> int:
  var motivation := 0
  for card in drawn_cards:
    motivation += card.get_motivation_for_tags(action.tags)
  if current_world_modifier:
    motivation += current_world_modifier.get_motivation_for_tags(action.tags)
  return motivation


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
  _update_willpower_display()


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

  for i in range(drawn_cards.size()):
    var card = drawn_cards[i]
    var card_panel := _create_mood_card_display(card)
    card_panel.pivot_offset = motivation_card_size / 2
    card_panel.scale = Vector2.ZERO
    card_panel.modulate.a = 0.0
    mood_cards_container.add_child(card_panel)

    var tween := create_tween()
    tween.set_parallel(true)
    var delay := i * card_reveal_delay
    tween.tween_property(card_panel, "scale", Vector2.ONE, 0.2).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(card_panel, "modulate:a", 1.0, 0.15).set_delay(delay)
    tween.tween_callback(_play_sound.bind(card_reveal_sound)).set_delay(delay)


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


func _update_willpower_display() -> void:
  var gap := maxi(0, current_action.motivation_cost - total_motivation)
  var willpower_needed := mini(gap, game_state.willpower)
  var can_attempt: bool = total_motivation + willpower_needed >= current_action.motivation_cost

  if gap == 0:
    willpower_cost_label.text = "No willpower needed"
  elif can_attempt:
    willpower_cost_label.text = "Willpower cost: %d" % willpower_needed
  else:
    willpower_cost_label.text = "Need %d more willpower" % (gap - game_state.willpower)

  attempt_button.disabled = not can_attempt
  attempt_button.text = "Attempt Action" if can_attempt else "Not enough willpower"


func _on_back_pressed() -> void:
  _show_action_selection()


func _on_attempt_pressed() -> void:
  _play_sound(attempt_sound)
  var gap := maxi(0, current_action.motivation_cost - total_motivation)
  var willpower_spent := mini(gap, game_state.willpower)
  game_state.spend_willpower(willpower_spent)
  willpower_spent_today += willpower_spent
  actions_taken.append(current_action.title)

  var success: bool = randf() < current_action.success_chance
  _show_result(success)


func _show_result(success: bool) -> void:
  motivation_phase_screen.visible = false
  result_panel.visible = true

  var score_gained := 0
  var cards_added := 0
  if success:
    for value_card in game_state.value_cards:
      score_gained += value_card.get_score_for_tags(current_action.tags)
    game_state.add_score(score_gained)

    for card in current_action.cards_on_success:
      game_state.add_motivation_card(card)
      cards_added += 1

    result_title.text = "Success!"
    result_title.add_theme_color_override("font_color", success_color)
    _play_sound(success_sound)
    var details_parts: Array = []
    if score_gained > 0:
      details_parts.append("You gained %d points!" % score_gained)
    if cards_added > 0:
      details_parts.append("Added %d card(s) to your motivation deck." % cards_added)
    if details_parts.is_empty():
      result_details.text = "Action completed, but it didn't align with your values."
    else:
      result_details.text = "\n".join(details_parts)
  else:
    result_title.text = "Failed..."
    result_title.add_theme_color_override("font_color", failure_color)
    _play_sound(failure_sound)
    result_details.text = "The action didn't succeed this time.\nBetter luck next time."

  _update_top_bar()


func _on_continue_pressed() -> void:
  game_state.current_day += 1
  if willpower_spent_today >= willpower_burnout_threshold:
    var burnout_penalty := willpower_spent_today / 10
    game_state.willpower_max = maxi(50, game_state.willpower_max - burnout_penalty)
  game_state.willpower = game_state.willpower_max
  willpower_spent_today = 0

  if game_state.current_day > max_days:
    _show_end_screen()
  else:
    _start_new_turn()
    _update_top_bar()


func _show_end_screen() -> void:
  action_selection_screen.visible = false
  motivation_phase_screen.visible = false
  result_panel.visible = false
  end_game_panel.visible = true

  end_title.text = "Week Complete!"
  final_score_label.text = "Final Score: %d" % game_state.score

  if actions_taken.is_empty():
    actions_summary.text = "You didn't take any actions this week."
  else:
    actions_summary.text = "Actions taken:\n" + "\n".join(actions_taken)


func _on_play_again_pressed() -> void:
  game_state = GameState.new()
  if starter_deck:
    game_state.load_from_deck(starter_deck)
  game_state.willpower = starting_willpower
  game_state.willpower_max = starting_willpower
  actions_taken.clear()
  willpower_spent_today = 0
  end_game_panel.visible = false
  _start_new_turn()
  _update_top_bar()
