extends Node

## A library system for loading and querying Res resources
## Autoload singleton that automatically loads all resources from res://reses
## Usage:
##   var item = ResLibrary.get_by_name("Health Potion")
##   var basic_items = ResLibrary.get_by_tier(Res.ETier.Basic)
##   var weapons = ResLibrary.get_by_tag(Res.ETag.Weapon)

const RESOURCES_FOLDER = "res://reses"

var _resources: Array[Res] = []
var _resources_by_name: Dictionary = {}  # String -> Res
var _resources_by_tier: Dictionary = {}  # Res.ETier -> Array[Res]
var _resources_by_tag: Dictionary = {}   # Res.ETag -> Array[Res]

func _ready() -> void:
	load_from_folder(RESOURCES_FOLDER)

## Load all .tres resource files from a folder
func load_from_folder(folder_path: String) -> void:
	clear()
	_scan_directory(folder_path)
	_build_indices()
	print("ResLibrary: Loaded %d resources from '%s'" % [_resources.size(), folder_path])

## Clear all loaded resources
func clear() -> void:
	_resources.clear()
	_resources_by_name.clear()
	_resources_by_tier.clear()
	_resources_by_tag.clear()

## Get a resource by exact name (case-sensitive)
func get_by_name(resource_name: String) -> Res:
	return _resources_by_name.get(resource_name, null)

## Get all resources of a specific tier
func get_by_tier(tier: Res.ETier) -> Array[Res]:
	return _resources_by_tier.get(tier, []).duplicate()

## Get all resources with a specific tag
func get_by_tag(tag: Res.ETag) -> Array[Res]:
	return _resources_by_tag.get(tag, []).duplicate()

## Get all resources that have ALL of the specified tags
func get_by_tags(tags: Array[Res.ETag]) -> Array[Res]:
	if tags.is_empty():
		return []
	
	var result: Array[Res] = []
	for res in _resources:
		var has_all_tags = true
		for tag in tags:
			if tag not in res.tags:
				has_all_tags = false
				break
		if has_all_tags:
			result.append(res)
	
	return result

## Get all resources that have ANY of the specified tags
func get_by_any_tag(tags: Array[Res.ETag]) -> Array[Res]:
	if tags.is_empty():
		return []
	
	var result_set: Dictionary = {}  # Use dict to avoid duplicates
	for tag in tags:
		var resources = get_by_tag(tag)
		for res in resources:
			result_set[res] = true
	
	var result: Array[Res] = []
	for res in result_set.keys():
		result.append(res)
	
	return result

## Search resources by name (case-insensitive, partial match)
func search_by_name(search_term: String) -> Array[Res]:
	var result: Array[Res] = []
	var term_lower = search_term.to_lower()
	
	for res in _resources:
		if res.name.to_lower().contains(term_lower):
			result.append(res)
	
	return result

## Get all loaded resources
func get_all() -> Array[Res]:
	return _resources.duplicate()

## Get the total number of loaded resources
func get_count() -> int:
	return _resources.size()

## Get all unique tiers present in the library
func get_all_tiers() -> Array[Res.ETier]:
	var tiers: Array[Res.ETier] = []
	for tier in _resources_by_tier.keys():
		tiers.append(tier)
	return tiers

## Get all unique tags present in the library
func get_all_tags() -> Array[Res.ETag]:
	var tags: Array[Res.ETag] = []
	for tag in _resources_by_tag.keys():
		tags.append(tag)
	return tags

## Advanced query with multiple filters (pass null for tier to skip tier filtering)
func query(tier: Variant = null, tags: Array[Res.ETag] = [], name_contains: String = "") -> Array[Res]:
	var result: Array[Res] = _resources.duplicate()
	
	# Filter by tier
	if tier != null:
		result = result.filter(func(res): return res.tier == tier)
	
	# Filter by tags (must have all)
	if not tags.is_empty():
		result = result.filter(func(res):
			for tag in tags:
				if tag not in res.tags:
					return false
			return true
		)
	
	# Filter by name
	if name_contains != "":
		var term_lower = name_contains.to_lower()
		result = result.filter(func(res): return res.name.to_lower().contains(term_lower))
	
	return result

## Private: Recursively scan directory for .tres files
func _scan_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		push_error("ResLibrary: Failed to open directory '%s'" % path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var file_path = path.path_join(file_name)
		
		if dir.current_is_dir():
			# Recursively scan subdirectories
			if file_name != "." and file_name != "..":
				_scan_directory(file_path)
		else:
			# Load .tres files
			if file_name.ends_with(".tres"):
				_load_resource_file(file_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

## Private: Load a single resource file
func _load_resource_file(file_path: String) -> void:
	var resource = load(file_path)
	
	if resource == null:
		push_warning("ResLibrary: Failed to load resource '%s'" % file_path)
		return
	
	if not resource is Res:
		push_warning("ResLibrary: Resource '%s' is not a Res type" % file_path)
		return
	
	_resources.append(resource)

## Private: Build lookup indices for fast queries
func _build_indices() -> void:
	_resources_by_name.clear()
	_resources_by_tier.clear()
	_resources_by_tag.clear()
	
	for res in _resources:
		# Index by name (derived from file path)
		var res_name = res.name
		if res_name in _resources_by_name:
			push_warning("ResLibrary: Duplicate resource name '%s'" % res_name)
		_resources_by_name[res_name] = res
		
		# Index by tier
		if res.tier not in _resources_by_tier:
			_resources_by_tier[res.tier] = []
		_resources_by_tier[res.tier].append(res)
		
		# Index by tags
		for tag in res.tags:
			if tag not in _resources_by_tag:
				_resources_by_tag[tag] = []
			_resources_by_tag[tag].append(res)
