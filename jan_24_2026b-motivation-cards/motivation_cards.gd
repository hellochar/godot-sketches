extends Control

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")
const GameState = preload("res://jan_24_2026b-motivation-cards/game_state.gd")
const StarterDeckResourceScript = preload("res://jan_24_2026b-motivation-cards/starter_deck_resource.gd")
const MotivationCardRes = preload("res://jan_24_2026b-motivation-cards/motivation_card_resource.gd")
const ValueCardRes = preload("res://jan_24_2026b-motivation-cards/value_card_resource.gd")
const GenericCardScene = preload("res://common/generic_card.tscn")

@export_group("Game Settings")
@export var cards_per_draw: int = 5
@export_range(0.0, 1.0) var world_modifier_chance: float = 0.5
@export var starting_willpower: int = 100
@export var max_days: int = 7
@export var card_reveal_delay: float = 0.15
@export var willpower_burnout_threshold: int = 50
@export var max_discards_per_turn: int = 2

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
@export var click_sound: AudioStream
@export var deck_add_sound: AudioStream
@export var willpower_low_sound: AudioStream

@export_group("Feedback")
@export var button_press_scale: float = 0.95
@export var button_hover_scale: float = 1.03
@export var pitch_variance: float = 0.1
@export var volume_variance_db: float = 2.0
@export var shake_amplitude: float = 8.0
@export var shake_duration: float = 0.2
@export var willpower_drain_duration: float = 0.4
@export var result_pause_duration: float = 0.2
@export var tally_card_delay: float = 0.15
@export var tally_card_reveal_time: float = 0.2
@export var transition_duration: float = 0.15
@export var low_willpower_threshold: float = 0.2

@onready var day_label: Label = %DayLabel
@onready var score_label: Label = %ScoreLabel
@onready var momentum_label: Label = %MomentumLabel
@onready var streak_label: Label = %StreakLabel
@onready var bonus_tag_label: Label = %BonusTagLabel
@onready var willpower_bar: ProgressBar = %WillpowerBar
@onready var willpower_label: Label = %WillpowerLabel

@onready var action_selection_screen: VBoxContainer = %ActionSelectionScreen
@onready var action_grid: Container = %ActionGrid
@onready var mood_cards_container: HBoxContainer = %MoodCardsContainer
@onready var mood_world_label: Label = %MoodWorldLabel
@onready var values_cards_container: HBoxContainer = %ValuesCardsContainer

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
@onready var discard_label: Label = %DiscardLabel
@onready var back_button: Button = %BackButton
@onready var attempt_button: Button = %AttemptButton

@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_title: Label = %ResultTitle
@onready var result_details: Label = %ResultDetails
@onready var cards_added_container: HBoxContainer = %CardsAddedContainer
@onready var forget_card_button: Button = %ForgetCardButton
@onready var continue_button: Button = %ContinueButton

@onready var card_removal_panel: PanelContainer = %CardRemovalPanel
@onready var card_removal_container: HBoxContainer = %CardRemovalContainer
@onready var skip_removal_button: Button = %SkipRemovalButton

@onready var end_game_panel: PanelContainer = %EndGamePanel
@onready var end_title: Label = %EndTitle
@onready var final_score_label: Label = %FinalScore
@onready var actions_summary: Label = %ActionsSummary
@onready var play_again_button: Button = %PlayAgainButton
@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var screen_overlay: ColorRect = %ScreenOverlay
@onready var main_container: VBoxContainer = $MainContainer

var game_state
var current_action
var drawn_cards: Array = []
var current_world_modifier
var total_motivation: int = 0
var actions_taken: Array = []
var willpower_spent_today: int = 0
var last_action_succeeded: bool = false
var discards_this_turn: int = 0
var discarded_cards_this_turn: Array = []
var is_animating: bool = false
var value_card_abilities_used: Dictionary = {}
var value_card_bonus_motivation: int = 0
var double_next_score: bool = false


func _build_context_for_action(action) -> Dictionary:
  var tag_counts := {}
  for tag in CardData.Tag.values():
    tag_counts[tag] = 0

  for card in drawn_cards:
    for tag in CardData.Tag.values():
      if card.get_modifier(tag) != 0:
        tag_counts[tag] += 1

  return {
    "tag_counts": tag_counts,
    "action_tags": action.tags,
    "action_tag_count": action.tags.size(),
    "action_cost": action.motivation_cost,
    "action_title": action.title,
    "success_chance": action.success_chance,
    "succeeded_yesterday": game_state.succeeded_yesterday,
    "success_streak": game_state.success_streak,
    "attempted_actions": game_state.attempted_actions,
    "discards_this_turn": discards_this_turn,
    "total_successes_this_week": game_state.total_successes_this_week,
    "last_successful_action_title": game_state.last_successful_action_title,
    "willpower": game_state.willpower,
  }


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
  forget_card_button.pressed.connect(_on_forget_card_pressed)
  skip_removal_button.pressed.connect(_on_skip_removal_pressed)

  _setup_button_feedback(back_button)
  _setup_button_feedback(attempt_button)
  _setup_button_feedback(continue_button)
  _setup_button_feedback(play_again_button)
  _setup_button_feedback(forget_card_button)
  _setup_button_feedback(skip_removal_button)


