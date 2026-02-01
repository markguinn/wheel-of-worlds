extends Node


func _get_container() -> Node2D:
	return get_tree().get_first_node_in_group("scene_container")


func change_scene(new_scene: PackedScene, hud_visible = true) -> void:
	var container := _get_container()
	var cur_scene = container.get_child(0)
	var new_instance = new_scene.instantiate()
	# TODO: fade or do something nice
	# TODO: show/hide hud
	container.add_child(new_instance)
	cur_scene.queue_free()
	
