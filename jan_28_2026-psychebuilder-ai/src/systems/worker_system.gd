extends Node

const WorkerScene = preload("res://jan_28_2026-psychebuilder-ai/src/entities/worker.tscn")

@onready var game_state: Node = get_node("/root/GameState")
@onready var config: Node = get_node("/root/Config")

var grid: RefCounted
var workers: Array = []

var attention_pool: int
var attention_used: int = 0

var habituation_thresholds: Array
var habituation_costs: Array

func setup(p_grid: RefCounted, p_attention_pool: int, p_thresholds: Array, p_costs: Array) -> void:
  grid = p_grid
  attention_pool = p_attention_pool
  habituation_thresholds = p_thresholds
  habituation_costs = p_costs

func get_available_attention() -> int:
  return attention_pool - attention_used

func spawn_worker(world_position: Vector2) -> Node:
  var worker = WorkerScene.instantiate()
  worker.position = world_position
  worker.setup(grid)
  worker.job_cycle_completed.connect(func(): update_habituation(worker))
  workers.append(worker)
  return worker

func remove_worker(worker: Node) -> void:
  if worker in workers:
    _refund_attention(worker)
    worker.unassign()
    workers.erase(worker)
    worker.queue_free()

func assign_transport_job(worker: Node, source: Node, dest: Node, resource_type: String) -> bool:
  var cost = _calculate_attention_cost(worker, "transport", source, dest, resource_type)
  if cost > get_available_attention():
    return false

  if worker.assign_transport_job(source, dest, resource_type):
    attention_used += cost
    return true
  return false

func assign_operate_job(worker: Node, building: Node) -> bool:
  var cost = _calculate_attention_cost(worker, "operate", building, null, "")
  if cost > get_available_attention():
    return false

  if worker.assign_operate_job(building):
    attention_used += cost
    return true
  return false

func unassign_worker(worker: Node) -> void:
  _refund_attention(worker)
  worker.unassign()

func _calculate_attention_cost(worker: Node, job_type: String, target_a: Node, target_b: Node, resource_type: String) -> int:
  var job_id = _make_job_id(job_type, target_a, target_b, resource_type)
  var game_state = game_state
  var completions = game_state.habituation_progress.get(job_id, 0)
  var tier = _get_habituation_tier(completions)
  var cost_multiplier = habituation_costs[tier]
  return ceili(cost_multiplier)

func _make_job_id(job_type: String, target_a: Node, target_b: Node, resource_type: String) -> String:
  if job_type == "transport":
    return "transport_%s_%s_%s" % [target_a.building_id, target_b.building_id, resource_type]
  elif job_type == "operate":
    return "operate_%s" % target_a.building_id
  return ""

func _get_habituation_tier(completions: int) -> int:
  for i in range(habituation_thresholds.size()):
    if completions < habituation_thresholds[i]:
      return i
  return habituation_thresholds.size()

func _refund_attention(worker: Node) -> void:
  if worker.job_type == "":
    return

  var cost = _calculate_attention_cost(worker, worker.job_type, worker.source_building if worker.source_building else worker.dest_building, worker.dest_building, worker.resource_type)
  attention_used = maxi(0, attention_used - cost)

func update_habituation(worker: Node) -> void:
  var target_a = worker.source_building if worker.source_building else worker.dest_building
  var old_cost = _calculate_attention_cost(worker, worker.job_type, target_a, worker.dest_building, worker.resource_type)

  var job_id = _make_job_id(worker.job_type, target_a, worker.dest_building, worker.resource_type)
  var game_state = game_state
  game_state.increment_habituation(job_id)

  var new_cost = _calculate_attention_cost(worker, worker.job_type, target_a, worker.dest_building, worker.resource_type)

  if new_cost < old_cost:
    attention_used -= (old_cost - new_cost)

func get_idle_workers() -> Array:
  var idle: Array = []
  for worker in workers:
    if worker.state == worker.State.IDLE:
      idle.append(worker)
  return idle

func get_workers_for_building(building: Node) -> Array:
  var result: Array = []
  for worker in workers:
    if worker.dest_building == building or worker.source_building == building:
      result.append(worker)
  return result