func _play_sound(sound: AudioStream, vary: bool = true) -> void:
  if sound and audio_player:
    audio_player.stream = sound
    if vary:
      audio_player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
      audio_player.volume_db = randf_range(-volume_variance_db, 0.0) - 12
    else:
      audio_player.pitch_scale = 1.0
      audio_player.volume_db = 0.0
    audio_player.play()


func _setup_button_feedback(btn: Button) -> void:
  btn.pivot_offset = btn.size / 2
  btn.button_down.connect(func() -> void:
    _play_sound(click_sound)
    var tween := create_tween()
    tween.tween_property(btn, "scale", Vector2.ONE * button_press_scale, 0.05)
  )
  btn.button_up.connect(func() -> void:
    var tween := create_tween()
    tween.tween_property(btn, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)
  )
  btn.mouse_entered.connect(func() -> void:
    if not btn.disabled:
      btn.pivot_offset = btn.size / 2
      var tween := create_tween()
      tween.tween_property(btn, "scale", Vector2.ONE * button_hover_scale, 0.1).set_ease(Tween.EASE_OUT)
  )
  btn.mouse_exited.connect(func() -> void:
    var tween := create_tween()
    tween.tween_property(btn, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)
  )
  btn.resized.connect(func() -> void:
    btn.pivot_offset = btn.size / 2
  )


