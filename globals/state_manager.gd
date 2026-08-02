extends Node

########################################################
# Handles node state that needs to survive changing scenes.
# We're not really tracking health or score or inventory so it
# may not be needed for the player. But for props, we need to
# keep them in the same place when you're coming and going.
########################################################

# player
	# field1 => val1
	# field2 => val2
# res://scenes/abc.tscn
	# $Path/$To/$Node
		# field1 => val1
		# field2 => val2

const PERSIST_PATH = "user://persisted-state.json"
const SURVIVING_KEYS = ["settings"]

var state := {}
#var cfg := ConfigFile.new()


func reset() -> void:
	var old_state := state
	state = {}
	for k in SURVIVING_KEYS:
		if k in old_state:
			state[k] = old_state[k]


func _ready() -> void:
	state = load_file()


func load_file() -> Dictionary:
	if FileAccess.file_exists(PERSIST_PATH):
		var file := FileAccess.open(PERSIST_PATH, FileAccess.READ)
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			return data
		else:
			Log.error(self, "Corrupted state data!", text)
	else:
		Log.info(self, "No saved state was present")
	return {}


func save_file() -> void:
	var s = JSON.stringify(state, "  ")
	var f = FileAccess.open(PERSIST_PATH, FileAccess.WRITE)
	if f:
		f.store_line(s)
		f.close()
	else:
		Log.warn(self, "Unable to save state")


func manage_node(node: Node, key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	if key in data and data[key] is Dictionary:
		var node_data = data[key]
		for k in node_data:
			var v = node_data[k]
			if v is String and v[0] == "(" and v[-1] == ")":
				v = v.trim_prefix("(").trim_suffix(")").split_floats(",")
				Log.debug(self, "restoring vector", node_data[k], v)
				if v.size() == 2:
					node_data[k] = Vector2(v[0], v[1])
		node.restore_persisted_state(node_data)
	else:
		data[key] = node.get_persisted_state()
	node.connect("persisted_state_changed", _on_state_update.bind(key, parent_key))
	Log.debug(self, "managing node:", key, parent_key, data[key])


func manage_scene(scene_instance: Node, scene_key: String, params: Dictionary) -> void:
	if not is_inside_tree():
		return
	Log.debug(self, "managing scene:", scene_key)
	for node in get_tree().get_nodes_in_group("persisted"):
		if scene_instance.is_ancestor_of(node):
			manage_node(node, node.get_path(), scene_key)
	if scene_instance.has_method("init_with_state"):
		scene_instance.init_with_state(_get_dict(scene_key), params)


func has_key(key: String, parent_key = "") -> bool:
	var data = _get_dict(parent_key)
	return key in data


func get_key(key: String, parent_key = "", default = null) -> Variant:
	var data = _get_dict(parent_key)
	return data.get(key, default)


func set_key(key: String, val: Variant, parent_key = "", persist = true) -> void:
	var data = _get_dict(parent_key)
	data[key] = val
	Log.debug(self, "set", key, ":", val, "parent=", parent_key)
	if persist:
		save_file()


func set_keys(updates: Dictionary, parent_key = "", persist = true) -> void:
	var data = _get_dict(parent_key)
	data.merge(updates, true)
	Log.debug(self, "set many", updates, "parent=", parent_key)
	if persist:
		save_file()


func clear_key(key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	data.erase(key)
	Log.debug(self, "clear", key, "parent=", parent_key)


func _get_dict(parent_key: String) -> Dictionary:
	if parent_key == "":
		return state
	if not parent_key in state:
		state[parent_key] = {}
	return state[parent_key]


func _on_state_update(node: Node, key: String, parent_key = "") -> void:
	var data = _get_dict(parent_key)
	data[key] = node.get_persisted_state()
	Log.debug(self, "update:", key, parent_key, data[key])
	if not GameManager.rate_limit(1000, "persiststate"):
		Log.debug(self, "saving")
		save_file()
