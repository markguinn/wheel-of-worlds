extends Node


func _get_container() -> Node2D:
	return get_tree().get_first_node_in_group("scene_container")


# TODO: can we keep the instances in memory? or at least cache the load part?
func change_scene(new_scene_path: String, _hud_visible = true, target_portal = "") -> void:
	print("[GameManager] changing to ", new_scene_path)
	var container := _get_container()
	var cur_scene: Node = container.get_child(0)
	var new_scene: Resource = load(new_scene_path)
	var new_instance: Node = new_scene.instantiate()
	# TODO: fade or do something nice
	# TODO: show/hide hud
	container.add_child(new_instance)
	container.remove_child(cur_scene)
	cur_scene.queue_free()
	# TODO: tighten up the ordering of the current scene being freed and the next on being set up
	# TODO: should this live somewhere else? on the scene scrip?
	StateManager.manage_scene.call_deferred(new_scene_path)
	_go_to_portal.call_deferred(target_portal, new_instance)


func _go_to_portal(target_portal: String, cur_scene: Node) -> void:
	if target_portal and get_tree():
		print("[GameManager] attempting target portal: ", target_portal)
		for portal in get_tree().get_nodes_in_group("portals"):
			if portal.portal_name == target_portal:
				print("[GameManager] found target at ", portal.global_position)
				for player in get_tree().get_nodes_in_group("player"):
					# 128 = make sure we're not overlapping the orb (which shoots it off into the ether
					player.global_position = portal.global_position - Vector2(128.0, 0.0)
				if cur_scene.has_method("init_player"):
					cur_scene.init_player(portal)
