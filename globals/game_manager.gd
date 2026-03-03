extends Node

########################################################
# This is the spot for things that orchestrate game play
# outside of a single stage or screen
########################################################


# we can use this to enable/disable logging, cheats, debug visuals, etc
const DEV_MODE = true


## Returns the parent node for the active screen or stage
func get_container() -> Node2D:
	return get_tree().get_first_node_in_group("scene_container")


## Returns the root of the current active scene
func get_active_scene() -> Node:
	return get_container().get_child(0)


## Returns the currently active player
func get_player() -> Player:
	return get_tree().get_first_node_in_group("player")


## Load in a new scene. For playable stages, params can generally have a "target_portal"
## key to indicate where you're coming into the level. Maybe that's the only one we'll
## have. Maybe there will be more. Who knows.
# TODO: can we keep the instances or the loaded scene in memory?
func change_scene(new_scene_path: String, params = {}, fade = false) -> void:
	print("[GameManager] changing to ", new_scene_path)
	var container := get_container()
	var cur_scene := get_active_scene()
	var new_scene: Resource = load(new_scene_path)
	var new_instance: Node = new_scene.instantiate()
	
	if fade:
		await VFX.fade_out().finished
	
	container.add_child(new_instance)
	container.remove_child(cur_scene)
	cur_scene.queue_free()
	StateManager.manage_scene.call_deferred(new_instance, new_scene_path, params)

	if fade:
		VFX.fade_in()
	
	# TODO: show/hide hud - maybe new_instance can have a is_hud_visible()->bool method? or maybe we just always hide the hud when the scene changes and each scene can call GameManager.show_hud()?
