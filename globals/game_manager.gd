extends Node


func get_container() -> Node2D:
	return get_tree().get_first_node_in_group("scene_container")


func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")


# TODO: can we keep the instances or the loaded scene in memory?
func change_scene(new_scene_path: String, params = {}) -> void:
	print("[GameManager] changing to ", new_scene_path)
	var container := get_container()
	var cur_scene: Node = container.get_child(0)
	var new_scene: Resource = load(new_scene_path)
	var new_instance: Node = new_scene.instantiate()
	
	# TODO: fade or do something nice
	
	container.add_child(new_instance)
	container.remove_child(cur_scene)
	cur_scene.queue_free()
	StateManager.manage_scene.call_deferred(new_instance, new_scene_path, params)
	
	# TODO: show/hide hud - maybe new_instance can have a is_hud_visible()->bool method? or maybe we just always hide the hud when the scene changes and each scene can call GameManager.show_hud()?
