extends Control

enum Element { FIRE, WATER, EARTH, AIR, LIGHTNING, ICE }

const ELEMENT_NAMES := {
  Element.FIRE: "Fire",
  Element.WATER: "Water",
  Element.EARTH: "Earth",
  Element.AIR: "Air",
  Element.LIGHTNING: "Lightning",
  Element.ICE: "Ice"
}

const ELEMENT_COLORS := {
  Element.FIRE: Color(1.0, 0.3, 0.1),
  Element.WATER: Color(0.2, 0.5, 1.0),
  Element.EARTH: Color(0.6, 0.4, 0.2),
  Element.AIR: Color(0.8, 0.9, 1.0),
  Element.LIGHTNING: Color(1.0, 1.0, 0.3),
  Element.ICE: Color(0.7, 0.9, 1.0)
}

const BEATS := {
  Element.FIRE: [Element.ICE, Element.AIR],
  Element.WATER: [Element.FIRE, Element.EARTH],
  Element.EARTH: [Element.LIGHTNING, Element.WATER],
  Element.AIR: [Element.EARTH, Element.ICE],
  Element.LIGHTNING: [Element.WATER, Element.AIR],
  Element.ICE: [Element.LIGHTNING, Element.FIRE]
}

const ANIM_DURATION := 0.3

var player_hand: Array[Element] = []
var computer_hand: Array[Element] = []
var player_score := 0
var computer_score := 0
var selected_card_index := -1
var battle_in_progress := false

@onready var player_hand_container: HBoxContainer = $VBoxContainer/GameArea/PlayerSection/PlayerHand
@onready var computer_hand_container: HBoxContainer = $VBoxContainer/GameArea/ComputerSection/ComputerHand
@onready var battle_area: CenterContainer = $VBoxContainer/GameArea/BattleArea
@onready var player_battle_card: Panel = $VBoxContainer/GameArea/BattleArea/HBoxContainer/PlayerBattleCard
@onready var computer_battle_card: Panel = $VBoxContainer/GameArea/BattleArea/HBoxContainer/ComputerBattleCard
@onready var result_label: Label = $VBoxContainer/GameArea/BattleArea/HBoxContainer/ResultLabel
@onready var score_label: Label = $VBoxContainer/TopBar/ScoreLabel
@onready var instruction_label: Label = $VBoxContainer/TopBar/InstructionLabel


func _ready() -> void:
  start_new_game()


func start_new_game() -> void:
  player_hand.clear()
  computer_hand.clear()
  player_score = 0
  computer_score = 0
  selected_card_index = -1
  battle_in_progress = false

  deal_hands()
  update_ui()
  instruction_label.text = "Select a card to play"


func deal_hands() -> void:
  for i in range(5):
    player_hand.append(random_element())
    computer_hand.append(random_element())


func random_element() -> Element:
  var elements := Element.values()
  return elements[randi() % elements.size()]


func update_ui() -> void:
  update_hand_display(player_hand_container, player_hand, true)
  update_hand_display(computer_hand_container, computer_hand, false)
  score_label.text = "Player: %d | Computer: %d" % [player_score, computer_score]

  player_battle_card.visible = false
  computer_battle_card.visible = false
  result_label.text = ""


func update_hand_display(container: HBoxContainer, hand: Array[Element], is_player: bool) -> void:
  for child in container.get_children():
    child.queue_free()

  for i in range(hand.size()):
    var card := create_card_button(hand[i], is_player, i)
    container.add_child(card)


func get_text_color(bg_color: Color) -> Color:
  var luminance := 0.299 * bg_color.r + 0.587 * bg_color.g + 0.114 * bg_color.b
  return Color.BLACK if luminance > 0.5 else Color.WHITE


func create_card_button(element: Element, is_player: bool, index: int) -> Button:
  var button := Button.new()
  button.custom_minimum_size = Vector2(80, 120)
  button.text = ELEMENT_NAMES[element]

  var style := StyleBoxFlat.new()
  if is_player:
    style.bg_color = ELEMENT_COLORS[element]
    button.add_theme_color_override("font_color", get_text_color(style.bg_color))
    button.add_theme_color_override("font_hover_color", get_text_color(style.bg_color))
  else:
    style.bg_color = Color(0.3, 0.3, 0.3)
  style.corner_radius_top_left = 8
  style.corner_radius_top_right = 8
  style.corner_radius_bottom_left = 8
  style.corner_radius_bottom_right = 8
  button.add_theme_stylebox_override("normal", style)

  var hover_style := style.duplicate()
  hover_style.bg_color = hover_style.bg_color.lightened(0.2)
  button.add_theme_stylebox_override("hover", hover_style)

  if is_player and not battle_in_progress:
    button.pressed.connect(_on_player_card_selected.bind(index))
  else:
    button.disabled = not is_player

  return button


func create_animated_card(element: Element) -> Panel:
  var panel := Panel.new()
  panel.custom_minimum_size = Vector2(100, 150)

  var style := StyleBoxFlat.new()
  style.bg_color = ELEMENT_COLORS[element]
  style.corner_radius_top_left = 8
  style.corner_radius_top_right = 8
  style.corner_radius_bottom_left = 8
  style.corner_radius_bottom_right = 8
  panel.add_theme_stylebox_override("panel", style)

  var label := Label.new()
  label.text = ELEMENT_NAMES[element]
  label.add_theme_font_size_override("font_size", 16)
  label.add_theme_color_override("font_color", get_text_color(style.bg_color))
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.set_anchors_preset(Control.PRESET_FULL_RECT)
  panel.add_child(label)

  return panel


