extends Node

# player
	# field1 => val1
	# field2 => val2
# res://scenes/abc.tscn
	# $Path/$To/$Node
		# field1 => val1
		# field2 => val2

const LOG_ENABLED = true

var state := {}


func reset() -> void:
	state = {}


func manage_node(node: Node, key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	if key in data:
		node.restore_persisted_state(data[key])
	else:
		data[key] = node.get_persisted_state()
	node.connect("persisted_state_changed", _on_state_update.bind(key, parent_key))
	if LOG_ENABLED:
		print("[StateManager] managing node: ", [key, parent_key, data[key]])


func manage_scene(scene_instance: Node, scene_key: String, params: Dictionary) -> void:
	if not get_tree():
		return
	if LOG_ENABLED:
		print("[StateManager] managing scene: ", scene_key)
	for node in get_tree().get_nodes_in_group("persisted"):
		if scene_instance.is_ancestor_of(node):
			manage_node(node, node.get_path(), scene_key)
	if scene_instance.has_method("init_with_state"):
		scene_instance.init_with_state(_get_dict(scene_key), params)


func has_key(key: String, parent_key = "") -> bool:
	var data = _get_dict(parent_key)
	return key in data


func get_key(key: String, parent_key = "") -> Variant:
	var data = _get_dict(parent_key)
	return data.get(key)


func set_key(key: String, val: Variant, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	data[key] = val
	if LOG_ENABLED:
		print_verbose("[StateManager] set ", key, ": ", val, ", parent=", parent_key)


func clear_key(key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	data.erase(key)
	if LOG_ENABLED:
		print_verbose("[StateManager] clear ", key, ", parent=", parent_key)


func _get_dict(parent_key: String) -> Dictionary:
	if parent_key == "":
		return state
	if not parent_key in state:
		state[parent_key] = {}
	return state[parent_key]


func _on_state_update(node: Node, key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	data[key] = node.get_persisted_state()
	if LOG_ENABLED:
		print_verbose("[StateManager] update: ", [key, parent_key, data[key]])
