@tool
extends EditorPlugin

var tag_manager_dock: Control
var inspector_plugin: EditorInspectorPlugin

func _enter_tree() -> void:
	# Add autoload
	add_autoload_singleton("GameplayTags", "res://addons/gameplay_tags/autoload/gameplay_tag_system.gd")

	# Add the tag manager dock
	tag_manager_dock = preload("res://addons/gameplay_tags/editor/tag_manager_dock.tscn").instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, tag_manager_dock)

	# Add custom inspector for tag properties
	inspector_plugin = preload("res://addons/gameplay_tags/editor/tag_property_editor.gd").new()
	add_inspector_plugin(inspector_plugin)

func _exit_tree() -> void:
	remove_autoload_singleton("GameplayTags")

	if tag_manager_dock:
		remove_control_from_docks(tag_manager_dock)
		tag_manager_dock.queue_free()

	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
