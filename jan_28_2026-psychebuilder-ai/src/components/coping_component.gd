class_name CopingComponent
extends BuildingComponent

var coping_cooldown_timer: float = 0.0

func on_process(delta: float) -> void:
  if coping_cooldown_timer > 0:
    coping_cooldown_timer -= delta
    return

  var trigger = definition.get("coping_trigger", "")
  if not building._evaluate_trigger(trigger):
    return

  var inputs = definition.get("coping_input", {})
  if building._has_inputs(inputs):
    building._consume_inputs(inputs)
    var outputs = definition.get("coping_output", {})
    for resource_id in outputs:
      output_resource(resource_id, outputs[resource_id])
    coping_cooldown_timer = definition.get("coping_cooldown", 30.0)