func _setup_card_feedback(card: Control) -> void:
  card.pivot_offset = card.size / 2
  card.gui_input.connect(func(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
      if event.pressed:
        _play_sound(click_sound)
        var tween := create_tween()
        tween.tween_property(card, "scale", Vector2.ONE * button_press_scale, 0.05)
      else:
        var tween := create_tween()
        tween.tween_property(card, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)
  )
  card.mouse_entered.connect(func() -> void:
    card.pivot_offset = card.size / 2
    var tween := create_tween()
    tween.tween_property(card, "scale", Vector2.ONE * button_hover_scale, 0.1).set_ease(Tween.EASE_OUT)
  )
  card.mouse_exited.connect(func() -> void:
    var tween := create_tween()
    tween.tween_property(card, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)
  )
  card.resized.connect(func() -> void:
    card.pivot_offset = card.size / 2
  )


func _update_top_bar() -> void:
  day_label.text = "Day %d of %d" % [game_state.current_day, max_days]
  score_label.text = "Score: %d" % game_state.score
  var momentum_bonus: int = game_state.momentum * game_state.MOMENTUM_BONUS_PER
  if momentum_bonus > 0:
    momentum_label.text = "Momentum: %d (+%d)" % [game_state.momentum, momentum_bonus]
  else:
    momentum_label.text = "Momentum: %d" % game_state.momentum
  streak_label.text = "Streak: %d" % game_state.success_streak
  if game_state.daily_bonus_tag >= 0:
    var tag_name: String = CardData.TAG_NAMES[game_state.daily_bonus_tag]
    bonus_tag_label.text = "Bonus: %s (+%d)" % [tag_name, game_state.DAILY_BONUS_SCORE]
  else:
    bonus_tag_label.text = ""
  willpower_bar.max_value = game_state.willpower_max
  willpower_bar.value = game_state.willpower
  willpower_label.text = "%d/%d" % [game_state.willpower, game_state.willpower_max]

  var low_threshold: float = game_state.willpower_max * low_willpower_threshold
  if game_state.willpower <= low_threshold:
    willpower_label.add_theme_color_override("font_color", failure_color)
    willpower_bar.modulate = Color(1.2, 0.8, 0.8)
  else:
    willpower_label.remove_theme_color_override("font_color")
    willpower_bar.modulate = Color.WHITE


func _show_action_selection() -> void:
  if motivation_phase_screen.visible:
    await _fade_out(motivation_phase_screen)
  if result_panel.visible:
    await _fade_out(result_panel)

  _populate_action_grid()
  _display_value_cards()
  _display_mood_cards()
  _display_mood_world_modifier()
  await _fade_in(action_selection_screen)


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


func _create_action_button(action) -> PanelContainer:
  var mastery_level: int = game_state.get_action_mastery(action.title)
  var mastery_discount: int = mastery_level * game_state.MASTERY_DISCOUNT_PER
  var effective_cost: int = maxi(0, action.motivation_cost - mastery_discount)
  var motivation := _get_motivation_for_action(action)
  var willpower_needed := maxi(0, effective_cost - motivation)
  var potential_score := _get_potential_score(action)

  var bg_color := button_normal_color
  if willpower_needed == 0:
    bg_color = positive_card_color
  elif willpower_needed > game_state.willpower:
    bg_color = negative_card_color

  var generic_card = GenericCardScene.instantiate()
  generic_card.card_size = action_button_size
  generic_card.background_color = bg_color
  generic_card.corner_radius = card_corner_radius
  generic_card.content_margin = card_margin
  generic_card.enable_hover = true
  generic_card.title = action.title

  if mastery_level > 0:
    var stars := "*".repeat(mastery_level)
    generic_card.set_corner_text(generic_card.Corner.TOP_LEFT, stars, Color(1.0, 0.85, 0.3))
  if willpower_needed > 0:
    generic_card.set_corner_text(generic_card.Corner.BOTTOM_LEFT, "%d willpower" % willpower_needed)
  if action.success_chance < 1.0:
    generic_card.set_corner_text(generic_card.Corner.TOP_RIGHT, "%d%%" % int(action.success_chance * 100))
  var score_str := "+%d pts" % potential_score if potential_score > 0 else "0 pts"
  generic_card.set_corner_text(generic_card.Corner.BOTTOM_RIGHT, score_str)

  for tag in action.tags:
    generic_card.add_tag(CardData.TAG_NAMES[tag], CardData.TAG_COLORS[tag])

  generic_card.pressed.connect(func() -> void: _select_action(action))
  _setup_card_feedback(generic_card)
  return generic_card


func _get_motivation_for_action(action) -> int:
  var context := _build_context_for_action(action)
  var has_negate := false
  var has_invert := false
  for card in drawn_cards:
    if card is MotivationCardRes:
      if card.special_effect == MotivationCardRes.SpecialEffect.NEGATE_NEGATIVES:
        has_negate = true
      elif card.special_effect == MotivationCardRes.SpecialEffect.INVERT_NEGATIVES:
        has_invert = true

  var motivation := 0
  for card in drawn_cards:
    var card_contrib: int = card.get_motivation_for_tags(action.tags, context)
    if card_contrib < 0:
      if has_invert:
        card_contrib = -card_contrib
      elif has_negate:
        card_contrib = 0
    motivation += card_contrib

  if current_world_modifier:
    motivation += current_world_modifier.get_motivation_for_tags(action.tags)
  motivation += _get_special_effect_bonus(action, context)
  motivation += value_card_bonus_motivation
  motivation += game_state.momentum * game_state.MOMENTUM_BONUS_PER
  return motivation


func _get_potential_score(action) -> int:
  var score := 0
  for value_card in game_state.value_cards:
    score += value_card.get_score_for_tags(action.tags)
  if game_state.daily_bonus_tag in action.tags:
    score += game_state.DAILY_BONUS_SCORE
  return score


func _get_special_effect_bonus(action, context: Dictionary) -> int:
  var bonus := 0
  var has_amplify := false
  for card in drawn_cards:
    if not (card is MotivationCardRes):
      continue
    if card.special_effect == MotivationCardRes.SpecialEffect.AMPLIFY_ALL:
      has_amplify = true

  for card in drawn_cards:
    if not (card is MotivationCardRes):
      continue
    match card.special_effect:
      MotivationCardRes.SpecialEffect.BONUS_FOR_NEW_ACTIONS:
        if action.title not in context.get("attempted_actions", []):
          bonus += card.special_value
      MotivationCardRes.SpecialEffect.STREAK_SCALING:
        bonus += card.special_value * context.get("success_streak", 0)
      MotivationCardRes.SpecialEffect.MOMENTUM_SCALING:
        bonus += card.special_value * context.get("total_successes_this_week", 0)
      MotivationCardRes.SpecialEffect.DISCARD_SCALING:
        bonus += card.special_value * context.get("discards_this_turn", 0)
      MotivationCardRes.SpecialEffect.EXHAUST_BONUS:
        bonus += card.special_value
      MotivationCardRes.SpecialEffect.BONUS_PER_NEGATIVE_CARD:
        var negative_count := 0
        for other_card in drawn_cards:
          var contrib: int = other_card.get_motivation_for_tags(action.tags, context)
          if contrib < 0:
            negative_count += 1
        bonus += card.special_value * negative_count
      MotivationCardRes.SpecialEffect.DOUBLE_TAG_ZERO_OTHER:
        pass
      MotivationCardRes.SpecialEffect.AMPLIFY_ALL:
        pass
      MotivationCardRes.SpecialEffect.NEGATE_NEGATIVES:
        pass
      MotivationCardRes.SpecialEffect.INVERT_NEGATIVES:
        pass

  if has_amplify:
    var base_motivation := 0
    for card in drawn_cards:
      if card is MotivationCardRes and card.special_effect == MotivationCardRes.SpecialEffect.AMPLIFY_ALL:
        continue
      base_motivation += card.get_motivation_for_tags(action.tags, context)
    bonus += base_motivation

  return bonus


func _format_tags(tags: Array) -> String:
  var parts: Array = []
  for tag in tags:
    parts.append(CardData.TAG_NAMES[tag])
  return ", ".join(parts)


func _select_action(action) -> void:
  current_action = action
  await _show_motivation_phase()


func _show_motivation_phase() -> void:
  await _fade_out(action_selection_screen)

  attempt_button.disabled = true
  back_button.disabled = true

  action_title.text = current_action.title
  var mastery_level: int = game_state.get_action_mastery(current_action.title)
  var mastery_discount: int = mastery_level * game_state.MASTERY_DISCOUNT_PER
  var effective_cost: int = maxi(0, current_action.motivation_cost - mastery_discount)
  if mastery_discount > 0:
    cost_label.text = "Cost: %d (-%d mastery)" % [effective_cost, mastery_discount]
  else:
    cost_label.text = "Cost: %d" % effective_cost
  if current_action.success_chance >= 1.0:
    success_label.text = ""
  else:
    success_label.text = "Success: %d%%" % int(current_action.success_chance * 100)

  _populate_tags()
  _display_drawn_cards()
  _display_world_modifier()
  _update_discard_label()

  await _fade_in(motivation_phase_screen)
  await _animate_motivation_tally()

  _display_drawn_cards_instant()
  _calculate_motivation()
  _update_willpower_display()
  _update_discard_label()
  back_button.disabled = false


func _start_new_turn() -> void:
  var draw_count: int = cards_per_draw + game_state.extra_draws_next_turn
  game_state.extra_draws_next_turn = 0
  drawn_cards = game_state.draw_motivation_cards(draw_count)
  discards_this_turn = 0
  discarded_cards_this_turn.clear()
  value_card_bonus_motivation = 0
  game_state.randomize_daily_bonus_tag()
  if (game_state.current_day - 1) % 7 == 0:
    value_card_abilities_used.clear()
    game_state.momentum = 0
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
  var generic_card = GenericCardScene.instantiate()
  generic_card.card_size = motivation_card_size
  generic_card.background_color = neutral_card_color
  generic_card.corner_radius = card_corner_radius
  generic_card.content_margin = card_margin
  generic_card.title = card.title
  generic_card.description = card.format_modifiers()
  return generic_card


func _display_mood_world_modifier() -> void:
  if current_world_modifier:
    mood_world_label.text = "World: %s" % current_world_modifier.title
  else:
    mood_world_label.text = ""


func _display_value_cards() -> void:
  for child in values_cards_container.get_children():
    child.queue_free()

  for value_card in game_state.value_cards:
    var card_panel := _create_value_card_display(value_card)
    values_cards_container.add_child(card_panel)


func _create_value_card_display(card) -> PanelContainer:
  var ability_used: bool = value_card_abilities_used.get(card.title, false)
  var has_ability: bool = card.has_ability()

  var bg_color := Color(0.25, 0.35, 0.45)
  if has_ability and not ability_used:
    bg_color = Color(0.35, 0.35, 0.55)

  var generic_card = GenericCardScene.instantiate()
  generic_card.card_size = motivation_card_size
  generic_card.background_color = bg_color
  generic_card.corner_radius = card_corner_radius
  generic_card.content_margin = card_margin
  generic_card.title = card.title
  generic_card.description = _format_value_card_scores(card)
  generic_card.description_color = success_color

  if has_ability:
    var ability_text: String = card.get_ability_description()
    var ability_color := Color(0.8, 0.7, 1.0) if not ability_used else Color(0.5, 0.5, 0.5)
    var status_text := ability_text if not ability_used else ability_text + " (used)"
    generic_card.add_content_label(status_text, 10, ability_color)

    if not ability_used:
      generic_card.enable_hover = true
      generic_card.pressed.connect(func() -> void: _activate_value_card_ability(card))
      _setup_card_feedback(generic_card)

  return generic_card


func _format_value_card_scores(card) -> String:
  var parts: Array = []
  if card.health_score > 0:
    parts.append("+%d Health" % card.health_score)
  if card.social_score > 0:
    parts.append("+%d Social" % card.social_score)
  if card.routine_score > 0:
    parts.append("+%d Routine" % card.routine_score)
  if card.effort_score > 0:
    parts.append("+%d Effort" % card.effort_score)
  if card.risk_score > 0:
    parts.append("+%d Risk" % card.risk_score)
  if card.creativity_score > 0:
    parts.append("+%d Creativity" % card.creativity_score)
  return "\n".join(parts)


func _activate_value_card_ability(card) -> void:
  if value_card_abilities_used.get(card.title, false):
    return

  value_card_abilities_used[card.title] = true
  _play_sound(click_sound)

  match card.ability_type:
    ValueCardRes.AbilityType.EXTRA_DRAW:
      var new_cards := game_state.draw_motivation_cards(card.ability_value)
      for new_card in new_cards:
        if new_card not in drawn_cards:
          drawn_cards.append(new_card)
    ValueCardRes.AbilityType.RESTORE_WILLPOWER:
      game_state.willpower = mini(game_state.willpower_max, game_state.willpower + card.ability_value)
      _update_top_bar()
    ValueCardRes.AbilityType.DOUBLE_NEXT_SCORE:
      double_next_score = true
    ValueCardRes.AbilityType.REROLL_HAND:
      drawn_cards = game_state.draw_motivation_cards(card.ability_value)
    ValueCardRes.AbilityType.BONUS_MOTIVATION:
      value_card_bonus_motivation += card.ability_value

  _display_value_cards()
  _display_drawn_cards_instant()
  _calculate_motivation()
  _update_willpower_display()


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
    card_panel.pivot_offset = motivation_card_size / 2
    card_panel.scale = Vector2.ZERO
    card_panel.modulate.a = 0.0
    drawn_cards_container.add_child(card_panel)


func _create_motivation_card_display(card) -> PanelContainer:
  var context := _build_context_for_action(current_action)
  var motivation_value: int = card.get_motivation_for_tags(current_action.tags, context)

  var bg_color := neutral_card_color
  if motivation_value > 0:
    bg_color = positive_card_color
  elif motivation_value < 0:
    bg_color = negative_card_color

  var generic_card = GenericCardScene.instantiate()
  generic_card.card_size = motivation_card_size
  generic_card.background_color = bg_color
  generic_card.corner_radius = card_corner_radius
  generic_card.content_margin = card_margin
  generic_card.title = card.title
  generic_card.description = card.format_modifiers()

  if card is MotivationCardRes:
    var condition_text: String = card.get_condition_text()
    if not condition_text.is_empty():
      var condition_met: bool = card.check_condition(context)
      var cond_color := success_color if condition_met else Color(0.6, 0.6, 0.6)
      generic_card.add_content_label(condition_text, 10, cond_color)

    var special_text: String = card.get_special_effect_text()
    if not special_text.is_empty():
      generic_card.add_content_label(special_text, 10, Color(0.8, 0.7, 1.0))

  if motivation_value != 0:
    var sign_str := "+" if motivation_value > 0 else ""
    var contrib_color := success_color if motivation_value > 0 else failure_color
    generic_card.add_content_label("→ %s%d" % [sign_str, motivation_value], 16, contrib_color)

  return generic_card


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
  var context := _build_context_for_action(current_action)
  total_motivation = 0
  for card in drawn_cards:
    total_motivation += card.get_motivation_for_tags(current_action.tags, context)

  if current_world_modifier:
    total_motivation += current_world_modifier.get_motivation_for_tags(current_action.tags)

  total_motivation += _get_special_effect_bonus(current_action, context)

  var effective_cost: int = _get_effective_action_cost(current_action)
  total_motivation_label.text = "Total Motivation: %d / %d" % [total_motivation, effective_cost]

  var gap := maxi(0, effective_cost - total_motivation)
  gap_label.text = "Gap: %d" % gap


func _get_effective_action_cost(action) -> int:
  var mastery_level: int = game_state.get_action_mastery(action.title)
  var mastery_discount: int = mastery_level * game_state.MASTERY_DISCOUNT_PER
  return maxi(0, action.motivation_cost - mastery_discount)


func _animate_motivation_tally() -> void:
  var context := _build_context_for_action(current_action)
  var running_total := 0
  total_motivation_label.text = "Total Motivation: 0 / %d" % current_action.motivation_cost
  gap_label.text = "Gap: %d" % current_action.motivation_cost

  var card_panels := drawn_cards_container.get_children()
  for i in range(drawn_cards.size()):
    var card = drawn_cards[i]
    var card_panel: PanelContainer = card_panels[i]
    var motivation_value: int = card.get_motivation_for_tags(current_action.tags, context)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(card_panel, "scale", Vector2.ONE, tally_card_reveal_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(card_panel, "modulate:a", 1.0, tally_card_reveal_time * 0.75)
    _play_sound(card_reveal_sound)

    await tween.finished

    if motivation_value != 0:
      var pulse_color := success_color if motivation_value > 0 else failure_color
      var original_modulate := card_panel.modulate
      card_panel.modulate = pulse_color
      var pulse_tween := create_tween()
      pulse_tween.tween_property(card_panel, "modulate", original_modulate, 0.2)

    running_total += motivation_value
    total_motivation_label.text = "Total Motivation: %d / %d" % [running_total, current_action.motivation_cost]
    var gap := maxi(0, current_action.motivation_cost - running_total)
    gap_label.text = "Gap: %d" % gap

    if i < drawn_cards.size() - 1:
      await get_tree().create_timer(tally_card_delay * 0.5).timeout

  if current_world_modifier:
    var mod_value: int = current_world_modifier.get_motivation_for_tags(current_action.tags)
    if mod_value != 0:
      running_total += mod_value
      total_motivation_label.text = "Total Motivation: %d / %d" % [running_total, current_action.motivation_cost]
      var gap := maxi(0, current_action.motivation_cost - running_total)
      gap_label.text = "Gap: %d" % gap

  var emphasis_tween := create_tween()
  total_motivation_label.pivot_offset = total_motivation_label.size / 2
  emphasis_tween.tween_property(total_motivation_label, "scale", Vector2.ONE * 1.15, 0.1)
  emphasis_tween.tween_property(total_motivation_label, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)


func _update_willpower_display() -> void:
  var effective_cost: int = _get_effective_action_cost(current_action)
  var gap := maxi(0, effective_cost - total_motivation)
  var willpower_needed := mini(gap, game_state.willpower)
  var can_attempt: bool = total_motivation + willpower_needed >= effective_cost

  if gap == 0:
    willpower_cost_label.text = "No willpower needed"
  elif can_attempt:
    willpower_cost_label.text = "Willpower cost: %d" % willpower_needed
  else:
    willpower_cost_label.text = "Need %d more willpower" % (gap - game_state.willpower)

  attempt_button.disabled = not can_attempt
  attempt_button.text = "Attempt Action" if can_attempt else "Not enough willpower"


func _update_discard_label() -> void:
  var remaining := max_discards_per_turn - discards_this_turn
  if remaining > 0:
    discard_label.text = "Click a card to discard and redraw (%d remaining)" % remaining
    discard_label.modulate = Color.WHITE
  else:
    discard_label.text = "No discards remaining"
    discard_label.modulate = Color(0.6, 0.6, 0.6)


func _discard_card(card_index: int) -> void:
  if is_animating or discards_this_turn >= max_discards_per_turn:
    return
  if card_index < 0 or card_index >= drawn_cards.size():
    return

  is_animating = true
  discards_this_turn += 1
  var discarded_card = drawn_cards[card_index]
  discarded_cards_this_turn.append(discarded_card)
  drawn_cards.remove_at(card_index)

  var new_card = game_state.draw_motivation_cards(1)
  if new_card.size() > 0:
    drawn_cards.insert(card_index, new_card[0])

  _play_sound(card_reveal_sound)

  _display_drawn_cards_instant()
  _calculate_motivation()
  _update_willpower_display()
  _update_discard_label()
  is_animating = false


func _display_drawn_cards_instant() -> void:
  for child in drawn_cards_container.get_children():
    child.queue_free()

  for i in range(drawn_cards.size()):
    var card = drawn_cards[i]
    var card_panel := _create_motivation_card_display_clickable(card, i)
    drawn_cards_container.add_child(card_panel)


func _create_motivation_card_display_clickable(card, card_index: int) -> PanelContainer:
  var context := _build_context_for_action(current_action)
  var motivation_value: int = card.get_motivation_for_tags(current_action.tags, context)

  var bg_color := neutral_card_color
  if motivation_value > 0:
    bg_color = positive_card_color
  elif motivation_value < 0:
    bg_color = negative_card_color

  var generic_card = GenericCardScene.instantiate()
  generic_card.card_size = motivation_card_size
  generic_card.background_color = bg_color
  generic_card.corner_radius = card_corner_radius
  generic_card.content_margin = card_margin
  generic_card.enable_hover = true
  generic_card.title = card.title
  generic_card.description = card.format_modifiers()

  if card is MotivationCardRes:
    var condition_text: String = card.get_condition_text()
    if not condition_text.is_empty():
      var condition_met: bool = card.check_condition(context)
      var cond_color := success_color if condition_met else Color(0.6, 0.6, 0.6)
      generic_card.add_content_label(condition_text, 10, cond_color)

    var special_text: String = card.get_special_effect_text()
    if not special_text.is_empty():
      generic_card.add_content_label(special_text, 10, Color(0.8, 0.7, 1.0))

  if motivation_value != 0:
    var sign_str := "+" if motivation_value > 0 else ""
    var contrib_color := success_color if motivation_value > 0 else failure_color
    generic_card.add_content_label("→ %s%d" % [sign_str, motivation_value], 16, contrib_color)

  if discards_this_turn < max_discards_per_turn:
    generic_card.pressed.connect(func() -> void: _discard_card(card_index))

  return generic_card


func _on_back_pressed() -> void:
  _show_action_selection()


func _on_attempt_pressed() -> void:
  _play_sound(attempt_sound)
  attempt_button.disabled = true
  back_button.disabled = true

  var effective_cost: int = _get_effective_action_cost(current_action)
  var gap := maxi(0, effective_cost - total_motivation)
  var willpower_spent := mini(gap, game_state.willpower)

  screen_overlay.color = Color(0, 0, 0, 0)
  screen_overlay.visible = true
  var dim_tween := create_tween()
  dim_tween.tween_property(screen_overlay, "color:a", 0.3, 0.15)

  if willpower_spent > 0:
    var start_willpower: int = game_state.willpower
    var end_willpower: int = start_willpower - willpower_spent
    var low_threshold: float = game_state.willpower_max * low_willpower_threshold
    var crossed_low_threshold := start_willpower > low_threshold and end_willpower <= low_threshold
    var already_low := start_willpower <= low_threshold
    var warning_color := failure_color

    var drain_tween := create_tween()
    drain_tween.tween_method(func(val: float) -> void:
      willpower_bar.value = val
      willpower_label.text = "%d/%d" % [int(val), game_state.willpower_max]
      if val <= low_threshold:
        willpower_label.add_theme_color_override("font_color", warning_color)
      else:
        willpower_label.remove_theme_color_override("font_color")
    , float(start_willpower), float(end_willpower), willpower_drain_duration)

    if crossed_low_threshold or already_low:
      var pulse_tween := create_tween()
      pulse_tween.set_loops(3)
      pulse_tween.tween_property(willpower_bar, "modulate", Color(1.5, 0.5, 0.5), 0.1)
      pulse_tween.tween_property(willpower_bar, "modulate", Color.WHITE, 0.1)

    await drain_tween.finished

    if crossed_low_threshold:
      _play_sound(willpower_low_sound)

    willpower_bar.modulate = Color.WHITE
    willpower_label.remove_theme_color_override("font_color")

  game_state.spend_willpower(willpower_spent)
  willpower_spent_today += willpower_spent
  actions_taken.append(current_action.title)

  await get_tree().create_timer(result_pause_duration).timeout

  var success: bool = randf() < current_action.success_chance

  if success:
    await _flash_screen(Color.WHITE, 0.08)
  else:
    await _shake_screen()

  screen_overlay.visible = false
  _show_result(success)


func _flash_screen(flash_color: Color, duration: float) -> void:
  screen_overlay.color = flash_color
  var tween := create_tween()
  tween.tween_property(screen_overlay, "color:a", 0.0, duration)
  await tween.finished


func _shake_screen() -> void:
  var original_pos := main_container.position
  var elapsed := 0.0
  while elapsed < shake_duration:
    var offset := Vector2(
      randf_range(-shake_amplitude, shake_amplitude),
      randf_range(-shake_amplitude, shake_amplitude)
    )
    main_container.position = original_pos + offset
    await get_tree().process_frame
    elapsed += get_process_delta_time()
  main_container.position = original_pos


func _fade_out(node: Control) -> void:
  if not node.visible:
    return
  var tween := create_tween()
  tween.tween_property(node, "modulate:a", 0.0, transition_duration)
  await tween.finished
  node.visible = false
  node.modulate.a = 1.0


func _fade_in(node: Control) -> void:
  node.modulate.a = 0.0
  node.visible = true
  var tween := create_tween()
  tween.tween_property(node, "modulate:a", 1.0, transition_duration)
  await tween.finished


func _show_result(success: bool) -> void:
  await _fade_out(motivation_phase_screen)

  for child in cards_added_container.get_children():
    child.queue_free()

  if current_action.title not in game_state.attempted_actions:
    game_state.attempted_actions.append(current_action.title)

  var score_gained := 0
  var cards_to_add: Array = []
  var willpower_restored := 0

  if success:
    game_state.success_streak += 1
    game_state.succeeded_yesterday = true
    game_state.total_successes_this_week += 1
    game_state.last_successful_action_title = current_action.title
    game_state.momentum = mini(game_state.MOMENTUM_MAX, game_state.momentum + 1)
    game_state.increase_action_mastery(current_action.title)
    last_action_succeeded = true

    for value_card in game_state.value_cards:
      score_gained += value_card.get_score_for_tags(current_action.tags)
    if game_state.daily_bonus_tag in current_action.tags:
      score_gained += game_state.DAILY_BONUS_SCORE
    var streak_bonus: int = game_state.success_streak
    score_gained += streak_bonus
    if double_next_score:
      score_gained *= 2
      double_next_score = false
    game_state.add_score(score_gained)

    for card in current_action.cards_on_success:
      game_state.add_motivation_card(card)
      cards_to_add.append(card)

    willpower_restored = _handle_success_special_effects()
    _handle_exhaust_cards()

    result_title.text = "Success!"
    result_title.add_theme_color_override("font_color", success_color)
    _play_sound(success_sound)
    forget_card_button.visible = game_state.motivation_deck.size() > 5
    var details_parts: Array = []
    if score_gained > 0:
      if streak_bonus > 1:
        details_parts.append("You gained %d points! (+%d streak bonus)" % [score_gained, streak_bonus])
      else:
        details_parts.append("You gained %d points!" % score_gained)
    if willpower_restored > 0:
      details_parts.append("Restored %d willpower!" % willpower_restored)
    if details_parts.is_empty() and cards_to_add.is_empty():
      result_details.text = "Action completed, but it didn't align with your values."
    else:
      result_details.text = "\n".join(details_parts)
  else:
    game_state.success_streak = 0
    game_state.succeeded_yesterday = false
    game_state.momentum = maxi(0, game_state.momentum - 1)
    last_action_succeeded = false

    willpower_restored = _handle_failure_special_effects()

    result_title.text = "Failed..."
    result_title.add_theme_color_override("font_color", failure_color)
    _play_sound(failure_sound)
    forget_card_button.visible = false
    var details_text := "The action didn't succeed this time."
    if willpower_restored > 0:
      details_text += "\nRestored %d willpower from Adrenaline Junkie!" % willpower_restored
    result_details.text = details_text

  await _fade_in(result_panel)

  if not cards_to_add.is_empty():
    await _animate_cards_added(cards_to_add)

  _update_top_bar()


func _handle_success_special_effects() -> int:
  var willpower_change := 0
  for card in drawn_cards:
    if not (card is MotivationCardRes):
      continue
    match card.special_effect:
      MotivationCardRes.SpecialEffect.EXTRA_DRAW_FOR_TAG:
        if card.special_target_tag in current_action.tags:
          game_state.extra_draws_next_turn += 1
      MotivationCardRes.SpecialEffect.RESTORE_WILLPOWER_ON_SUCCESS:
        willpower_change += card.special_value
        game_state.willpower = mini(game_state.willpower_max, game_state.willpower + card.special_value)
      MotivationCardRes.SpecialEffect.EXTRA_DRAW_ON_SUCCESS:
        game_state.extra_draws_next_turn += 1
      MotivationCardRes.SpecialEffect.DRAIN_WILLPOWER_ON_SUCCESS:
        willpower_change -= card.special_value
        game_state.willpower = maxi(0, game_state.willpower - card.special_value)
      MotivationCardRes.SpecialEffect.REDUCE_MAX_WILLPOWER:
        game_state.willpower_max = maxi(30, game_state.willpower_max - card.special_value)
        game_state.willpower = mini(game_state.willpower, game_state.willpower_max)
  return willpower_change


func _handle_failure_special_effects() -> int:
  var willpower_restored := 0
  for card in drawn_cards:
    if not (card is MotivationCardRes):
      continue
    match card.special_effect:
      MotivationCardRes.SpecialEffect.RESTORE_WILLPOWER_ON_FAIL:
        willpower_restored += card.special_value
        game_state.willpower = mini(game_state.willpower_max, game_state.willpower + card.special_value)
  return willpower_restored


func _handle_exhaust_cards() -> void:
  for card in drawn_cards:
    if not (card is MotivationCardRes):
      continue
    if card.special_effect == MotivationCardRes.SpecialEffect.EXHAUST_BONUS:
      game_state.remove_motivation_card(card)


func _animate_cards_added(cards: Array) -> void:
  for i in range(cards.size()):
    var card = cards[i]
    var card_panel := _create_deck_add_card_display(card)
    card_panel.pivot_offset = motivation_card_size / 2
    card_panel.scale = Vector2.ZERO
    card_panel.modulate.a = 0.0
    cards_added_container.add_child(card_panel)

    _play_sound(deck_add_sound)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(card_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(card_panel, "modulate:a", 1.0, 0.2)
    await tween.finished

    if i < cards.size() - 1:
      await get_tree().create_timer(0.1).timeout


func _create_deck_add_card_display(card) -> PanelContainer:
  var generic_card = GenericCardScene.instantiate()
  generic_card.card_size = motivation_card_size * 0.8
  generic_card.background_color = positive_card_color
  generic_card.corner_radius = card_corner_radius
  generic_card.content_margin = card_margin
  generic_card.title = card.title
  generic_card.set_corner_text(generic_card.Corner.TOP_LEFT, "+ Added", success_color)
  return generic_card


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
  if action_selection_screen.visible:
    await _fade_out(action_selection_screen)
  if motivation_phase_screen.visible:
    await _fade_out(motivation_phase_screen)
  if result_panel.visible:
    await _fade_out(result_panel)

  end_title.text = "Week Complete!"
  final_score_label.text = "Final Score: %d" % game_state.score

  if actions_taken.is_empty():
    actions_summary.text = "You didn't take any actions this week."
  else:
    actions_summary.text = "Actions taken:\n" + "\n".join(actions_taken)

  await _fade_in(end_game_panel)


func _on_play_again_pressed() -> void:
  await _fade_out(end_game_panel)

  game_state = GameState.new()
  if starter_deck:
    game_state.load_from_deck(starter_deck)
  game_state.willpower = starting_willpower
  game_state.willpower_max = starting_willpower
  actions_taken.clear()
  willpower_spent_today = 0
  value_card_abilities_used.clear()
  _start_new_turn()
  _update_top_bar()


func _on_forget_card_pressed() -> void:
  await _fade_out(result_panel)
  _show_card_removal()


func _show_card_removal() -> void:
  for child in card_removal_container.get_children():
    child.queue_free()

  for card in game_state.motivation_deck:
    var card_panel := _create_removal_card_display(card)
    card_removal_container.add_child(card_panel)

  await _fade_in(card_removal_panel)


func _create_removal_card_display(card) -> PanelContainer:
  var generic_card = GenericCardScene.instantiate()
  generic_card.card_size = motivation_card_size
  generic_card.background_color = neutral_card_color
  generic_card.corner_radius = card_corner_radius
  generic_card.content_margin = card_margin
  generic_card.enable_hover = true
  generic_card.title = card.title
  generic_card.description = card.format_modifiers()

  generic_card.pressed.connect(func() -> void: _remove_card_from_deck(card))
  _setup_card_feedback(generic_card)
  return generic_card


func _remove_card_from_deck(card) -> void:
  game_state.remove_motivation_card(card)
  _play_sound(click_sound)
  await _fade_out(card_removal_panel)
  _on_continue_pressed()


func _on_skip_removal_pressed() -> void:
  await _fade_out(card_removal_panel)
  _on_continue_pressed()
