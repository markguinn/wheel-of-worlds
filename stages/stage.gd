class_name Stage
extends Node2D


@onready var player = $Player


func init_with_state(_persisted_state: Dictionary, params: Dictionary) -> void:
	var target_portal = params.get("target_portal")
	if target_portal:
		print("[Stage] attempting to start at: ", target_portal)
		for portal in get_tree().get_nodes_in_group("portals"):
			if portal.portal_name == target_portal and self.is_ancestor_of(portal):
				print("[GameManager] found target at ", portal.global_position)
				for player in get_tree().get_nodes_in_group("player"):
					# 128 = make sure we're not overlapping the orb (which shoots it off into the ether
					player.global_position = portal.global_position - Vector2(128.0, 0.0)
					if self.has_method("init_player_at_portal"):
						self.call("init_player_at_portal", portal)
