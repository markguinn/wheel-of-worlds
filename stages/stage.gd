class_name Stage
extends Node2D

##########################################################
# Base class for a stage scene that can be entered through
# different portals.
##########################################################

# This makes sure we're not overlapping the orb (which shoots it off into the aether)
const OFFSET_FROM_PORTAL = Vector2(-128, 0)

@export var bloom := 0.4
@export var brightness := 1.0
@export var contrast := 1.0
@export var saturation := 1.0


func _ready() -> void:
	AudioManager.reset_music()
	GameManager.is_in_game = true
	VFX.set_baseline(bloom, brightness, contrast, saturation)


func init_with_state(_persisted_state: Dictionary, params: Dictionary) -> void:
	var target_portal = params.get("target_portal")
	if target_portal:
		Log.info(self, "attempting to start at:", target_portal)
		for portal in get_tree().get_nodes_in_group("portals"):
			if portal.portal_name == target_portal and self.is_ancestor_of(portal):
				Log.debug(self, "found target at ", portal.global_position)
				var player: Player = GameManager.get_player()
				if player:
					player.global_position = portal.global_position + OFFSET_FROM_PORTAL
					player.start_pos = player.global_position
				# this allows individual stages to add their own initialization
				# this may only be needed in the wheel (which adjusts its rotation to the players position)
				if self.has_method("init_player_at_portal"):
					self.call("init_player_at_portal", portal)