func _on_player_card_selected(index: int) -> void:
  if battle_in_progress or index >= player_hand.size() or computer_hand.is_empty():
    return

  selected_card_index = index
  battle_in_progress = true
  instruction_label.text = "Battle!"

  var player_element := player_hand[index]
  var computer_index := choose_computer_card()
  var computer_element := computer_hand[computer_index]

  var player_card_button: Button = player_hand_container.get_child(index)
  var computer_card_button: Button = computer_hand_container.get_child(computer_index)
  var player_start_pos := player_card_button.global_position
  var computer_start_pos := computer_card_button.global_position

  player_hand.remove_at(index)
  computer_hand.remove_at(computer_index)
  update_hand_display(player_hand_container, player_hand, true)
  update_hand_display(computer_hand_container, computer_hand, false)

  await animate_battle(player_element, computer_element, player_start_pos, computer_start_pos)


func choose_computer_card() -> int:
  return randi() % computer_hand.size()


func animate_battle(player_element: Element, computer_element: Element, player_start: Vector2, computer_start: Vector2) -> void:
  var player_card := create_animated_card(player_element)
  var computer_card := create_animated_card(computer_element)

  add_child(player_card)
  add_child(computer_card)

  player_card.global_position = player_start
  computer_card.global_position = computer_start

  await get_tree().process_frame
  var player_target := player_battle_card.global_position
  var computer_target := computer_battle_card.global_position

  var tween := create_tween()
  tween.set_parallel(true)
  tween.tween_property(player_card, "global_position", player_target, ANIM_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
  tween.tween_property(computer_card, "global_position", computer_target, ANIM_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
  await tween.finished

  setup_battle_card(player_battle_card, player_element)
  setup_battle_card(computer_battle_card, computer_element)
  player_battle_card.visible = true
  computer_battle_card.visible = true
  player_card.visible = false
  computer_card.visible = false

  var result := resolve_battle(player_element, computer_element)

  match result:
    1:
      result_label.text = "WIN!"
      result_label.add_theme_color_override("font_color", Color.GREEN)
      player_hand.append(player_element)
      player_score += 1
    -1:
      result_label.text = "LOSE!"
      result_label.add_theme_color_override("font_color", Color.RED)
      computer_hand.append(computer_element)
      computer_score += 1
    0:
      result_label.text = "TIE!"
      result_label.add_theme_color_override("font_color", Color.YELLOW)
      player_hand.append(player_element)
      computer_hand.append(computer_element)

  score_label.text = "Player: %d | Computer: %d" % [player_score, computer_score]

  await get_tree().create_timer(1.0).timeout

  player_battle_card.visible = false
  computer_battle_card.visible = false
  result_label.text = ""

  update_hand_display(player_hand_container, player_hand, true)
  update_hand_display(computer_hand_container, computer_hand, false)
  await get_tree().process_frame

  var has_return_anim := false

  if result >= 0 and player_hand.size() > 0:
    var target_button: Button = player_hand_container.get_child(player_hand.size() - 1)
    player_card.visible = true
    player_card.global_position = player_target
    var return_tween := create_tween()
    return_tween.tween_property(player_card, "global_position", target_button.global_position, ANIM_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    has_return_anim = true

  if result <= 0 and computer_hand.size() > 0:
    var target_button: Button = computer_hand_container.get_child(computer_hand.size() - 1)
    computer_card.visible = true
    computer_card.global_position = computer_target
    var return_tween := create_tween()
    return_tween.tween_property(computer_card, "global_position", target_button.global_position, ANIM_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
    has_return_anim = true

  if has_return_anim:
    await get_tree().create_timer(ANIM_DURATION).timeout

  player_card.queue_free()
  computer_card.queue_free()

  battle_in_progress = false
  update_hand_display(player_hand_container, player_hand, true)
  update_hand_display(computer_hand_container, computer_hand, false)
  check_game_end()


func setup_battle_card(panel: Panel, element: Element) -> void:
  var style := StyleBoxFlat.new()
  style.bg_color = ELEMENT_COLORS[element]
  style.corner_radius_top_left = 8
  style.corner_radius_top_right = 8
  style.corner_radius_bottom_left = 8
  style.corner_radius_bottom_right = 8
  panel.add_theme_stylebox_override("panel", style)

  var label: Label = panel.get_node_or_null("Label")
  if label:
    label.text = ELEMENT_NAMES[element]
    label.add_theme_color_override("font_color", get_text_color(style.bg_color))


func resolve_battle(player: Element, computer: Element) -> int:
  if player == computer:
    return 0
  if computer in BEATS[player]:
    return 1
  return -1


func check_game_end() -> void:
  if player_hand.is_empty():
    instruction_label.text = "Game Over! Computer wins! Click to restart."
    await get_tree().create_timer(0.5).timeout
    set_process_input(true)
  elif computer_hand.is_empty():
    instruction_label.text = "Game Over! You win! Click to restart."
    await get_tree().create_timer(0.5).timeout
    set_process_input(true)
  else:
    instruction_label.text = "Select a card to play"


func _input(event: InputEvent) -> void:
  if battle_in_progress:
    return
  if event is InputEventMouseButton and event.pressed:
    if player_hand.is_empty() or computer_hand.is_empty():
      set_process_input(false)
      start_new_game()
