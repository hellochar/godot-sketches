@tool
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	return true

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	# Check if this property should use our custom editor
	# Match properties with "HierarchicalTag" hint or names ending in "_tags" or "hierarchical_tags"
	if hint_string == "HierarchicalTag" or name.ends_with("_tags") or name == "hierarchical_tags":
		if type == TYPE_ARRAY or type == TYPE_PACKED_STRING_ARRAY:
			var editor = TagArrayEditor.new()
			add_property_editor(name, editor)
			return true
	return false


class TagArrayEditor extends EditorProperty:
	var container: VBoxContainer
	var tag_list: ItemList
	var updating := false

	func _init() -> void:
		container = VBoxContainer.new()
		container.add_theme_constant_override("separation", 4)
		add_child(container)
		set_bottom_editor(container)

		tag_list = ItemList.new()
		tag_list.custom_minimum_size.y = 100
		tag_list.select_mode = ItemList.SELECT_SINGLE
		tag_list.allow_reselect = true
		container.add_child(tag_list)

		var buttons = HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 4)
		container.add_child(buttons)

		var add_btn = Button.new()
		add_btn.text = "Add Tag"
		add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_btn.pressed.connect(_on_add_tag)
		buttons.add_child(add_btn)

		var remove_btn = Button.new()
		remove_btn.text = "Remove"
		remove_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		remove_btn.pressed.connect(_on_remove_tag)
		buttons.add_child(remove_btn)

	func _update_property() -> void:
		if updating:
			return

		tag_list.clear()
		var value = get_edited_object().get(get_edited_property())
		if value is Array or value is PackedStringArray:
			for tag in value:
				tag_list.add_item(str(tag))

	func _on_add_tag() -> void:
		var picker = TagPickerDialog.new()
		picker.tag_selected.connect(func(tag: String):
			updating = true
			var arr = _get_array_copy()
			if tag not in arr:
				arr.append(tag)
				emit_changed(get_edited_property(), arr)
			updating = false
		)
		add_child(picker)
		picker.popup_centered(Vector2(300, 400))

	func _on_remove_tag() -> void:
		var selected = tag_list.get_selected_items()
		if selected.size() > 0:
			updating = true
			var arr = _get_array_copy()
			arr.remove_at(selected[0])
			emit_changed(get_edited_property(), arr)
			updating = false

	func _get_array_copy() -> Array:
		var value = get_edited_object().get(get_edited_property())
		if value is PackedStringArray:
			return Array(value)
		elif value is Array:
			return value.duplicate()
		return []
