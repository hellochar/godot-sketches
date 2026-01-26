class_name GameState
extends RefCounted

const CardData = preload("res://jan_24_2026b-motivation-cards/card_data.gd")

var motivation_deck: Array = []
var value_cards: Array = []
var all_value_cards: Array = []
var willpower: int = 100
var willpower_max: int = 100
var score: int = 0
var current_day: int = 1

var available_actions: Array = []
var world_modifiers: Array = []

var success_streak: int = 0
var attempted_actions: Array[String] = []
var extra_draws_next_turn: int = 0
var succeeded_yesterday: bool = false
var total_successes_this_week: int = 0
var last_successful_action_title: String = ""
var momentum: int = 0
const MOMENTUM_MAX: int = 10
const MOMENTUM_BONUS_PER: int = 3
var action_mastery: Dictionary = {}
const MASTERY_MAX: int = 3
const MASTERY_DISCOUNT_PER: int = 5
var daily_bonus_tag: int = -1
const DAILY_BONUS_SCORE: int = 5


func _init() -> void:
  pass


func get_action_mastery(action_title: String) -> int:
  return action_mastery.get(action_title, 0)


func increase_action_mastery(action_title: String) -> void:
  var current: int = action_mastery.get(action_title, 0)
  action_mastery[action_title] = mini(MASTERY_MAX, current + 1)


func randomize_daily_bonus_tag() -> void:
  daily_bonus_tag = randi() % CardData.Tag.size()


func load_from_deck(deck: Resource) -> void:
  available_actions = deck.actions.duplicate()
  motivation_deck = deck.motivation_cards.duplicate()
  all_value_cards = deck.value_cards.duplicate()
  value_cards = []
  if not all_value_cards.is_empty():
    var random_index := randi() % all_value_cards.size()
    value_cards.append(all_value_cards[random_index])
  world_modifiers = deck.world_modifiers.duplicate()


func _create_starter_content() -> void:
  _create_starter_actions()
  _create_starter_motivation_cards()
  _create_starter_value_cards()
  _create_world_modifiers()


func _create_starter_actions() -> void:
  available_actions = [
    CardData.ActionData.new(
      "Go for a Morning Run",
      75,
      [CardData.Tag.HEALTH, CardData.Tag.EFFORT, CardData.Tag.ROUTINE] as Array,
      0.80
    ),
    CardData.ActionData.new(
      "Call a Friend",
      40,
      [CardData.Tag.SOCIAL] as Array,
      0.95
    ),
    CardData.ActionData.new(
      "Start Creative Project",
      90,
      [CardData.Tag.CREATIVITY, CardData.Tag.EFFORT, CardData.Tag.RISK] as Array,
      0.60
    ),
    CardData.ActionData.new(
      "Clean the Apartment",
      50,
      [CardData.Tag.ROUTINE, CardData.Tag.EFFORT] as Array,
      0.90
    ),
    CardData.ActionData.new(
      "Try Something Risky",
      60,
      [CardData.Tag.RISK, CardData.Tag.CREATIVITY] as Array,
      0.50
    ),
  ]


func _create_starter_motivation_cards() -> void:
  motivation_deck = [
    CardData.MotivationCard.new("I value health", {CardData.Tag.HEALTH: 25}),
    CardData.MotivationCard.new("I avoid discomfort", {CardData.Tag.EFFORT: -15}),
    CardData.MotivationCard.new("I seek routine", {CardData.Tag.ROUTINE: 15}),
    CardData.MotivationCard.new("Social anxiety", {CardData.Tag.SOCIAL: -20}),
    CardData.MotivationCard.new("Creative spark", {CardData.Tag.CREATIVITY: 30}),
    CardData.MotivationCard.new("Fear of failure", {CardData.Tag.RISK: -25}),
    CardData.MotivationCard.new("Morning person", {CardData.Tag.ROUTINE: 20}),
    CardData.MotivationCard.new("Physical energy", {CardData.Tag.HEALTH: 15, CardData.Tag.EFFORT: 10}),
    CardData.MotivationCard.new("Feeling isolated", {CardData.Tag.SOCIAL: 25}),
    CardData.MotivationCard.new("Comfort seeker", {CardData.Tag.EFFORT: -10, CardData.Tag.ROUTINE: 10}),
    CardData.MotivationCard.new("Ambitious drive", {CardData.Tag.RISK: 20}),
    CardData.MotivationCard.new("Restless mind", {CardData.Tag.CREATIVITY: 15, CardData.Tag.ROUTINE: -10}),
    CardData.MotivationCard.new("Need for connection", {CardData.Tag.SOCIAL: 20}),
    CardData.MotivationCard.new("Body feels good", {CardData.Tag.HEALTH: 20, CardData.Tag.EFFORT: 15}),
    CardData.MotivationCard.new("Lazy afternoon", {CardData.Tag.EFFORT: -20, CardData.Tag.ROUTINE: 5}),
  ]


func _create_starter_value_cards() -> void:
  all_value_cards = [
    CardData.ValueCard.new("I care about health", {CardData.Tag.HEALTH: 10}),
    CardData.ValueCard.new("Community matters", {CardData.Tag.SOCIAL: 10}),
    CardData.ValueCard.new("Self-expression", {CardData.Tag.CREATIVITY: 15}),
  ]
  value_cards = []
  if not all_value_cards.is_empty():
    var random_index := randi() % all_value_cards.size()
    value_cards.append(all_value_cards[random_index])


func _create_world_modifiers() -> void:
  world_modifiers = [
    CardData.WorldModifier.new("It's raining", {CardData.Tag.EFFORT: -10}),
    CardData.WorldModifier.new("Friend texted", {CardData.Tag.SOCIAL: 10}),
    CardData.WorldModifier.new("Beautiful day", {CardData.Tag.HEALTH: 10, CardData.Tag.ROUTINE: 5}),
    CardData.WorldModifier.new("Feeling tired", {CardData.Tag.EFFORT: -15}),
  ]


func draw_motivation_cards(count: int) -> Array:
  var deck_copy := motivation_deck.duplicate()
  deck_copy.shuffle()
  var drawn: Array = []
  for i in mini(count, deck_copy.size()):
    drawn.append(deck_copy[i])
  return drawn


func get_random_world_modifier():
  if world_modifiers.is_empty():
    return null
  return world_modifiers[randi() % world_modifiers.size()]


func spend_willpower(amount: int) -> void:
  willpower = maxi(0, willpower - amount)


func add_score(amount: int) -> void:
  score += amount


func add_motivation_card(card) -> void:
  motivation_deck.append(card)


func remove_motivation_card(card) -> void:
  var idx := motivation_deck.find(card)
  if idx >= 0:
    motivation_deck.remove_at(idx)


func add_value_card(card) -> void:
  value_cards.append(card)


func new_day() -> void:
  current_day += 1
  willpower = willpower_max
  motivation_deck = motivation_deck.filter(func(c) -> bool: return not c.is_temporary)
