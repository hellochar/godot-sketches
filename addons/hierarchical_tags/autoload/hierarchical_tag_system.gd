@tool
class_name HierarchicalTagSystem
extends Node

const TAGS_PATH = "res://addons/hierarchical_tags/data/registered_tags.tres"

var _registered_tags: Dictionary = {}  # tag -> metadata
var _tag_tree: Dictionary = {}  # Hierarchical structure for UI

signal tags_changed

func _ready() -> void:
	_load_tags()

func _load_tags() -> void:
	if ResourceLoader.exists(TAGS_PATH):
		var data = load(TAGS_PATH)
		if data and data.has_meta("tags"):
			_registered_tags = data.get_meta("tags")
			_rebuild_tree()

func _save_tags() -> void:
	var data = Resource.new()
	data.set_meta("tags", _registered_tags)
	ResourceSaver.save(data, TAGS_PATH)

func _rebuild_tree() -> void:
	_tag_tree.clear()
	for tag in _registered_tags.keys():
		_add_to_tree(tag)

func _add_to_tree(tag: String) -> void:
	var parts = tag.split(".")
	var current = _tag_tree
	for part in parts:
		if part not in current:
			current[part] = {}
		current = current[part]

# --- Registration API ---

func register_tag(tag: String, description: String = "") -> void:
	_registered_tags[tag] = {"description": description}
	_add_to_tree(tag)
	_save_tags()
	tags_changed.emit()

func unregister_tag(tag: String) -> void:
	# Remove this tag and all children
	var to_remove: Array[String] = []
	for t in _registered_tags.keys():
		if t == tag or t.begins_with(tag + "."):
			to_remove.append(t)
	for t in to_remove:
		_registered_tags.erase(t)
	_rebuild_tree()
	_save_tags()
	tags_changed.emit()

func get_all_tags() -> Array[String]:
	var tags: Array[String] = []
	tags.assign(_registered_tags.keys())
	tags.sort()
	return tags

func get_tag_tree() -> Dictionary:
	return _tag_tree

func is_registered(tag: String) -> bool:
	return tag in _registered_tags

func get_tag_description(tag: String) -> String:
	if tag in _registered_tags:
		return _registered_tags[tag].get("description", "")
	return ""

# --- Query API ---

func has_tag(container: Array[String], tag: String) -> bool:
	return tag in container

func has_tag_parent(container: Array[String], parent_tag: String) -> bool:
	## Returns true if container has the tag OR any child of it
	for t in container:
		if t == parent_tag or t.begins_with(parent_tag + "."):
			return true
	return false

func has_any(container: Array[String], tags: Array[String]) -> bool:
	for tag in tags:
		if has_tag_parent(container, tag):
			return true
	return false

func has_all(container: Array[String], tags: Array[String]) -> bool:
	for tag in tags:
		if not has_tag_parent(container, tag):
			return false
	return true

func filter_by_tag(nodes: Array[Node], tag: String) -> Array[Node]:
	## Filter an array of nodes by those that have a matching tag
	var result: Array[Node] = []
	for node in nodes:
		if node.has_method("get_hierarchical_tags"):
			if has_tag_parent(node.get_hierarchical_tags(), tag):
				result.append(node)
	return result

func get_matching_tags(container: Array[String], parent_tag: String) -> Array[String]:
	## Get all tags in container that match a parent
	var result: Array[String] = []
	for t in container:
		if t == parent_tag or t.begins_with(parent_tag + "."):
			result.append(t)
	return result
