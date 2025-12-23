@tool
class_name GameplayTagContainer
extends Resource

## A resource that holds a collection of gameplay tags.
## Can be used as an @export property for better editor integration.

@export var tags: Array[String] = []

func has(tag: String) -> bool:
	## Check if this container has the tag or any child of it
	if not GameplayTags:
		return tag in tags
	return GameplayTags.has_tag_parent(tags, tag)

func has_exact(tag: String) -> bool:
	## Check if this container has the exact tag
	return tag in tags

func has_any(check_tags: Array[String]) -> bool:
	## Check if this container has any of the specified tags
	if not GameplayTags:
		for t in check_tags:
			if t in tags:
				return true
		return false
	return GameplayTags.has_any(tags, check_tags)

func has_all(check_tags: Array[String]) -> bool:
	## Check if this container has all of the specified tags
	if not GameplayTags:
		for t in check_tags:
			if t not in tags:
				return false
		return true
	return GameplayTags.has_all(tags, check_tags)

func add_tag(tag: String) -> void:
	if tag not in tags:
		tags.append(tag)
		emit_changed()

func remove_tag(tag: String) -> void:
	if tag in tags:
		tags.erase(tag)
		emit_changed()

func clear() -> void:
	tags.clear()
	emit_changed()

func get_tags() -> Array[String]:
	return tags.duplicate()
