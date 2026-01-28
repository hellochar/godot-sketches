class_name ItemLibrary
extends RefCounted

## A library system for loading and querying Item resources
## Lazy singleton that loads all resources from res://dec-7-2025/items on first access
## Usage:
##   var item = ItemLibrary.instance.get_by_name("Health Potion")
##   var basic_items = ItemLibrary.instance.get_by_tier(Item.ETier.Basic)
##   var weapons = ItemLibrary.instance.get_by_tag(Item.ETag.Weapon)

const RESOURCES_FOLDER = "res://dec-7-2025/items"

static var _instance: ItemLibrary

static var instance: ItemLibrary:
  get:
    if not _instance:
      _instance = ItemLibrary.new()
      _instance.load_from_folder(RESOURCES_FOLDER)
    return _instance

var _resources: Array[Item] = []
var _resources_by_name: Dictionary[String, Item] = {}
var _resources_by_tier: Dictionary[Item.ETier, Array] = {}
var _resources_by_tag: Dictionary[Item.ETag, Array] = {}

func load_from_folder(folder_path: String) -> void:
  clear()
  _scan_directory(folder_path)
  _build_indices()
  print("ItemLibrary: Loaded %d resources from '%s'" % [_resources.size(), folder_path])

func clear() -> void:
  _resources.clear()
  _resources_by_name.clear()
  _resources_by_tier.clear()
  _resources_by_tag.clear()

func get_by_name(resource_name: String) -> Item:
  return _resources_by_name.get(resource_name, null)

func get_by_tier(tier: Item.ETier) -> Array[Item]:
  var arr: Array[Item] = []
  arr.assign(_resources_by_tier.get(tier, []))
  return arr

func get_by_tag(tag: Item.ETag) -> Array[Item]:
  var arr: Array[Item] = []
  arr.assign(_resources_by_tag.get(tag, []))
  return arr

func get_by_tags(tags: Array[Item.ETag]) -> Array[Item]:
  if tags.is_empty():
    return []
  
  var result: Array[Item] = []
  for res in _resources:
    var has_all_tags = true
    for tag in tags:
      if tag not in res.tags:
        has_all_tags = false
        break
    if has_all_tags:
      result.append(res)
  
  return result

func get_by_any_tag(tags: Array[Item.ETag]) -> Array[Item]:
  if tags.is_empty():
    return []
  
  var result_set: Dictionary = {}
  for tag in tags:
    var resources = get_by_tag(tag)
    for res in resources:
      result_set[res] = true
  
  var result: Array[Item] = []
  for res in result_set.keys():
    result.append(res)
  
  return result

func search_by_name(search_term: String) -> Array[Item]:
  var result: Array[Item] = []
  var term_lower = search_term.to_lower()
  
  for res in _resources:
    if res.name.to_lower().contains(term_lower):
      result.append(res)
  
  return result

func get_all() -> Array[Item]:
  return _resources.duplicate()

func get_count() -> int:
  return _resources.size()

func get_all_tiers() -> Array[Item.ETier]:
  var tiers: Array[Item.ETier] = []
  for tier in _resources_by_tier.keys():
    tiers.append(tier)
  return tiers

func get_all_tags() -> Array[Item.ETag]:
  var tags: Array[Item.ETag] = []
  for tag in _resources_by_tag.keys():
    tags.append(tag)
  return tags

func query(tier: Variant = null, tags: Array[Item.ETag] = [], name_contains: String = "") -> Array[Item]:
  var result: Array[Item] = _resources.duplicate()
  
  if tier != null:
    result = result.filter(func(res): return res.tier == tier)
  
  if not tags.is_empty():
    result = result.filter(func(res):
      for tag in tags:
        if tag not in res.tags:
          return false
      return true
    )
  
  if name_contains != "":
    var term_lower = name_contains.to_lower()
    result = result.filter(func(res): return res.name.to_lower().contains(term_lower))
  
  return result

func _scan_directory(path: String) -> void:
  var dir = DirAccess.open(path)
  if dir == null:
    push_error("ItemLibrary: Failed to open directory '%s'" % path)
    return
  
  dir.list_dir_begin()
  var file_name = dir.get_next()
  
  while file_name != "":
    var file_path = path.path_join(file_name)
    
    if dir.current_is_dir():
      if file_name != "." and file_name != "..":
        _scan_directory(file_path)
    else:
      if file_name.ends_with(".tres"):
        _load_resource_file(file_path)
    
    file_name = dir.get_next()
  
  dir.list_dir_end()

func _load_resource_file(file_path: String) -> void:
  var resource = load(file_path)
  
  if resource == null:
    push_warning("ItemLibrary: Failed to load resource '%s'" % file_path)
    return
  
  if not resource is Item:
    push_warning("ItemLibrary: Resource '%s' is not an Item type" % file_path)
    return
  
  _resources.append(resource)

func _build_indices() -> void:
  _resources_by_name.clear()
  _resources_by_tier.clear()
  _resources_by_tag.clear()
  
  for res in _resources:
    var res_name = res.name
    if res_name in _resources_by_name:
      push_warning("ItemLibrary: Duplicate resource name '%s'" % res_name)
    _resources_by_name[res_name] = res
    
    if res.tier not in _resources_by_tier:
      _resources_by_tier[res.tier] = []
    _resources_by_tier[res.tier].append(res)
    
    for tag in res.tags:
      if tag not in _resources_by_tag:
        _resources_by_tag[tag] = []
      _resources_by_tag[tag].append(res)
